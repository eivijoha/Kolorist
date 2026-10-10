# Data i FargeKjerne og lisensene deres

| Fil | Innhold | Kilde og lisens |
|---|---|---|
| `Sources/FargeMaaling/CIEData.json` | CIE 1931 2°-observatøren, dagslysserien S0–S2, lyskildene FL og LED (380–780 nm, 5 nm) | © CIE, **CC BY-SA 4.0** (via colour-science 0.4.4). Uttrekket er lisensiert under CC BY-SA 4.0 og publisert på https://kolorist.no/data/cie/. Deles det videre, må CIE krediteres og uttrekket deles under samme lisens. |
| `Sources/FargeKjerne/Filamentfarger.json` | Filamentfarger | FilamentColors.xyz, **CC BY 4.0** (kreditering i appen og på nettsiden). |
| `Sources/FargeKI/Fargesemantikk.json` | Fargebegreper | Laget for Kolorist. |

## Metoder som er lisensvurdert

- **Burns' refleksjonsrekonstruksjon (LLSS)** i `Refleksjonsestimat.swift`: skrevet fra artikkelen (Color Research &
  Application 45(1), 2020), ikke fra Burns' kode (CC BY-SA). Bare kildehenvisning; står i «Metoder og kilder».
- **Root-polynomial fargekorreksjon** (Finlayson mfl. 2015): Apples patent US 9,049,407 utløp 2019.

Regel (2026-10-10): FargeKjerne og Kolorist skal ikke inneholde modeller eller data med vilkår ut over Creative Commons
(CC BY og CC BY-SA godtas), og andres varemerker brukes ikke som navn på funksjoner. APCA er tatt ut av den grunn (se
`Dokumentasjon/APCA-gjeninnforing.md`), og Munsell (varemerke; renotasjonsdata med uklart opphav for de ekstrapolerte
verdiene) ble tatt ut 2026-10-10 (se `Dokumentasjon/Munsell-gjeninnforing.md`).
