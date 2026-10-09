import FargeKjerne
import SwiftData
import SwiftUI

/// Rad for å velge en farge (f.eks. forgrunn, bakgrunn, A eller B). Trykk på prøven eller «Velg»
/// åpner lagrede farger; kameraknappen plukker med kamera eller fra bilde; menyen har også lim inn og (på Mac)
/// skjermpipette.
struct FargeValgRad: View {
    let tittel: String
    @Binding var farge: Farge
    /// Verdien som vises under tittelen (hex, eller fargen i en fargemodell).
    var verditekst: (Farge) -> String = { $0.hex() }
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @State private var visVelger = false
    @State private var målrettet = false

    var body: some View {
        HStack(spacing: 12) {
            Button { visVelger = true } label: {
                FargeRute(farge: farge, visTekst: false, hjørne: 8).frame(width: 52, height: 36)
                    // Tynn kant, så hvitt/svært lyse farger synes mot lys bakgrunn (og mørke mot mørk).
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(.secondary.opacity(0.4), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(tittel): \(farge.hex()). Velg fra lagrede farger")
            VStack(alignment: .leading, spacing: 1) {
                Text(tittel).font(.caption).foregroundStyle(Color.sekundærTekst)
                Text(verditekst(farge)).font(.callout.monospaced()).lineLimit(1).minimumScaleFactor(0.7)
            }
            Spacer()
            UtplukkKnapp(tittel: tittel) { farge = $0 }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
            Button("Velg") { visVelger = true }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .lineLimit(1)
            Menu("Mer", systemImage: "ellipsis.circle") {
                FargehentingValg(farge: $farge)
            }
            .labelStyle(.iconOnly)
        }
        // Slipp en farge (fra palettkolonnen, en palett, Studio eller et annet program) for å bruke den.
        .contentShape(Rectangle())
        .tarImotFarger { farger in
            guard let f = farger.first else { return false }
            farge = f.farge
            return true
        } isTargeted: { målrettet = $0 }
        .background {
            if målrettet {
                RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color.accentColor, lineWidth: 2).padding(-4)
            }
        }
        .sheet(isPresented: $visVelger) {
            LagretFargeArk(tittel: tittel) { farge = $0 }
        }
    }
}

/// Hent en farge fra aktiv farge, utklippstavlen eller (på Mac) skjermen – felles for fargevalgene.
struct FargehentingValg: View {
    @Binding var farge: Farge
    var visAktivFarge = true
    @Environment(Arbeidsbenk.self) private var arbeidsbenk

    var body: some View {
        if visAktivFarge {
            Button("Aktiv farge", systemImage: "slider.horizontal.3") { farge = arbeidsbenk.aktivFarge }
        }
        Button("Lim inn", systemImage: "doc.on.clipboard") { if let f = Utklippstavle.limInn() { farge = f } }
        #if os(macOS)
        Button("Plukk fra skjermen", systemImage: "eyedropper") {
            Task { if let f = await Pipette.plukkFraSkjerm() { farge = f; arbeidsbenk.registrerMåling(f) } }
        }
        #endif
    }
}

/// Velg en farge rett fra en fargeflate: etiketten (prøven i flaten, eller en fargeknapp) åpner en meny med lagrede
/// farger og kjent verdi, kamera eller bilde, lim inn og (på Mac) skjermpipette. En farge som slippes på etiketten, brukes.
struct FargeVelgerMeny<Etikett: View>: View {
    let tittel: String
    @Binding var farge: Farge
    /// «Aktiv farge» i menyen – ikke når feltet selv er aktiv farge.
    var visAktivFarge = true
    /// Hvit og sort som snarveier (for bakgrunner).
    var visHvitOgSort = false
    /// Ekstra valg nederst (f.eks. «Gi navn» og «Fjern» for en skriftfarge).
    var ekstra: AnyView? = nil
    @ViewBuilder var etikett: Etikett
    @State private var visLagret = false
    @State private var visUtplukk = false
    @State private var endrerIStudio = false
    @State private var studiotilstand: EndreIStudioArk.Tilstand?
    @State private var målrettet = false

