#if os(macOS)
import AppKit
#endif
import FargeKjerne
import QuickLook
import SwiftUI

/// Det 3D-visningen viser.
enum Fargerom3DKilde: Identifiable {
    /// Farger (en harmoni eller palett), eventuelt med banen for en tonebane.
    case farger(navn: String, farger: [Farge], bane: [Farge]? = nil)
    /// En overgang: OKLab-veien (som Kolorist bruker) og den vanlige veien gjennom sRGB.
    case overgang(navn: String, fra: Farge, til: Farge, antall: Int)
    /// Tonene i et fargebibliotek som punktsky, eventuelt med en farge og nærmeste tone markert.
    case bibliotek(Fargebibliotek, markert: Farge? = nil)
    /// Fargerommet til en ICC-profil.
    case profil(ICCProfil)

    var id: String {
        switch self {
        case .farger(let navn, let farger, _): "farger:\(navn):\(farger.map { $0.hex() }.joined())"
        case .overgang(let navn, let fra, let til, let antall): "overgang:\(navn):\(fra.hex())\(til.hex())\(antall)"
        case .bibliotek(let b, let m): "bibliotek:\(b.id):\(m?.hex() ?? "")"
        case .profil(let p): "profil:\(p.id)"
        }
    }

    var navn: String {
        switch self {
        case .farger(let navn, _, _), .overgang(let navn, _, _, _): navn
        case .bibliotek(let b, _): b.navn
        case .profil: String(localized: "Fargerom i 3D")
        }
    }

    /// Rommet visningen starter i.
    var foretrukketRom: Fargerom3DRom? {
        switch self {
        case .farger: nil
        case .overgang: .okLab
        case .bibliotek, .profil: .cieLab
        }
    }
}

/// Rommet farger vises i.
enum Fargerom3DRom: String, CaseIterable, Identifiable {
    case fargekule, okLab, cieLab
    var id: String { rawValue }
    var navn: LocalizedStringKey {
        switch self {
        case .fargekule: "Fargekule"
        case .okLab: "OKLab"
        case .cieLab: "CIELab"
        }
    }
    /// Rom med kube og akser (a, b ut, L opp).
    nonisolated var erLab: Bool { self != .fargekule }

    nonisolated func posisjon(_ f: Farge, gamut: Gamut) -> SIMD3<Double> {
        switch self {
        case .fargekule: Fargerom3D.kuleposisjon(f, gamut: gamut)
        case .okLab: Fargerom3D.oklabposisjon(f)
        case .cieLab: Fargerom3D.labposisjon(f)
        }
    }
}

/// Ferdig regnet innhold til tegning: trekanter (flater), punkter og streker i modellkoordinater, med fargene klare.
struct Fargerom3DTegning: Sendable {
    struct Trekant: Sendable {
        var a: SIMD3<Double>, b: SIMD3<Double>, c: SIMD3<Double>
        var farge: Color
        var opasitet: Double
    }
    struct Punkt: Sendable {
        var p: SIMD3<Double>
        var farge: Color
        var størrelse: CGFloat
        var kant = true
    }
    struct Strek: Sendable {
        var a: SIMD3<Double>, b: SIMD3<Double>
        var farge: Color
        var bredde: CGFloat
        var stiplet = false
    }
    var trekanter: [Trekant] = []
    var punkter: [Punkt] = []
    var streker: [Strek] = []
    var rom: Fargerom3DRom = .fargekule
    /// Kort tekst om det som er tegnet (f.eks. hvor mange farger som ligger utenfor profilen).
    var merknad: String?
    /// Det samme som USDZ-scene.
    var scene = Fargerom3D.Scene()

    /// Kula og gamutskallene mellomlagres per rom, profil, gamut og tilpasningsmetode – de er det tunge (skallene regnes
    /// gjennom ICC-profilen), og de endres ikke mens fargene justeres. Da kan levende 3D følge fargene fortløpende.
    nonisolated private static let bufferlås = NSLock()
    nonisolated(unsafe) private static var flatebuffer: [String: [Fargerom3D.Flate]] = [:]

    nonisolated private static func buffret(_ nøkkel: String, _ lag: () -> [Fargerom3D.Flate]) -> [Fargerom3D.Flate] {
        bufferlås.lock()
        if let f = flatebuffer[nøkkel] { bufferlås.unlock(); return f }
        bufferlås.unlock()
        let f = lag()
        bufferlås.lock()
        if flatebuffer.count > 24 { flatebuffer.removeAll() }
        flatebuffer[nøkkel] = f
        bufferlås.unlock()
        return f
    }

