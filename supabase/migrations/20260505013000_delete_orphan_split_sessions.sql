-- Remove visible session rows that no longer have any backing component.
-- Also make future exact source-session re-pushes clean up their old same-id
-- aggregate row when the component already belongs to a different canonical
-- session.

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

    select session_id into v_target_id
    from session_components
    where user_id = v_uid
      and source = p_source
      and source_session_id = p_id
    limit 1;

    if v_target_id is null then
        select id into v_target_id
        from sessions
        where user_id = v_uid
          and started_at <= p_ended_at + v_gap
          and ended_at   >= p_started_at - v_gap
        order by
            case when id = p_id then 1 else 0 end,
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

    delete from sessions s
    where s.user_id = v_uid
      and s.id <> v_target_id
      and not exists (
          select 1
          from session_components sc
          where sc.user_id = s.user_id
            and sc.session_id = s.id
      );

    return v_target_id;
end;
$$;

delete from sessions s
where not exists (
    select 1
    from session_components sc
    where sc.user_id = s.user_id
      and sc.session_id = s.id
);
