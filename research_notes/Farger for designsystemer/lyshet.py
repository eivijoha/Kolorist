#!/usr/bin/env python3
"""Lyshet mot kontrast. Kun standardbiblioteket. Kjør: python3 lyshet.py"""
import math

# ---------- sRGB / lineær ----------
def srgb_to_lin(c):
    return c/12.92 if c <= 0.04045 else ((c+0.055)/1.055)**2.4
def lin_to_srgb(c):
    return 12.92*c if c <= 0.0031308 else 1.055*c**(1/2.4)-0.055

# ---------- OKLab (Ottosson 2020) ----------
def lin_to_oklab(r, g, b):
    l = 0.4122214708*r + 0.5363325363*g + 0.0514459929*b
    m = 0.2119034982*r + 0.6806995451*g + 0.1073969566*b
    s = 0.0883024619*r + 0.2817188376*g + 0.6299787005*b
    l, m, s = (math.copysign(abs(x)**(1/3), x) for x in (l, m, s))
    return (0.2104542553*l + 0.7936177850*m - 0.0040720468*s,
            1.9779984951*l - 2.4285922050*m + 0.4505937099*s,
            0.0259040371*l + 0.7827717662*m - 0.8086757660*s)
def oklab_to_lin(L, a, b):
    l = (L + 0.3963377774*a + 0.2158037573*b)**3
    m = (L - 0.1055613458*a - 0.0638541728*b)**3
    s = (L - 0.0894841775*a - 1.2914855480*b)**3
    return (4.0767416621*l - 3.3077115913*m + 0.2309699292*s,
            -1.2684380046*l + 2.6097574011*m - 0.3413193965*s,
            -0.0041960863*l - 0.7034186147*m + 1.7076147010*s)
def oklch_to_lin(L, C, h):
    hr = math.radians(h)
    return oklab_to_lin(L, C*math.cos(hr), C*math.sin(hr))
EPS = 1e-7
def in_gamut(rgb):
    return all(-EPS <= c <= 1+EPS for c in rgb)
def max_chroma(L, h):
    """Største C som er innenfor sRGB ved gitt L og h (bisection)."""
    if L <= 0 or L >= 1: return 0.0
    lo, hi = 0.0, 0.5
    for _ in range(50):
        mid = (lo+hi)/2
        if in_gamut(oklch_to_lin(L, mid, h)): lo = mid
        else: hi = mid
    return lo
def clamp01(x): return min(1.0, max(0.0, x))

# ---------- Y, CIE L*, WCAG 2 ----------
def Y_of_lin(rgb):
    r, g, b = (clamp01(c) for c in rgb)
    return 0.2126*r + 0.7152*g + 0.0722*b      # WCAG 2.x-koeffisienter
def Y_exact(rgb):                               # CSS Color 4 / sRGB-matrisen
    r, g, b = (clamp01(c) for c in rgb)
    return 0.2126729*r + 0.7151522*g + 0.0721750*b
def Lstar(Y):
    return 116*Y**(1/3)-16 if Y > 216/24389 else Y*24389/27
def Y_of_Lstar(Ls):
    return ((Ls+16)/116)**3 if Ls > 8 else Ls*27/24389
def wcag(Y1, Y2):
    a, b = max(Y1, Y2), min(Y1, Y2)
    return (a+0.05)/(b+0.05)

# ---------- APCA 0.0.98G-4g ----------
def apca_Y(rgb_lin_unused=None, srgb=None):
    r, g, b = (clamp01(c) for c in srgb)
    return 0.2126729*r**2.4 + 0.7151522*g**2.4 + 0.0721750*b**2.4   # ren gamma 2.4, ikke stykkevis
def apca_Lc(Ytxt, Ybg):
    blkThrs, blkClmp = 0.022, 1.414
    normBG, normTXT, revTXT, revBG = 0.56, 0.57, 0.62, 0.65
    scaleBoW = scaleWoB = 1.14
    loBoWoffset = loWoBoffset = 0.027
    deltaYmin, loClip = 0.0005, 0.1
    if Ytxt < blkThrs: Ytxt += (blkThrs-Ytxt)**blkClmp
    if Ybg < blkThrs: Ybg += (blkThrs-Ybg)**blkClmp
    if abs(Ybg-Ytxt) < deltaYmin: return 0.0
    if Ybg > Ytxt:
        s = (Ybg**normBG - Ytxt**normTXT)*scaleBoW
        return 0.0 if s < loClip else (s-loBoWoffset)*100
    s = (Ybg**revBG - Ytxt**revTXT)*scaleWoB
    return 0.0 if s > -loClip else (s+loWoBoffset)*100

# ---------- farge fra (L, C-modus, h) ----------
def color_at(L, h, cap):
    C = max_chroma(L, h) if cap is None else min(cap, max_chroma(L, h))
    lin = oklch_to_lin(L, C, h)
    lin = tuple(clamp01(c) for c in lin)
    srgb = tuple(lin_to_srgb(c) for c in lin)
    return C, lin, srgb