    /// Bygger innholdet (tungt for ICC-profiler og biblioteker første gang: kjøres i bakgrunnen).
    nonisolated static func lag(_ kilde: Fargerom3DKilde, rom: Fargerom3DRom, profil: ICCProfil, sammenlign: ICCProfil?,
                                gamut: Gamut, hensikt: Gjengivelseshensikt = .relativKolorimetrisk) -> Fargerom3DTegning {
        var t = Fargerom3DTegning()
        let rom: Fargerom3DRom = if case .profil = kilde { rom == .fargekule ? .cieLab : rom } else { rom }
        t.rom = rom
        let posisjon: (Farge) -> SIMD3<Double> = { rom.posisjon($0, gamut: gamut) }

        func flate(_ f: Fargerom3D.Flate, opasitet: Double) {
            let farger = f.farger.map(\.swiftUI)
            for tr in f.trekanter {
                let (i, j, k) = (Int(tr.x), Int(tr.y), Int(tr.z))
                t.trekanter.append(.init(a: f.punkter[i], b: f.punkter[j], c: f.punkter[k], farge: farger[i], opasitet: opasitet))
            }
            t.scene.flater.append((f, opasitet))
        }
        func skall(_ p: ICCProfil, opasitet: Double, oppløsning: Int) {
            let sider = buffret("skall|\(p.id)|\(oppløsning)|\(hensikt.kolorimetrisk.rawValue)|\(rom.rawValue)|\(String(describing: gamut))") {
                guard let sider = Fargerom3D.gamutskall(p, oppløsning: oppløsning, hensikt: hensikt) else { return [] }
                return rom == .cieLab ? sider : sider.map { $0.omplassert(posisjon) }
            }
            for s in sider { flate(s, opasitet: opasitet) }
        }
        func kule(opasitet: Double) {
            for f in buffret("kule|\(String(describing: gamut))", { [Fargerom3D.kuleflate(gamut: gamut, kolonner: 49, rader: 25)] }) {
                flate(f, opasitet: opasitet)
            }
        }
        func linje(_ punkter: [SIMD3<Double>], farger: [Color], bredde: CGFloat, stiplet: Bool = false) {
            for i in 1..<punkter.count {
                t.streker.append(.init(a: punkter[i - 1], b: punkter[i], farge: farger[min(i, farger.count - 1)], bredde: bredde, stiplet: stiplet))
            }
        }
        func punkt(_ f: Farge, størrelse: CGFloat = 14, radius: Double = 0.06, kant: Bool = true) {
            let p = posisjon(f)
            t.punkter.append(.init(p: p, farge: f.swiftUI, størrelse: størrelse, kant: kant))
            t.scene.punkter.append((p, f, radius))
        }
        /// Fargen slik profilen gjengir den med valgt hensikt: inn i profilen med hensikten, og tilbake kolorimetrisk –
        /// det trykket faktisk gir. Med perseptuell i en trykkprofil kan fargene da havne inne i skallet (og farger
        /// innenfor flyttes også litt). sRGB, Display P3 og andre matriseprofiler har ingen egne tabeller for
        /// hensiktene; der gir perseptuell og metning Kolorists gamut-kartlegging for sRGB og P3 (OKLCH, kulør og
        /// lyshet bevares, til overflaten), og ellers klipper alle.
        func kartlagt(_ f: Farge) -> Farge {
            let perseptuell = hensikt == .perseptuell || hensikt == .metning
            if profil.id == ICCProfil.sRGB.id, perseptuell { return f.gamutKartlagt(til: .sRGB) }
            if profil.id == ICCProfil.displayP3.id, perseptuell { return f.gamutKartlagt(til: .displayP3) }
            guard let k = f.komponenter(i: profil, hensikt: hensikt),
                  let tilbake = Farge(komponenter: k, i: profil, hensikt: hensikt.kolorimetrisk) else { return f }
            return tilbake
        }
        /// Piler fra farger utenfor profilen til der de havner.
        func kartlegging(_ farger: [Farge]) {
            guard rom.erLab else { return }
            var utenfor = 0
            for f in farger {
                let m = kartlagt(f)
                let a = f.okLab, b = m.okLab
                guard hypot(hypot(a.l - b.l, a.a - b.a), a.b - b.b) > 0.01 else { continue }
                utenfor += 1
                let (p, q) = (posisjon(f), posisjon(m))
                t.streker.append(.init(a: p, b: q, farge: .red.opacity(0.85), bredde: 2))
                t.punkter.append(.init(p: q, farge: m.swiftUI, størrelse: 9))
                t.scene.streker.append(([p, q], Farge(lineærR: 0.8, g: 0.05, b: 0.05), 0.008))
                t.scene.punkter.append((q, m, 0.035))
            }
            if utenfor > 0 {
                t.merknad = String(localized: "\(utenfor) av fargene ligger utenfor \(profil.navn). Pilene viser hvor de havner.")
            }
        }

        switch kilde {
        case .farger(_, let farger, let bane):
            if rom == .fargekule {
                kule(opasitet: 0.32)
                let ekvator = (0...72).map { Fargerom3D.kuleposisjon(lyshet: 0.5, metning: 1, kulør: Double($0) * 5) }
                linje(ekvator, farger: [.primary.opacity(0.35)], bredde: 0.75, stiplet: true)
            } else {
                skall(profil, opasitet: 0.28, oppløsning: 12)
            }
            if let bane, bane.count > 1 {
                let punkter = bane.map(posisjon)
                linje(punkter, farger: [.primary.opacity(0.8)], bredde: 2.5)
                t.scene.streker.append((punkter, Farge(lineærR: 0.2, g: 0.2, b: 0.2), 0.012))
            }
            for f in farger { punkt(f) }
            kartlegging(farger)

        case .overgang(_, let fra, let til, let antall):
            if rom == .fargekule {
                kule(opasitet: 0.26)
            } else {
                skall(profil, opasitet: 0.2, oppløsning: 12)
            }
            // OKLab-veien (Kolorist) og veien gjennom sRGB (vanlige CSS-overganger og de fleste designprogrammer). Veien
            // gjennom sRGB er et bevisst unntak fra regelen om at all interpolasjon skjer i OKLab: den vises til sammenligning.
            let ok = Overgang.toner(fra: fra, til: til, antall: 48)
            let (a, b) = (fra.gamutKartlagt(til: .sRGB).sRGB, til.gamutKartlagt(til: .sRGB).sRGB)
            let srgb = (0..<48).map { i -> Farge in
                let t = Double(i) / 47
                return Farge(sRGB: SRGB(r: a.r + (b.r - a.r) * t, g: a.g + (b.g - a.g) * t, b: a.b + (b.b - a.b) * t))
            }
            let okPunkter = ok.map(posisjon), srgbPunkter = srgb.map(posisjon)
            linje(srgbPunkter, farger: [.orange], bredde: 2.5, stiplet: true)
            linje(okPunkter, farger: [.primary.opacity(0.85)], bredde: 2.5)
            t.scene.streker.append((srgbPunkter, Farge(lineærR: 0.9, g: 0.4, b: 0.05), 0.01))
            t.scene.streker.append((okPunkter, Farge(lineærR: 0.15, g: 0.15, b: 0.15), 0.012))
            let toner = Overgang.toner(fra: fra, til: til, antall: max(antall, 2))
            for f in toner { punkt(f, størrelse: 12, radius: 0.05) }
            for i in 1..<max(antall, 2) - 1 {
                let t = Double(i) / Double(max(antall, 2) - 1)
                let f = Farge(sRGB: SRGB(r: a.r + (b.r - a.r) * t, g: a.g + (b.g - a.g) * t, b: a.b + (b.b - a.b) * t))
                punkt(f, størrelse: 8, radius: 0.03)
            }
            t.merknad = String(localized: "Heltrukket: OKLab, som Kolorist bruker. Stiplet: rett gjennom sRGB, som vanlige overganger.")

        case .bibliotek(let bibliotek, let markert):
            if rom == .fargekule {
                kule(opasitet: 0.17)
            } else {
                skall(profil, opasitet: 0.17, oppløsning: 12)
            }
            let små: CGFloat = bibliotek.farger.count > 400 ? 5 : 8
            for pf in bibliotek.farger { punkt(pf.farge, størrelse: små, radius: 0.018, kant: false) }
            if let markert {
                punkt(markert, størrelse: 16, radius: 0.06)
                if let n = bibliotek.nærmeste(til: markert) {
                    punkt(n.tone.farge, størrelse: 12, radius: 0.045)
                    let (p, q) = (posisjon(markert), posisjon(n.tone.farge))
                    t.streker.append(.init(a: p, b: q, farge: .primary, bredde: 2))
                    t.scene.streker.append(([p, q], Farge(lineærR: 0.1, g: 0.1, b: 0.1), 0.008))
                    t.merknad = String(localized: "Nærmeste tone: \(n.tone.visningsnavn) (ΔE00 \(String(format: "%.1f", n.avstand))).")
                }
            }

        case .profil:
            skall(profil, opasitet: 1, oppløsning: 16)
            if let sammenlign { skall(sammenlign, opasitet: 0.3, oppløsning: 12) }
        }

        // Den grå aksen, fra sort til hvit.
        let akse = (0...10).map { SIMD3<Double>(0, Double($0) / 5 - 1, 0) }
        linje(akse, farger: (0...10).map { Color(white: Double($0) / 10) }, bredde: 3)
        if rom.erLab {
            // Kuben og a/b-aksene ved bunnen.
            let h: [SIMD3<Double>] = [[-1, -1, -1], [1, -1, -1], [1, -1, 1], [-1, -1, 1], [-1, 1, -1], [1, 1, -1], [1, 1, 1], [-1, 1, 1]]
            for (a, b) in [(0, 1), (1, 2), (2, 3), (3, 0), (4, 5), (5, 6), (6, 7), (7, 4), (0, 4), (1, 5), (2, 6), (3, 7)] {
                t.streker.append(.init(a: h[a], b: h[b], farge: .primary.opacity(0.15), bredde: 1))
            }
            t.streker.append(.init(a: [-1, -1, 0], b: [1, -1, 0], farge: .primary.opacity(0.35), bredde: 1.5))
            t.streker.append(.init(a: [0, -1, -1], b: [0, -1, 1], farge: .primary.opacity(0.35), bredde: 1.5))
        }
        return t
    }
}

