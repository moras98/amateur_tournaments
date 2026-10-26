# Tande — Design System

Rules for keeping the UI consistent, modern and sporty. The code that
implements this lives in `lib/core/theme/app_theme.dart` — change both
together.

**Principles:** one green accent · tonal surfaces instead of shadows ·
rounded shapes · bold headings · 8pt spacing · Uruguayan Spanish.

---

## 1. Brand

| | |
| --- | --- |
| Name | Tande |
| Tagline | "Tu torneo empieza acá" (es) / "Your tournament starts here" (en) |
| App icon | Mint location pin with a play triangle cut out `#34E0A1` on a deep-green `#0F3B2A` field — neutral to any sport; adaptive icon (foreground at 66% safe zone, solid `#0F3B2A` background) plus an Android 13+ monochrome glyph; splash matches the same field color. Regenerate with `dart run flutter_launcher_icons` + `dart run flutter_native_splash:create` |
| Color | Green `#1B8A5A` (sport pitch, "go", trust) |
| Personality | Local, direct, energetic, friendly — pickup sports, not enterprise |
| Iconography | Rounded Material Symbols, sport glyphs per modality |

## 2. Color

All colors derive from the seed via `ColorScheme.fromSeed` (Material 3
tonal palettes) — never hardcode raw colors in widgets; use scheme roles.
Light **and** dark themes must both work (`ThemeMode.system`).

Two seeds: green `#1B8A5A` drives the scheme, and an amber `#ED8B00`
tonal scheme donates the **whole tertiary family** (see
`AppTheme._build`) so pending/waiting states read warm instead of green.
Beyond solid roles, the signature **brand gradient**
(`AppGradients.brand`: `#0E5C3A → #1B8A5A → #3FB877`, top-left to
bottom-right) paints the hero headers — auth screens and the profile
header — always with white content on top.

| Role | Use for |
| --- | --- |
| `primary` | Primary buttons, links, focus rings, active icons |
| `onPrimary` | Content on `primary` |
| `primaryContainer` / `onPrimaryContainer` | Badges, "Abierto", nav indicator |
| `tertiaryContainer` | Pending/waiting states (chips, badges) |
| `error` / `errorContainer` | Validation, destructive actions, "Rechazada" |
| `surface` | Cards, sheets, dialogs (one level **above** the page) |
| `surfaceContainerLowest` | Page background (light theme) |
| `surfaceContainerHighest` | Input field fill, quiet badges |
| `outlineVariant` | Hairline borders, dividers |
| `inverseSurface` / `onInverseSurface` | SnackBars |
| Sport colors | Marker dots and accents only (see `core/sports.dart`) |

Rules:
- **One primary action per screen** — the single filled button.
- Never encode state with color alone: pair with an icon and a text label
  (e.g. spots badge = color + `label` text).
- Destructive confirmations use `error` for the confirming button only.

## 3. Typography

Family: **Plus Jakarta Sans** (variable, bundled — `assets/fonts/`).
Fallbacks: platform default. No second family.

| Style | Weight | Use |
| --- | --- | --- |
| `headlineMedium/Small` | 700 | Empty-state titles, hero moments |
| `titleLarge` | 700 | Section headers, card titles |
| `titleMedium/Small` | 600 | Card titles, tile headers |
| `bodyLarge/Medium` | 400–400 (height 1.45) | Descriptions, dialog content |
| `bodySmall` | 400 | Captions, map attribution |
| `labelLarge` | 600 | Buttons, chips, form labels |
| `labelSmall` | 600 | Badges, counters, timestamps (+0.2 tracking) |

Rules:
- Sentence case; **no all-caps** except tiny status labels
  (`ABIERTO`, `COMPLETO`, `CERRADO`) via `status.label.toUpperCase()`.
