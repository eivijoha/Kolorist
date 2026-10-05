import FargeKI
import FargeKjerne
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Palettoversikt som kort i en rullevisning (ikke `List`): i en `List` tar raden over
/// dra-gesten, slik at enkeltfarger ikke kan dras ut av den. Her kan hver fargeprøve dras,
/// og hvert kort tar imot farger som slippes på det.
struct PalettListe: View {
    /// I palettkolonnen på Mac: «Ny palett» ligger i listen, ikke i verktøylinjen (knapper fra en
    /// lukket inspektør blir ellers hengende igjen når vinduet gjøres smalt).
    var iKolonne = false
    @Environment(\.modelContext) private var kontekst
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @Query(sort: \PalettDokument.opprettet, order: .reverse) private var paletter: [PalettDokument]
    @Query(sort: \LagretFarge.opprettet, order: .reverse) private var enkeltfarger: [LagretFarge]
    @Query(sort: \PalettGruppe.opprettet) private var grupper: [PalettGruppe]
    /// Navigasjonssti: oversikten fyller hele hovedvisningen (også på Mac og iPad), valgt palett åpnes over.
    @State private var sti: [Valg] = []
    @State private var målrettet: Valg?
    @State private var slettes: PalettDokument?
    @State private var omdøpes: PalettDokument?
    @State private var vurderes: PalettDokument?
    @State private var matrise: PalettDokument?
    @State private var visVerdiord = false
    @State private var lagresSom: PalettDokument?
    @State private var visNyPalett = false
    @State private var nyPalettNavn = ""
    @State private var importererASE = false
    @State private var importfeil: String?
    /// Palettgrupper: ny gruppe (ev. med en palett som skal flyttes dit), nytt navn og sletting.
    @State private var visNyGruppe = false
    @State private var gruppenavn = ""
    @State private var flyttesTilNyGruppe: PalettDokument?
    @State private var omdøpesGruppe: PalettGruppe?
    @State private var slettesGruppe: PalettGruppe?

    /// Gruppene sortert etter navn.
    private var sorterteGrupper: [PalettGruppe] {
        grupper.sorted { $0.navn.localizedStandardCompare($1.navn) == .orderedAscending }
    }

    /// Paletter uten gruppe – også de som peker på en gruppe som er slettet (f.eks. på en annen enhet).
    private var paletterUtenGruppe: [PalettDokument] {
        let ider = Set(grupper.map(\.id))
        return paletter.filter { $0.gruppeID.map { !ider.contains($0) } ?? true }
    }

    private func flyttPalett(_ p: PalettDokument, til gruppe: UUID?) {
        kontekst.angresteg("Flytt palett") { p.gruppeID = gruppe }
    }

    private func opprettGruppe() {
        let navn = gruppenavn.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !navn.isEmpty else { return }
        kontekst.angresteg("Ny palettgruppe") {
            let g = PalettGruppe(navn: navn)
            kontekst.insert(g)
            flyttesTilNyGruppe?.gruppeID = g.id
        }
        flyttesTilNyGruppe = nil
    }

    /// Menyen for å flytte en palett til en gruppe (eller ut av den).
    @ViewBuilder private func flyttTilGruppeMeny(_ p: PalettDokument) -> some View {
        Menu("Flytt til gruppe", systemImage: "folder") {
            ForEach(sorterteGrupper) { g in
                Button(g.navn.isEmpty ? String(localized: "Uten navn") : g.navn) { flyttPalett(p, til: g.id) }
                    .disabled(p.gruppeID == g.id)
            }
            if p.gruppeID != nil {
                Button("Uten gruppe", systemImage: "tray") { flyttPalett(p, til: nil) }
            }
            Divider()
            Button("Ny gruppe …", systemImage: "folder.badge.plus") {
                gruppenavn = ""
                flyttesTilNyGruppe = p
                visNyGruppe = true
            }
        }
    }

