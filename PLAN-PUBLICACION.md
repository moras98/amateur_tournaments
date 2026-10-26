# Publicación iOS + Android — Bracket

Auditoría técnica, plan de publicación, plan de marketing y modelo económico.
Base: `main` @ `c30ecd7` (incluye el scaffolding de Bracket Pro, ya commiteado). Fecha: 26 de
octubre de 2026. **Alcance: publicación global (todas las tiendas/territorios) + emails por
Resend.** Lo global cambia tres cosas: el modelo de ingresos (§8), la estrategia de crecimiento
(§6) y dos límites del código que hoy sólo se ven con datos de un país (§4.8 y §4.9).

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
   logout) y la política y los términos tienen `EMAIL_DE_CONTACTO` y no tienen URL pública.
   Con Resend el problema del email cambia de forma pero no desaparece: no hay **recuperar
   contraseña** (§4.4) y el link de confirmación no vuelve a la app (§4.1), así que quien se
   registra queda a mitad de camino y quien olvida la clave pierde la cuenta para siempre.
4. **Un bug real de pérdida de datos en el registro.** Si "Confirm email" está activo (default
   de Supabase), el alta en 3 pasos tira a la basura usuario, fecha de nacimiento, género y
   deportes: la fila de `profiles` solo recibe el nombre (ver §4.1).

Global agrega dos bloqueantes de código que no se notan con 20 torneos de prueba y sí con
datos de varios países: la consulta de torneos **no filtra por cercanía ni pagina** (trae todo
lo que hay, con el tope de 1000 filas de PostgREST) y la **moneda está hardcodeada** a peso
uruguayo (§4.8 y §4.9). Publicar en 175 países es gratis; lo que no es gratis es que la app
funcione igual de bien en todos.

Los números, sin maquillaje: con suscripción de organizador **no se paga el tiempo** a ninguna
escala razonable. La infraestructura global cuesta **US$ 679 el primer año** (Play 25 + Apple 99
+ dominio 15 + Supabase Pro 300 + Resend Pro 240) = **16 suscriptores**. Cubrir el tiempo
(266 h/año) son **110-267 suscriptores**. Lo que sí cambia el resultado es vender a clubes y
complejos fuera de las tiendas: **5 clubes a US$ 75/mes cubren el tiempo a US$ 15/h**, y 8 clubes
lo cubren a US$ 25/h. Ese es el modelo que escala globalmente; la suscripción individual es el
complemento.

**Recomendación en una línea:** 3-4 semanas hasta Android en producción y 5-6 hasta iOS, con
disponibilidad global desde el día 1 pero **una sola ciudad como mercado inicial**. Antes de
gastar en marketing, decidí si el cuadro se construye (2-3 semanas) o si la ficha se reescribe
para lo que hay: sin cuadro no hay loop de WhatsApp y el nombre promete otra cosa.

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
- [ ] Términos: agregar borrado de cuenta, retención de datos y jurisdicción.
- [ ] **Global = GDPR/LGPD/CCPA.** Si la app se puede descargar en la UE tenés obligaciones
      reales: base legal, DPA con Supabase/Resend/Apple/Google, exportación y borrado de datos
      (el borrado in-app que ya hay que hacer para Apple sirve para esto), y evaluación de
      transferencias internacionales según la región del proyecto Supabase. Para Brasil (LGPD)
      lo mismo. No es un abogado: es una lista de tres documentos. Si preferís arrancar sin la
      UE, Play y App Store permiten limitar territorios y ampliar después.

### 3.4 Global: qué cambia de verdad (y qué no)

**Lo que NO cambia:** el costo de publicar. Play y App Store cobran lo mismo por 1 país que por
175, y la app ya es es/en. Marcar "todos los territorios" es gratis y no agrega trabajo.

**Lo que SÍ cambia:**

