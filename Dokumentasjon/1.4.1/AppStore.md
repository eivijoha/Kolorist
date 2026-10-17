# App Store Connect – Kolorist 1.4.1

Feilrettingsversjon på grenen `versjon-1.4` (MARKETING_VERSION 1.4.1), etter 1.4. Bare «Nytt i denne versjonen» endres;
alt annet (tekster, nøkkelord, skjermbilder, header, App Review-notat) er som i 1.4 (`Dokumentasjon/1.4/AppStore.md`) –
uten iPhone Duo i tekstene til den er sluppet (23. oktober).

Rettingene er også i 1.5 (`versjon-1.5`).

## Rettinger

- **Tonebane og monokrom** (`92e7f99`): et endepunkt helt ute i kanten av flaten for lyshet og metning ble klippet
  (særlig det merkede, som er større); tonene ved omrisset av fargekula likeså. Nå tegnes de helt.
- **Tilpasningsmetode i trykkprofiler** (fra `25c0932` på 1.5): perseptuell og metning ble også brukt på veien tilbake
  fra profilen, så fargene havnet på overflaten av profilens perseptuelle referanserom. Nå regnes de tilbake
  kolorimetrisk – det trykket faktisk gir – i 3D (skallet og pilene), i «Vis som» i Studio og i paletter. Med
  perseptuell havner farger utenfor da inne i skallet, og farger innenfor flyttes litt. Matriseprofiler (sRGB,
  Display P3, Adobe RGB, Rec. 2020, ProPhoto) har ingen egne perseptuelle tabeller og er uendret.
- **Flater som forsvant i AR** (fra `36a3081` på 1.5): AR Quick Look ser bort fra at flatene er tosidige og skjulte
  baksidene, så sider av et gamutskall kunne forsvinne; heldekkende flater ble også behandlet som gjennomsiktige. Nå
  skrives hver trekant i begge retninger, og heldekkende materialer får ingen opasitet.
- **Papirhvitt bak 3D-modellen** (fra `4ac6321` på 1.5): med absolutt kolorimetrisk står modellen mot profilens
  hvitpunkt (papirets farge) på skjermen, med en linje som forklarer det. 3D-modellen (USDZ) og AR er uendret.

## Nytt i denne versjonen (iOS og Mac)

Norsk:

```
Kolorist 1.4.1 retter tre feil og viser papirhvitt i 3D:

• Med perseptuell tilpasning i en trykkprofil viser 3D og «Vis som» nå fargen slik den faktisk blir på trykk – farger utenfor havner inne i fargerommet, ikke bare på overflaten.
• I AR vises alle flatene i 3D-modellen, også sidene av et fargerom sett bakfra.
• Endepunktene i tonebaner og monokrome harmonier vises helt, også ute i kanten av flaten for lyshet og metning.
• Med absolutt kolorimetrisk står 3D-modellen mot papirhvitt – profilens hvitpunkt – så fargene ses mot underlaget de trykkes på.
```

English:

```
Kolorist 1.4.1 fixes three issues and shows paper white in 3D:

• With perceptual rendering in a print profile, 3D and “Show as” now show the colour as it will actually print – colours outside end up inside the colour space, not just on its surface.
• In AR, every surface of the 3D model is shown, including the sides of a colour space seen from behind.
• The end points of tone paths and monochromatic harmonies are shown in full, even at the edge of the lightness and saturation field.
• With absolute colorimetric, the 3D model sits against paper white – the profile’s white point – so you see the colours against the stock they are printed on.
```

## Før du sender inn

- [ ] 1.4 godkjent og ute.
- [ ] Ny versjon 1.4.1 opprettet for iOS og macOS, med teksten over.
- [ ] `CURRENT_PROJECT_VERSION` økt for opplastingen.
- [ ] FargeKjerne: rettingen av `gamutskall` (kolorimetrisk tilbake) står under «Ikke publisert» i CHANGELOG – publiseres
  sammen med neste versjon av pakken.
