-- Unified sessions: merges overlapping/adjacent sessions (within 30 min gap)
-- across sources into a single work session.
--
-- Uses a recursive CTE to assign a group_id to sessions that overlap or
-- are within 30 minutes of each other. Then aggregates stats per group.

create or replace view unified_sessions as
with ordered as (
    select
        id,
        user_id,
        started_at,
        ended_at,
        active_duration,
        lines_added,
        lines_removed,
        files_touched,
        tokens,
        model,
        repo_alias,
        git_branch,
        source,
        created_at,
        lag(ended_at) over (partition by user_id order by started_at) as prev_ended_at
    from sessions
),
grouped as (
    select *,
        sum(case
            when prev_ended_at is null
                 or started_at > prev_ended_at + interval '30 minutes'
            then 1 else 0
        end) over (partition by user_id order by started_at) as group_id
    from ordered
)
select
    user_id,
    group_id,
    min(started_at) as started_at,
    max(ended_at) as ended_at,
    sum(active_duration) as active_duration,
    sum(lines_added) as lines_added,
    sum(lines_removed) as lines_removed,
    greatest(max(files_touched), 0) as files_touched,
    sum(tokens) as tokens,
    array_agg(distinct source order by source) as sources,
    array_agg(distinct model order by model) as models,
    array_agg(distinct repo_alias order by repo_alias)
        filter (where repo_alias is not null) as repos,
    (array_agg(git_branch order by started_at desc))[1] as git_branch,
    count(*) as raw_session_count,
    min(id) as id,
    min(created_at) as created_at
from grouped
group by user_id, group_id
order by started_at desc;
