"""Candy Match ses efektlerini sıfırdan sentezler (saf stdlib, telifsiz)."""

import math
import os
import random
import struct
import wave

SR = 44100
OUT = os.path.expanduser("~/candy_match/assets/audio")
os.makedirs(OUT, exist_ok=True)
random.seed(7)


def write(name, samples, peak=0.85):
    hi = max(abs(s) for s in samples) or 1.0
    gain = peak / hi
    data = b"".join(
        struct.pack("<h", int(max(-1.0, min(1.0, s * gain)) * 32767)) for s in samples
    )
    path = os.path.join(OUT, name)
    with wave.open(path, "w") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(data)
    print(f"{name:18} {len(samples)/SR:.2f}s  {len(data)//1024}KB")


def n_samples(seconds):
    return int(SR * seconds)


def fade_edges(buf, ms=4):
    """Klik sesini önlemek için baş/son mikro fade."""
    k = min(n_samples(ms / 1000), len(buf) // 2)
    for i in range(k):
        buf[i] *= i / k
        buf[-1 - i] *= i / k
    return buf


def lowpass(buf, cutoff_start, cutoff_end):
    """Tek kutuplu, kesim frekansı zamanla süzülen alçak geçiren filtre."""
    out = []
    y = 0.0
    n = len(buf)
    for i, x in enumerate(buf):
        cut = cutoff_start + (cutoff_end - cutoff_start) * (i / n)
        a = 1.0 - math.exp(-2 * math.pi * cut / SR)
        y += a * (x - y)
        out.append(y)
    return out


def tone(freq_start, freq_end, dur, decay=6.0, harmonics=(1.0,), curve="exp"):
    """Frekansı kayan, üstel sönümlü ton."""
    total = n_samples(dur)
    buf = []
    phase = 0.0
    for i in range(total):
        t = i / total
        f = freq_start + (freq_end - freq_start) * (t**0.5 if curve == "exp" else t)
        phase += 2 * math.pi * f / SR
        value = sum(a * math.sin(phase * (h + 1)) for h, a in enumerate(harmonics))
        buf.append(value * math.exp(-decay * t))
    return fade_edges(buf)


def noise(dur, decay=8.0):
    total = n_samples(dur)
    return [(random.random() * 2 - 1) * math.exp(-decay * (i / total)) for i in range(total)]


def mix(*layers):
    length = max(len(l) for l in layers)
    out = [0.0] * length
    for layer in layers:
        for i, s in enumerate(layer):
            out[i] += s
    return out


def bell(freq, dur, decay=5.0, amp=1.0):
    """Çan benzeri nota: temel + tek sayılı harmonikler."""
    total = n_samples(dur)
    buf = []
    for i in range(total):
        t = i / total
        env = math.exp(-decay * t)
        s = (
            math.sin(2 * math.pi * freq * i / SR)
            + 0.45 * math.sin(2 * math.pi * freq * 2 * i / SR)
            + 0.22 * math.sin(2 * math.pi * freq * 3.01 * i / SR)
            + 0.10 * math.sin(2 * math.pi * freq * 4.7 * i / SR)
        )
        buf.append(s * env * amp)
    return fade_edges(buf)


def sequence(notes, gap):
    """notes: (freq, dur, decay) listesi; gap saniye cinsinden nota aralığı."""
    total = n_samples(gap * (len(notes) - 1) + max(d for _, d, _ in notes))
    out = [0.0] * total
    for idx, (freq, dur, decay) in enumerate(notes):
        start = n_samples(gap * idx)
        for i, s in enumerate(bell(freq, dur, decay)):
            if start + i < total:
                out[start + i] += s * 0.7
    return out


# --------------------------------------------------------------------------
# 1. Takas: kısa, yumuşak blip
write("swap.wav", tone(420, 760, 0.09, decay=9.0, harmonics=(1.0, 0.25)))

# 2. Geçersiz hamle: alçak, hafif rahatsız iki vuruş
invalid = mix(
    tone(200, 150, 0.10, decay=10.0, harmonics=(1.0, 0.5, 0.3)),
    [0.0] * n_samples(0.12) + tone(170, 120, 0.10, decay=10.0, harmonics=(1.0, 0.5)),
)
write("invalid.wav", invalid)

# 3. Patlama sesleri: pentatonik merdiven (zincir uzadıkça tizleşiyor)
#    Böylece arka arkaya patlamalar müzikal bir ezgi gibi duyuluyor.
for idx, freq in enumerate([523.25, 587.33, 698.46, 783.99, 880.00, 1046.50], start=1):
    pop = mix(
        tone(freq * 0.75, freq * 1.6, 0.13, decay=11.0, harmonics=(1.0, 0.3, 0.12)),
        [s * 0.25 for s in noise(0.02, decay=60.0)],
    )
    write(f"pop{idx}.wav", pop)

# 4. Bomba oluşumu: yükselen kıvılcım arpeji
write(
    "bomb_create.wav",
    sequence([(659.25, 0.18, 9), (880.0, 0.18, 9), (1174.66, 0.30, 7)], gap=0.055),
)

# 5. Bomba patlaması: gürültü patlaması + alçak gümbürtü
blast = mix(
    lowpass(noise(0.55, decay=6.5), 4000, 260),
    tone(90, 38, 0.45, decay=7.0, harmonics=(1.0, 0.4)),
    [s * 0.35 for s in noise(0.05, decay=45.0)],
)
write("bomb.wav", blast)

# 6. Renk patlaması: yükselen süpürme + parlak arpej
write(
    "rainbow.wav",
    mix(
        tone(380, 1700, 0.55, decay=4.0, harmonics=(1.0, 0.4, 0.18)),
        sequence(
            [(783.99, 0.22, 8), (1046.50, 0.22, 8), (1318.51, 0.45, 5)],
            gap=0.07,
        ),
    ),
)

# 7. Çapraz patlama: iki keskin ışın süpürmesi + kısa gümbürtü
sweep = mix(
    tone(1500, 260, 0.30, decay=6.0, harmonics=(1.0, 0.35, 0.15)),
    lowpass(noise(0.30, decay=9.0), 6000, 900),
)
cross = [0.0] * n_samples(0.55)
for i, s in enumerate(sweep):
    cross[i] += s
offset = n_samples(0.11)
for i, s in enumerate(sweep):
    if offset + i < len(cross):
        cross[offset + i] += s * 0.75
for i, s in enumerate(tone(150, 60, 0.30, decay=7.0, harmonics=(1.0, 0.4))):
    if offset + i < len(cross):
        cross[offset + i] += s * 0.8
write("cross.wav", cross)

# 8. Mega patlama: yükselen gerilim + dev gümbürtü + serpinti
riser = tone(180, 900, 0.42, decay=-1.2, harmonics=(1.0, 0.3))
boom = mix(
    lowpass(noise(1.0, decay=3.8), 5000, 140),
    tone(120, 32, 0.85, decay=4.2, harmonics=(1.0, 0.5, 0.25)),
    [s * 0.4 for s in noise(0.08, decay=35.0)],
)
mega = [0.0] * n_samples(0.34 + 1.0)
for i, s in enumerate(riser):
    mega[i] += s * 0.5
offset = n_samples(0.34)
for i, s in enumerate(boom):
    mega[offset + i] += s
write("mega.wav", mega)

# 8. Tahtanın dökülmesi: pentatonik boncuklar + yumuşak hışırtı
#    Sütunlar 50 ms arayla düştüğü için notaları da o ritme yakın diziyoruz.
POUR_SCALE = [1046.50, 880.00, 783.99, 659.25, 587.33, 523.25, 440.00, 392.00]
pour = [0.0] * n_samples(1.15)
for idx, freq in enumerate(POUR_SCALE):
    start = n_samples(0.045 * idx)
    for i, s in enumerate(bell(freq, 0.5, decay=7.0, amp=0.55)):
        if start + i < len(pour):
            pour[start + i] += s
# altta hafif bir akış hışırtısı
for i, s in enumerate(lowpass(noise(0.75, decay=3.0), 3000, 500)):
    if i < len(pour):
        pour[i] += s * 0.18
# son şeker otururken küçük bir tok vuruş
thud_at = n_samples(0.62)
for i, s in enumerate(tone(190, 90, 0.22, decay=9.0, harmonics=(1.0, 0.4))):
    if thud_at + i < len(pour):
        pour[thud_at + i] += s * 0.5
write("pour.wav", pour)

# 9. Yeni rekor: yükselen zafer arpeji + parıltı
write(
    "record.wav",
    mix(
        sequence(
            [
                (523.25, 0.18, 9),
                (659.25, 0.18, 9),
                (783.99, 0.18, 9),
                (1046.50, 0.22, 8),
                (1318.51, 0.75, 3),
            ],
            gap=0.085,
        ),
        [0.0] * n_samples(0.34)
        + [s * 0.35 for s in tone(1800, 3200, 0.55, decay=3.0, harmonics=(1.0, 0.3))],
    ),
)

# 10. Seviye atlama: yükselen beşli merdiven + parlak kuyruk
write(
    "levelup.wav",
    mix(
        sequence(
            [
                (392.00, 0.16, 10),
                (523.25, 0.16, 10),
                (659.25, 0.16, 10),
                (783.99, 0.16, 10),
                (1046.50, 0.85, 3),
            ],
            gap=0.075,
        ),
        [0.0] * n_samples(0.30)
        + [s * 0.3 for s in tone(900, 2600, 0.6, decay=3.2, harmonics=(1.0, 0.35))],
    ),
)

# 11. Oyun bitti: inen dört nota, uzun sönümlü
write(
    "gameover.wav",
    sequence(
        [(523.25, 0.30, 5), (440.00, 0.30, 5), (349.23, 0.35, 4), (261.63, 0.95, 2)],
        gap=0.20,
    ),
)

# 9. Tebrik fanfarları: zincir uzadıkça daha görkemli
write("praise1.wav", sequence([(523.25, 0.25, 7), (659.25, 0.35, 6)], gap=0.09))
write(
    "praise2.wav",
    sequence([(523.25, 0.22, 8), (659.25, 0.22, 8), (783.99, 0.42, 5)], gap=0.085),
)
write(
    "praise3.wav",
    sequence(
        [(523.25, 0.20, 9), (659.25, 0.20, 9), (783.99, 0.20, 9), (1046.50, 0.60, 4)],
        gap=0.08,
    ),
)
