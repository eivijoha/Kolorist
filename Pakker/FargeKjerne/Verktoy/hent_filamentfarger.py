#!/usr/bin/env python3
"""Henter filamentfarger fra FilamentColors.xyz (CC BY 4.0) til Kolorists innebygde fargebiblioteker.

    python3 Pakker/FargeKjerne/Verktoy/hent_filamentfarger.py

Skriver Sources/FargeKjerne/Filamentfarger.json. Kjøres ved behov før en ny versjon, og resultatet sjekkes inn,
så appen aldri henter noe fra nettet selv.

Hva som tas med og hva som endres (oppgis også i appen under Metoder og kilder):
- Per prøve: id (til lenken https://filamentcolors.xyz/swatch/<id>/), produsent, fargenavn, materiale,
  materialgruppe, CIELab (D65, 10°-observatør, målt med kolorimeter) og TD der det finnes.
- Prøver uten målt Lab (eldre prøver der fargen kommer fra et fotografi) tas med med hex og merkes som anslått.
- Ikke med: bilder, kjøpslenker, fargeforslag og koblinger til rettighetsbelagte fargesystemer.
Målebetingelsene står i kildekoden til FilamentColors.xyz (filamentcolors/constants.py: ILLUMINANT = "d65",
OBSERVER_ANGLE = "10").
"""
import datetime
import json
import pathlib
import subprocess
import time

API = "https://filamentcolors.xyz/api/swatch/?format=json&page_size=100&page={}"
UT = pathlib.Path(__file__).resolve().parent.parent / "Sources" / "FargeKjerne" / "Filamentfarger.json"


def hent(side):
    # curl: API-et avviser Pythons standard-klient.
    svar = subprocess.run(["curl", "-sf", "--max-time", "60", "-A", "Kolorist (+https://kolorist.no)", API.format(side)],
                          check=True, capture_output=True)
    return json.loads(svar.stdout)


def main():
    prøver, side = [], 1
    while True:
        data = hent(side)
        prøver += data["results"]
        if not data.get("next"):
            break
        side += 1
        time.sleep(1)  # vennlig mot tjenesten

    ut = []
    for s in sorted(prøver, key=lambda s: s["id"]):
        if not s.get("published", True):
            continue
        type_ = s.get("filament_type") or {}
        post = {
            "id": s["id"],
            "p": s["manufacturer"]["name"].strip(),
            "n": s["color_name"].strip(),
            "m": (type_.get("name") or "").strip(),
            "g": ((type_.get("parent_type") or {}).get("name") or "").strip(),
        }
        if s.get("lab_l") is not None:
            post["lab"] = [round(s["lab_l"], 2), round(s["lab_a"], 2), round(s["lab_b"], 2)]
        elif s.get("hex_color"):
            post["hex"] = s["hex_color"].upper()
        else:
            continue
        if s.get("td") is not None:
            post["td"] = s["td"]
        ut.append(post)

    resultat = {
        "kilde": "FilamentColors.xyz",
        "kildelenke": "https://filamentcolors.xyz/",
        "lisens": "CC BY 4.0",
        "lisenslenke": "https://creativecommons.org/licenses/by/4.0/",
        "hentet": datetime.date.today().isoformat(),
        "lab": "CIELab, D65, 10°-observatør (kolorimeter)",
        "endringer": "Utvalg av felt; prøver uten målt Lab har hex fra foto og er merket som anslått. "
                     "Bilder, kjøpslenker og koblinger til rettighetsbelagte fargesystemer er utelatt.",
        "prøver": ut,
    }
    UT.write_text(json.dumps(resultat, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    målt = sum(1 for p in ut if "lab" in p)
    print(f"{len(ut)} prøver ({målt} målt, {len(ut) - målt} anslått) → {UT}")


if __name__ == "__main__":
    main()