    var body: some View {
        Menu {
            Section(tittel) {
                Button("Lagrede farger eller kjent verdi …", systemImage: "swatchpalette") { visLagret = true }
                Button("Plukk med kamera eller fra bilde", systemImage: "camera") { visUtplukk = true }
                FargehentingValg(farge: $farge, visAktivFarge: visAktivFarge)
            }
            if visHvitOgSort {
                Section {
                    Button("Hvit") { farge = Farge(hex: "#FFFFFF")! }
                    Button("Sort") { farge = Farge(hex: "#000000")! }
                }
            }
            if let ekstra { Section { ekstra } }
            Section {
                Button("Endre i Studio …", systemImage: "slider.horizontal.3") {
                    studiotilstand = EndreIStudioArk.start(med: farge)
                    endrerIStudio = true
                }
                Button("Kopier \(farge.hex())", systemImage: "doc.on.doc") { Utklippstavle.kopier(farge) }
            }
        } label: {
            etikett
                .overlay {
                    if målrettet {
                        RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color.accentColor, lineWidth: 2).padding(-4)
                    }
                }
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .accessibilityLabel("\(tittel): \(farge.hex())")
        .accessibilityHint("Velg farge")
        .tarImotFarger { farger in
            guard let f = farger.first else { return false }
            farge = f.farge
            return true
        } isTargeted: { målrettet = $0 }
        .sheet(isPresented: $visLagret) { LagretFargeArk(tittel: tittel) { farge = $0 } }
        .sheet(isPresented: $visUtplukk) { FargeutplukkArk(tittel: tittel) { farge = $0 } }
        .sheet(isPresented: $endrerIStudio, onDismiss: {
            if let studiotilstand { EndreIStudioArk.slutt(studiotilstand) }
            studiotilstand = nil
        }) {
            // Studios farge settes tilbake først, så den nye fargen: feltet kan være selve den aktive fargen (Kontrast).
            EndreIStudioArk(tittel: tittel) { ny in
                if let studiotilstand { EndreIStudioArk.slutt(studiotilstand) }
                studiotilstand = nil
                farge = ny
            }
        }
    }
}

/// Studio i et ark for å endre fargen i et fargefelt: «Bruk» gir fargen tilbake til feltet. Studios egen aktive farge
/// settes tilbake når arket lukkes (`slutt`), så arbeidet der ikke går tapt.
struct EndreIStudioArk: View {
    let tittel: String
    /// Kalles med den endrede fargen når brukeren velger «Bruk».
    var bruk: (Farge) -> Void
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @Environment(\.dismiss) private var lukk

    /// Studios aktive farge før arket, som settes tilbake etterpå.
    struct Tilstand {
        let farge: Farge
        let verdier: Arbeidsbenk.Profilverdier?
    }

    /// Gjør fargen i feltet til Studios aktive farge (før arket vises) og svarer med det som skal settes tilbake.
    static func start(med farge: Farge) -> Tilstand {
        let a = Arbeidsbenk.delt
        let t = Tilstand(farge: a.aktivFarge, verdier: a.profilverdier)
        a.profilverdier = nil
        a.aktivFarge = farge
        return t
    }

    static func slutt(_ t: Tilstand) {
        Arbeidsbenk.delt.aktivFarge = t.farge
        Arbeidsbenk.delt.profilverdier = t.verdier
    }

    var body: some View {
        NavigationStack {
            FargeEditor(bareFarge: true, tittel: tittel)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Avbryt") { lukk() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Bruk") {
                            let ny = arbeidsbenk.aktivFarge
                            lukk()
                            bruk(ny)
                        }
                    }
                }
        }
        #if os(macOS)
        .frame(minWidth: 760, minHeight: 640)
        #endif
    }
}

