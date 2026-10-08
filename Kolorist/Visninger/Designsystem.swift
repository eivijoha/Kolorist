import FargeKjerne
import SwiftData
import SwiftUI
#if os(macOS)
import AppKit
#endif

// Designsystem fra en palett (fra 1.3): roller, skalaer, komponenter med kontrollpunkter, og eksport. Valgfritt – inngangen
// er «Lag designsystem» i palettens meny, og seksjonen i Paletter vises bare når det finnes designsystemer.

/// Åpner et designsystem i palettlistens navigasjon. Alltid lik ved sammenligning: handlingen er den samme hver gang
/// (den legger til i palettlistens sti), så visningene som leser den, tegnes ikke på nytt for en ny closure.
struct ÅpneDesignsystem: Equatable {
    let åpne: (DesignsystemDokument) -> Void

    func callAsFunction(_ d: DesignsystemDokument) { åpne(d) }

    static func == (_: ÅpneDesignsystem, _: ÅpneDesignsystem) -> Bool { true }
}

extension EnvironmentValues {
    /// Satt av `PalettListe`.
    @Entry var åpneDesignsystem: ÅpneDesignsystem? = nil
}

/// Et nytt designsystem fra en palett (rollene fordeles automatisk). Det lagres ikke: visningen er en forhåndsvisning til
/// brukeren trykker «Lagre» (se `DesignsystemVisning`).
@MainActor
func nyttDesignsystem(fra p: PalettDokument) -> DesignsystemDokument {
    DesignsystemDokument(Designsystem(fra: p.palett), palettID: p.id)
}

extension Designrolle {
    var navn: LocalizedStringKey {
        switch self {
        case .aksent: "Aksent"
        case .sekundær: "Sekundær"
        case .nøytral: "Nøytral"
        case .feil: "Feil"
        case .suksess: "Suksess"
        case .advarsel: "Advarsel"
        }
    }

    var bruk: LocalizedStringKey {
        switch self {
        case .aksent: "Hovedknapp, lenker, valgt fane og fokusring"
        case .sekundær: "Brytere som er på"
        case .nøytral: "Bakgrunn, flater, tekst, kanter og skillelinjer"
        case .feil: "Feilmeldinger og slettehandlinger"
        case .suksess: "Bekreftelser"
        case .advarsel: "Advarsler: gul flate med mørk tekst"
        }
    }

    /// Fargen rollen har i et tema (den som vises for rollen i hver modus).
    func farge(i tema: Designtema) -> Farge {
        switch self {
        case .aksent: tema.aksent
        case .sekundær: tema.sekundær
        case .nøytral: tema.kant
        case .feil, .suksess: tema.status(self).tekst
        case .advarsel: tema.status(self).flate
        }
    }
}

extension Designmodus {
    var kortnavn: LocalizedStringKey {
        switch self {
        case .lys: "Lys"
        case .mørk: "Mørk"
        case .lysØktKontrast: "Lys+"
        case .mørkØktKontrast: "Mørk+"
        }
    }
}

extension Komponenttilstand {
    var navn: LocalizedStringKey {
        switch self {
        case .normal: "Normal"
        case .trykket: "Trykket"
        case .fokus: "Fokus"
        case .deaktivert: "Deaktivert"
        }
    }
}

extension Komponentpar {
    var navn: LocalizedStringKey {
        switch self {
        case .tekst: "Tekst på flate"
        case .sekundærtekst: "Hjelpetekst på bakgrunnen"
        case .plassholder: "Plassholder i tekstfelt"
        case .lenke: "Lenke på bakgrunnen"
        case .destruktiv: "Slettehandling på bakgrunnen"
        case .knappetekst: "Tekst på hovedknapp"
        case .tonetKnapp: "Tekst på sekundærknapp"
        case .feltkant: "Kant på tekstfelt"
        case .bryter: "Bryter som er på"
        case .fokusring: "Fokusring"
        case .feilvarsel: "Feilmelding"
        case .suksessvarsel: "Bekreftelse"
        case .advarselvarsel: "Advarsel"
        case .egenVarsel: "Varsel"
        case .egenKnapp: "Tekst på knapp"
        case .egenEtikettkant: "Kant på etikett"
        case .egenEtikettekst: "Tekst på etikett"
        }
    }

    /// Navnet, med rollen for egne roller («Varsel: info»).
    func navn(rolle: String?) -> Text {
        guard let rolle else { return Text(navn) }
        return Text("\(Text(navn)): \(rolle)")
    }
}

// MARK: - Seksjonen i Paletter

/// Designsystemene i palettoversikten (iPhone, mindre iPader og smale Mac-vinduer). Vises bare når det finnes minst ett.
struct DesignsystemSeksjon: View {
    @Query private var designsystemer: [DesignsystemDokument]
    let åpne: (DesignsystemDokument) -> Void

    var body: some View {
        if !designsystemer.isEmpty {
            Listeseksjon("designsystemer", tittel: "Designsystemer") {
                Text("\(designsystemer.count)").font(.callout).foregroundStyle(Color.sekundærTekst).monospacedDigit()
            } innhold: {
                DesignsystemRutenett(åpne: åpne)
            }
        }
    }
}

/// Kortene for designsystemene: trykk for å åpne, sveip fra høyre eller menyen for å slette.
struct DesignsystemRutenett: View {
    @Query(sort: \DesignsystemDokument.opprettet, order: .reverse) private var designsystemer: [DesignsystemDokument]
    @Environment(\.modelContext) private var kontekst
    let åpne: (DesignsystemDokument) -> Void
    @State private var slettes: DesignsystemDokument?

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 12, alignment: .top)], alignment: .leading, spacing: 12) {
            ForEach(designsystemer) { d in
                // Sveip fra høyre for å slette, som palettene.
                SveipForÅSlette(slett: { slettes = d }) {
                    DesignsystemKort(dokument: d)
                        .onTapGesture { åpne(d) }
                        .contextMenu {
                            Button("Slett designsystem", systemImage: "trash", role: .destructive) { slettes = d }
                        }
                }
            }
        }
        .alert("Slette designsystemet «\(slettes?.navn ?? "")»?", isPresented: Binding(get: { slettes != nil }, set: { if !$0 { slettes = nil } })) {
            Button("Avbryt", role: .cancel) {}
            Button("Slett", role: .destructive) {
                if let d = slettes { kontekst.angresteg("Slett designsystem") { kontekst.delete(d) } }
            }
        } message: { Text("Paletten det ble laget fra, beholdes.") }
    }
}

