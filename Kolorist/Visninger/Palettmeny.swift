import FargeKjerne
import SwiftData
import SwiftUI

/// Valg i palettmenyen som åpner et ark eller et varsel. Visningen menyen står i, viser dem med `paletthandlinger(_:)`.
enum Paletthandling: Identifiable, Hashable {
    case vurder(PalettDokument)
    case skriftkontrast(PalettDokument)
    case lagreSom(PalettDokument)
    case omdøp(PalettDokument)
    case slett(PalettDokument)
    case nyGruppe(PalettDokument)
    case vis3D(PalettDokument)

    var id: Self { self }

    var palett: PalettDokument {
        switch self {
        case .vurder(let p), .skriftkontrast(let p), .lagreSom(let p), .omdøp(let p), .slett(let p), .nyGruppe(let p),
             .vis3D(let p): p
        }
    }
}

/// Menyen for én palett (trykk og hold / høyreklikk), lik i palettlisten og palettkolonnen:
///
/// 1. Vurder paletten · Skriftkontrast · Lag designsystem · Vis i 3D
/// 2. Gi nytt navn … · Flytt til gruppe
/// 3. Kopier til · Del som lenke · Lagre som … · Skriv ut … · kildene (f.eks. filamentprøvene)
/// 4. Slett palett
struct PalettMeny: View {
    let palett: PalettDokument
    let utfør: (Paletthandling) -> Void
    let lagDesignsystem: (PalettDokument) -> Void
    @Environment(\.modelContext) private var kontekst
    @Query(sort: \PalettGruppe.opprettet) private var grupper: [PalettGruppe]

    private var tom: Bool { palett.farger.isEmpty && palett.gradienter.isEmpty }

    var body: some View {
        let p = palett
        Section {
            Button("Vurder paletten", systemImage: "text.magnifyingglass") { utfør(.vurder(p)) }
                .disabled(p.farger.isEmpty)
            Button("Skriftkontrast", systemImage: "a.square") { utfør(.skriftkontrast(p)) }
                .disabled(p.farger.count < 2)
            Button("Lag designsystem", systemImage: "square.stack.3d.up") { lagDesignsystem(p) }
                .disabled(p.farger.isEmpty)
            Button("Vis i 3D …", systemImage: "rotate.3d") { utfør(.vis3D(p)) }
                .disabled(p.farger.isEmpty)
        }
        Section {
            Button("Gi nytt navn …", systemImage: "character.cursor.ibeam") { utfør(.omdøp(p)) }
            flyttTilGruppe
        }
        Section {
            KopierTilMeny(farger: p.farger, navn: p.navn)
                .disabled(p.farger.isEmpty)
            let (navn, farger, gradienter) = (p.navn, p.farger, p.gradienter)
            DelSomLenke(navn: navn) { Lenkedeling.palett(navn: navn, farger: farger, gradienter: gradienter) }
                .disabled(tom)
            Button("Lagre som …", systemImage: "square.and.arrow.down") { utfør(.lagreSom(p)) }
                .disabled(tom)
            Button("Skriv ut …", systemImage: "printer") { PalettUtskrift.skrivUt(p) }
                .disabled(tom)
            KildeMeny(farger: p.farger)
        }
        Section {
            Button("Slett palett", systemImage: "trash", role: .destructive) { utfør(.slett(p)) }
        }
    }

    /// Flytt paletten til en gruppe (eller ut av den), eller til en ny gruppe.
    private var flyttTilGruppe: some View {
        Menu("Flytt til gruppe", systemImage: "folder") {
            ForEach(grupper.sorted { $0.navn.localizedStandardCompare($1.navn) == .orderedAscending }) { g in
                Button(g.navn.isEmpty ? String(localized: "Uten navn") : g.navn) { flytt(til: g.id) }
                    .disabled(palett.gruppeID == g.id)
            }
            if palett.gruppeID != nil {
                Button("Uten gruppe", systemImage: "tray") { flytt(til: nil) }
            }
            Divider()
            Button("Ny gruppe …", systemImage: "folder.badge.plus") { utfør(.nyGruppe(palett)) }
        }
    }

    private func flytt(til gruppe: UUID?) {
        let p = palett
        kontekst.angresteg("Flytt palett") { p.gruppeID = gruppe }
    }
}

/// Arkene og varslene for `PalettMeny`.
private struct Paletthandlinger: ViewModifier {
    @Binding var handling: Paletthandling?
    /// Kalles rett før paletten slettes (f.eks. for å lukke den om den er åpen).
    var slettes: (PalettDokument) -> Void
    @Environment(\.modelContext) private var kontekst
    @State private var gruppenavn = ""

    private func binding(_ hent: @escaping (Paletthandling) -> PalettDokument?) -> Binding<PalettDokument?> {
        Binding(get: { handling.flatMap(hent) }, set: { if $0 == nil { handling = nil } })
    }

    private var ark: Binding<Paletthandling?> {
        Binding(get: {
            switch handling {
            case .vurder, .skriftkontrast, .lagreSom, .vis3D: handling
            default: nil
            }
        }, set: { if $0 == nil { handling = nil } })
    }

    func body(content: Content) -> some View {
        content
            .sheet(item: ark) { h in
                switch h {
                case .vurder(let p): PalettVurderingArk(palett: p.palett)
                case .skriftkontrast(let p): KontrastmatriseArk(palett: p.palett)
                case .lagreSom(let p):
                    LagreSomArk(innhold: Lagringsinnhold(navn: p.navn, farger: p.farger, gradienter: p.gradienter,
                                                         tekstfarger: p.tekstfarger))
                case .vis3D(let p):
                    Fargerom3DArk(kilde: .farger(navn: p.navn.isEmpty ? String(localized: "Uten navn") : p.navn,
                                                 farger: p.farger.map(\.farge)))
                default: EmptyView()
                }
            }
            .omdøpPalett(binding { if case .omdøp(let p) = $0 { p } else { nil } })
            .modifier(SlettPalettBekreftelse(navn: handling?.palett.navn ?? "",
                                             vises: Binding(get: { if case .slett = handling { true } else { false } },
                                                            set: { if !$0 { handling = nil } })) {
                if case .slett(let p) = handling {
                    slettes(p)
                    kontekst.angresteg("Slett palett") { kontekst.delete(p) }
                }
            })
            .alert("Ny palettgruppe", isPresented: Binding(get: { if case .nyGruppe = handling { true } else { false } },
                                                           set: { if !$0 { handling = nil } })) {
                TextField("Navn", text: $gruppenavn)
                Button("Avbryt", role: .cancel) {}
                Button("Opprett") {
                    let navn = gruppenavn.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !navn.isEmpty, case .nyGruppe(let p) = handling else { return }
                    kontekst.angresteg("Ny palettgruppe") {
                        let g = PalettGruppe(navn: navn)
                        kontekst.insert(g)
                        p.gruppeID = g.id
                    }
                }
            } message: {
                if case .nyGruppe(let p) = handling { Text("«\(p.navn)» flyttes til den nye gruppen.") }
            }
            .onChange(of: handling) { _, ny in if case .nyGruppe = ny { gruppenavn = "" } }
    }
}

extension View {
    /// Viser arkene og varslene fra `PalettMeny`.
    func paletthandlinger(_ handling: Binding<Paletthandling?>, slettes: @escaping (PalettDokument) -> Void = { _ in }) -> some View {
        modifier(Paletthandlinger(handling: handling, slettes: slettes))
    }
}