def solve_L(h, cap, f, target, increasing_in_L):
    """Finn OKLCH L slik at f(L)=target (f monoton i L)."""
    lo, hi = 0.001, 0.999
    for _ in range(60):
        mid = (lo+hi)/2
        v = f(mid)
        if (v < target) == increasing_in_L: lo = mid
        else: hi = mid
    return (lo+hi)/2

HUES = list(range(0, 360, 30))

def wcag_vs_white(L, h, cap):  # kontrast mot hvit (synkende i L)
    C, lin, _ = color_at(L, h, cap)
    return wcag(1.0, Y_of_lin(lin))
def wcag_vs_black(L, h, cap):  # kontrast mot svart (stigende i L)
    C, lin, _ = color_at(L, h, cap)
    return wcag(Y_of_lin(lin), 0.0)
def apca_text_on_white(L, h, cap):  # Lc, fargen er tekst på hvit, positiv, synkende i L
    C, lin, srgb = color_at(L, h, cap)
    return apca_Lc(apca_Y(srgb=srgb), 1.0)
def apca_white_on_color(L, h, cap):  # |Lc|, hvit tekst på fargen, synkende i L
    C, lin, srgb = color_at(L, h, cap)
    return abs(apca_Lc(1.0, apca_Y(srgb=srgb)))
def apca_black_on_color(L, h, cap):  # Lc, svart tekst på fargen, stigende i L
    C, lin, srgb = color_at(L, h, cap)
    return apca_Lc(0.0, apca_Y(srgb=srgb))

def stats(xs):
    return min(xs), max(xs), max(xs)-min(xs), (sum(xs)/len(xs))

def table(title, fn, target, increasing, cap, kind="wcag"):
    print(f"\n#### {title}\n")
    print("| Kulør h | C brukt | OKLCH L | CIE L* | Y | sRGB hex |")
    print("|---:|---:|---:|---:|---:|:--|")
    Ls, Lss, Ys = [], [], []
    for h in HUES:
        L = solve_L(h, cap, lambda x: fn(x, h, cap), target, increasing)
        C, lin, srgb = color_at(L, h, cap)
        Y = Y_of_lin(lin) if kind == "wcag" else Y_exact(lin)
        ls = Lstar(Y)
        hexs = "#"+"".join(f"{round(clamp01(c)*255):02X}" for c in srgb)
        Ls.append(L); Lss.append(ls); Ys.append(Y)
        print(f"| {h} | {C:.3f} | {L:.4f} | {ls:.2f} | {Y:.4f} | {hexs} |")
    a = stats(Ls); b = stats(Lss); c = stats(Ys)
    print(f"| **min–maks** | | {a[0]:.4f}–{a[1]:.4f} | {b[0]:.2f}–{b[1]:.2f} | {c[0]:.4f}–{c[1]:.4f} | |")
    print(f"| **spredning (maks−min)** | | **{a[2]:.4f}** (={a[2]*100:.1f} på 0–100-skala) | **{b[2]:.2f}** | {c[2]:.4f} | |")
    return a[2]*100, b[2]

