# LAUNCH — publish Tande and get the first users

Working checklist. Update the boxes as you go. Base market: **Uruguay**.

> **Leer antes de seguir:** [`PLAN-PUBLICACION.md`](PLAN-PUBLICACION.md) — auditoría verificada
> (26/10/2026), bloqueantes por tienda (iOS incluido), bug de pérdida de datos en el registro,
> plan de publicación por fases, plan de marketing y modelo económico con escenarios.
>
> Dos cosas de este archivo quedaron desactualizadas y el plan las corrige: (1) el checklist
> asume sólo Android — iOS es obligatorio si querés App Store y su camino no necesita Mac;
> (2) §6 dice que la app "ya comparte el cuadro por WhatsApp": no comparte nada, y los cuadros
> tampoco existen.

## Current state

| Item | Status |
|---|---|
| App build | ✅ analyze clean, **154/154 tests**, `1.0.0+1` |
| Application ID | ✅ `com.tande.app` (permanent — never change after publish) |
| Git | ✅ 5 commits, secrets gitignored |
| Upload keystore | ✅ `~/upload-keystore.jks` + `android/key.properties` |
| Store AAB script | ✅ `scripts/build-release.sh` |
| Store copy | ✅ `store/play-store.md` |
| Legal docs | 📝 drafts — contact email filled (`a.morascastro@gmail.com`), still needs public URL |
| Monetization | ✅ built, **inert** until Play products exist — launch after first users (§7) |
| Supabase anon key in `.release.env` | ✅ filled — real-backend release AAB built (62.1 MB) |
| Migrations `0005` … `0013` applied | ✅ `delete_account` RPC live in prod (verified: 42501 anon) |
| Auth email links (confirm + reset) | ⬜ dashboard allow-list + templates |
| Play Console account | ⬜ |
| Closed test (14 days) | ⬜ |

---

## 1. Do now (unblock everything else)

- [ ] **Back up the keystore + password**: `~/upload-keystore.jks` and the
      `storePassword` in `android/key.properties` → password manager.
      (Losing both = Google upload-key reset process.)
- [x] **Paste the Supabase anon key** into `.release.env` (done; smoke test against
      production: `GET /rest/v1/tournaments` → HTTP 200).
- [ ] **Confirm migrations `0005_split_status_triggers.sql`,
      `0006_signup_checks.sql`, `0007_signup_metadata.sql`,
      `0008_explore_indexes.sql`, `0009_currency.sql`,
      `0010_tournament_banners.sql`, `0011_contact_channels.sql`,
      `0012_delete_account.sql` and `0013_no_oversell.sql`** are
      applied in the Supabase
      dashboard. **`0007` is the sign-up data-loss fix** —
      until it runs, the confirm-email path keeps dropping username /
      birth date / gender / sports (the app already sends them in the
      metadata). `0008` indexes the Explore query (date cut, radius box,
      200-row page); `0009` adds the per-tournament `currency` column
      (default `UYU`, CHECK on the offered codes). **`0012` is the
      in-app account-deletion RPC** (both stores require it: App Store
      5.1.1(v) / Play account-deletion policy) — the Profile screen's
      "Eliminar cuenta" button calls it and fails politely until the
      migration runs. `0013` blocks overselling spots when two players
      confirm at the same instant.
- [ ] **Auth email links land in the app** (dashboard, Authentication):
      URL Configuration → Redirect URLs must list
      `io.supabase.amateurtournaments://login-callback` (it should already
      be there for OAuth — confirm), and the *Confirm signup* / *Reset
      password* templates must link through `{{ .ConfirmationURL }}` (the
      Supabase defaults do). The app now passes `emailRedirectTo` on
      sign-up and on password reset; without the allow-list entry GoTrue
      falls back to the Site URL and the link opens a web page instead of
      the app.
- [ ] **Real-backend smoke test on your phone**: install a release build with
      the Supabase defines, then sign up → create tournament → request
      inscription → share to WhatsApp → see it appear. Mock tests prove
      nothing about the Supabase repositories.
- [x] **Mapa vectorial** (ver §Mapas): OpenFreeMap, sin clave ni costo, con
      estilos propios claro/oscuro y sin íconos de POI. El raster quedó como
      fallback (`--dart-define=BASEMAP=raster`).
