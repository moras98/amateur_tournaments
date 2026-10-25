-- 0006_signup_checks.sql
-- Live "email / username already in use" hints on the sign-up form
-- (debounced 250 ms in the client). Both functions are `security definer`
-- so the anonymous sign-up form can check without reading auth.users or
-- other profiles directly. The real constraints still run at sign-up and
-- profile save — these are best-effort UX only.

create or replace function public.email_taken(p_email text)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from auth.users where lower(email) = lower(p_email)
  );
$$;

create or replace function public.username_taken(
  p_username text,
  p_excluding uuid default null
)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where username = p_username and id is distinct from p_excluding
  );
$$;

grant execute on function public.email_taken(text) to anon, authenticated;
grant execute on function public.username_taken(text, uuid)
  to anon, authenticated;
