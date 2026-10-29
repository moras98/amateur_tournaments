-- 0013_no_oversell.sql — la base no permite sobrevender el cupo.
--
-- Hasta ahora el cupo sólo lo frenaba la UI (event_requests_screen y el
-- form del evento): dos dispositivos confirmando a la vez — o una
-- pantalla desactualizada — podían llevar confirmed + manual_confirmed más
-- allá de total_teams. El trigger de sync (0005) marcaba el torneo `full`
-- pero no revirtía ni avisaba: la sobreventa quedaba guardada.
--
-- Tres guardas, una por camino de escritura, todas con mensaje en español
-- (la app lo muestra tal cual):
--
--   1. Confirmar una inscripción (BEFORE INSERT / UPDATE OF status) sólo
--      pasa si hay un cupo libre. Se serializa contra otras confirmaciones
--      con un `for update` sobre la fila del torneo ANTES de contar: dos
--      transacciones simultáneas no pueden leer el mismo cupo vacío.
--   2. Subir manual_confirmed (BEFORE UPDATE OF manual_confirmed) sólo
--      pasa si entra en el cupo.
--   3. Bajar total_teams (BEFORE UPDATE OF total_teams) no puede dejar
--      confirmados por encima del nuevo tope (el form ya lo frenaba con
--      capBelowConfirmed; esto es la misma regla en la base).
--
-- `security definer` + `set search_path = ''` como en 0005/0007: el conteo
-- tiene que ver TODAS las inscripciones del torneo aunque el que dispara
-- el trigger sólo vea las suyas (la RLS de inscriptions es por jugador y
-- organizador, 0002), y el guard no depende del rol que llame.
--
-- No toca la lista de espera: la promoción (0007) se dispara cuando un
-- cupo se acaba de liberar, así que pasa el conteo igual. Un error acá
-- aborta la confirmación — nunca deja la fila escrita.

-- 1) Confirmación de inscripción ------------------------------------------------
create or replace function public.enforce_cap_on_inscription()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  cap int;
  taken int;
begin
  if new.status <> 'confirmed'
     or (tg_op = 'UPDATE' and old.status = 'confirmed') then
    return new;
  end if;

  -- Serializa contra cualquier otra escritura de cupo del mismo torneo.
  -- Se hace en una sentencia propia para que el conteo de abajo corra con
  -- un snapshot fresco (READ COMMITTED: una sentencia nueva ve lo que
  -- commitó la transacción que acaba de soltar el lock).
  perform 1
    from public.tournaments t
   where t.id = new.tournament_id
     for update;

  if not found then
    return new; -- el torneo se fue en el medio: no hay cupo que frenar
  end if;

  select t.total_teams
    into cap
    from public.tournaments t
   where t.id = new.tournament_id;

  select count(*)
    into taken
    from public.inscriptions i
   where i.tournament_id = new.tournament_id
     and i.status = 'confirmed'
     and i.id <> new.id;

  if taken >= cap then
    raise exception 'El torneo ya no tiene cupo libre (confirmados: %, cupo: %).',
      taken + 1, cap
      using errcode = 'NOSPT';
  end if;

  return new;
end;
$$;

drop trigger if exists inscriptions_cap_guard on public.inscriptions;
create trigger inscriptions_cap_guard
  before insert or update of status on public.inscriptions
  for each row execute function public.enforce_cap_on_inscription();

-- 2) Confirmados fuera de la app ------------------------------------------------
create or replace function public.enforce_cap_on_manual()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  taken int;
begin
  if new.manual_confirmed <= old.manual_confirmed then
    return new;
  end if;

  select count(*)
    into taken
    from public.inscriptions i
   where i.tournament_id = new.id
     and i.status = 'confirmed';

  if taken + new.manual_confirmed > new.total_teams then
    raise exception 'El torneo ya no tiene cupo libre (confirmados: %, cupo: %).',
      taken + new.manual_confirmed, new.total_teams
      using errcode = 'NOSPT';
  end if;

  return new;
end;
$$;

drop trigger if exists tournaments_manual_cap_guard on public.tournaments;
create trigger tournaments_manual_cap_guard
  before update of manual_confirmed on public.tournaments
  for each row execute function public.enforce_cap_on_manual();

-- 3) Bajar el cupo por debajo de los confirmados --------------------------------
create or replace function public.enforce_cap_on_lowering()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  taken int;
begin
  if new.total_teams >= old.total_teams then
    return new;
  end if;

  select count(*)
    into taken
    from public.inscriptions i
   where i.tournament_id = new.id
     and i.status = 'confirmed';

  if taken + new.manual_confirmed > new.total_teams then
    raise exception 'No podés bajar el cupo: ya tenés % equipos confirmados.',
      taken + new.manual_confirmed
      using errcode = 'NOSPT';
  end if;

  return new;
end;
$$;

drop trigger if exists tournaments_lower_cap_guard on public.tournaments;
create trigger tournaments_lower_cap_guard
  before update of total_teams on public.tournaments
  for each row execute function public.enforce_cap_on_lowering();
