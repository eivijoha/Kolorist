import FargeKjerne
import SwiftUI

/// Kvadrat for én kulør (OKLCH): lyshet loddrett, metning vannrett som andel av høyeste kroma innenfor gamut ved
/// hver lyshet (grå til venstre, så mettet som kuløren kan bli til høyre). Streken for en monokromatisk harmoni
/// ligger oppå; dra endepunktene for å flytte den, og tonene fordeler seg jevnt langs streken.
struct LyshetMetningFlate: View {
    let kulør: Double
    let gamut: Gamut
    /// Fargerommet «Vis som» viser: området utenfor stripes, med grensen som kurve.
    var grense: ICCProfil? = nil
    @Binding var strek: Monokromstrek
    let toner: [Farge]
    /// Grunnfargen, vist som en liten ring for å orientere seg.
    let grunnfarge: Farge
    var velg: (Farge) -> Void = { _ in }
    /// «↑ Lyshet» og «Metning →» ved kantene (ikke inni kulørringen for tonebane, der kvadratet heller får plassen).
    var visAkser = true
    /// Grunnfargen som stiplet ring (monokrom). Ikke for tonebane, der kvadratet viser kuløren i ett av endepunktene.
    var visGrunnfarge = true
    /// Endepunktet som redigeres eller sist ble redigert (`true` = `b`), uthevet (tonebane).
    var merketSlutt: Bool? = nil
    /// Kalles når et endepunkt begynner å dras (`true` = `b`).
    var redigerer: (Bool) -> Void = { _ in }

    /// Endepunktet som dras (a eller b), valgt ved starten av bevegelsen.
    @State private var drar: WritableKeyPath<Monokromstrek, Monokromstrek.Punkt>?
    /// Om bevegelsen har startet (og om den startet nær et endepunkt).
    @State private var startet = false

    private static let rader = 96
    private let marg: CGFloat = 14
    /// Hvor langt lerretet med tonene går utenfor flaten: det merkede endepunktet (30 pt med 4 pt kant) er større enn margen.
    private static let utenfor: CGFloat = 8

    private func punkt(_ p: Monokromstrek.Punkt, i r: CGRect) -> CGPoint {
        CGPoint(x: r.minX + r.width * p.metning, y: r.maxY - r.height * p.lyshet)
    }

