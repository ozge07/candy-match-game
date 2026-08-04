#!/usr/bin/env python3
"""Uygulama ikonunu sıfırdan üretir.

Hiçbir dış kütüphane kullanmıyor: PNG'yi `zlib` ve `struct` ile elle yazıyoruz.
Böylece telifli hiçbir görsel projeye girmiyor ve ikon oyunun kendi renk/şekil
paletinden türüyor.

Çalıştırmak için:

    python3 tool/gen_icon.py

Android'in beş yoğunluğu için `android/app/src/main/res/mipmap-*/ic_launcher.png`
dosyalarını üretir.
"""

from __future__ import annotations

import math
import pathlib
import struct
import zlib

# Oyunun şeker paletinden alınan renkler.
RED = (0xE8, 0x4C, 0x3D)
BLUE = (0x34, 0x98, 0xDB)
GREEN = (0x2E, 0xCC, 0x71)
YELLOW = (0xF1, 0xC4, 0x0F)
INK = (0x1C, 0x18, 0x36)

# Android'in beklediği yoğunluklar (klasör adı, kenar uzunluğu).
DENSITIES = [
    ("mdpi", 48),
    ("hdpi", 72),
    ("xhdpi", 96),
    ("xxhdpi", 144),
    ("xxxhdpi", 192),
]

# Kenarları yumuşatmak için bu katsayıyla büyük çizip küçültüyoruz.
SUPERSAMPLE = 4


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def mix(c1, c2, t: float):
    return tuple(int(round(lerp(c1[i], c2[i], t))) for i in range(3))


def polygon(cx: float, cy: float, radius: float, sides: int, rotation: float):
    """Merkezi verilen düzgün çokgenin köşeleri."""
    return [
        (
            cx + math.cos(rotation + i * 2 * math.pi / sides) * radius,
            cy + math.sin(rotation + i * 2 * math.pi / sides) * radius,
        )
        for i in range(sides)
    ]


def inside_polygon(x: float, y: float, points) -> bool:
    """Ray casting: nokta çokgenin içinde mi?"""
    inside = False
    count = len(points)
    j = count - 1
    for i in range(count):
        xi, yi = points[i]
        xj, yj = points[j]
        if (yi > y) != (yj > y):
            crossing = xi + (y - yi) * (xj - xi) / (yj - yi)
            if x < crossing:
                inside = not inside
        j = i
    return inside


def inside_rounded_square(x: float, y: float, size: float, radius: float) -> bool:
    """Yuvarlatılmış kare maskesi."""
    if x < 0 or y < 0 or x >= size or y >= size:
        return False
    # Köşe merkezlerine uzaklık; kenarlarda zaten içerideyiz.
    cx = min(max(x, radius), size - radius)
    cy = min(max(y, radius), size - radius)
    dx = x - cx
    dy = y - cy
    return dx * dx + dy * dy <= radius * radius