    /// Palettkortene i et rutenett som tilpasser seg bredden: én kolonne på iPhone, flere på iPad og Mac.
    private func palettRutenett(_ liste: [PalettDokument]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 12, alignment: .top)],
                  alignment: .leading, spacing: 12) {
            ForEach(liste) { p in
                SveipForÅSlette(slett: { slettes = p }) {
                    kort(.palett(p)) {
                        PalettRad(dokument: p, velg: velgFarge)
                    } slipp: { farger in
                        flytt(farger, til: p, i: kontekst)
                    }
                    .contextMenu {
                        Button("Vurder paletten", systemImage: "text.magnifyingglass") { vurderes = p }
                            .disabled(p.farger.isEmpty)
                        Button("Skriftkontrast", systemImage: "a.square") { matrise = p }
                            .disabled(p.farger.count < 2)
                        Button("Skriv ut …", systemImage: "printer") { PalettUtskrift.skrivUt(p) }
                            .disabled(p.farger.isEmpty && p.gradienter.isEmpty)
                        Divider()
                        Button("Gi nytt navn …", systemImage: "character.cursor.ibeam") { omdøpes = p }
                        flyttTilGruppeMeny(p)
                        KopierTilMeny(farger: p.farger, navn: p.navn)
                        let (navn, farger, gradienter) = (p.navn, p.farger, p.gradienter)
                        DelSomLenke(navn: navn) { Lenkedeling.palett(navn: navn, farger: farger, gradienter: gradienter) }
                            .disabled(farger.isEmpty && gradienter.isEmpty)
                        Button("Lagre som …", systemImage: "square.and.arrow.down") { lagresSom = p }
                            .disabled(p.farger.isEmpty && p.gradienter.isEmpty)
                        Button("Slett palett", systemImage: "trash", role: .destructive) { slettes = p }
                    }
                }
            }
        }
    }

    /// Antall paletter, til høyre i en gruppeoverskrift.
    private func antall(_ n: Int) -> some View {
        Text("\(n)").font(.callout).foregroundStyle(Color.sekundærTekst).monospacedDigit()
    }

    enum Valg: Hashable {
        case enkeltfarger
        case palett(PalettDokument)
    }

    private var nyPalettMeny: some View {
        Menu("Ny palett", systemImage: "plus") {
            Button("Ny tom palett …", systemImage: "square.dashed") {
                nyPalettNavn = ""
                visNyPalett = true
            }
            Button("Ny palett fra verdiord (KI)", systemImage: "sparkles") { visVerdiord = true }
            Button("Importer fra ASE …", systemImage: "square.and.arrow.down") { importererASE = true }
            Divider()
            Button("Ny palettgruppe …", systemImage: "folder.badge.plus") {
                gruppenavn = ""
                flyttesTilNyGruppe = nil
                visNyGruppe = true
            }
        }
    }

    /// ASE-filer som nye paletter: én palett per fargegruppe i filen (se `Bibliotekimport.aseSomPaletter`).
    private func importerASE(_ urler: [URL]) {
        // Per fil: flere fargegrupper blir en palettgruppe med filnavnet, én gruppe blir bare én palett.
        var filer: [(navn: String, paletter: [Palett])] = []
        for url in urler {
            let tilgang = url.startAccessingSecurityScopedResource()
            defer { if tilgang { url.stopAccessingSecurityScopedResource() } }
            do {
                filer.append((url.deletingPathExtension().lastPathComponent,
                              try Bibliotekimport.aseSomPaletter(Data(contentsOf: url), filnavn: url.lastPathComponent)))
            } catch {
                importfeil = String(localized: "«\(url.lastPathComponent)» kunne ikke leses: \(error.localizedDescription)")
            }
        }
        guard !filer.isEmpty else { return }
        kontekst.angresteg("Importer paletter") {
            for fil in filer {
                var gruppe: UUID?
                if fil.paletter.count > 1 {
                    let g = PalettGruppe(navn: fil.navn)
                    kontekst.insert(g)
                    gruppe = g.id
                }
                for p in fil.paletter {
                    let dokument = PalettDokument(navn: p.navn, farger: p.farger)
                    dokument.gruppeID = gruppe
                    kontekst.insert(dokument)
                }
            }
        }
    }

    var body: some View {
        NavigationStack(path: $sti) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if !arbeidsbenk.målinger.isEmpty {
                        Listeseksjon("plukkede", tittel: "Plukkede farger") {
                            IkkeLagretMerke()
                            PlukkedeFargerValg()
                        } innhold: {
                            MidlertidigeFarger(medTittel: false)
                                .padding(12)
                                .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Color.sekundærTekst.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [5, 3])))
                        }
                    }
                    Listeseksjon("enkeltfarger", tittel: "Enkeltfarger") {
                        Text("\(enkeltfarger.count)").font(.callout).foregroundStyle(Color.sekundærTekst).monospacedDigit()
                    } innhold: {
                        kort(.enkeltfarger) {
                            EnkeltfargerRad(farger: enkeltfarger.map(\.palettFarge), paletter: paletter, velg: velgFarge)
                        } slipp: { farger in
                            flyttTilEnkeltfarger(farger, i: kontekst)
                        }
                    }

                    GradientSeksjon()

                    Listeseksjon("paletter", tittel: "Paletter") {
                        if iKolonne { nyPalettMeny.labelStyle(.iconOnly).menuIndicator(.hidden).fixedSize() }
                    } innhold: {
                        if paletter.isEmpty {
                            Text("Ingen paletter ennå. Trykk + for en tom palett eller en palett fra verdiord, eller lag en fra Studio, Overgang eller Utplukk.")
                                .font(.callout)
                                .foregroundStyle(Color.sekundærTekst)
                        }
                        // Palettgrupper (sammenleggbare), deretter paletter uten gruppe.
                        ForEach(sorterteGrupper) { g in
                            let iGruppen = paletter.filter { $0.gruppeID == g.id }
                            Listeseksjon("gruppe.\(g.id.uuidString)",
                                         tittel: Text(verbatim: g.navn.isEmpty ? String(localized: "Uten navn") : g.navn),
                                         undernivå: true, ikon: "folder") {
                                antall(iGruppen.count)
                                Menu {
                                    Button("Gi gruppen nytt navn …", systemImage: "character.cursor.ibeam") {
                                        gruppenavn = g.navn
                                        omdøpesGruppe = g
                                    }
                                    Button("Slett gruppe …", systemImage: "trash", role: .destructive) { slettesGruppe = g }
                                } label: {
                                    Image(systemName: "ellipsis.circle").minsteTrykkflate()
                                }
                                .menuIndicator(.hidden)
                                .fixedSize()
                                .accessibilityLabel(Text("Valg for gruppen"))
                            } innhold: {
                                if iGruppen.isEmpty {
                                    Text("Ingen paletter i gruppen ennå. Flytt paletter hit med «Flytt til gruppe» i menyen på hver palett.")
                                        .font(.callout)
                                        .foregroundStyle(Color.sekundærTekst)
                                }
                                palettRutenett(iGruppen)
                            }
                        }
                        let uten = paletterUtenGruppe
                        if grupper.isEmpty {
                            palettRutenett(uten)
                        } else if !uten.isEmpty {
                            Listeseksjon("gruppe.ingen", tittel: Text("Uten gruppe"), undernivå: true, ikon: "tray") {
                                antall(uten.count)
                            } innhold: {
                                palettRutenett(uten)
                            }
                        }
                    }
                    Label(Lagring.synkroniserer ? "Paletter, gradienter og enkeltfarger synkroniseres via iCloud."
                                                : "Paletter, gradienter og enkeltfarger lagres bare på denne enheten.",
                          systemImage: Lagring.synkroniserer ? "icloud" : "iphone")
                        .font(.footnote)
                        .foregroundStyle(Color.sekundærTekst)
                        .padding(.top, 8)
                    // Luft over presentasjonen av appen, så den skiller seg fra palettene (mest i bred visning).
                    Utviklerlinje()
                        .padding(.top, iKolonne ? 8 : 24)
                }
                .padding()
            }
            .background(Color(white: 0.5).opacity(0.06))
            .navigationTitle("Paletter")
            .toolbar {
                if !iKolonne { nyPalettMeny }
            }
            #if DEBUG
            // Test: `-lagreSomTest` åpner «Lagre som» for første palett.
            .task { if UserDefaults.standard.bool(forKey: "lagreSomTest") { lagresSom = paletter.first } }
            #endif
            .sheet(item: $lagresSom) { p in
                LagreSomArk(innhold: Lagringsinnhold(navn: p.navn, farger: p.farger, gradienter: p.gradienter))
            }
            .fileImporter(isPresented: $importererASE, allowedContentTypes: [UTType(filenameExtension: "ase") ?? .data, .data],
                          allowsMultipleSelection: true) { resultat in
                if let urler = try? resultat.get() { importerASE(urler) }
            }
            .alert("Ny palettgruppe", isPresented: $visNyGruppe) {
                TextField("Navn", text: $gruppenavn)
                Button("Avbryt", role: .cancel) { flyttesTilNyGruppe = nil }
                Button("Opprett", action: opprettGruppe)
            } message: {
                if let p = flyttesTilNyGruppe { Text("«\(p.navn)» flyttes til den nye gruppen.") }
            }
            .alert("Gi gruppen nytt navn", isPresented: Binding(get: { omdøpesGruppe != nil }, set: { if !$0 { omdøpesGruppe = nil } })) {
                TextField("Navn", text: $gruppenavn)
                Button("Avbryt", role: .cancel) {}
                Button("Lagre") {
                    let navn = gruppenavn.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let g = omdøpesGruppe, !navn.isEmpty { kontekst.angresteg("Gi gruppen nytt navn") { g.navn = navn } }
                }
            }
            .alert("Slette gruppen «\(slettesGruppe?.navn ?? "")»?", isPresented: Binding(get: { slettesGruppe != nil }, set: { if !$0 { slettesGruppe = nil } })) {
                Button("Avbryt", role: .cancel) {}
                Button("Slett gruppe", role: .destructive) {
                    if let g = slettesGruppe {
                        kontekst.angresteg("Slett palettgruppe") {
                            for p in paletter where p.gruppeID == g.id { p.gruppeID = nil }
                            kontekst.delete(g)
                        }
                    }
                }
            } message: {
                Text("Palettene i gruppen beholdes og flyttes til «Uten gruppe».")
            }
            .alert("Importen mislyktes", isPresented: Binding(get: { importfeil != nil }, set: { if !$0 { importfeil = nil } })) {
                Button("OK", role: .cancel) {}
            } message: { Text(importfeil ?? "") }
            .sheet(isPresented: $visVerdiord) {
                NavigationStack {
                    VerdiordVisning()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) { Button("Lukk") { visVerdiord = false } }
                        }
                }
            }
            // Varsel midt på skjermen: en boble (iPad) bundet til et kort i rutenettet havnet på uventede steder.
            .modifier(SlettPalettBekreftelse(navn: slettes?.navn ?? "",
                                             vises: Binding(get: { slettes != nil }, set: { if !$0 { slettes = nil } })) {
                if let p = slettes {
                    sti.removeAll { $0 == .palett(p) }
                    kontekst.angresteg("Slett palett") { kontekst.delete(p) }
                }
            })
            .omdøpPalett($omdøpes)
            .sheet(item: $vurderes) { PalettVurderingArk(palett: $0.palett) }
            .sheet(item: $matrise) { KontrastmatriseArk(palett: $0.palett) }
            // ⌘N (Arkiv › Ny palett).
            .onChange(of: arbeidsbenk.nyPalettForespurt) { _, ny in
                guard ny else { return }
                arbeidsbenk.nyPalettForespurt = false
                nyPalettNavn = ""
                visNyPalett = true
            }
            .alert("Ny palett", isPresented: $visNyPalett) {
                TextField("Navn", text: $nyPalettNavn)
                Button("Avbryt", role: .cancel) {}
                Button("Opprett") {
                    let navn = nyPalettNavn.trimmingCharacters(in: .whitespacesAndNewlines)
                    let p = PalettDokument(navn: navn.isEmpty ? String(localized: "Ny palett") : navn)
                    kontekst.insert(p)
                    velg(.palett(p))
                }
            } message: {
                Text("Gi paletten et navn. Du kan endre det senere.")
            }
            .navigationDestination(for: Valg.self) { v in
                Group {
                    switch v {
                    case .enkeltfarger: EnkeltfargerVisning()
                    case .palett(let p): PalettDetalj(dokument: p)
                    }
                }
                .environment(\.iPalettkolonne, iKolonne)
                // Vinduets egen tilbakepil (fra kolonnens navigasjon) skjules; knappen over brukes i stedet.
                .navigationBarBackButtonHidden(iKolonne)
                // I palettkolonnen på Mac vises ingen navigasjonslinje med tilbakeknapp; lag en selv.
                .safeAreaInset(edge: .top, spacing: 0) {
                    if iKolonne {
                        HStack {
                            Button { sti.removeAll() } label: {
                                Label("Alle paletter", systemImage: "chevron.left")
                            }
                            .buttonStyle(.borderless)
                            .keyboardShortcut("[", modifiers: .command)
                            .help("Tilbake til alle paletter (⌘[)")
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.bar)
                    }
                }
            }
        }
    }

    private func velg(_ v: Valg) {
        sti = [v]
    }

    /// Trykk på en fargeprøve: fargen blir aktiv. I palettkolonnen blir du der du er; på egen
    /// Paletter-fane går appen til Studio, som når en farge velges inne i en palett.
    private func velgFarge(_ farge: Farge) {
        arbeidsbenk.aktivFarge = farge
        if !iKolonne { arbeidsbenk.valgtFane = .studio }
    }

    /// Kort som kan trykkes (åpner) og som tar imot slippede farger.
    private func kort<Innhold: View>(_ v: Valg, @ViewBuilder innhold: () -> Innhold,
                                     slipp: @escaping ([PalettFarge]) -> Bool) -> some View {
        HStack(alignment: .center, spacing: 8) {
            innhold()
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Color.tertiærTekst)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(målrettet == v ? Color.accentColor : .clear,
                              lineWidth: målrettet == v ? 3 : 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onTapGesture { velg(v) }
        .tarImotFarger { farger in
            slipp(farger)
        } isTargeted: { over in
            målrettet = over ? v : (målrettet == v ? nil : målrettet)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { velg(v) }
    }
}

/// Dra og slipp flytter: fargen legges i målet og fjernes der den kom fra (en annen palett eller
/// Enkeltfarger). Farger uten kilde i appen (fra Studio, andre apper eller tekst) legges bare til.
@discardableResult
func flytt(_ farger: [PalettFarge], til mål: PalettDokument, i kontekst: ModelContext) -> Bool {
    let eksisterende = Set(mål.farger.map(\.id))
    let nye = farger.filter { !eksisterende.contains($0.id) }
    guard leggTil(nye, i: mål) else { return false }
    fjernFraKilder(nye, i: kontekst, unntattPalett: mål)
    return true
}

@discardableResult
func flyttTilEnkeltfarger(_ farger: [PalettFarge], i kontekst: ModelContext) -> Bool {
    let lagrede = Set(((try? kontekst.fetch(FetchDescriptor<LagretFarge>())) ?? []).map(\.id))
    let nye = farger.filter { !lagrede.contains($0.id) }
    guard !nye.isEmpty else { return false }
    lagreEnkeltfarger(nye, i: kontekst, navngi: false)
    fjernFraKilder(nye, i: kontekst, beholdEnkeltfarger: true)
    return true
}

/// Fjerner fargene (etter id) fra paletter og enkeltfarger de ligger i.
private func fjernFraKilder(_ farger: [PalettFarge], i kontekst: ModelContext,
                            unntattPalett: PalettDokument? = nil, beholdEnkeltfarger: Bool = false) {
    let ider = Set(farger.map(\.id))
    for p in (try? kontekst.fetch(FetchDescriptor<PalettDokument>())) ?? [] where p.id != unntattPalett?.id {
        if p.farger.contains(where: { ider.contains($0.id) }) {
            p.farger.removeAll { ider.contains($0.id) }
        }
    }
    if !beholdEnkeltfarger {
        for lagret in (try? kontekst.fetch(FetchDescriptor<LagretFarge>())) ?? [] where ider.contains(lagret.id) {
            kontekst.delete(lagret)
        }
    }
}

/// Lagrer farger som enkeltfarger (uten palett), med nye identiteter.
/// Lagrer farger som enkeltfarger. Én ny farge lagres med en gang og åpner så et ark for å gi den
/// navn (Avbryt beholder den uten navn), så fargen aldri går tapt om arket ikke kan vises.
func lagreEnkeltfarger(_ farger: [PalettFarge], i kontekst: ModelContext, navngi: Bool = true) {
    let nye = farger.map { LagretFarge($0.kopi) }
    for f in nye { kontekst.insert(f) }
    if navngi, nye.count == 1, let ny = nye.first, ny.palettFarge.navn.isEmpty {
        Arbeidsbenk.delt.navngiNy(ny)
    }
}

struct EnkeltfargerRad: View {
    let farger: [PalettFarge]
    let paletter: [PalettDokument]
    var velg: (Farge) -> Void = { _ in }
    @Environment(\.modelContext) private var kontekst
    @Environment(Arbeidsbenk.self) private var arbeidsbenk

    var body: some View {
        // Tittel og antall står i seksjonsoverskriften over kortet.
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Nyeste først, så den nye fargen havner der feltet står.
                    LeggTilFelt(farge: arbeidsbenk.fargeÅLeggeTil.farge, navn: arbeidsbenk.fargeÅLeggeTil.navn, hjørne: 6, visTekst: false) {
                        kontekst.angresteg("Legg til farge") { lagreEnkeltfarger([arbeidsbenk.fargeÅLeggeTil], i: kontekst) }
                    }
                    .frame(width: 44, height: 44)
                    ForEach(farger.prefix(60)) { pf in
                        FargeRute(farge: pf.farge, navn: pf.navn, visTekst: false, hjørne: 6,
                                  fjern: { slettEnkeltfarge(pf.id, i: kontekst) },
                                  palettFarge: pf, ekstraMeny: AnyView(FlyttMeny(farge: pf, fra: nil)))
                            .frame(width: 44, height: 44)
                            .onTapGesture { velg(pf.farge) }
                            .accessibilityAction(named: "Gjør til aktiv farge") { velg(pf.farge) }
                    }
                    if farger.isEmpty {
                        Text("Farger lagret uten palett havner her").font(.caption).foregroundStyle(Color.sekundærTekst)
                    }
                }
            }
        }
    }
}

