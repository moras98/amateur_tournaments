# Publicación iOS + Android — Bracket

Auditoría técnica, plan de publicación, plan de marketing y modelo económico.
Base: `main` @ `c30ecd7` (incluye el scaffolding de Bracket Pro, ya commiteado). Fecha: 26 de
octubre de 2026.

---

## 1. Veredicto

El código está sano: `flutter analyze` limpio y **107/107 tests** en verde. Lo que falta
para publicar **no es código de pantallas**. Son cuatro cosas, y una decisión de producto.

1. **La ficha de tienda vende un producto que la app no es.** `store/play-store.md` promete
   "el cuadro se arma solo", "resultados", "posiciones", "notificaciones" y "compartir el
   cuadro por WhatsApp". En todo `lib/` hay **0 coincidencias** de `cuadro`, `llave`,
   `partido`, `resultado`, `fixture`, `standings`. La app es: mapa/lista de torneos +
   solicitud de inscripción + el organizador confirma. Si publicás así, ambas tiendas pueden
   rechazar por metadatos engañosos y, si pasa el filtro, cada persona que llega esperando el
   cuadro se va y deja 1 estrella. **Esto es el bloqueante #1.**
2. **iOS nunca se compiló.** No hay `ios/Podfile`, no hay `DEVELOPMENT_TEAM` en el proyecto
   Xcode, no hay cuenta Apple. No hace falta Mac para publicar (Codemagic, 500 min/mes
   gratis), pero sí hacen falta dos cosas que hoy no existen: **borrar cuenta dentro de la
   app** (Apple lo exige sin excepción si hay registro) y el **proveedor Apple configurado en
   Supabase** (el botón existe; si el provider no está activo, el revisor ve un login roto).
3. **Falta lo mínimo legal y operativo en las dos tiendas.** No hay borrado de cuenta (solo
   logout), la política y los términos tienen `EMAIL_DE_CONTACTO` y no tienen URL pública, y
   el email de confirmación de Supabase Free (**~2 correos/hora**) no aguanta un lanzamiento.
4. **Un bug real de pérdida de datos en el registro.** Si "Confirm email" está activo (default
   de Supabase), el alta en 3 pasos tira a la basura usuario, fecha de nacimiento, género y
   deportes: la fila de `profiles` solo recibe el nombre (ver §4.1).

Los números, sin maquillaje: Uruguay solo, con suscripción de organizador, **no paga el
tiempo**. Escenario base realista del año 1: **US$ 26/mes netos**. La infraestructura cuesta
**US$ 139 el primer año** (Play 25 + Apple 99 + dominio 15). Cubrir la infraestructura son
**9-10 suscriptores**; cubrir el tiempo (5 h/semana) son **100-160**. Eso no significa que no
lo hagas: significa que este proyecto, como está planteado, es una apuesta de mercado y
aprendizaje, no un ingreso. La sección 8 muestra qué tendría que pasar para que sí lo sea.

**Recomendación en una línea:** 3-4 semanas hasta Android en producción y 5-6 hasta iOS, pero
antes de invertir un peso en marketing decidí si el cuadro se construye (2-3 semanas) o si la
ficha se reescribe para lo que hay. Sin cuadro, "Bracket" es un calendario de torneos con un
nombre que promete otra cosa.

---

## 2. Estado verificado hoy (repetible)

