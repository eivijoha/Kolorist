import FargeKjerne
import QuickLook
import SwiftUI

/// Det 3D-visningen viser: farger (en harmoni eller palett, eventuelt med banen for en tonebane) eller fargerommet til
/// en ICC-profil.
enum Fargerom3DKilde: Identifiable {
    case farger(navn: String, farger: [Farge], bane: [Farge]? = nil)
    case profil(ICCProfil)

    var id: String {
        switch self {
        case .farger(let navn, let farger, _): "farger:\(navn):\(farger.map { $0.hex() }.joined())"
        case .profil(let p): "profil:\(p.id)"
        }
    }

    var navn: String {
        switch self {
        case .farger(let navn, _, _): navn
        case .profil: String(localized: "Fargerom i 3D")
        }
    }
}

/// Rommet farger vises i.
enum Fargerom3DRom: String, CaseIterable, Identifiable {
    case fargekule, cieLab
    var id: String { rawValue }
    var navn: LocalizedStringKey {
        switch self {
        case .fargekule: "Fargekule"
        case .cieLab: "CIELab"
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
    var lab = false
    /// Det samme som USDZ-scene.
    var scene = Fargerom3D.Scene()

    /// Bygger innholdet (tungt for ICC-profiler: kjøres i bakgrunnen).
    nonisolated static func lag(_ kilde: Fargerom3DKilde, rom: Fargerom3DRom, profil: ICCProfil, sammenlign: ICCProfil?,
                                gamut: Gamut) -> Fargerom3DTegning {
        var t = Fargerom3DTegning()
        func flate(_ f: Fargerom3D.Flate, opasitet: Double) {
            let farger = f.farger.map(\.swiftUI)
            for tr in f.trekanter {
                let (i, j, k) = (Int(tr.x), Int(tr.y), Int(tr.z))
                t.trekanter.append(.init(a: f.punkter[i], b: f.punkter[j], c: f.punkter[k], farge: farger[i], opasitet: opasitet))
            }
            t.scene.flater.append((f, opasitet))
        }
        func linje(_ punkter: [SIMD3<Double>], farger: [Color], bredde: CGFloat, stiplet: Bool = false) {
            for i in 1..<punkter.count {
                t.streker.append(.init(a: punkter[i - 1], b: punkter[i], farge: farger[min(i, farger.count - 1)], bredde: bredde, stiplet: stiplet))
            }
        }

        switch kilde {
        case .farger(_, let farger, let bane):
            let posisjon: (Farge) -> SIMD3<Double> = rom == .fargekule
                ? { Fargerom3D.kuleposisjon($0, gamut: gamut) } : { Fargerom3D.labposisjon($0) }
            if rom == .fargekule {
                flate(Fargerom3D.kuleflate(gamut: gamut, kolonner: 49, rader: 25), opasitet: 0.22)
                // Den grå aksen, fra sort til hvit.
                let akse = (0...10).map { SIMD3<Double>(0, Double($0) / 5 - 1, 0) }
                linje(akse, farger: (0...10).map { Color(white: Double($0) / 10) }, bredde: 3)
                let ekvator = (0...72).map { Fargerom3D.kuleposisjon(lyshet: 0.5, metning: 1, kulør: Double($0) * 5) }
                linje(ekvator, farger: [.primary.opacity(0.35)], bredde: 0.75, stiplet: true)
            } else {
                t.lab = true
                if let skall = Fargerom3D.gamutskall(profil, oppløsning: 12) {
                    for s in skall { flate(s, opasitet: 0.2) }
                }
            }
            if let bane, bane.count > 1 {
                let punkter = bane.map(posisjon)
                linje(punkter, farger: [.primary.opacity(0.8)], bredde: 2.5)
                t.scene.streker.append((punkter, Farge(lineærR: 0.2, g: 0.2, b: 0.2), 0.012))
            }
            for f in farger {
                let p = posisjon(f)
                t.punkter.append(.init(p: p, farge: f.swiftUI, størrelse: 14))
                t.scene.punkter.append((p, f, 0.06))
            }
        case .profil:
            t.lab = true
            if let skall = Fargerom3D.gamutskall(profil, oppløsning: 16) {
                for s in skall { flate(s, opasitet: 1) }
            }
            if let sammenlign, let skall = Fargerom3D.gamutskall(sammenlign, oppløsning: 12) {
                for s in skall { flate(s, opasitet: 0.22) }
            }
        }
        if t.lab {
            // Kuben (±128 a* og b*, L* 0–100) og aksene.
            let h: [SIMD3<Double>] = [[-1, -1, -1], [1, -1, -1], [1, -1, 1], [-1, -1, 1], [-1, 1, -1], [1, 1, -1], [1, 1, 1], [-1, 1, 1]]
            for (a, b) in [(0, 1), (1, 2), (2, 3), (3, 0), (4, 5), (5, 6), (6, 7), (7, 4), (0, 4), (1, 5), (2, 6), (3, 7)] {
                t.streker.append(.init(a: h[a], b: h[b], farge: .primary.opacity(0.15), bredde: 1))
            }
            let akse = (0...10).map { SIMD3<Double>(0, Double($0) / 5 - 1, 0) }
            linje(akse, farger: (0...10).map { Color(white: Double($0) / 10) }, bredde: 3)
            t.streker.append(.init(a: [-1, -1, 0], b: [1, -1, 0], farge: .primary.opacity(0.35), bredde: 1.5))
            t.streker.append(.init(a: [0, -1, -1], b: [0, -1, 1], farge: .primary.opacity(0.35), bredde: 1.5))
        }
        return t
    }
}

/// 3D-visningen: tegnet med egen projeksjon og flatene sortert bakfra (virker likt på iPhone, iPad og Mac, og takler
/// gjennomsiktige flater). Dra for å dreie, knip for å zoome.
struct Fargerom3DVisning: View {
    let tegning: Fargerom3DTegning
    @Binding var dreining: Double
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
        case punkt(CGPoint, Color, CGFloat)
        case strek(CGPoint, CGPoint, Color, CGFloat, Bool)
    }

    var body: some View {
        Canvas { ctx, størrelse in
            let senter = CGPoint(x: størrelse.width / 2, y: størrelse.height / 2)
            let skala = min(størrelse.width, størrelse.height) * (tegning.lab ? 0.3 : 0.42) * zoom
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
                elementer.append((z + 0.002, .punkt(q, p.farge, p.størrelse)))
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
                    ctx.stroke(sti, with: .color(farge), style: StrokeStyle(lineWidth: bredde, lineCap: .round, dash: stiplet ? [2, 3] : []))
                case .punkt(let p, let farge, let d):
                    let sirkel = Path(ellipseIn: CGRect(x: p.x - d / 2, y: p.y - d / 2, width: d, height: d))
                    ctx.fill(sirkel, with: .color(farge))
                    ctx.stroke(sirkel, with: .color(.white), lineWidth: 2)
                    ctx.stroke(sirkel.strokedPath(StrokeStyle(lineWidth: 2)), with: .color(.black.opacity(0.3)), lineWidth: 0.5)
                }
            }
            if tegning.lab {
                let merker: [(String, SIMD3<Double>)] = [("L* 100", [0, 1.12, 0]), ("L* 0", [0, -1.14, 0]),
                                                         ("+a*", [1.18, -1, 0]), ("−a*", [-1.18, -1, 0]),
                                                         ("+b*", [0, -1, -1.18]), ("−b*", [0, -1, 1.18])]
                for (tekst, p) in merker {
                    ctx.draw(Text(verbatim: tekst).font(.caption2.weight(.semibold)).foregroundStyle(Color.sekundærTekst),
                             at: projiser(p, senter: senter, skala: skala).0)
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { g in
                    let s = start ?? (dreining, helning)
                    start = s
                    dreining = s.dreining + g.translation.width * 0.01
                    helning = min(max(s.helning + g.translation.height * 0.01, -1.4), 1.4)
                }
                .onEnded { _ in start = nil }
        )
        .simultaneousGesture(
            MagnifyGesture()
                .onChanged { g in
                    let s = zoomStart ?? zoom
                    zoomStart = s
                    zoom = min(max(s * g.magnification, 0.6), 2.5)
                }
                .onEnded { _ in zoomStart = nil }
        )
        .accessibilityElement()
        .accessibilityLabel(Text("Fargerom i 3D"))
        .accessibilityHint(Text("Dra for å dreie"))
        .accessibilityAdjustableAction { retning in dreining += retning == .increment ? 0.2 : -0.2 }
    }
}

/// Ark med 3D-visningen: valg av rom (for farger) og profil, deling som 3D-modell (USDZ) og Hurtigvisning (AR på
/// iPhone og iPad).
struct Fargerom3DArk: View {
    let kilde: Fargerom3DKilde
    var gamut: Gamut = .displayP3
    @Environment(\.dismiss) private var lukk
    @AppStorage("fargerom3D.rom") private var rom: Fargerom3DRom = .fargekule
    @AppStorage("fargerom3D.profil") private var profilID = ICCProfil.sRGB.id
    @AppStorage("fargerom3D.sammenlign") private var sammenlignID = ""
    @State private var tegning: Fargerom3DTegning?
    @State private var dreining = 0.0
    @State private var fil: URL?
    @State private var forhåndsvisning: URL?

