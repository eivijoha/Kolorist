import FargeKjerne
import SwiftUI

/// Studio › Toneskala: trinnene 50–950 fra den aktive fargen, med kontrasten for hvit og sort tekst på hvert trinn.
/// Samme beregning og innstillinger som «Lag toneskala» i paletten (`Toneskalavalg`).
struct ToneskalaSeksjon: View {
    let grunnfarge: Farge
    var lagre: ([PalettFarge], String) -> Void
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @AppStorage("toneskala.antall") private var antall = 11
    @AppStorage("toneskala.demping") private var demping = 0.6
    @AppStorage("toneskala.kontrast") private var kontrast = true

    private var toner: [Farge] {
        Toneskalavalg.toner(for: grunnfarge, antall: antall, demping: demping, kontrast: kontrast,
                            gamut: arbeidsbenk.gamut, begrens: arbeidsbenk.begrens)
    }

    private var navn: String { String(localized: "Toneskala \(grunnfarge.hex())") }

    private func palettfarger(_ toner: [Farge]) -> [PalettFarge] {
        toner.enumerated().map { i, f in
            PalettFarge(navn: Toneskalavalg.trinnavn(i, antall: antall), farge: f, opphav: .toneskala)
        }
    }

    var body: some View {
        let toner = toner
        Section {
            Picker("Lyshet", selection: $kontrast) {
                Text("Kontrast (L*)").tag(true)
                Text("Jevn lyshet").tag(false)
            }
            .pickerStyle(.segmented)
            Stepper("Trinn: \(antall)", value: $antall, in: 3...21)
            VStack(alignment: .leading) {
                Text("Kromademping mot ytterpunktene")
                Slider(value: $demping, in: 0...1)
            }
            Button("Legg toneskalaen i palett", systemImage: "plus.square.on.square") { lagre(palettfarger(toner), navn) }
            KopierTilMeny(farger: palettfarger(toner), navn: navn)
        } header: {
            Text("Toneskala")
        } footer: {
            KortForklaring(kontrast ? "Samme lyshet (L*) for alle kulører, så kontrasten blir lik." : "Like steg i opplevd lyshet (OKLab).") {
                Text(kontrast
                     ? "Faste trinn fra lyst til mørkt for designsystemer. Hvert trinn har samme lyshet (L*) for alle kulører, så kontrasten blir lik: med 11 trinn holder 400 minst 3:1 mot hvit (kanter og ikoner) og 600 minst 4,5:1 (tekst og knapper). «Lysere og mørkere toner» under Farge gir i stedet trinn rundt fargen selv."
                     : "Like steg i opplevd lyshet (OKLab). Kontrasten mot hvit og sort varierer litt mellom kulører.")
            }
        }
        Section {
            ForEach(Array(toner.enumerated()), id: \.offset) { i, f in
                ToneskalaTrinn(navn: Toneskalavalg.trinnavn(i, antall: antall), farge: f)
            }
        } header: {
            Text("Kontrast per trinn")
        } footer: {
            VStack(alignment: .leading, spacing: 6) {
                Text("WCAG-forhold og APCA (Lc) for hvit og sort tekst på trinnet. Fet skrift: minst 4,5:1 (all tekst).")
                MetodeHenvisning(.wcag, .apca, .oklab)
            }
        }
    }
}
