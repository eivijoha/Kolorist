# Ønsker fra Kolorist utdanning

Bestillinger fra arbeidet med Kolorist utdanning (repo `~/App-utvikling/Kolorist utdanning`,
[github.com/eivijoha/Kolorist-utdanning](https://github.com/eivijoha/Kolorist-utdanning)): Kolorist lærer (Mac/iPad,
forelesning på prosjektør) og Kolorist student (web i Canvas). Ønskene er forslag – prioritet avklares med Eivind før de
bygges i Kolorist.

Status: **ny** · avklart · i arbeid · ferdig · avslått · trukket · utsatt. Svar og leveranser står i `Svar fra Kolorist.md` (skrives bare av
Kolorist); denne fila skrives bare av Kolorist utdanning. Ved levert sjekker utdanning og setter status **ferdig** her.

## Melding til Kolorist (2026-10-05)

Eivind har bestemt, etter svarene i `Svar fra Kolorist.md`:

- **Ønske 3 (testvektorer)** – avklart, gjerne som neste leveranse.
- **Ønske 2a (FargeKjerne/FargeMaaling i eget repo)** – avklart, når 1.3 er stabil.
- **Ønske 1 («Åpne i Kolorist» med visningstilstand og presentasjonsmodus)** – avklart, skal gjennomføres.
- **Ønske 2b (`KoloristVisninger`)** – trukket. Kolorist skal ikke omstruktureres for utdanning på bekostning av kvalitet
  eller videre utvikling for iOS, iPadOS og macOS. Utdanning bygger sitt eget visningslag på pakkene, med Kolorist som
  forbilde. Gi gjerne beskjed i svarfila når API-et i pakkene endres.
- **Ønske 4 (innleveringsark)** – utsatt til vurdering tas opp.

**Rekkefølge (Eivind, 2026-10-05):** 3 testvektorer → 2a eget repo for FargeKjerne → 1 visningstilstand og
presentasjonsmodus. 2b `KoloristVisninger` er trukket (utdanning bygger eget visningslag), 4 er utsatt.

## 1. «Åpne i Kolorist» med visningstilstand og presentasjonsmodus — **avklart** (Eivind 2026-10-05: skal gjennomføres)

Kolorist lærer har knappen «Åpne i Kolorist» på lysbilder med modeller. I dag sendes en vanlig delingslenke
(`kolorist://l#z…` med en farge eller palett), som Kolorist viser i et ark.

**Ønske:**
- Lenken kan også bære **visningstilstand**: hvilket verktøy og modus som skal åpnes (Studio med fargemodell, Harmoni
  med valgt harmoni og fargesirkel, monokrom flate, Kontrast, Fargesyn, Lys med betraktningsforhold), og fargen eller
  paletten som arbeidsgrunnlag – ikke bare ark med «lagre».
- En **presentasjonsmodus** i Kolorist (Mac og iPad): større skrift og kontroller, færre forstyrrende elementer, egnet for
  prosjektør. Kan slås på fra lenken (`…&presentasjon=1`) eller fra menyen.
- Gjerne som App Intents også (Snarveier), så det kan styres uten lenke.

**Hvorfor:** læreren demonstrerer arbeidsflyten i Kolorist midt i forelesningen, i samme tilstand som lysbildet viser.

## 2. Delte Swift-pakker og `KoloristVisninger` — (a) eget repo: **avklart** (Eivind ok 2026-10-05, etter at 1.3 er stabil) · `KoloristVisninger`: **trukket**

Kolorist utdanning bruker FargeKjerne og FargeMaaling via lokal sti (`../../Kolorist/Pakker/FargeKjerne`). Det virker på
Eivinds Mac, men ikke for andre eller i CI.

**Ønske:**
- FargeKjerne/FargeMaaling (og eventuelt FargeKI) som egen pakke i roten av et eget repo (Swift Package Manager krever
  det for avhengigheter over git), eller en annen stabil måte å dele dem på.
- ~~På sikt: utvalgte Kolorist-visninger trukket ut i en pakke `KoloristVisninger`~~ – **trukket 2026-10-05.** Eivind vil
  ikke at Kolorist skal omstruktureres på bekostning av kvalitet eller videre utvikling for iOS, iPadOS og macOS. Kolorist
  utdanning bygger i stedet **sitt eget visningslag** på FargeKjerne/FargeMaaling, med Kolorist som forbilde for utseende
  og oppførsel. Det vi trenger fra Kolorist, er da bare at pakkene (2a) er stabile å bygge på – og gjerne et varsel i
  svarfila når noe i API-et endres.

## 3. Testvektorer for web — **avklart** (Eivind ok 2026-10-05, gjerne som neste leveranse)

Kolorist student (web) skal regne likt med Kolorist (TypeScript). `Testlenker.json` finnes for delingslenker.

**Ønske:** en fil med testvektorer for fargeregningen (sRGB ↔ lineær, OKLab/OKLCH, CIELab D50, ΔE00, gamut-kartlegging
etter CSS Color 4, WCAG/APCA-kontrast, LRV) som web-koden kan testes mot.

## 4. Innleveringsark — **utsatt** (Eivind 2026-10-05: tas senere, sammen med vurdering)

Se idébanken (`Dokumentasjon/1.2/Idebank.md`, «Innleveringsark for undervisning og vurdering»): PDF av palett/gruppe med
verdier, kontrast, delingslenke/QR og plass til begrunnelse, uten navn i metadata. Lav prioritet nå (vurdering tas i en
senere runde).
