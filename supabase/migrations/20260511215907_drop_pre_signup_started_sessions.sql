-- Stricter pre-signup cleanup: drop any session whose started_at predates the
-- owning user's account creation. Replaces the prior ended_at-based rule
-- (20260511170752) which preserved sessions straddling the cutoff — those
-- still bleed pre-signup activity into the user's history and are no longer
-- wanted.
--
-- Components attached to such sessions are deleted outright. Surviving
-- components are re-fragmented so any chains that bridged across the cutoff
-- regroup cleanly.

with bad as (
    select s.user_id, s.id
    from sessions s
    join auth.users u on u.id = s.user_id
    where s.started_at < u.created_at
),
del_components as (
    delete from session_components sc
    using bad b
    where sc.user_id = b.user_id
      and sc.session_id = b.id
    returning sc.user_id
),
del_sessions as (
    delete from sessions s
    using bad b
    where s.user_id = b.user_id
      and s.id = b.id
    returning s.user_id
)
select count(*) from del_sessions;

do $$
declare
    r_user uuid;
begin
    for r_user in
        select distinct sc.user_id
        from session_components sc
        join auth.users u on u.id = sc.user_id
    loop
        perform devkat_refragment_user(r_user, null);
    end loop;
end $$;
