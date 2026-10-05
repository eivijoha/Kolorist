import SwiftUI

/// Hvilke mål «Kopier til» viser, og i hvilken rekkefølge – felles for farger og gradienter (målene har samme id-er).
/// Lagres per enhet. Nye mål (fra en nyere versjon) havner nederst og vises.
enum Kopiinnstillinger {
    static let rekkefølgeNøkkel = "kopimål.rekkefølge"
    static let skjultNøkkel = "kopimål.skjult"

    /// Id-ene i lagret rekkefølge (ukjente til slutt, i standardrekkefølgen).
    static func ordnet(_ ider: [String], rekkefølge: String) -> [String] {
        let lagret = rekkefølge.split(separator: ",").map(String.init)
        return lagret.filter(ider.contains) + ider.filter { !lagret.contains($0) }
    }

    /// Id-ene som skal vises i menyene, i rekkefølge.
    static func synlige(_ ider: [String], rekkefølge: String, skjult: String) -> [String] {
        let skjulte = Set(skjult.split(separator: ",").map(String.init))
        return ordnet(ider, rekkefølge: rekkefølge).filter { !skjulte.contains($0) }
    }
}

/// Åpner «Tilpass Kopier til» fra en meny hvor som helst (arket vises fra rotvisningen).
@Observable
final class Kopitilpasning {
    static let delt = Kopitilpasning()
    var vises = false
}

/// Siste valg i «Kopier til»-menyene: tilpass listen.
struct TilpassKopimålKnapp: View {
    var body: some View {
        Button("Tilpass listen …", systemImage: "slider.horizontal.3") { Kopitilpasning.delt.vises = true }
    }
}

/// Slå mål av og på, og dra dem i den rekkefølgen de skal stå i «Kopier til».
struct KopimålArk: View {
    @AppStorage(Kopiinnstillinger.rekkefølgeNøkkel) private var rekkefølge = ""
    @AppStorage(Kopiinnstillinger.skjultNøkkel) private var skjult = ""
    @Environment(\.dismiss) private var lukk

    private var mål: [Kopimål] {
        Kopiinnstillinger.ordnet(Kopimål.allCases.map(\.rawValue), rekkefølge: rekkefølge).compactMap(Kopimål.init(rawValue:))
    }

    private func synlig(_ m: Kopimål) -> Binding<Bool> {
        Binding(get: { !skjult.split(separator: ",").contains(Substring(m.rawValue)) }, set: { vis in
            var sett = Set(skjult.split(separator: ",").map(String.init))
            if vis { sett.remove(m.rawValue) } else { sett.insert(m.rawValue) }
            skjult = Kopimål.allCases.map(\.rawValue).filter(sett.contains).joined(separator: ",")
        })
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(mål) { m in
                        Toggle(isOn: synlig(m)) {
                            Label { Text(m.navn); Text(m.forklaring) } icon: { Image(systemName: m.symbol) }
                        }
                    }
                    .onMove { fra, til in
                        var ider = mål.map(\.rawValue)
                        ider.move(fromOffsets: fra, toOffset: til)
                        rekkefølge = ider.joined(separator: ",")
                    }
                } footer: {
                    Text("Målene som er slått på, vises i «Kopier til» for farger, paletter og gradienter, i denne rekkefølgen. Dra for å endre rekkefølgen.")
                }
                Section {
                    Button("Tilbakestill", systemImage: "arrow.uturn.backward") {
                        rekkefølge = ""
                        skjult = ""
                    }
                    .disabled(rekkefølge.isEmpty && skjult.isEmpty)
                }
            }
            #if os(iOS)
            // Dra-håndtak på radene; brytere og knapper virker fortsatt.
            .environment(\.editMode, .constant(.active))
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .navigationTitle("Kopier til")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Ferdig") { lukk() } } }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 520)
        #endif
    }
}
