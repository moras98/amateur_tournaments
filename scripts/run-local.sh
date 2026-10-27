#!/usr/bin/env bash
# Corre la app en un dispositivo o emulador con la configuración real de
# .release.env (backend + mapas), sin tipear claves a mano.
#
#   ./scripts/run-local.sh                       # debug en el dispositivo que elijas
#   ./scripts/run-local.sh -d emulator-5554      # elegir dispositivo
#   ./scripts/run-local.sh --profile             # perfil (mide en serio)
#   ./scripts/run-local.sh --release             # release: el mapa del store
#   ./scripts/run-local.sh --web                 # en Chrome, para ver el mapa ya
#   ./scripts/run-local.sh --devices             # lista dispositivos y sale
#   ./scripts/run-local.sh --dry-run             # muestra el comando y sale
#
# Todo lo que no sea --devices/--dry-run se pasa tal cual a `flutter run`, así
# que sirven --verbose, -d, --dart-define extra, etc.
#
# ENV_FILE permite usar otro archivo (por ejemplo .staging.env).
set -euo pipefail
cd "$(dirname "$0")/.."

ENV_FILE="${ENV_FILE:-.release.env}"

if [[ "${1:-}" == "--devices" ]]; then
  exec "${FLUTTER:-flutter}" devices
fi

DRY_RUN=0
WEB=0
ARGS=()
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    # Atajo: revisar el mapa en Chrome no necesita teléfono ni clang instalado.
    --web) WEB=1 ;;
    *) ARGS+=("$arg") ;;
  esac
done
if [[ "$WEB" == "1" ]]; then
  ARGS=(-d chrome ${ARGS[@]+"${ARGS[@]}"})
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "error: falta $ENV_FILE — copiá .release.env.example y completalo." >&2
  exit 1
fi

# `set -a` exporta lo que define el archivo para que lo vean los checks de abajo.
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

FLUTTER_BIN="${FLUTTER:-$(command -v flutter || true)}"
if [[ -z "$FLUTTER_BIN" ]]; then
  FLUTTER_BIN="/home/agustin/snap/flutter/common/flutter/bin/flutter"
fi
if [[ ! -x "$FLUTTER_BIN" ]]; then
  echo "error: no encontré flutter (probá FLUTTER=/ruta/al/flutter $0)." >&2
  exit 1
fi

TILE_PROVIDER="${TILE_PROVIDER:-osm}"

# Mismas guardas que build-release.sh: acá fallan temprano y con un mensaje
# claro, en vez de reventar en un assert adentro de la app.
if [[ "$TILE_PROVIDER" == "thunderforest" && -z "${THUNDERFOREST_KEY:-}" ]]; then
  echo "error: TILE_PROVIDER=thunderforest pero THUNDERFOREST_KEY está vacío en $ENV_FILE." >&2
  exit 1
fi
if [[ "$TILE_PROVIDER" == "custom" && -z "${TILE_URL_TEMPLATE:-}" ]]; then
  echo "error: TILE_PROVIDER=custom pero TILE_URL_TEMPLATE está vacío en $ENV_FILE." >&2
  exit 1
fi

if [[ -n "${SUPABASE_ANON_KEY:-}" && "${SUPABASE_ANON_KEY}" != "<anon key>" ]]; then
  BACKEND="Supabase"
else
  BACKEND="datos mock (SUPABASE_ANON_KEY vacío)"
fi
echo "Backend: $BACKEND"
echo "Tiles:   $TILE_PROVIDER"
echo

# La clave nunca se imprime: solo viaja como --dart-define.
DEFINES=(
  --dart-define=SUPABASE_URL="${SUPABASE_URL:-}"
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"
  --dart-define=TILE_PROVIDER="$TILE_PROVIDER"
  --dart-define=THUNDERFOREST_KEY="${THUNDERFOREST_KEY:-}"
  --dart-define=TILE_URL_TEMPLATE="${TILE_URL_TEMPLATE:-}"
  --dart-define=TILE_ATTRIBUTION="${TILE_ATTRIBUTION:-© OpenStreetMap contributors}"
  --dart-define=TILE_FRESH_DAYS="${TILE_FRESH_DAYS:-30}"
  --dart-define=GEOCODER_URL="${GEOCODER_URL:-https://nominatim.openstreetmap.org/reverse}"
)

if [[ "$DRY_RUN" == "1" ]]; then
  echo "Comando (claves ocultas):"
  for d in "${DEFINES[@]}"; do
    case "$d" in
      *KEY=*|*ANON_KEY=*) echo "  ${d%%=*}=***" ;;
      *) echo "  $d" ;;
    esac
  done
  echo "  run ${ARGS[*]:-}"
  exit 0
fi

exec "$FLUTTER_BIN" run "${DEFINES[@]}" ${ARGS[@]+"${ARGS[@]}"}
