# App Store Connect – Kolorist 1.5

Under arbeid på grenen `versjon-1.5` (laget fra `versjon-1.4` 2026-10-16, etter at 1.4 ble lastet opp). Tekstene fylles
ut etter hvert som 1.5 tar form; App-informasjon, URL-er, personvern, nøkkelord og skjermbilder er som i 1.4
(`Dokumentasjon/1.4/AppStore.md`).

## Nytt i denne versjonen – utkast

Nyheter:

- **3D som roterer av seg selv:** trykk på modellen (eller knappen nede til høyre) for en rolig rotasjon rundt den grå
  aksen; mens du drar eller knipser, står den stille, og den fortsetter når du slipper. «Se i AR» og 3D-modellen på Mac roterer da også; «Del som 3D-modell» står stille.
  Av når «Reduser bevegelse» er slått på. Flatene i 3D er også litt mer dekkende, så fargene står tydeligere frem.

Norsk:

```
• 3D-modellen kan rotere av seg selv: trykk på den for å starte eller stoppe – også i AR.
```

English:

```
• The 3D model can rotate on its own: tap it to start or stop – in AR too.
```


Feilrettinger (nevnes i «Nytt i denne versjonen», ikke som nyhet på nettsiden):

- **Tilpasningsmetode i trykkprofiler:** perseptuell og metning ble også brukt på veien tilbake fra profilen, så fargene
  havnet på overflaten av profilens perseptuelle referanserom. Nå regnes de tilbake kolorimetrisk – det trykket faktisk
  gir: i 3D (skallet og pilene), i «Vis som» i Studio og i paletter. Med perseptuell havner farger utenfor da inne i
  skallet, og farger innenfor flyttes litt. Matriseprofiler (sRGB, Display P3, Adobe RGB, Rec. 2020, ProPhoto) har ingen
  egne perseptuelle tabeller og er uendret; Generisk CMYK har like tabeller for alle metodene.

Norsk:

```
• Rettet: med perseptuell tilpasning i en trykkprofil viser 3D og «Vis som» nå fargen slik den faktisk blir på trykk.
```

English:

```
• Fixed: with perceptual rendering in a print profile, 3D and “Show as” now show the colour as it will actually print.
```

- **Tonebane og monokrom:** et endepunkt helt ute i kanten av flaten for lyshet og metning ble klippet (særlig det
  merkede, som er større); tonene ved omrisset av fargekula likeså. Nå tegnes de helt (`92e7f99`).

Norsk:

```
• Rettet: endepunktene i tonebaner og monokrome harmonier vises helt, også ute i kanten av flaten for lyshet og metning.
```

English:

```
• Fixed: the end points of tone paths and monochromatic harmonies are shown in full, even at the edge of the lightness and saturation field.
```
