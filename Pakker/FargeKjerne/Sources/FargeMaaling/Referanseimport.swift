import FargeKjerne
import Foundation

/// Leser referanseverdier for et kort fra så mange formater som mulig: CGATS (.txt, .cgats, .it8, .ti1/.ti3),
/// CxF3 (.cxf), CSV/TSV med eller uten overskrifter, en ren tallmatrise (Lab, XYZ eller spektre i rader eller
/// kolonner), og fargebiblioteker (ASE, ACO, ACB) som Lab-verdier.
public enum Referanseimport {
    public enum Feil: LocalizedError, Equatable {
        case ukjentFormat
        case ingenFelt

        public var errorDescription: String? {
            switch self {
            case .ukjentFormat: String(localized: "Fant ingen referanseverdier i filen.", bundle: .module)
            case .ingenFelt: String(localized: "Filen har ingen felt med verdier.", bundle: .module)
            }
        }
    }

    public static func les(_ data: Data, filnavn: String) throws -> Referansekort {
        let navn = (filnavn as NSString).deletingPathExtension
        let felt: [Referansefelt]
        var treKolonnerSkala: Double?
        if Bibliotekimport.endelse(for: data) != nil {
            let palett = try Bibliotekimport.les(data, filnavn: filnavn)
            felt = palett.farger.map { Referansefelt(navn: $0.navn, verdi: .lab($0.farge.cieLab)) }
        } else if let tekst = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) {
            if tekst.contains("<") && (tekst.contains("CxF") || tekst.contains(":Object") || tekst.contains("<Object")) {
                felt = CxF.les(data)
            } else if tekst.contains("BEGIN_DATA") {
                felt = try CGATS.les(tekst)
            } else {
                (felt, treKolonnerSkala) = try Tabell.les(tekst)
            }
        } else {
            throw Feil.ukjentFormat
        }
        guard !felt.isEmpty else { throw Feil.ingenFelt }
        var kort = ordnet(felt, navn: navn, kilde: filnavn)
        kort.treKolonnerSkala = treKolonnerSkala
        return kort
    }

    // MARK: Rekkefølge og oppsett

    /// Rader × kolonner for et antall felt, liggende og så nær 2:3 som mulig (24 → 4 × 6).
    static func oppsett(for antall: Int) -> (rader: Int, kolonner: Int) {
        let kjente: [Int: (Int, Int)] = [24: (4, 6), 140: (10, 14), 96: (8, 12), 48: (6, 8), 288: (12, 24), 264: (12, 22)]
        if let k = kjente[antall] { return k }
        var best = (1, antall)
        var bestAvvik = Double.infinity
        for r in 1...max(1, Int(Double(antall).squareRoot())) where antall % r == 0 {
            let avvik = abs(log(Double(antall / r) / Double(r) / 1.5))
            if avvik < bestAvvik { bestAvvik = avvik; best = (r, antall / r) }
        }
        return best
    }

    /// Ordner feltene rad for rad. Filer fra måleinstrumenter er ofte kolonne for kolonne; det kjennes igjen på at
    /// de nøytrale feltene da kommer med jevne mellomrom i stedet for samlet på én rad.
    static func ordnet(_ felt: [Referansefelt], navn: String, kilde: String?) -> Referansekort {
        let (rader, kolonner) = oppsett(for: felt.count)
        var ordnet = felt
        if rader > 1 && rader * kolonner == felt.count {
            let nøytral = felt.map { hypot($0.verdi.lab.a, $0.verdi.lab.b) < 6 }
            func andelPåEnRad(_ indeks: (Int, Int) -> Int) -> Int {
                (0..<rader).map { r in (0..<kolonner).filter { nøytral[indeks(r, $0)] }.count }.max() ?? 0
            }
            let radvis = andelPåEnRad { r, k in r * kolonner + k }
            let kolonnevis = andelPåEnRad { r, k in k * rader + r }
            if kolonnevis > radvis {
                ordnet = (0..<felt.count).map { i in felt[(i % kolonner) * rader + i / kolonner] }
            }
        }
        // Felt uten navn (eller bare løpenummer) får posisjonsnavn.
        for i in ordnet.indices where ordnet[i].navn.isEmpty || Int(ordnet[i].navn) != nil {
            ordnet[i].navn = Referansekort.posisjonsnavn(i, kolonner: kolonner)
        }
        return Referansekort(navn: navn, rader: rader, kolonner: kolonner, felt: ordnet, kilde: kilde)
    }

    // MARK: Kolonner

    /// Hva en kolonne inneholder, ut fra overskriften.
    enum Kolonne: Equatable {
        case navn, l, a, b, x, y, z, bølgelengde(Double), annet
    }

    static func kolonne(_ overskrift: String) -> Kolonne {
        let o = overskrift.trimmingCharacters(in: CharacterSet(charactersIn: "\"' ")).uppercased()
        switch o {
        case "SAMPLE_NAME", "NAME", "NAVN", "PATCH", "PATCH_NAME", "FELT", "SAMPLE", "ID", "SAMPLE_ID", "SAMPLEID": return .navn
        case "LAB_L", "L", "L*", "CIE L", "CIEL", "L_STAR": return .l
        case "LAB_A", "A", "A*", "CIE A", "CIEA", "A_STAR": return .a
        case "LAB_B", "B", "B*", "CIE B", "CIEB", "B_STAR": return .b
        case "XYZ_X", "X": return .x
        case "XYZ_Y", "Y": return .y
        case "XYZ_Z", "Z": return .z
        default: break
        }
        // SPECTRAL_NM380, SPECTRAL_380, SPEC_380, NM380, R380, 380, 380NM, 380 NM
        let siffer = o.filter(\.isNumber)
        if let nm = Double(siffer), (300...830).contains(nm) {
            let rest = o.filter { !$0.isNumber }.replacingOccurrences(of: " ", with: "")
            if ["", "NM", "SPECTRAL_NM", "SPECTRAL_", "SPEC_", "R", "R_", "NM_", "SPECTRAL"].contains(rest) {
                return .bølgelengde(nm)
            }
        }
        return .annet
    }

    /// Bygger felt fra rader med verdier og kolonnebeskrivelser. Spekter foretrekkes, så XYZ, så Lab.
    static func felt(rader: [[String]], kolonner: [Kolonne]) -> [Referansefelt] {
        let spektral = kolonner.enumerated().compactMap { i, k -> (Int, Double)? in
            if case .bølgelengde(let nm) = k { (i, nm) } else { nil }
        }.sorted { $0.1 < $1.1 }
        func indeks(_ k: Kolonne) -> Int? { kolonner.firstIndex(of: k) }
        let navnIndeks = kolonner.lastIndex(of: .navn)
        let tall = rader.map { $0.map { Double($0.replacingOccurrences(of: ",", with: ".")) } }

        // Skala: prosent eller 0–1 for spektre, 0–100 eller 0–1 for XYZ.
        var spekterSkala = 1.0
        if spektral.count >= 3 {
            let maks = tall.flatMap { r in spektral.compactMap { $0.0 < r.count ? r[$0.0] : nil } }.max() ?? 1
            if maks > 1.5 { spekterSkala = 0.01 }
        }
        var xyzSkala = 1.0
        if let yi = indeks(.y), (tall.compactMap { yi < $0.count ? $0[yi] : nil }.max() ?? 0) > 2 { xyzSkala = 0.01 }

        var steg = 10.0
        if spektral.count >= 2 { steg = spektral[1].1 - spektral[0].1 }

        return rader.indices.compactMap { r -> Referansefelt? in
            let verdier = tall[r]
            func v(_ k: Kolonne) -> Double? { indeks(k).flatMap { $0 < verdier.count ? verdier[$0] : nil } }
            let navn = navnIndeks.map { $0 < rader[r].count ? rader[r][$0].trimmingCharacters(in: CharacterSet(charactersIn: "\"")) : "" } ?? ""
            if spektral.count >= 3 {
                let s = spektral.compactMap { $0.0 < verdier.count ? verdier[$0.0] : nil }
                if s.count == spektral.count {
                    return Referansefelt(navn: navn, verdi: .spekter(Spektrum(start: spektral[0].1, steg: steg,
                                                                               verdier: s.map { $0 * spekterSkala })))
                }
            }
            if let x = v(.x), let y = v(.y), let z = v(.z) {
                return Referansefelt(navn: navn, verdi: .xyz(XYZ(x: x * xyzSkala, y: y * xyzSkala, z: z * xyzSkala),
                                                            hvit: Lyskilde.d50.hvitpunkt))
            }
            if let l = v(.l), let a = v(.a), let b = v(.b) {
                return Referansefelt(navn: navn, verdi: .lab(CIELab(l: l, a: a, b: b)))
            }
            return nil
        }
    }

    // MARK: CGATS

    enum CGATS {
        static func les(_ tekst: String) throws -> [Referansefelt] {
            var format: [String] = [], rader: [[String]] = []
            var iFormat = false, iData = false
            for linje in tekst.components(separatedBy: .newlines) {
                let t = linje.trimmingCharacters(in: .whitespaces)
                if t.isEmpty || t.hasPrefix("#") { continue }
                switch t {
                case "BEGIN_DATA_FORMAT": iFormat = true; continue
                case "END_DATA_FORMAT": iFormat = false; continue
                case "BEGIN_DATA": iData = true; continue
                case "END_DATA": iData = false; continue
                default: break
                }
                if iFormat { format += biter(t) } else if iData { rader.append(biter(t)) }
            }
            guard !format.isEmpty, !rader.isEmpty else { throw Feil.ukjentFormat }
            return felt(rader: rader, kolonner: format.map(kolonne))
        }

        /// Deler en linje i ord, med anførselstegn rundt tekst som kan inneholde mellomrom.
        static func biter(_ linje: String) -> [String] {
            var resultat: [String] = [], gjeldende = "", iSitat = false
            for tegn in linje {
                if tegn == "\"" { iSitat.toggle(); continue }
                if !iSitat && (tegn == " " || tegn == "\t") {
                    if !gjeldende.isEmpty { resultat.append(gjeldende); gjeldende = "" }
                } else {
                    gjeldende.append(tegn)
                }
            }
            if !gjeldende.isEmpty { resultat.append(gjeldende) }
            return resultat
        }
    }

    // MARK: CSV, TSV og rene tallmatriser

    enum Tabell {
        /// Feltene, og skalaen for XYZ når verdiene var tre kolonner uten overskrift (tolkningen er et valg).
        static func les(_ tekst: String) throws -> ([Referansefelt], Double?) {
            let linjer = tekst.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && !$0.hasPrefix("#") }
            guard let første = linjer.first else { throw Feil.ingenFelt }
            let skilletegn: Character? = første.contains("\t") ? "\t" : første.contains(";") ? ";" : første.contains(",") && !erDesimalkomma(linjer) ? "," : nil
            let rader = linjer.map { linje -> [String] in
                let deler = skilletegn.map { s in linje.split(separator: s, omittingEmptySubsequences: false).map(String.init) }
                    ?? linje.split(whereSeparator: { $0 == " " }).map(String.init)
                return deler.map { $0.trimmingCharacters(in: .whitespaces) }
            }
            let erTall = { (s: String) in Double(s.replacingOccurrences(of: ",", with: ".")) != nil }
            if rader[0].contains(where: { !erTall($0) && !$0.isEmpty }) {
                // Overskrifter. Kjenner vi ingen kolonner, prøver vi første kolonne som navn og resten som tall.
                let kolonner = rader[0].map(kolonne)
                let resultat = felt(rader: Array(rader.dropFirst()), kolonner: kolonner)
                if !resultat.isEmpty { return (resultat, nil) }
                return matrise(rader.dropFirst().map { Array($0.dropFirst()) }, navn: rader.dropFirst().map { $0.first ?? "" })
            }
            return matrise(rader, navn: nil)
        }

        /// Komma som desimaltegn når hver linje har tall som «0,123» og ingen andre skilletegn.
        static func erDesimalkomma(_ linjer: [String]) -> Bool {
            linjer.prefix(5).allSatisfy { $0.range(of: #"\d,\d"#, options: .regularExpression) != nil && !$0.contains(", ") }
                && linjer.prefix(5).allSatisfy { $0.contains(" ") }
        }

        /// Spektrale oppsett ut fra antall verdier: (start, steg).
        static let spektraleOppsett: [Int: (Double, Double)] = [
            16: (400, 20), 31: (400, 10), 36: (380, 10), 41: (380, 10), 81: (380, 5), 401: (380, 1),
        ]

        /// En ren tallmatrise: hver rad et felt (eller hver kolonne, hvis det passer bedre), med Lab, XYZ eller
        /// spekter. En første kolonne med løpenummer eller bølgelengder kjennes igjen.
        static func matrise(_ tekstrader: [[String]], navn: [String]?) -> ([Referansefelt], Double?) {
            var m = tekstrader.map { $0.compactMap { Double($0.replacingOccurrences(of: ",", with: ".")) } }.filter { !$0.isEmpty }
            guard let bredde = m.first?.count, m.allSatisfy({ $0.count == bredde }) else { return ([], nil) }
            var start: Double?, steg: Double?
            // Bølgelengder i første kolonne → kolonnene er felt.
            let førsteKolonne = m.map { $0[0] }
            if førsteKolonne.count >= 3, (300...830).contains(førsteKolonne[0]),
               zip(førsteKolonne, førsteKolonne.dropFirst()).allSatisfy({ $1 - $0 == førsteKolonne[1] - førsteKolonne[0] }) {
                start = førsteKolonne[0]; steg = førsteKolonne[1] - førsteKolonne[0]
                m = m.map { Array($0.dropFirst()) }
                m = transponert(m)
            } else if let første = m.first, første.count >= 3, (300...830).contains(første[0]),
                      zip(første, første.dropFirst()).allSatisfy({ $1 - $0 == første[1] - første[0] && $1 > $0 }) {
                // Bølgelengder i første rad.
                start = første[0]; steg = første[1] - første[0]
                m = Array(m.dropFirst())
            } else if spektraleOppsett[bredde] == nil, spektraleOppsett[m.count] != nil, bredde != 3 {
                m = transponert(m)
            }
            // Løpenummer først (1, 2, 3, …) med tre verdier etter.
            if let b = m.first?.count, b == 4, m.enumerated().allSatisfy({ $1[0] == Double($0 + 1) }) {
                m = m.map { Array($0.dropFirst()) }
            }
            guard let b = m.first?.count else { return ([], nil) }
            let felt: [Referanseverdi]
            var treKolonnerSkala: Double?
            if b == 3 {
                treKolonnerSkala = (m.map { $0[1] }.max() ?? 0) > 2 ? 0.01 : 1
                // Lab hvis andre og tredje verdi har negative tall eller første er lyshet; ellers XYZ.
                let harNegative = m.contains { $0[1] < 0 || $0[2] < 0 }
                if harNegative || m.allSatisfy({ $0[0] <= 100 }) && !m.allSatisfy({ $0[0] <= 1.5 && $0[1] <= 1.5 }) {
                    felt = m.map { .lab(CIELab(l: $0[0], a: $0[1], b: $0[2])) }
                } else {
                    let skala = (m.map { $0[1] }.max() ?? 0) > 2 ? 0.01 : 1
                    felt = m.map { .xyz(XYZ(x: $0[0] * skala, y: $0[1] * skala, z: $0[2] * skala), hvit: Lyskilde.d50.hvitpunkt) }
                }
            } else if let oppsett = start.map({ ($0, steg ?? 10) }) ?? spektraleOppsett[b] {
                let skala = (m.flatMap { $0 }.max() ?? 0) > 1.5 ? 0.01 : 1
                felt = m.map { .spekter(Spektrum(start: oppsett.0, steg: oppsett.1, verdier: $0.map { $0 * skala })) }
            } else {
                return ([], nil)
            }
            return (felt.enumerated().map { i, v in
                Referansefelt(navn: navn.flatMap { i < $0.count ? $0[i] : nil } ?? "", verdi: v)
            }, treKolonnerSkala)
        }

        static func transponert(_ m: [[Double]]) -> [[Double]] {
            guard let b = m.first?.count else { return [] }
            return (0..<b).map { j in m.map { $0[j] } }
        }
    }

    // MARK: CxF3

    final class CxF: NSObject, XMLParserDelegate {
        private var felt: [Referansefelt] = []
        private var navn = ""
        private var tekst = ""
        private var spekterStart = 380.0, spekterSteg = 10.0
        private var spekter: [Double]?
        private var lab: [String: Double] = [:], xyz: [String: Double] = [:]
        private var iLab = false, iXYZ = false

        static func les(_ data: Data) -> [Referansefelt] {
            let leser = CxF()
            let parser = XMLParser(data: data)
            parser.shouldProcessNamespaces = true
            parser.delegate = leser
            parser.parse()
            return leser.felt
        }

        func parser(_ parser: XMLParser, didStartElement element: String, namespaceURI: String?, qualifiedName: String?,
                    attributes: [String: String] = [:]) {
            tekst = ""
            switch element {
            case "Object":
                navn = attributes["Name"] ?? attributes["Id"] ?? ""
                spekter = nil; lab = [:]; xyz = [:]
            case "WavelengthRange":
                if let s = attributes["StartWL"].flatMap(Double.init) { spekterStart = s }
                if let i = attributes["Increment"].flatMap(Double.init) { spekterSteg = i }
            case "ReflectanceSpectrum":
                if let s = attributes["StartWL"].flatMap(Double.init) { spekterStart = s }
            case "ColorCIELab": iLab = true
            case "ColorCIEXYZ": iXYZ = true
            default: break
            }
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) { tekst += string }

        func parser(_ parser: XMLParser, didEndElement element: String, namespaceURI: String?, qualifiedName: String?) {
            let verdi = Double(tekst.trimmingCharacters(in: .whitespacesAndNewlines))
            switch element {
            case "ReflectanceSpectrum":
                spekter = tekst.split(whereSeparator: \.isWhitespace).compactMap { Double($0) }
            case "L" where iLab, "A" where iLab, "B" where iLab: lab[element] = verdi
            case "X" where iXYZ, "Y" where iXYZ, "Z" where iXYZ: xyz[element] = verdi
            case "ColorCIELab": iLab = false
            case "ColorCIEXYZ": iXYZ = false
            case "Object":
                if let s = spekter, s.count >= 3 {
                    let skala = (s.max() ?? 0) > 1.5 ? 0.01 : 1
                    felt.append(Referansefelt(navn: navn, verdi: .spekter(Spektrum(start: spekterStart, steg: spekterSteg,
                                                                                  verdier: s.map { $0 * skala }))))
                } else if let x = xyz["X"], let y = xyz["Y"], let z = xyz["Z"] {
                    let skala = y > 2 ? 0.01 : 1
                    felt.append(Referansefelt(navn: navn, verdi: .xyz(XYZ(x: x * skala, y: y * skala, z: z * skala),
                                                                     hvit: Lyskilde.d50.hvitpunkt)))
                } else if let l = lab["L"], let a = lab["A"], let b = lab["B"] {
                    felt.append(Referansefelt(navn: navn, verdi: .lab(CIELab(l: l, a: a, b: b))))
                }
            default: break
            }
        }
    }
}
