import FargeKjerne
import SwiftUI

/// Fargeflaten øverst i Studio i Harmoni-modus: én flate per farge i harmonien, vist i fargerommet som er
/// valgt under «Vis også» (ICC-profil, eller nærmeste tone i et fargebibliotek), med verdiene eller tonenavnet.
/// Grunnfargen harmonien er bygd på, har ramme og merket «Grunnfarge».
struct HarmoniFlate: View {
    let farger: [Farge]
    /// Plassen til grunnfargen i `farger`.
    let grunnIndeks: Int?
    let profil: ICCProfil
    var fargebibliotek: Fargebibliotek? = nil
    var hensikt: Gjengivelseshensikt = .relativKolorimetrisk
    /// Navnet på fargerommet slik det vises i «Vis også» (står i menyen under flaten; her bare for VoiceOver).
    let romnavn: String
    /// Ekstra verdi øverst i hvert felt: fargens plass i harmoniens fargesirkel («5R 4/14», «RYB 210°» …), eller
    /// fargen i Studios fargemodell (Overgang, Toner).
    var verditekst: ((Farge) -> String)? = nil
    /// Flatene under hverandre (bred visning) i stedet for side ved side.
    var stablet = false
    /// Ramme rundt grunnfargens flate (Harmoni). Uten ramme merkes den bare med stjernen (Toner).
    var rammeRundtGrunn = true
    /// Ramme rundt alle flatene (Overgang: hele overgangen er grunnraden for lysere og mørkere toner).
    var rammeRundtAlle = false
    var velg: (Farge) -> Void = { _ in }
    var lagre: (PalettFarge) -> Void = { _ in }
    var leggIPalett: (PalettFarge) -> Void = { _ in }

    /// Fargen i valgt rom, teksten som vises og eventuell merknad (utenfor gamut / avstand til tonen).
    private struct Motpart {
        var farge: PalettFarge
        var tekst: String
        var merknad: String?
    }

    private func motpart(_ f: Farge) -> Motpart {
        if let fargebibliotek {
            guard let n = fargebibliotek.nærmeste(til: f) else {
                return Motpart(farge: PalettFarge(farge: f), tekst: String(localized: "Tomt bibliotek"))
            }
            let tone = PalettFarge(navn: n.tone.navn, farge: n.tone.farge, opphav: .bibliotek, representasjon: n.tone.representasjon,
                                  kilde: n.tone.kilde)
            return Motpart(farge: tone, tekst: n.tone.visningsnavn,
                           merknad: n.avstand < 1 ? nil : "ΔE00 \(String(format: "%.1f", n.avstand))")
        }
        let utenfor = f.erInnenfor(profil, hensikt: hensikt) ? nil : String(localized: "Utenfor gamut")
        if profil.id == ICCProfil.sRGB.id {
            let s = f.gamutKartlagt(til: .sRGB)
            let v = s.sRGB
            return Motpart(farge: PalettFarge(farge: s, representasjon: Fargerepresentasjon(
                rom: .icc(id: profil.id, navn: profil.navn), verdier: [v.r, v.g, v.b], tekst: s.hex())), tekst: s.hex(), merknad: utenfor)
        }
        guard let k = f.komponenter(i: profil, hensikt: hensikt), let g = Farge(komponenter: k, i: profil, alfa: f.alfa) else {
            return Motpart(farge: PalettFarge(farge: f), tekst: "–")
        }
        let tekst = profil.formatert(k)
        return Motpart(farge: PalettFarge(farge: g, representasjon: Fargerepresentasjon(
            rom: .icc(id: profil.id, navn: profil.navn), verdier: k, tekst: tekst)), tekst: tekst, merknad: utenfor)
    }

