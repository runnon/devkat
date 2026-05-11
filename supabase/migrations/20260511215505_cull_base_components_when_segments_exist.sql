-- Real cause of the over-merge: the on-disk parsers were pushing both a "base"
-- component (`<uuid>`) AND its segmented children (`<uuid>_seg0`, `_seg1`, ...)
-- for the same source session. The base spans the union of all segments — for
-- a long-lived Cursor composer that's a continuous 6.7-day bridge — which not
-- only double-counts tokens/activity but also defeats the 4h-gap chain rule by
-- never having an internal gap.
--
-- Drop every base component whenever any `<base>_seg%` sibling exists for the
-- same user, then re-fragment.

delete from session_components sc
where exists (
    select 1
    from session_components seg
    where seg.user_id = sc.user_id
      and seg.source  = sc.source
      and seg.source_session_id like sc.source_session_id || '\_seg%' escape '\'
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
