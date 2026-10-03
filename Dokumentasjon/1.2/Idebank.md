# Idébank for 1.2 og senere – lys og fargemåling

Eivind prioriterte (2026-10-03):

1. **Kompensere plukkede farger for lysforholdene** (hovedsak).
2. **Lagrede lysmiljøer** – «se denne fargen i [lagret lysmiljø]» (sekundært).

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
