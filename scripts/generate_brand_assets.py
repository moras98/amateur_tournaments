#!/usr/bin/env python3
"""Genera los assets de marca de Tande a partir del logo maestro (JPEG).

Uso:  python3 scripts/generate_brand_assets.py [ruta-del-logo.jpeg]

El maestro es un logo verde sobre blanco: escudo + laureles + flecha (marca)
y el wordmark "tande" debajo. El script:

  1. Detecta la marca y el lockup completo por perfil de filas.
  2. Le saca el fondo blanco (alfa por distancia al blanco, con rampa suave
     para no dejar halos ni comerse el antialias).
  3. Reescala con LANCZOS + unsharp leve y escribe:
       assets/logo_full.png        lockup marca+wordmark, transparente (splash)
       assets/splash_android12.png marca en canvas 1152 (recorte circular A12)
       assets/icon.png             icono legacy/iOS 1024, marca sobre blanco
       assets/icon_fg.png          foreground adaptive 1024, marca al 64 %
       assets/icon_mono.png        glifo monocromo 1024 (Android 13+)
       assets/icon_white.png       marca blanca 1024 (headers verdes in-app)
       web/icons/*.png             PWA 192/512 + maskable
       store/play-icon-512.png     icono 512 para Play Console

Requiere Pillow + numpy. Salida determinista: correr de nuevo y comparar.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SOURCE = Path.home() / "Downloads" / "tande-logo.jpeg"

WHITE = (255, 255, 255)
ADAPTIVE_FRACTION = 0.60


def alpha_from_white(rgb: np.ndarray) -> np.ndarray:
    """Cobertura 0..1 estimada desde 'cuán lejos del blanco' está cada pixel.

    min(R,G,B) es el canal más afectado por el blanco de fondo; la rampa
    (12..45) descarta el ruido JPEG del fondo y conserva el antialias.
    """
    distance = 255.0 - rgb.min(axis=2).astype(np.float32)
    t = np.clip((distance - 12.0) / (45.0 - 12.0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)  # smoothstep


def cutout(source: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    rgb = np.asarray(source.crop(box)).astype(np.float32)
    alpha = alpha_from_white(rgb)
    rgba = np.dstack([rgb, alpha * 255.0]).round().astype(np.uint8)
    return Image.fromarray(rgba, "RGBA")


def upscale(img: Image.Image, scale: float, sharpen: bool = True) -> Image.Image:
    w, h = img.size
    out = img.resize((round(w * scale), round(h * scale)), Image.LANCZOS)
    if sharpen:
        out = out.filter(ImageFilter.UnsharpMask(radius=1.2, percent=55, threshold=2))
    return out


def fit_on_canvas(
    img: Image.Image, canvas: int, fraction: float, background=None
) -> Image.Image:
    """Centra `img` en un canvas cuadrado, ocupando `fraction` del ancho/alto."""
    target = canvas * fraction
    scale = target / max(img.size)
    art = upscale(img, scale)
    base = Image.new("RGBA", (canvas, canvas), background or (0, 0, 0, 0))
    base.alpha_composite(
        art, ((canvas - art.width) // 2, (canvas - art.height) // 2)
    )
    return base


def white_version(img: Image.Image) -> Image.Image:
    arr = np.asarray(img).copy()
    arr[..., :3] = 255
    return Image.fromarray(arr, "RGBA")


def trim(img: Image.Image) -> Image.Image:
    bbox = img.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
    return img.crop(bbox) if bbox else img


def main() -> None:
    source_path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_SOURCE
    if not source_path.exists():
        sys.exit(f"No encuentro el logo maestro: {source_path}")

    source = Image.open(source_path).convert("RGB")
    ink = (np.asarray(source).min(axis=2) < 240)
    row_has_ink = ink.sum(axis=1) > 2

    # Perfil de filas -> la marca es el primer bloque, el wordmark el segundo.
    blocks: list[tuple[int, int]] = []
    start = None
    for y, filled in enumerate(row_has_ink):
        if filled and start is None:
            start = y
        elif not filled and start is not None:
            blocks.append((start, y - 1))
            start = None
    if start is not None:
        blocks.append((start, len(row_has_ink) - 1))
    blocks = [b for b in blocks if b[1] - b[0] > 8]
    if len(blocks) < 2:
        sys.exit("No pude separar la marca del texto: revisá el logo maestro.")

    (mark_top, mark_bottom), (text_top, text_bottom) = blocks[0], blocks[1]
    print(f"marca filas {mark_top}-{mark_bottom} · texto filas {text_top}-{text_bottom}")


    def cols(top: int, bottom: int) -> tuple[int, int]:
        cols_ink = np.where(ink[top : bottom + 1].any(axis=0))[0]
        return int(cols_ink.min()), int(cols_ink.max())

    left, right = cols(mark_top, mark_bottom)
    mark_box = (left, mark_top, right + 1, mark_bottom + 1)
    left, right = cols(mark_top, text_bottom)
    lockup_box = (left, mark_top, right + 1, text_bottom + 1)

    mark = trim(cutout(source, mark_box))
    lockup = trim(cutout(source, lockup_box))
    print(f"marca recortada {mark.size} · lockup {lockup.size}")

    assets = ROOT / "assets"
    assets.mkdir(exist_ok=True)

    # Lockup completo: se muestra a ~180 dp en el splash (el plugin asume
    # densidad 4x, así que W px -> W/4 dp).
    lockup_wide = upscale(lockup, 720 / lockup.width)
    lockup_wide.save(assets / "logo_full.png", optimize=True)

    # Splash Android 12: canvas 1152 con el contenido dentro del círculo de
    # 768 px; la marca queda ~192 dp en pantalla.
    fit_on_canvas(mark, 1152, 700 / 1152).save(
        assets / "splash_android12.png", optimize=True
    )

    # Adaptive: canvas 108 dp con zona segura de 72 dp -> el arte va al ~60 %
    # del ancho para que ni el círculo ni el squircle le coman la flecha.
    # icon.png es opaco: guardarlo en paleta de 256 colores lo deja en ~60 KB
    # en vez de ~350 KB (el degradado verde trae miles de colores únicos).
    icon = fit_on_canvas(mark, 1024, 0.74, WHITE).convert("RGB")
    icon.quantize(colors=256, method=Image.FASTOCTREE, dither=Image.FLOYDSTEINBERG).save(
        assets / "icon.png", optimize=True
    )
    fit_on_canvas(mark, 1024, ADAPTIVE_FRACTION).save(
        assets / "icon_fg.png", optimize=True
    )
    fit_on_canvas(white_version(mark), 1024, ADAPTIVE_FRACTION).save(
        assets / "icon_mono.png", optimize=True
    )
    # 512 alcanza y sobra: in-app se dibuja a 72 dp (216 px en xxxhdpi).
    fit_on_canvas(white_version(mark), 512, 0.74).save(
        assets / "icon_white.png", optimize=True
    )

    web_icons = ROOT / "web" / "icons"
    if web_icons.is_dir():
        fit_on_canvas(mark, 192, 0.74, WHITE).convert("RGB").save(
            web_icons / "Icon-192.png", optimize=True
        )
        fit_on_canvas(mark, 512, 0.74, WHITE).convert("RGB").save(
            web_icons / "Icon-512.png", optimize=True
        )
        fit_on_canvas(mark, 192, 0.55, WHITE).convert("RGB").save(
            web_icons / "Icon-maskable-192.png", optimize=True
        )
        fit_on_canvas(mark, 512, 0.55, WHITE).convert("RGB").save(
            web_icons / "Icon-maskable-512.png", optimize=True
        )
        fit_on_canvas(mark, 64, 0.74, WHITE).convert("RGB").save(
            ROOT / "web" / "favicon.png", optimize=True
        )

    store = ROOT / "store"
    if store.is_dir():
        fit_on_canvas(mark, 512, 0.74, WHITE).convert("RGB").save(
            store / "play-icon-512.png", optimize=True
        )

    for path in sorted(assets.glob("*.png")) + [store / "play-icon-512.png"]:
        if path.exists():
            print(f"{path.relative_to(ROOT)}  {Image.open(path).size}")


if __name__ == "__main__":
    main()
