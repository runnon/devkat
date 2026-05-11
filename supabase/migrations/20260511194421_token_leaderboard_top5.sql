-- Bump the leaderboard RPC from top-3 to top-5. The iOS home strip now
-- horizontally scrolls through positions 1–5 (only the first three get
-- the lion/leopard/cat emoji).

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
    limit 5;
$$;
