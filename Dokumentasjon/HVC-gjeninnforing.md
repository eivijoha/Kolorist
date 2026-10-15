# Fargemodellen med kulør, valør og kroma (HVC) – tatt ut 2026-10-10, og hvordan den kan føres tilbake

Fargemodellen og fargesirkelen med kulør, valør og kroma ble fjernet fra Kolorist og FargeKjerne 2026-10-10
(versjon 1.3.1), av to grunner:

- **Varemerke:** Modellen var oppkalt etter et registrert varemerke, og navnet ble brukt på en fargemodell, en
  fargesirkel og en notasjon i appen, på nettsiden og i App Store-tekstene.
- **Data:** Datafila var tabelldata fra RIT (`all.dat`, 4 995 oppføringer). Rundt 2 700 er de målte verdiene fra 1943;
  resten er ekstrapolert senere, med uklart opphav og uten lisens. RIT oppgir ingen lisens for filene.

## Siste versjon med modellen

- Git-merket **`hvc-siste`** (commit `1318c41` på `versjon-1.3.1`) har hele implementeringen.
- Commiten som tok den ut, er `fbd5f5e` på `versjon-1.3.1`. Den kan reverseres med `git revert`, men se vilkårene under
  først. Den gamle koden bruker varemerket i filnavn, typer og tekster; det må byttes ut før noe føres tilbake.

Det som kommer tilbake: modellens Swift-fil (typen, konvertering til og fra `Farge`, gamut-sjekk, trinn og notasjon),
datafila, modellen i `Fargemodell`, fargesirkelen i `Fargesirkel` med `trinn`/`avrundet` og den trinnvise
sirkeltegningen i `HarmoniSeksjon`, valør/kroma-gliderne i harmonien, trinnene i `FargeEditor`, notasjonen i
`Fargetolk`, feltet `mu` i `DeltFarge`, metoden i `Metode`, valget i `FargemodellAppEnum`, testene og raden for modellen
på visningssiden (`web/<versjon>/l/vis.js`). Et skjermbilde og tekstene på nettsiden (arkitektur, funksjoner, støtte,
metoder) ble endret i samme commit.

## Før den føres tilbake

1. **Nøytralt navn.** Ikke varemerket som navn på modell, sirkel, notasjon eller funksjon, men for eksempel «Kulør ·
   valør · kroma» eller «HVC». Varemerket kan eventuelt stå i kildehenvisningen, med merknad om at det tilhører
   rettighetshaveren og at Kolorist ikke er tilknyttet.
2. **Bare de målte dataene.** Table I i Newhall, Nickerson & Judd, JOSA 33(7), 385–418 (1943), og Judd & Wyszecki,
   JOSA 46(4), 281–284 (1956). Ifølge The Online Books Page er ingen av heftene fornyet, og de er derfor allemannseie i
   USA. Kontroller tallene mot et skann av artiklene, ikke bare mot RITs `real.dat`.
3. **Egen ekstrapolasjon eller ingen.** Utenfor de målte dataene: lag en egen ekstrapolasjon (dokumentert) eller la
   fargene være uten notasjon. Ikke bruk RITs `all.dat` eller andres ekstrapolerte filer uten lisens.
4. **Lisensvurder på nytt** og oppdater `Pakker/FargeKjerne/DATALISENSER.md`.