/// Designsystemer som egen fane der palettene ligger i en spalte (Mac med bredt vindu, 13"-iPad i liggende format), så
/// designsystemet får hele bredden. Forhåndsvisninger fra «Lag designsystem» åpnes her.
struct DesignsystemFane: View {
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @State private var sti: [DesignsystemDokument] = []

    var body: some View {
        NavigationStack(path: $sti) {
            ScrollView {
                DesignsystemRutenett { sti = [$0] }
                    .padding()
            }
            .background(Color(white: 0.5).opacity(0.06))
            .navigationTitle("Designsystemer")
            .navigationDestination(for: DesignsystemDokument.self) { DesignsystemVisning(dokument: $0) }
        }
        .onChange(of: arbeidsbenk.designsystemSomÅpnes, initial: true) { _, d in
            guard let d else { return }
            sti = [d]
            arbeidsbenk.designsystemSomÅpnes = nil
        }
        .onChange(of: sti) { _, ny in
            // Tilbake fra en forhåndsvisning: den er enten lagret (og står i lista) eller forkastet.
            if ny.isEmpty { arbeidsbenk.designsystemUtkast = nil }
        }
    }
}

/// Kort for et designsystem: navnet, og aksent, tekst og flater i lys og mørk modus.
struct DesignsystemKort: View {
    let dokument: DesignsystemDokument

    var body: some View {
        let ds = dokument.designsystem
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(verbatim: dokument.navn.isEmpty ? String(localized: "Uten navn") : dokument.navn)
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                HStack(spacing: 6) {
                    ForEach([Designmodus.lys, .mørk]) { m in
                        let t = ds.tema(m)
                        HStack(spacing: 4) {
                            Text("Aa").font(.caption.weight(.semibold)).foregroundStyle(t.tekst.swiftUI)
                            Capsule().fill(t.aksent.swiftUI).frame(width: 26, height: 12)
                        }
                        .padding(.horizontal, 8)
                        .frame(height: 30)
                        .background(t.flate.swiftUI, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Color.primary.opacity(0.1)))
                    }
                    ForEach(Designrolle.allCases.map { ds[$0] } + ds.egneRoller.map(\.farge), id: \.self) { f in
                        RoundedRectangle(cornerRadius: 4, style: .continuous).fill(f.swiftUI).frame(width: 14, height: 30)
                    }
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Color.tertiærTekst)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Designsystemet

struct DesignsystemVisning: View {
    @Bindable var dokument: DesignsystemDokument
    @Environment(\.modelContext) private var kontekst
    @Environment(\.dismiss) private var lukk
    @Query private var paletter: [PalettDokument]

    enum Del: String, CaseIterable, Identifiable {
        case komponenter, roller, skalaer
        var id: String { rawValue }
        var navn: LocalizedStringKey {
            switch self {
            case .komponenter: "Komponenter"
            case .roller: "Roller"
            case .skalaer: "Skalaer"
            }
        }
    }

    @AppStorage("designsystem.del") private var del: Del = .komponenter
    @AppStorage("designsystem.mørk") private var mørk = false
    @AppStorage("designsystem.øktKontrast") private var øktKontrast = false
    @State private var tilstand: Komponenttilstand = .normal
    @State private var visEksport = false
    @State private var slettSpørsmål = false
    @State private var omdøper = false
    @State private var nyttNavn = ""
    /// Lagret i denne visningen (bekreftelsen står så lenge visningen er åpen).
    @State private var nettoppLagret = false
    /// Lagret i lageret; ellers er visningen en forhåndsvisning. Egen tilstand, siden SwiftUI ikke følger
    /// `modelContext` på modellen.
    @State private var erLagret: Bool
    @State private var lagrer = false
    /// Navnevalget før lagring.
    @State private var velgerNavn = false

    init(dokument: DesignsystemDokument) {
        self.dokument = dokument
        _erLagret = State(initialValue: dokument.modelContext != nil)
    }

    /// Paletten designsystemet ble laget fra, når den finnes.
    private var palett: PalettDokument? { paletter.first { $0.id == dokument.palettID } }

