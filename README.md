# Tande

> **Publishing & first users:** see [`LAUNCH.md`](LAUNCH.md) · Store copy in
> [`store/play-store.md`](store/play-store.md), privacy policy in
> [`docs/privacy-policy.md`](docs/privacy-policy.md).

Players discover amateur tournaments near them (map + list — open filtered
to the sports in their profile), contact the
organizer on WhatsApp to coordinate payment off-app, and the organizer
confirms inscriptions so everyone sees the spots left. **No in-app payments.**

Both sides are included in v1: players (explore, register, cancel) and
organizers (create/edit events, confirm/reject requests, search and sort
their events, count teams confirmed off the app, close/reopen/delete).
Confirming or rejecting a request offers a pre-filled WhatsApp message to
notify the player. **The UI follows the phone's locale**: `es*` devices get
Uruguayan Spanish (`es_UY`, the source language of the catalog) and `en*`
devices get English — all copy lives in `lib/l10n/*.arb` (gen-l10n, run
`flutter gen-l10n` after editing an ARB file). Money always renders
Uruguayan-peso style (`$ 25.000`) in every language, and the pre-filled
WhatsApp messages stay Spanish (they're addressed to Uruguayan organizers).

The profile's phone field splits into a country dial code + national
number; the dial code defaults to the device location's country (reverse
geocoded via Nominatim, fallback `+598`) and is stored back as one
international digit string (`59899123456`, no `+`) for `wa.me` links.

Visual design rules live in [`design.md`](design.md); the implementation is
`lib/core/theme/app_theme.dart` (Material 3, brand green, Plus Jakarta Sans,
light + dark). On iOS the app speaks native Cupertino where it corresponds —
alerts, switches, date/time wheels and page transitions
(`lib/core/theme/adaptive.dart`).

## Running

The app runs entirely on repository **mocks** unless Supabase credentials are
passed at build time:

```bash
# Mock mode (demo data, in-memory):
flutter run

# Real backend:
flutter run \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon key>

# Backend + mapas, leyendo .release.env (sin tipear claves; --web abre Chrome):
./scripts/run-local.sh
./scripts/run-local.sh --web
```

Demo logins in mock mode (any password of 6+ characters):

| Email                  | Role                        |
| ---------------------- | --------------------------- |
| `nico@demo.app`        | player                      |
| `el_turco@demo.app`    | organizer (u-org-1)         |
| `mariano@demo.app`     | organizer (u-org-2)         |

The "Continuar con Google" / "Continuar con Apple" buttons ("Continue with
Google" / "Apple" on an English device) sign in the
seeded social demo accounts (`sofia@demo.app`, `martin@demo.app`) — no
browser involved in mock mode.

Sign-up runs in three short steps — **cuenta** (name, email, a secure
password: 8+ characters with an uppercase, a lowercase and a digit,
ticked live under the field), **sobre vos** (username, birth date,
gender) and **¿Qué jugás?** (sports) — so new accounts land in the app
already complete. `/complete-profile` remains for first-time OAuth
sign-ins, the email-confirmation flow and later edits.

## Supabase setup

Run the migrations in order (Supabase SQL editor, or `supabase db push`):

1. `supabase/migrations/0001_profiles.sql` — profiles, RLS, sign-up trigger.
2. `supabase/migrations/0002_tournaments_inscriptions.sql` — tournaments,
   inscriptions, the `spots_left` view, the status-sync trigger and RLS.
3. `supabase/migrations/0003_manual_confirmed.sql` — off-app confirmed
   count (`manual_confirmed`), folded into the status trigger.
4. `supabase/migrations/0004_spots_left_rows_only.sql` — `spots_left`
   counts app inscription rows only (the app adds `manual_confirmed` on
   top) and reloads PostgREST's schema cache.
5. `supabase/migrations/0005_split_status_triggers.sql` — one status-sync
   trigger function per table, fixing the manual-count write failing with
   `record "new" has no field "tournament_id"` (42703).
6. `supabase/migrations/0006_signup_checks.sql` — `email_taken` /
   `username_taken` security-definer functions powering the sign-up form's
   live "already in use" hints (best effort: without them the app just
   skips the hint — sign-up and profile save still enforce uniqueness).
7. `supabase/migrations/0007_signup_metadata.sql` — recreates
   `handle_new_user()` so the sign-up form's metadata (username, birth
   date, gender, sports) reaches `profiles` at account creation — the
   **sign-up data-loss fix** for the confirm-email path.
8. `supabase/migrations/0008_explore_indexes.sql` — indexes behind the
   Explore query: `end_time` (date cut), `latitude`/`longitude` (radius
   box), plus 0002's `start_time` for the 200-row ordered page.
9. `supabase/migrations/0009_currency.sql` — per-tournament `currency`
   (ISO 4217, default `UYU`, CHECK on the 13 offered codes): the event
   form prices each tournament in its own currency.
10. `supabase/migrations/0010_tournament_banners.sql` — optional
    organizer-uploaded banner: `banner_path` on `tournaments`, the public
    `tournament-banners` storage bucket, and owner-scoped upload/delete
    policies keyed on the tournament id folder.

All are idempotent (`if not exists` / `drop policy if exists`) — safe to
re-run. Tournament locations are plain `latitude`/`longitude` columns; **no
PostGIS extension is required**.

### Social login (Google, Apple)

The login screen offers browser-redirect OAuth: the system browser opens
the provider and returns to `io.supabase.amateurtournaments://login-callback`
(declared in `AndroidManifest.xml` and `ios/Runner/Info.plist`; see
`AppConstants.oauthRedirectUrl`). To enable it on a Supabase project:

1. **Google** — Auth → Providers → Google: paste an OAuth client ID and
   client secret from Google Cloud Console (Credentials → OAuth 2.0 Client
   of type *Web application*; enable the Google provider on the OAuth
   consent screen).
2. **Apple** — Auth → Providers → Apple: needs an Apple *Service ID*, a
   Sign in with Apple key (`.p8`) and your Apple team ID. The browser flow
   works without the Xcode capability; Apple requires it only for the
   native SDK flow.
3. Auth → URL Configuration → add
   `io.supabase.amateurtournaments://login-callback` to **Redirect URLs**.

First-time OAuth sign-ins land on `/complete-profile` (the profiles row
starts empty); returning users go straight to their destination.

## Tests

```bash
flutter analyze
flutter test        # 195 tests (11 skipped)
```

Widget tests drive the app through `test/support/harness.dart`
(`appHarness(initialView:, signedIn:, withLocation:, locationOverride:,
signedInAs:, reverseCountryCode:)`) with fake map tiles and a mocked URL
launcher. The harness pins the simulated device to `es_UY` (both
`localeTestValue` and `localesTestValue` — `Localizations` resolves from the
plural list), so assertions see the Spanish copy; `test/locale_test.dart`
switches to English with `pinTestLocale` to cover the other language.

## App icon & splash

Icons are generated from `assets/icon.png` / `assets/icon_fg.png`
(brand color `#1B8A5A`). After changing them:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Project structure

```
lib/
  core/        # constants, theme, router, map tiles, formatting, location
  data/        # repositories: abstract + mock + supabase, auth
  features/    # explore, tournament, inscriptions, organizer, auth, profile
  l10n/        # ARB catalogs (es_UY source + en), labels.dart, generated/
  models/      # tournament, inscription, user
```

State management is Riverpod; navigation is go_router (bottom-nav shell:
Explore · My inscriptions · Organize · Profile).
