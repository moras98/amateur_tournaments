-- Tande — lista de espera con promoción automática (Bracket Pro, feature 3)
--
-- Run in the Supabase SQL editor, or with the supabase CLI:
--   supabase db push
--
-- Qué agrega:
--   1. El estado `waitlisted` en `public.inscriptions`.
--   2. La política de insert deja al jugador crear `pending` o `waitlisted`.
--   3. Un trigger que, cuando un cupo confirmado se libera (cancelación del
--      jugador o rechazo del organizador), promueve al más antiguo de la lista
--      de espera a `confirmed`.
--
-- Idempotente: se puede re-ejecutar.

-- 1. Estado nuevo -----------------------------------------------------------
-- El check original se creó inline (Postgres lo nombra inscriptions_status_check).
alter table public.inscriptions drop constraint if exists inscriptions_status_check;
alter table public.inscriptions
  add constraint inscriptions_status_check
  check (status in ('pending', 'waitlisted', 'confirmed', 'rejected', 'cancelled'));

-- Índice para encontrar al primero de la fila sin escanear la tabla.
create index if not exists inscriptions_waitlist_idx
  on public.inscriptions (tournament_id, created_at)
  where status = 'waitlisted';

-- 2. El jugador puede anotarse en la lista de espera ------------------------
drop policy if exists "Players request their own inscriptions" on public.inscriptions;
create policy "Players request their own inscriptions"
  on public.inscriptions for insert
  with check (player_id = auth.uid() and status in ('pending', 'waitlisted'));

-- 3. Promoción automática al liberarse un cupo ------------------------------
-- Corre como security definer porque actualiza la fila de OTRO jugador, cosa
-- que las políticas de UPDATE del organizador no permiten.
--
-- No promueve si el torneo está cerrado: cerrar las inscripciones es una
-- decisión explícita del organizador y meterle gente la contradice.
create or replace function public.promote_from_waitlist()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
  next_id uuid;
begin
  if old.status = 'confirmed' and new.status in ('cancelled', 'rejected') then
    select i.id into next_id
      from public.inscriptions i
      join public.tournaments t on t.id = i.tournament_id
     where i.tournament_id = new.tournament_id
       and i.status = 'waitlisted'
       and t.status <> 'closed'
     order by i.created_at
     limit 1;

    if next_id is not null then
      update public.inscriptions
         set status = 'confirmed',
             confirmed_at = now()
       where id = next_id;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists inscriptions_promote_waitlist on public.inscriptions;
create trigger inscriptions_promote_waitlist
  after update of status on public.inscriptions
  for each row execute function public.promote_from_waitlist();

notify pgrst, 'reload schema';
