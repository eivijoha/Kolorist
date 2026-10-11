import FargeKjerne
import SwiftUI

/// Sammenligner to målte farger med ΔE2000 (og ΔE76 / ΔE_OK for referanse).
/// Fargene kan komme fra kamera, bilde, skjermpipette (macOS), aktiv farge eller utklippstavlen.
struct SammenligningVisning: View {
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @Environment(\.dismiss) private var lukk
    @State var a: Farge
    @State var b: Farge
    /// Innebygd i en fane (uten egen navigasjon og «Ferdig»), i stedet for som ark.
    var innebygd = false

    @Environment(\.presentasjonsmodus) private var presentasjon

    var body: some View {
        if innebygd {
            // Fanen holdes i live, og @State beholder første verdi: A følger aktiv farge når den endres.
            fane.onChange(of: arbeidsbenk.aktivFarge) { _, ny in a = ny }
        } else {
            NavigationStack {
                ScrollView {
                    kort(bred: false)
                    detaljer.padding(.horizontal, 16)
                }
                .background(Color.skjemabakgrunn)
                .navigationTitle(Text(verbatim: "ΔE"))
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Ferdig") { lukk() } } }
            }
        }
    }

    /// Som Kontrast: kortet med verdien og de to fargene øverst (til venstre i bred visning), detaljene under.
    private var fane: some View {
        GeometryReader { geo in
            let bred = Breddeoppsett.erBred(geo.size)
            let oppsett = bred ? AnyLayout(HStackLayout(spacing: 0)) : AnyLayout(VStackLayout(spacing: 0))
            oppsett {
                kort(bred: bred).frame(width: bred ? geo.size.width / 2 : nil)
                Form { detaljseksjon }
                    .formStyle(.grouped)
                    #if os(iOS)
                    .listSectionSpacing(.compact)
                    #endif
                    .contentMargins(.top, 0, for: .scrollContent)
            }
            .background(Color.skjemabakgrunn)
        }
        .navigationTitle(Text(verbatim: "ΔE"))
    }

