-- 0007_signup_metadata.sql
--
-- Bug fix: with "Confirm email" on (Supabase's default) signUp returns no
-- session, so the app never gets to save the profile itself. The 3-step
-- sign-up form collects username, birth date, gender and sports on top of
-- the name — but only `full_name` rode along in raw_user_meta_data, so
-- handle_new_user() (0001) dropped everything else and the user retyped
-- the whole form after confirming the email.
--
-- Recreates handle_new_user() to copy the whole form from the signup
-- metadata (the app sends it with every signUp since the fix). The
-- trigger runs on the auth.users INSERT — i.e. at sign-up time, before
-- any confirmation — so both paths (confirmation on/off) land a complete
-- profile.
--
-- Then backfills accounts created by the fixed app before this migration
-- was applied: the metadata still carries the fields, only the profile
-- row lost them. Backfill only fills blanks — it never overwrites what
-- the user already re-entered.
--
-- Apply manually (like 0005/0006): Supabase SQL editor or `supabase db push`.
-- Idempotent: `create or replace` + blanks-only backfill.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
  v_username  text;
  v_full_name text;
  v_gender    text;
  v_birth     date;
  v_sports    text[] := '{football}';
  v_sports_js jsonb;
begin
  v_username  := nullif(trim(new.raw_user_meta_data ->> 'username'), '');
  v_full_name := coalesce(new.raw_user_meta_data ->> 'full_name', '');
  v_gender    := coalesce(new.raw_user_meta_data ->> 'gender', '');
  v_sports_js := new.raw_user_meta_data -> 'sports';

  -- birth_date travels as DateTime.toIso8601String(). Metadata is
  -- client-written: a malformed value drops the date instead of failing
  -- account creation (the completion banner then asks for it again).
  begin
    v_birth := (new.raw_user_meta_data ->> 'birth_date')::date;
  exception when others then
    v_birth := null;
  end;

  -- sports: JSON array of the chosen disciplines. Anything else keeps
  -- the column default (football), like the pre-metadata behaviour.
  if jsonb_typeof(v_sports_js) = 'array' then
    select coalesce(array_agg(value), '{football}')
      into v_sports
      from jsonb_array_elements_text(v_sports_js);
  end if;

  begin
    insert into public.profiles
      (id, username, full_name, birth_date, gender, sports)
    values (new.id, v_username, v_full_name, v_birth, v_gender, v_sports)
    on conflict (id) do nothing;
  exception
    when unique_violation then
      -- profiles.username raced away between the form's live check and
      -- sign-up: keep the account and every other field — only the handle
      -- goes missing (the completion banner asks for a new one). Never
      -- fail account creation over it.
      insert into public.profiles
        (id, username, full_name, birth_date, gender, sports)
      values (new.id, null, v_full_name, v_birth, v_gender, v_sports)
      on conflict (id) do nothing;
  end;
  return new;
end;
$$;

-- Backfill: accounts created while the app already sent the metadata but
-- the old trigger (0001) still ran. Per-field, blanks only; each statement
-- carries its own error guard (metadata is client-written) so one bad
-- account can't break the migration.
do $$
begin
  -- username: skip handles that got taken meanwhile (unique constraint).
  begin
    update public.profiles p
    set username = nullif(trim(u.raw_user_meta_data ->> 'username'), '')
    from auth.users u
    where u.id = p.id
      and p.username is null
      and nullif(trim(u.raw_user_meta_data ->> 'username'), '') is not null
      and not exists (
        select 1 from public.profiles x
        where x.username = nullif(trim(u.raw_user_meta_data ->> 'username'), '')
      );
  exception when others then
    raise notice '0007 backfill username skipped: %', sqlerrm;
  end;

  -- birth_date: only when never set, and only date-shaped values.
  begin
    update public.profiles p
    set birth_date = (u.raw_user_meta_data ->> 'birth_date')::date
    from auth.users u
    where u.id = p.id
      and p.birth_date is null
      and (u.raw_user_meta_data ->> 'birth_date')
          ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}';
  exception when others then
    raise notice '0007 backfill birth_date skipped: %', sqlerrm;
  end;

  -- gender: only when empty.
  begin
    update public.profiles p
    set gender = nullif(u.raw_user_meta_data ->> 'gender', '')
    from auth.users u
    where u.id = p.id
      and p.gender = ''
      and nullif(u.raw_user_meta_data ->> 'gender', '') is not null;
  exception when others then
    raise notice '0007 backfill gender skipped: %', sqlerrm;
  end;

  -- sports: the column default is football, so a default row plus metadata
  -- means "the choices were lost" — unless the user really only picked
  -- football, in which case this writes the identical value (a no-op).
  begin
    update public.profiles p
    set sports = (
      select coalesce(array_agg(value), '{football}'::text[])
      from jsonb_array_elements_text(u.raw_user_meta_data -> 'sports')
    )
    from auth.users u
    where u.id = p.id
      and p.sports = '{football}'
      and jsonb_typeof(u.raw_user_meta_data -> 'sports') = 'array'
      and jsonb_array_length(u.raw_user_meta_data -> 'sports') > 0;
  exception when others then
    raise notice '0007 backfill sports skipped: %', sqlerrm;
  end;
end $$;
