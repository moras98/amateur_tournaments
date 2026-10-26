-- Amateur Tournaments — per-tournament currency (audit 4.9)
--
-- Run in the Supabase SQL editor, or with the supabase CLI:
--   supabase db push
--
-- The event form now sends a `currency` (ISO 4217) with every create/
-- update, defaulting to the device region's currency — the home market's
-- UYU for existing rows and any write that predates the column. `CHECK`
-- keeps only the currencies the app offers (country_code.dart).
--
-- The model reads a missing column as UYU too, so the column can be added
-- before or after the app ships.

alter table public.tournaments
  add column if not exists currency text not null default 'UYU';

-- The app offers UYU, ARS, BOB, BRL, CLP, COP, EUR, USD, MXN, PYG, PEN,
-- GBP and VES. `country_code.dart` keeps the canonical list; this guard
-- rejects anything else at the door (a bad value would render as a bare
-- ISO code in every card otherwise).
alter table public.tournaments
  drop constraint if exists tournaments_currency_check;

alter table public.tournaments
  add constraint tournaments_currency_check
  check (currency in (
    'UYU', 'ARS', 'BOB', 'BRL', 'CLP', 'COP', 'EUR', 'USD',
    'MXN', 'PYG', 'PEN', 'GBP', 'VES'
  ));