    var body: some View {
        GeometryReader { geo in
            let r = CGRect(origin: .zero, size: geo.size).insetBy(dx: marg, dy: marg)
            let pa = punkt(strek.a, i: r)
            let pb = punkt(strek.b, i: r)
            Canvas { ctx, _ in
                // Fargene i kvadratet: én tynn rad per lyshet, med en jevn overgang fra grå til høyeste metning.
                let radH = r.height / CGFloat(Self.rader)
                for rad in 0..<Self.rader {
                    let l = (Double(rad) + 0.5) / Double(Self.rader)
                    let maks = Farge.maksKroma(lyshet: l, kulør: kulør, i: gamut)
                    let stopp = (0...8).map { k in
                        Farge(okLCH: OKLCH(l: l, c: Double(k) / 8 * maks, h: kulør)).gamutKartlagt(til: gamut).swiftUI
                    }
                    let y = r.maxY - CGFloat(rad + 1) * radH
                    // Litt overlapp, så det ikke blir fuger mellom radene.
                    ctx.fill(Path(CGRect(x: r.minX, y: y, width: r.width, height: radH + 0.6)),
                             with: .linearGradient(Gradient(colors: stopp), startPoint: CGPoint(x: r.minX, y: y),
                                                   endPoint: CGPoint(x: r.maxX, y: y)))
                }

                // Grensen for «Vis som»-rommet: kurven der fargene går ut av rommet, og striper utenfor.
                if let grense, !grenselinje(grense).isEmpty {
                    let punkter = grenselinje(grense).map { punkt(.init(lyshet: $0.lyshet, metning: $0.metning), i: r) }
                    var utenfor = Path()
                    utenfor.move(to: CGPoint(x: r.maxX, y: r.maxY))
                    for p in punkter { utenfor.addLine(to: p) }
                    utenfor.addLine(to: CGPoint(x: r.maxX, y: r.minY))
                    utenfor.closeSubpath()
                    var klippet = ctx
                    klippet.clip(to: utenfor)
                    klippet.tegnGamutstriper(i: r, avstand: 6)
                    var kurve = Path()
                    kurve.addLines(punkter)
                    ctx.stroke(kurve, with: .color(.white.opacity(0.9)), lineWidth: 2.5)
                    ctx.stroke(kurve, with: .color(.black.opacity(0.6)), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                }

            }
            // Streken og tonene på et eget lerret som går litt utenfor flaten (se `utenfor`), så et endepunkt helt ute i
            // kanten tegnes helt; det tar ikke imot berøring, så flaten og ringen rundt beholder sine områder.
            .overlay {
                Canvas { ctx, _ in
                    ctx.translateBy(x: Self.utenfor, y: Self.utenfor)
                    // Streken og tonene langs den.
                    var linje = Path()
                    linje.move(to: pa)
                    linje.addLine(to: pb)
                    ctx.stroke(linje, with: .color(.white.opacity(0.9)), lineWidth: 3)
                    ctx.stroke(linje, with: .color(.black.opacity(0.55)), lineWidth: 1)
                    for (i, tone) in toner.enumerated() {
                        let t = toner.count > 1 ? CGFloat(i) / CGFloat(toner.count - 1) : 0
                        let p = CGPoint(x: pa.x + (pb.x - pa.x) * t, y: pa.y + (pb.y - pa.y) * t)
                        let endepunkt = i == 0 || i == toner.count - 1
                        // Med et merket endepunkt (tonebane) uthevet som grunnfargen i fargesirkelen: større og tykkere kant.
                        let merket = merketSlutt.map { endepunkt && (i == toner.count - 1) == $0 }
                        let d: CGFloat = !endepunkt ? 16 : merket == nil ? 28 : merket! ? 30 : 22
                        let kant: CGFloat = !endepunkt ? 2 : merket == nil ? 3 : merket! ? 4 : 2.5
                        let rute = CGRect(x: p.x - d / 2, y: p.y - d / 2, width: d, height: d)
                        ctx.fill(Path(ellipseIn: rute), with: .color(tone.swiftUI))
                        ctx.stroke(Path(ellipseIn: rute), with: .color(tone.lesbarTekstfarge.swiftUI), lineWidth: kant)
                    }

                    // Grunnfargen som en liten ring.
                    if visGrunnfarge {
                        let g = punkt(.fra(lyshet: grunnfarge.okLCH.l, kroma: grunnfarge.okLCH.c, kulør: kulør, gamut: gamut), i: r)
                        ctx.stroke(Path(ellipseIn: CGRect(x: g.x - 6, y: g.y - 6, width: 12, height: 12)),
                                   with: .color(grunnfarge.lesbarTekstfarge.swiftUI), style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                    }
                }
                .padding(-Self.utenfor)
                .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        if !startet {
                            startet = true
                            // Bare nær et endepunkt; et trykk andre steder (f.eks. på en tone) flytter ingenting.
                            let da = hypot(v.startLocation.x - pa.x, v.startLocation.y - pa.y)
                            let db = hypot(v.startLocation.x - pb.x, v.startLocation.y - pb.y)
                            if min(da, db) < 32 {
                                drar = da <= db ? \.a : \.b
                                redigerer(da > db)
                            }
                        }
                        guard let drar else { return }
                        let l = Double((r.maxY - v.location.y) / r.height)
                        let m = Double((v.location.x - r.minX) / r.width)
                        strek[keyPath: drar] = Monokromstrek.Punkt(lyshet: min(max(l, 0.02), 0.98), metning: m)
                    }
                    .onEnded { v in
                        // Et trykk uten bevegelse på en tone gjør den til aktiv farge.
                        if hypot(v.translation.width, v.translation.height) < 4,
                           let nærmeste = nærmesteTone(v.location, pa: pa, pb: pb), nærmeste.avstand < 18 {
                            velg(toner[nærmeste.indeks])
                        }
                        drar = nil
                        startet = false
                    }
            )
            .overlay(alignment: .bottomTrailing) {
                if visAkser {
                    Text("Metning →").font(.caption2).foregroundStyle(Color.sekundærTekst).padding(.trailing, marg).padding(.bottom, 0)
                        .offset(y: marg - 2)
                }
            }
            .overlay(alignment: .topLeading) {
                if visAkser {
                    Text("↑ Lyshet").font(.caption2).foregroundStyle(Color.sekundærTekst).padding(.leading, marg)
                        .offset(y: -2)
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text("Lyshet og metning"))
        .accessibilityValue(Text("Fra lyshet \(Int(strek.a.lyshet * 100)) % og metning \(Int(strek.a.metning * 100)) % til lyshet \(Int(strek.b.lyshet * 100)) % og metning \(Int(strek.b.metning * 100)) %"))
    }

    /// Grensekurven: for hver lyshet (nedenfra og opp) den høyeste metningen som er innenfor `grense`. Mellomlagres
    /// per kulør og rom (søket går gjennom profilen for CMYK).
    private func grenselinje(_ grense: ICCProfil) -> [Monokromstrek.Punkt] {
        let nøkkel = "\(grense.id)|\(Int((kulør * 2).rounded()))|\(gamut.rawValue)"
        if let lagret = Self.grenser[nøkkel] { return lagret }
        let rader = 48
        let linje = (0...rader).map { j -> Monokromstrek.Punkt in
            let l = min(max(Double(j) / Double(rader), 0.005), 0.995)
            func inne(_ m: Double) -> Bool { Monokromstrek.Punkt(lyshet: l, metning: m).farge(kulør: kulør, gamut: gamut).erInnenfor(grense) }
            if inne(1) { return .init(lyshet: l, metning: 1) }
            var (lav, høy) = (0.0, 1.0)
            for _ in 0..<9 { let midt = (lav + høy) / 2; if inne(midt) { lav = midt } else { høy = midt } }
            return .init(lyshet: l, metning: lav)
        }
        // Litt utjevnet (tre naboer): tabellbaserte profiler (CMYK) gir ellers en takkete kurve.
        let jevn = linje.indices.map { i -> Monokromstrek.Punkt in
            let naboer = linje[max(i - 1, 0)...min(i + 1, linje.count - 1)]
            return .init(lyshet: linje[i].lyshet, metning: naboer.map(\.metning).reduce(0, +) / Double(naboer.count))
        }
        // Ingen grense å vise når hele flaten er innenfor.
        let resultat = linje.allSatisfy { $0.metning >= 1 } ? [] : jevn
        if Self.grenser.count > 64 { Self.grenser.removeAll() }
        Self.grenser[nøkkel] = resultat
        return resultat
    }
    @MainActor private static var grenser: [String: [Monokromstrek.Punkt]] = [:]

    private func nærmesteTone(_ p: CGPoint, pa: CGPoint, pb: CGPoint) -> (indeks: Int, avstand: CGFloat)? {
        guard !toner.isEmpty else { return nil }
        return toner.indices.map { i -> (Int, CGFloat) in
            let t = toner.count > 1 ? CGFloat(i) / CGFloat(toner.count - 1) : 0
            let q = CGPoint(x: pa.x + (pb.x - pa.x) * t, y: pa.y + (pb.y - pa.y) * t)
            return (i, hypot(p.x - q.x, p.y - q.y))
        }.min { $0.1 < $1.1 }.map { (indeks: $0.0, avstand: $0.1) }
    }
}
