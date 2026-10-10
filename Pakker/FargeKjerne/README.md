# FargeKjerne

Fargevitenskapen i [Kolorist](https://kolorist.no): Swift-pakken appen er bygd på. Privat repo.

> **Kilden er Kolorist-repoet** (`Pakker/FargeKjerne`). Endringer gjøres der og speiles hit med
> `Pakker/publiser_fargekjerne.sh` i Kolorist, med et versjonsmerke per utgivelse. Ikke gjør endringer direkte her.

## Produkter

| Produkt | Innhold |
|---|---|
| `FargeKjerne` | `Farge` (kanonisk lineær utvidet sRGB), fargerom (sRGB, Display P3, OKLab/OKLCH, CIELab/LCH D50, HSL/HSB, CMYK), gamut-kartlegging etter CSS Color 4, overganger i OKLab, harmonier, kontrast (WCAG 2), LRV, fargesyn, ICC via CoreGraphics, delingslenker, eksport og import (ASE, CSS, DTCG, GPL, SwiftUI m.fl.) |
| `FargeMaaling` | Spektre, kolorimetri (CIE 1931 2°), fargetemperatur, CAM16, betraktningsforhold, lyskompensasjon og referansekort |
| `FargeKI` | Verdiord → palett og beskrivelse → farge (Foundation Models på enheten, med leksikon som reserve) |

Plattformer: iOS, iPadOS, macOS og visionOS 26. Swift 6.2.

```swift
dependencies: [
    .package(url: "git@github.com:eivijoha/FargeKjerne.git", from: "0.1.1"),
],
targets: [
    .target(name: "MittMål", dependencies: [
        .product(name: "FargeKjerne", package: "FargeKjerne"),
        .product(name: "FargeMaaling", package: "FargeKjerne"),
    ]),
]
```

Repoet er privat: SwiftPM henter det med din SSH-nøkkel (eller GitHub-kontoen i Xcode).

## Versjoner

[Semantisk versjonering](https://semver.org). I 0.x kan en mindre versjon (0.2.0) endre API-et; endringene står i
[CHANGELOG.md](CHANGELOG.md). 1.0 når API-et er stabilt.

## Tester og testvektorer

```bash
swift test
```

`Testvektorer/Fargeregning.json` har resultater for et fast utvalg farger og fargepar, så andre implementasjoner (f.eks.
TypeScript) kan testes mot samme regning – se [Testvektorer/README.md](Testvektorer/README.md). Delingslenkene har sine i
`Tests/FargeKjerneTests/Testlenker.json`.

Filnavn i pakken er uten æ, ø og å (SwiftPM klarer ikke å lese dem fra git).

`swift run kiprove` prøver KI-promptene mot modellen på Macen (utviklerverktøy, ikke et produkt).

## Data og kreditering

- **CIE-data** (`FargeMaaling/CIEData.json`): CIE 15:2018 – 1931 2°-observatøren, dagslysserien og standardlyskilder.
- **Filamentfarger** (`FargeKjerne/Filamentfarger.json`): fra [FilamentColors.xyz](https://filamentcolors.xyz/), lisensiert
  under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Krediteringen skal følge med der fargene vises.
- **Fargesemantikk** (`FargeKI/Fargesemantikk.json`): Kolorists egen kunnskapsbase.
