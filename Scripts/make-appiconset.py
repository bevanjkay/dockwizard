#!/usr/bin/env python3
"""Builds the app icon set and the site favicons from Design/app-icon-source.png.

The source artwork is a square, full-bleed render that already carries its own dark
background, so there is nothing to cut away: the square is masked straight to a squircle
and placed on Apple's 1024-pt icon grid (icon body = 824 pt).

The mask is a superellipse rather than a rounded rectangle. Apple's corner is continuous,
and a plain rounded rectangle shows a visible break where the straight edge meets the arc
at 512 pt and above.

Requires Pillow and numpy.
"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
CANVAS = 1024
BODY = 824
MAC_SIZES = (16, 32, 128, 256, 512)
# Favicon, apple-touch-icon, and the Open Graph card image.
SITE_ICONS = {"favicon.png": 64, "apple-touch-icon.png": 180, "icon-256.png": 256, "icon.png": 512}


def squircle(size: int, exponent: float = 5.0, supersample: int = 4) -> Image.Image:
    """An anti-aliased continuous-corner squircle mask."""
    side = size * supersample
    y, x = np.mgrid[0:side, 0:side]
    half = (side - 1) / 2
    u, v = (x - half) / half, (y - half) / half
    inside = (np.abs(u) ** exponent + np.abs(v) ** exponent) <= 1.0
    return Image.fromarray((inside * 255).astype(np.uint8), "L").resize((size, size), Image.LANCZOS)


def build(source: Path) -> Image.Image:
    art = Image.open(source).convert("RGBA")
    if art.width != art.height:
        raise SystemExit(f"{source} must be square, got {art.width}x{art.height}")
    body = art.resize((BODY, BODY), Image.LANCZOS)
    body.putalpha(squircle(BODY))
    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    canvas.alpha_composite(body, ((CANVAS - BODY) // 2, (CANVAS - BODY) // 2))
    return canvas


def write_appiconset(canvas: Image.Image) -> int:
    out = ROOT / "App/Assets.xcassets/AppIcon.appiconset"
    out.mkdir(parents=True, exist_ok=True)
    images = []
    for size in MAC_SIZES:
        for factor in (1, 2):
            name = f"icon_{size}x{size}@{factor}x.png"
            canvas.resize((size * factor, size * factor), Image.LANCZOS).save(out / name, optimize=True)
            images.append({"filename": name, "idiom": "mac", "scale": f"{factor}x", "size": f"{size}x{size}"})
    (out / "Contents.json").write_text(
        json.dumps({"images": images, "info": {"author": "xcode", "version": 1}}, indent=2, sort_keys=True) + "\n"
    )
    return len(images)


def write_asset_catalog_root() -> None:
    root = ROOT / "App/Assets.xcassets"
    (root / "Contents.json").write_text(
        json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2, sort_keys=True) + "\n"
    )


def write_site_icons(canvas: Image.Image) -> None:
    site = ROOT / "site"
    for name, size in SITE_ICONS.items():
        canvas.resize((size, size), Image.LANCZOS).save(site / name, optimize=True)


def main() -> None:
    source = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "Design/app-icon-source.png"
    canvas = build(source)
    count = write_appiconset(canvas)
    write_asset_catalog_root()
    write_site_icons(canvas)
    print(f"Wrote {count} app icons and {len(SITE_ICONS)} site icons from {source.name}")


if __name__ == "__main__":
    main()