/// Alle enkeltfarger som rutenett.
struct EnkeltfargerVisning: View {
    @Environment(\.modelContext) private var kontekst
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @Query(sort: \LagretFarge.opprettet, order: .reverse) private var lagrede: [LagretFarge]
    @State private var leggIPalett: [PalettFarge]?
    @State private var navngis: LagretFarge?
    @Environment(\.iPalettkolonne) private var iKolonne

    private let rutenett = [GridItem(.adaptive(minimum: 96), spacing: 10)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: rutenett, spacing: 10) {
                // Nyeste først, så den nye fargen havner der feltet står.
                LeggTilFelt(farge: arbeidsbenk.fargeÅLeggeTil.farge, navn: arbeidsbenk.fargeÅLeggeTil.navn) {
                    kontekst.angresteg("Legg til farge") { lagreEnkeltfarger([arbeidsbenk.fargeÅLeggeTil], i: kontekst) }
                }
                .aspectRatio(1, contentMode: .fit)
                ForEach(lagrede) { lagret in
                    let pf = lagret.palettFarge
                    FargeRute(farge: pf.farge, navn: pf.navn,
                              leggIPalett: { _ in leggIPalett = [pf] },
                              fjern: { kontekst.angresteg("Slett farge") { kontekst.delete(lagret) } },
                              navngi: { navngis = lagret }, palettFarge: pf)
                        .aspectRatio(1, contentMode: .fit)
                        .onTapGesture {
                            arbeidsbenk.aktivFarge = pf.farge
                            // I palettkolonnen blir du der du er; ellers vises fargen i Studio.
                            if !iKolonne { arbeidsbenk.valgtFane = .studio }
                        }
                }
            }
            .padding()
        }
        .overlay {
            if lagrede.isEmpty {
                ContentUnavailableView("Ingen enkeltfarger", systemImage: "square.dashed",
                                       description: Text("Lagre en farge uten palett fra Studio, Utplukk eller «Legg i palett»."))
            }
        }
        .navigationTitle("Enkeltfarger")
        .tarImotFarger { farger in
            flyttTilEnkeltfarger(farger, i: kontekst)
        }
        .fargetastatur(kopier: { lagrede.map(\.palettFarge) }, limInn: { lagreEnkeltfarger($0, i: kontekst) })
        .toolbar {
            ToolbarItemGroup {
                LimInnFargerKnapp { lagreEnkeltfarger($0, i: kontekst) }
                Button("Legg alle i palett", systemImage: "square.and.arrow.down.on.square") {
                    leggIPalett = lagrede.map(\.palettFarge)
                }
                .disabled(lagrede.isEmpty)
            }
        }
        .sheet(isPresented: Binding(get: { leggIPalett != nil }, set: { if !$0 { leggIPalett = nil } })) {
            VelgPalettArk(farger: leggIPalett ?? [], tilbyEnkeltfarger: false)
        }
        .sheet(item: $navngis) { lagret in
            NavngiArk(farge: lagret.palettFarge) { navn in
                var pf = lagret.palettFarge
                pf.navn = navn
                lagret.palettFarge = pf
            }
        }
    }
}