    private var erProfil: Bool { if case .profil = kilde { true } else { false } }
    private var visesILab: Bool { erProfil || rom == .cieLab }
    private var profiler: [ICCProfil] { ProfilBibliotek.delt.alle.filter { $0.modell == .rgb || $0.modell == .cmyk } }
    private var profil: ICCProfil { ProfilBibliotek.delt.profil(id: profilID) ?? .sRGB }
    private var sammenlign: ICCProfil? { sammenlignID.isEmpty ? nil : ProfilBibliotek.delt.profil(id: sammenlignID) }
    private var nøkkel: String { "\(kilde.id)|\(rom.rawValue)|\(profil.id)|\(sammenlignID)" }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                if !erProfil {
                    Picker("Rom", selection: $rom) {
                        ForEach(Fargerom3DRom.allCases) { Text($0.navn).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                if visesILab {
                    // Fargerommet (som skall – i heldekkende farger for en profil, som glass rundt fargene ellers),
                    // og for en profil et annet rom til sammenligning (som glass).
                    profilvelger("Fargerom", valgt: $profilID, ingen: false)
                    if erProfil { profilvelger("Sammenlign med", valgt: $sammenlignID, ingen: true) }
                }
                ZStack {
                    if let tegning {
                        Fargerom3DVisning(tegning: tegning, dreining: $dreining)
                    } else {
                        ProgressView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                Text(visesILab
                     ? "CIELab (D50): L* opp, a* og b* ut. Dra for å dreie, knip for å zoome."
                     : "Kuløren rundt den grå aksen, lysheten opp og metningen ut mot overflaten. Dra for å dreie.")
                    .font(.footnote)
                    .foregroundStyle(Color.sekundærTekst)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .navigationTitle(kilde.navn)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Ferdig") { lukk() } }
                ToolbarItemGroup(placement: .primaryAction) {
                    if let fil {
                        Button {
                            forhåndsvisning = fil
                        } label: {
                            #if os(iOS)
                            Label("Se i AR", systemImage: "arkit")
                            #else
                            Label("Hurtigvisning", systemImage: "eye")
                            #endif
                        }
                        ShareLink(item: fil) { Label("Del som 3D-modell", systemImage: "square.and.arrow.up") }
                    }
                }
            }
            .quickLookPreview($forhåndsvisning)
            .onAppear { if case .profil(let p) = kilde { profilID = p.id } }
            .task(id: nøkkel) { await bygg() }
        }
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 600)
        #endif
    }

    private func profilvelger(_ tittel: LocalizedStringKey, valgt: Binding<String>, ingen: Bool) -> some View {
        Picker(tittel, selection: valgt) {
            if ingen { Text("Ingen").tag("") }
            ForEach(profiler) { Text(ProfilBibliotek.delt.visningsnavn($0)).tag($0.id) }
        }
    }

    /// Regner ut tegningen (og USDZ-fila) i bakgrunnen.
    private func bygg() async {
        let navn = erProfil ? ProfilBibliotek.delt.visningsnavn(profil) : kilde.navn
        let (k, r, p, s, g) = (kilde, rom, profil, sammenlign, gamut)
        if case .farger(_, let farger, _) = kilde, dreining == 0 {
            // Snu kula så snittkuløren vender mot betrakteren.
            let lch = farger.map(\.okLCH).filter { $0.c > 0.02 }
            let (sx, sy) = lch.reduce((0.0, 0.0)) { ($0.0 + cos($1.h * .pi / 180), $0.1 + sin($1.h * .pi / 180)) }
            let h = lch.isEmpty ? 0 : atan2(sy, sx)
            dreining = -.pi / 2 - h
        } else if dreining == 0 {
            dreining = 215 * .pi / 180
        }
        let ny = await Task.detached(priority: .userInitiated) {
            Fargerom3DTegning.lag(k, rom: r, profil: p, sammenlign: s, gamut: g)
        }.value
        guard !Task.isCancelled else { return }
        tegning = ny
        let scene = ny.scene
        fil = await Task.detached(priority: .utility) { () -> URL? in
            let trygt = navn.replacingOccurrences(of: "/", with: "-").trimmingCharacters(in: .whitespaces)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent((trygt.isEmpty ? "Kolorist" : trygt) + ".usdz")
            do { try scene.usdz(navn: trygt).write(to: url, options: .atomic); return url } catch { return nil }
        }.value
    }
}