| Ítem | Valor | Cómo se verifica |
|---|---|---|
| Analyze | limpio, 0 issues | `flutter analyze` |
| Tests | **107 / 107** | `flutter test` |
| Código | 59 archivos Dart, 11.130 LOC (+2.559 en `l10n/generated`) | `find lib -name '*.dart' -not -path '*/generated/*' \| wc -l` |
| Flutter / Dart | 3.44.4 stable / Dart 3.12.2 | `flutter --version` |
| Versión app | `1.0.0+1` | `pubspec.yaml` |
| applicationId | `com.bracket.torneos` (permanente) | `android/app/build.gradle.kts` |
| targetSdk / minSdk | **36 / 24** | `build/app/intermediates/merged_manifests/release/.../AndroidManifest.xml` |
| Firma Android | `~/upload-keystore.jks` + `android/key.properties` presentes | `ls -la` |
| Backend | `.release.env`: URL cargada (40 chars), **anon key vacía** → `build-release.sh` aborta | `awk -F= '{print $1, length($2)}' .release.env` (no imprime el valor) |
| Migraciones | 0001-0006 en repo | `ls supabase/migrations` |
| Proyecto iOS | bundle id `com.bracket.torneos`, iOS 13.0, **sin Podfile, sin Team** | `ls ios/`, `grep DEVELOPMENT_TEAM ios/Runner.xcodeproj/project.pbxproj` |
| Push / analytics / crash | **0 dependencias** | `grep -rn "firebase\|sentry\|analytics" lib pubspec.yaml` |
| Borrar cuenta | **no existe** (solo `signOut`) | `grep -rn "deleteAccount" lib` |
| Compartir | **no existe** (solo abrir chat de WhatsApp con el organizador) | `grep -rn "share_plus\|Share\." lib` |
| Cuadros / resultados / posiciones | **0 coincidencias** | `grep -rn "cuadro\|llave\|partido\|resultado" lib` |
| Gráficos de tienda | **no hay** (ni feature graphic ni screenshots) | `find store -type f` |
| CI | **no hay** | `ls .github` |

---

## 3. Bloqueantes y faltantes por tienda

### 3.0 Bloqueante común a las dos tiendas: no se puede compilar un build real

`.release.env` línea 6 es `SUPABASE_ANON_KEY=` **vacía**. `scripts/build-release.sh` aborta con
"SUPABASE_URL / SUPABASE_ANON_KEY not filled", y sin las dos defines la app compila en modo
mock (datos de demo, sin backend). O sea: **todavía no existe ningún build con backend real**, y
el smoke test en device contra Supabase que pide `LAUNCH.md` §1 nunca se hizo. Es un minuto de
trabajo y desbloquea todo lo demás.

### 3.1 Android / Google Play

| # | Ítem | Estado | Bloqueante |
|---|---|---|---|
| A1 | Ficha que coincide con el producto | ❌ 5 de 8 bullets son falsos | **Sí** (metadatos engañosos) |
| A2 | Política de privacidad con URL pública + email real | ❌ `EMAIL_DE_CONTACTO` | **Sí** |
| A3 | Borrado de cuenta declarado (in-app o link web) | ❌ hay sólo "escribinos" | **Sí** |
| A4 | Data safety coherente (nombre, email, foto, nacimiento, género, teléfono, ubicación, UGC) | ⬜ sin declarar | **Sí** |
| A5 | Cuenta Play Console ($25) + verificación de identidad | ⬜ | **Sí** |
| A6 | Test cerrado 12 testers × 14 días (cuenta personal) | ⬜ | **Sí** (reloj de 14 días) |
| A7 | AAB firmado con la upload key | ✅ script listo | No |
| A8 | Gráficos: feature 1024×500 + ≥2 capturas en es | ⬜ | **Sí** |
| A9 | Content rating (IARC) y público 13+ | ⬜ | **Sí** |
| A10 | Acceso para revisores (cuenta demo con torneo) | ⬜ | **Sí** |
| A11 | Email de confirmación de Supabase: **2/hora en Free** | ❌ | **Sí** en la práctica |
| A12 | Cuenta Supabase con backups (Free no tiene) | ❌ | Riesgo alto |

### 3.2 iOS / App Store