- [ ] **Create the Google Play developer account** ($25 + identity
      verification). Personal account ⇒ the 14-day closed-test clock applies
      to you. Start today so verification runs in parallel.

## 2. Build the shippable AAB

```bash
# after filling .release.env:
./scripts/build-release.sh
# → build/app/outputs/bundle/release/app-release.aab
# (runs gen-l10n + 140 tests, signs with the upload key, prints the signer)
```

- [ ] `.release.env` filled (never commit it — it's gitignored)
- [ ] Script finishes and signer shows `CN=Tande, OU=Tande, O=Tande, L=Montevideo, C=UY`
- [ ] Re-run the on-device smoke test with **this exact AAB's** build

> The AAB already in `build/` was built with a placeholder key for pipeline
> verification — **do not upload it**. Always produce the store build with the
> script.

## 3. Play Console listing

- [ ] **App identity**: name `Tande`, application ID `com.tande.app`
      (autofills from the AAB), version `1.0.0+1`.
- [ ] **Legal docs**: contact email is filled (`a.morascastro@gmail.com`) —
      publish both docs (GitHub Pages on this repo is fine), paste the privacy URL into Play Console, then point
      `AppConstants.privacyUrl` / `AppConstants.termsUrl`
      (`lib/core/constants.dart`) at the final URLs — the sign-up checkbox
      and the login fine print open them in the browser.
- [ ] **Data safety form** (must match the policy):
      - Collected: **name, email, profile photo (from Google/Apple), date of
        birth, gender, phone (optional), approximate/precise location
        (optional), user-generated tournaments/inscriptions**
      - Used for app functionality · **not sold** · **not used for ads**
      - Shared: Supabase (backend), Google/Apple (login), OpenStreetMap (maps)
- [ ] **Content rating** questionnaire (IARC) — sports/organizing tool, no
      violence, no in-app chat between strangers beyond tournament info.
- [ ] **App access**: give reviewers a working login (demo account with a
      seeded tournament, or leave mocks out of the release build — release
      ships Supabase, so create a real reviewer account).
- [ ] **Target audience**: 13+ (matches the privacy policy).
- [ ] **Graphics**:
      - Feature graphic 1024×500 (fondo blanco, cresta verde `#1B8A5A` /
        `#2FB56A` + wordmark, "Tu torneo empieza acá")
      - ≥ 2 phone screenshots (emulator or the YAL L21): mapa en Explore,
        lista filtrada, detalle del torneo, inscripción — UI en **es**
- [ ] **Copy** from `store/play-store.md`: título (26), descripción corta (77),
      descripción larga, keywords de App Store. Ya está reescrita para decir sólo
      lo que la app hace.

## 4. The 14-day clock (personal accounts, created after Nov 2023)

Google requires **12 opted-in testers × 14 continuous days** on a *closed
testing* track before production access. Internal testing does **not** count.

- [ ] Create **Closed testing** track, upload the AAB from step 2
- [ ] Choose the test countries (include Uruguay at minimum)
- [ ] Invite **15 testers** (not 12 — if someone drops below 12 the clock
      resets). Real Google accounts, physical devices. Sources: friends,
      family, the organizers you onboard, a paid tester service if needed
- [ ] **Every tester must opt in via the link AND open the app daily** for 14
      unbroken days — track them with a WhatsApp group reminder
- [ ] Day 15: **apply for production access** (dashboard questionnaire —
      answer with real numbers: 140 automated tests + on-device manual QA)

## 5. Production

- [ ] Production track with a **staged rollout** (20% → 50% → 100%)
- [ ] Watch Android vitals (crash-free rate) + Supabase logs the first week
- [ ] Reply to every Play Store review early — it ranks you

## 6. Get users (start in parallel with step 4 — this is the hard part)

The app is a marketplace: **organizers are the supply, players the demand**.
An empty tournament list = a dead app.

- [ ] **Land 2–3 real Montevideo tournaments before launch.** Offer free
      white-glove setup ("armo tu torneo, no pagás nada"). Each organizer
      brings their whole roster — that's your launch audience
- [ ] **WhatsApp**: por ahora la app abre el chat del organizador con el mensaje
      ya escrito; **todavía no se puede compartir el evento** (§4.10-c del plan) —
      hasta que exista, el link lo pegás vos en cada grupo
- [ ] **Facebook groups**: Montevideo amateur football / pádel / "busco
      equipo" groups are where your exact audience already is
- [ ] **Instagram Reels**: 15 s screen recording — "armás tu torneo en 30
      segundos"; hashtags `#futbol5 #montevideo #padel #torneo`
- [ ] **Venues**: one poster with a QR code per fútbol‑5 complex and padel
      club (padel is booming — they want visibility)
- [ ] **ASO**: keep `Tande + torneos` together in the title; re-check the
      keyword list in `store/play-store.md` after the first weeks of search
      impressions

## 7. Monetization — "Tande Pro" (only after real users)

Decision: **organizer-side subscription**; players never pay. Ads rejected —
UY CPMs are tiny and AdMob would force privacy/data-safety churn before
launch. Entry-fee commission rejected — "ningún pago se realiza dentro de la
app" (terms §1) is a selling point, and taking a cut would need Play Billing
+ local payment rails. Everything ships **100% free through production and
the closed test** — never gate the 12 testers.

- [ ] **Trigger**: a handful of organizers running repeat tournaments (or one
      asking for exports / limits lifted) → then turn Pro on. No users yet =
      no product to charge for.
- [ ] **Free tier stays generous**: everything a player does is free forever;
      organizers get 2 active tournaments in parallel
      (`AppConstants.freeActiveTournaments = 2`): a Saturday league plus a
      Sunday cup is the normal case, and gating the second one reads as
      extortion.
- [x] **Pro features shipped (26/10)**: unlimited active tournaments (the
      gate) and **CSV export** (`lib/core/utils/csv_export.dart`, share sheet
      from the event screen). Plus, free for everyone: **waitlist with
      automatic promotion** (`supabase/migrations/0007_waitlist.sql`, mock
      parity + tests). The waitlist is *not* a Pro bullet: the entitlement
      lives in the client, so it cannot be gated by the organizer's plan.
- [ ] **Pro features pending** (each one is a paywall bullet only when it
      exists): PDF exports · substitutes · stats · boost in Explore (the boost
      can become a one-off non-subscription SKU later).
- [x] **Code (scaffolding)**: `in_app_purchase` wired in `lib/data/billing/`,
      paywall at `/pro` (profile card + free-tier gate), entitlement from
      the store. **Inert until products exist** — with no products
      configured the paywall shows the benefits with a "próximamente"
      note (no prices, no buy button), the profile entry stays visible to
      organizers, and the app is 100% free and ungated — which is what
      ships through the closed test. **Creating `tande_pro_monthly` /
      `tande_pro_yearly` in Play Console switches paying mode ON for every
      user without an entitlement** — only do it when Pro launches, after
      the closed test, once the features below actually ship.
- [ ] **Play Console**: subscription products `tande_pro_monthly` +
      `tande_pro_yearly`, base plans, 7-day trial (mirror the trial length
      in `AppConstants.proTrialDays` — the plugin can't read it); price in
      USD (confirm whether Play offers UYU pricing — USD is safe).
- [ ] **Server-side verification** (before real money): Supabase edge
      function validating purchases against Google's API — today the
      entitlement is client-side only (Play query + restore on startup).
- [ ] **Fee & payouts**: Google keeps **15%** of subscription revenue; fill
      tax info + bank payout details in Console when revenue starts.
- [ ] **Docs**: update `store/terms-and-conditions.md` §1/§5 and the privacy
      policy — both currently state that no payment happens in the app.

## Mapas y geocodificación

The map is the product on the Explore screen, so how it is drawn is a
publishing decision, not a detail.

**Base vectorial (default).** `flutter_map_vector_tiles` renders OpenFreeMap's
MVT tiles from a MapLibre style bundled in the app
(`assets/map/style_light.json` and `style_dark.json`, picked by the theme
brightness). Why vector:

* **No POI icons.** A raster tile carries the provider's icons *painted into
  the image*; a vector style simply does not have those layers. This is the
  reason for the switch, not a nicety.
* **Own palette.** Both files are OpenFreeMap **Positron** re-tinted for Tande
  by `scripts/build_map_style.py` (mint parks, teal water, green-grey labels)
  — the cartography, road hierarchy and zoom rules stay upstream's.
* **Crisp at any zoom**: labels and lines are drawn per frame instead of
  scaling a bitmap, and the tiles are cached on disk (50 MB, 14 days).

OpenFreeMap's public instance is free: no key, no account, no request limit,
donation-funded, **no SLA**. The credit line — `OpenFreeMap © OpenMapTiles
Data from OpenStreetMap` — comes from the TileJSON, is rendered on the map and
is **not optional**. If it ever grows past a donation-funded service, both the
styles and the tiles are open source and self-hostable (Protomaps / tileserver).

Rebuild the styles only if the palette changes or OpenFreeMap re-publishes its
cartography: `python3 scripts/build_map_style.py`, then the usual
`dart run flutter_launcher_icons`-style rebuild of the app. Reverting to raster
tiles is one flag — `--dart-define=BASEMAP=raster` — and lands on the code
path below, which is also what the widget tests run against.

**Raster fallback.** `lib/core/map/tile_source.dart` still resolves a raster
provider from build-time defines:

| Source | Cost | Notes |
| --- | --- | --- |
| `osm` | free | Donated servers. Policy allows light use only: no SLA, may block without notice, and it asks apps to be able to switch without an update (hence `TILE_PROVIDER`). Fine for testers, not for a launch peak. |
| Thunderforest | 150k tiles/month free, then US$125/mo for 1.5M | "Commercial use is permitted and encouraged" on the free tier. Attribution may not be removed. There is **no cheap middle tier**: 150k → 1.5M is a 10x jump. |
| Stadia Maps | US$20/mo (Starter) | Its free tier is explicitly non-commercial, so a published app lands on Starter. |

`TILE_PROVIDER=custom` + `TILE_URL_TEMPLATE` + `TILE_ATTRIBUTION` points the
build at **any** raster provider with no code change. URL, attribution and zoom
ceiling come from a provider, so switching is a `.release.env` change — which is
exactly what the OSM policy asks for.

**Tile cache (raster path).** flutter_map 8 already caches tiles on disk; the app
configures it explicitly (`lib/core/map/tile_provider.dart`): 300 MB instead of
the 1 GB default, a cache key that ignores the query string (so rotating an API
key does not invalidate the whole map and re-bill every tile), and a **30-day**
freshness window instead of the provider's own header.

That last one is not cosmetic: Thunderforest answers with
`Cache-Control: max-age=21600` — six hours — so trusting the header means every
returning user re-downloads their whole area every day, which on a 150k/month
plan is the difference between hundreds of users and dozens. `TILE_FRESH_DAYS=0`
goes back to honoring the header. Check the cache on a device: pan the map,
kill the app, turn data off, reopen; tiles should still draw.

**Reverse geocoding.** `nominatim.openstreetmap.org` is also donated, and its
policy caps the *whole application* at 1 request/second and requires being able
to switch servers without an update. `lib/core/location/reverse_geocoder.dart`
now throttles to one request per second, caches addresses for 30 days (~11 m
grid, negatives included) and takes the endpoint from
`--dart-define=GEOCODER_URL`, so moving to Photon or a self-hosted Nominatim is
a build flag. If usage grows, the next step is a proxy on the Supabase side
(the policy explicitly recommends it).

## Later

- [ ] **iOS**: needs a Mac + Apple Developer Program ($99/yr). Uruguay has
      real iPhone share — do it after Play validates the product
- [ ] Crash reporting (Sentry/Firebase) if vitals show crashes
- [ ] **B2B / white label** (clubes, municipios, federaciones): sold and
      delivered outside Play — no billing issue; needs a real offer first
- [ ] **Mapa a escala**: OpenFreeMap es gratis y sin límite, pero lo mantiene
      una persona con donaciones. Si Tande crece, self-hostear los estilos y los
      tiles (Protomaps/tileserver) o pasar a MapTiler. El raster OSM no es una
      opción a volumen: sus servidores son donados.

---

### Key facts (don't guess these)

| | |
|---|---|
| Application ID | `com.tande.app` — **permanent** |
| Version | `1.0.0+1` (bump in `pubspec.yaml` per release) |
| Keystore | `~/upload-keystore.jks`, alias `upload`, password in `android/key.properties` |
| Store build | `./scripts/build-release.sh` → `build/app/outputs/bundle/release/app-release.aab` |
| Backend | `.release.env` (gitignored) → `--dart-define` at build time; without it the app runs on **mocks** |
| OAuth redirect | `io.supabase.amateurtournaments://login-callback` (registered in manifest + Supabase dashboard — unrelated to the application ID) |
| Locale | `es_UY` source + `en*` → en; money always `$ 25.000` |
