# Ficha de tienda — Tande (Google Play + App Store)

Base: **global**, primer mercado Uruguay. Copy en `es-419` (neutro: sin voseo rioplatense
cerrado, sin modismos) y en `en`. Nada de lo que dice acá puede ser mentira: la ficha promete
exactamente lo que la app hace hoy (mapa de eventos + inscripción + contacto por WhatsApp).

> **Regla:** si una función no está en `lib/`, no entra en la ficha. Pendientes (cuadros,
> resultados, notificaciones, compartir) quedan para la release que las construya.

---

## Google Play

**Título** (≤ 30) — 26 caracteres

```
Tande - Torneos cerca tuyo
```

**Descripción corta** (≤ 80) — 77 caracteres

```
Inscribite a torneos amateur cerca tuyo. Organizá el tuyo y confirmá equipos.
```

**Descripción larga** (≤ 4000) — 891 caracteres

```
Tande es la app para encontrar y organizar torneos amateur cerca tuyo.

Para jugadores: mirá en el mapa los torneos de fútbol 5, fútbol 7, pádel, tenis y básquet que se juegan cerca, filtrá por deporte y distancia, y anotate en segundos. Coordinás el pago directo con el organizador por WhatsApp, sin comisiones ni pagos dentro de la app.

Para organizadores: creá el torneo con fecha, sede y cupo; recibí solicitudes de inscripción; confirmá o rechazá equipos y avisales por WhatsApp con un toque. También podés sumar los equipos que confirmaste en persona, para que el cupo siempre esté al día. Y si querés, agregale una imagen para que destaque en Explorar.

- Mapa y lista de torneos cerca tuyo
- Inscripción desde el celular, sin filas ni planillas
- Confirmación del organizador con aviso por WhatsApp
- Cupos actualizados en tiempo real
- Gratis para jugadores

Tu torneo empieza acá.
```

Play no tiene campo de keywords: la descripción es el índice. Palabras que tienen que aparecer
naturalmente arriba (primeros 250 caracteres): **torneo, torneos, inscripción, fútbol 5, pádel,
amateur, cerca**.

---

## App Store

**Nombre** (≤ 30) — 26

```
Tande - Torneos cerca tuyo
```

**Subtítulo** (≤ 30) — 26

```
Torneos amateur cerca tuyo
```

**Keywords** (≤ 100, separadas por coma, sin repetir el nombre) — 91

```
torneos,futbol 5,padel,tenis,basquet,inscripcion,fixture,deporte amateur,montevideo,uruguay
```

**Descripción** — misma que Play, en español (`es-419`). Para el locale `en`:

```
Tande is the app to find and organize amateur tournaments near you.

For players: see football 5-a-side, football 7-a-side, padel, tennis and basketball tournaments around you on the map, filter by sport and distance, and sign up in seconds. You arrange payment directly with the organizer on WhatsApp — no fees, no payments inside the app.

For organizers: create your tournament with date, venue and team limit; receive sign-up requests; confirm or reject teams and notify them on WhatsApp in one tap. You can also add the teams you confirmed in person so your open spots always match reality. And if you want, add an image so your tournament stands out in Explore.

- Map and list of tournaments near you
- Sign up from your phone — no spreadsheets, no group-chat chaos
- Organizer confirmation with a WhatsApp notice
- Open spots always up to date
- Free for players

Your tournament starts here.
```

---

## Gráficos

| Pieza | Especificación | Estado |
|---|---|---|
| Icono de tienda | 512×512 PNG (Play) / 1024×1024 sin alpha (App Store) | ✅ generado desde `assets/icon.png` |
| Feature graphic (Play) | 1024×500, fondo `#0F3B2A`, marca menta `#34E0A1`, texto "Tande — Tu torneo empieza acá" | ⬜ |
| Capturas teléfono | ≥ 2 (recomendado 4): mapa en Explore · lista filtrada · detalle del torneo · inscripción | ⬜ |
| Capturas iPad (App Store) | sólo si se declara soporte iPad | ⬜ |

Las capturas van en **es** con el mapa de Montevideo y precios `$ 25.000`. Para el locale `en`,
las mismas pantallas con la UI en inglés.

---

## Lo que la ficha NO debe decir (hoy)

- "El cuadro se arma solo", "resultados", "posiciones", "fixture en vivo" → no existe
  (`grep -rn "cuadro\|llave\|partido\|resultado" lib` = 0).
- "Notificaciones / no te pierdas ningún cambio" → no hay push.
- "Compartir el cuadro por WhatsApp" → no hay hoja de compartir; lo que existe es el mensaje
  uno-a-uno al organizador y el aviso al jugador.
- "Inscripción desde un link" → la inscripción es desde la app, no desde un link web.

Cuando se construyan, entran a la ficha en el mismo commit que las publica.