| # | Ítem | Estado | Bloqueante |
|---|---|---|---|
| I1 | Apple Developer Program (US$ 99/año) + 2FA | ⬜ | **Sí** |
| I2 | Ficha honesta (misma corrección que A1) | ❌ | **Sí** |
| I3 | **Borrar cuenta dentro de la app** (guía 5.1.1(v)) | ❌ | **Sí** – rechazo seguro |
| I4 | Sign in with Apple operativo (guía 4.8): botón existe, **provider en Supabase sin configurar** | ⚠️ | **Sí** – revisor ve login roto |
| I5 | Restaurar compras visible si hay suscripción (3.1.2) | ✅ ya está en el paywall | No |
| I6 | Disclosure de autorrenovación + links a términos/privacidad en el paywall | ✅ ya está | No |
| I7 | `PrivacyInfo.xcprivacy` (APIs de razón requerida) | ❌ | Riesgo (ITMS-91053) |
| I8 | `ITSAppUsesNonExemptEncryption` en Info.plist (evita la pregunta en cada envío) | ❌ | Molesto |
| I9 | `NSLocationWhenInUseUsageDescription` en español (hoy sólo inglés) | ⚠️ | No |
| I10 | Pipeline de build macOS (no tenés Mac → Codemagic) | ❌ | **Sí** |
| I11 | Un iPhone físico para QA/TestFlight | ❓ | **Sí** |
| I12 | App Store Connect: registro de la app, categoría, age rating 13+, capturas 6.7"/6.1"/iPad | ⬜ | **Sí** |
| I13 | Productos `bracket_pro_monthly` / `bracket_pro_yearly` en App Store Connect | ⬜ | Sólo si Pro se lanza |
| I14 | Guideline 4.2 (minimum functionality) | ✅ app con backend real y UGC | No |

**Sobre "no tenés Mac":** no es bloqueante. Codemagic da 500 minutos macOS gratis por mes
(Mac mini M2 a US$ 0,095/min si te pasás), compila, firma y sube a App Store Connect con una
API key. TestFlight instala en tu iPhone sin Mac. Lo único que no podés hacer sin Mac es
correr el simulador localmente — el QA se hace en device por TestFlight.

### 3.3 Legal (las dos tiendas)

- [ ] Reemplazar `EMAIL_DE_CONTACTO` en `store/privacy-policy.md` y `store/terms-and-conditions.md`.
- [ ] Publicar ambos en una URL propia (GitHub Pages sirve) y apuntar `AppConstants.privacyUrl` / `termsUrl`.
- [ ] Reescribir la política: hoy dice que la app "abre WhatsApp con el mensaje ya cargado
      [del cuadro]" y que "te avisa dentro de la app sobre cambios" — ninguna de las dos existe.
- [ ] Si Pro se lanza: los términos §1/§5 dicen que no se paga nada dentro de la app. Cambiar
      antes de crear los productos en las tiendas.
- [ ] Términos: agregar borrado de cuenta, retención de datos y jurisdicción (UY).

---

## 4. Bugs y riesgos de código (verificados, no sospechas)

### 4.1 🔴 El registro en 3 pasos pierde los datos si hay confirmación por email

`lib/features/auth/signup_screen.dart:205-212`: si `session == null` (confirmación pendiente,
que es el **default** de Supabase) muestra "cuenta creada, confirmá tu email" y manda a
`/login`. Los campos de los pasos 2 y 3 (usuario, fecha de nacimiento, género, deportes)
**nunca se escriben**.

La fila de `profiles` la crea el trigger `handle_new_user()` (`supabase/migrations/0001_profiles.sql:41-55`)
y **solo copia `full_name`**. Además el default de `sports` es `'{football}'`, así que quien
eligió sólo pádel aparece con fútbol.

Efecto: el usuario confirma el mail, entra y cae en `/complete-profile` a cargar otra vez todo
lo que ya había cargado. Es el peor momento posible para pedirle algo dos veces.

**Fix recomendado (2-4 h):** mandar los campos como metadata en `signUp(..., data: {...})` y
extender el trigger para que los copie (`username`, `birth_date`, `gender`, `sports`). Cuidado
con el `username` único: si está tomado, el insert del trigger falla y el alta entera revienta
con un 500 — el trigger tiene que resolver el username con `null` + aviso, no con excepción.
Alternativa más barata (1 h): guardar el borrador en `SharedPreferences` y aplicarlo en el
primer `/complete-profile`.

### 4.2 🟠 Fail-open del paywall: sin red, todos son Pro

`lib/data/billing/play_billing_service.dart:37`: `isPro => _products.isEmpty || _entitled.isNotEmpty`.
Es intencional (no bloquear testers) pero tiene dos consecuencias reales:

- Si `queryProductDetails` falla (sin red, Play caído), `_products` queda vacío y **todos**
  tienen Pro gratis. Fuga de ingresos silenciosa.
- No hay verificación server-side: el entitlement vive en el proceso. Un usuario con el APK
  modificado o un reembolso queda Pro hasta reinstalar.