    var body: some View {
        let ds = dokument.designsystem
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(verbatim: dokument.navn.isEmpty ? String(localized: "Uten navn") : dokument.navn)
                    .font(.title2.weight(.semibold))
                    .padding(.top, 12)
                lagringsstatus
                Picker("Vis", selection: $del) {
                    ForEach(Del.allCases) { Text($0.navn).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                switch del {
                case .komponenter: komponenter(ds)
                case .roller: DesignsystemRoller(dokument: dokument, palett: palett)
                case .skalaer: DesignsystemSkalaer(designsystem: ds)
                }
                MetodeHenvisning(.designsystem, .wcag, .oklab)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Color(white: 0.5).opacity(0.06))
        .navigationTitle("")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if del == .komponenter { modusvalg }
        }
        .toolbar {
            if !erLagret {
                ToolbarItem(placement: .confirmationAction) {
                    if lagrer {
                        ProgressView()
                    } else {
                        Button("Lagre", action: spørOmNavn)
                            .help("Lagre designsystemet under Designsystemer i Paletter")
                    }
                }
            }
            ToolbarItem {
                Button("Eksporter …", systemImage: "square.and.arrow.up") { visEksport = true }
                    .help("Eksporter designsystemet")
            }
            ToolbarItem(placement: .secondaryAction) {
                Button("Gi nytt navn …", systemImage: "character.cursor.ibeam") {
                    nyttNavn = dokument.navn
                    omdøper = true
                }
            }
            if erLagret {
                ToolbarItem(placement: .secondaryAction) {
                    Button("Slett designsystem", systemImage: "trash", role: .destructive) { slettSpørsmål = true }
                }
            }
        }
        .sheet(isPresented: $visEksport) { DesignsystemEksportArk(designsystem: dokument.designsystem, navn: dokument.navn) }
        .alert("Gi nytt navn", isPresented: $omdøper) {
            TextField("Navn", text: $nyttNavn)
            Button("Avbryt", role: .cancel) {}
            Button("Lagre") {
                let navn = nyttNavn.trimmingCharacters(in: .whitespacesAndNewlines)
                if !navn.isEmpty { kontekst.angresteg("Gi nytt navn") { dokument.navn = navn } }
            }
        }
        .alert("Lagre designsystemet", isPresented: $velgerNavn) {
            TextField("Navn", text: $nyttNavn)
            Button("Avbryt", role: .cancel) {}
            Button("Lagre") { lagre(som: nyttNavn) }
        } message: {
            Text("Gi designsystemet et navn. Du finner det under Designsystemer i Paletter.")
        }
        .alert("Slette designsystemet?", isPresented: $slettSpørsmål) {
            Button("Avbryt", role: .cancel) {}
            Button("Slett", role: .destructive) {
                let d = dokument
                lukk()
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(350))
                    kontekst.angresteg("Slett designsystem") { kontekst.delete(d) }
                }
            }
        } message: { Text("Paletten det ble laget fra, beholdes.") }
    }

    private var modus: Designmodus { Designmodus(mørk: mørk, øktKontrast: øktKontrast) }

    private func spørOmNavn() {
        nyttNavn = dokument.navn
        velgerNavn = true
    }

    /// Lagrer med valgt navn. Spinneren vises først, så lagringen skjer i neste runde.
    private func lagre(som navn: String) {
        let navn = navn.trimmingCharacters(in: .whitespacesAndNewlines)
        lagrer = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(80))
            kontekst.angresteg("Lagre designsystem") {
                if !navn.isEmpty { dokument.navn = navn }
                kontekst.insert(dokument)
            }
            try? kontekst.save()
            withAnimation {
                lagrer = false
                erLagret = true
                nettoppLagret = true
            }
        }
    }

    /// Forhåndsvisning med «Lagre», eller bekreftelse rett etter lagring.
    @ViewBuilder private var lagringsstatus: some View {
        if !erLagret {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: "eye")
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Forhåndsvisning. Se gjennom rollene og komponentene, og lagre for å beholde designsystemet.")
                        .font(.callout)
                    if lagrer {
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.small)
                            Text("Lagrer …").font(.callout).foregroundStyle(Color.sekundærTekst)
                        }
                    } else {
                        Button("Lagre designsystemet …", systemImage: "checkmark", action: spørOmNavn)
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else if nettoppLagret {
            Label("Lagret. Du finner det under Designsystemer i Paletter.", systemImage: "checkmark.circle.fill")
                .font(.callout)
                .foregroundStyle(Color.primary)
                .symbolRenderingMode(.multicolor)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .transition(.opacity)
        }
    }

    /// Komponentene i valgt modus og tilstand, med kontrollpunktene under.
    @ViewBuilder private func komponenter(_ ds: Designsystem) -> some View {
        let tema = ds.tema(modus)
        let sjekker = tema.sjekker(tilstand)
        let feiler = sjekker.filter { !$0.består }.count
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text(feiler == 0 ? "Alle fargepar holder kravet" : "\(feiler) fargepar holder ikke kravet")
            } icon: {
                Image(systemName: feiler == 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(feiler == 0 ? Color.green : Color.red)
            }
            .font(.headline)
            KomponentSkjerm(tema: tema, tilstand: tilstand)
        }
        VStack(alignment: .leading, spacing: 0) {
            ForEach(sjekker) { s in
                Kontrollpunkt(sjekk: s)
                if s.id != sjekker.last?.id { Divider().padding(.leading, 56) }
            }
        }
        .padding(.vertical, 4)
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        Text("Kravene er fra WCAG 2 (AA). 1.4.3 gjelder tekst og finnes i WCAG 2.0 og nyere. 1.4.11 gjelder kanter og kontroller og kom i WCAG 2.1. Offentlig sektor i Norge skal følge WCAG 2.1. For private virksomheter er kravet WCAG 2.0, uten 1.4.11. Deaktiverte kontroller er unntatt.")
            .font(.footnote)
            .foregroundStyle(Color.sekundærTekst)
    }

    /// Modus og tilstand, fast nederst så de kan byttes mens komponentene vises.
    private var modusvalg: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Picker("Modus", selection: $mørk) {
                    Text("Lys").tag(false)
                    Text("Mørk").tag(true)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                Toggle(isOn: $øktKontrast) {
                    Label("Økt kontrast", systemImage: "circle.lefthalf.filled")
                }
                .toggleStyle(.button)
                .help("Økt kontrast (tilgjengelighetsinnstillingen)")
            }
            Picker("Tilstand", selection: $tilstand) {
                ForEach(Komponenttilstand.allCases) { Text($0.navn).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }
}

/// Et kontrollert fargepar: prøve, navn og krav, forholdet og om det holder.
private struct Kontrollpunkt: View {
    let sjekk: Komponentsjekk

