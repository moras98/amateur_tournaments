# Play Store listing — Bracket

Base market: **Uruguay**; the listing travels to all of Latin America and
English-speaking markets. Two Play Console locales ship at launch:

| Play Console locale | Copy in this file |
|---|---|
| **es-419** (Español de América Latina) | "es-419" section below — **neutral** Spanish |
| **en** (English) | "English" section below |

## Locale rules

- **es-419, not es-ES.** Latin-American phones (incl. Uruguay) resolve to
  es-419; it is where the whole regional market searches. es-ES would
  read foreign to the target audience.
- **The store copy is neutral Spanish** (tú/usted imperatives: "Crea",
  "Elige", "cerca de ti") — no voseo. Play copy must travel beyond
  Uruguay.
- **The app itself stays voseo (es_UY) — do not rewrite it.** The two
  intentionally differ: the store is discovery for everyone, the app is
  the home market's voice. Screenshots show the real app in es_UY
  (voseo, `$ 25.000` prices) — that is correct, not a bug to fix.
- **Only promise what ships.** Google removes listings for misleading
  descriptions and early churn is worse. "Do not promise" list at the
  bottom — re-check it whenever a feature lands.

## Store fields — es-419

**Title** (≤ 30 chars)

```
Bracket - Torneos cerca de ti
```

**Short description** (≤ 80 chars) — first thing in search results:

```
Crea tu torneo, aprueba inscripciones en la app y descubre torneos cerca de ti.
```

**Full description** (≤ 4000 chars)

```
Bracket es la app para organizar y seguir torneos amateur desde el celular.

Crea tu torneo en minutos: elige el deporte (fútbol 5, pádel, tenis o básquet), el formato (eliminatoria o liga), la fecha, la sede y el precio de la inscripción en tu moneda. Publícalo y recibe las inscripciones de los equipos en la app.

- Inscripciones online: los equipos se anotan desde el enlace del torneo y tú apruebas o rechazas cada solicitud desde el celular.
- Coordinación por WhatsApp: al inscribirse, el equipo abre WhatsApp con un mensaje listo para acordar el pago, y tú puedes avisarle la decisión desde la app.
- Equipos confirmados fuera de la app: cuenta los que se anotaron en persona o en efectivo, sin perder su lugar.
- Estado claro: cada torneo se ve abierto, lleno o cerrado, con los lugares libres a la vista.
- Mapa y búsqueda: descubre torneos amateur cerca de ti, por ciudad, por deporte o por nombre.
- Entra con email, Google o Apple.

Organiza como un profesional, juega como siempre. Tu torneo empieza aquí.

Gratis para jugadores y organizadores. Crea tu primer torneo hoy.
```

(≈ 1 100 chars — room left for a line about the launch city once the
first real tournaments are listed.)

## Store fields — English

**Title** (≤ 30 chars)

```
Bracket - Tournaments near you
```

**Short description** (≤ 80 chars)

```
Run your tournament: create events, approve sign-ups and find events near you.
```

**Full description** (≤ 4000 chars)

```
Bracket is the app to run amateur tournaments from your phone.

Create your tournament in minutes: pick the sport (5-a-side football, padel, tennis or basketball), the format (elimination or league), the date, the venue and the entry fee in your currency. Publish it and take team sign-ups right in the app.

- Online sign-ups: teams register from the tournament's link; you approve or reject each request from your phone.
- WhatsApp coordination: when a team signs up, WhatsApp opens with a ready-made message to arrange payment, and you can send the decision back from the app.
- Off-app teams: count the teams that signed up in person or paid cash, without losing their spot.
- Clear status: every tournament shows as open, full or closed, with remaining spots visible.
- Map and search: find amateur tournaments near you by city, sport or name.
- Sign in with email, Google or Apple.

Run it like a pro, play like always. Your tournament starts here.

Free for players and organizers. Create your first tournament today.
```

## Keywords (Play has no keyword field — the description is indexed, so
## these must appear naturally)

Spanish (es-419):

- Primarios: **torneo**, **torneos**, **inscripción**, **eliminatoria**, **liga**
- Deportes: **fútbol 5**, **pádel**, **tenis**, **básquet**
- Acciones: **organizar torneo**, **anotar equipo**, **aprobar inscripción**
- Locales: **uruguay**, **montevideo** (add the launch city; Play indexes
  city terms well for local discovery)

English:

- **tournament**, **amateur tournament**, **league**, **elimination**,
  **sign-up**, **padel**, **5-a-side football**

## Ranking notes

- The word "bracket" alone is crowded abroad — the ASO battle is won on
  Spanish terms: keep **Bracket + "torneos"** together in the title, and
  "torneo/inscripción/eliminatoria" in the first 250 chars of the
  description.
- Screenshots in **es-419** show the app in es_UY (voseo, Montevideo-area
  map data, `$ 25.000`-style prices) — real UI, intentionally. One
  English set for the `en` listing.
- Category: **Sports** (secondary: Events). Content rating: low-maturity
  utility app. Free; no in-app purchases at launch (Terms §1 says so).

## Do not promise (not built yet)

- **Automatic brackets / live results / standings** — the app registers
  the format (elimination or league) but does not generate or track
  brackets/results yet.
- **In-app payments** — entry fees are shown and coordinated off-app
  (WhatsApp). Terms §1 promises no in-app payment; keep it until Pro.
- **Push notifications** — none exist.

Move an item out of this list only when the feature actually ships.
