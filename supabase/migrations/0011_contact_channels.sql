-- Contact channels beyond the phone: Instagram, Telegram and a free-form link
-- (a Google Form, a spreadsheet, the club's site).
--
-- The app normalises before writing (bare handle, https scheme) and the DB
-- bounds what can come in through any other client. Lengths are generous but
-- finite: these strings are rendered in lists and sheets.
--
-- Existing rows get '' (not null), so `hasContactChannels` needs no null
-- handling and older clients keep working untouched.

alter table public.profiles
  add column if not exists instagram text not null default '',
  add column if not exists telegram text not null default '',
  add column if not exists contact_url text not null default '';

alter table public.profiles
  drop constraint if exists profiles_instagram_len,
  add constraint profiles_instagram_len
    check (char_length(instagram) <= 40),
  drop constraint if exists profiles_telegram_len,
  add constraint profiles_telegram_len
    check (char_length(telegram) <= 40),
  drop constraint if exists profiles_contact_url_len,
  add constraint profiles_contact_url_len
    check (char_length(contact_url) <= 500),
  -- A bare "forms.gle/..." would never open: the launcher only takes absolute
  -- URLs, so the column refuses anything without a scheme.
  drop constraint if exists profiles_contact_url_scheme,
  add constraint profiles_contact_url_scheme
    check (contact_url = '' or contact_url ~* '^https?://');

comment on column public.profiles.instagram is
  'Instagram handle, no @ (normalised by the app).';
comment on column public.profiles.telegram is
  'Telegram username, no @ (normalised by the app).';
comment on column public.profiles.contact_url is
  'Extra way to reach or sign up: Google Form, spreadsheet, club site. Absolute URL.';