- Never mix weights beyond the table (e.g. no 300 or 500 body text).
- Money `$ 25.000`, dates `sáb 3 oct • 19:00` (es_UY, via
  `core/utils/format.dart` — don't format by hand).

## 4. Spacing & layout

- Grid: **8pt** (multiples of 4 for tight pairs like icon+text).
- Screen gutters: `16`. Section gap: `16–24`. Between related rows: `12`.
- **No empty app bars**: tab and auth screens (Inscripciones, Perfil,
  login, signup) render bar-less — with the titles removed, an AppBar was
  just a blank strip content scrolled under. The status-bar inset comes
  from `SafeArea` (`bottom: false` on tabs: the floating nav capsule
  already insets the bottom). Bars only exist where they carry something
  (search fields, back buttons).
- Touch targets ≥ **48×48** (buttons are 52 tall).
- Lists scroll; anything below the first viewport must survive
  `scrollUntilVisible` in tests.
- Root navigation: 4 tabs — Explorar · Mis inscripciones · Organizar · Perfil.

## 5. Shape

| Radius | Apply to |
| --- | --- |
| Stadium (pill) | Buttons, chips |
| 14 | Inputs, list tiles, snackbars, segmented buttons |
| 20 | Cards |
| 24 | Dialogs |
| 28 | Bottom sheets (top corners) |
| 16 | Inline media (maps, images) |

## 6. Elevation & surfaces

- Prefer **tonal layering** over shadows: page (`surfaceContainerLowest`)
  → cards (`surface`, hairline `outlineVariant` border) → overlays
  (dialogs/sheets, flat, `surfaceTintColor: transparent`).
- Elevation only where something floats: snackbar 2, FAB 2, dialog 1.
- App bars are flat (`scrolledUnderElevation: 0`); don't add separators
  under them.

## 7. Components

- **Buttons** — pill. Filled = primary action (max 1 per screen); tonal =
  positive secondary (`Confirmar`); outlined = neutral; text = tertiary
  (with icon when it has an action verb). Destructive = text/outlined in
  `error`, never filled.
- **Inputs** — filled at full strength (`surfaceContainerHighest`), no resting
  border, focus ring 1.5 `primary`, errors 1.2–1.5 `error` below/inline.
  Label above (`labelText`), hint as example format, helper for context.
- **Search bar** — one shared rounded capsule (`SearchCapsule`) on **every
  screen that searches**: search, filter (with badge) and map/list toggle in
  Explore; search plus the sort menu in Organizar; search over the list in
  Mis inscripciones. It uses the bottom nav's recipe (12 margin, 64-tall
  stadium, `surface` + `outlineVariant` hairline — the two capsules bookend
  the screen) and it **never docks into an app bar**: over Explore's map it
  floats full-bleed; elsewhere the content slides below its region
  (margin + bar + margin). The field carries **no fill of its own** — the
  pill's `surface` is its background (the theme's grey rounded-rect fill
  would fight the stadium's curve). The pill is the identity of the search
  row everywhere.
- **Organizer events row** — the same capsule with a trailing **sort menu**
  (`Más próximos` [default] / `Creados recientemente` / `Título (A–Z)`,
  active option checkmarked); the search covers title/venue/city with the same
  250 ms debounce and answers a no-match with "No encontramos eventos…",
  never a blank list.
- **Off-app confirmations** — the requests screen summary carries a
  "Confirmados fuera de la app" tile: a `surfaceContainerHighest` row with
  ± steppers and a tap-the-number dialog. The count is a stored slice
  (`manual_confirmed`) **added** to the app-confirmed rows — every
  "X de Y lugares" shows `totalConfirmed`, capped at the event's capacity;
  the generic `update()` never writes it (only `setManualConfirmed`).
- **Chips** — filter/choice only; pill; unselected = `surface` + `outlineVariant`
  hairline; **selected = solid `primary` with a bold `onPrimary` label**; no
  checkmark; padding gives a ~40dp touch target. Use **`ChoiceChip` for every
  chip, multi-select included** — only it applies `secondaryLabelStyle`; a
  `FilterChip` keeps the resting label color on the selected fill (grey text
  on green).
- **Sport chips** — read-only tags (profile "Deportes"): **no fill, no
  border** — the sport glyph in full accent + a semibold `onSurface` label,
  padding only to keep the row rhythm; a lone tinted pill reads as an error,
  and display tags never borrow the filter-chip recipe.
