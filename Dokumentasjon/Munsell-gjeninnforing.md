# Munsell – tatt ut 2026-10-10, og hvordan det kan føres tilbake

Fargemodellen og fargesirkelen etter Munsell (kulør, valør og kroma) ble fjernet fra Kolorist og FargeKjerne
2026-10-10 (versjon 1.3.1), av to grunner:

- **Varemerke:** Munsell® er et registrert varemerke (X-Rite). Navnet ble brukt som navn på en fargemodell, en
  fargesirkel og en notasjon i appen, på nettsiden og i App Store-tekstene.
- **Data:** `Munsell.json` var RITs `all.dat` (4 995 oppføringer). Rundt 2 700 er de målte verdiene fra 1943; resten er
  ekstrapolert senere, med uklart opphav og uten lisens. RIT oppgir ingen lisens for filene.

## Siste versjon med Munsell

- Git-merket **`munsell-siste`** (commit `1318c41` på `versjon-1.3.1`) har hele implementeringen.
- Commiten som tok det ut, finnes med `git log --grep "Munsell tatt ut"`. Den kan reverseres med `git revert`, men se
  vilkårene under først.

Det som kommer tilbake: `Munsell.swift` (typen `Munsell`, `Farge.munsell`, `Farge(munsell:)`, `Farge.innenforMunsell`,
trinn og notasjon), `Munsell.json`, `Fargemodell.munsell`, `Fargesirkel.munsell` med `trinn`/`avrundet` og den trinnvise
sirkeltegningen i `HarmoniSeksjon`, valør/kroma-gliderne i harmonien, Munsell-trinn i `FargeEditor`, notasjon i
`Fargetolk`, `DeltFarge.munsell` (`mu`), `Metode.munsell`, `FargemodellAppEnum.munsell`, testene (`MunsellTests`,
`munsellTrinn` m.fl.) og visningssidens Munsell-rad (`web/<versjon>/l/vis.js`). Skjermbildet `skjermbilde-munsell.png`
og tekstene på nettsiden (arkitektur, funksjoner, støtte, metoder) ble endret i samme commit.

## Før det føres tilbake

1. **Nøytralt navn.** Ikke «Munsell» som navn på modell, sirkel, notasjon eller funksjon, for eksempel «Kulør · valør ·
   kroma» eller «HVC». Navnet kan stå i kildehenvisningen, med «Munsell® er et registrert varemerke for X-Rite, Inc.;
   Kolorist er ikke tilknyttet».
2. **Bare de målte dataene.** Table I i Newhall, Nickerson & Judd, JOSA 33(7), 385–418 (1943), og Judd & Wyszecki,
   JOSA 46(4), 281–284 (1956). Ifølge The Online Books Page er ingen av heftene fornyet, og de er derfor allemannseie i
   USA. Kontroller tallene mot et skann av artiklene, ikke bare mot RITs `real.dat`.
3. **Egen ekstrapolasjon eller ingen.** Utenfor de målte dataene: lag en egen ekstrapolasjon (dokumentert) eller la
   fargene være uten notasjon. Ikke bruk RITs `all.dat` eller Centores ekstrapolerte filer (ingen lisens).
4. **Lisensvurder på nytt** og oppdater `Pakker/FargeKjerne/DATALISENSER.md`.
