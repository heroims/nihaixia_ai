#!/usr/bin/env python3
"""Generate platform PNG resources from the checked-in branding SVGs."""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
from pathlib import Path


ANDROID_DENSITIES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}


def render(svg: Path, output: Path, pixels: int, converter: str) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [converter, "-w", str(pixels), "-h", str(pixels), "-o", str(output), str(svg)],
        check=True,
    )


def parse_pixels(size: str, scale: str) -> int:
    points = float(size.split("x", 1)[0])
    factor = float(scale.removesuffix("x"))
    return round(points * factor)


def generate(root: Path) -> None:
    converter = shutil.which("rsvg-convert")
    if converter is None:
        raise SystemExit("rsvg-convert not found; install it with: brew install librsvg")

    branding = root / "app/assets/branding"
    icon_svg = branding / "icon.svg"
    launch_svg = branding / "launch.svg"
    for source in (icon_svg, launch_svg):
        if not source.is_file():
            raise SystemExit(f"missing branding source: {source}")

    android_res = root / "app/android/app/src/main/res"
    for density, pixels in ANDROID_DENSITIES.items():
        render(icon_svg, android_res / f"mipmap-{density}/ic_launcher.png", pixels, converter)
    render(launch_svg, android_res / "drawable/launch_logo.png", 512, converter)

    appicon_dir = root / "app/ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((appicon_dir / "Contents.json").read_text(encoding="utf-8"))
    for image in contents["images"]:
        filename = image.get("filename")
        if not filename:
            continue
        pixels = parse_pixels(image["size"], image["scale"])
        render(icon_svg, appicon_dir / filename, pixels, converter)

    launch_dir = root / "app/ios/Runner/Assets.xcassets/LaunchImage.imageset"
    launch_contents = json.loads((launch_dir / "Contents.json").read_text(encoding="utf-8"))
    for image in launch_contents["images"]:
        filename = image.get("filename")
        if not filename:
            continue
        pixels = {"LaunchImage.png": 200, "LaunchImage@2x.png": 400, "LaunchImage@3x.png": 600}[filename]
        render(launch_svg, launch_dir / filename, pixels, converter)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[3], help="repository root")
    args = parser.parse_args()
    generate(args.root.resolve())


if __name__ == "__main__":
    main()
