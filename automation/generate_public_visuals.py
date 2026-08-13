#!/usr/bin/env python3
"""Generate PCADI public SVG and PNG assets from shared layout definitions."""

from __future__ import annotations

import html
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "docs" / "assets"

NAVY = "#123047"
BLUE = "#1F6F8B"
TEAL = "#2A9D8F"
MINT = "#DDF3EE"
PALE_BLUE = "#E8F1F5"
PALE_GOLD = "#FFF2D6"
GOLD = "#E5A73C"
INK = "#1D2A32"
MUTED = "#52646F"
WHITE = "#FFFFFF"
LINE = "#A9BEC8"
BG = "#F7FAFC"


@dataclass(frozen=True)
class Box:
    x: int
    y: int
    width: int
    height: int
    lines: tuple[str, ...]
    fill: str
    stroke: str = BLUE
    radius: int = 18
    text: str = INK
    font_size: int = 28
    bold: bool = False


@dataclass(frozen=True)
class Arrow:
    x1: int
    y1: int
    x2: int
    y2: int
    colour: str = BLUE
    width: int = 5


def font_path(bold: bool = False) -> Path:
    candidates = [
        Path("C:/Windows/Fonts/seguisb.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf"),
        Path("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
        Path("/Library/Fonts/Arial Bold.ttf" if bold else "/Library/Fonts/Arial.ttf"),
    ]
    for candidate in candidates:
        if candidate.is_file():
            return candidate
    raise FileNotFoundError("No supported system font was found.")


def pil_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(font_path(bold)), size=size)


def centre_text(
    draw: ImageDraw.ImageDraw,
    bounds: tuple[int, int, int, int],
    lines: tuple[str, ...],
    size: int,
    colour: str,
    bold: bool = False,
    spacing: int = 8,
) -> None:
    font = pil_font(size, bold)
    x1, y1, x2, y2 = bounds
    heights = []
    widths = []
    for line in lines:
        left, top, right, bottom = draw.textbbox((0, 0), line, font=font)
        widths.append(right - left)
        heights.append(bottom - top)
    total_height = sum(heights) + spacing * (len(lines) - 1)
    y = y1 + (y2 - y1 - total_height) / 2
    for line, width, height in zip(lines, widths, heights):
        draw.text((x1 + (x2 - x1 - width) / 2, y), line, font=font, fill=colour)
        y += height + spacing


def draw_box(draw: ImageDraw.ImageDraw, box: Box) -> None:
    bounds = (box.x, box.y, box.x + box.width, box.y + box.height)
    draw.rounded_rectangle(bounds, radius=box.radius, fill=box.fill, outline=box.stroke, width=3)
    centre_text(draw, bounds, box.lines, box.font_size, box.text, box.bold)


def draw_arrow(draw: ImageDraw.ImageDraw, arrow: Arrow) -> None:
    draw.line((arrow.x1, arrow.y1, arrow.x2, arrow.y2), fill=arrow.colour, width=arrow.width)
    dx = arrow.x2 - arrow.x1
    dy = arrow.y2 - arrow.y1
    length = max((dx * dx + dy * dy) ** 0.5, 1)
    ux, uy = dx / length, dy / length
    px, py = -uy, ux
    head = 16
    wing = 9
    points = [
        (arrow.x2, arrow.y2),
        (arrow.x2 - head * ux + wing * px, arrow.y2 - head * uy + wing * py),
        (arrow.x2 - head * ux - wing * px, arrow.y2 - head * uy - wing * py),
    ]
    draw.polygon(points, fill=arrow.colour)


def svg_text(x: float, y: float, lines: tuple[str, ...], size: int, colour: str, bold: bool) -> str:
    weight = "700" if bold else "400"
    line_height = size * 1.24
    start = y - line_height * (len(lines) - 1) / 2
    tspans = "".join(
        f'<tspan x="{x}" y="{start + i * line_height:.1f}">{html.escape(line)}</tspan>'
        for i, line in enumerate(lines)
    )
    return (
        f'<text text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" '
        f'font-size="{size}" font-weight="{weight}" fill="{colour}">{tspans}</text>'
    )


def svg_box(box: Box) -> str:
    return (
        f'<rect x="{box.x}" y="{box.y}" width="{box.width}" height="{box.height}" '
        f'rx="{box.radius}" fill="{box.fill}" stroke="{box.stroke}" stroke-width="3"/>'
        + svg_text(
            box.x + box.width / 2,
            box.y + box.height / 2 + box.font_size * 0.35,
            box.lines,
            box.font_size,
            box.text,
            box.bold,
        )
    )


def svg_arrow(arrow: Arrow) -> str:
    return (
        f'<line x1="{arrow.x1}" y1="{arrow.y1}" x2="{arrow.x2}" y2="{arrow.y2}" '
        f'stroke="{arrow.colour}" stroke-width="{arrow.width}" marker-end="url(#arrow)"/>'
    )


