-- Amateur Tournaments — off-app confirmed count
--
-- NOTE: the view definition below was later corrected by
-- 0004_spots_left_rows_only.sql (the manual count must NOT be folded into
-- the view — the app adds it on top). Always run the migrations in order.
--
-- NOTE: the combined sync_tournament_status() below was replaced by
-- 0005_split_status_triggers.sql — one function per row type (the
-- `tg_table_name` guard can't protect `new.tournament_id` against the
-- tournaments rowtype; it broke every manual-count update).
--
-- Organizers confirm teams in person / by WhatsApp / cash. Those teams
-- have no inscription row in the app, and the confirmed count is a view
-- over `inscriptions` (read-only), so it couldn't represent them.
-- `manual_confirmed` is the organizer-owned slice of the count: the
-- displayed total becomes (confirmed inscriptions) + (manual count),
-- written only by the owner (`setManualConfirmed` in the app, scoped by
-- the existing "Organizers update their own events" policy).

alter table public.tournaments
  add column if not exists manual_confirmed int not null default 0
  check (manual_confirmed >= 0);

-- Same columns as before (tournament_id, confirmed_teams) so the
-- `spots_left(confirmed_teams)` embed keeps working unchanged. Every
-- tournament now has a row (0 confirmed + manual), and the count adds
-- the manual slice.
create or replace view public.spots_left as
select t.id as tournament_id,
       (select count(*)::int
          from public.inscriptions i
         where i.tournament_id = t.id
           and i.status = 'confirmed')
       + t.manual_confirmed as confirmed_teams
from public.tournaments t;

-- Open/full sync now adds the manual count too, and serves both writers:
-- inscriptions changes (tournament_id on new/old) and manual-count edits
-- (the tournaments row itself, via the trigger below).
create or replace function public.sync_tournament_status()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
  tid uuid;
begin
  tid := case when tg_table_name = 'inscriptions'
              then coalesce(new.tournament_id, old.tournament_id)
              else new.id end;

  update public.tournaments t
  set status = case
    when (select count(*)
            from public.inscriptions i
           where i.tournament_id = t.id and i.status = 'confirmed')
         + t.manual_confirmed
         >= t.total_teams
    then 'full'
    else 'open'
  end
  where t.id = tid
    and t.status in ('open', 'full');
  return coalesce(new, old);
end;
$$;

drop trigger if exists inscriptions_sync_status on public.inscriptions;
create trigger inscriptions_sync_status
  after insert or update of status or delete on public.inscriptions
  for each row execute function public.sync_tournament_status();

drop trigger if exists tournaments_sync_status on public.tournaments;
create trigger tournaments_sync_status
  after update of manual_confirmed on public.tournaments
  for each row execute function public.sync_tournament_status();
