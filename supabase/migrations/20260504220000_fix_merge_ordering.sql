-- Fix merge_session to pick the best overlapping session (closest match)
-- instead of the earliest one, which could be from a different day.

create or replace function merge_session(
    p_id            text,
    p_started_at    timestamptz,
    p_ended_at      timestamptz,
    p_active_duration float8,
    p_lines_added   int,
    p_lines_removed int,
    p_files_touched int,
    p_tokens        int,
    p_model         text,
    p_repo_alias    text,
    p_git_branch    text,
    p_source        text
) returns text
language plpgsql security definer
as $$
declare
    v_uid       uuid := auth.uid();
    v_existing  record;
    v_gap       interval := interval '30 minutes';
begin
    -- Find the best existing session to merge with:
    -- Must overlap or be within 30 min, pick the one with the closest time range
    select * into v_existing
    from sessions
    where user_id = v_uid
      and started_at <= p_ended_at + v_gap
      and ended_at   >= p_started_at - v_gap
    order by
        -- Prefer sessions that actually contain this time range
        case when started_at <= p_started_at and ended_at >= p_ended_at then 0 else 1 end,
        -- Then prefer closest by gap distance
        greatest(0, extract(epoch from (p_started_at - ended_at)),
                    extract(epoch from (started_at - p_ended_at)))
    limit 1;

    if found then
        -- Merge into existing row
        update sessions set
            started_at      = least(sessions.started_at, p_started_at),
            ended_at        = greatest(sessions.ended_at, p_ended_at),
            active_duration = sessions.active_duration + p_active_duration,
            lines_added     = sessions.lines_added + p_lines_added,
            lines_removed   = sessions.lines_removed + p_lines_removed,
            files_touched   = greatest(sessions.files_touched, p_files_touched),
            tokens          = sessions.tokens + p_tokens,
            sources         = array(select distinct unnest from unnest(sessions.sources || array[p_source]) order by 1),
            models          = array(select distinct unnest from unnest(sessions.models  || array[p_model])  order by 1),
            repo_alias      = coalesce(sessions.repo_alias, p_repo_alias),
            git_branch      = coalesce(p_git_branch, sessions.git_branch)
        where id = v_existing.id;

        return v_existing.id;
    else
        -- Insert new session
        insert into sessions (id, user_id, started_at, ended_at, active_duration,
            lines_added, lines_removed, files_touched, tokens,
            sources, models, repo_alias, git_branch)
        values (p_id, v_uid, p_started_at, p_ended_at, p_active_duration,
            p_lines_added, p_lines_removed, p_files_touched, p_tokens,
            array[p_source], array[p_model], p_repo_alias, p_git_branch);

        return p_id;
    end if;
end;
$$;

-- Also merge the orphaned May 4th session into the correct one
-- Session 019df455 (18:52-18:54) should be part of 5839fa36 (14:05-19:25)
update sessions
set tokens = tokens + 393654,
    lines_added = lines_added + 9,
    lines_removed = lines_removed + 4,
    active_duration = active_duration + 121,
    sources = array(select distinct unnest from unnest(sources || '{codex}') order by 1)
where id = '5839fa36-1819-4d58-a3e2-c07e8631330f';

delete from sessions where id = '019df455-9666-7fa3-89ed-828e268ded74';
