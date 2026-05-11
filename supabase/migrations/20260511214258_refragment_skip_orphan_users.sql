-- The recovery in 20260511211523 ran devkat_refragment_user for every user_id
-- in session_components, but at least one of those users was already deleted
-- from auth.users — leaving orphan components. Upserting a sessions row for
-- the orphan tripped sessions_user_id_fkey and aborted the migration.
--
-- Drop the orphan components, then re-run the recovery for the users that
-- still exist.

delete from session_components sc
where not exists (
    select 1 from auth.users u where u.id = sc.user_id
);

delete from sessions s
where not exists (
    select 1 from auth.users u where u.id = s.user_id
);

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
