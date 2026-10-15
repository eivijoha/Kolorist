import FargeKjerne
import SwiftData
import SwiftUI

/// Liten gradientstripe (OKLab-overgangen mellom endepunktene), brukt i palettoversikten og -kolonnen.
struct GradientStripe: View {
    let oppsett: Gradientoppsett
    var hjørne: CGFloat = 6

    var body: some View {
        let prøver = Overgang.toner(fra: oppsett.fra, til: oppsett.til, antall: 16)
        LinearGradient(stops: prøver.enumerated().map { Gradient.Stop(color: $1.swiftUI, location: Double($0) / 15) },
                       startPoint: .leading, endPoint: .trailing)
            .clipShape(RoundedRectangle(cornerRadius: hjørne, style: .continuous))
            .accessibilityLabel(String(localized: "Gradient fra \(oppsett.fra.hex()) til \(oppsett.til.hex())"))
    }
}

/// «Legg gradienten i palett»: velg en palett, eller lag en ny med gradienten.
struct LeggGradientIPalettMeny: View {
    let oppsett: Gradientoppsett
    let navn: String
    @Environment(\.modelContext) private var kontekst
    @Query(sort: \PalettDokument.opprettet, order: .reverse) private var paletter: [PalettDokument]

    var body: some View {
        Menu("Legg gradienten i palett", systemImage: "swatchpalette") {
            ForEach(paletter) { p in
                Button(p.navn.isEmpty ? String(localized: "Uten navn") : p.navn) {
                    p.gradienter.append(PalettGradient(navn: navn, oppsett: oppsett))
                }
            }
            if !paletter.isEmpty { Divider() }
            Button("Ny palett med gradienten", systemImage: "plus") {
                let p = PalettDokument(navn: navn.isEmpty ? String(localized: "Ny palett") : navn)
                p.gradienter = [PalettGradient(navn: navn, oppsett: oppsett)]
                kontekst.insert(p)
            }
        }
    }
}

/// Gradientene i en åpen palett: navn, stripe og endepunkter. Trykk åpner gradienten i Overgang.
struct PalettGradientListe: View {
    @Bindable var dokument: PalettDokument
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @Environment(\.modelContext) private var kontekst
    @State private var slettes: PalettGradient?

    var body: some View {
        if !dokument.gradienter.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Gradienter").font(.headline)
                ForEach(dokument.gradienter) { g in
                    // Sveip til venstre for å slette (iPhone/iPad).
                    SveipForÅSlette(slett: { slettes = g }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(g.navn.isEmpty ? String(localized: "Uten navn") : g.navn).font(.subheadline.weight(.semibold)).lineLimit(1)
                        GradientStripe(oppsett: g.oppsett, hjørne: 8).frame(height: 44)
                        HStack {
                            Text(g.oppsett.fra.hex())
                            Spacer()
                            Text(g.oppsett.til.hex())
                        }
                        .font(.caption2.monospaced())
                        .foregroundStyle(Color.sekundærTekst)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { åpne(g) }
                    .gradientmeny(g.oppsett, navn: g.navn, åpne: { åpne(g) }, giNavn: { navn in
                        let id = g.id
                        kontekst.angresteg("Gi gradienten navn") {
                            dokument.gradienter = dokument.gradienter.map { var x = $0; if x.id == id { x.navn = navn }; return x }
                        }
                    }, slett: { slettes = g })
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction(named: "Åpne i Overgang") { åpne(g) }
                    // Bakgrunn, så slett-knappen ikke skinner gjennom mens raden glir.
                    .background(Color.skjemabakgrunn)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
            .alert("Slette «\(slettes.map { $0.navn.isEmpty ? String(localized: "Uten navn") : $0.navn } ?? "")»?",
                   isPresented: Binding(get: { slettes != nil }, set: { if !$0 { slettes = nil } })) {
                Button("Avbryt", role: .cancel) {}
                Button("Slett gradient", role: .destructive) {
                    if let id = slettes?.id {
                        kontekst.angresteg("Slett gradient") { dokument.gradienter.removeAll { $0.id == id } }
                    }
                }
            } message: {
                #if os(macOS)
                Text("Du kan angre med ⌘Z.")
                #else
                Text("Rist for å angre.")
                #endif
            }
        }
    }

    /// Åpner gradienten i Overgang (i palettkolonnen vises Overgang ved siden av).
    private func åpne(_ g: PalettGradient) {
        arbeidsbenk.åpne(g.oppsett)
    }
}

/// Menyen for én gradient (trykk og hold / høyreklikk), lik for lagrede gradienter og gradientene i en palett:
///
/// 1. Åpne i Overgang · Gi nytt navn …
/// 2. Lagre farger som palett … · Legg gradienten i palett
/// 3. Kopier CSS · Kopier til · Kopier tonene til · Del som lenke · Lagre som … · Skriv ut …
/// 4. Slett gradient
private struct Gradientmeny: ViewModifier {
    let oppsett: Gradientoppsett
    let navn: String
    let åpne: () -> Void
    let giNavn: (String) -> Void
    /// Ber om å slette (visningen bekrefter først).
    let slett: () -> Void
    @State private var omdøpes = false
    @State private var nyttNavn = ""
    @State private var lagresSom = false
    @State private var somPalett = false