/// 3D-visningen: tegnet med egen projeksjon og flatene sortert bakfra (virker likt på iPhone, iPad og Mac, og takler
/// gjennomsiktige flater). Dra for å dreie, knip for å zoome, trykk for å la den rotere av seg selv.
struct Fargerom3DVisning: View {
    /// Sekunder per runde når modellen roterer av seg selv (også i den roterende 3D-modellen til AR).
    nonisolated static let rundetid = 36.0
    let tegning: Fargerom3DTegning
    @Binding var dreining: Double
    /// Rotasjon av seg selv rundt den grå aksen: trykk på modellen eller knappen i hjørnet. Mens du drar eller knipser,
    /// står den stille, og den fortsetter litt etter at du slipper.
    @Binding var roterer: Bool
    /// Rotasjonen holdt igjen av et grep (dra eller knip), og oppgaven som slipper den løs igjen.
    @State private var holdt = false
    @State private var slipp: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduserBevegelse
    @State private var helning = 0.38
    @State private var zoom = 1.0
    @State private var start: (dreining: Double, helning: Double)?
    @State private var zoomStart: Double?

    private func projiser(_ p: SIMD3<Double>, senter: CGPoint, skala: Double) -> (CGPoint, Double) {
        let x1 = p.x * cos(dreining) + p.z * sin(dreining)
        let z1 = -p.x * sin(dreining) + p.z * cos(dreining)
        let y2 = p.y * cos(helning) - z1 * sin(helning)
        let z2 = p.y * sin(helning) + z1 * cos(helning)
        return (CGPoint(x: senter.x + x1 * skala, y: senter.y - y2 * skala), z2)
    }

