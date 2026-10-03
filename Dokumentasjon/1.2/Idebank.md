# Idébank for 1.2 og senere – lys og fargemåling

Eivind prioriterte (2026-10-03):

1. **Kompensere plukkede farger for lysforholdene** (hovedsak).
2. **Lagrede lysmiljøer** – «se denne fargen i [lagret lysmiljø]» (sekundært).

**IT8-referansekort** (Eivind har et; må være refleksivt IT8.7/2 / ISO 12641, med referansefil i CGATS-format):
- Karakterisere iPhone-kameraet én gang under godt lys → deretter holder et gråkort på stedet (nivå B blir presist).
- Gråskalaen gir kameraets tonekurve → nøyaktig linearisering av kamerabildet.
- Presisjonsmodus med kortet i bildet (full korreksjon for lys + kamera, typisk snitt-ΔE00 ≈ 2 eller lavere).
- Lysmiljøer kan lagre hele korreksjonen, ikke bare Kelvin og lux.
- Dokumentert nøyaktighet («snitt ΔE00 1,6, maks 3,9»), og et grovt varsel om lys med dårlig fargegjengivelse.
- Krever: import av CGATS-referansefil (via «Mine fargerom»), hjørnemarkering eller Vision-gjenkjenning og
  perspektivretting, jevnt lys uten gjenskinn.

Øvrige muligheter som skal tas opp igjen senere:

- **Lysmåler (lux) for rommet** med referansekort, sammenlignet med anbefalte nivåer (f.eks. NS-EN 12464-1:
  kontor 500 lx, lesing 300–500 lx, korridor ≈ 100 lx) – særlig relevant for universell utforming.
- **Målt luminanskontrast mellom flater i rommet** (dør mot vegg i faktisk belysning), som supplement til
  LRV-kontrasten etter NS 11001.
- **Dokumentasjon av lysforhold** sammen med plukkede farger og kontrastmålinger («≈ 3200 K, ≈ 450 lx»).
- **Paletter som tåler lyset**: varsle om farger som endrer karakter mye under varmt/kaldt lys, og foreslå justering.
- **Fargetemperatur som verdi** for hvite og nesten hvite farger (lysdesign, «varme» og «kalde» hvite).
- **Lysstyrkens effekt på fargeinntrykk** (Hunt- og Stevens-effekten, CAM16) – inngår delvis i lagrede lysmiljøer.
- **Eksterne fargemålere** for det kameraet ikke kan måle: fargegjengivelse (CRI) og metameri (spektralmåling).

Tekniske forutsetninger: iOS gir ikke tilgang til omgivelseslyssensoren; kameraet (AVFoundation) gir
hvitbalanse (Kelvin og tint) og eksponering. Mac med innebygd kamera gir ikke hvitbalansedata.
