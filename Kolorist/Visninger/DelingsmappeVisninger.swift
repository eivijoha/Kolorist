import FargeKjerne
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Oppsett av delingsmappa: velg mappe, formater og om palettene skal holdes oppdatert.
struct DelingsmappeArk: View {
    @State private var deling = Delingsmappe.delt
    @Query(sort: \PalettDokument.opprettet) private var paletter: [PalettDokument]
    @State private var velgerMappe = false
    @State private var feil: String?
    @Environment(\.dismiss) private var lukk

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    switch deling.status {
                    case .ikkeKoblet:
                        Label("Ingen mappe valgt", systemImage: "folder.badge.questionmark")
                            .foregroundStyle(Color.sekundærTekst)
                    case .koblet(let navn):
                        Label(navn, systemImage: "folder.fill")
                    case .utenTilgang:
                        Label("Mappa kan ikke åpnes. Den kan være flyttet eller slettet, eller appen til skytjenesten er fjernet. Velg den på nytt.",
                              systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.advarsel)
                    }
                    Button(deling.status == .ikkeKoblet ? "Velg mappe …" : "Velg en annen mappe …", systemImage: "folder.badge.plus") {
                        velgerMappe = true
                    }
                    if deling.status != .ikkeKoblet {
                        Button("Koble fra mappa", systemImage: "folder.badge.minus", role: .destructive) { deling.kobleFra() }
                    }
                } header: {
                    Text("Mappe")
                } footer: {
                    Text("Velg en mappe i OneDrive, Google Drive, Dropbox, iCloud Drive eller en annen tjeneste i Filer. Kolorist skriver palettene dit som filer, så de kan åpnes på Windows og andre maskiner. Tjenestens egen app laster opp filene – Kolorist sender ingenting selv.")
                }

                Section {
                    ForEach(Delingsformat.allCases) { f in
                        Toggle(f.navn, isOn: Binding(get: { deling.formater.contains(f) }, set: { deling.settFormat(f, $0) }))
                    }
                } header: {
                    Text("Formater")
                } footer: {
                    Text("Hver palett skrives som én fil per format, med palettens navn som filnavn.")
                }

                Section {
                    Toggle("Hold palettene oppdatert", isOn: $deling.holdOppdatert)
                    Button("Skriv alle paletter nå", systemImage: "arrow.triangle.2.circlepath") {
                        Task { await deling.synk(paletter, alle: true) }
                    }
                    .disabled(!deling.erKoblet || deling.formater.isEmpty || deling.arbeider)
                    if deling.arbeider {
                        ProgressView("Skriver …")
                    } else if let r = deling.sisteResultat {
                        if let feil = r.feil {
                            Label(feil, systemImage: "exclamationmark.triangle.fill").foregroundStyle(Color.advarsel)
                        } else {
                            Text(r.antall == 1
                                 ? "1 palett skrevet \(r.tid.formatted(date: .omitted, time: .shortened))"
                                 : "\(r.antall) paletter skrevet \(r.tid.formatted(date: .omitted, time: .shortened))")
                                .foregroundStyle(Color.sekundærTekst)
                        }
                    }
                } footer: {
                    Text("Med «Hold palettene oppdatert» skrives en palett på nytt når den endres, og filene flyttes når den får nytt navn. Filer for slettede paletter blir liggende i mappa.")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Delingsmappe")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Ferdig") { lukk() } } }
            .fileImporter(isPresented: $velgerMappe, allowedContentTypes: [.folder]) { resultat in
                do {
                    try deling.kobleTil(try resultat.get())
                    Task { await deling.synk(paletter, alle: true) }
                } catch {
                    feil = error.localizedDescription
                }
            }
            .alert("Kunne ikke bruke mappa", isPresented: Binding(get: { feil != nil }, set: { if !$0 { feil = nil } })) {
                Button("OK") {}
            } message: { Text(feil ?? "") }
            .onAppear { deling.oppdaterStatus() }
        }
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 560)
        #endif
    }
}

/// Kortet i palettoversikten: status for delingsmappa, og trykk for å sette den opp.
struct DelingsmappeRad: View {
    @State private var deling = Delingsmappe.delt
    @State private var visArk = false

    var body: some View {
        Button { visArk = true } label: {
            HStack(spacing: 12) {
                Image(systemName: deling.status == .utenTilgang ? "exclamationmark.triangle" : "folder")
                    .font(.title3)
                    .foregroundStyle(deling.status == .utenTilgang ? Color.advarsel : Color.accentColor)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Delingsmappe").font(.body.weight(.semibold)).foregroundStyle(.primary)
                    Group {
                        switch deling.status {
                        case .ikkeKoblet: Text("Del paletter som filer i en mappe – for eksempel OneDrive, Google Drive eller Dropbox, også for kolleger på Windows")
                        case .koblet(let navn): Text("Paletter deles i mappa «\(navn)»")
                        case .utenTilgang: Text("Delingsmappa kan ikke åpnes – velg den på nytt")
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(deling.status == .utenTilgang ? Color.advarsel : Color.sekundærTekst)
                    .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Color.sekundærTekst)
            }
            .padding(12)
            .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
        .sheet(isPresented: $visArk) { DelingsmappeArk() }
    }
}

/// Holder delingsmappa oppdatert i bakgrunnen: skriver endrede paletter et par sekunder etter siste endring.
struct DelingsmappeSynk: View {
    @State private var deling = Delingsmappe.delt
    @Query(sort: \PalettDokument.opprettet) private var paletter: [PalettDokument]
    @Environment(\.scenePhase) private var fase

    /// Endrer seg når en palett endres, legges til, eller oppsettet endres.
    private var nøkkel: String {
        guard deling.holdOppdatert, deling.erKoblet else { return "av" }
        let formater = deling.formater.map(\.rawValue).sorted().joined(separator: ",")
        return formater + paletter.map { "\($0.id)\($0.endret.timeIntervalSinceReferenceDate)\($0.navn)" }.joined()
    }

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .task(id: nøkkel) {
                guard nøkkel != "av" else { return }
                // Vent til endringene har roet seg (oppgaven avbrytes og startes på nytt ved hver endring).
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                await deling.synk(paletter)
            }
            .onChange(of: fase) { _, ny in if ny == .active { deling.oppdaterStatus() } }
    }
}
