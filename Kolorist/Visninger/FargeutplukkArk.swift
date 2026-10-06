import FargeKjerne
import SwiftUI

/// Plukk én farge med kameraet eller fra et bilde, til feltet arket ble åpnet fra (f.eks. kontrastsjekkens tekst
/// eller bakgrunn, eller aktiv farge i Studio). Samme utplukk som i Utplukk-fanen, med lyskompensasjon, men uten
/// lagring og paletter: fangsten går rett tilbake og arket lukkes. Fangede farger kommer også i «Plukkede farger».
struct FargeutplukkArk: View {
    let tittel: String
    var valgt: (Farge) -> Void
    @Environment(\.dismiss) private var lukk

    var body: some View {
        NavigationStack {
            UtplukkVisning(tittel: tittel) { farge in
                valgt(farge)
                lukk()
            }
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Avbryt") { lukk() } } }
        }
        #if os(macOS)
        .frame(minWidth: 640, idealWidth: 760, minHeight: 560, idealHeight: 680)
        #endif
    }
}

/// Knapp som åpner utplukk (kamera eller bilde) for ett fargefelt.
struct UtplukkKnapp: View {
    let tittel: String
    var valgt: (Farge) -> Void
    @State private var vis = false

    var body: some View {
        Button("Plukk med kamera eller fra bilde", systemImage: "camera") { vis = true }
            .help("Plukk med kamera eller fra bilde")
            .sheet(isPresented: $vis) { FargeutplukkArk(tittel: tittel, valgt: valgt) }
    }
}