    private enum Element {
        case trekant(Path, Color, Double)
        case punkt(CGPoint, Color, CGFloat, Bool)
        case strek(CGPoint, CGPoint, Color, CGFloat, Bool)
    }

    private var aksetekster: [(String, SIMD3<Double>)] {
        switch tegning.rom {
        case .fargekule: []
        case .okLab: [("L 1", [0, 1.12, 0]), ("L 0", [0, -1.14, 0]), ("+a", [1.18, -1, 0]), ("−a", [-1.18, -1, 0]),
                      ("+b", [0, -1, -1.18]), ("−b", [0, -1, 1.18])]
        case .cieLab: [("L* 100", [0, 1.12, 0]), ("L* 0", [0, -1.14, 0]), ("+a*", [1.18, -1, 0]), ("−a*", [-1.18, -1, 0]),
                       ("+b*", [0, -1, -1.18]), ("−b*", [0, -1, 1.18])]
        }
    }

    var body: some View {
        Canvas { ctx, størrelse in
            let senter = CGPoint(x: størrelse.width / 2, y: størrelse.height / 2)
            let skala = min(størrelse.width, størrelse.height) * (tegning.rom.erLab ? 0.3 : 0.42) * zoom
            var elementer: [(dybde: Double, element: Element)] = []
            elementer.reserveCapacity(tegning.trekanter.count + tegning.punkter.count + tegning.streker.count)
            for t in tegning.trekanter {
                let (a, za) = projiser(t.a, senter: senter, skala: skala)
                let (b, zb) = projiser(t.b, senter: senter, skala: skala)
                let (c, zc) = projiser(t.c, senter: senter, skala: skala)
                var sti = Path()
                sti.move(to: a); sti.addLine(to: b); sti.addLine(to: c); sti.closeSubpath()
                elementer.append(((za + zb + zc) / 3, .trekant(sti, t.farge, t.opasitet)))
            }
            for s in tegning.streker {
                let (a, za) = projiser(s.a, senter: senter, skala: skala)
                let (b, zb) = projiser(s.b, senter: senter, skala: skala)
                elementer.append(((za + zb) / 2 + 0.001, .strek(a, b, s.farge, s.bredde, s.stiplet)))
            }
            for p in tegning.punkter {
                let (q, z) = projiser(p.p, senter: senter, skala: skala)
                elementer.append((z + 0.002, .punkt(q, p.farge, p.størrelse, p.kant)))
            }
            elementer.sort { $0.dybde < $1.dybde }
            for (_, e) in elementer {
                switch e {
                case .trekant(let sti, let farge, let opasitet):
                    if opasitet < 1 {
                        ctx.fill(sti, with: .color(farge.opacity(opasitet)))
                    } else {
                        ctx.fill(sti, with: .color(farge))
                        ctx.stroke(sti, with: .color(farge), lineWidth: 0.7)
                    }
                case .strek(let a, let b, let farge, let bredde, let stiplet):
                    var sti = Path()
                    sti.move(to: a); sti.addLine(to: b)
                    ctx.stroke(sti, with: .color(farge), style: StrokeStyle(lineWidth: bredde, lineCap: .round, dash: stiplet ? [4, 4] : []))
                case .punkt(let p, let farge, let d, let kant):
                    let sirkel = Path(ellipseIn: CGRect(x: p.x - d / 2, y: p.y - d / 2, width: d, height: d))
                    ctx.fill(sirkel, with: .color(farge))
                    if kant {
                        ctx.stroke(sirkel, with: .color(.white), lineWidth: 2)
                        ctx.stroke(sirkel.strokedPath(StrokeStyle(lineWidth: 2)), with: .color(.black.opacity(0.3)), lineWidth: 0.5)
                    }
                }
            }
            for (tekst, p) in aksetekster {
                ctx.draw(Text(verbatim: tekst).font(.caption2.weight(.semibold)).foregroundStyle(Color.sekundærTekst),
                         at: projiser(p, senter: senter, skala: skala).0)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { if !reduserBevegelse { roterer.toggle() } }
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { g in
                    hold()
                    let s = start ?? (dreining, helning)
                    start = s
                    dreining = s.dreining + g.translation.width * 0.01
                    helning = min(max(s.helning + g.translation.height * 0.01, -1.4), 1.4)
                }
                .onEnded { _ in start = nil; slippEtterHvert() }
        )
        .simultaneousGesture(
            MagnifyGesture()
                .onChanged { g in
                    hold()
                    let s = zoomStart ?? zoom
                    zoomStart = s
                    zoom = min(max(s * g.magnification, 0.6), 2.5)
                }
                .onEnded { _ in zoomStart = nil; slippEtterHvert() }
        )
        // Rotasjonen: om lag 30 bilder i sekundet mens den står på og visningen er synlig (oppgaven stopper ellers).
        // «Reduser bevegelse» i systemet holder den av.
        .task(id: roterer && !holdt && !reduserBevegelse) {
            guard roterer, !holdt, !reduserBevegelse else { return }
            var forrige = Date.now
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(33))
                let nå = Date.now
                dreining += nå.timeIntervalSince(forrige) * 2 * .pi / Self.rundetid
                forrige = nå
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if !reduserBevegelse {
                Button { roterer.toggle() } label: {
                    Label(roterer ? "Stopp rotasjonen" : "Roter av seg selv", systemImage: roterer ? "pause.fill" : "rotate.3d")
                        .labelStyle(.iconOnly)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .tint(roterer ? Color.accentColor : Color.secondary)
                .help(roterer ? "Stopp rotasjonen" : "Roter av seg selv")
            }
        }
        .onDisappear { slipp?.cancel() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Fargerom i 3D"))
        .accessibilityHint(Text("Dra for å dreie"))
        .accessibilityAdjustableAction { retning in dreining += retning == .increment ? 0.2 : -0.2 }
    }
}

extension Fargerom3DVisning {
    /// Et grep begynner: rotasjonen står stille så lenge det varer.
    private func hold() {
        slipp?.cancel()
        if !holdt { holdt = true }
    }

    /// Grepet er sluppet: rotasjonen fortsetter fra den nye vinkelen etter et lite øyeblikk.
    private func slippEtterHvert() {
        slipp?.cancel()
        slipp = Task {
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }
            holdt = false
        }
    }
}

extension View {
    /// Viser 3D-visningen for kilden: i venstre halvdel i bredt oppsett med fargekort (åpen iPhone Duo, iPad liggende,
    /// bred Mac), ellers som ark (iPhone, iPad) eller i eget vindu (Mac).
    /// `opphav`: hva som åpnet 3D-visningen (f.eks. «harmoni»). I venstre halvdel følger den da fargene derfra
    /// (`levende3D(opphav:kilde:)`).
    func fargerom3D(_ kilde: Binding<Fargerom3DKilde?>, gamut: Gamut = .displayP3, startprofil: ICCProfil? = nil,
                    opphav: String? = nil) -> some View {
        modifier(Fargerom3DÅpner(kilde: kilde, gamut: gamut, startprofil: startprofil, opphav: opphav))
    }

