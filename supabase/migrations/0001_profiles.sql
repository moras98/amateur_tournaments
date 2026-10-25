-- Amateur Tournaments — profiles table (phase 2: auth + profile)
--
-- Run in the Supabase SQL editor, or with the supabase CLI:
--   supabase db push
--
-- Later phases add tournaments/inscriptions in follow-up migrations.

create table if not exists public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  username     text unique,
  full_name    text not null default '',
  birth_date   date,
  gender       text not null default '',
  avatar_url   text,
  phone        text,
  is_organizer boolean not null default false,
  sports       text[] not null default '{football}',
  created_at   timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "Profiles are readable by everyone" on public.profiles;
create policy "Profiles are readable by everyone"
  on public.profiles for select
  using (true);

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Creates a profile row automatically on sign-up, carrying the full name
-- passed by the app in the signup metadata.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
