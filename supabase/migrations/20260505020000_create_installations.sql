-- Tracks Mac clients (Claude / Codex / Cursor hosts) that have run the
-- devkat-push installer for each user. The iOS app uses the existence of
-- a row to distinguish "never set up" from "set up, waiting for a session".

create table if not exists installations (
    id            uuid        primary key default gen_random_uuid(),
    user_id       uuid        references auth.users on delete cascade not null default auth.uid(),
    hostname      text        not null,
    installed_at  timestamptz not null default now(),
    last_seen_at  timestamptz not null default now(),
    unique (user_id, hostname)
);

alter table installations enable row level security;

create policy "Users can read own installations"
    on installations for select
    using (auth.uid() = user_id);

create index if not exists installations_user
    on installations (user_id, last_seen_at desc);

-- Upsert from the CLI: insert on first install, bump last_seen_at on every
-- subsequent push. SECURITY DEFINER bypasses the lack of an insert/update
-- policy; auth.uid() is read from the JWT, so each user can only touch
-- their own row.
create or replace function upsert_installation(p_hostname text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    if auth.uid() is null then
        raise exception 'not authenticated';
    end if;

    insert into installations (user_id, hostname)
    values (auth.uid(), p_hostname)
    on conflict (user_id, hostname) do update
        set last_seen_at = now();
end;
$$;

revoke all on function upsert_installation(text) from public;
grant execute on function upsert_installation(text) to authenticated;