| Tema | Estado | Qué hacer |
|---|---|---|
| Idiomas de tienda | ⬜ sólo es (y en en el repo) | Ficha localizada en **es** y **en** como mínimo; pt-BR es el siguiente por tamaño de mercado de fútbol/pádel |
| Voseo | ⚠️ todo `es*` cae en `es_UY` ("Creá", "anotate") | En México/España suena extranjero. Con `es_UY` como fuente, agregar `es` neutro es trabajo de traducción, no de código — patearlo a la fase 2 |
| Moneda | ❌ hardcodeada a `$` uruguayo (§4.9) | Un organizador de Madrid escribe 25 y la app muestra "$ 25" |
| Escala de datos | ❌ sin filtro geográfico ni paginación (§4.8) | Con 1000+ torneos el "cerca tuyo" empieza a mentir en silencio |
| Precios por país | ⬜ | Activar tiers por poder de compra (Apple "alternate tiers", Google PPP): US$ 4,99 en Brasil es caro, en Suiza es barato |
| Impuestos | ✅ | Apple y Google son merchant of record y liquidan VAT/GST; vos facturás exportación de servicios en UY |
| ASO | ❌ "Bracket" está tomado 5+ veces | Global empeora la colisión: el título solo no te encuentra nadie. Se gana con "torneos/cuadro/inscripción" en la descripción |
| Soporte | ⬜ | Global = husos horarios y otro idioma en las reviews. Responder en 24 h desde el día 1 |

**Decisión estratégica: publicar global ≠ lanzar global.** El producto es un marketplace por
ciudad: los organizadores son la oferta y son locales. Abrir 175 territorios el mismo día es la
forma más rápida de tener 175 listas vacías, que es peor que 1 lista vacía porque nadie vuelve a
mirar. La secuencia recomendada: **disponibilidad global, go-to-market en una ciudad por vez**
(§6.3), con un playbook repetible de 3 semanas por ciudad, y B2B (clubes/complejos) como el canal
que no depende de que la ciudad tenga densidad.

### 3.5 Resend: configuración exacta y lo que destapa

Resend es la elección correcta (el servidor de email integrado de Supabase **sólo entrega a
direcciones pre-autorizadas del equipo** — con eso no se puede registrar nadie).

| Paso | Valor |
|---|---|
| Dominio | Verificar un dominio propio en Resend con **SPF + DKIM** (y DMARC). No se puede enviar desde gmail/outlook |
| Supabase → Auth → SMTP | Host `smtp.resend.com` · Puerto `465` (SSL) · Usuario `resend` · Contraseña = API key de Resend |
| Sender | `no-reply@tudominio` con nombre "Bracket" (no uses una dirección que reciba: sin buzón, las respuestas se pierden) |
| Rate limit | Al habilitar SMTP propio Supabase queda en **30 correos/hora** por defecto → subilo en Auth → Rate Limits (100-200/h) |
| Límite real | Resend Free = **3.000/mes y 100/día** → día de lanzamiento con 300 altas te quedás sin emails. Pro US$ 20/mes = 50.000 |
| Plantillas | Dashboard → Auth → Email Templates: confirmación y recuperación, con la marca (`#0F3B2A` / `#1B8A5A`). Supabase **no** tiene plantillas multi-idioma: o una bilingüe, o el "Send Email Hook" con la API de Resend para elegir idioma por `user_metadata.locale` (verificar disponibilidad en tu dashboard) |
| Redirect | Agregar `io.supabase.amateurtournaments://login-callback` a **Redirect URLs** y pasar `emailRedirectTo` en `signUp` (hoy no se pasa: §4.1) |

Con esto, la parte de Resend es **1-2 h de configuración + 2-3 h de plantillas**. Lo que no
resuelve Resend es el código que falta alrededor: recuperar contraseña (§4.4) y que el link de
confirmación vuelva a la app (§4.1).

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

**Y hay una segunda mitad del mismo bug:** `signUp` (`lib/data/auth/supabase_auth_repository.dart:52`)
**no pasa `emailRedirectTo`** (0 coincidencias en todo `lib/`), así que el link del correo apunta
al `SiteURL` del proyecto — una página web, no la app. El usuario confirma en el navegador y la
app nunca se entera (o cae en `/login` a adivinar). Con Resend esto se arregla al mismo tiempo:
pasar `emailRedirectTo: AppConstants.oauthRedirectUrl`, agregar esa URL a Redirect URLs y usar
`{{ .ConfirmationURL }}` en la plantilla.

