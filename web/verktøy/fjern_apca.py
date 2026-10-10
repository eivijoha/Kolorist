#!/usr/bin/env python3
"""Fjerner alle omtaler av APCA fra nettsidene og kildene deres (2026-10-10: APCA er lisensbelagt og tas ut av Kolorist).

    python3 web/verktøy/fjern_apca.py <fil eller mappe> …
"""
import pathlib, re, sys

ERSTATT = [
    # Norsk
    ('WCAG 2.2, APCA eller LRV', 'WCAG 2.2 eller LRV'), ('WCAG, APCA eller LRV', 'WCAG eller LRV'),
    ('WCAG, APCA og LRV', 'WCAG og LRV'), ('WCAG 2.2, APCA og standardene', 'WCAG 2.2 og standardene'),
    ('Tekst og grafikk (WCAG 2.2 og APCA)', 'Tekst og grafikk (WCAG 2.2)'),
    ('– også etter APCA og LRV', '– også etter LRV'), ('WCAG, APCA, LRV,', 'WCAG, LRV,'),
    ('simulering av fargesynsavvik, APCA, LRV', 'simulering av fargesynsavvik, LRV'),
    ('WCAG, APCA og LRV', 'WCAG og LRV'),
    # Engelsk
    ('WCAG 2.2, APCA or LRV', 'WCAG 2.2 or LRV'), ('WCAG, APCA or LRV', 'WCAG or LRV'),
    ('WCAG, APCA and LRV', 'WCAG and LRV'), ('WCAG 2.2, APCA and the standards', 'WCAG 2.2 and the standards'),
    ('Text and graphics (WCAG 2.2 and APCA)', 'Text and graphics (WCAG 2.2)'),
    ('– also by APCA and LRV', '– also by LRV'), ('WCAG, APCA, LRV,', 'WCAG, LRV,'),
    ('WCAG 2.2, APCA, LRV', 'WCAG 2.2, LRV'),
]
# Hele listepunkter og avsnitt som bare handler om APCA (i HTML og i Python-kildene).
FJERN = [
    r'[ \t]*<li>Tekst på fargeflater i sort eller hvit etter opplevd lesbarhet \(APCA\)[^\n]*</li>\n',
    r'[ \t]*<li>Lesekontrast etter APCA \(Lc\)[^\n]*</li>\n',
    r'[ \t]*<li>Text on colour fields in black or white by perceived legibility \(APCA\)[^\n]*</li>\n',
    r'[ \t]*<li>Reading contrast by APCA \(Lc\)[^\n]*</li>\n',
    r"[ \t]*'Tekst på fargeflater i sort eller hvit etter opplevd lesbarhet \(APCA\)[^\n]*\n",
    r"[ \t]*'Lesekontrast etter APCA \(Lc\)[^\n]*\n",
    r"[ \t]*'Text on colour fields in black or white by perceived legibility \(APCA\)[^\n]*\n",
    r"[ \t]*'Reading contrast by APCA \(Lc\)[^\n]*\n",
    # Metodesiden: hele APCA-avsnittet fram til neste overskrift.
    r'[ \t]*<h2 id="apca">.*?(?=[ \t]*<h2 )',
]

def rens(tekst: str) -> str:
    for o, n in ERSTATT:
        tekst = tekst.replace(o, n)
    for mønster in FJERN:
        tekst = re.sub(mønster, '', tekst, flags=re.S)
    return tekst

for arg in sys.argv[1:]:
    sti = pathlib.Path(arg)
    filer = [sti] if sti.is_file() else [f for f in sti.rglob('*') if f.suffix in ('.html', '.py', '.js')]
    for f in filer:
        if f.name == 'fjern_apca.py':
            continue
        gammel = f.read_text()
        ny = rens(gammel)
        if ny != gammel:
            f.write_text(ny)
            print('renset', f)
