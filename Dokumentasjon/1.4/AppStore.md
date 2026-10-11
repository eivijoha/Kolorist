# App Store Connect – Kolorist 1.4

Under arbeid på grenen `versjon-1.4`. Tekstene fylles ut etter hvert som 1.4 tar form; App-informasjon, URL-er og
personvern er som i 1.3 (`Dokumentasjon/1.3/AppStore.md`).

## Nytt i denne versjonen – utkast

Nyheter:

- **Tekst på fargeflater (WCAG+, internt navn):** hvit tekst når hvit gir minst 2,7:1 etter WCAG 2, ellers sort. Mettede
  mellomtoner får hvit tekst slik øyet foretrekker; knappetekst i designsystemet holder fortsatt 4,5:1. Navnet «WCAG+»
  brukes ikke i appen eller tekstene.

- **Fargerapporter:** vanskelige fargepar, kontrast mellom flater (LRV) og ΔE kan kopieres som tabell, deles som lenke
  (kolorist.no viser rapporten) og skrives ut som A4-PDF.
- **Dra en hel palett ut:** som delingslenke og som hex-verdier (også nyttig for Kolorist underviser, men nevnes ikke).
- **Installerte ICC-profiler på Mac** i profilvelgeren.
- **Spørsmål om omtale** nederst i palettpanelet (nevnes ikke).

```
• Tekst på fargeflater følger øyet: mettede mellomtoner får hvit tekst, og knappetekst i designsystemet holder fortsatt kravet i WCAG.
• Fargerapporter: kopier vurderingen av vanskelige fargepar, kontrast mellom flater og ΔE som tabell, del den som lenke eller skriv den ut.
• Dra en hel palett inn i andre programmer – som lenke eller som hex-verdier.
• På Mac: velg blant ICC-profilene som er installert på maskinen.
```

```
• Text on colour fields follows the eye: saturated mid-tones get white text, and button text in the design system still meets the WCAG requirement.
• Colour reports: copy the assessment of hard-to-tell-apart colour pairs, contrast between surfaces and ΔE as a table, share it as a link or print it.
• Drag a whole palette into other apps – as a link or as hex values.
• On the Mac: choose among the ICC profiles installed on the computer.
```

Feilrettinger (nevnes i «Nytt i denne versjonen», ikke som nyhet på nettsiden):

- **Konvertering mellom profiler:** «Bruk som aktiv farge» setter fargen i målprofilens fargemodell og fargerom (for
  eksempel CMYK i valgt trykkprofil) med nøyaktig de konverterte verdiene, i stedet for bare fargen.

Norsk:

```
• Rettet: når du bruker en konvertert farge som aktiv farge, får du den i målprofilens fargemodell og fargerom, med de konverterte verdiene.
```

English:

```
• Fixed: when you use a converted colour as the active colour, you now get it in the target profile’s colour model and colour space, with the converted values.
```
