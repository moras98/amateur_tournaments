-- Amateur Tournaments — indexes for the Explore query (audit 4.8)
--
-- Run in the Supabase SQL editor, or with the supabase CLI:
--   supabase db push
--
-- `SupabaseTournamentRepository.fetchTournaments` now asks PostgREST for:
--
--   where  end_time >= now()
--      [and latitude  between :lat_min and :lat_max]   ← radius box
--      [and longitude between :lon_min and :lon_max]
--   order  by start_time                                ← index from 0002
--   limit  200
--
-- Each new predicate gets its own btree so the planner can combine them
-- (bitmap AND). Without them the filter degrades to a sequential scan as
-- the table grows — and PostgREST cuts any response at 1000 rows, so the
-- "nearby" screen would silently show an arbitrary slice of the table.

-- Events still running or upcoming (Explore's main predicate).
create index if not exists tournaments_end_time_idx
  on public.tournaments (end_time);

-- The radius pre-filter box (lat and lon ranges are independent, so two
-- single-column indexes beat one composite here).
create index if not exists tournaments_latitude_idx
  on public.tournaments (latitude);

create index if not exists tournaments_longitude_idx
  on public.tournaments (longitude);
