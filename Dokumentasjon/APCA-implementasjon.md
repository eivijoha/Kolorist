# APCA in Kolorist – implementation for review

Kolorist uses APCA – the Accessible Perceptual Contrast Algorithm by Andrew Somers / Myndex Research – with permission
from the copyright holder. This document describes the implementation so it can be reviewed and verified. APCA™ is a
trademark of Myndex.

## Summary

| | |
|---|---|
| Product | Kolorist – colour palettes for designers |
| Platforms | iPhone (iOS 26), iPad (iPadOS 26) and Mac (macOS 26); one universal app |
| Developer | Eivind Arnstein Johansen, Department of Design, NTNU (Norwegian University of Science and Technology) |
| Contact | eivind.johansen@ntnu.no |
| Website | https://kolorist.no/en/ |
| App Store | https://apps.apple.com/app/id6818636272 |
| Methods and sources | https://kolorist.no/en/methods.html#apca (published with Kolorist 1.4) |
| APCA version | Base algorithm 0.0.98G-4g with the output clamp at about ±Lc 10, as in apca-w3 0.1.9 |
| Reference implementation | https://github.com/Myndex/apca-w3 (constants used unchanged) |
| Implemented | 15 October 2026 |
| First Kolorist version with APCA under the permission | 1.4 (build 15 or later) |
| Language | Swift 6.2, no third-party dependencies |
| Files | `Kolorist/APCA/APCA.swift` and `Kolorist/APCA/APCA+Kolorist.swift` (attached) |
| Document version | 1.0, 15 October 2026 |

## Update policy

We keep the implementation in step with the current available version of APCA and update it regularly:

- Before each Kolorist release, and otherwise at least every three months, we check apca-w3 for a new version.
- A new version is implemented in the next Kolorist release, the reference values are updated, and this document gets
  a new line in the change log below.
- The version is stated in the code (`APCA.versjon`), in the app (Methods and sources) and on the website.

## Files to share

The complete implementation is in one folder in the app, `Kolorist/APCA/`:

| File | Content |
|---|---|
| `APCA.swift` | The algorithm: constants, screen luminance (`y`), Lc (`lc`), and the reference values from apca-w3 |
| `APCA+Kolorist.swift` | How Kolorist uses APCA: Lc for colours, «Fix» (lightness to a target Lc), guidance levels, and the connection that chooses text colours on colour fields |

APCA is not part of FargeKjerne, Kolorist's colour package, which is shared with other apps. The package only has a
neutral hook (`Tekstvalg`) that the app connects APCA to at launch.

## How it is calculated

1. **Input colours.** Kolorist stores colours in linear extended sRGB and may use Display P3. Before APCA is calculated,
   both colours are gamut-mapped to sRGB (CSS Color 4 gamut mapping), so APCA gets the colour shown in sRGB. A
   translucent text colour is first composited on the background.
2. **Screen luminance.** Each sRGB channel 0 … 1 is raised to 2.4 and weighted 0.2126729 / 0.7151522 / 0.0721750, as
   `sRGBtoY` in apca-w3 (no linear segment).
3. **Soft clamp near black.** Threshold 0.022, exponent 1.414. |ΔY| below 0.0005 gives Lc 0.
4. **Polarity.** Normal (dark text on light): (Ybg^0.56 − Ytxt^0.57) × 1.14. Reverse (light text on dark):
   (Ybg^0.65 − Ytxt^0.62) × 1.14.
5. **Output.** |SAPC| below 0.1 gives 0; otherwise the offset 0.027 is removed and the result is multiplied by 100.

Colours are calculated in double precision and are not rounded to 8 bits, except where the input is a hex value.

## Reference values

`APCA.kontroller()` reproduces these values from the apca-w3 documentation to within 1e-9. It runs every time a debug
build of Kolorist starts, and the build stops if a value is not reproduced.

| Text | Background | Lc |
|---|---|---|
| #888888 | #FFFFFF | 63.056469930209424 |
| #FFFFFF | #888888 | −68.54146436644962 |
| #000000 | #AAAAAA | 58.146262578561334 |
| #AAAAAA | #000000 | −56.24113336839742 |
| #112233 | #DDEEFF | 91.66830811481631 |
| #DDEEFF | #112233 | −93.06770049484275 |

## Where Kolorist uses APCA

- **Contrast check** (Assess › Contrast › APCA): Lc for the colour as text on the background, with the polarity in words
  (dark text on a light background, or the reverse) and these guidance levels:

  | Level | Shown as |
  |---|---|
  | Lc 90 | Good enough for all text, including body text |
  | Lc 75 | Body text (minimum) |
  | Lc 60 | Larger text, not body text |
  | Lc 45 | Large or bold headings |
  | Lc 30 | Non-essential text, such as placeholders |
  | Lc 15 | Icons and graphics, not text |

  Lc is shown truncated towards zero («Lc 74» for 74.9), so a level is never shown as reached when it isn't.
- **Fix:** changes only the colour's lightness (OKLCH, in steps of 0.005) until |Lc| reaches the chosen level, in the
  direction that needs the smallest change. If the level can't be reached, the result is black or white, whichever gives
  the higher |Lc|.
- **Text and icons on colour fields** (colour values, names and the [+] button on colour fields throughout the app):
  black or white, whichever has the higher |Lc|. Where a requirement applies – button text in the design system –
  WCAG 2 (4.5:1) is the floor.
- **Text colours in palettes:** among the palette's text colours, the one with the highest |Lc|, with the same WCAG 2
  floor where a requirement applies.
- **Design system and tone scales:** Lc is shown next to the WCAG 2 ratio for each colour pair and each step.
- **Reports:** the contrast report (copy as table, share as link, print) can include Lc and the levels.

## How APCA is presented

- APCA is named «APCA» and credited in the app (Methods and sources) and on kolorist.no to Andrew Somers (Myndex
  Research), with the version, a link to apca-w3, and that it is used with permission.
- Kolorist says that accessibility regulations refer to WCAG 2 and presents APCA as a supplement to WCAG 2.2.
- The APCA logo and «Powered by APCA» are not used.

## Change log

| Date | Kolorist | APCA | Change |
|---|---|---|---|
| 15 October 2026 | 1.4 | 0.0.98G-4g (apca-w3 0.1.9) | Implemented under the permission |