    var body: some View {
        HStack(spacing: 12) {
            Text("Aa")
                .font(.callout.weight(.semibold))
                .foregroundStyle(sjekk.forgrunn.swiftUI)
                .frame(width: 40, height: 32)
                .background(sjekk.bakgrunn.swiftUI, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).strokeBorder(Color.primary.opacity(0.12)))
            VStack(alignment: .leading, spacing: 2) {
                sjekk.par.navn(rolle: sjekk.rolle).font(.subheadline)
                Group {
                    if let kriterium = sjekk.krav.suksesskriterium, let m = sjekk.krav.minimum {
                        Text("\(kriterium) · minst \(m.formatted(.number.precision(.fractionLength(m == 3 ? 0 : 1)))):1")
                    } else {
                        Text("Unntatt (deaktivert)")
                    }
                }
                .font(.caption)
                .foregroundStyle(Color.sekundærTekst)
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    if sjekk.krav.minimum != nil {
                        Image(systemName: sjekk.består ? "checkmark" : "xmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(sjekk.består ? Color.green : Color.red)
                    }
                    Text(Kontrasttest(forgrunn: sjekk.forgrunn, bakgrunn: sjekk.bakgrunn).formatert)
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                }
                Text(APCANivå.formatert(sjekk.lc)).font(.caption.monospacedDigit()).foregroundStyle(Color.sekundærTekst)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Komponentene

/// En liten app-skjerm tegnet med temaets farger: tittel, gruppert liste med bryter, tekstfelt, knapper, lenke,
/// slettehandling, varsler og fanelinje.
struct KomponentSkjerm: View {
    let tema: Designtema
    let tilstand: Komponenttilstand

    private var av: Bool { tilstand == .deaktivert }
    private var fokus: Bool { tilstand == .fokus }
    private func c(_ f: Farge) -> Color { f.swiftUI }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Innstillinger")
                .font(.title2.weight(.bold))
                .foregroundStyle(c(tema.tekst))
                .padding(.top, 4)
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "bell.fill")
                        .font(.footnote)
                        .foregroundStyle(c(tema.påAksent))
                        .frame(width: 28, height: 28)
                        .background(c(tema.aksent), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    Text("Varsler").foregroundStyle(c(tema.tekst))
                    Spacer()
                    bryter
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                Rectangle().fill(c(tema.skille)).frame(height: 1).padding(.leading, 50)
                HStack(spacing: 10) {
                    Image(systemName: "person.fill")
                        .font(.footnote)
                        .foregroundStyle(c(tema.påAksent))
                        .frame(width: 28, height: 28)
                        .background(c(tema.aksent), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    Text("Konto").foregroundStyle(c(tema.tekst))
                    Spacer()
                    Text("Kari").foregroundStyle(c(tema.sekundærtekst))
                    Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(c(tema.sekundærtekst))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(c(tema.flate), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            Text("Varsler vises også på låseskjermen.")
                .font(.footnote)
                .foregroundStyle(c(tema.sekundærtekst))
                .padding(.horizontal, 4)
            // Tekstfelt med kant, og fokusring i fokusert tilstand.
            Text("Navn")
                .foregroundStyle(c(av ? tema.deaktivertTekst : tema.plassholder))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(c(tema.flate), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(c(av ? tema.skille : tema.kant), lineWidth: 1))
                .overlay { if fokus { RoundedRectangle(cornerRadius: 13, style: .continuous).strokeBorder(c(tema.aksent), lineWidth: 2).padding(-3) } }
            HStack(spacing: 10) {
                Text("Lagre")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(c(av ? tema.deaktivertTekst : tema.påAksent))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(c(av ? tema.deaktivertFyll : tilstand == .trykket ? tema.aksentTrykket : tema.aksent), in: Capsule())
                    .overlay { if fokus { Capsule().strokeBorder(c(tema.aksent), lineWidth: 2).padding(-4) } }
                Text("Avbryt")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(c(av ? tema.deaktivertTekst : tilstand == .trykket ? tema.aksentTrykket : tema.aksent))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(c(av ? tema.deaktivertFyll : tema.aksentTonet), in: Capsule())
            }
            HStack {
                Text("Les mer om personvern").underline().foregroundStyle(c(tema.aksent))
                Spacer()
                Text("Slett konto").foregroundStyle(c(av ? tema.deaktivertTekst : tema.status(.feil).tekst))
            }
            .font(.subheadline)
            .padding(.horizontal, 4)
            VStack(spacing: 6) {
                varsel(.feil, ikon: "xmark.octagon.fill", tekst: "Navnet mangler")
                varsel(.suksess, ikon: "checkmark.circle.fill", tekst: "Endringene er lagret")
                varsel(.advarsel, ikon: "exclamationmark.triangle.fill", tekst: "Lagringsplassen er snart full")
                ForEach(tema.egne.filter { $0.mal == .status }) { egenVarsel($0) }
            }
            let knapper = tema.egne.filter { $0.mal == .aksent }
            if !knapper.isEmpty {
                HStack(spacing: 10) { ForEach(knapper) { egenKnapp($0) } }
            }
            let etiketter = tema.egne.filter { $0.mal == .markering }
            if !etiketter.isEmpty {
                HStack(spacing: 8) {
                    ForEach(etiketter) { etikett($0) }
                    Spacer(minLength: 0)
                }
            }
            fanelinje
        }
        .padding(14)
        .background(c(tema.bakgrunn), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Color.primary.opacity(0.12)))
        .environment(\.colorScheme, tema.modus.erMørk ? .dark : .light)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Eksempel på komponenter"))
    }

    private var bryter: some View {
        let fyll = av ? tema.deaktivertFyll : tema.sekundær
        return Capsule()
            .fill(c(fyll))
            .frame(width: 50, height: 30)
            .overlay(alignment: .trailing) {
                Circle().fill(Color.white).shadow(color: .black.opacity(0.2), radius: 1.5, y: 1).padding(2)
            }
    }

    private func varsel(_ rolle: Designrolle, ikon: String, tekst: LocalizedStringKey) -> some View {
        let s = tema.status(rolle)
        return HStack(spacing: 8) {
            Image(systemName: ikon)
            Text(tekst)
            Spacer(minLength: 0)
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(c(s.tekst))
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(c(s.flate), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    /// Varsel for en egen rolle som status.
    private func egenVarsel(_ e: EgenRolleFarger) -> some View {
        HStack(spacing: 8) {
            Image(systemName: e.tokennavn == "info" ? "info.circle.fill" : "circle.fill")
            Text(verbatim: e.navn.prefix(1).uppercased() + e.navn.dropFirst())
            Spacer(minLength: 0)
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(c(e.tekst ?? tema.tekst))
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(c(e.flate), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    /// Knapp for en egen rolle som aksent.
    private func egenKnapp(_ e: EgenRolleFarger) -> some View {
        Text(verbatim: e.navn.prefix(1).uppercased() + e.navn.dropFirst())
            .font(.body.weight(.semibold))
            .foregroundStyle(c(av ? tema.deaktivertTekst : e.påFlate ?? tema.tekst))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(c(av ? tema.deaktivertFyll : tilstand == .trykket ? e.trykket ?? e.flate : e.flate), in: Capsule())
    }

    /// Etikett for en egen rolle som markering: svak flate, tydelig kant og prikk, vanlig tekst.
    private func etikett(_ e: EgenRolleFarger) -> some View {
        HStack(spacing: 6) {
            Circle().fill(c(e.kant ?? e.flate)).frame(width: 8, height: 8)
            Text(verbatim: e.navn)
        }
        .font(.footnote.weight(.medium))
        .foregroundStyle(c(tema.tekst))
        .padding(.horizontal, 10)
        .frame(height: 26)
        .background(c(e.flate), in: Capsule())
        .overlay(Capsule().strokeBorder(c(e.kant ?? e.flate), lineWidth: 1.5))
    }

    private var fanelinje: some View {
        HStack {
            fane("house.fill", "Hjem", valgt: true)
            fane("magnifyingglass", "Søk", valgt: false)
            fane("gearshape.fill", "Innstillinger", valgt: false)
        }
        .padding(.vertical, 6)
        .background(c(tema.flate), in: Capsule())
        .overlay(Capsule().strokeBorder(c(tema.skille), lineWidth: 1))
    }

    private func fane(_ ikon: String, _ tekst: LocalizedStringKey, valgt: Bool) -> some View {
        VStack(spacing: 2) {
            Image(systemName: ikon).font(.body)
            Text(tekst).font(.caption2.weight(.medium))
        }
        .foregroundStyle(c(valgt ? tema.aksent : tema.sekundærtekst))
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Roller

/// Fargen for hver rolle og skriftfargene, med fargene rollen får i hver modus.
struct DesignsystemRoller: View {
    @Bindable var dokument: DesignsystemDokument
    let palett: PalettDokument?
    @Environment(\.modelContext) private var kontekst
    /// Rollen en annen rolle dras over (for å bytte farge), markert med ramme.
    @State private var slippMål: RolleRef?
    /// Ny egen rolle (navnet skrives først) og rolle som får nytt navn.
    @State private var nyRolle = false
    @State private var omdøpes: UUID?
    @State private var rollenavn = ""

    /// En rolle i lista: en av de faste eller en egen.
    enum RolleRef: Hashable {
        case fast(Designrolle)
        case egen(UUID)

        /// Som tekst når den dras (med prefiks, så annen tekst som slippes, ikke tolkes som en rolle).
        var dratekst: String {
            switch self {
            case .fast(let r): RolleRef.prefiks + "fast:" + r.rawValue
            case .egen(let id): RolleRef.prefiks + "egen:" + id.uuidString
            }
        }

        init?(dratekst t: String) {
            guard t.hasPrefix(RolleRef.prefiks) else { return nil }
            let rest = t.dropFirst(RolleRef.prefiks.count)
            if rest.hasPrefix("fast:"), let r = Designrolle(rawValue: String(rest.dropFirst(5))) { self = .fast(r) }
            else if rest.hasPrefix("egen:"), let id = UUID(uuidString: String(rest.dropFirst(5))) { self = .egen(id) }
            else { return nil }
        }

        static let prefiks = "kolorist.designrolle:"
    }

    var body: some View {
        let ds = dokument.designsystem
        let temaer = Designmodus.allCases.map { ds.tema($0) }
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Designrolle.allCases) { rolle in
                rolleRad(.fast(rolle), tittel: Text(rolle.navn), bruk: Text(rolle.bruk), ds: ds,
                         modusfarger: temaer.map { ($0.modus, rolle.farge(i: $0)) })
                Divider().padding(.leading, 68)
            }
            rad(tittel: Text("Lys tekst"), bruk: Text("Tekst i mørk modus og på mørke flater"), farge: tekst(lys: true), ekstra: nil) { EmptyView() }
            Divider().padding(.leading, 68)
            rad(tittel: Text("Mørk tekst"), bruk: Text("Tekst i lys modus og på lyse flater"), farge: tekst(lys: false), ekstra: nil) { EmptyView() }
        }
        .padding(.vertical, 4)
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

        // Egne roller (valgfritt): vises først når det finnes en.
        if !ds.egneRoller.isEmpty {
            Text("Egne roller").font(.headline).padding(.top, 4)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(ds.egneRoller.enumerated()), id: \.element.id) { i, egen in
                    rolleRad(.egen(egen.id), tittel: Text(verbatim: egen.navn), bruk: Text(egen.mal.navn), ds: ds,
                             modusfarger: temaer.map { ($0.modus, $0.egne[i].hovedfarge) })
                    if i < ds.egneRoller.count - 1 { Divider().padding(.leading, 68) }
                }
            }
            .padding(.vertical, 4)
            .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        Menu {
            if !ds.egneRoller.contains(where: { $0.navn.lowercased() == "info" }) {
                Button("Info", systemImage: "info.circle") { leggTil(.info) }
            }
            Button("Egen rolle …", systemImage: "plus") {
                rollenavn = ""
                nyRolle = true
            }
        } label: {
            Label("Legg til rolle", systemImage: "plus.circle")
        }
        .disabled(ds.egneRoller.count >= EgenRolle.maksAntall)
        .font(.callout)
        .fixedSize()
        .alert("Ny rolle", isPresented: $nyRolle) {
            TextField("Navn", text: $rollenavn)
            Button("Avbryt", role: .cancel) {}
            Button("Legg til") {
                let navn = rollenavn.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !navn.isEmpty else { return }
                leggTil(EgenRolle(navn: navn, farge: forslagsfarge(), mal: .status))
            }
        } message: {
            Text("Gi rollen et navn, for eksempel «tilbud» eller «kategori». Velg bruk og farge etterpå i menyen på fargen.")
        }
        .alert("Gi rollen nytt navn", isPresented: Binding(get: { omdøpes != nil }, set: { if !$0 { omdøpes = nil } })) {
            TextField("Navn", text: $rollenavn)
            Button("Avbryt", role: .cancel) {}
            Button("Lagre") {
                let navn = rollenavn.trimmingCharacters(in: .whitespacesAndNewlines)
                if let id = omdøpes, !navn.isEmpty { endreEgen(id, "Gi rollen nytt navn") { $0.navn = navn } }
            }
        }

        Text("Trykk på en farge for å velge en annen. Dra en rolle over en annen, eller bruk «Bytt med» i menyen, for å bytte fargene mellom to roller. Merkefargen brukes uendret i hver modus der den holder kravene; ellers får den samme kulør med lysheten som trengs. Lys+ og Mørk+ er økt kontrast.")
            .font(.footnote)
            .foregroundStyle(Color.sekundærTekst)
        Text("Egne roller, høyst \(EgenRolle.maksAntall): som status (tekst på en tonet flate), som aksent (knapp) eller som markering (etiketter og diagrammer). De får farger i alle modusene og egne kontrollpunkter under Komponenter.")
            .font(.footnote)
            .foregroundStyle(Color.sekundærTekst)
        if let palett {
            Button("Fordel rollene på nytt fra «\(palett.navn)»", systemImage: "arrow.triangle.2.circlepath") {
                kontekst.angresteg("Fordel rollene") {
                    var ny = Designsystem(fra: palett.palett)
                    ny.navn = dokument.navn
                    ny.egneRoller = dokument.designsystem.egneRoller
                    dokument.designsystem = ny
                }
            }
            .font(.callout)
        }
    }

    /// En rolle med farge, navn, bruk og fargen i hver modus; kan dras over en annen rolle for å bytte farge.
    private func rolleRad(_ ref: RolleRef, tittel: Text, bruk: Text, ds: Designsystem,
                          modusfarger: [(Designmodus, Farge)]) -> some View {
        rad(tittel: tittel, bruk: bruk, farge: binding(ref), ekstra: AnyView(Group {
            fraPaletten(ref)
            byttMeny(ref, ds: ds)
            if case .egen(let id) = ref { egenMeny(id, ds: ds) }
        })) {
            HStack(spacing: 4) {
                ForEach(modusfarger, id: \.0) { modus, f in
                    VStack(spacing: 1) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous).fill(f.swiftUI)
                            .frame(width: 30, height: 16)
                            .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).strokeBorder(Color.primary.opacity(0.12)))
                        Text(modus.kortnavn).font(.caption2).foregroundStyle(Color.sekundærTekst)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(modus.kortnavn))
                    .accessibilityValue(f.hex())
                }
            }
        }
        // Dra en rolle over en annen for å bytte fargene deres.
        .contentShape(Rectangle())
        .draggable(ref.dratekst) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 6, style: .continuous).fill(farge(ref, i: ds).swiftUI).frame(width: 28, height: 28)
                tittel.font(.subheadline.weight(.semibold))
            }
            .padding(8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .dropDestination(for: String.self) { tekster, _ in
            slippMål = nil
            guard let t = tekster.first, let fra = RolleRef(dratekst: t) else { return false }
            bytt(fra, ref)
            return true
        } isTargeted: { over in
            if over { slippMål = ref } else if slippMål == ref { slippMål = nil }
        }
        .overlay {
            if slippMål == ref {
                RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color.accentColor, lineWidth: 2).padding(2)
            }
        }
    }

    // MARK: Fargen for en rolle

    private func farge(_ ref: RolleRef, i ds: Designsystem) -> Farge {
        switch ref {
        case .fast(let r): ds[r]
        case .egen(let id): ds.egneRoller.first { $0.id == id }?.farge ?? ds[.aksent]
        }
    }

    private func sett(_ ref: RolleRef, _ f: Farge, i ds: inout Designsystem) {
        switch ref {
        case .fast(let r): ds[r] = f
        case .egen(let id): if let i = ds.egneRoller.firstIndex(where: { $0.id == id }) { ds.egneRoller[i].farge = f }
        }
    }

    private func navn(_ ref: RolleRef, i ds: Designsystem) -> Text {
        switch ref {
        case .fast(let r): Text(r.navn)
        case .egen(let id): Text(verbatim: ds.egneRoller.first { $0.id == id }?.navn ?? "")
        }
    }

    private func binding(_ ref: RolleRef) -> Binding<Farge> {
        Binding(get: { farge(ref, i: dokument.designsystem) }, set: { ny in
            kontekst.angresteg("Endre rolle") {
                var ds = dokument.designsystem
                sett(ref, ny, i: &ds)
                dokument.designsystem = ds
            }
        })
    }

    /// Bytter fargene mellom to roller.
    private func bytt(_ a: RolleRef, _ b: RolleRef) {
        guard a != b else { return }
        kontekst.angresteg("Bytt roller") {
            var ds = dokument.designsystem
            let fa = farge(a, i: ds), fb = farge(b, i: ds)
            sett(a, fb, i: &ds)
            sett(b, fa, i: &ds)
            dokument.designsystem = ds
        }
    }

    /// «Bytt med» en annen rolle (faste og egne).
    private func byttMeny(_ ref: RolleRef, ds: Designsystem) -> some View {
        let alle = Designrolle.allCases.map(RolleRef.fast) + ds.egneRoller.map { RolleRef.egen($0.id) }
        return Menu("Bytt med", systemImage: "arrow.left.arrow.right") {
            ForEach(alle.filter { $0 != ref }, id: \.self) { annen in
                // To tekster i et menyvalg blir tittel og undertittel.
                Button { bytt(ref, annen) } label: {
                    navn(annen, i: ds)
                    Text(verbatim: farge(annen, i: ds).hex())
                }
            }
        }
    }

    // MARK: Egne roller

    private func leggTil(_ rolle: EgenRolle) {
        kontekst.angresteg("Legg til rolle") {
            var ds = dokument.designsystem
            guard ds.egneRoller.count < EgenRolle.maksAntall else { return }
            ds.egneRoller.append(rolle)
            dokument.designsystem = ds
        }
    }

    private func endreEgen(_ id: UUID, _ angrenavn: String.LocalizationValue, _ endring: (inout EgenRolle) -> Void) {
        kontekst.angresteg(angrenavn) {
            var ds = dokument.designsystem
            guard let i = ds.egneRoller.firstIndex(where: { $0.id == id }) else { return }
            endring(&ds.egneRoller[i])
            dokument.designsystem = ds
        }
    }

    /// En farge fra paletten som ingen rolle bruker ennå, ellers en standardfarge.
    private func forslagsfarge() -> Farge {
        let ds = dokument.designsystem
        let brukt = Set(Designrolle.allCases.map { ds[$0].hex() } + ds.egneRoller.map { $0.farge.hex() })
        return palett?.farger.first { !brukt.contains($0.farge.hex()) && $0.farge.okLCH.c >= 0.04 }?.farge
            ?? Farge(okLCH: OKLCH(l: 0.6, c: 0.14, h: 300))
    }

    /// Bruk, nytt navn og fjern for en egen rolle.
    @ViewBuilder private func egenMeny(_ id: UUID, ds: Designsystem) -> some View {
        if let egen = ds.egneRoller.first(where: { $0.id == id }) {
            Picker(selection: Binding(get: { egen.mal }, set: { ny in endreEgen(id, "Endre bruk") { $0.mal = ny } })) {
                ForEach(Rollemal.allCases) { Text($0.navn).tag($0) }
            } label: {
                Label("Bruk", systemImage: "square.on.square")
            }
            .pickerStyle(.menu)
            Button("Gi nytt navn …", systemImage: "character.cursor.ibeam") {
                rollenavn = egen.navn
                omdøpes = id
            }
            Button("Fjern rollen", systemImage: "trash", role: .destructive) {
                kontekst.angresteg("Fjern rolle") {
                    var ds = dokument.designsystem
                    ds.egneRoller.removeAll { $0.id == id }
                    dokument.designsystem = ds
                }
            }
        }
    }

    private func tekst(lys: Bool) -> Binding<Farge> {
        Binding(get: { lys ? dokument.designsystem.lysTekst : dokument.designsystem.mørkTekst }, set: { ny in
            kontekst.angresteg("Endre skriftfarge") {
                var ds = dokument.designsystem
                if lys { ds.lysTekst = ny } else { ds.mørkTekst = ny }
                dokument.designsystem = ds
            }
        })
    }

    /// Palettens farger som valg for rollen.
    @ViewBuilder private func fraPaletten(_ ref: RolleRef) -> some View {
        if let palett, !palett.farger.isEmpty {
            Menu("Fra «\(palett.navn)»", systemImage: "swatchpalette") {
                ForEach(palett.farger) { pf in
                    Button(pf.visningsnavn) { binding(ref).wrappedValue = pf.farge }
                }
            }
        }
    }

    private func rad<Tillegg: View>(tittel: Text, bruk: Text, farge: Binding<Farge>, ekstra: AnyView?,
                                    @ViewBuilder tillegg: () -> Tillegg) -> some View {
        HStack(spacing: 12) {
            FargeVelgerMeny(tittel: String(localized: "Farge"), farge: farge, ekstra: ekstra) {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(farge.wrappedValue.swiftUI)
                    .frame(width: 44, height: 44)
                    .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).strokeBorder(Color.primary.opacity(0.12)))
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    tittel.font(.subheadline.weight(.semibold))
                    Text(farge.wrappedValue.hex()).font(.caption.monospaced()).foregroundStyle(Color.sekundærTekst)
                }
                bruk.font(.caption).foregroundStyle(Color.sekundærTekst)
                tillegg().padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

extension Rollemal {
    var navn: LocalizedStringKey {
        switch self {
        case .status: "Som status: tekst på en tonet flate"
        case .aksent: "Som aksent: knapp med tekst på"
        case .markering: "Markering: etiketter og diagrammer"
        }
    }
}

// MARK: - Skalaer

/// Toneskalaen for hver rolle (50–950, lik L* på hvert trinn).
struct DesignsystemSkalaer: View {
    let designsystem: Designsystem

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Designrolle.allCases) { rolle in
                skala(Text(rolle.navn), designsystem.skala(for: rolle))
            }
            ForEach(designsystem.egneRoller) { egen in
                skala(Text(verbatim: egen.navn), designsystem.skala(for: egen))
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        Text("Trinnene har samme lyshet (L*) i alle roller, så kontrasten er lik: 400 holder minst 3:1 og 600 minst 4,5:1 mot hvitt. Skalaene følger med i design tokens.")
            .font(.footnote)
            .foregroundStyle(Color.sekundærTekst)
    }

    private func skala(_ tittel: Text, _ farger: [Farge]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            tittel.font(.subheadline.weight(.semibold))
            HStack(spacing: 2) {
                ForEach(Array(zip(Designsystem.trinnavn, farger)), id: \.0) { trinn, f in
                    VStack(spacing: 2) {
                        Rectangle().fill(f.swiftUI).frame(height: 36)
                        Text(trinn).font(.system(size: 9).monospacedDigit()).foregroundStyle(Color.sekundærTekst)
                    }
                    .contextMenu {
                        Button("Vis farge", systemImage: "slider.horizontal.3") { Arbeidsbenk.delt.visIStudio(f) }
                        Button("Kopier \(f.hex())", systemImage: "doc.on.doc") { Utklippstavle.kopier(f) }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(verbatim: trinn))
                    .accessibilityValue(f.hex())
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }
}

// MARK: - Eksport

extension DesignsystemEksport.Format {
    var navn: LocalizedStringKey {
        switch self {
        case .xcode: "Xcode: fargesett (asset catalog)"
        case .designTokens: "Design tokens (DTCG) med alias og resolver"
        case .figma: "Figma-variabler (én fil per modus)"
        case .css: "CSS med light-dark()"
        }
    }

    var forklaring: LocalizedStringKey {
        switch self {
        case .xcode: "Ett fargesett per farge, med lys, mørk og økt kontrast. Dra mappa inn i Xcode-prosjektet."
        case .designTokens: "Skalaer og farger som primitiver, én fil per modus med alias, og resolver.json."
        case .figma: "Åpne Variables-visningen, lag en ny samling og dra de fire filene inn. Hver fil blir en modus. README-en har trinnene."
        case .css: "Lys og mørk med light-dark(), økt kontrast med prefers-contrast, og Display P3 med sRGB som reserve."
        }
    }
}

/// Velg formater og lagre eller del designsystemet som en mappe.
struct DesignsystemEksportArk: View {
    let designsystem: Designsystem
    let navn: String
    @AppStorage("designsystem.eksport") private var valgte = "xcode,designTokens,figma,css"
    @State private var mappe: URL?
    @State private var velgerMappe = false
    @State private var feil: String?
    @Environment(\.dismiss) private var lukk

    private var formater: Set<DesignsystemEksport.Format> {
        Set(valgte.split(separator: ",").compactMap { DesignsystemEksport.Format(rawValue: String($0)) })
    }

    private func sett(_ f: DesignsystemEksport.Format, _ på: Bool) {
        var s = formater
        if på { s.insert(f) } else { s.remove(f) }
        valgte = DesignsystemEksport.Format.allCases.filter { s.contains($0) }.map(\.rawValue).joined(separator: ",")
    }

    private var mappenavn: String {
        LagreSomArk.rentFilnavn(String(localized: "\(navn.isEmpty ? String(localized: "Uten navn") : navn) designsystem"))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(DesignsystemEksport.Format.allCases) { f in
                        Toggle(isOn: Binding(get: { formater.contains(f) }, set: { sett(f, $0) })) {
                            Text(f.navn)
                            Text(f.forklaring)
                        }
                    }
                } footer: {
                    Text("Filene legges i mappa «\(mappenavn)», med en README som forklarer systemet og bruken. Fargene er i sRGB, som alle skjermer og Figma forstår. CSS-fila har i tillegg Display P3 der fargene går utenfor sRGB.")
                }
            }
            .formStyle(.grouped)
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    Button { lagre() } label: {
                        Label("Lagre …", systemImage: "folder").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    if let mappe {
                        ShareLink(item: mappe) {
                            Label("Del …", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .controlSize(.large)
                .disabled(mappe == nil)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.bar)
            }
            .navigationTitle("Eksporter designsystem")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Ferdig") { lukk() } } }
            .task(id: valgte) { mappe = lagMappe() }
            #if os(iOS)
            .sheet(isPresented: $velgerMappe) { if let mappe { Eksportvelger(filer: [mappe]).ignoresSafeArea() } }
            #endif
            .alert("Kunne ikke lagre", isPresented: Binding(get: { feil != nil }, set: { if !$0 { feil = nil } })) {
                Button("OK") {}
            } message: { Text(feil ?? "") }
        }
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 420)
        #endif
    }

    /// Filene i en mappe i den midlertidige katalogen, eller nil uten valgte formater.
    private func lagMappe() -> URL? {
        guard !formater.isEmpty else { return nil }
        let rot = FileManager.default.temporaryDirectory.appendingPathComponent("Kolorist-designsystem-\(UUID().uuidString)", isDirectory: true)
        let mappe = rot.appendingPathComponent(mappenavn, isDirectory: true)
        do {
            let versjon = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
            let avsender = DesignsystemEksport.Avsender(app: versjon.isEmpty ? "Kolorist" : "Kolorist \(versjon)",
                                                         lenke: URL(string: "https://kolorist.no"),
                                                         utvikler: "Eivind Arnstein Johansen")
            for (sti, data) in DesignsystemEksport.filer(designsystem, formater: formater, navn: navn, avsender: avsender) {
                let url = mappe.appendingPathComponent(sti)
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try data.write(to: url, options: .atomic)
            }
            return mappe
        } catch {
            feil = error.localizedDescription
            return nil
        }
    }

    private func lagre() {
        #if os(iOS)
        velgerMappe = true
        #else
        guard let mappe else { return }
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = String(localized: "Lagre")
        panel.message = String(localized: "Velg mappa designsystemet skal lagres i.")
        guard panel.runModal() == .OK, let mål = panel.url else { return }
        do {
            let ut = mål.appendingPathComponent(mappe.lastPathComponent, isDirectory: true)
            if FileManager.default.fileExists(atPath: ut.path) { try FileManager.default.removeItem(at: ut) }
            try FileManager.default.copyItem(at: mappe, to: ut)
        } catch {
            feil = error.localizedDescription
        }
        #endif
    }
}