    /// Levende 3D: står 3D-visningen for `opphav` i venstre halvdel, bygges den på nytt med `kilde` når fargene endres
    /// (harmonien, fargen, overgangen eller paletten man arbeider med). Dreiningen beholdes.
    func levende3D(opphav: String, kilde: Fargerom3DKilde?) -> some View {
        modifier(Levende3D(opphav: opphav, kilde: kilde))
    }
}

private struct Levende3D: ViewModifier {
    let opphav: String
    let kilde: Fargerom3DKilde?
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @Environment(\.venstre3DFane) private var fane

    func body(content: Content) -> some View {
        content.onChange(of: kilde?.id) {
            guard let fane, let v = arbeidsbenk.venstre3D[fane], v.opphav == opphav, let k = kilde, k.id != v.kilde.id else { return }
            arbeidsbenk.venstre3D[fane] = Fargerom3DVindu(kilde: k, gamut: v.gamut, startprofil: v.startprofil, opphav: opphav)
        }
    }
}

private struct Fargerom3DÅpner: ViewModifier {
    @Binding var kilde: Fargerom3DKilde?
    let gamut: Gamut
    let startprofil: ICCProfil?
    let opphav: String?
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @Environment(\.venstre3DFane) private var venstreFane
    #if os(macOS)
    @Environment(\.openWindow) private var åpneVindu
    #endif

    /// Fanen 3D-visningen legges i venstre halvdel for, eller `nil` (ark / eget vindu). Rotvisningen (skjermbilder)
    /// har ingen fane i miljøet, men følger åpen iPhone Duo.
    private var tilVenstre: Arbeidsbenk.Fane? {
        venstreFane ?? (arbeidsbenk.duoÅpen || arbeidsbenk.bredeKort.contains(arbeidsbenk.valgtFane) ? arbeidsbenk.valgtFane : nil)
    }

