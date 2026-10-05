# Ønsker fra Kolorist utdanning

Bestillinger fra arbeidet med Kolorist utdanning (repo `~/App-utvikling/Kolorist utdanning`,
[github.com/eivijoha/Kolorist-utdanning](https://github.com/eivijoha/Kolorist-utdanning)): Kolorist lærer (Mac/iPad,
forelesning på prosjektør) og Kolorist student (web i Canvas). Ønskene er forslag – prioritet avklares med Eivind før de
bygges i Kolorist.

Status: **ny** · avklart · i arbeid · ferdig · avslått. Svar og leveranser står i `Svar fra Kolorist.md` (skrives bare av
Kolorist); denne fila skrives bare av Kolorist utdanning. Ved levert sjekker utdanning og setter status **ferdig** her.

**Forslag til rekkefølge (fra utdanning, Eivind avgjør):** 3 testvektorer (liten, låser opp web-modellene) → 2a eget repo
for FargeKjerne (låser opp deling uten lokal sti) → 1 visningstilstand og presentasjonsmodus → 2b `KoloristVisninger` → 4.

## 1. «Åpne i Kolorist» med visningstilstand og presentasjonsmodus — ny (2026-10-05) · svar mottatt, venter på prioritering

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

## 2. Delte Swift-pakker og `KoloristVisninger` — ny (2026-10-05) · svar mottatt: alternativ (a) eget repo passer oss, etter at 1.3 er stabil

Kolorist utdanning bruker FargeKjerne og FargeMaaling via lokal sti (`../../Kolorist/Pakker/FargeKjerne`). Det virker på
Eivinds Mac, men ikke for andre eller i CI.

**Ønske:**
- FargeKjerne/FargeMaaling (og eventuelt FargeKI) som egen pakke i roten av et eget repo (Swift Package Manager krever
  det for avhengigheter over git), eller en annen stabil måte å dele dem på.
- På sikt: utvalgte Kolorist-visninger trukket ut i en pakke `KoloristVisninger` (Studio-flaten, harmonisirkelen, den
  monokrome flaten, kontrastmatrisen, fargesyn), så lærer-appen kan bygge dem inn i lysbilder.

## 3. Testvektorer for web — ny (2026-10-05) · svar mottatt, foreslått som neste leveranse – gjerne

Kolorist student (web) skal regne likt med Kolorist (TypeScript). `Testlenker.json` finnes for delingslenker.

**Ønske:** en fil med testvektorer for fargeregningen (sRGB ↔ lineær, OKLab/OKLCH, CIELab D50, ΔE00, gamut-kartlegging
etter CSS Color 4, WCAG/APCA-kontrast, LRV) som web-koden kan testes mot.

## 4. Innleveringsark — ny (2026-10-05) · svar mottatt, venter

Se idébanken (`Dokumentasjon/1.2/Idebank.md`, «Innleveringsark for undervisning og vurdering»): PDF av palett/gruppe med
verdier, kontrast, delingslenke/QR og plass til begrunnelse, uten navn i metadata. Lav prioritet nå (vurdering tas i en
senere runde).