/// Legger slippede farger i en palett. Farger som allerede finnes i paletten (samme id) hoppes over,
/// så et slipp tilbake på samme palett ikke lager duplikater.
@discardableResult
func leggTil(_ farger: [PalettFarge], i dokument: PalettDokument) -> Bool {
    let eksisterende = Set(dokument.farger.map(\.id))
    let nye = farger.filter { !eksisterende.contains($0.id) }.map(\.kopi)
    guard !nye.isEmpty else { return false }
    dokument.farger += nye
    return true
}

/// Rad i palettlisten: navn og små fargeprøver som kan dras til andre paletter.
struct PalettRad: View {
    let dokument: PalettDokument
    @Environment(\.modelContext) private var kontekst
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    /// Trykk på en fargeprøve velger fargen (resten av kortet åpner paletten).
    var velg: (Farge) -> Void = { _ in }

    var body: some View {
        // Gradientene dekodes fra JSON; les dem én gang per tegning.
        let gradienter = dokument.gradienter
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(dokument.navn.isEmpty ? String(localized: "Uten navn") : dokument.navn).font(.headline)
                Spacer()
                Text("\(dokument.farger.count)").font(.caption).foregroundStyle(Color.sekundærTekst).monospacedDigit()
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(dokument.farger) { pf in
                        FargeRute(farge: pf.farge, navn: pf.navn, visTekst: false, hjørne: 6,
                                  fjern: { kontekst.angresteg("Slett farge") { dokument.farger.removeAll { $0.id == pf.id } } }, palettFarge: pf,
                                  ekstraMeny: AnyView(FlyttMeny(farge: pf, fra: dokument)))
                            .frame(width: 44, height: 44)
                            .onTapGesture { velg(pf.farge) }
                            .accessibilityAction(named: "Gjør til aktiv farge") { velg(pf.farge) }
                    }
                    // Gradienter som bredere brikker etter fargene.
                    ForEach(gradienter) { g in
                        GradientStripe(oppsett: g.oppsett).frame(width: 72, height: 44)
                    }
                    if dokument.farger.isEmpty && gradienter.isEmpty {
                        Text("Slipp farger her, eller åpne paletten for å legge til").font(.caption).foregroundStyle(Color.sekundærTekst)
                    }
                }
            }
        }
    }
}

struct PalettStripe: View {
    let farger: [Farge]
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(farger.enumerated()), id: \.offset) { $1.swiftUI }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

struct PalettDetalj: View {
    @Bindable var dokument: PalettDokument
    @Environment(\.modelContext) private var kontekst
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @State private var visSkala: PalettFarge?
    /// Hva palettvisningen viser: fargene, fargene i et lysmiljø (rett i rutene), eller skriftkontrasten mellom dem.
    /// Huskes mellom palettene.
    enum Visning: String { case farger, lys, skriftkontrast }
    @AppStorage("palett.visning") private var visning: Visning = .farger
    @AppStorage("seILys.somFoto") private var somFoto = false
    @State private var lysbibliotek = Lysbibliotek.delt
    @State private var visLagreSom = false
    @State private var vurdering: PalettVurdering?
    @State private var kiArbeider = false
    @State private var kiFeil: String?
    @State private var navngisPalettfarge: PalettFarge?
    @State private var slettSpørsmål = false
    /// Fargen det dras over (for å endre rekkefølge), markert med ramme.
    @State private var slippMål: UUID?
    @Environment(\.dismiss) private var lukkPalett
    /// I palettkolonnen på Mac: handlingene ligger i en rad under tittelen, ikke i vinduets verktøylinje.
    @Environment(\.iPalettkolonne) private var iKolonne
    @State private var redigererNavn = false
    @FocusState private var navnIFokus: Bool