**Fix (medio día + backend):** columna `pro_until timestamptz` en `profiles`, edge function que
valide el `purchaseToken` contra Play Developer API / App Store Server API, y `isPro` leyendo de
la base. El cliente sólo muestra el estado. Es el único punto del proyecto donde el cliente
"decide" algo que vale plata.

### 4.3 🟠 Sobreventa: la base no impide confirmar más equipos que el total

No hay constraint ni trigger que rechace confirmar el equipo 13 en un torneo de 12. El único
guard es la UI (`lib/features/organizer/event_requests_screen.dart:293` y `:758`). El trigger
`sync_inscription_status()` marca `full` cuando se pasa, pero no revierte ni avisa. Un
organizador que confirme desde dos dispositivos a la vez (o con la pantalla desactualizada)
puede sobrevender.

**Fix (1-2 h):** `raise exception` en el trigger cuando `confirmed + manual_confirmed >
total_teams` (con `errcode` propio y mensaje en español para mostrarlo tal cual).

### 4.4 🟡 Registro con confirmación de email + límite de envío

Supabase Free permite ~2 correos de auth por hora con su servicio integrado. Con 15 testers
del test cerrado registrándose el mismo día, la mitad no recibe nada y va a pensar que la app
está rota. **Fix:** SMTP propio (Resend free: 3.000/mes) o plan Pro (US$ 25/mes). Esto no es
código, es configuración, y es más urgente que casi todo lo demás.

### 4.5 🟡 No hay nada de observabilidad

Cero crash reporting, cero analytics. El día 1 en producción no vas a saber si la app crashea,
en qué pantalla abandonan ni cuántas inscripciones se confirman. Play Vitals te da crashes
Android; para el embudo no tenés nada. **Fix:** Sentry Flutter (free 5k eventos) + Firebase
Analytics (free) — 3-4 h, sin tocar la lógica.

### 4.6 🟡 Sin notificaciones: el marketplace no tiene forma de volver a llamar

Un pedido de inscripción depende de que el organizador abra la app. Sin push, el jugador queda
en el aire y el organizador pierde el pedido. **Fix mínimo (6-8 h):** Supabase + FCM
(`firebase_messaging`) con un trigger/edge function en `inscriptions` insert y
`status` change. Para iOS necesita APNs key en Firebase.

### 4.7 🟢 Deuda menor

- `lib/core/utils/format.dart:3,39` — comentarios dicen "ARS" (resabio del rebase argentino).
- `README.md:118` dice "103 tests", son 107.
- `LAUNCH.md:117` dice que la app "ya comparte el cuadro por WhatsApp": no comparte nada.
- Nombre: "Bracket" está tomado por al menos 5 apps (`Bracket App`, `My Bracket`,
  `Bracket Maker` ×3) en App Store y Play. El título funciona, pero perdés toda la búsqueda
  genérica; el ASO se gana en "torneos" + "cuadro", no en "bracket".

---

## 5. Plan de publicación (realista a 5-10 h/semana)

Cada fase tiene criterio de aceptación. No arranques la siguiente sin cerrar la anterior.

### Fase 0 — Decisiones y trámites (semana 1, 6-8 h)
- [ ] **Decisión de producto:** ¿el cuadro se construye antes de publicar o se reescribe la ficha?
- [ ] Crear Apple Developer Program (US$ 99) y Play Console (US$ 25). La verificación de
      identidad tarda días: hacelo el día 1.
- [ ] Elegir y comprar dominio si vas a usar uno para legal (o GitHub Pages).
- [ ] SMTP propio en Supabase (Resend) para matar el límite de 2 correos/hora.
- [ ] Pegar la anon key en `.release.env` (hoy está vacía; sin ella no hay build real).
- **Criterio:** cuentas creadas y SMTP enviando un correo de prueba.

### Fase 1 — Cerrar los bloqueantes de código (semana 2, 8-10 h)
- [ ] 4.1 bug de registro (metadata + trigger).
- [ ] Borrado de cuenta in-app: `deleteAccount` en `AuthRepository`, `on delete cascade` ya
      existe en las tablas, pantalla en Perfil con doble confirmación. **Requisito Apple.**
