"""app_icon.html 첫 번째 아이콘(운전대)과 동일 디자인을 1024 PNG로 생성합니다."""
from __future__ import annotations

from PIL import Image, ImageDraw

W = 1024
S = W / 160.0  # viewBox 160 -> 1024


def lerp(a: float, b: float, t: float) -> int:
    return int(round(a + (b - a) * t))


def main() -> None:
    img = Image.new("RGBA", (W, W), (255, 255, 255, 0))
    px = img.load()
    c0 = (52, 199, 89)  # #34C759
    c1 = (36, 138, 61)  # #248A3D
    for y in range(W):
        t = y / (W - 1) if W > 1 else 0.0
        r = lerp(c0[0], c1[0], t)
        g = lerp(c0[1], c1[1], t)
        b = lerp(c0[2], c1[2], t)
        for x in range(W):
            px[x, y] = (r, g, b, 255)

    # 상단 하이라이트 (opacity 0.06 흰색)
    hl = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    top = Image.new(
        "RGBA",
        (W, W // 2),
        (255, 255, 255, int(255 * 0.06)),
    )
    hl.paste(top, (0, 0))
    img = Image.alpha_composite(img, hl)

    draw = ImageDraw.Draw(img)
    cx, cy = 80 * S, 82 * S
    r_outer = 42 * S
    w_stroke = 10 * S

    # 바깥 원
    bbox = [
        cx - r_outer,
        cy - r_outer,
        cx + r_outer,
        cy + r_outer,
    ]
    draw.ellipse(bbox, outline=(255, 255, 255, int(255 * 0.95)), width=int(round(w_stroke)))

    def thick_line(x1: float, y1: float, x2: float, y2: float) -> None:
        draw.line(
            [(x1, y1), (x2, y2)],
            fill=(255, 255, 255, int(255 * 0.95)),
            width=int(round(9 * S)),
            joint="curve",
        )

    thick_line(80 * S, 42 * S, 80 * S, 64 * S)
    thick_line(80 * S, 100 * S, 80 * S, 122 * S)
    thick_line(40 * S, 82 * S, 62 * S, 82 * S)
    thick_line(98 * S, 82 * S, 120 * S, 82 * S)

    hub_r = 10 * S
    hb = [cx - hub_r, cy - hub_r, cx + hub_r, cy + hub_r]
    draw.ellipse(hb, fill=(255, 255, 255, int(255 * 0.95)))

    notch_r = 5 * S
    nx, ny = 80 * S, 40 * S
    nb = [nx - notch_r, ny - notch_r, nx + notch_r, ny + notch_r]
    draw.ellipse(nb, fill=(255, 255, 255, int(255 * 0.5)))

    out = "assets/app_icon.png"
    img.convert("RGB").save(out, "PNG", optimize=True)
    print(f"Wrote {out}")


if __name__ == "__main__":
    main()