def render(size: int, adaptive: bool = False):
    """İkonu [size]x[size] RGBA piksel dizisi olarak çizer.

    [adaptive] verilirse Android'in uyarlanabilir ikon katmanı üretilir: zemin
    saydam kalır ve şekiller güvenli alana (kenarların %25'i kırpılabiliyor)
    sığacak kadar küçültülür.
    """
    big = size * SUPERSAMPLE
    radius = big * 0.22

    # Uyarlanabilir katmanda şekiller güvenli alana sığmalı.
    k = 0.62 if adaptive else 1.0
    cx = big / 2

    def place(fx: float, fy: float):
        """Oranları merkeze göre ölçekler."""
        return cx + (big * fx - cx) * k, cx + (big * fy - cx) * k

    # Üç şeker: üstte daire, altta eşkenar dörtgen ve üçgen — oyundaki
    # şekil merdiveninin ilk üçü.
    cxr, cyr = place(0.5, 0.36)
    circle = (cxr, cyr, big * 0.20 * k)
    dx_, dy_ = place(0.30, 0.68)
    dia_points = polygon(dx_, dy_, big * 0.175 * k, 4, -math.pi / 2)
    tx, ty = place(0.70, 0.68)
    tri_points = polygon(tx, ty, big * 0.185 * k, 3, -math.pi / 2)

    rows = []
    for py in range(big):
        row = []
        for px in range(big):
            x = px + 0.5
            y = py + 0.5
            if adaptive:
                # Zemin ayrı katmanda; burada yalnızca şekiller var.
                colour = None
            elif not inside_rounded_square(x, y, big, radius):
                row.append((0, 0, 0, 0))
                continue
            else:
                # Zemin: sol üstten sağ alta koyu bir geçiş.
                t = (x / big + y / big) / 2
                colour = mix(INK, mix(INK, YELLOW, 0.14), t)

            ccx, ccy, cr = circle
            if (x - ccx) ** 2 + (y - ccy) ** 2 <= cr * cr:
                # Sol üstten gelen ışık: düz renk yerine hacim hissi.
                shade = ((x - ccx) + (y - ccy)) / (2 * cr)
                colour = mix(mix(RED, (255, 255, 255), 0.35), RED, min(max(shade + 0.5, 0.0), 1.0))
            elif inside_polygon(x, y, dia_points):
                colour = BLUE
            elif inside_polygon(x, y, tri_points):
                colour = GREEN

            if colour is None:
                row.append((0, 0, 0, 0))
            else:
                row.append((colour[0], colour[1], colour[2], 255))
        rows.append(row)

    # Süper örneklemeyi geri indir: her hedef piksel SUPERSAMPLE² örneğin
    # ortalaması. Kenarlar böyle yumuşuyor.
    out = []
    for oy in range(size):
        line = bytearray()
        for ox in range(size):
            r = g = b = a = 0
            for sy in range(SUPERSAMPLE):
                for sx in range(SUPERSAMPLE):
                    pr, pg, pb, pa = rows[oy * SUPERSAMPLE + sy][
                        ox * SUPERSAMPLE + sx
                    ]
                    # Saydam pikseller rengi kirletmesin diye alfayla ağırlıklı.
                    r += pr * pa
                    g += pg * pa
                    b += pb * pa
                    a += pa
            if a == 0:
                line += bytes((0, 0, 0, 0))
            else:
                line += bytes(
                    (
                        r // a,
                        g // a,
                        b // a,
                        a // (SUPERSAMPLE * SUPERSAMPLE),
                    )
                )
        out.append(bytes(line))
    return out


def write_png(path: pathlib.Path, rows, size: int) -> None:
    """Sıkıştırılmış 8 bit RGBA PNG yazar."""

    def chunk(tag: bytes, payload: bytes) -> bytes:
        return (
            struct.pack('>I', len(payload))
            + tag
            + payload
            + struct.pack('>I', zlib.crc32(tag + payload) & 0xFFFFFFFF)
        )

    raw = b''.join(b'\x00' + row for row in rows)  # filtre tipi 0
    png = (
        b'\x89PNG\r\n\x1a\n'
        + chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 6, 0, 0, 0))
        + chunk(b'IDAT', zlib.compress(raw, 9))
        + chunk(b'IEND', b'')
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(png)


def main() -> None:
    root = pathlib.Path(__file__).resolve().parent.parent
    res = root / 'android' / 'app' / 'src' / 'main' / 'res'
    for folder, size in DENSITIES:
        rows = render(size)
        target = res / f'mipmap-{folder}' / 'ic_launcher.png'
        write_png(target, rows, size)
        print(f'{target.relative_to(root)}  ({size}x{size})')

    # Uyarlanabilir ikonun ön katmanı. Android bunu 108dp'lik bir tuval
    # varsayıp kenarlarından kırpıyor, o yüzden ayrı ve daha büyük ölçekte.
    for folder, size in DENSITIES:
        adaptive_size = size * 108 // 48
        rows = render(adaptive_size, adaptive=True)
        target = res / f'mipmap-{folder}' / 'ic_launcher_foreground.png'
        write_png(target, rows, adaptive_size)
        print(f'{target.relative_to(root)}  ({adaptive_size}x{adaptive_size})')

    # Play Store listelemesi için 512x512 de üretiyoruz.
    store = root / 'store' / 'icon-512.png'
    write_png(store, render(512), 512)
    print(f'{store.relative_to(root)}  (512x512)')


if __name__ == '__main__':
    main()