- [ ] 3.2 sobreventa (trigger con `raise`).
- [ ] Privacidad y términos reales, con email y URL, publicados y linkeados.
- [ ] Ficha honesta (ver §6.1 para el texto corregido).
- **Criterio:** `flutter analyze` limpio, tests ≥ 112, borrado de cuenta probado en device
  contra el backend real.

### Fase 2 — Build y test cerrado Android (semana 2-3, 4 h + 14 días de reloj)
- [ ] `./scripts/build-release.sh` con `.release.env` real → AAB firmado.
- [ ] Smoke test en tu teléfono con ese AAB exacto: alta → crear torneo → inscribirse →
      confirmar → ver el cambio en las dos cuentas.
- [ ] Subir a **test cerrado**, invitar 15 personas (no 12; si alguien se cae, el reloj
      reinicia). Grupo de WhatsApp con recordatorio diario.
- **Criterio:** 12+ testers opt-in durante 14 días corridos y app abierta a diario.

### Fase 3 — iOS (semanas 3-4, 8-10 h, en paralelo con el reloj)
- [ ] `com.bracket.torneos` en App Store Connect; Apple Service ID + `.p8` para el provider
      Apple de Supabase; redirect URL ya declarada.
- [ ] `ios/Podfile` (se genera al primer build), `flutter_launcher_icons` ya tiene los assets.
- [ ] `PrivacyInfo.xcprivacy` + `ITSAppUsesNonExemptEncryption=false` + descripción de
      ubicación en español.
- [ ] `codemagic.yaml` en el repo: analyze → test → `build ipa` → subir a App Store Connect
      con API key. 500 min/mes cubren de sobra.
- [ ] TestFlight interno en tu iPhone: mismo smoke test que Android.
- **Criterio:** build en TestFlight, instalado y probado en device.

### Fase 4 — Producción y lanzamiento (semana 5-6, 4 h)
- [ ] Play: pedir acceso a producción (día 15) con números reales de testers y tests.
- [ ] Rollout escalonado 20% → 50% → 100%.
- [ ] iOS: enviar a revisión con cuenta demo y nota para el revisor explicando que el pago de
      la inscripción se coordina por WhatsApp fuera de la app (evita el malentendido de IAP).
- [ ] Responder cada review (las primeras 20 reviews mueven el ranking).
- **Criterio:** las dos apps públicas y sin crashes en Vitals la primera semana.

**Total: 30-40 h de trabajo propio + 14 días de espera inevitable de Google.**

---

## 6. Plan de marketing

La regla del marketplace: **los organizadores son la oferta, los jugadores la demanda**. Una
lista vacía es una app muerta. Todo el marketing antes de tener 3 torneos activos es tirar plata.

### 6.1 Antes de gastar un peso (fase 0 de marketing)
- [ ] **5 organizadores ancla** de Montevideo con "te armo el torneo, no pagás nada" (2-3 h
      cada uno, hacelo vos). Cada uno trae 8-16 equipos = tu primera audiencia real.
- [ ] Un torneo **en curso** durante el lanzamiento: la app se muestra con datos vivos, no con
      una pantalla vacía.
- [ ] Capturas y feature graphic. Sin gráficos no hay publicación.

### 6.2 Canales, en orden de retorno esperado

| Canal | Qué hacer | Costo | Por qué |
|---|---|---|---|
| **WhatsApp** | Mensaje con el link del torneo en los grupos donde ya se coordinan los partidos. Pedirle a cada organizador ancla que lo mande a su grupo | $0 | Es donde el público objetivo vive. Acá se gana o se pierde |
| **Complejos y clubes** | Un póster A3 con QR por complejo. Hay **28 clubes de pádel registrados en Montevideo** (padelvs.com) y decenas de complejos de fútbol 5 | ~$U 1.500 impresión | Tráfico físico con intención altísima |
| **Instagram Reels** | 3 por semana, 15-20 s: "armás el torneo en 30 segundos", "así se anotan los equipos", "el cuadro se actualiza solo" (sólo cuando exista) | $0 | El fútbol 5 amateur se consume en Reels/TikTok |
| **Facebook grupos** | Grupos de "fútbol 5 Montevideo", "pádel UY", "busco equipo" | $0 | Sigue siendo el canal de coordinación de las ligas barriales |
| **Alianza con organizadores** | El organizador difunde porque le resuelve la organización; vos le das visibilidad en Explore (eso es una feature de Pro) | $0 | Crecimiento con incentivo alineado |
| **Paid ads** | **No antes** de tener retención medida y 3+ torneos activos. Después: US$ 3-5/día geo Montevideo | US$ 90-150/mes | Con producto vacío, el CPA se come cualquier ingreso |

