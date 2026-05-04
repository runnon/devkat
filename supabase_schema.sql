-- Run this once in your Supabase SQL Editor
-- https://supabase.com/dashboard/project/sbuskyzrwhlqlxxkoozq/sql

create table if not exists sessions (
    id            text primary key,
    user_id       uuid references auth.users not null default auth.uid(),
    started_at    timestamptz not null,
    ended_at      timestamptz not null,
    active_duration float8 not null,
    lines_added   int not null default 0,
    lines_removed int not null default 0,
    files_touched int not null default 0,
    tokens        int not null default 0,
    model         text not null default '',
    repo_alias    text,
    git_branch    text,
    created_at    timestamptz default now()
);

alter table sessions enable row level security;

create policy "Users can read own sessions"
    on sessions for select
    using (auth.uid() = user_id);

create policy "Users can insert own sessions"
    on sessions for insert
    with check (auth.uid() = user_id);

create policy "Users can update own sessions"
    on sessions for update
    using (auth.uid() = user_id);

create index if not exists sessions_user_started on sessions (user_id, started_at desc);