Los dos arreglos juntos son el flujo completo de alta: **5-6 h** y es la primera cosa que hay que
hacer, porque sin eso el test cerrado de Google se llena de gente que "no puede entrar".

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

### 4.4 🔴 No existe "olvidé mi contraseña"

`AuthRepository` (`lib/data/auth/auth_repository.dart:60-82`) expone `signIn`,
`signInWithOAuth`, `signUp`, `isEmailRegistered` y `signOut`. **No hay `resetPassword`**, y en
todo `lib/` hay 0 coincidencias de `reset`, `forgot`, `olvid`, `restablec` o `recovery`.

Consecuencia: quien se registra con email y contraseña y la olvida **pierde la cuenta para
siempre**. No es un detalle de UX: es la diferencia entre un usuario que vuelve y uno que
reinstala, crea otra cuenta y te deja datos huérfanos (inscripciones a torneos que ya no puede
cancelar). Con Resend ya configurado es barato:

1. `resetPasswordForEmail(email, redirectTo: AppConstants.oauthRedirectUrl)` en el repositorio.
2. Pantalla `/forgot-password` con el input y el aviso "te mandamos un correo".
3. Pantalla `/reset-password` que recibe la sesión de recuperación y pide la clave nueva.
4. Plantilla de "recovery" en Resend con la marca.

**Esfuerzo: 6-8 h.** Para una app global con registro por email, Apple lo va a notar (un revisor
que no puede recuperar la clave es un revisor que rechaza), y es la mitad que falta para que
Resend sirva de algo.

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

### 4.8 🔴 Global: la consulta de torneos no filtra por cercanía ni pagina

`lib/data/repositories/supabase/supabase_tournament_repository.dart:41-42`:

```dart
final rows = await request.order('start_time');
```