### 6.3 Calendario de 90 días
- **Semanas 1-2:** reclutar 5 organizadores ancla. Cero publicidad. Armar gráficos.
- **Semanas 3-4:** test cerrado = primera comunidad (15 personas que ya son usuarios reales).
- **Semana 5:** lanzamiento Android + Reels 1 ("así organicé mi torneo en 5 minutos") + pósters.
- **Semana 6:** lanzamiento iOS + Reels 2 + push a los grupos de WhatsApp de los anclas.
- **Semanas 7-8:** 10 organizadores activos. Primer pedido de feedback formal.
- **Semanas 9-12:** primer torneo con inscripción llena 100% desde la app. Ese es el caso de
  éxito que se convierte en el contenido del mes 4.

### 6.4 Métricas que importan (y hoy no podés medir)
Instalaciones · % que abre Explore con ubicación · **inscripciones por torneo** ·
ratio inscripción/confirmación · **organizadores activos por mes** (la métrica que decide si
esto vive) · retención D7/D30 · costo por organizador conseguido.
Sin analytics (§4.5) no vas a poder responder "¿funcionó el Reel?" — instalalo antes del lanzamiento.

### 6.5 Ficha corregida (para lo que la app hace hoy)

**Título:** `Bracket - Torneos cerca tuyo` (29 caracteres, está bien).

**Descripción corta (79):**
`Inscribite a torneos amateur cerca tuyo. Organizá el tuyo y confirmá equipos.`

**Descripción larga (honesta):**
```
Bracket es la app para encontrar y organizar torneos amateur cerca tuyo.

Para jugadores: mirá en el mapa los torneos de fútbol 5, fútbol 7, pádel, tenis y básquet
que se juegan cerca, filtrá por deporte y distancia, y anotate en segundos. Coordinás el pago
directo con el organizador por WhatsApp, sin comisiones ni pagos dentro de la app.

Para organizadores: creá el torneo con fecha, sede y cupo; recibí solicitudes de inscripción;
confirmá o rechazá equipos y avisales por WhatsApp con un toque. También podés sumar los
equipos que confirmaste en persona, para que el cupo siempre esté al día.

- Mapa y lista de torneos cerca tuyo
- Inscripción desde el celular, sin filas ni planillas
- Confirmación del organizador con aviso por WhatsApp
- Cupos actualizados en tiempo real
- Gratis para jugadores

Tu torneo empieza acá.
```
Cuando el cuadro exista, ahí sí: "el cuadro se arma solo y se actualiza con cada resultado"
pasa a ser el primer bullet.

---

## 7. Costos de mantenimiento

### 7.1 Plata (valores en USD, fuentes en §10)

| Ítem | Año 1 | Año 2+ | Nota |
|---|---|---|---|
| Google Play Console | 25 (único) | 0 | pago único |
| Apple Developer Program | 99 | 99 | anual, obligatorio mientras la app esté publicada |
| Dominio (si usás uno propio) | 15 | 15 | GitHub Pages es gratis |
| Supabase Pro | 300 (25/mes) | 300 | **necesario**: Free no tiene backups y pausa por inactividad |
| SMTP (Resend) | 0 | 0 | free tier 3k/mes |
| Crash + analytics (Sentry, Firebase) | 0 | 0 | free tiers suficientes |
| Builds iOS (Codemagic) | 0 | 0-120 | 500 min/mes gratis; a US$ 0,095/min si te pasás |
| Tiles de mapa (OSM público) | 0 | 0-600 | gratis mientras sea chico; si crece, MapTiler/Stadia |
| **Total caja** | **139** | **414-1.134** | |
| Marketing (opcional) | 0-1.200 | 0-1.200 | sólo después de validar |

### 7.2 Tiempo (el costo real)