/// Velg blant lagrede farger: aktiv farge, enkeltfarger, paletter og siste målinger.
struct LagretFargeArk: View {
    let tittel: String
    var valgt: (Farge) -> Void
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @Environment(\.dismiss) private var lukk
    @Query(sort: \LagretFarge.opprettet, order: .reverse) private var enkeltfarger: [LagretFarge]
    @Query(sort: \PalettDokument.opprettet, order: .reverse) private var paletter: [PalettDokument]

    // Toppjustert: farger uten navn står på linje med fargene som har navn under seg.
    private let rutenett = [GridItem(.adaptive(minimum: 52), spacing: 8, alignment: .top)]
    /// Kjent verdi skrevet inn: hex (sRGB), eller annen CSS-farge.
    @State private var hexTekst = ""
    private var tolket: Farge? { Fargetolk.tolk(hexTekst.trimmingCharacters(in: .whitespaces)) }

    private func brukInnskrevet() {
        guard let f = tolket else { return }
        valgt(f)
        lukk()
    }

    private var innskriving: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(tolket?.swiftUI ?? Color.clear)
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(.secondary.opacity(0.4), lineWidth: 1))
                .frame(width: 44, height: 36)
            TextField("Hex, f.eks. #2F7FD8", text: $hexTekst)
                .font(.body.monospaced())
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.characters)
                #endif
                .submitLabel(.done)
                .onSubmit(brukInnskrevet)
                .textFieldStyle(.roundedBorder)
            Button("Bruk", action: brukInnskrevet)
                .buttonStyle(.borderedProminent)
                .disabled(tolket == nil)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Kjent verdi", systemImage: "number").font(.headline)
                        innskriving
                        Text("sRGB-hex som #2F7FD8 eller 2F7FD8; CSS-farger som oklch(…) og rgb(…) går også.")
                            .font(.caption)
                            .foregroundStyle(Color.sekundærTekst)
                    }
                    gruppe(String(localized: "Aktiv farge"), [PalettFarge(farge: arbeidsbenk.aktivFarge)])
                    if !enkeltfarger.isEmpty {
                        gruppe(String(localized: "Enkeltfarger"), enkeltfarger.map(\.palettFarge), symbol: "square.fill")
                    }
                    ForEach(paletter) { p in
                        if !p.farger.isEmpty {
                            gruppe(p.navn.isEmpty ? String(localized: "Uten navn") : p.navn, p.farger, symbol: "swatchpalette")
                        }
                    }
                    if !arbeidsbenk.målinger.isEmpty {
                        gruppe(String(localized: "Siste målinger"), arbeidsbenk.målinger.reversed().map { PalettFarge(farge: $0) },
                               symbol: "eyedropper")
                    }
                    if enkeltfarger.isEmpty && paletter.allSatisfy({ $0.farger.isEmpty }) {
                        Text("Ingen lagrede farger ennå. Lagre farger fra Studio eller Utplukk, eller lag en palett.")
                            .font(.callout)
                            .foregroundStyle(Color.sekundærTekst)
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: "Velg farge – \(tittel)"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Avbryt") { lukk() } } }
        }
        .presentationDetents([.medium, .large])
    }

    private func gruppe(_ navn: String, _ farger: [PalettFarge], symbol: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if let symbol { Label(navn, systemImage: symbol) } else { Text(navn) }
            }
            .font(.headline)
            LazyVGrid(columns: rutenett, alignment: .leading, spacing: 8) {
                ForEach(farger) { pf in
                    Button {
                        valgt(pf.farge)
                        lukk()
                    } label: {
                        VStack(spacing: 3) {
                            FargeRute(farge: pf.farge, visTekst: false, hjørne: 8)
                                .frame(height: 52)
                                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(.secondary.opacity(0.3), lineWidth: 1))
                            if !pf.navn.isEmpty {
                                Text(pf.navn).font(.caption2).lineLimit(1).foregroundStyle(Color.sekundærTekst)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(pf.visningsnavn), \(pf.farge.hex())")
                }
            }
        }
    }
}