    /// Verdien og hvor synlig forskjellen er over de to fargene, som i kontrastsjekken. Fargene er likeverdige flater med
    /// rette hjørner der de møtes; trykk på en flate for å velge fargen.
    private func kort(bred: Bool) -> some View {
        let de00 = a.deltaE2000(til: b)
        return VStack(spacing: 0) {
            VStack(spacing: 0) {
                topptekst(de00)
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 0) {
                    felt("A", String(localized: "Farge A"), farge: $a)
                    felt("B", String(localized: "Farge B"), farge: $b)
                }
            }
            .clipShape(Kortform.fargepanel(bred: bred))
            .frame(height: bred ? nil : (presentasjon ? 330 : 250))
            .frame(maxHeight: bred ? .infinity : nil)
        }
        .frame(maxWidth: .infinity)
        .background(Color.kortbakgrunn, in: Kortform.fargepanel(bred: bred))
        .padding(.leading, 16)
        .padding(.trailing, bred ? 0 : 16)
        .padding(.top, bred ? 16 : 4)
        .padding(.bottom, bred ? 16 : 8)
    }

    /// ΔE00 stort, med hvor synlig forskjellen er til høyre (på samme grunnlinje), og forskjellen i lyshet, kroma og
    /// kulør under.
    private func topptekst(_ de00: Double) -> some View {
        let la = a.cieLCH, lb = b.cieLCH
        let detalj = String(localized: "ΔL* \(lb.l - la.l, format: .number.precision(.fractionLength(1))) · ΔC* \(lb.c - la.c, format: .number.precision(.fractionLength(1))) · Δh \(kulørforskjell(la.h, lb.h), format: .number.precision(.fractionLength(0)))°")
        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(verbatim: "ΔE00").koloristFont(.title2, weight: .semibold).foregroundStyle(Color.sekundærTekst)
                Text(de00, format: .number.precision(.fractionLength(2)))
                    .koloristFont(.largeTitle, weight: .bold).monospacedDigit()
                    .fixedSize()
                    .layoutPriority(1)
                Text(Fargeavstand.tolkning(de00)).koloristFont(.headline).lineLimit(2).minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }
            Text(detalj).koloristFont(.subheadline).opacity(0.8).lineLimit(1).minimumScaleFactor(0.8)
        }
        .foregroundStyle(Color.primary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "ΔE00 \(de00.formatted(.number.precision(.fractionLength(2)))), \(Fargeavstand.tolkning(de00)). \(detalj)"))
    }

    /// Én av de to fargene: bokstav og hex i flatens farge. Hele flaten åpner valgene for fargen.
    private func felt(_ bokstav: String, _ tittel: String, farge: Binding<Farge>) -> some View {
        let lesbar = farge.wrappedValue.lesbarTekstfarge.swiftUI
        // Fargen som eget lag bak menyen, så flatene møtes i en rett kant (menyen avrunder på iOS 26).
        return ZStack {
            farge.wrappedValue.swiftUI
            FargeVelgerMeny(tittel: tittel, farge: farge, visHvitOgSort: true) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: bokstav).koloristFont(.title2, weight: .bold)
                    Spacer(minLength: 4)
                    HStack(spacing: 4) {
                        Text(farge.wrappedValue.hex()).koloristFont(.caption, design: .monospaced)
                        Image(systemName: "chevron.up.chevron.down").font(.caption2)
                    }
                    .opacity(0.85)
                }
                .foregroundStyle(lesbar)
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .contentShape(Rectangle())
            }
        }
        .tarImotFarger { farger in
            guard let f = farger.first else { return false }
            farge.wrappedValue = f.farge
            return true
        }
    }

    private var detaljer: some View {
        Form { detaljseksjon }.formStyle(.grouped).frame(minHeight: 480).scrollDisabled(true)
    }

    /// Verdiene i detaljlista: navn, verdi og antall desimaler.
    private var verdier: [(navn: String, verdi: Double, desimaler: Int)] {
        let la = a.cieLab, lb = b.cieLab, ca = a.cieLCH, cb = b.cieLCH
        return [
            (String(localized: "ΔE00 (CIEDE2000)"), a.deltaE2000(til: b), 2),
            (String(localized: "ΔE76 (CIELab)"), Fargeavstand.deltaE76(la, lb), 2),
            (String(localized: "ΔE OK (OKLab)"), a.avstandOK(til: b), 4),
            (String(localized: "ΔL* (lyshet)"), lb.l - la.l, 2),
            (String(localized: "ΔC* (kroma)"), cb.c - ca.c, 2),
            (String(localized: "Δh (kulør, grader)"), kulørforskjell(ca.h, cb.h), 1),
        ]
    }

    private func tall(_ verdi: Double, _ desimaler: Int) -> String {
        verdi.formatted(.number.precision(.fractionLength(desimaler)))
    }

    /// Alle verdiene som rapport: tabellen kopieres med tabulatorer mellom kolonnene, så den limes inn som celler i
    /// regneark og tabeller, og kan deles som lenke og skrives ut.
    private var rapport: Fargerapport {
        let tabell = [[String(localized: "Farge A"), a.hex()], [String(localized: "Farge B"), b.hex()]]
            + verdier.map { [$0.navn, tall($0.verdi, $0.desimaler)] }
        return Fargerapport(navn: "", farger: [PalettFarge(farge: a), PalettFarge(farge: b)],
                            rapport: DeltRapport(slag: "deltaE", tittel: String(localized: "Fargeforskjell (ΔE)"),
                                                 par: [DeltRapportpar(a: 0, b: 1, tekst: "ΔE00 \(tall(a.deltaE2000(til: b), 2))")],
                                                 tabell: tabell))
    }

    @ViewBuilder private var detaljseksjon: some View {
        Section {
            ForEach(verdier, id: \.navn) { d in
                LabeledContent(d.navn) {
                    Text(tall(d.verdi, d.desimaler)).monospacedDigit()
                }
                .contextMenu {
                    Button("Kopier verdi", systemImage: "doc.on.doc") { Utklippstavle.kopierTekst(tall(d.verdi, d.desimaler)) }
                    Divider()
                    RapportValg(rapport: rapport)
                }
            }
            RapportValg(rapport: rapport)
        } header: {
            Text("Detaljer")
        } footer: {
            VStack(alignment: .leading, spacing: 6) {
                KortForklaring("Under 1 er ikke merkbart, over 5 regnes som ulike farger.") {
                    Text("Beregnet i CIELab D50. Tolkning: under 1 er ikke merkbart, 1–2 merkbart ved nøye sammenligning, 2–3,5 merkbart, over 5 regnes som ulike farger. Kameramålinger påvirkes av lys og hvitbalanse. Trykk og hold (høyreklikk på Mac) på en verdi for å kopiere den.")
                }
                MetodeHenvisning(.ciede2000, .cieLab)
            }
        }
    }

    private func kulørforskjell(_ h1: Double, _ h2: Double) -> Double {
        var d = h2 - h1
        if d > 180 { d -= 360 } else if d < -180 { d += 360 }
        return d
    }
}

/// Viser ΔE2000 mellom de to siste fangede fargene; trykk åpner full sammenligning.
struct DeltaEMerke: View {
    let fanget: [Farge]
    @Environment(Arbeidsbenk.self) private var arbeidsbenk

    var body: some View {
        if fanget.count >= 2 {
            let a = fanget[fanget.count - 2], b = fanget[fanget.count - 1]
            let d = a.deltaE2000(til: b)
            Button {
                arbeidsbenk.sammenlign(a, b)
            } label: {
                HStack(spacing: 8) {
                    HStack(spacing: 0) { a.swiftUI; b.swiftUI }
                        .frame(width: 36, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    Text("ΔE00 \(d, format: .number.precision(.fractionLength(2))) · \(Fargeavstand.tolkning(d))")
                        .font(.callout.monospacedDigit())
                    Image(systemName: "chevron.right").font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Forskjell mellom de to siste fargene: Delta E 2000 \(d.formatted(.number.precision(.fractionLength(1)))), \(Fargeavstand.tolkning(d))")
        }
    }
}