    private var toner: [PalettFarge] { oppsett.toner.map { PalettFarge(farge: $0, opphav: .overgang) } }

    func body(content: Content) -> some View {
        content
            .contextMenu {
                Section {
                    Button("Åpne i Overgang", systemImage: "arrow.up.forward.app", action: åpne)
                    Button("Gi nytt navn …", systemImage: "character.cursor.ibeam") {
                        nyttNavn = navn
                        omdøpes = true
                    }
                }
                Section {
                    Button("Lagre farger som palett …", systemImage: "swatchpalette") { somPalett = true }
                    LeggGradientIPalettMeny(oppsett: oppsett, navn: navn)
                }
                Section {
                    let (o, n) = (oppsett, navn)
                    DelSomLenke(navn: n) { Lenkedeling.gradient(o, navn: n) }
                    Button("Skriv ut …", systemImage: "printer") {
                        PalettUtskrift.skrivUt(Palett(navn: navn, farger: toner), gradienter: [PalettGradient(navn: navn, oppsett: oppsett)])
                    }
                    Button("Kopier CSS", systemImage: "doc.on.doc") { Utklippstavle.kopierTekst(oppsett.css) }
                    GradientKopierTilMeny(gradient: Gradientkopi(farger: [oppsett.fra, oppsett.til], navn: navn))
                    KopierTilMeny(farger: toner, navn: navn, tittel: "Kopier tonene til")
                    Button("Lagre som …", systemImage: "square.and.arrow.down") { lagresSom = true }
                }
                Section {
                    Button("Slett gradient", systemImage: "trash", role: .destructive, action: slett)
                }
            }
            .alert("Gi gradienten navn", isPresented: $omdøpes) {
                TextField("Navn", text: $nyttNavn)
                Button("Avbryt", role: .cancel) {}
                Button("Lagre") {
                    let rent = nyttNavn.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !rent.isEmpty { giNavn(rent) }
                }
            }
            .sheet(isPresented: $lagresSom) {
                LagreSomArk(innhold: Lagringsinnhold(navn: navn, farger: toner,
                                                     gradienter: [PalettGradient(navn: navn, oppsett: oppsett)]))
            }
            .sheet(isPresented: $somPalett) {
                VelgPalettArk(farger: oppsett.rader.flatMap { $0 }.map { PalettFarge(farge: $0, opphav: .overgang) },
                              foreslåttNavn: navn)
            }
    }
}

extension View {
    /// Den felles gradientmenyen (se `Gradientmeny`).
    func gradientmeny(_ oppsett: Gradientoppsett, navn: String, åpne: @escaping () -> Void, giNavn: @escaping (String) -> Void,
                      slett: @escaping () -> Void) -> some View {
        modifier(Gradientmeny(oppsett: oppsett, navn: navn, åpne: åpne, giNavn: giNavn, slett: slett))
    }
}