    var body: some View {
        let motparter = farger.map(motpart)
        GeometryReader { geo in
            let antall = max(farger.count, 1)
            // Plass til tekst? Smale flater (mange farger på iPhone) viser bare fargen og grunnfargemerket.
            let flatebredde = stablet ? geo.size.width : geo.size.width / CGFloat(antall)
            let flatehøyde = stablet ? geo.size.height / CGFloat(antall) : geo.size.height
            let visTekst = flatebredde >= 58 && flatehøyde >= 44
            // Smale flater (iPhone med mange farger): bare stjerne og varselsymbol, ikke ordene ved siden av.
            let kompakt = flatebredde < 110
            let oppsett = stablet ? AnyLayout(VStackLayout(spacing: 0)) : AnyLayout(HStackLayout(spacing: 0))
            oppsett {
                ForEach(Array(motparter.enumerated()), id: \.offset) { i, m in
                    flate(m, original: farger[i], sirkeltekst: verditekst?(farger[i]),
                          erGrunn: i == grunnIndeks, visTekst: visTekst, kompakt: kompakt,
                          hjørner: hjørner(indeks: i, antall: motparter.count))
                }
            }
        }
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: høyreHjørne, style: .continuous))
        .overlay {
            if rammeRundtAlle {
                // Samme regel som grunnfarge-sirkelen: lesbar tekstfarge når flatene er enige, ellers primærfargen.
                let kanter = Set(farger.map(\.lesbarTekstfarge))
                UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: høyreHjørne, style: .continuous)
                    .strokeBorder(kanter.count == 1 ? kanter.first!.swiftUI : Color.primary, lineWidth: 3)
                    .allowsHitTesting(false)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Harmonien i \(romnavn)"))
    }

    /// Bred visning (flatene stablet til venstre): skarpt øvre høyre hjørne mot kontrollene til høyre.
    private var høyreHjørne: CGFloat { stablet ? 0 : 20 }

    /// Avrundede hjørner for flaten på plass `indeks`: flatene ligger i en form med avrundede øvre hjørner (20 pt),
    /// så rammen rundt grunnfargen må følge de samme hjørnene for ikke å bli kuttet.
    private func hjørner(indeks: Int, antall: Int) -> (venstre: CGFloat, høyre: CGFloat) {
        let r: CGFloat = 20
        if stablet { return indeks == 0 ? (r, høyreHjørne) : (0, 0) }
        return (indeks == 0 ? r : 0, indeks == antall - 1 ? r : 0)
    }

    private func flate(_ m: Motpart, original: Farge, sirkeltekst: String?, erGrunn: Bool, visTekst: Bool, kompakt: Bool,
                       hjørner: (venstre: CGFloat, høyre: CGFloat)) -> some View {
        let tekstfarge = m.farge.farge.lesbarTekstfarge.swiftUI
        return FargeRute(farge: m.farge.farge, visTekst: false, hjørne: 0, visMerke: false,
                         lagre: { _ in lagre(m.farge) }, leggIPalett: { _ in leggIPalett(m.farge) }, palettFarge: m.farge,
                         ekstraMeny: AnyView(Button("Kopier verdier", systemImage: "doc.on.doc") { Utklippstavle.kopierTekst(m.tekst) }))
            .overlay {
                if erGrunn && rammeRundtGrunn {
                    UnevenRoundedRectangle(topLeadingRadius: hjørner.venstre, topTrailingRadius: hjørner.høyre, style: .continuous)
                        .strokeBorder(tekstfarge, lineWidth: 3)
                        .allowsHitTesting(false)
                }
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 2) {
                    if erGrunn {
                        if visTekst && !kompakt {
                            Label("Grunnfarge", systemImage: "star.fill").font(.caption2.weight(.bold))
                        } else {
                            Image(systemName: "star.fill").font(.caption2.weight(.bold))
                        }
                    }
                    if visTekst {
                        if let sirkeltekst {
                            Text(sirkeltekst).font(.caption2.monospaced().weight(.semibold)).lineLimit(2).minimumScaleFactor(0.6)
                        }
                        Text(m.tekst).font(.caption2.monospaced()).lineLimit(3).minimumScaleFactor(0.6)
                        if let merknad = m.merknad {
                            if kompakt {
                                Image(systemName: "exclamationmark.triangle.fill").font(.caption2)
                            } else {
                                Label(merknad, systemImage: "exclamationmark.triangle.fill").font(.caption2).lineLimit(1).minimumScaleFactor(0.7)
                            }
                        }
                    }
                }
                .foregroundStyle(tekstfarge)
                .padding(8)
                .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .onTapGesture { velg(original) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(erGrunn ? String(localized: "Grunnfarge: \([sirkeltekst, m.tekst].compactMap { $0 }.joined(separator: ", "))")
                                        : [sirkeltekst, m.tekst].compactMap { $0 }.joined(separator: ", "))
            .accessibilityValue(m.merknad ?? "")
            .accessibilityAddTraits(.isButton)
    }
}
