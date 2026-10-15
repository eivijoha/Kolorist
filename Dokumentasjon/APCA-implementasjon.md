# APCA in Kolorist – implementation for review

Kolorist (iOS, iPadOS and macOS) uses APCA – the Accessible Perceptual Contrast Algorithm by Andrew Somers / Myndex
Research – with permission from the copyright holder. This note describes the implementation so it can be reviewed.
APCA™ is a trademark of Myndex.

## Version and update policy

- **Algorithm:** APCA base 0.0.98G-4g with the output clamp at approximately ±Lc 10, as in apca-w3 0.1.9. The constants
  are used unchanged.
- **Updates:** we keep the implementation in step with the current available version of APCA and update it regularly
  when a new version is published. The version is stated in the code (`APCA.versjon`) and in the app's methods and
  sources.

## Files to share

The complete implementation is in one folder in the app, `Kolorist/APCA/`:

| File | Content |
|---|---|
| `APCA.swift` | The algorithm: constants, screen luminance (`y`), Lc (`lc`), and the reference values from apca-w3 |
| `APCA+Kolorist.swift` | How Kolorist uses APCA: Lc for colours, «Fix» (lightness to a target Lc), guidance levels, and the connection that chooses text colours on colour fields |

APCA is not part of FargeKjerne (Kolorist's colour package); the package only has a neutral hook (`Tekstvalg`) that the
app connects APCA to at launch.

## How it is calculated

1. Colours are gamut-mapped to sRGB (CSS Color 4), and a translucent text colour is composited on the background.
2. Screen luminance: each sRGB channel 0 … 1 raised to 2.4, weighted 0.2126729 / 0.7151522 / 0.0721750 (as `sRGBtoY`).
3. Soft clamp near black (threshold 0.022, exponent 1.414); |ΔY| below 0.0005 gives 0.
4. Normal polarity (dark text on light): (Ybg^0.56 − Ytxt^0.57) × 1.14; reverse: (Ybg^0.65 − Ytxt^0.62) × 1.14.
5. Output clamp: |SAPC| below 0.1 gives 0; otherwise the offset 0.027 is removed and the result is scaled by 100.

## Reference values

`APCA.kontroller()` reproduces these values from the apca-w3 documentation to within 1e-9, and is asserted every time a
debug build starts:

| Text | Background | Lc |
|---|---|---|
| #888888 | #FFFFFF | 63.056469930209424 |
| #FFFFFF | #888888 | −68.54146436644962 |
| #000000 | #AAAAAA | 58.146262578561334 |
| #AAAAAA | #000000 | −56.24113336839742 |
| #112233 | #DDEEFF | 91.66830811481631 |
| #DDEEFF | #112233 | −93.06770049484275 |

## Where Kolorist uses APCA

- **Contrast check** (Assess › Contrast › APCA): Lc for the colour as text on the background, the guidance levels
  (Lc 90, 75, 60, 45, 30, 15) and «Fix», which changes only the lightness (OKLCH) until a level is reached.
- **Text and icons on colour fields:** black or white, whichever has the higher |Lc|. Where a requirement applies
  (button text in the design system), WCAG 2 remains the floor.
- **Design system and tone scales:** Lc is shown next to the WCAG 2 ratio.
- **Reports:** the contrast report can include Lc and the levels.

Kolorist says that accessibility regulations refer to WCAG 2, and presents APCA as a supplement. APCA is credited in
the app (Methods and sources) and on kolorist.no, with a link to https://github.com/Myndex/apca-w3.
