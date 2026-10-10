# APCA – tatt ut 2026-10-10, og hvordan det kan føres tilbake

APCA (Accessible Perceptual Contrast Algorithm, Myndex/Andrew Somers, 0.0.98G-4g) ble fjernet fra Kolorist og
FargeKjerne 2026-10-10 fordi lisensen bare gjelder nettinnhold under W3C-avtalen og kommersiell bruk krever egen
skriftlig avtale med Myndex. Lisensen: https://github.com/Myndex/apca-w3/blob/master/LICENSE.md (kodeendring, revisjon på
forespørsel, bruk av navnet bare for korrekt og oppdatert implementering, logo bare med samtykke).

## Siste versjon med APCA

- Git-merket **`apca-siste`** (= `versjon-1.3`, Kolorist 1.3 slik den ble sendt inn) har hele implementeringen.

## Endringene som tok det ut (kan reverseres)

- `76c1566` – app og FargeKjerne (versjon 1.3.1)
- `e8a7cb2` – nettsiden 1.3 (og `fjern_apca.py`), `deb28be` – nettsiden 1.4

`git revert 76c1566` gir tilbake: `Farge.apcaKontrast(tekst:)` og `apcaLuminans` (Kontrast.swift), `Farge.medAPCA(mot:minst:)`
(Justering.swift), `Komponentsjekk.lc`, APCA som tiebreak i `Skriftfarger.beste`, `lesbarTekstfarge` etter APCA,
`APCANivå`/`APCASeksjon` og `Kontrasttype.apca` (KontrastVisninger.swift), Lc i designsystemet og toneskalaen,
`Metode.apca`, testene (`FargeromTests.apca`/`apcaRettOpp`) og `apcaLc` i testvektorene.

## Før det føres tilbake

- Skriftlig, signert kommersiell avtale med Myndex som dekker app (ikke bare nettinnhold), iOS og macOS.
- Implementeringen må følge gjeldende APCA-versjon og konstanter (sjekk apca-w3 for endringer siden 0.0.98G-4g,
  bl.a. klemming ved ±Lc 10 i 0.1.9), og avtalen avgjør om navnet «APCA» kan brukes i appen og på nettsiden.

## Intern bruk og avtale (2026-10-10)

Lisensen gjelder også intern bruk: å velge tekstfarge med APCA i appens eget grensesnitt er ikke nettinnhold, og
kommersiell bruk krever skriftlig avtale uansett om navnet vises. Eivind tar kontakt med Myndex om en avtale. Den bør dekke:

- Native apper (iOS, iPadOS, macOS) distribuert gjennom App Store, både som synlig kontrastsjekk og intern bruk
  (tekstfarge, skriftfarger, designsystem).
- FargeKjerne som pakke, også brukt av Kolorist underviser og Kolorist student (web).
- Patentlisens for metoden, ikke bare opphavsrett til koden.
- Bruk av navnet «APCA» i appen, på nettsiden og i App Store-tekstene, og eventuelt logoen.
- Versjonskrav (hvilken algoritmeversjon og konstanter, og plikten til å holde den oppdatert), revisjonsretten, vederlag,
  varighet og oppsigelse.
