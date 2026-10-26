# LAUNCH — publish Bracket and get the first users

Working checklist. Update the boxes as you go. Base market: **Uruguay**.

## Current state

| Item | Status |
|---|---|
| App build | ✅ analyze clean, **102/102 tests**, `1.0.0+1` |
| Application ID | ✅ `com.bracket.torneos` (permanent — never change after publish) |
| Git | ✅ 2 commits, secrets gitignored |
| Upload keystore | ✅ `~/upload-keystore.jks` + `android/key.properties` |
| Store AAB script | ✅ `scripts/build-release.sh` |
| Store copy | ✅ `store/play-store.md` |
| Privacy policy | 📝 draft `store/privacy-policy.md` — needs contact email + public URL |
| Supabase anon key in `.release.env` | ⬜ **not filled yet** |
| Migrations `0005` / `0006` applied | ❓ unconfirmed |
| Play Console account | ⬜ |
| Closed test (14 days) | ⬜ |

---

## 1. Do now (unblock everything else)

- [ ] **Back up the keystore + password**: `~/upload-keystore.jks` and the
      `storePassword` in `android/key.properties` → password manager.
      (Losing both = Google upload-key reset process.)
- [ ] **Paste the Supabase anon key** into `.release.env` (URL already filled).
- [ ] **Confirm migrations `0005_split_status_triggers.sql` and
      `0006_signup_checks.sql`** are applied in the Supabase dashboard.
- [ ] **Real-backend smoke test on your phone**: install a release build with
      the Supabase defines, then sign up → create tournament → request
      inscription → share to WhatsApp → see it appear. Mock tests prove
      nothing about the Supabase repositories.
- [ ] **Create the Google Play developer account** ($25 + identity
      verification). Personal account ⇒ the 14-day closed-test clock applies
      to you. Start today so verification runs in parallel.

## 2. Build the shippable AAB

```bash
# after filling .release.env:
./scripts/build-release.sh
# → build/app/outputs/bundle/release/app-release.aab
# (runs gen-l10n + 102 tests, signs with the upload key, prints the signer)
```

- [ ] `.release.env` filled (never commit it — it's gitignored)
- [ ] Script finishes and signer shows `CN=Bracket, OU=Bracket, O=Bracket, L=Montevideo, C=UY`
- [ ] Re-run the on-device smoke test with **this exact AAB's** build

> The AAB already in `build/` was built with a placeholder key for pipeline
> verification — **do not upload it**. Always produce the store build with the
> script.

## 3. Play Console listing

- [ ] **App identity**: name `Bracket`, application ID `com.bracket.torneos`
      (autofills from the AAB), version `1.0.0+1`.
- [ ] **Privacy policy URL**: fill `EMAIL_DE_CONTACTO` in
      `store/privacy-policy.md`, publish it (GitHub Pages on this repo is
      fine), paste the URL into Play Console.
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
      - Feature graphic 1024×500 (green `#1B8A5A` / mint `#34E0A1` on
        `#0F3B2A`, bracket mark + "Tu torneo empieza acá")
      - ≥ 2 phone screenshots (emulator or the YAL L21): explore map,
        bracket/fixture, inscription flow — UI in **es**
- [ ] **Copy** from `store/play-store.md`: title (28 chars), short description
      (79 chars), full description, keyword list.

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
      answer with real numbers: 102 automated tests + on-device manual QA)

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
- [ ] **WhatsApp**: the app already shares the bracket with a pre-filled
      Spanish message — post it into the groups where teams coordinate
- [ ] **Facebook groups**: Montevideo amateur football / pádel / "busco
      equipo" groups are where your exact audience already is
- [ ] **Instagram Reels**: 15 s screen recording — "armás tu torneo en 30
      segundos"; hashtags `#futbol5 #montevideo #padel #torneo`
- [ ] **Venues**: one poster with a QR code per fútbol‑5 complex and padel
      club (padel is booming — they want visibility)
- [ ] **ASO**: keep `Bracket + torneos` together in the title; re-check the
      keyword list in `store/play-store.md` after the first weeks of search
      impressions

## Later

- [ ] **iOS**: needs a Mac + Apple Developer Program ($99/yr). Uruguay has
      real iPhone share — do it after Play validates the product
- [ ] Crash reporting (Sentry/Firebase) if vitals show crashes
- [ ] OSM tile usage: fine at small scale; if the app grows, move to a paid
      tile provider (public tile servers forbid heavy commercial use)

---

### Key facts (don't guess these)

| | |
|---|---|
| Application ID | `com.bracket.torneos` — **permanent** |
| Version | `1.0.0+1` (bump in `pubspec.yaml` per release) |
| Keystore | `~/upload-keystore.jks`, alias `upload`, password in `android/key.properties` |
| Store build | `./scripts/build-release.sh` → `build/app/outputs/bundle/release/app-release.aab` |
| Backend | `.release.env` (gitignored) → `--dart-define` at build time; without it the app runs on **mocks** |
| OAuth redirect | `io.supabase.amateurtournaments://login-callback` (registered in manifest + Supabase dashboard — unrelated to the application ID) |
| Locale | `es_UY` source + `en*` → en; money always `$ 25.000` |
