-- Amateur Tournaments — spots_left counts app rows only (+ schema reload)
--
-- Fixes two things left by 0003:
--   1) The view folded `manual_confirmed` into `confirmed_teams`, but the
--      app already adds it on top (TournamentModel.totalConfirmed) —
--      every off-app confirmation counted twice. The view now counts
--      confirmed *inscription rows* only; the model composes the total.
--   2) Every tournament gets a row (zero confirmed included), so a
--      missing row is never ambiguous.
--
-- `notify pgrst, 'reload schema'` refreshes PostgREST's schema cache even
-- when the migration ran through psql/`supabase db push`; a stale cache
-- surfaces as PGRST200 "Could not find a relationship ..." errors.

create or replace view public.spots_left as
select t.id as tournament_id,
       (select count(*)::int
          from public.inscriptions i
         where i.tournament_id = t.id
           and i.status = 'confirmed') as confirmed_teams
from public.tournaments t;

notify pgrst, 'reload schema';
