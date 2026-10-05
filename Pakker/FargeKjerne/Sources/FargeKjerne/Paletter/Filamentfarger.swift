import Foundation

/// Innebygde fargebiblioteker med filamentfarger for 3D-print, fra FilamentColors.xyz (CC BY 4.0).
///
/// Fargene er målt på utskrevne prøver med kolorimeter og oppgitt som CIELab under D65 med 10°-observatør
/// (`filamentcolors/constants.py` i kildekoden til FilamentColors.xyz). Kolorist regner om til sitt eget fargerom:
/// Lab → XYZ med D65-hvitpunktet for 10°, Bradford-tilpasning til D65-hvitpunktet for 2° (observatørforskjellen kan
/// ikke regnes om nøyaktig uten spektre, men avviket er lite), og videre som andre farger. Prøver uten målt Lab har
/// hex fra et fotografi og merkes som anslått. Uttrekket lages med `Verktoy/hent_filamentfarger.py` og følger med
/// appen; appen henter ingenting fra nettet. Hver tone lenker til prøven hos FilamentColors.xyz.
public enum Filamentfarger {
    /// Opplysningene om uttrekket (kilde, lisens, dato, endringer).
    public struct Om: Sendable {
        public let kilde: String
        public let kildelenke: URL?
        public let lisens: String
        public let lisenslenke: URL?
        public let hentet: String
        public let antall: Int
        public let målt: Int
    }

    struct Fil: Decodable {
        let kilde: String
        let kildelenke: String
        let lisens: String
        let lisenslenke: String
        let hentet: String
        let prøver: [Prøve]
    }

    struct Prøve: Decodable {
        let id: Int
        let p: String
        let n: String
        let m: String
        let g: String
        let lab: [Double]?
        let hex: String?
        let td: Double?
    }

    /// Materialgruppene som egne bibliotek, i fast rekkefølge (nærmeste tone søkes innen samme materiale).
    static let grupper: [(nøkkel: String, id: String)] = [
        ("PLA", "pla"), ("PETG", "petg"), ("ABS / ASA", "abs-asa"), ("TPU / TPE", "tpu-tpe"), ("Exotics", "andre"),
    ]

    static func gruppenavn(_ id: String) -> String {
        switch id {
        case "alle": String(localized: "Filament: alle typer", bundle: .module)
        case "pla": String(localized: "Filament: PLA", bundle: .module)
        case "petg": String(localized: "Filament: PETG", bundle: .module)
        case "abs-asa": String(localized: "Filament: ABS og ASA", bundle: .module)
        case "tpu-tpe": String(localized: "Filament: TPU og TPE", bundle: .module)
        default: String(localized: "Filament: andre materialer", bundle: .module)
        }
    }

    private static let innhold: (biblioteker: [Fargebibliotek], om: Om?) = last()

    /// «Alle typer» (beste treff uansett materiale) først, så ett bibliotek per materialgruppe.
    public static var biblioteker: [Fargebibliotek] { innhold.biblioteker }
    public static var om: Om? { innhold.om }

    static func last() -> ([Fargebibliotek], Om?) {
        guard let url = Bundle.module.url(forResource: "Filamentfarger", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let fil = try? JSONDecoder().decode(Fil.self, from: data) else { return ([], nil) }
        let kjente = Set(grupper.map(\.nøkkel))
        var perGruppe: [String: [PalettFarge]] = [:]
        for p in fil.prøver {
            guard let farge = farge(p) else { continue }
            let gruppe = grupper.first { $0.nøkkel == p.g }?.id ?? (kjente.contains(p.g) ? p.g : "andre")
            let kilde = Fargekilde(produsent: p.p, navn: p.n, materiale: p.m,
                                   lenke: URL(string: "https://filamentcolors.xyz/swatch/\(p.id)/"),
                                   målt: p.lab != nil, td: p.td, kildenavn: fil.kilde)
            perGruppe[gruppe, default: []].append(PalettFarge(navn: "\(p.p) \(p.n) (\(p.m))", farge: farge,
                                                              opphav: .bibliotek, kilde: kilde))
        }
        let sortert = { (farger: [PalettFarge]) in farger.sorted { $0.navn.localizedStandardCompare($1.navn) == .orderedAscending } }
        let perMateriale = grupper.compactMap { g -> Fargebibliotek? in
            guard let farger = perGruppe[g.id], !farger.isEmpty else { return nil }
            return Fargebibliotek(id: "bib:filament-\(g.id)", navn: gruppenavn(g.id), farger: sortert(farger))
        }
        // Alle typer: nærmeste filament uansett materiale.
        let alle = Fargebibliotek(id: "bib:filament-alle", navn: gruppenavn("alle"), farger: sortert(perGruppe.values.flatMap { $0 }))
        let biblioteker = alle.farger.isEmpty ? perMateriale : [alle] + perMateriale
        let om = Om(kilde: fil.kilde, kildelenke: URL(string: fil.kildelenke), lisens: fil.lisens,
                    lisenslenke: URL(string: fil.lisenslenke), hentet: fil.hentet, antall: fil.prøver.count,
                    målt: fil.prøver.filter { $0.lab != nil }.count)
        return (biblioteker, om)
    }

    static func farge(_ p: Prøve) -> Farge? {
        if let lab = p.lab, lab.count == 3 { return farge(labD65_10: CIELab(l: lab[0], a: lab[1], b: lab[2])) }
        return p.hex.flatMap { Farge(hex: "#" + $0) }
    }

    /// D65-hvitpunktet for 10°-observatøren (CIE 1964), normert til Y = 1.
    static let hvitD65_10 = Vektor3(0.94811, 1, 1.07304)
    static let fra10Til2 = Matriser.bradford(fra: hvitD65_10, til: Matriser.hvitD65)

    /// Farge fra CIELab målt under D65 med 10°-observatør.
    static func farge(labD65_10 lab: CIELab) -> Farge {
        let hvit = XYZ(x: hvitD65_10.x, y: hvitD65_10.y, z: hvitD65_10.z)
        let x = Labregning.xyz(lab, hvit: hvit)
        let tilpasset = fra10Til2 * Vektor3(x.x, x.y, x.z)
        return Farge(xyz: XYZ(x: tilpasset.x, y: tilpasset.y, z: tilpasset.z))
    }
}