def save_visual(
    stem: str,
    width: int,
    height: int,
    title: str,
    subtitle: str,
    boxes: list[Box],
    arrows: list[Arrow],
    extra_svg: list[str] | None = None,
    extra_png=None,
) -> None:
    ASSETS.mkdir(parents=True, exist_ok=True)
    image = Image.new("RGB", (width, height), BG)
    draw = ImageDraw.Draw(image)
    centre_text(draw, (80, 28, width - 80, 92), (title,), 44, NAVY, True)
    centre_text(draw, (100, 88, width - 100, 130), (subtitle,), 23, MUTED)
    for arrow in arrows:
        draw_arrow(draw, arrow)
    for box in boxes:
        draw_box(draw, box)
    if extra_png:
        extra_png(draw)
    image.save(ASSETS / f"{stem}.png", format="PNG", optimize=True)

    svg = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img" aria-labelledby="title description">',
        f"<title id=\"title\">{html.escape(title)}</title>",
        f"<desc id=\"description\">{html.escape(subtitle)}</desc>",
        "<defs>",
        f'<marker id="arrow" markerWidth="12" markerHeight="12" refX="10" refY="6" orient="auto"><path d="M0,0 L12,6 L0,12 z" fill="{BLUE}"/></marker>',
        "</defs>",
        f'<rect width="{width}" height="{height}" fill="{BG}"/>',
        svg_text(width / 2, 70, (title,), 44, NAVY, True),
        svg_text(width / 2, 116, (subtitle,), 23, MUTED, False),
    ]
    svg.extend(svg_arrow(arrow) for arrow in arrows)
    svg.extend(svg_box(box) for box in boxes)
    if extra_svg:
        svg.extend(extra_svg)
    svg.append("</svg>")
    (ASSETS / f"{stem}.svg").write_text("\n".join(svg) + "\n", encoding="utf-8")


def architecture() -> None:
    boxes = [
        Box(250, 205, 1100, 68, ("Official NHS England publications",), PALE_BLUE, NAVY, 18, NAVY, 28, True),
        Box(180, 295, 250, 66, ("OCS",), WHITE, BLUE, 15, NAVY, 26, True),
        Box(470, 295, 250, 66, ("GPAD",), WHITE, BLUE, 15, NAVY, 26, True),
        Box(760, 295, 250, 66, ("CBT",), WHITE, BLUE, 15, NAVY, 26, True),
        Box(1050, 295, 330, 66, ("Registered patients",), WHITE, BLUE, 15, NAVY, 24, True),
        Box(250, 415, 1100, 92, ("Source contracts and provenance", "Publication vintage | observation month | selected owner"), MINT, TEAL, 18, INK, 25, True),
        Box(250, 555, 1100, 92, ("Validated one-row-per-practice-month source tables", "ODS practice code is the identity key"), WHITE, BLUE, 18, INK, 25, True),
        Box(90, 695, 650, 86, ("Coverage and provenance union spine", "Portable practice-month design"), PALE_GOLD, GOLD, 18, INK, 24, True),
        Box(860, 695, 650, 86, ("Matched OCS-GPAD-denominator panel", "Verified annual reference lineage"), PALE_BLUE, BLUE, 18, INK, 24, True),
        Box(90, 835, 650, 96, ("Question-specific practice-month views", "Each retains its documented key population"), WHITE, BLUE, 18, INK, 23, True),
        Box(860, 835, 650, 96, ("Annual national and nested CBT matrices", "12-month eligibility plus prepared CBT evidence"), WHITE, BLUE, 18, INK, 23, True),
        Box(390, 980, 820, 72, ("Validation, reuse and downstream analysis",), NAVY, NAVY, 18, WHITE, 28, True),
        Box(90, 145, 300, 42, ("Reusable pipeline",), NAVY, NAVY, 16, WHITE, 18, True),
        Box(1030, 145, 480, 42, ("Included reference: Apr 2025 to Mar 2026",), MINT, TEAL, 16, NAVY, 18, True),
    ]
    arrows = [
        Arrow(800, 361, 800, 415),
        Arrow(800, 507, 800, 555),
        Arrow(800, 647, 415, 695),
        Arrow(800, 647, 1185, 695),
        Arrow(415, 781, 415, 835),
        Arrow(1185, 781, 1185, 835),
        Arrow(415, 931, 650, 980),
        Arrow(1185, 931, 950, 980),
    ]
    save_visual(
        "pcadi-architecture",
        1600,
        1090,
        "PCADI data-integration architecture",
        "From official source contracts to auditable practice-month and annual outputs",
        boxes,
        arrows,
    )


