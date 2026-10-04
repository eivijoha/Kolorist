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

    var body: some View {
        if innebygd {
            // Fanen holdes i live, og @State beholder første verdi: A følger aktiv farge når den endres.
            skjema.onChange(of: arbeidsbenk.aktivFarge) { _, ny in a = ny }
        } else {
            NavigationStack {
                skjema
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) { Button("Ferdig") { lukk() } }
                    }
            }
        }
    }

    private var skjema: some View {
        let de00 = a.deltaE2000(til: b)
        return Form {
            Section {
                // De store flatene er selve velgerne: trykk for å endre, slipp en farge på dem, eller hold inne for mer.
                HStack(spacing: 0) {
                    FargeflateVelger(bokstav: "A", tittel: String(localized: "Farge A"), farge: $a, kant: .leading)
                    FargeflateVelger(bokstav: "B", tittel: String(localized: "Farge B"), farge: $b, kant: .trailing)
                }
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                // Tynn kant, så hvite og svært lyse flater synes mot kortet.
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.secondary.opacity(0.3), lineWidth: 1))
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)

                VStack(spacing: 2) {
                    Text("ΔE00 \(de00, format: .number.precision(.fractionLength(2)))")
                        .font(.largeTitle.weight(.semibold).monospacedDigit())
                    Text(Fargeavstand.tolkning(de00)).font(.headline).foregroundStyle(Color.sekundærTekst)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .accessibilityElement(children: .combine)
            }

            Section {
                let la = a.cieLab, lb = b.cieLab, ca = a.cieLCH, cb = b.cieLCH
                rad("ΔE00 (CIEDE2000)", de00, 2)
                rad("ΔE76 (CIELab)", Fargeavstand.deltaE76(la, lb), 2)
                rad("ΔE OK (OKLab)", a.avstandOK(til: b), 4)
                rad("ΔL* (lyshet)", lb.l - la.l, 2)
                rad("ΔC* (kroma)", cb.c - ca.c, 2)
                rad("Δh (kulør, grader)", kulørforskjell(ca.h, cb.h), 1)
            } header: { Group {
                Text("Detaljer")
            }.foregroundStyle(Color.sekundærTekst) } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Beregnet i CIELab D50. Tolkning: under 1 er ikke merkbart, 1–2 merkbart ved nøye sammenligning, 2–3,5 merkbart, over 5 regnes som ulike farger. Kameramålinger påvirkes av lys og hvitbalanse.")
                    MetodeHenvisning(.ciede2000, .cieLab)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Forskjell")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem {
                Button("Bytt A og B", systemImage: "arrow.left.arrow.right") { swap(&a, &b) }
            }
        }
    }

    private func rad(_ navn: LocalizedStringKey, _ verdi: Double, _ desimaler: Int) -> some View {
        LabeledContent(navn) {
            Text(verdi, format: .number.precision(.fractionLength(desimaler))).monospacedDigit()
        }
    }

    private func kulørforskjell(_ h1: Double, _ h2: Double) -> Double {
        var d = h2 - h1
        if d > 180 { d -= 360 } else if d < -180 { d += 360 }
        return d
    }
}

/// Halvparten av det store fargefeltet i «Forskjell», som også er velgeren for fargen. Merket nederst (bokstav, hex og
/// blyant) viser at flaten kan trykkes på.
private struct FargeflateVelger: View {
    let bokstav: String
    let tittel: String
    @Binding var farge: Farge
    let kant: HorizontalAlignment
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @State private var visVelger = false
    @State private var målrettet = false

    var body: some View {
        Button { visVelger = true } label: {
            farge.swiftUI
                .overlay(alignment: Alignment(horizontal: kant, vertical: .bottom)) { merke.padding(10) }
                .overlay {
                    if målrettet { Rectangle().strokeBorder(Color.accentColor, lineWidth: 3) }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(Flatetrykk())
        #if os(iOS)
        .hoverEffect(.highlight)
        #endif
        .contextMenu {
            Button("Velg farge …", systemImage: "square.grid.2x2") { visVelger = true }
            Button("Aktiv farge", systemImage: "slider.horizontal.3") { farge = arbeidsbenk.aktivFarge }
            Button("Lim inn", systemImage: "doc.on.clipboard") { if let f = Utklippstavle.limInn() { farge = f } }
            #if os(macOS)
            Button("Plukk fra skjermen", systemImage: "eyedropper") {
                Task { if let f = await Pipette.plukkFraSkjerm() { farge = f; arbeidsbenk.registrerMåling(f) } }
            }
            #endif
        }
        .tarImotFarger { farger in
            guard let f = farger.first else { return false }
            farge = f.farge
            return true
        } isTargeted: { målrettet = $0 }
        .accessibilityLabel("\(tittel): \(farge.hex())")
        .accessibilityHint("Trykk for å velge en annen farge")
        .sheet(isPresented: $visVelger) {
            LagretFargeArk(tittel: tittel) { farge = $0 }
        }
    }

    private var merke: some View {
        HStack(spacing: 6) {
            Text(bokstav).font(.headline)
            Text(farge.hex()).font(.caption.monospaced())
            Image(systemName: "pencil").font(.caption.weight(.semibold))
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: Capsule())
    }
}

/// Lett dimming mens flaten trykkes, så den kjennes som en knapp.
private struct Flatetrykk: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.75 : 1)
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