    private func flyttTilVenstreHalvdel() {
        guard let fane = tilVenstre, let k = kilde else { return }
        kilde = nil
        arbeidsbenk.venstre3D[fane] = Fargerom3DVindu(kilde: k, gamut: gamut, startprofil: startprofil, opphav: opphav)
    }

    func body(content: Content) -> some View {
        #if os(iOS)
        content
            .sheet(item: Binding(get: { tilVenstre == nil ? kilde : nil }, set: { kilde = $0 })) {
                Fargerom3DArk(kilde: $0, gamut: gamut, startprofil: startprofil)
            }
            .onChange(of: kilde?.id) { flyttTilVenstreHalvdel() }
            // Brettet ut / snudd til liggende med arket oppe: 3D-visningen flytter til venstre halvdel.
            .onChange(of: tilVenstre) { flyttTilVenstreHalvdel() }
        #else
        content.onChange(of: kilde?.id) {
            guard let k = kilde else { return }
            if tilVenstre != nil { flyttTilVenstreHalvdel(); return }
            kilde = nil
            let id = UUID()
            Fargerom3DVindu.åpne[id] = Fargerom3DVindu(kilde: k, gamut: gamut, startprofil: startprofil)
            åpneVindu(id: Fargerom3DVindu.scene, value: id)
        }
        #endif
    }
}

/// 3D-visningen for en kilde: i venstre halvdel i bredt oppsett (`Arbeidsbenk.venstre3D`), ellers i eget vindu på Mac
/// (kilden kan ikke kodes til vindustilstand, så vinduet får en nøkkel til innholdet i `åpne`; vinduet gjenopprettes ikke
/// etter omstart, og finnes ikke innholdet, lukkes det).
struct Fargerom3DVindu {
    static let scene = "fargerom3D"
    static var åpne: [UUID: Fargerom3DVindu] = [:]
    let kilde: Fargerom3DKilde
    let gamut: Gamut
    let startprofil: ICCProfil?
    /// Hva som åpnet visningen (levende 3D, se `levende3D(opphav:kilde:)`).
    var opphav: String? = nil
}

#if os(macOS)
struct Fargerom3DVinduInnhold: View {
    let id: UUID?
    @Environment(\.dismiss) private var lukk

    var body: some View {
        if let id, let v = Fargerom3DVindu.åpne[id] {
            Fargerom3DArk(kilde: v.kilde, gamut: v.gamut, startprofil: v.startprofil)
                .onDisappear { Fargerom3DVindu.åpne[id] = nil }
        } else {
            Color.clear.frame(width: 1, height: 1).onAppear { lukk() }
        }
    }
}
#endif

/// 3D-visningen: valg av rom og profil, deling som 3D-modell (USDZ) og AR på iPhone og iPad. Ark på iPhone og iPad,
/// eget vindu på Mac (se `fargerom3D(_:gamut:startprofil:)`).
struct Fargerom3DArk: View {
    let kilde: Fargerom3DKilde
    var gamut: Gamut = .displayP3
    /// Profilen visningen starter med (f.eks. den som er valgt under «Vis som» i Studio).
    var startprofil: ICCProfil? = nil
    /// I venstre halvdel (åpen iPhone Duo): «Ferdig» viser fargekortet igjen i stedet for å lukke et ark.
    var ferdig: (() -> Void)? = nil
    @Environment(\.dismiss) private var lukk
    @AppStorage("fargerom3D.rom") private var lagretRom: Fargerom3DRom = .fargekule
    @AppStorage("fargerom3D.profil") private var profilID = ICCProfil.sRGB.id
    /// Rommet en profil sammenlignes med (sRGB til å begynne med; «Ingen» lagres som tom).
    @AppStorage("fargerom3D.sammenlign") private var sammenlignID = ICCProfil.sRGB.id
    @AppStorage("fargerom3D.hensikt") private var hensikt: Gjengivelseshensikt = .relativKolorimetrisk
    /// Om modellen roterer av seg selv (huskes). AR og 3D-modellen på Mac roterer da også; delt 3D-modell står stille.
    @AppStorage("fargerom3D.roterer") private var roterer = false
    @Environment(\.accessibilityReduceMotion) private var reduserBevegelse
    /// Profilen arket ble åpnet med (en profil eller «Vis som» i Studio) – gjelder bare dette arket, så det lagrede
    /// valget for paletter og harmonier står urørt.
    @State private var øktprofilID: String?
    /// Om visningen er snudd til utgangsstillingen (én gang per ark).
    @State private var orientert = false
    @State private var rom: Fargerom3DRom = .fargekule
    @State private var tegning: Fargerom3DTegning?
    @State private var dreining = 0.0
    @State private var fil: URL?
    @State private var forhåndsvisning: URL?

