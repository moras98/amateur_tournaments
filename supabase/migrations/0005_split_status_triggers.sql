-- Amateur Tournaments — split the open/full sync trigger per table
--
-- Fixes the manual-count write failing with:
--   record "new" has no field "tournament_id" (42703)
--
-- 0003 served BOTH triggers (inscriptions changes and manual-count edits)
-- from one function, branching on `tg_table_name`. That guard cannot work:
-- PL/pgSQL resolves record fields when compiling the expression, so
-- `new.tournament_id` blows up against the `tournaments` rowtype before the
-- CASE branch is ever chosen — i.e. every `manual_confirmed` update aborted.
--
-- One function per row type: no branch ever touches a foreign field.

create or replace function public.sync_inscription_status()
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
         + t.manual_confirmed
         >= t.total_teams
    then 'full'
    else 'open'
  end
  where t.id = coalesce(new.tournament_id, old.tournament_id)
    and t.status in ('open', 'full');
  return coalesce(new, old);
end;
$$;

create or replace function public.sync_manual_status()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  -- Only `status` is written here, so the `update of manual_confirmed`
  -- trigger below never fires from its own body (no recursion).
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
  where t.id = new.id
    and t.status in ('open', 'full');
  return new;
end;
$$;

drop trigger if exists inscriptions_sync_status on public.inscriptions;
create trigger inscriptions_sync_status
  after insert or update of status or delete on public.inscriptions
  for each row execute function public.sync_inscription_status();

drop trigger if exists tournaments_sync_status on public.tournaments;
create trigger tournaments_sync_status
  after update of manual_confirmed on public.tournaments
  for each row execute function public.sync_manual_status();

-- The combined 0003 function is now unused (both triggers were recreated
-- above): drop it so nothing points at the broken body.
drop function if exists public.sync_tournament_status();

notify pgrst, 'reload schema';
