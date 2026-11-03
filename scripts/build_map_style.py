#!/usr/bin/env python3
"""Genera los estilos vectoriales de Tande a partir de OpenFreeMap Positron.

Uso:  python3 scripts/build_map_style.py

Baja `https://tiles.openfreemap.org/styles/positron` (MapLibre style JSON,
OpenFreeMap, sin clave), lo re-pinta con la paleta de Tande y escribe:

    assets/map/style_light.json
    assets/map/style_dark.json

Reglas del re-pintado:
  * Se van las capas de POI (aeródromos y cualquier `poi`): el mapa queda con
    calles, manzanas, agua y nombres de barrio/ciudad, sin íconos de negocios.
  * El resto de la cartografía (jerarquía de calles, anchos por zoom, filtros)
    queda igual: solo cambian los colores.
  * Los `sources` siguen apuntando a OpenFreeMap (el TileJSON trae la
    atribución y la URL versionada de los tiles), y `glyphs`/`sprite` también:
    no hay copias locales que se desactualicen.

El resultado se commitea; correr esto otra vez solo si cambia la paleta o si
OpenFreeMap publica una cartografía nueva.
"""

from __future__ import annotations

import json
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "map"
UPSTREAM = "https://tiles.openfreemap.org/styles/positron"

# Capas que se descartan: son puntos de interés con ícono, justo lo que el
# mapa de Tande no quiere mostrar al acercarse.
DROP_IDS = {"airport"}
DROP_SOURCE_LAYERS = {"poi", "aerodrome_label"}

LIGHT = {
    "background": "#F5F7F3",
    "park": "#DFECDF",
    "water": "#C7DCD8",
    "waterway": "#BAD3CE",
    "residential": "#ECEEE8",
    "wood": "#D5E6D6",
    "building": "#E4E7DF",
    "building_outline": "#D9DCD3",
    "road_inner": "#FFFFFF",
    "road_casing": "#DADFD6",
    "road_minor": "#E2E6DF",
    "road_path": "#E4E9E0",
    "motorway_inner": "#FFF7E9",
    "motorway_casing": "#DBD5C6",
    "rail": "#D5DAD2",
    "rail_dash": "#F5F7F3",
    "aeroway": "#E6E8E2",
    "boundary": "#CBD3CA",
    "label_place": "#33463C",
    "label_road": "#5F6F66",
    "label_water": "#4F7C74",
    "label_halo": "#FFFFFF",
    "label_halo_width": 1.2,
}

DARK = {
    "background": "#0F1915",
    "park": "#17271D",
    "water": "#123033",
    "waterway": "#1D4340",
    "residential": "#16211C",
    "wood": "#1A2C21",
    "building": "#1B2924",
    "building_outline": "#23332C",
    "road_inner": "#3B4C42",
    "road_casing": "#233229",
    "road_minor": "#2A3A31",
    "road_path": "#22322A",
    "motorway_inner": "#4A4433",
    "motorway_casing": "#2A2A1F",
    "rail": "#26342C",
    "rail_dash": "#16211C",
    "aeroway": "#1F2D27",
    "boundary": "#2C3A32",
    "label_place": "#DCE7DF",
    "label_road": "#A9B8AE",
    "label_water": "#7FB3AA",
    "label_halo": "#0B1411",
    "label_halo_width": 1.2,
}


def fetch(style_url: str) -> dict:
    req = urllib.request.Request(style_url, headers={"User-Agent": "com.tande.app"})
    with urllib.request.urlopen(req, timeout=30) as res:
        return json.loads(res.read().decode())


def paint(layer: dict, p: dict) -> None:
    """Aplica la paleta según el id de capa. Solo se tocan propiedades válidas
    para el tipo de capa: MapLibre rechaza el estilo entero si una capa `line`
    recibe un `fill-color`."""
    lid = layer["id"]
    props = layer.setdefault("paint", {})
    allowed = {
        "fill": {"fill-color", "fill-outline-color"},
        "line": {"line-color"},
        "symbol": {"text-color", "text-halo-color", "text-halo-width"},
        "background": {"background-color"},
    }.get(layer["type"], set())

    def put(key, value):
        if key in allowed:
            props[key] = value

    if lid == "background":
        put("background-color", p["background"])
    elif lid == "park":
        put("fill-color", p["park"])
    elif lid == "water":
        put("fill-color", p["water"])
    elif lid == "waterway":
        put("line-color", p["waterway"])
    elif lid == "landuse_residential":
        put("fill-color", p["residential"])
    elif lid == "landcover_wood":
        put("fill-color", p["wood"])
    elif lid == "building":
        put("fill-color", p["building"])
        put("fill-outline-color", p["building_outline"])
    elif lid.startswith(("tunnel_motorway", "highway_motorway")) and lid.endswith("casing"):
        put("line-color", p["motorway_casing"])
    elif lid.startswith(("tunnel_motorway", "highway_motorway")) and lid.endswith("inner"):
        put("line-color", p["motorway_inner"])
    elif lid.endswith("casing"):
        put("line-color", p["road_casing"])
    elif lid.endswith("inner"):
        put("line-color", p["road_inner"])
    elif lid in ("highway_minor",):
        put("line-color", p["road_minor"])
    elif lid in ("highway_path",):
        put("line-color", p["road_path"])
    elif lid in ("road_area_pier",):
        put("fill-color", p["background"])
    elif lid in ("road_pier",):
        put("line-color", p["background"])
    elif lid.startswith("railway") and lid.endswith("dashline"):
        put("line-color", p["rail_dash"])
    elif lid.startswith("railway"):
        put("line-color", p["rail"])
    elif lid.startswith("aeroway"):
        put("line-color", p["aeroway"])
        put("fill-color", p["aeroway"])
    elif lid.startswith("boundary"):
        put("line-color", p["boundary"])
    elif lid.startswith("label_") or lid in ("water_name_point_label", "water_name_line_label"):
        if "water" in lid:
            put("text-color", p["label_water"])
        else:
            put("text-color", p["label_place"])
        put("text-halo-color", p["label_halo"])
        put("text-halo-width", p["label_halo_width"])
    elif "name" in lid or lid.endswith("-label"):
        put("text-color", p["label_road"])
        put("text-halo-color", p["label_halo"])
        put("text-halo-width", p["label_halo_width"])


def build(style: dict, palette: dict) -> dict:
    out = json.loads(json.dumps(style))  # copia profunda
    layers = []
    for layer in out["layers"]:
        if layer["id"] in DROP_IDS:
            continue
        if layer.get("source-layer") in DROP_SOURCE_LAYERS:
            continue
        paint(layer, palette)
        layers.append(layer)
    out["layers"] = layers
    return out


def main() -> None:
    style = fetch(UPSTREAM)
    OUT.mkdir(parents=True, exist_ok=True)
    for name, palette in (("light", LIGHT), ("dark", DARK)):
        built = build(style, palette)
        path = OUT / f"style_{name}.json"
        path.write_text(json.dumps(built, ensure_ascii=False, separators=(",", ":")))
        pois = [
            l
            for l in built["layers"]
            if l.get("source-layer") in DROP_SOURCE_LAYERS
        ]
        print(
            f"{path.relative_to(ROOT)}  {len(built['layers'])} capas  "
            f"{path.stat().st_size // 1024} KB  capas POI: {len(pois)}"
        )


if __name__ == "__main__":
    main()