def cohort_flow() -> None:
    boxes = [
        Box(160, 145, 1080, 92, ("Validated OCS and GPAD practice-month reporting",), PALE_BLUE, BLUE, 18, NAVY, 28, True),
        Box(230, 290, 940, 460, ("",), MINT, TEAL, 24, NAVY, 31, True),
        Box(330, 420, 740, 260, ("",), PALE_BLUE, BLUE, 24, NAVY, 28, True),
        Box(450, 535, 500, 105, ("1,456 practices with complete", "supported CBT outcomes"), PALE_GOLD, GOLD, 22, INK, 25, True),
        Box(255, 800, 890, 82, ("Nested evidence-availability cohorts", "Each cohort follows its documented source contract"), NAVY, NAVY, 18, WHITE, 25, True),
    ]
    arrows = [
        Arrow(700, 237, 700, 290),
        Arrow(700, 750, 700, 800),
    ]
    extra = [
        svg_text(700, 340, ("6,067 practices in the national annual matrix",), 31, NAVY, True),
        svg_text(700, 382, ("12 complete eligible matched months",), 22, MUTED, False),
        svg_text(700, 490, ("3,020 practices with valid CBT inbound evidence",), 28, NAVY, True),
    ]

    def extra_png(draw: ImageDraw.ImageDraw) -> None:
        centre_text(draw, (300, 305, 1100, 350), ("6,067 practices in the national annual matrix",), 31, NAVY, True)
        centre_text(draw, (300, 352, 1100, 395), ("12 complete eligible matched months",), 22, MUTED)
        centre_text(draw, (360, 445, 1040, 510), ("3,020 practices with valid CBT inbound evidence",), 28, NAVY, True)

    save_visual(
        "pcadi-cohort-flow",
        1400,
        930,
        "April 2025 to March 2026 reference cohorts",
        "Annual OCS-GPAD eligibility with nested CBT evidence availability",
        boxes,
        arrows,
        extra,
        extra_png,
    )


def social_preview() -> None:
    width, height = 1280, 640
    image = Image.new("RGB", (width, height), NAVY)
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((68, 62, 1212, 578), radius=36, fill="#163B54", outline=TEAL, width=3)
    draw.rectangle((68, 62, 88, 578), fill=TEAL)
    draw.text((145, 120), "PCADI", font=pil_font(88, True), fill=WHITE)
    draw.text((150, 230), "Primary Care Activity Data Integration", font=pil_font(42, True), fill="#DDF3EE")
    draw.text((150, 330), "OCS + GPAD + CBT + registered-patient data", font=pil_font(30), fill=WHITE)
    draw.line((150, 400, 1125, 400), fill="#5CA6B4", width=2)
    draw.text(
        (150, 440),
        "Practice-month integration | Auditable joins | Reusable periods",
        font=pil_font(27),
        fill="#DDF3EE",
    )
    image.save(ASSETS / "social-preview.png", format="PNG", optimize=True)

    svg = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="640" viewBox="0 0 1280 640" role="img" aria-labelledby="title description">
  <title id="title">PCADI social preview</title>
  <desc id="description">Primary Care Activity Data Integration for OCS, GPAD, CBT and registered-patient data.</desc>
  <rect width="1280" height="640" fill="{NAVY}"/>
  <rect x="68" y="62" width="1144" height="516" rx="36" fill="#163B54" stroke="{TEAL}" stroke-width="3"/>
  <rect x="68" y="62" width="20" height="516" fill="{TEAL}"/>
  <text x="145" y="205" font-family="Segoe UI, Arial, sans-serif" font-size="88" font-weight="700" fill="{WHITE}">PCADI</text>
  <text x="150" y="280" font-family="Segoe UI, Arial, sans-serif" font-size="42" font-weight="700" fill="#DDF3EE">Primary Care Activity Data Integration</text>
  <text x="150" y="360" font-family="Segoe UI, Arial, sans-serif" font-size="30" fill="{WHITE}">OCS + GPAD + CBT + registered-patient data</text>
  <line x1="150" y1="400" x2="1125" y2="400" stroke="#5CA6B4" stroke-width="2"/>
  <text x="150" y="480" font-family="Segoe UI, Arial, sans-serif" font-size="27" fill="#DDF3EE">Practice-month integration | Auditable joins | Reusable periods</text>
</svg>
'''
    (ASSETS / "social-preview.svg").write_text(svg, encoding="utf-8")


def main() -> None:
    architecture()
    cohort_flow()
    social_preview()
    for name in (
        "pcadi-architecture.svg",
        "pcadi-architecture.png",
        "pcadi-cohort-flow.svg",
        "pcadi-cohort-flow.png",
        "social-preview.svg",
        "social-preview.png",
    ):
        path = ASSETS / name
        print(f"{path.relative_to(ROOT)} | {path.stat().st_size} bytes")


if __name__ == "__main__":
    main()