| Tarea | h/año |
|---|---|
| Soporte y bugs | 104 (2 h/sem) |
| Releases (2 tiendas × 4/año, con revisión) | 32 |
| Backend / infra / migraciones | 52 (1 h/sem) |
| Contenido y marketing | 78 (1,5 h/sem) |
| **Total** | **≈ 266 h/año ≈ 5 h/semana** |

Eso es exactamente tu presupuesto semanal para el emprendimiento. Es decir: **Bracket consume
todo el tiempo disponible**. Si además querés construir el cuadro (2-3 semanas) y push
(1 semana), el mes 1 está copado antes de empezar.

### 7.3 Costos que aparecen recién cuando crece
- Supabase: >500 MB de base o >5 GB de egress → Pro/Team (25-599/mes).
- Tiles OSM: la política prohíbe uso comercial intensivo → proveedor pago (~25-50/mes).
- Alguien revisando reviews y soporte: hoy sos vos; es lo primero que se paga cuando hay ingresos.
- Impuestos: Apple/Google actúan como merchant of record y te pagan neto de su comisión. Lo que
  te pagan es exportación de servicios — **consultá a un contador** el tratamiento de IVA y
  pedí/entregá el W-8BEN. Los números de §8 son brutos menos comisión de tienda, sin impuestos.

---

## 8. Predicción de ganancias

Precios propuestos: **US$ 4,99/mes** y **US$ 34,99/año** (el anual es el que conviene empujar:
cobra un año y reduce el churn a cero por 12 meses). Comisión: **15%** en las dos tiendas
(Apple Small Business Program y el tier de 15% de Play — hay que inscribirse, no es automático).
Neto por suscriptor con mix 60% mensual / 40% anual: **US$ 3,68/mes (US$ 44,14/año)**.

### 8.1 Escenarios año 1 (Uruguay)

| Escenario | Instalaciones | Organizadores | Pagos | Bruto neto/año | Neto/mes | vs. infra (439) |
|---|---|---|---|---|---|---|
| A — pesimista | 200 | 6 | 1 | US$ 44 | US$ 3,68 | −395 |
| B — base | 1.500 | 25 | 7 | US$ 309 | US$ 25,75 | −130 |
| C — optimista | 5.000 | 70 | 20 | US$ 883 | US$ 73,56 | **+444** |

El escenario base asume un 28% de conversión de organizadores a pago, que para un SaaS B2B de
nicho es **optimista**, no conservador. Con 20% real: US$ 18/mes.

### 8.2 Puntos de equilibrio

| Qué tiene que cubrir | Suscriptores pagos necesarios |
|---|---|
| Infraestructura año 1 (US$ 439) | 10 |
| Infraestructura año 2 (US$ 414) | 9,4 |
| Infra + 266 h/año a US$ 15/h | 98 |
| Infra + 266 h/año a US$ 25/h | 157 |
| Infra + 266 h/año a US$ 40/h | 245 |

**245 organizadores pagos en Uruguay no existen.** Con 150 organizadores activos (que ya sería
un excelente año) y 20% de conversión son 30 pagos = **US$ 110/mes netos**. Es un ingreso
marginal a cambio de ~5 h/semana.

### 8.3 Entonces, ¿qué haría que esto sí sea negocio?

Por orden de retorno sobre esfuerzo:

1. **B2B / white label (el mejor candidato).** Un club o complejo paga US$ 50-100/mes por su
   propio espacio de torneos con su marca. 10 clubes = US$ 500-1.000/mes con **el mismo
   código**. Se vende y se cobra fuera de las tiendas (factura, no IAP), así que no hay 15% ni
   revisión. Los 28 clubes de pádel de Montevideo son una lista de llamadas, no un mercado
   teórico.
2. **Regional.** Lo mismo que hoy, pero en Argentina/México hay 20-50× el volumen. El costo es
   localización (los ARB ya están preparados), soporte en otra zona horaria y competencia real
   (hay apps de torneos con años de ventaja). No lo haría antes de validar UY.
3. **El loop del cuadro.** Si el cuadro existe, cada organizador que lo comparte por WhatsApp
   trae 8-16 jugadores sin que pongas un peso en ads. Es el único mecanismo de crecimiento
   orgánico que este producto puede tener. **Sin cuadro no hay loop, y sin loop el CAC lo
   pagás siempre vos.**