def main():
    # Selvtest
    assert abs(apca_Lc(0.0, 1.0)-106.04) < 0.1, apca_Lc(0.0, 1.0)
    assert abs(apca_Lc(1.0, 0.0)+107.88) < 0.1, apca_Lc(1.0, 0.0)
    print(f"Selvtest APCA: svart på hvit {apca_Lc(0,1):.2f}, hvit på svart {apca_Lc(1,0):.2f}")
    print(f"Selvtest: L*(Y=1)={Lstar(1):.2f}, wcag(1,0)={wcag(1,0):.1f}")
    summary = []
    for capname, cap in (("C = min(0,12, maks i gamut)", 0.12), ("C = maks i sRGB-gamut", None)):
        print(f"\n### WCAG 2 – {capname}")
        for title, fn, tgt, inc in (
            ("3:1 mot hvit", wcag_vs_white, 3.0, False),
            ("4,5:1 mot hvit", wcag_vs_white, 4.5, False),
            ("4,5:1 mot svart", wcag_vs_black, 4.5, True)):
            s = table(f"{title} ({capname})", lambda L, h, c, fn=fn: fn(L, h, c), tgt, inc, cap)
            summary.append((capname, "WCAG "+title, s))
        print(f"\n### APCA 0.0.98G-4g – {capname}")
        for lc in (60, 75, 90):
            s = table(f"APCA: farget tekst på hvit, Lc {lc} ({capname})", apca_text_on_white, lc, False, cap, kind="apca")
            summary.append((capname, f"APCA tekst på hvit Lc {lc}", s))
            s = table(f"APCA: hvit tekst på fargen, |Lc| {lc} ({capname})", apca_white_on_color, lc, False, cap, kind="apca")
            summary.append((capname, f"APCA hvit på farge |Lc| {lc}", s))
    print("\n### Oppsummering: spredning over 12 kulører (OKLCH L ×100 vs CIE L*)\n")
    print("| Kromatilstand | Mål | Spredning OKLCH L (×100) | Spredning CIE L* |\n|:--|:--|---:|---:|")
    for cn, name, (so, sl) in summary:
        print(f"| {cn} | {name} | {so:.1f} | {sl:.2f} |")

    # Fast OKLCH L: hvilken kontrast får du?
    print("\n### Fast OKLCH L → kontrast mot hvit på tvers av 12 kulører (C = min(0,12, maks))\n")
    print("| OKLCH L | min kontrast | maks kontrast | CIE L* min–maks |\n|---:|---:|---:|:--|")
    for L in (0.45, 0.50, 0.56, 0.60, 0.65, 0.70):
        cs, ls = [], []
        for h in HUES:
            C, lin, _ = color_at(L, h, 0.12)
            Y = Y_of_lin(lin); cs.append(wcag(1.0, Y)); ls.append(Lstar(Y))
        print(f"| {L:.2f} | {min(cs):.2f} | {max(cs):.2f} | {min(ls):.1f}–{max(ls):.1f} |")
    print("\n### Samme, men C = maks i gamut\n")
    print("| OKLCH L | min kontrast | maks kontrast | CIE L* min–maks |\n|---:|---:|---:|:--|")
    for L in (0.45, 0.50, 0.56, 0.60, 0.65, 0.70):
        cs, ls = [], []
        for h in HUES:
            C, lin, _ = color_at(L, h, None)
            Y = Y_of_lin(lin); cs.append(wcag(1.0, Y)); ls.append(Lstar(Y))
        print(f"| {L:.2f} | {min(cs):.2f} | {max(cs):.2f} | {min(ls):.1f}–{max(ls):.1f} |")

    # Grå (C=0): OKLCH L mot L*
    print("\n### Nøytrale (C=0): OKLCH L ved gitt CIE L*\n")
    print("| CIE L* | OKLCH L (×100) |\n|---:|---:|")
    for ls in (95, 90, 80, 70, 60, 50, 40, 30, 20, 10):
        Y = Y_of_Lstar(ls); L = Y**(1/3)
        print(f"| {ls} | {L*100:.1f} |")

    # Material-regelen: eksakt minste toneforskjell
    print("\n### Material-regelen «40 tonar = 3:1, 50 tonar = 4,5:1» (eksakt, Y fra L*)\n")
    for ratio in (3.0, 4.5, 7.0):
        worst = 0
        worst_at = None
        t = 0.0
        # for hvert par (tA,tB) finn minste forskjell d slik at kontrast >= ratio; ta maks over posisjon
        for i in range(0, 10001):
            tA = i/100  # lys tone fra 0..100
            YA = Y_of_Lstar(tA)
            # mørk tone tB som gir akkurat ratio: (YA+.05)/(YB+.05)=ratio
            YB = (YA+0.05)/ratio-0.05
            if YB < 0: continue
            d = tA-Lstar(YB)
            if d > worst: worst, worst_at = d, tA
        print(f"- Kontrast {ratio}:1 krever høyst ΔL* = {worst:.2f} (verst ved lys tone {worst_at:.2f})")
    for d in (40, 50):
        print(f"- Tone 100 mot tone {100-d}: {wcag(1.0, Y_of_Lstar(100-d)):.3f}:1;  tone {d} mot tone 0: {wcag(Y_of_Lstar(d), 0):.3f}:1")
    # Verste tilfelle for ΔL*=40 og 50 over hele skalaen
    for d in (40, 50):
        mn = min((wcag(Y_of_Lstar(t+d), Y_of_Lstar(t)), t) for t in [i/100 for i in range(0, 100*(100-d)+1)])
        print(f"- Minste kontrast for ΔL*={d} over hele skalaen: {mn[0]:.3f}:1 ved lav tone {mn[1]:.2f}")

    # USWDS-vinduer
    print("\n### USWDS: luminansvinduer omregnet til CIE L*\n")
    win = {5:(0.850,0.930),10:(0.750,0.820),20:(0.500,0.650),30:(0.350,0.450),40:(0.225,0.300),50:(0.175,0.183),
           60:(0.100,0.125),70:(0.050,0.070),80:(0.020,0.040),90:(0.005,0.015)}
    print("| Grad | Y min–maks | L* min–maks | 100−grad | Kontrast mot hvit (min–maks) |\n|---:|:--|:--|---:|:--|")
    for g, (a, b) in win.items():
        print(f"| {g} | {a}–{b} | {Lstar(a):.1f}–{Lstar(b):.1f} | {100-g} | {wcag(1,b):.2f}–{wcag(1,a):.2f} |")
    print("\nWorst-case kontrast for «magisk tall» (gradpar, vinduer: lys grad g1 med min-Y, mørk grad g2 med maks-Y):\n")
    allw = dict(win); allw[0] = (1.0, 1.0); allw[100] = (0.0, 0.0)
    for mag in (40, 50, 70):
        worst = 9e9; wp = None
        for g1 in allw:
            g2 = g1+mag
            if g2 in allw:
                r = wcag(allw[g1][0], allw[g2][1])
                if r < worst: worst, wp = r, (g1, g2)
        print(f"- Magisk tall {mag}: laveste mulige kontrast {worst:.2f}:1 (grad {wp[0]} mot {wp[1]})")
if __name__ == "__main__":
    main()