Sin `.limit()`, sin `.range()`, sin filtro de fechas y sin caja geográfica. El radio de
"cerca tuyo" se aplica **después**, en el cliente (`:46-60`, comentario incluido: "a PostGIS RPC
is the upgrade path"). Con datos de una ciudad funciona perfecto; con datos globales:

- PostgREST corta en **1000 filas** por defecto (max rows): pasando eso, cada usuario ve un
  subconjunto arbitrario ordenado por `start_time`, **no los más cercanos**. La promesa del
  producto se rompe sin error, sin log y sin crash.
- Se traen también los torneos de 2023 al inicio de la lista, así que el tope se alcanza antes
  de lo que parece.
- Cada `fetchTournaments` dispara además una segunda consulta (`_confirmedCounts`) con los ids
  de esas filas.

**Fix (4-6 h + 1 migration):**
1. Filtro de fechas server-side: `.gte('end_time', nowIso)` (los torneos viejos no le importan a
   nadie y es lo que más crece).
2. Caja geográfica server-side con el centro del mapa/ubicación: `.gte('latitude', minLat)` etc.
   (±0.5° ≈ 55 km, más que suficiente para el radio máximo de la UI). Sin PostGIS.
3. `.limit(200)` + paginación incremental cuando el usuario mueve el mapa.
4. Índices: `(end_time)`, `(latitude, longitude)` y `(sport, start_time)`.
5. Test que falle con >1000 filas simuladas (el mock no lo va a detectar nunca).

### 4.9 🟠 Global: la moneda está hardcodeada a peso uruguayo

`lib/core/utils/format.dart:47-57`: `formatCost` formatea siempre con `locale: appLocale`
(`es_UY`), `symbol: '$'` y patrón `$ #,##0`. Un organizador de Madrid que escribe 25 ve
"$ 25"; uno de México que escribe 2500 ve "$ 2.500", que en México se lee como 2.500 pesos
pero en EE.UU. como 2,5 dólares. El número lo carga el organizador; la moneda la inventa la app.

**Fix mínimo (4-6 h):** columna `currency text not null default 'UYU'` en `tournaments`, con la
moneda del país del organizador como default (el mismo lookup de país que ya existe para el
código telefónico: `lib/core/utils/country_code.dart`), y `formatCost` usando
`NumberFormat.currency(locale: localeDelUsuario, name: currency)`. En la UI de creación, un
selector de moneda junto al monto. Ojo: las inscripciones se pagan **fuera de la app**, así que
esto es información, no un cobro — no hace falta conversión ni tipo de cambio.

## 5. Plan de publicación (realista a 5-10 h/semana)

Cada fase tiene criterio de aceptación. No arranques la siguiente sin cerrar la anterior.

### Fase 0 — Decisiones y trámites (semana 1, 6-8 h)
- [ ] **Decisión de producto:** ¿el cuadro se construye antes de publicar o se reescribe la ficha?
- [ ] Crear Apple Developer Program (US$ 99) y Play Console (US$ 25). La verificación de
      identidad tarda días: hacelo el día 1.
- [ ] **Dominio propio** (Bracket + Resend lo necesitan: no se puede verificar un dominio que no
      tenés, y sin dominio verificado Resend no entrega).
- [ ] **Resend**: cuenta, dominio verificado (SPF/DKIM/DMARC), SMTP en Supabase (§3.5), rate
      limit a 100-200/h, plantillas de confirmación y recuperación con la marca.
- [ ] Pegar la anon key en `.release.env` (hoy está vacía; sin ella no hay build real).
- [ ] Decidir territorios: global desde el día 1 (§3.4) — es gratis y no agrega trabajo.
- **Criterio:** cuentas creadas, dominio verificado en Resend y un correo de prueba llegando a
  Gmail y a Outlook (no sólo a tu bandeja).

### Fase 1 — Cerrar los bloqueantes de código (semana 2, 12-16 h)
- [ ] §4.1 registro: metadata + trigger + `emailRedirectTo` (las dos mitades del flujo de alta).
- [ ] §4.4 recuperar contraseña: `resetPasswordForEmail`, `/forgot-password`, `/reset-password`.
- [ ] Borrado de cuenta in-app: `deleteAccount` en `AuthRepository`, `on delete cascade` ya
      existe en las tablas, pantalla en Perfil con doble confirmación. **Requisito Apple.**
- [ ] §4.3 sobreventa (trigger con `raise`).
- [ ] §4.8 filtro por fecha + caja geográfica + `.limit()` + índices (esto es lo que hace que
      "cerca tuyo" sea verdad fuera de Montevideo).
- [ ] §4.9 moneda del torneo (columna + selector + `formatCost`).
- [ ] Privacidad y términos reales, con email y URL, publicados y linkeados, con la sección de
      GDPR/LGPD si abrís Europa/Brasil.
- [ ] Ficha honesta y localizada es/en (ver §6.5 y §6.6 para el texto corregido).
- **Criterio:** `flutter analyze` limpio, tests ≥ 120, alta con confirmación + recuperación de
  clave + borrado de cuenta probados en device contra el backend real.

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

**Total: 40-52 h de trabajo propio + 14 días de espera inevitable de Google.** (Lo global suma
~10 h: filtro geográfico, moneda y ficha en inglés; no suma nada en dinero.)

---

## 6. Plan de marketing

La regla del marketplace: **los organizadores son la oferta, los jugadores la demanda**. Una
lista vacía es una app muerta. Todo el marketing antes de tener 3 torneos activos es tirar plata.

Y con publicación global hay una regla más: **el marketing es geográfico aunque la tienda no lo
sea**. La app está en 175 países; el esfuerzo va a **un metro por vez** hasta tener un playbook
que se pueda copiar (3 semanas por ciudad, §6.4). Sin densidad local, el mapa muestra vacío y el
usuario desinstala: es el mismo problema que tendrías en Montevideo, multiplicado por 175.

### 6.1 Antes de gastar un peso (fase 0 de marketing)
- [ ] **5 organizadores ancla del primer metro** (recomendado: Montevideo, por acceso directo)
      con "te armo el torneo, no pagás nada" (2-3 h cada uno, hacelo vos). Cada uno trae 8-16
      equipos = tu primera audiencia real.
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
- **Semanas 1-2:** reclutar 5 organizadores ancla del primer metro. Cero publicidad. Armar
  gráficos y fichas es/en.
- **Semanas 3-4:** test cerrado = primera comunidad (15 personas que ya son usuarios reales).
- **Semana 5:** lanzamiento Android **en todos los territorios** + Reels 1 ("así organicé mi
  torneo en 5 minutos") + pósters en el primer metro.
- **Semana 6:** lanzamiento iOS + Reels 2 + push a los grupos de WhatsApp de los anclas.
- **Semanas 7-8:** 10 organizadores activos. Primer pedido de feedback formal.
- **Semanas 9-12:** primer torneo con inscripción llena 100% desde la app. Ese es el caso de
  éxito que se convierte en el contenido del mes 4.

Ojo con la tentación de "ya que está global, pruebo en otro país": sin un metro que funcione,
el segundo es una distracción. El test de que el playbook está listo es concreto: 10
organizadores activos, 1 torneo lleno desde la app y alguien pidiéndote que abras su ciudad.

### 6.4 Playbook por ciudad (el activo real, y el que hace escalable lo global)

Lo que se repite en cada metro nuevo, en 3 semanas y sin código:

1. **Mapear la oferta:** complejos de fútbol 5 y clubes de pádel con liga propia. (En Montevideo:
   28 clubes de pádel registrados + decenas de complejos de f5.)
2. **Onboarding white-glove de 5 organizadores:** 2-3 h cada uno, vos, gratis.
3. **Un torneo en curso antes de cualquier publicidad.** El mapa con datos vivos convierte; el
   mapa vacío no.
4. **Póster con QR en cada complejo** (el complejo gana visibilidad en la app, no paga nada).
5. **3 Reels grabados en ese metro**, con nombres reales de canchas y barrios: la gente reconoce
   el lugar y baja.
6. **Medir 30 días:** organizadores activos, inscripciones por torneo, retención D7.

Si el paso 6 no da, no abras la ciudad siguiente: cambiá el playbook. Esto es lo que hace que
"global" sea una decisión de tienda y no una fantasía de crecimiento.

### 6.5 Métricas que importan (y hoy no podés medir)
Instalaciones · % que abre Explore con ubicación · **inscripciones por torneo** ·
ratio inscripción/confirmación · **organizadores activos por mes** (la métrica que decide si
esto vive) · retención D7/D30 · costo por organizador conseguido.
Sin analytics (§4.5) no vas a poder responder "¿funcionó el Reel?" — instalalo antes del lanzamiento.

### 6.6 Ficha corregida en español (para lo que la app hace hoy)

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

**Sobre el español global:** Apple y Play dejan localizar `es-419` (LatAm neutro), `es-ES` y
`es-MX` por separado. El voseo de esta ficha es correcto para Uruguay/Argentina y suena
extranjero en México y España. Para la **ficha** conviene `es-419`; para la **app** el voseo es
una decisión aparte (cambiarlo toca ~60 claves del ARB y, si algún día se hace, se hace con
`es` neutro como locale base, no reescribiendo `es_UY`).

### 6.7 Ficha en inglés (locale `en` — obligatorio para publicar global)

**Title** (≤ 30): `Bracket - Tournaments near you`

**Short description** (≤ 80):
`Find amateur tournaments near you, or organize yours and confirm teams.`

**Full description:**
```
Bracket is the app to find and organize amateur tournaments near you.

For players: see football 5-a-side, football 7-a-side, padel, tennis and basketball
tournaments around you on the map, filter by sport and distance, and sign up in seconds.
You arrange payment directly with the organizer on WhatsApp — no fees, no payments inside
the app.

For organizers: create your tournament with date, venue and team limit; receive sign-up
requests; confirm or reject teams and notify them on WhatsApp in one tap. You can also add
the teams you confirmed in person so your open spots always match reality.

- Map and list of tournaments near you
- Sign-up from your phone — no spreadsheets, no group chat chaos
- Organizer confirmation with a WhatsApp notice
- Open spots always up to date
- Free for players

Your tournament starts here.
```

---

## 7. Costos de mantenimiento

### 7.1 Plata (valores en USD, fuentes en §10)

| Ítem | Año 1 | Año 2+ | Nota |
|---|---|---|---|
| Google Play Console | 25 (único) | 0 | pago único |
| Apple Developer Program | 99 | 99 | anual, obligatorio mientras la app esté publicada |
| Dominio propio | 15 | 15 | **obligatorio con Resend** (no se puede verificar un dominio que no tenés; además aloja la política/términos) |
| Supabase Pro | 300 (25/mes) | 300 | necesario: Free no tiene backups y limita los emails |
| **Resend** | **240 (20/mes)** | 240 | Free = 3.000/mes y **100/día**: el día de lanzamiento no alcanza. Pro = 50.000/mes |
| Crash + analytics (Sentry, Firebase) | 0 | 0 | free tiers suficientes |
| Builds iOS (Codemagic) | 0 | 0-120 | 500 min/mes gratis; a US$ 0,095/min si te pasás |
| Tiles de mapa (OSM público) | 0 | 0-600 | gratis mientras sea chico; si crece, MapTiler/Stadia |
| **Total caja** | **679** | **654-1.374** | |
| Marketing (opcional) | 0-1.200 | 0-1.200 | sólo después de validar |
| Contador (tratamiento de exportación de servicios) | 0-300 | 0-300 | única vez si es consulta puntual |

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

## 8. Predicción de ganancias (con publicación global)

Precios propuestos: **US$ 4,99/mes** y **US$ 34,99/año** (empujar el anual: cobra un año y
elimina el churn por 12 meses). Comisión **15%** en las dos tiendas (Apple Small Business
Program y el tier de 15% de Play — hay que inscribirse, no es automático). Neto por suscriptor
con mix 60% mensual / 40% anual: **US$ 3,54/mes (US$ 42,44/año)**.

Precios por país: activá los tiers por poder de compra (Apple *alternate tiers*, Google PPP).
US$ 4,99 en Brasil es caro (≈ R$ 27) y en Suiza es barato; sin ajuste, la conversión cae donde
está el volumen.

### 8.1 Escenarios año 1

La unidad de medida global no es el país, es el **metro con organizadores activos**. Escenarios
con disponibilidad global desde el día 1 y GTM en un metro por vez (§6.4):

| Escenario | Metros con tracción | Organizadores activos | Pagos (20%/15%) | Suscripciones neto/mes | Clubes B2B | B2B/mes | **Total/mes** |
|---|---|---|---|---|---|---|---|
| A — 1 metro flojo | 1 | 25 | 5 | US$ 18 | 0 | — | **US$ 18** |
| B — 1-2 metros | 1-2 | 100 | 20 | US$ 71 | 0 | — | **US$ 71** |
| C — 5 metros | 5 | 250 | 38 | US$ 135 | 0 | — | **US$ 135** |
| D — B + 5 clubes | 1-2 | 100 | 20 | US$ 71 | 5 | US$ 375 | **US$ 446** |
| E — 5 metros + 15 clubes | 5 | 250 | 38 | US$ 135 | 15 | US$ 1.125 | **US$ 1.260** |

Dos cosas para leer en esa tabla:

- La columna de suscripciones crece **lento y lineal con el esfuerzo de venta**, porque cada
  organizador hay que conseguirlo a mano. Cinco metros y 250 organizadores es un año de trabajo
  sostenido a 5-10 h/semana, no un resultado de lanzamiento.
- La fila D es la que importa: **5 clubes aportan 5× lo que 20 suscripciones**. El B2B es la
  única línea que crece sin depender de que cada jugador descubra la app.

### 8.2 Puntos de equilibrio

| Qué tiene que cubrir | Suscriptores pagos | o clubes B2B (US$ 75/mes) |
|---|---|---|
| Infraestructura año 1 (US$ 679) | 16 | 1 |
| Infraestructura año 2 (US$ 654) | 15 | 1 |
| Infra + 266 h/año a US$ 15/h | 110 | 5 |
| Infra + 266 h/año a US$ 25/h | 173 | 8 |
| Infra + 266 h/año a US$ 40/h | 267 | 13 |

**Ese es el cambio que trae lo global:** los 267 suscriptores siguen siendo improbables, pero
**8 clubes pagando US$ 75/mes es alcanzable** y no depende de tener masa de jugadores en 175
países. Y el comprador de un club puede estar en Montevideo, Buenos Aires, Santiago, Madrid o
Miami: el límite pasa a ser cuántas llamadas hacés, no cuánta gente hay en tu ciudad.

### 8.3 Qué haría que esto sí sea negocio (en orden)

1. **B2B / white label a clubes, complejos y ligas.** US$ 50-100/mes por su espacio de torneos
   con su marca. Mismo código, sin 15% de tienda (se factura), sin revisión de Apple/Google, y
   el club trae a sus propios jugadores. Es el modelo que aprovecha la publicación global:
   el producto es el mismo y el comprador puede estar en cualquier país.
2. **El loop del cuadro.** Si el cuadro existe, cada organizador que lo comparte por WhatsApp
   trae 8-16 jugadores sin que pongas un peso en ads. Es el único mecanismo de crecimiento
   orgánico que este producto puede tener, y es lo que hace que el metro 2 sea más barato que
   el metro 1. **Sin cuadro no hay loop, y sin loop el CAC lo pagás siempre vos.**
3. **Expansión a más metros** (Buenos Aires, Santiago, São Paulo, Madrid): recién cuando el
   playbook de §6.4 esté probado, con la ficha en pt-BR y un español neutro en la tienda.
4. **Suscripción individual de organizador**: se queda como está (complemento, no base). A
   US$ 4,99 conviene más como filtro de calidad de organizadores que como fuente de ingreso.

Lo que no cambiaría nada: subir el precio. Con 20 pagos, duplicarlo te deja en US$ 147/mes y
probablemente te baja la conversión. El problema es cuántos organizadores tenés, no cuánto cobrás.

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
- **Abrir 5 mercados a la vez "porque ya está global".** La disponibilidad es global; el esfuerzo
  no. Un metro validado vale más que 20 listings con el mapa vacío, y cada uno consume soporte
  en otro idioma y otro huso horario.
- **Traducir la app a 10 idiomas.** es + en cubren la mayor parte del mercado de fútbol/pádel
  amateur. pt-BR es el único siguiente con justificación de tamaño. Las traducciones se hacen con
  usuarios, no antes.
- **Venta de entradas/pagos dentro de la app.** Sigue siendo el error más caro posible: cuando
  hay plata de terceros de por medio cambian los términos, la responsabilidad y el soporte.

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
- Resend: SMTP `smtp.resend.com`, puerto 465, usuario `resend` — https://resend.com/docs/send-with-supabase-smtp
- Resend precios: Free 3.000/mes, Pro US$ 20/mes (50.000) — https://resend.com/pricing
- Resend límites de cuenta (free: 100 emails/día) — https://resend.com/docs/knowledge-base/resend-sending-limits
- Supabase: SMTP propio y rate limit de emails (30/h por defecto al habilitarlo) —
  https://supabase.com/docs/guides/auth/auth-smtp · https://supabase.com/docs/guides/auth/rate-limits
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
# global + emails (hoy los tres dan 0 y son bloqueantes)
grep -rn "resetPassword\|forgotPassword" lib || echo "0: no hay recuperar contraseña"
grep -rn "emailRedirectTo" lib || echo "0: el link de confirmacion no vuelve a la app"
grep -n "limit(\|range(" lib/data/repositories/supabase/supabase_tournament_repository.dart || echo "0: sin paginacion (tope 1000 filas de PostgREST)"
grep -n "currency" lib/models/tournament_model.dart || echo "0: el modelo no tiene moneda (format.dart la hardcodea a $)"
```

### 10.3 Orden de ejecución si tenés 10 horas esta semana
1. Crear las dos cuentas de developer (hoy: la verificación tarda días).
2. Comprar el dominio y verificarlo en Resend; SMTP en Supabase (2 h).
3. Ficha honesta es/en + privacidad con email y URL (3 h).
4. Bug de registro §4.1 completo, con `emailRedirectTo` (4 h).
5. Anon key en `.release.env` (5 min).
6. Commit.

La semana siguiente, sin excepción: recuperar contraseña (§4.4), borrado de cuenta (§3.2) y el
filtro geográfico con paginación (§4.8) — esos tres son los que separan "se puede publicar" de
"se puede usar fuera de Montevideo".