Lo que no cambiaría nada: subir el precio. Con 20 pagos, duplicar el precio te deja en US$ 147/mes
y probablemente te baja la conversión. El problema es el número de organizadores, no el precio.

---

## 9. Qué NO construir todavía

- **Pagos dentro de la app** (retiene equipos, cobra comisión). Suma obligaciones de Play
  Billing/StoreKit, disputas, reembolsos y responsabilidad por plata de terceros. En Uruguay,
  además, rails de pago propios.
- **Chat interno.** Moderación, reportes, bloqueo, y de golpe sos responsable de contenido
  (y de menores). WhatsApp ya resuelve esto y es donde están.
- **Ranking global / gamificación / puntos.** Necesita masa crítica; con 30 torneos un ranking
  es un cuadro vacío.
- **Web pública con SEO.** Es la jugada correcta para el año 2 (torneos indexados en Google),
  pero hoy no hay torneos que indexar.
- **iPad / tablet layout, watch, widgets.** Cero retorno en la etapa actual.
- **Cuadro complejo (ligas + playoffs + ida y vuelta + tercer puesto).** Si construís el cuadro,
  empezá por eliminación simple con llaves de 4/8/16 y listo. El 90% de los torneos amateur es eso.

---

## 10. Anexo

### 10.1 Fuentes de los números externos
- Apple Developer Program US$ 99/año — https://developer.apple.com/programs/whats-included/
- Apple Small Business Program (15% bajo US$ 1M) — https://developer.apple.com/app-store/small-business-program/
- Google Play: US$ 25 pago único — https://support.google.com/googleplay/android-developer/answer/112622
- Test cerrado 12 testers × 14 días (cuentas personales post 13/11/2023) — https://support.google.com/googleplay/android-developer/answer/14151465
- Supabase planes y pausa de proyectos Free — https://supabase.com/pricing · https://supabase.com/docs/guides/platform/free-project-pausing
- Codemagic: 500 min/mes gratis, Mac mini M2 US$ 0,095/min — https://codemagic.io/pricing/
- Uruguay: 3,15 M de usuarios de internet, 91% de hogares con acceso, 99% se conecta desde el
  móvil (ICEX e-País 2025) — https://www.icex.es/content/dam/icex/centros/uruguay/documentos/2025/resumen-ejecutivo-informe-e-pais-comercio-electronico-uruguay-2025.pdf
- Pádel: 28 clubes registrados en Montevideo — https://padelvs.com/padel/montevideo
- Cuota iOS vs Android en Uruguay: **consultar el número del mes** en
  https://gs.statcounter.com/os-market-share/mobile/uruguay — no lo afirmo acá porque cambia.

**No verificado y por eso no lo uso:** porcentaje exacto de iOS en UY; tasa de conversión de
organizadores a pago (no hay dato público de este nicho — los 20-28% de §8 son supuestos, están
etiquetados como tales); precio promedio de inscripción a un torneo amateur en Montevideo.

### 10.2 Re-verificación (copiar y pegar)
```bash
cd ~/Development/apps/amateur_tournaments
flutter analyze
flutter test
grep -rn "cuadro\|llave\|partido\|resultado" lib || echo "0: no hay cuadros ni resultados"
grep -rn "deleteAccount" lib || echo "0: no hay borrado de cuenta"
grep -rn "firebase\|sentry\|analytics" lib pubspec.yaml || echo "0: sin push/analytics/crash"
ls ios/Podfile 2>/dev/null || echo "0: iOS nunca compilado"
grep -c DEVELOPMENT_TEAM ios/Runner.xcodeproj/project.pbxproj
find store -type f
grep -n "EMAIL_DE_CONTACTO" store/*.md
```

### 10.3 Orden de ejecución si tenés 10 horas esta semana
1. Crear las dos cuentas de developer (hoy, la verificación tarda).
2. SMTP propio en Supabase (30 min).
3. Ficha honesta + privacidad con email y URL (2 h).
4. Bug de registro §4.1 (3 h).
5. Borrado de cuenta (3 h).
6. Commit de todo, incluido tu trabajo de Pro.