    private var erProfil: Bool { if case .profil = kilde { true } else { false } }
    private var profiler: [ICCProfil] { ProfilBibliotek.delt.alle.filter { $0.modell == .rgb || $0.modell == .cmyk } }
    private var profil: ICCProfil { ProfilBibliotek.delt.profil(id: øktprofilID ?? profilID) ?? .sRGB }
    /// Ikke sammenligning med seg selv.
    private var sammenlign: ICCProfil? {
        sammenlignID.isEmpty || sammenlignID == profil.id ? nil : ProfilBibliotek.delt.profil(id: sammenlignID)
    }
    private var nøkkel: String { "\(kilde.id)|\(rom.rawValue)|\(profil.id)|\(sammenlignID)|\(hensikt.rawValue)" }
    private var romvalg: [Fargerom3DRom] { erProfil ? [.okLab, .cieLab] : Fargerom3DRom.allCases }
    /// Profilens hvitt (CMYK 0/0/0/0, RGB 1/1/1) med absolutt kolorimetrisk – papirets farge – når den er valgt.
    private var papirhvitt: Farge? {
        guard rom.erLab, hensikt == .absoluttKolorimetrisk, profil.modell == .rgb || profil.modell == .cmyk else { return nil }
        let hvitt = Array(repeating: profil.modell == .cmyk ? 0.0 : 1.0, count: profil.antallKomponenter)
        return Farge(komponenter: hvitt, i: profil, hensikt: .absoluttKolorimetrisk)
    }