- **Nav bar** — floating capsule: 64 tall (stadium), `surface` with a hairline
  `outlineVariant` border, 12 margin all around with the page tint showing
  behind it; pill `primaryContainer` indicator, selected tab bold in `primary`,
  unselected `onSurfaceVariant`. Geometry lives in `core/utils/nav_geometry.dart`
  (mirrored by `navigationBarTheme.height`). Labels must fit **one line** in a
  quarter of the capsule (the SDK exposes no maxLines/ellipsis hook for them —
  long labels wrap, hence "Inscripciones", not "Mis inscripciones").
- **Filter rows** — status/filter chips sit on **one horizontally scrolling
  row** (never a `Wrap`, which stacks them into a centered second run on
  narrow phones).
- **Hero headers** — rounded-rect (20–24 radius) block with
  `AppGradients.brand` and white content: login, signup and profile put
  the title/identity on top of it. Any new full-bleed header follows the
  same recipe; content inside is never a scheme role (it's white).
- **Form sections** — each block starts with a section label in bold
  `primary` (`_sectionLabel`).
- **Password rules** (sign-up) — 8+ characters with an uppercase, a
  lowercase and a digit (`PasswordRules.validate`), mirrored by a live
  checklist under the field: one compact row per rule, brand `check` when
  met, outline icon when not (`PasswordChecklist`). Sign-up runs in three
  in-screen steps — **cuenta** (name, email, password; on the brand hero)
  → **sobre vos** (username, birth date, gender) → **¿Qué jugás?**
  (sports) — with a dot indicator plus a back arrow on the left (steps
  2+), a fade/slide swap, the single full-width filled action at the
  bottom, and validation scoped to the mounted step (the
  `Form` wraps the switcher, never the step children). The **cuenta**
  step additionally gates `Siguiente` on an unchecked terms checkbox
  below the password checklist (`TermsCheckbox`, its link opens the
  hosted terms): the field validators run first, then a snackbar demands
  the tick. Google/Apple sign-in has no form of its own, so the OAuth
  acceptance is a tappable fine-print line under the social buttons
  instead — consent precedes account creation either way. The birth date is
  a section label over a tappable hairline row (`surface` +
  `outlineVariant`, 52 tall) — never a floating input title. Email and
  username are checked live while typing (250 ms debounce, like the
  inscriptions search), and each `Siguiente` tap re-runs its step's check
  fresh before validating — a step never advances on a stale debounce
  result. The checks go through `AuthRepository.isEmailRegistered` /
  `ProfileRepository.isUsernameTaken` — best-effort Supabase RPCs
  (`0006_signup_checks.sql`), silently degrading to no hint when the RPC
  isn't applied; the real constraints still run at sign-up/save, and the
  edit form runs the same username check excluding its own handle. New
  accounts land in the app already complete; the shared field widgets live
  in `features/auth/widgets/profile_fields.dart`.
- **Cards** (event card) — title (titleMedium), meta row (icon 16 +
  labelSmall: sport · date · city), cost bottom-left (`formatCost`), spots
  badge bottom-right (see status colors). Whole card is the tap target.
- **Status badges/chips** — use the enum getters
  (`TournamentStatus.label`, `InscriptionStatus.label`); colors:
  open/confirmed `primaryContainer`, full/pending `tertiaryContainer`,
  closed/cancelled `surfaceContainerHighest`, rejected
  `errorContainer` — always with an icon.
- **Dialogs** — the cancel action is a close (X) button **on top**, never a
  second action in the row; below it an icon in a tinted circle
  (`errorContainer` for destructive, `primaryContainer` otherwise), title +
  one short paragraph centered, and a single **full-width** confirm
  (filled; `error` color for destructive). On iOS the same shape as a
  native Cupertino alert: X on top, only the confirming action (red when
  destructive). Shells: `CloseTopDialog`, `CupertinoCloseAlert`.
- **Platform adaptation (iOS)** — the app keeps its Material design
  language on both platforms, but speaks native Cupertino where iOS users
  expect it (`core/theme/adaptive.dart`; `isCupertino` = `ThemeData.platform
  == TargetPlatform.iOS`, so tests pin either side):
  - Confirmation dialogs → `showConfirmDialog` (native alert with the X
    on top, single red action); the off-app count alert swaps its field
    for a `CupertinoTextField` the same way. Used by sign-out, cancel
    inscription and delete event.
  - Switches → `AdaptiveSwitch` (`Switch` / `CupertinoSwitch`): the
    profile's organizer toggle and the filters sheet.
  - Date/time pickers → `showAdaptiveDatePicker` /
    `showAdaptiveDateTimePicker`: Material calendar + clock, or the
    Cupertino wheel sheet ("Listo", 24h, es_UY).
  - Page transitions → `CupertinoPageTransitionsBuilder` on iOS (slide +
    edge-swipe back); the framework default (zoom) elsewhere.
  - `main.dart` bridges a `CupertinoThemeData` with the Material primary,
    so tinted Cupertino controls match the brand instead of system blue.
  - Stays Material on both platforms: bottom sheets, snackbars, spinners,
    the nav bar and forms.
- **SnackBars** — transient success/feedback only, floating, one line;
  destructive/irreversible actions get a dialog instead. Failure snackbars
  say what failed and the next step ("No se pudo abrir WhatsApp. Llamá al …").
- **FAB** — "Crear evento" only, extended with icon + label.

## 8. Maps

- flutter_map + OSM tiles, `© OpenStreetMap` attribution always visible
  (bottom-left) on every map.
- Event pins: sport icon in a sport-colored circle (grey when full/closed),
  44pt; user location: blue dot with white ring; venue pin:
  `Icons.location_pin` in `primary`.
- The form map is 320 tall. Tap-to-place puts the pin **and reverse-geocodes
  (debounced ~0.8 s) to complete the empty address/city fields** — text the
  organizer typed is never overwritten. "Usar mi ubicación" does the same
  from the device location, moving the camera to zoom 16.
- The Explore map **never preloads a hardcoded city**: it waits for the device
  location (loading state, no tiles wasted), frames the loaded pins' bounds
  when the location is unavailable, and asks to retry when there is neither —
  the camera always frames real content.
- The Explore map is **full-bleed behind the floating nav capsule** (the shell
  runs `extendBody` on that tab only): attribution and the recenter button are
  lifted, the list view's last card clears the bar — all via
  `navBarClearanceOf` — and modal sheets open on the **root navigator** so
  they overlay the capsule instead of hiding underneath it.
- **Discovery defaults to what you play**: signed in, Explore opens filtered
  to the profile sports (picked at registration/profile edit), and the filter
  badge counts that default so a narrowed view explains itself. The sheet's
  sport chips are **multi-select** and open with that default preselected;
  applying any choice (including "Todos") pins it — and the empty state's
  "Borrar filtros" widens to every sport, the escape hatch when the default
  matches nothing. Signed out = every sport.

## 9. Feedback states

Every data-driven screen defines four states:

| State | Treatment |
| --- | --- |
| Loading | Centered `CircularProgressIndicator` (buttons show 20pt inline spinners) |
| Empty | Icon + `headline` title + one body line + primary CTA |
| Error | One-line message + "Reintentar" |
| Loaded | Content |

Rules: never block navigation on background work; forms disable their
button while saving.

## 10. Motion

- Standard M3 emphasis: 200–300 ms, ease; `InkSparkle` ripples.
- **Page pushes** — detail, forms, requests, auth: 240 ms fade + 4% slide-up
  with `easeOutCubic` (`_pushPage` in `app_router.dart`). Tab switches stay
  instant (shell keeps each branch alive).
- **List entrance** — cards fade + slide up via `AnimateIn`, staggered 50 ms
  per index (capped at 6). The delay is baked into the curve (`Interval`) —
  no timers, so tests `pumpAndSettle` straight through.
- **Hero** — the sport icon flies card → detail (`sport-<id>` tag). Tags are
  one per tournament, so nothing collides onscreen.
- **Pin drop** — a new pin on the event-form map bounces in
  (`elasticOut`, 450 ms); moving an existing pin does nothing (state is
  preserved).
- **Map ↔ list** — `AnimatedSwitcher` crossfade + 2.5% slide, 260 ms.
- No decorative animation otherwise; motion only for state changes
  (sheets, chips, spinners).
- Keep maps and lists alive across tab switches (`StatefulShellRoute`).

## 11. Accessibility & localization

- Contrast ≥ 4.5:1 for text (theme roles guarantee it — don't override).
- Text scales up to 200%: prefer `Wrap`/`Expanded` over fixed widths.
- Icon-only buttons need `tooltip` from `l10n` — never a hardcoded string.
- **The UI follows the phone's locale.** Every string comes from gen-l10n
  (`lib/l10n/app_es_UY.arb` is the source/template, `app_en.arb` mirrors it
  key for key, `app_es.arb` is the empty base `gen-l10n` requires).
  `main.dart`'s `localeResolutionCallback` resolves: any `es*` device →
  `es_UY`, any `en*` → `en`, anything else → `es_UY`. No hardcoded UI
  strings; shared vocabulary (sports, statuses, countries) lives in
  `lib/l10n/labels.dart` extensions.
- **Money always renders Uruguayan-peso style** (`$ 25.000`) in every
  language — `formatCost` never localizes the layout, only the "Gratis"
  label. Dates/pickers follow the resolved locale (`activeLocale`).
- One-handed use: primary actions in the bottom half of the screen.

## 12. Copy (Uruguayan Spanish)

- es_UY is the **source language** of the ARB catalog: the voseo copy is
  the template everything else translates from (English lives in
  `app_en.arb` with identical keys — keep the two in sync; ARB files are
  plain JSON, no comments).
- Voseo for imperatives and direct address: "Coordiná", "Inscribite",
  "Creá tu evento", "Podés"; infinitive buttons are fine ("Inscribirme").
- Sentence case, no exclamation spam, "tú"→"vos" everywhere.
- Domain words: **inscripción** (not registro), **torneo/evento**,
  **sede**, **lugar** (not spot/cupo), **organizador**.
- WhatsApp flows: always polite, name the tournament and next step. The
  pre-filled WhatsApp messages stay **Spanish even in English** (they're
  addressed to Uruguayan organizers and are not in the catalog).

## 13. Do / Don't

| Do | Don't |
| --- | --- |
| Use scheme roles (`colorScheme.primary`) | Hardcode `Colors.green` / hex in widgets |
| One filled button per screen | Stack two primary CTAs |
| Pill buttons and chips | Square-cornered actions |
| Tonal surfaces + hairline borders | Drop shadows everywhere |
| Icon + text for every status | Color-only status |
| Copy via `l10n` keys, sentence case | Hardcoded UI strings, ALL CAPS headings |
| `format.dart` for dates/money | Manual `toString()` formatting |

## 14. Where things live

| Piece | File |
| --- | --- |
| Theme (all tokens) | `lib/core/theme/app_theme.dart` |
| iOS adaptation (dialogs, switches, pickers, transitions) | `lib/core/theme/adaptive.dart` |
| Sign-up/profile fields (password rules, username, chips) | `lib/features/auth/widgets/profile_fields.dart` |
| Terms acceptance (checkbox, inline legal links) | `lib/features/auth/widgets/terms_acceptance.dart` |
| Tande Pro (paywall, entitlement, Play Billing) | `lib/features/pro/`, `lib/data/billing/` |
| Sport colors/icons | `lib/core/sports.dart` |
| Date/money formatting | `lib/core/utils/format.dart` |
| UI strings (es_UY source + English) | `lib/l10n/app_es_UY.arb`, `lib/l10n/app_en.arb` → `flutter gen-l10n` |
| Sport/status/country vocabulary | `lib/l10n/labels.dart` |
| App icon/splash (`#1B8A5A`) | `assets/icon*.png`, `pubspec.yaml` |
| This document | `design.md` |
