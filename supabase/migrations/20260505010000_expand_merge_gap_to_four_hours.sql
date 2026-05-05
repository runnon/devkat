-- Treat coding activity separated by up to 4 hours as one visible session.
-- Keep the component-backed merge semantics so re-pushes replace source
-- components instead of double-counting them.

create or replace function merge_session(
    p_id              text,
    p_started_at      timestamptz,
    p_ended_at        timestamptz,
    p_active_duration float8,
    p_lines_added     int,
    p_lines_removed   int,
    p_files_touched   int,
    p_tokens          int,
    p_model           text,
    p_repo_alias      text,
    p_git_branch      text,
    p_source          text
) returns text
language plpgsql security definer
as $$
declare
    v_uid       uuid := auth.uid();
    v_target_id text;
    v_gap       interval := interval '4 hours';
begin
    if v_uid is null then
        raise exception 'merge_session requires an authenticated user';
    end if;

    -- Exact source-session match: this is a re-push, so replace its component.
    select session_id into v_target_id
    from session_components
    where user_id = v_uid
      and source = p_source
      and source_session_id = p_id
    limit 1;

    -- Exact aggregate row match, useful before a component exists.
    if v_target_id is null then
        select id into v_target_id
        from sessions
        where user_id = v_uid
          and id = p_id
        limit 1;
    end if;

    -- Otherwise merge into the closest overlapping/nearby aggregate row.
    if v_target_id is null then
        select id into v_target_id
        from sessions
        where user_id = v_uid
          and started_at <= p_ended_at + v_gap
          and ended_at   >= p_started_at - v_gap
        order by
            case when started_at <= p_started_at and ended_at >= p_ended_at then 0 else 1 end,
            greatest(0, extract(epoch from (p_started_at - ended_at)),
                        extract(epoch from (started_at - p_ended_at)))
        limit 1;
    end if;

    if v_target_id is null then
        v_target_id := p_id;

        insert into sessions (
            id, user_id, started_at, ended_at, active_duration,
            lines_added, lines_removed, files_touched, tokens,
            sources, models, repo_alias, git_branch
        )
        values (
            v_target_id, v_uid, p_started_at, p_ended_at, p_active_duration,
            p_lines_added, p_lines_removed, p_files_touched, p_tokens,
            array[p_source], array[p_model], p_repo_alias, p_git_branch
        )
        on conflict (id) do nothing;
    end if;

    -- Remove stale same-source components for the same target/range. This
    -- cleans rows created before component-backed merging existed.
    delete from session_components
    where user_id = v_uid
      and session_id = v_target_id
      and source = p_source
      and source_session_id <> p_id
      and started_at <= p_ended_at + v_gap
      and ended_at   >= p_started_at - v_gap;

    insert into session_components (
        user_id, session_id, source, source_session_id,
        started_at, ended_at, active_duration,
        lines_added, lines_removed, files_touched, tokens, model
    )
    values (
        v_uid, v_target_id, p_source, p_id,
        p_started_at, p_ended_at, p_active_duration,
        p_lines_added, p_lines_removed, p_files_touched, p_tokens,
        coalesce(p_model, '')
    )
    on conflict (user_id, session_id, source, source_session_id) do update set
        started_at      = excluded.started_at,
        ended_at        = excluded.ended_at,
        active_duration = excluded.active_duration,
        lines_added     = excluded.lines_added,
        lines_removed   = excluded.lines_removed,
        files_touched   = excluded.files_touched,
        tokens          = excluded.tokens,
        model           = excluded.model,
        updated_at      = now();

    with agg as (
        select
            min(started_at) as started_at,
            max(ended_at) as ended_at,
            sum(active_duration) as active_duration,
            sum(lines_added)::int as lines_added,
            sum(lines_removed)::int as lines_removed,
            max(files_touched)::int as files_touched,
            sum(tokens)::int as tokens,
            array_agg(distinct source order by source) as sources,
            coalesce(
                array_agg(distinct model order by model) filter (where model <> ''),
                '{}'::text[]
            ) as models
        from session_components
        where user_id = v_uid
          and session_id = v_target_id
    )
    update sessions set
        started_at      = agg.started_at,
        ended_at        = agg.ended_at,
        active_duration = agg.active_duration,
        lines_added     = agg.lines_added,
        lines_removed   = agg.lines_removed,
        files_touched   = agg.files_touched,
        tokens          = agg.tokens,
        sources         = agg.sources,
        models          = agg.models,
        repo_alias      = coalesce(sessions.repo_alias, p_repo_alias),
        git_branch      = coalesce(p_git_branch, sessions.git_branch)
    from agg
    where sessions.user_id = v_uid
      and sessions.id = v_target_id;

    return v_target_id;
