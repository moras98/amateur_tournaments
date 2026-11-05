-- 0014_profile_privacy.sql — dejar de exponer datos personales de todos.
--
-- Antes: `profiles` tenía una política SELECT `using (true)`, así que la
-- anon key (que viaja dentro del APK y es pública por diseño) podía leer
-- todas las columnas de todos los perfiles: teléfono, fecha de nacimiento
-- y género incluidos. Con la app publicada eso es cosecha de teléfonos y
-- un problema directo bajo la Ley 18.331 y el formulario Data Safety.
--
-- Después:
--   1. `profiles` sólo lo lee su dueño (`auth.uid() = id`).
--   2. `public_profiles` expone sólo los datos de un organizador que
--      efectivamente tiene torneos: nombre, usuario, avatar, deportes y
--      sus canales de contacto. Nunca fecha de nacimiento ni género, y
--      nunca el teléfono de un jugador que no organiza.
--   3. `inscription_player_contacts(tournament_id)` es la única vía por la
--      que el organizador ve el contacto de los jugadores anotados en SUS
--      torneos (la pantalla de solicitudes y el CSV).
--
-- La app usa `profiles` para el perfil propio y `public_profiles` para el
-- organizador de un torneo. Idempotente.

-- 1) El perfil completo vuelve a ser privado --------------------------------
drop policy if exists "Profiles are readable by everyone" on public.profiles;
drop policy if exists "Users can read own profile" on public.profiles;
create policy "Users can read own profile"
  on public.profiles for select
  using (auth.uid() = id);

-- El look-up público pregunta "¿este perfil organiza algo?" y la lista de
-- eventos del organizador filtra por owner_id: sin este índice ambos hacen
-- un scan de tournaments.
create index if not exists tournaments_owner_id_idx
  on public.tournaments (owner_id);

-- 2) Proyección pública: sólo organizadores con torneos ---------------------
-- La vista corre con los privilegios de su dueño (Postgres), así que puede
-- leer `profiles` sin RLS; por eso el WHERE es la frontera de privacidad y
-- las columnas son deliberadamente pocas. `security_invoker = false` es el
-- default en Postgres 15+ y es intencional: el que consulta no tiene (ni
-- debe tener) SELECT sobre `profiles`.
create or replace view public.public_profiles as
select
  p.id,
  p.username,
  p.full_name,
  p.avatar_url,
  p.is_organizer,
  p.sports,
  p.phone,
  p.instagram,
  p.telegram,
  p.contact_url
from public.profiles p
where exists (
  select 1
  from public.tournaments t
  where t.owner_id = p.id
);

comment on view public.public_profiles is
  'Datos públicos de organizadores con torneos: sin birth_date ni gender. '
  'Los jugadores que no organizan no aparecen acá.';

revoke all on public.public_profiles from public;
grant select on public.public_profiles to anon, authenticated;

-- 3) Contacto de los jugadores para el organizador del torneo --------------
-- SECURITY DEFINER porque el organizador no puede leer la fila privada del
-- jugador. La autorización está en el WHERE: sólo devuelve filas si el que
-- llama es dueño del torneo. Un jugador puede ver su propio contacto en sus
-- inscripciones, pero no el de los demás.
create or replace function public.inscription_player_contacts(
  p_tournament_id uuid
)
returns table (
  player_id uuid,
  username text,
  full_name text,
  avatar_url text,
  phone text,
  instagram text,
  telegram text,
  contact_url text,
  sports text[]
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    p.id,
    p.username,
    p.full_name,
    p.avatar_url,
    p.phone,
    p.instagram,
    p.telegram,
    p.contact_url,
    p.sports
  from public.inscriptions i
  join public.profiles p on p.id = i.player_id
  where i.tournament_id = p_tournament_id
    and (
      exists (
        select 1
        from public.tournaments t
        where t.id = i.tournament_id
          and t.owner_id = auth.uid()
      )
      or i.player_id = auth.uid()
    );
$$;

revoke execute on function public.inscription_player_contacts(uuid)
  from public, anon;
grant execute on function public.inscription_player_contacts(uuid)
  to authenticated;

comment on function public.inscription_player_contacts(uuid) is
  'Canales de contacto de los jugadores anotados en un torneo. Sólo el '
  'organizador dueño (o el propio jugador) puede leerlos.';

-- PostgREST cachea el esquema: la vista y la función tienen que aparecer ya.
notify pgrst, 'reload schema';
