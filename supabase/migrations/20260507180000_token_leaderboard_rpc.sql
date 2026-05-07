-- Top-3 token leaderboard. Aggregates total tokens across all users.
-- Returns email + total_tokens for the top 3 token-burners (tokens > 0).
-- Runs as security definer so it can read across all users' sessions
-- regardless of RLS.

create or replace function token_leaderboard()
returns table(email text, total_tokens bigint)
language sql
security definer
set search_path = public, auth
as $$
    select
        au.email::text,
        coalesce(sum(s.tokens), 0)::bigint as total_tokens
    from auth.users au
    join public.sessions s on s.user_id = au.id
    group by au.email
    having coalesce(sum(s.tokens), 0) > 0
    order by total_tokens desc
    limit 3;
$$;

revoke all on function token_leaderboard() from public;
grant execute on function token_leaderboard() to authenticated;