    private func startNavneredigering() {
        redigererNavn = true
        // Fokus etter at feltet er på plass.
        Task { @MainActor in navnIFokus = true }
    }

    private let rutenett = [GridItem(.adaptive(minimum: 96), spacing: 10)]

    /// Analysen for «Se i lys», eller nil når modusen er av.
    private var lys: PalettLys? {
        guard visning == .lys, !dokument.farger.isEmpty else { return nil }
        return PalettLys(farger: dokument.farger, miljø: lysbibliotek.gjeldendeLysmiljø, somFoto: somFoto)
    }

    /// Farger sluppet på fargen `målID`: farger fra paletten flyttes dit (etter målet når de flyttes bakover,
    /// foran når de flyttes framover), farger fra andre steder settes inn som kopier foran målet.
    private func slipp(_ farger: [PalettFarge], på målID: UUID) -> Bool {
        slippMål = nil
        let ider = Set(farger.map(\.id))
        guard !ider.contains(målID), let målFør = dokument.farger.firstIndex(where: { $0.id == målID }) else { return false }
        let flyttes = farger.map { f in dokument.farger.first { $0.id == f.id } ?? f.kopi }
        let fraFør = dokument.farger.firstIndex { ider.contains($0.id) }
        var nye = dokument.farger
        nye.removeAll { ider.contains($0.id) }
        let mål = nye.firstIndex { $0.id == målID } ?? nye.count
        let innsett = (fraFør.map { $0 < målFør } ?? false) ? mål + 1 : mål
        kontekst.angresteg("Flytt farge") {
            withAnimation(.snappy) { dokument.farger = Array(nye[..<innsett]) + flyttes + Array(nye[innsett...]) }
        }
        return true
    }

    /// Flytter en farge ett steg fram (−1) eller bak (+1), for VoiceOver.
    private func flyttSteg(_ id: UUID, med steg: Int) {
        guard let i = dokument.farger.firstIndex(where: { $0.id == id }), dokument.farger.indices.contains(i + steg) else { return }
        kontekst.angresteg("Flytt farge") { dokument.farger.swapAt(i, i + steg) }
    }

    var body: some View {
        let lys = lys
        ScrollView {
            // Tittel med blyant: trykk på blyanten (eller tittelen) for å endre navnet.
            HStack(spacing: 8) {
                if redigererNavn {
                    TextField("Navn på paletten", text: $dokument.navn)
                        .textFieldStyle(.plain)
                        .focused($navnIFokus)
                        .submitLabel(.done)
                        .onSubmit { redigererNavn = false }
                } else {
                    Text(dokument.navn.isEmpty ? String(localized: "Uten navn") : dokument.navn)
                        .foregroundStyle(dokument.navn.isEmpty ? Color.sekundærTekst : Color.primary)
                        .onTapGesture { startNavneredigering() }
                }
                Button {
                    if redigererNavn { redigererNavn = false } else { startNavneredigering() }
                } label: {
                    Image(systemName: redigererNavn ? "checkmark.circle.fill" : "pencil")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .help(redigererNavn ? "Ferdig" : "Endre navnet")
                .accessibilityLabel(redigererNavn ? "Ferdig med navnet" : "Endre navnet på paletten")
                Spacer(minLength: 0)
            }
            .font(.title2.weight(.semibold))
            .padding(.horizontal)
            .padding(.top, 28)
            .onChange(of: navnIFokus) { _, fokus in if !fokus { redigererNavn = false } }
            if iKolonne {
                HStack(spacing: 14) { handlinger }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .menuIndicator(.hidden)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }
            if let lys {
                PalettLysValg(lys: lys).padding([.horizontal, .top])
            }
            if visning == .skriftkontrast && dokument.farger.count >= 2 {
                Kontrastmatrise(farger: dokument.farger).padding()
            } else {
                LazyVGrid(columns: rutenett, spacing: 10) {
                    ForEach(dokument.farger) { pf in
                        // Fargerutens egen meny (høyreklikk / trykk og hold) har Slett; den overstyrer en ytre meny.
                        let iLyset = lys?.iLyset(pf)
                        FargeRute(farge: pf.farge, navn: pf.navn, visTekst: iLyset == nil,
                                  fjern: { kontekst.angresteg("Slett farge") { dokument.farger.removeAll { $0.id == pf.id } } },
                                  navngi: { navngisPalettfarge = pf }, palettFarge: pf,
                                  ekstraMeny: AnyView(Group {
                                      Button("Lag toneskala", systemImage: "square.3.layers.3d") { visSkala = pf }
                                      FlyttMeny(farge: pf, fra: dokument)
                                  }))
                            .aspectRatio(1, contentMode: .fit)
                            // Se i lys: fargen i lyset i nedre halvdel.
                            .overlay {
                                if let iLyset, let skift = lys?.skift(pf) { LysHalvdel(farge: iLyset, skift: skift) }
                            }
                            .onTapGesture {
                                arbeidsbenk.aktivFarge = pf.farge
                                // I palettkolonnen blir du der du er; ellers vises fargen i Studio.
                                if !iKolonne { arbeidsbenk.valgtFane = .studio }
                            }
                            // Dra en farge hit for å endre rekkefølgen (eller sette inn en farge fra et annet sted her).
                            .dropDestination(for: PalettFarge.self) { farger, _ in
                                slipp(farger, på: pf.id)
                            } isTargeted: { over in
                                if over { slippMål = pf.id } else if slippMål == pf.id { slippMål = nil }
                            }
                            .overlay {
                                if slippMål == pf.id {
                                    RoundedRectangle(cornerRadius: 10).strokeBorder(Color.accentColor, lineWidth: 3)
                                }
                            }
                            .accessibilityAction(named: "Flytt fram") { flyttSteg(pf.id, med: -1) }
                            .accessibilityAction(named: "Flytt bak") { flyttSteg(pf.id, med: 1) }
                    }
                    LeggTilFelt(farge: arbeidsbenk.fargeÅLeggeTil.farge, navn: arbeidsbenk.fargeÅLeggeTil.navn) {
                        kontekst.angresteg("Legg til farge") { dokument.farger.append(arbeidsbenk.fargeÅLeggeTil.kopi) }
                    }
                    .aspectRatio(1, contentMode: .fit)
                }
                .padding()
            }
            if let lys {
                PalettLysPar(lys: lys).padding(.horizontal).padding(.bottom)
            }
            // Gradienter i paletten, under fargene.
            PalettGradientListe(dokument: dokument)
        }
        // Navnet står i tittelfeltet; navigasjonslinjen viser det ikke i tillegg.
        .navigationTitle("")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .tarImotFarger { farger in
            flytt(farger, til: dokument, i: kontekst)
        }
        .fargetastatur(kopier: { dokument.farger }, limInn: { farger in kontekst.angresteg("Lim inn farger") { dokument.farger += farger } })
        // ⇧⌘S: «Lagre som …» for denne paletten.
        .focusedSceneValue(\.palettlagring, dokument.farger.isEmpty && dokument.gradienter.isEmpty ? nil
            : Palettlagring(id: dokument.id) { visLagreSom = true })
        // ⌘P skriver ut denne paletten.
        .focusedSceneValue(\.palettutskrift, dokument.farger.isEmpty && dokument.gradienter.isEmpty ? nil
            : Palettutskrift(id: dokument.id, navn: dokument.navn.isEmpty ? String(localized: "Uten navn") : dokument.navn) { PalettUtskrift.skrivUt(dokument) })
        .toolbar {
            if !iKolonne {
                ToolbarItemGroup { handlinger }
            }
        }
        .sheet(item: $visSkala) { pf in
            ToneskalaArk(grunnfarge: pf) { nye in dokument.farger += nye }
        }
        .sheet(isPresented: $visLagreSom) {
            LagreSomArk(innhold: Lagringsinnhold(navn: dokument.navn, farger: dokument.farger, gradienter: dokument.gradienter))
        }
        .sheet(item: $navngisPalettfarge) { pf in
            NavngiArk(farge: pf) { navn in
                var f = dokument.farger
                if let i = f.firstIndex(where: { $0.id == pf.id }) { f[i].navn = navn }
                dokument.farger = f
            }
        }
        .sheet(item: $vurdering) { VurderingArk(vurdering: $0, farger: dokument.farger) }
        .modifier(SlettPalettBekreftelse(navn: dokument.navn, vises: $slettSpørsmål, slett: slettPalett))
        .alert("KI", isPresented: Binding(get: { kiFeil != nil }, set: { if !$0 { kiFeil = nil } })) {
            Button("OK") {}
        } message: { Text(kiFeil ?? "") }
    }

    /// Lukk paletten først, så visningen ikke tegnes for en slettet palett.
    private func slettPalett() {
        let dokument = dokument
        lukkPalett()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            kontekst.angresteg("Slett palett") { kontekst.delete(dokument) }
        }
    }