    var body: some View {
        if let ferdig {
            // I venstre halvdel (åpen iPhone Duo, iPad liggende, bred Mac): egen topplinje – et navigasjonsoppsett inne
            // i fanens viser ikke verktøylinjen.
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Text(kilde.navn).font(.headline).lineLimit(1)
                    Spacer(minLength: 8)
                    modellknapper.labelStyle(.iconOnly)
                    Button("Ferdig", action: ferdig).fontWeight(.semibold)
                }
                .padding(.horizontal)
                .padding(.top, 12)
                hovedinnhold
            }
        } else {
            NavigationStack {
                hovedinnhold
                    .navigationTitle(kilde.navn)
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .toolbar {
                        #if os(iOS)
                        ToolbarItem(placement: .confirmationAction) { Button("Ferdig") { lukk() } }
                        #endif
                        ToolbarItemGroup(placement: .primaryAction) { modellknapper }
                    }
            }
            #if os(macOS)
            .frame(minWidth: 520, minHeight: 600)
            #endif
        }
    }

    /// AR / 3D-modellen og deling som 3D-modell (når modellen er laget).
    @ViewBuilder private var modellknapper: some View {
        if let fil {
            // iPhone og iPad: AR Quick Look (modellen på bordet). Mac: 3D-modellen i eget vindu, uten AR.
            #if os(iOS)
            Button { Task { forhåndsvisning = await visningsfil(fil) } } label: { Label("Se i AR", systemImage: "arkit") }
            #else
            Button { Task { NSWorkspace.shared.open(await visningsfil(fil)) } } label: { Label("Vis 3D-modell", systemImage: "cube") }
            #endif
            ShareLink(item: fil) { Label("Del som 3D-modell", systemImage: "square.and.arrow.up") }
        }
    }

    private var hovedinnhold: some View {
        VStack(spacing: 12) {
            Picker("Rom", selection: $rom) {
                ForEach(romvalg) { Text($0.navn).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            if rom.erLab {
                // Fargerommet (heldekkende for en profil, som glass rundt fargene ellers) og for en profil et annet
                // rom til sammenligning (som glass).
                // Et valg her gjelder videre (lagres); profilen arket ble åpnet med, gjelder bare til den byttes.
                profilvelger("Fargerom", valgt: Binding(get: { øktprofilID ?? profilID },
                                                        set: { øktprofilID = nil; profilID = $0 }), ingen: false)
                if erProfil { profilvelger("Sammenlign med", valgt: $sammenlignID, ingen: true) }
                HStack {
                    Text("Tilpasningsmetode").foregroundStyle(Color.sekundærTekst)
                    Spacer(minLength: 8)
                    Picker("Tilpasningsmetode", selection: $hensikt) {
                        ForEach(Gjengivelseshensikt.allCases, id: \.self) { Text($0.visningsnavn).tag($0) }
                    }
                    .labelsHidden()
                }
            }
            ZStack {
                if let tegning {
                    Fargerom3DVisning(tegning: tegning, dreining: $dreining, roterer: $roterer)
                } else {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Absolutt kolorimetrisk: papirhvitt (profilens hvitpunkt) bak modellen, så fargene ses mot underlaget de
            // gjengis på. Bare på skjermen – 3D-modellen (USDZ) og AR er uendret.
            .background {
                if let papirhvitt {
                    RoundedRectangle(cornerRadius: 16, style: .continuous).fill(papirhvitt.swiftUI)
                }
            }
            VStack(spacing: 4) {
                if papirhvitt != nil {
                    Text("Bakgrunnen er papirhvitt i \(ProfilBibliotek.delt.visningsnavn(profil)).").font(.footnote)
                }
                if let merknad = tegning?.merknad {
                    Text(merknad).font(.footnote)
                }
                Text(forklaring)
                    .font(.footnote)
                    .foregroundStyle(Color.sekundærTekst)
            }
            .multilineTextAlignment(.center)
        }
        .padding()
        #if os(iOS)
        .quickLookPreview($forhåndsvisning)
        #endif
        .onAppear {
            if case .profil(let p) = kilde { øktprofilID = p.id } else if let startprofil { øktprofilID = startprofil.id }
            rom = kilde.foretrukketRom ?? lagretRom
        }
        .onChange(of: rom) { _, ny in if kilde.foretrukketRom == nil { lagretRom = ny } }
        // Levende 3D: et nytt fargerom (f.eks. «Vis som» byttet) vises med en gang.
        .onChange(of: kilde.id) { if case .profil(let p) = kilde { øktprofilID = p.id } }
        .task(id: nøkkel) { await bygg() }
    }

    private var forklaring: LocalizedStringKey {
        switch rom {
        case .fargekule: "Kuløren rundt den grå aksen, lysheten opp og metningen ut mot overflaten. Dra for å dreie."
        case .okLab: "OKLab: L opp, a og b ut – overganger er rette linjer her. Dra for å dreie, knip for å zoome."
        case .cieLab: "CIELab (D50): L* opp, a* og b* ut. Dra for å dreie, knip for å zoome."
        }
    }

    /// Etikett til venstre og valget til høyre, så det er tydelig hvilket valg som er hva.
    private func profilvelger(_ tittel: LocalizedStringKey, valgt: Binding<String>, ingen: Bool) -> some View {
        HStack {
            Text(tittel).foregroundStyle(Color.sekundærTekst)
            Spacer(minLength: 8)
            Picker(tittel, selection: valgt) {
                if ingen { Text("Ingen").tag("") }
                ForEach(profiler) { Text(ProfilBibliotek.delt.visningsnavn($0)).tag($0.id) }
            }
            .labelsHidden()
        }
    }

    /// Fila til AR / 3D-modellen: den samme som deles, eller – når modellen roterer – en roterende variant med samme
    /// navn (i egen mappe), så modellen snurrer også der.
    private func visningsfil(_ fil: URL) async -> URL {
        guard roterer, !reduserBevegelse, let scene = tegning?.scene else { return fil }
        let navn = fil.deletingPathExtension().lastPathComponent
        return await Task.detached(priority: .userInitiated) { () -> URL in
            let mappe = FileManager.default.temporaryDirectory.appendingPathComponent("Roterende", isDirectory: true)
            let url = mappe.appendingPathComponent(fil.lastPathComponent)
            do {
                try FileManager.default.createDirectory(at: mappe, withIntermediateDirectories: true)
                try scene.usdz(navn: navn, rundetid: Fargerom3DVisning.rundetid).write(to: url, options: .atomic)
                return url
            } catch { return fil }
        }.value
    }

    /// Regner ut tegningen (og USDZ-fila) i bakgrunnen.
    private func bygg() async {
        let navn = erProfil ? ProfilBibliotek.delt.visningsnavn(profil) : kilde.navn
        let (k, r, p, s, g, h) = (kilde, rom, profil, sammenlign, gamut, hensikt)
        if !orientert, case .overgang(_, let fra, let til, _) = kilde {
            // Overgangen på tvers av synsretningen, så forskjellen mellom de to veiene ses fra siden.
            let d = Fargerom3D.oklabposisjon(til) - Fargerom3D.oklabposisjon(fra)
            dreining = atan2(d.z, d.x) + (abs(d.x) + abs(d.z) < 0.01 ? 0.6 : 0)
            orientert = true
        }
        if !orientert {
            orientert = true
            // Snu kula så snittkuløren av fargene vender mot betrakteren.
            let farger: [Farge] = switch kilde {
            case .farger(_, let f, _): f
            case .overgang(_, let fra, let til, _): [fra, til]
            case .bibliotek(_, let m): m.map { [$0] } ?? []
            case .profil: []
            }
            let lch = farger.map(\.okLCH).filter { $0.c > 0.02 }
            if lch.isEmpty {
                dreining = 215 * .pi / 180
            } else {
                let (sx, sy) = lch.reduce((0.0, 0.0)) { ($0.0 + cos($1.h * .pi / 180), $0.1 + sin($1.h * .pi / 180)) }
                dreining = -.pi / 2 - atan2(sy, sx)
            }
        }
        let ny = await Task.detached(priority: .userInitiated) {
            Fargerom3DTegning.lag(k, rom: r, profil: p, sammenlign: s, gamut: g, hensikt: h)
        }.value
        guard !Task.isCancelled else { return }
        tegning = ny
        // 3D-modellen (USDZ) til deling og AR først når fargene har stått stille litt (levende 3D under dragning).
        if fil != nil {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
        }
        let scene = ny.scene
        fil = await Task.detached(priority: .utility) { () -> URL? in
            let trygt = navn.replacingOccurrences(of: "/", with: "-").trimmingCharacters(in: .whitespaces)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent((trygt.isEmpty ? "Kolorist" : trygt) + ".usdz")
            do { try scene.usdz(navn: trygt).write(to: url, options: .atomic); return url } catch { return nil }
        }.value
    }
}
