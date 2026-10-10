# Testvektorer for fargeregningen

`Fargeregning.json` inneholder resultater fra FargeKjerne for et fast utvalg farger og fargepar, så andre
implementasjoner (f.eks. TypeScript på web) kan testes mot samme regning. FargeKjerne er fasiten.

- **`farger`** – hver oppføring har inndata (`inn`: sRGB-hex, OKLCH – også utenfor gamut – eller Display P3) og
  resultatene: lineær sRGB, sRGB, XYZ (D65), OKLab, OKLCH, CIELab og CIELCH (D50), Display P3, HSL, HSB, om fargen er
  innenfor sRGB/Display P3, gamut-kartlagt sRGB og Display P3 (CSS Color 4), hex og LRV.
- **`par`** – tekst og bakgrunn: WCAG 2-kontrast, ΔE2000, ΔE76 og ΔE i OKLab, og hvilken tekstfarge (sort
  eller hvit) som leses best på bakgrunnen.
- **`konvensjoner`** – skalaer, hvitpunkter og definisjoner for hvert felt.

Tallene er avrundet til 12 desimaler; bruk 1e-9 som toleranse.

Fila lages og kontrolleres av `Tests/FargeKjerneTests/TestvektorerTests.swift`. Ved en bevisst endring i regningen:

```bash
LAG_TESTVEKTORER=1 swift test --filter Testvektorer
```

Se også `Tests/FargeKjerneTests/Testlenker.json` for delingslenker.