    /// Av/på for en visning; de utelukker hverandre.
    private func visningsvalg(_ v: Visning) -> Binding<Bool> {
        Binding(get: { visning == v }, set: { visning = $0 ? v : .farger })
    }

    /// Knappene for paletten: i verktøylinjen, eller i en rad under tittelen i palettkolonnen.
    @ViewBuilder private var handlinger: some View {
        LimInnFargerKnapp { farger in kontekst.angresteg("Lim inn farger") { dokument.farger += farger } }
        Toggle(isOn: visningsvalg(.skriftkontrast)) {
            Label("Skriftkontrast", systemImage: visning == .skriftkontrast ? "a.square.fill" : "a.square")
        }
        .toggleStyle(.button)
        .disabled(dokument.farger.count < 2)
        .help(visning == .skriftkontrast ? "Vis fargene" : "Skriftkontrast mellom fargene")
        Toggle(isOn: visningsvalg(.lys)) {
            Label("Se i lys", systemImage: visning == .lys ? "lightbulb.fill" : "lightbulb")
        }
        .toggleStyle(.button)
        .disabled(dokument.farger.isEmpty)
        .help(visning == .lys ? "Vis fargene uten lys" : "Se fargene i et lysmiljø")
        Button {
            Task { await vurder() }
        } label: {
            if kiArbeider { ProgressView().controlSize(.small) } else { Label("Vurder paletten", systemImage: "text.magnifyingglass") }
        }
        .disabled(dokument.farger.isEmpty || kiArbeider)
        .help("Vurder paletten")
        Button("Skriv ut …", systemImage: "printer") { PalettUtskrift.skrivUt(dokument) }
            .disabled(dokument.farger.isEmpty && dokument.gradienter.isEmpty)
            .help("Skriv ut paletten (A4, fargeflater i CIELab)")
        Menu("Del", systemImage: "square.and.arrow.up") {
            Button("Lagre som …", systemImage: "square.and.arrow.down") { visLagreSom = true }
                .disabled(dokument.farger.isEmpty && dokument.gradienter.isEmpty)
            Divider()
            let navn = dokument.navn, farger = dokument.farger, gradienter = dokument.gradienter
            DelSomLenke(navn: navn) { Lenkedeling.palett(navn: navn, farger: farger, gradienter: gradienter) }
                .disabled(farger.isEmpty && gradienter.isEmpty)
            Button("Kopier alle som hex") { Utklippstavle.kopier(dokument.palett) }
            Button("Kopier alle som OKLCH") { Utklippstavle.kopier(dokument.palett, som: .okLCH) }
            KopierTilMeny(farger: dokument.farger, navn: dokument.navn)
        }
        .help("Lagre som, del og kopier")
        Button("Slett palett", systemImage: "trash", role: .destructive) { slettSpørsmål = true }
            .help("Slett paletten")
    }

    private func vurder() async {
        kiArbeider = true
        defer { kiArbeider = false }
        do { vurdering = try await Palettvurderer.vurder(dokument.palett) }
        catch { kiFeil = error.localizedDescription }
    }
}

/// Vurderer paletten når arket åpnes (fra palettens meny i oversikten), med fremdrift mens det pågår.
struct PalettVurderingArk: View {
    let palett: Palett
    @State private var vurdering: PalettVurdering?
    @State private var feil: String?
    @Environment(\.dismiss) private var lukk

    var body: some View {
        NavigationStack {
            Group {
                if let vurdering {
                    Form { PalettVurderingInnhold(vurdering: vurdering, farger: palett.farger) }.formStyle(.grouped)
                } else if let feil {
                    ContentUnavailableView("Kunne ikke vurdere paletten", systemImage: "xmark.circle", description: Text(feil))
                } else {
                    ProgressView("Vurderer «\(palett.navn)» …").frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Vurdering")
            .toolbar { Button("Ferdig") { lukk() } }
        }
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 520)
        #endif
        .task {
            do { vurdering = try await Palettvurderer.vurder(palett) }
            catch { feil = error.localizedDescription }
        }
    }
}

struct VurderingArk: View {
    let vurdering: PalettVurdering
    var farger: [PalettFarge] = []
    @Environment(\.dismiss) private var lukk

