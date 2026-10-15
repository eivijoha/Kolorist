# App Store Connect – Kolorist 1.4

Under arbeid på grenen `versjon-1.4`. Tekstene fylles ut etter hvert som 1.4 tar form; App-informasjon, URL-er og
personvern er som i 1.3 (`Dokumentasjon/1.3/AppStore.md`).

## Nytt i denne versjonen – utkast

Nyheter:

- **APCA tilbake (med tillatelse fra rettighetshaver, 2026-10-15):** lesekontrast (Lc) i kontrastsjekken med «Rett opp»,
  tekst og ikoner på fargefelt etter APCA (WCAG 2 som gulv der krav gjelder), Lc i designsystem og toneskala. WCAG+ (hvit
  ved minst 2,7:1) brukes bare når ingen lesbarhetsmodell er koblet inn i FargeKjerne.

- **Fargerapporter:** vanskelige fargepar, kontrast mellom flater (LRV) og ΔE kan kopieres som tabell, deles som lenke
  (kolorist.no viser rapporten) og skrives ut som A4-PDF.
- **Dra en hel palett ut:** som delingslenke og som hex-verdier (også nyttig for Kolorist underviser, men nevnes ikke).
- **Installerte ICC-profiler på Mac** i profilvelgeren.
- **Spørsmål om omtale** nederst i palettpanelet (nevnes ikke).

```
• APCA er tilbake: lesekontrast (Lc) i kontrastsjekken, med «Rett opp» til nivået, og Lc i designsystem og toneskala.
• Tekst og ikoner på fargefelt i sort eller hvit etter opplevd lesbarhet (APCA) – knappetekst i designsystemet holder fortsatt kravet i WCAG.
• Fargerapporter: kopier vurderingen av vanskelige fargepar, kontrast mellom flater og ΔE som tabell, del den som lenke eller skriv den ut.
• Dra en hel palett inn i andre programmer – som lenke eller som hex-verdier.
• På Mac: velg blant ICC-profilene som er installert på maskinen.
```

```
• APCA is back: reading contrast (Lc) in the contrast check, with auto-fix to the level, and Lc in the design system and tone scale.
• Text and icons on colour fields in black or white by perceived readability (APCA) – button text in the design system still meets the WCAG requirement.
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