end;
$$;

-- Repair rows that were split under the old 30-minute gap.
with recursive ordered_components as (
    select
        sc.*,
        coalesce(s.repo_alias, '') as repo_alias,
        coalesce(s.git_branch, '') as git_branch,
        max(sc.ended_at) over (
            partition by sc.user_id, coalesce(s.repo_alias, ''), coalesce(s.git_branch, '')
            order by sc.started_at, sc.ended_at, sc.session_id, sc.source, sc.source_session_id
            rows between unbounded preceding and 1 preceding
        ) as previous_ended_at
    from session_components sc
    left join sessions s
      on s.user_id = sc.user_id
     and s.id = sc.session_id
),
grouped_components as (
    select
        *,
        sum(
            case
                when previous_ended_at is null or started_at > previous_ended_at + interval '4 hours' then 1
                else 0
            end
        ) over (
            partition by user_id, repo_alias, git_branch
            order by started_at, ended_at, session_id, source, source_session_id
        ) as session_group
    from ordered_components
),
canonical_groups as (
    select
        user_id,
        repo_alias,
        git_branch,
        session_group,
        (array_agg(session_id order by started_at, ended_at, session_id))[1] as canonical_session_id
    from grouped_components
    group by user_id, repo_alias, git_branch, session_group
),
remapped_components as (
    update session_components sc
    set session_id = cg.canonical_session_id,
        updated_at = now()
    from grouped_components gc
    join canonical_groups cg
      on cg.user_id = gc.user_id
     and cg.repo_alias = gc.repo_alias
     and cg.git_branch = gc.git_branch
     and cg.session_group = gc.session_group
    where sc.user_id = gc.user_id
      and sc.session_id = gc.session_id
      and sc.source = gc.source
      and sc.source_session_id = gc.source_session_id
      and sc.session_id <> cg.canonical_session_id
    returning sc.user_id
),
affected_users as (
    select user_id from remapped_components
    union
    select distinct user_id from session_components
),
session_aggregates as (
    select
        sc.user_id,
        sc.session_id,
        min(sc.started_at) as started_at,
        max(sc.ended_at) as ended_at,
        sum(sc.active_duration) as active_duration,
        sum(sc.lines_added)::int as lines_added,
        sum(sc.lines_removed)::int as lines_removed,
        max(sc.files_touched)::int as files_touched,
        sum(sc.tokens)::int as tokens,
        array_agg(distinct sc.source order by sc.source) as sources,
        coalesce(
            array_agg(distinct sc.model order by sc.model) filter (where sc.model <> ''),
            '{}'::text[]
        ) as models
    from session_components sc
    join affected_users au on au.user_id = sc.user_id
    group by sc.user_id, sc.session_id
),
updated_sessions as (
    update sessions s
    set started_at = sa.started_at,
        ended_at = sa.ended_at,
        active_duration = sa.active_duration,
        lines_added = sa.lines_added,
        lines_removed = sa.lines_removed,
        files_touched = sa.files_touched,
        tokens = sa.tokens,
        sources = sa.sources,
        models = sa.models
    from session_aggregates sa
    where s.user_id = sa.user_id
      and s.id = sa.session_id
    returning s.user_id, s.id
)
delete from sessions s
where exists (
    select 1 from affected_users au where au.user_id = s.user_id
)
and not exists (
    select 1
    from session_components sc
    where sc.user_id = s.user_id
      and sc.session_id = s.id
);