    var body: some View {
        NavigationStack {
            Form { PalettVurderingInnhold(vurdering: vurdering, farger: farger) }
                .formStyle(.grouped)
                .navigationTitle("Vurdering")
                .toolbar { Button("Ferdig") { lukk() } }
        }
    }
}

extension PalettVurdering: @retroactive Identifiable {
    public var id: String { oppsummering + fakta.joined() }
}

struct EksportDokument: FileDocument {
    static let readableContentTypes: [UTType] = [.data]
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

/// Legg farger i en ny palett (med eget navn) eller i en eksisterende.
struct VelgPalettArk: View {
    let farger: [PalettFarge]
    var foreslåttNavn: String = ""
    /// Vis «Lagre uten palett» (skjules når kilden allerede er enkeltfargene).
    var tilbyEnkeltfarger = true
    /// Sett navnefeltet for ny palett i fokus med en gang (når målet er en ny palett).
    var nyPalett = false
    /// Kalles når fargene er lagret (ikke ved Avbryt).
    var lagret: () -> Void = {}
    @Environment(\.modelContext) private var kontekst
    @Environment(\.dismiss) private var lukk
    @Query(sort: \PalettDokument.opprettet, order: .reverse) private var paletter: [PalettDokument]
    @State private var nyttNavn = ""
    @FocusState private var navnIFokus: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PalettStripe(farger: farger.map(\.farge)).frame(height: 32)
                }
                if tilbyEnkeltfarger {
                    Section {
                        Button(farger.count == 1 ? "Lagre som enkeltfarge" : "Lagre som \(farger.count) enkeltfarger",
                               systemImage: "plus.square") {
                            lagreEnkeltfarger(farger, i: kontekst)
                            lagret()
                            lukk()
                        }
                    } footer: { Group {
                        Text("Lagres uten palett, under «Enkeltfarger» i Paletter.")
                    }.foregroundStyle(Color.sekundærTekst) }
                }
                Seksjon("Ny palett") {
                    TextField("Navn på paletten", text: $nyttNavn)
                        .focused($navnIFokus)
                        .submitLabel(.done)
                        .onSubmit(opprett)
                    Button("Opprett og legg til", systemImage: "plus.square.fill.on.square.fill", action: opprett)
                        .disabled(nyttNavn.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                if !paletter.isEmpty {
                    Seksjon("Eksisterende paletter") {
                        ForEach(paletter) { p in
                            Button {
                                p.farger += farger.map(\.kopi)
                                lagret()
                                lukk()
                            } label: {
                                HStack {
                                    Text(p.navn.isEmpty ? String(localized: "Uten navn") : p.navn).foregroundStyle(.primary)
                                    Spacer()
                                    Text("\(p.farger.count)").foregroundStyle(Color.sekundærTekst).monospacedDigit()
                                    PalettStripe(farger: p.farger.map(\.farge)).frame(width: 90, height: 20)
                                }
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(farger.count == 1 ? "Lagre farge" : "Lagre \(farger.count) farger")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Avbryt") { lukk() } } }
            .onAppear {
                nyttNavn = foreslåttNavn
                if paletter.isEmpty || nyPalett { navnIFokus = true }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func opprett() {
        let navn = nyttNavn.trimmingCharacters(in: .whitespaces)
        guard !navn.isEmpty else { return }
        kontekst.insert(PalettDokument(navn: navn, farger: farger.map(\.kopi)))
        lagret()
        lukk()
    }
}

/// Lys–mørk-skala (50…950) rundt en farge.
struct ToneskalaArk: View {
    let grunnfarge: PalettFarge
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    var leggTil: ([PalettFarge]) -> Void
    @Environment(\.dismiss) private var lukk
    @State private var antall = 11
    @State private var demping = 0.6

    private var toner: [Farge] {
        let lysheter = antall == 11 ? Toneskala.standardLysheter : Toneskala.jevn(antall: antall)
        return Toneskala(lysheter: lysheter, kromaDemping: demping, gamut: arbeidsbenk.gamut).toner(for: grunnfarge.farge).map(arbeidsbenk.begrens)
    }

    var body: some View {
        NavigationStack {
            Form {
                Stepper("Trinn: \(antall)", value: $antall, in: 3...21)
                VStack(alignment: .leading) {
                    Text("Kromademping mot ytterpunktene")
                    Slider(value: $demping, in: 0...1)
                }
                PalettStripe(farger: toner).frame(height: 64)
            }
            .formStyle(.grouped)
            .navigationTitle("Toneskala")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Avbryt") { lukk() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Legg til") {
                        let basis = grunnfarge.visningsnavn
                        leggTil(toner.enumerated().map { i, f in
                            PalettFarge(navn: "\(basis) \(i + 1)", farge: f, opphav: .toneskala)
                        })
                        lukk()
                    }
                }
            }
        }
    }
}

/// «Flytt til» en annen palett. Uten `fra` (enkeltfarger) vises «Legg i palett».
/// «Kopier til» er forbeholdt kopiering til andre programmer (`KopierTilMeny`).
struct FlyttMeny: View {
    let farge: PalettFarge
    let fra: PalettDokument?
    @Query(sort: \PalettDokument.opprettet, order: .reverse) private var paletter: [PalettDokument]

    var body: some View {
        let andre = paletter.filter { $0.id != fra?.id }
        if !andre.isEmpty {
            if fra == nil {
                Menu("Legg i palett", systemImage: "plus.square.on.square") {
                    ForEach(andre) { p in Button(p.navn.isEmpty ? String(localized: "Uten navn") : p.navn) { leggTil([farge], i: p) } }
                }
            }
            if let fra {
                Menu("Flytt til", systemImage: "arrow.right.square") {
                    ForEach(andre) { p in
                        Button(p.navn.isEmpty ? String(localized: "Uten navn") : p.navn) {
                            if leggTil([farge], i: p) { fra.farger.removeAll { $0.id == farge.id } }
                        }
                    }
                }
            }
        }
    }
}

/// Gi en farge navn, med fargebeskrivelse som hjelp og forslag fra KI.
struct NavngiArk: View {
    let farge: PalettFarge
    /// Tittel og avbrytknapp; for nye farger «Ny enkeltfarge» og «Hopp over».
    var tittel: LocalizedStringKey = "Gi navn"
    var avbryt: LocalizedStringKey = "Avbryt"
    var lagre: (String) -> Void
    @Environment(\.dismiss) private var lukk
    @State private var navn = ""
    @State private var foreslår = false
    @FocusState private var fokus: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        FargeRute(farge: farge.farge, visTekst: false, hjørne: 8).frame(width: 56, height: 40)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(farge.farge.hex()).font(.callout.monospaced())
                            Text(Fargebeskrivelse.beskriv(farge.farge)).font(.caption).foregroundStyle(Color.sekundærTekst)
                        }
                    }
                    TextField("Navn, f.eks. «Fjordblå»", text: $navn)
                        .focused($fokus)
                        .submitLabel(.done)
                        .onSubmit(lagreOgLukk)
                }
                Section {
                    Button {
                        Task { await foreslå() }
                    } label: {
                        if foreslår { ProgressView() } else { Label("Foreslå navn", systemImage: "sparkles") }
                    }
                    .disabled(foreslår)
                } footer: { Group {
                    Text("Forslaget lages med Apple Intelligence på enheten når det er tilgjengelig.")
                }.foregroundStyle(Color.sekundærTekst) }
            }
            .formStyle(.grouped)
            .navigationTitle(tittel)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(avbryt) { lukk() } }
                ToolbarItem(placement: .confirmationAction) { Button("Lagre", action: lagreOgLukk) }
            }
            .onAppear {
                navn = farge.navn
                fokus = true
            }
        }
        .presentationDetents([.medium])
    }

    private func lagreOgLukk() {
        lagre(navn.trimmingCharacters(in: .whitespacesAndNewlines))
        lukk()
    }

    private func foreslå() async {
        foreslår = true
        defer { foreslår = false }
        let beskrivelse = Fargebeskrivelse.beskriv(farge.farge)
        let reserve = beskrivelse.prefix(1).uppercased() + beskrivelse.dropFirst()
        navn = (try? await Fargenavngiver.navngi([farge.farge]).first) ?? reserve
    }
}

/// Omdøping av palett i en dialog med tekstfelt.
private struct OmdøpPalett: ViewModifier {
    @Binding var palett: PalettDokument?
    @State private var navn = ""

    func body(content: Content) -> some View {
        content
            .alert("Gi paletten navn", isPresented: Binding(get: { palett != nil }, set: { if !$0 { palett = nil } })) {
                TextField("Navn", text: $navn)
                Button("Avbryt", role: .cancel) {}
                Button("Lagre") {
                    let rent = navn.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let palett, !rent.isEmpty { palett.navn = rent }
                }
            }
            .onChange(of: palett) { _, ny in navn = ny?.navn ?? "" }
    }
}

