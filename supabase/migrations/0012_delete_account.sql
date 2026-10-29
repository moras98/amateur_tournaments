-- 0012_delete_account.sql — eliminar la cuenta desde dentro de la app.
--
-- Requisito de las dos tiendas: la guía 5.1.1(v) de App Store exige un
-- flujo de borrado *dentro* de la app cuando hay registro (no alcanza con
-- un link web), y la política de cuenta de Google Play pide lo mismo. El
-- flujo vive en Perfil → "Eliminar cuenta" (doble confirmación) y llama a
-- esta función; la app sólo se encarga de presentarlo.
--
-- Borrar la fila de auth.users es lo que realmente borra la cuenta: las
-- claves foráneas con `on delete cascade` (0001 y 0002) arrastran
-- profiles, tournaments (owner_id), inscriptions (player_id) y todo lo que
-- cuelga de esas tablas. El banner del storage no cuelga de ninguna tabla
-- (es un objeto en un bucket público): lo limpia la app, antes de llamar,
-- como mejor esfuerzo.
--
-- `security definer` porque auth.users sólo admite escritura del owner del
-- schema (el rol postgres). Se revoca a PUBLIC/anon y se otorga únicamente
-- a authenticated: sin sesión no se borra nada, y con sesión cada cual sólo
-- puede borrar la propia.

create or replace function public.delete_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'No hay una sesión activa.' using errcode = '42501';
  end if;

  delete from auth.users where id = uid;
end;
$$;

revoke execute on function public.delete_account() from public, anon;
grant execute on function public.delete_account() to authenticated;

comment on function public.delete_account() is
  'Borra la cuenta del usuario autenticado (y, por cascade, todos sus datos).';
