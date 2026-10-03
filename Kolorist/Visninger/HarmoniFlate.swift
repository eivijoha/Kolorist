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
    /// Navnet på fargerommet slik det vises i «Vis også».
    let romnavn: String
    /// Flatene under hverandre (bred visning) i stedet for side ved side.
    var stablet = false
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
            let tone = PalettFarge(navn: n.tone.navn, farge: n.tone.farge, opphav: .bibliotek, representasjon: n.tone.representasjon)
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
                    flate(m, original: farger[i], erGrunn: i == grunnIndeks, visTekst: visTekst, kompakt: kompakt)
                }
            }
        }
        .overlay(alignment: .topLeading) {
            // Fargerommet flatene er vist i – én gang for hele harmonien.
            Text(romnavn)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(.regularMaterial, in: Capsule())
                .padding(8)
                .allowsHitTesting(false)
        }
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Harmonien i \(romnavn)"))
    }

    private func flate(_ m: Motpart, original: Farge, erGrunn: Bool, visTekst: Bool, kompakt: Bool) -> some View {
        let tekstfarge = m.farge.farge.lesbarTekstfarge.swiftUI
        return FargeRute(farge: m.farge.farge, visTekst: false, hjørne: 0, visMerke: false,
                         lagre: { _ in lagre(m.farge) }, leggIPalett: { _ in leggIPalett(m.farge) }, palettFarge: m.farge,
                         ekstraMeny: AnyView(Button("Kopier verdier", systemImage: "doc.on.doc") { Utklippstavle.kopierTekst(m.tekst) }))
            .overlay {
                if erGrunn {
                    Rectangle().strokeBorder(tekstfarge, lineWidth: 3).allowsHitTesting(false)
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
            .accessibilityLabel(erGrunn ? String(localized: "Grunnfarge: \(m.tekst)") : m.tekst)
            .accessibilityValue(m.merknad ?? "")
            .accessibilityAddTraits(.isButton)
    }
}