extension View {
    func omdøpPalett(_ palett: Binding<PalettDokument?>) -> some View { modifier(OmdøpPalett(palett: palett)) }
}

/// «<appnavn> er utviklet av …» – appnavnet hentes fra bunten, så det følger med ved navnebytte.
struct Utviklerlinje: View {
    private var appnavn: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String) ?? "Kolorist"
    }
    private var versjon: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? ""
    }

    @State private var visMetoder = false

    static var nettside: URL {
        Bundle.main.preferredLocalizations.first?.hasPrefix("en") == true
            ? URL(string: "https://kolorist.no/en/")! : URL(string: "https://kolorist.no/")!
    }

    private var bygg: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? ""
    }

    /// Minste høyde for radene: 44 pt på berøringsskjerm (HIG), lavere på Mac.
    private var radhøyde: CGFloat {
        #if os(macOS)
        32
        #else
        44
        #endif
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                Image("Appikon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 13.5, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 13.5, style: .continuous).strokeBorder(.separator, lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(appnavn).font(.headline)
                    Text("Fargepaletter for designere").font(.subheadline).foregroundStyle(Color.sekundærTekst)
                    if !versjon.isEmpty {
                        Text(bygg.isEmpty ? String(localized: "Versjon \(versjon)") : String(localized: "Versjon \(versjon) (\(bygg))"))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Color.sekundærTekst)
                    }
                }
            }
            .padding(.bottom, 12)
            .accessibilityElement(children: .combine)

            Divider()
            VStack(alignment: .leading, spacing: 2) {
                Text("Utviklet av Eivind Arnstein Johansen").font(.subheadline)
                Text("Institutt for design, NTNU").font(.caption).foregroundStyle(Color.sekundærTekst)
            }
            .padding(.vertical, 10)
            .accessibilityElement(children: .combine)

            Divider()
            Button { visMetoder = true } label: {
                rad(Label("Metoder og kilder", systemImage: "books.vertical"), tegn: "chevron.right")
            }
            .buttonStyle(.plain)
            Divider()
            // Nettsiden på appens språk.
            Link(destination: Self.nettside) {
                rad(Label("kolorist.no", systemImage: "safari"), tegn: "arrow.up.right")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .sheet(isPresented: $visMetoder) { MetoderArk() }
        .frame(maxWidth: 560, alignment: .leading)
        .padding(.top, 4)
    }

    /// En hel rad som kan trykkes, minst 44 pt høy på iPhone og iPad.
    private func rad(_ etikett: Label<Text, Image>, tegn: String) -> some View {
        HStack {
            // Ikonene i fast bredde, så tekstene står på linje.
            etikett.labelStyle(Ikonkolonne()).foregroundStyle(.tint)
            Spacer()
            Image(systemName: tegn).font(.footnote.weight(.semibold)).foregroundStyle(Color.tertiærTekst)
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity, minHeight: radhøyde, alignment: .leading)
        .contentShape(Rectangle())
    }
}

/// Etikett med ikonet i en kolonne med fast bredde, så teksten i flere rader under hverandre står på linje.
private struct Ikonkolonne: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 10) {
            configuration.icon.frame(width: 24)
            configuration.title
        }
    }
}

/// Sveip til venstre på et kort for å vise «Slett» (iPhone/iPad). Kortene ligger i en rullevisning,
/// ikke en `List` (der tar raden over dra-gesten for fargeprøvene), så sveipet er laget her.
/// Et langt sveip sletter direkte; slettingen bekreftes av kalleren.
struct SveipForÅSlette<Innhold: View>: View {
    var slett: () -> Void
    @ViewBuilder var innhold: Innhold

    #if os(iOS)
    @State private var åpen = false
    /// Sveipet mens fingeren er nede. Nullstilles av seg selv om gesten avbrytes (f.eks. av rulling).
    @GestureState private var drag: CGFloat = 0
    private let knappebredde: CGFloat = 88

    private var forskyvning: CGFloat { min(0, (åpen ? -knappebredde : 0) + drag) }

    private func sett(åpen nyÅpen: Bool) {
        withAnimation(.snappy(duration: 0.25)) { åpen = nyÅpen }
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            if forskyvning < 0 {
                Button(role: .destructive) {
                    sett(åpen: false)
                    slett()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "trash").font(.title3)
                        Text("Slett").font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(width: max(knappebredde - 8, -forskyvning - 8))
                    .frame(maxHeight: .infinity)
                    .background(Color.feil, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            innhold
                // Når knappen vises, lukker et trykk på kortet sveipet i stedet for å åpne paletten.
                // (Før offset, så laget følger kortet og ikke dekker slett-knappen.)
                .overlay {
                    if åpen {
                        Color.clear.contentShape(Rectangle()).onTapGesture { sett(åpen: false) }
                    }
                }
                .offset(x: forskyvning)
                .animation(.snappy(duration: 0.2), value: drag == 0)
        }
        // Kortet glir inn under sin egen kant, ikke over naboen i rutenettet (iPad og Mac har flere kolonner).
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .updating($drag) { g, tilstand, _ in
                    // Bare tydelig vannrette sveip; loddrette lar rullevisningen rulle.
                    guard abs(g.translation.width) > abs(g.translation.height) * 1.5 else { return }
                    tilstand = g.translation.width
                }
                .onEnded { g in
                    guard abs(g.translation.width) > abs(g.translation.height) * 1.5 else { return }
                    let mål = (åpen ? -knappebredde : 0) + g.translation.width
                    if mål < -knappebredde * 2.5 {
                        sett(åpen: false)
                        slett()
                    } else {
                        sett(åpen: mål < -knappebredde / 2)
                    }
                }
        )
        .accessibilityAction(named: "Slett") { slett() }
    }
    #else
    // Mac: slett via høyreklikkmenyen.
    var body: some View { innhold }
    #endif
}

extension EnvironmentValues {
    /// Visningen ligger i palettkolonnen på Mac (uten egen verktøylinje).
    @Entry var iPalettkolonne = false
}

/// Sletter en enkeltfarge (lagret uten palett) ut fra id-en.
func slettEnkeltfarge(_ id: UUID, i kontekst: ModelContext) {
    for lagret in (try? kontekst.fetch(FetchDescriptor<LagretFarge>())) ?? [] where lagret.id == id {
        kontekst.delete(lagret)
    }
}

/// «Slette «navn»?» med angremulighet, felles for palettlista og palettvisningen. Et varsel midt på skjermen, så det
/// ikke er avhengig av hvor knappen eller kortet står.
private struct SlettPalettBekreftelse: ViewModifier {
    let navn: String
    @Binding var vises: Bool
    let slett: () -> Void

    func body(content: Content) -> some View {
        content.alert("Slette «\(navn.isEmpty ? String(localized: "Uten navn") : navn)»?", isPresented: $vises) {
            Button("Slett palett", role: .destructive, action: slett)
            Button("Avbryt", role: .cancel) {}
        } message: {
            #if os(macOS)
            Text("Fargene og gradientene i paletten slettes også. Du kan angre med ⌘Z.")
            #else
            Text("Fargene og gradientene i paletten slettes også. Rist for å angre.")
            #endif
        }
    }
}
