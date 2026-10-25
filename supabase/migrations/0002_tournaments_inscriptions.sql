-- Amateur Tournaments — tournaments + inscriptions (phase 5: organizer side)
--
-- Run in the Supabase SQL editor, or with the supabase CLI:
--   supabase db push
--
-- Locations are plain latitude/longitude columns so the schema has no
-- PostGIS dependency (some projects don't have the extension enabled).
-- If server-side distance ordering is ever needed: enable postgis, switch
-- to a `geography (point, 4326)` column + gist index and order by
-- `location <-> point(...)`.

create table if not exists public.tournaments (
  id               uuid primary key default gen_random_uuid(),
  owner_id         uuid not null references public.profiles (id) on delete cascade,
  sport            text not null,
  kind             text not null default 'elimination',
  title            text not null,
  description      text not null default '',
  prizes           text not null default '',
  start_time       timestamptz not null,
  end_time         timestamptz not null,
  inscription_cost numeric not null default 0,
  total_teams      int not null check (total_teams > 0),
  venue_name       text not null default '',
  address          text not null default '',
  city             text not null default '',
  latitude         double precision,
  longitude        double precision,
  status           text not null default 'open'
                   check (status in ('open', 'full', 'closed')),
  created_at       timestamptz not null default now()
);

create index if not exists tournaments_start_time_idx
  on public.tournaments (start_time);
create index if not exists tournaments_sport_idx
  on public.tournaments (sport);

create table if not exists public.inscriptions (
  id           uuid primary key default gen_random_uuid(),
  tournament_id uuid not null references public.tournaments (id) on delete cascade,
  player_id    uuid not null references public.profiles (id) on delete cascade,
  status       text not null default 'pending'
               check (status in ('pending', 'confirmed', 'rejected', 'cancelled')),
  team_name    text not null default '',
  note         text not null default '',
  created_at   timestamptz not null default now(),
  confirmed_at timestamptz,
  unique (tournament_id, player_id)
);

create index if not exists inscriptions_tournament_idx
  on public.inscriptions (tournament_id);
create index if not exists inscriptions_player_idx
  on public.inscriptions (player_id);

-- Confirmed spots per tournament (the app's "spots left" / progress bar).
-- Deliberately *without* `security_invoker`: it exposes only an aggregate and
-- must be readable by everyone, including signed-out explorers.
create or replace view public.spots_left as
select tournament_id, count(*)::int as confirmed_teams
from public.inscriptions
where status = 'confirmed'
group by tournament_id;

-- Keeps `tournaments.status` in sync as the last spots fill or empty.
-- 'closed' is only ever set manually by the organizer.
create or replace function public.sync_tournament_status()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  update public.tournaments t
  set status = case
    when (select count(*)
          from public.inscriptions i
          where i.tournament_id = t.id and i.status = 'confirmed')
         >= t.total_teams
    then 'full'
    else 'open'
  end
  where t.id = coalesce(new.tournament_id, old.tournament_id)
    and t.status in ('open', 'full');
  return coalesce(new, old);
end;
$$;

drop trigger if exists inscriptions_sync_status on public.inscriptions;
create trigger inscriptions_sync_status
  after insert or update of status or delete on public.inscriptions
  for each row execute function public.sync_tournament_status();

-- Row Level Security ----------------------------------------------------

alter table public.tournaments enable row level security;
alter table public.inscriptions enable row level security;

-- Event listings are public.
drop policy if exists "Tournaments are readable by everyone" on public.tournaments;
create policy "Tournaments are readable by everyone"
  on public.tournaments for select
  using (true);

drop policy if exists "Organizers create their own events" on public.tournaments;
create policy "Organizers create their own events"
  on public.tournaments for insert
  with check (auth.uid() = owner_id);

drop policy if exists "Organizers update their own events" on public.tournaments;
create policy "Organizers update their own events"
  on public.tournaments for update
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

drop policy if exists "Organizers delete their own events" on public.tournaments;
create policy "Organizers delete their own events"
  on public.tournaments for delete
  using (auth.uid() = owner_id);

-- A player sees their own inscriptions; an organizer sees the requests for
-- their own events.
drop policy if exists "Inscriptions are visible to player and organizer"
  on public.inscriptions;
create policy "Inscriptions are visible to player and organizer"
  on public.inscriptions for select
  using (
    player_id = auth.uid()
    or exists (
      select 1 from public.tournaments t
      where t.id = tournament_id and t.owner_id = auth.uid()
    )
  );

drop policy if exists "Players request their own inscriptions" on public.inscriptions;
create policy "Players request their own inscriptions"
  on public.inscriptions for insert
  with check (player_id = auth.uid() and status = 'pending');

-- The organizer confirms/rejects (any status).
drop policy if exists "Organizers decide inscriptions" on public.inscriptions;
create policy "Organizers decide inscriptions"
  on public.inscriptions for update
  using (
    exists (
      select 1 from public.tournaments t
      where t.id = tournament_id and t.owner_id = auth.uid()
    )
  );

-- A player may only cancel their own inscription (never self-confirm:
-- the with_check constrains the *new* row).
drop policy if exists "Players cancel their own inscriptions" on public.inscriptions;
create policy "Players cancel their own inscriptions"
  on public.inscriptions for update
  using (player_id = auth.uid())
  with check (player_id = auth.uid() and status = 'cancelled');
