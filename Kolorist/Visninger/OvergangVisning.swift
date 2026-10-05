import FargeKjerne
import SwiftData
import SwiftUI

/// Overgangstoner i like OKLab-steg mellom to farger, med lysere/mørkere rader.
struct OvergangVisning: View {
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    // Lagres som CSS-tekst (hex, eller Display P3 utenfor sRGB), så endepunktene huskes.
    @AppStorage("overgangFra") private var startTekst = "#1B3A6B"
    @AppStorage("overgangTil") private var sluttTekst = "#F2B84B"

    private var start: Farge {
        get { Fargetolk.tolk(startTekst) ?? Farge(hex: "#1B3A6B")! }
        nonmutating set { startTekst = Self.lagringstekst(newValue) }
    }
    private var slutt: Farge {
        get { Fargetolk.tolk(sluttTekst) ?? Farge(hex: "#F2B84B")! }
        nonmutating set { sluttTekst = Self.lagringstekst(newValue) }
    }

    static func lagringstekst(_ f: Farge) -> String {
        f.erISRGB ? f.hex() : Fargemodell.displayP3.tekst(for: f)
    }
    @AppStorage("overgangAntall") private var antall = 7
    /// Farger som skal lagres som palett: bare overgangen, eller med lysere og mørkere rader.
    @State private var somPalett: [PalettFarge]?
    @State private var navngirGradient = false
    @State private var gradientnavn = ""
    @State private var gradientLagret = false
    /// Én farge fra overgangen som skal legges i en palett (trykk og hold).
    @State private var leggIPalett: [PalettFarge]?
    @Environment(\.modelContext) private var kontekst
    @Environment(ProfilBibliotek.self) private var bibliotek
    /// Samme «Vis som»-rom og hensikt som Studio, så feltene øverst viser verdiene der.
    @AppStorage("visOgsåProfil") private var visOgsåID = ICCProfil.sRGB.id
    @AppStorage("gjengivelseshensikt") private var hensikt: Gjengivelseshensikt = .relativKolorimetrisk
    @State private var visMineFargerom = false
    /// Endepunktene da dra-bevegelsen på lyshetsstigen startet.
    @State private var lyshetsutgangspunkt: (Farge, Farge)?
    @State private var lyshetslupe = Lyshetslupetilstand()

    private var visOgsåProfil: ICCProfil { bibliotek.profil(id: visOgsåID) ?? .sRGB }
    private var visOgsåBibliotek: Fargebibliotek? { bibliotek.fargebibliotek(id: visOgsåID) }

    /// «+» i øvre høyre hjørne av feltene: lagre, kopiere eller dele hele overgangen. Hver tone har sine egne valg
    /// i trykk og hold-menyen (høyreklikk på Mac).
    private var lagremeny: some View {
        let farger = toner.map { PalettFarge(farge: $0, opphav: .overgang) }
        let navn = String(localized: "Overgang \(start.hex()) → \(slutt.hex())")
        let oppsett = Gradientoppsett(fra: start, til: slutt, antall: antall, trinn: arbeidsbenk.lyshetstrinn)
        return RekkeMeny(farger: farger, navn: navn,
                         lagreSomPalett: { somPalett = farger },
                         flereLagringsvalg: rader.count > 1 ? AnyView(
                             Button("Lagre med lysere og mørkere toner …", systemImage: "square.grid.3x3") {
                                 somPalett = rader.flatMap { $0 }.map { PalettFarge(farge: $0, opphav: .overgang) }
                             }) : nil,
                         lenketittel: "Del overgangen som lenke",
                         // Tonene i trinn og selve gradienten, så mottakeren ser begge.
                         lenke: { Lenkedeling.palett(navn: navn, farger: farger, gradienter: [PalettGradient(navn: navn, oppsett: oppsett)]) },
                         tekstfarge: (toner.last ?? slutt).lesbarTekstfarge.swiftUI)
    }

    private func lagreGradient() {
        let navn = gradientnavn.trimmingCharacters(in: .whitespacesAndNewlines)
        let oppsett = Gradientoppsett(fra: start, til: slutt, antall: antall, trinn: arbeidsbenk.lyshetstrinn)
        kontekst.insert(LagretGradient(navn: navn.isEmpty ? String(localized: "Uten navn") : navn, oppsett: oppsett))
        gradientLagret = true
        Task { try? await Task.sleep(for: .seconds(1.5)); gradientLagret = false }
    }

    private func lagre(_ f: Farge) { lagreEnkeltfarger([PalettFarge(farge: f, opphav: .overgang)], i: kontekst) }
    private func velgPalett(_ f: Farge) { leggIPalett = [PalettFarge(farge: f, opphav: .overgang)] }

    private var toner: [Farge] { Overgang.toner(fra: start, til: slutt, antall: antall).map(arbeidsbenk.begrens) }

    /// Rader fra lysest til mørkest; midtraden er selve overgangen.
    private var rader: [[Farge]] {
        let trinn = arbeidsbenk.lyshetstrinn
        let variasjoner = toner.map { trinn.toner(for: $0, gamut: arbeidsbenk.gamut).map(arbeidsbenk.begrens) }
        return (0..<(trinn.antallLysere + trinn.antallMørkere + 1)).map { rad in variasjoner.map { $0[rad] } }
    }

    /// Feltene øverst, som i Studio: tonene i «Vis som»-rommet (venstre ende er nøyaktig «Fra», høyre nøyaktig
    /// «Til»), med «Vis som» under. Fast øverst mens resten ruller.
    /// Bred visning (Mac, iPad i liggende format): feltene stablet til venstre, kontrollene til høyre.
    private func overgangsflate(bred: Bool) -> some View {
        @Bindable var arbeidsbenk = arbeidsbenk
        return VStack(spacing: 0) {
            HarmoniFlate(farger: toner, grunnIndeks: nil, profil: visOgsåProfil, fargebibliotek: visOgsåBibliotek, hensikt: hensikt,
                         romnavn: visOgsåBibliotek?.navn ?? bibliotek.visningsnavn(visOgsåProfil),
                         verditekst: arbeidsbenk.modell.kortTekst,
                         stablet: bred,
                         rammeRundtAlle: true,
                         velg: { arbeidsbenk.aktivFarge = $0 },
                         lagre: { lagreEnkeltfarger([$0], i: kontekst) },
                         leggIPalett: { leggIPalett = [$0] })
                .frame(height: bred ? nil : 140)
                .frame(maxHeight: bred ? .infinity : nil)
                .overlay(alignment: .topTrailing) { lagremeny }
            HStack {
                Spacer(minLength: 0)
                VisOgsåMeny(valgtID: $visOgsåID, begrens: $arbeidsbenk.begrensAktiv, farge: start, visMineFargerom: $visMineFargerom)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 48)
        }
        .frame(maxWidth: .infinity)
        .background(Color.kortbakgrunn, in: Kortform.fargepanel(bred: bred))
        .padding(.leading, 16)
        .padding(.trailing, bred ? 0 : 16)
        // Bred visning: like mye luft over som til venstre for kortet.
        .padding(.top, bred ? 16 : 4)
        .padding(.bottom, bred ? 16 : 8)
        .background(Color.skjemabakgrunn)
    }

    /// Antall toner i overgangen (tonene vises i feltene øverst).
    private var overgangspanel: some View {
        PanelSeksjon(panel: .overgangstoner, tittel: String(localized: "Overgang i OKLab – \(antall) toner")) {
            Stepper("Toner: \(antall)", value: $antall, in: 2...24)
        } fot: {
            VStack(alignment: .leading, spacing: 6) {
                Text("Tonene vises i feltene øverst. Trykk på en tone for å gjøre den aktiv, eller trykk og hold (høyreklikk på Mac) for å lagre, kopiere eller dele den.")
                MetodeHenvisning(.oklab)
            }
        }
    }

    /// Lysere og mørkere varianter av hver tone (overgangsraden markert med ramme), over trinnkontrollene.
    private var lysereMørkerePanel: some View {
        @Bindable var arbeidsbenk = arbeidsbenk
        return PanelSeksjon(panel: .lysereMørkere) {
            if rader.count > 1 {
                Grid(horizontalSpacing: 3, verticalSpacing: 3) {
                    let midtrad = arbeidsbenk.lyshetstrinn.antallLysere
                    ForEach(Array(rader.enumerated()), id: \.offset) { r, rad in
                        GridRow {
                            ForEach(Array(rad.enumerated()), id: \.offset) { _, farge in
                                FargeRute(farge: farge, visTekst: false, hjørne: 4, lagre: lagre, leggIPalett: velgPalett,
                                          åpneIStudio: { arbeidsbenk.visIStudio($0) }, valgBoble: true)
                                    .frame(minHeight: 36)
                                    .overlay {
                                        if r == midtrad {
                                            RoundedRectangle(cornerRadius: 4).strokeBorder(.primary, lineWidth: 2)
                                        }
                                    }
                                    .onTapGesture { arbeidsbenk.aktivFarge = farge }
                            }
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
            }
            // Forklaringen regnes fra midterste tone i overgangen.
            LyshetstrinnKontroller(trinn: $arbeidsbenk.lyshetstrinn,
                                   grunnlyshet: toner.isEmpty ? 0.6 : toner[toner.count / 2].okLCH.l,
                                   grunnfarger: [start, slutt],
                                   grunnlysheter: toner.map(\.okLCH.l)) { endring, ferdig in
                // Begge endepunktene flyttes like mye, så hele overgangen og radene blir lysere eller mørkere.
                let (fra, til) = lyshetsutgangspunkt ?? (start, slutt)
                lyshetsutgangspunkt = ferdig ? nil : (fra, til)
                start = fra.medOKLCHLyshet(fra.okLCH.l + endring, gamut: arbeidsbenk.gamut)
                slutt = til.medOKLCHLyshet(til.okLCH.l + endring, gamut: arbeidsbenk.gamut)
            }
            // Hele settet (alle radene, lysest først): lagre som palett, del som lenke eller kopier til andre programmer.
            let sett = rader.flatMap { $0 }.map { PalettFarge(farge: $0, opphav: .overgang) }
            let settnavn = String(localized: "Lysere og mørkere \(start.hex()) → \(slutt.hex())")
            Button("Lagre settet som palett …", systemImage: "square.grid.3x3") { somPalett = sett }
                .disabled(rader.count < 2)
            DelSomLenke(navn: settnavn, tittel: "Del settet som lenke") {
                Lenkedeling.palett(navn: settnavn, farger: sett, gradienter: [])
            }
            .disabled(rader.count < 2)
            KopierTilMeny(farger: sett, navn: settnavn, tittel: "Kopier settet til")
                .disabled(rader.count < 2)
        } fot: {
            VStack(alignment: .leading, spacing: 6) {
                if rader.count > 1 {
                    Text("Raden med ramme er selve overgangen. Radene over er lysere, radene under mørkere.")
                }
                MetodeHenvisning(.oklab, .cssColor4)
            }
        }
    }

    var body: some View {
        GeometryReader { geo in
        let bred = Breddeoppsett.erBred(geo.size)
        // AnyLayout bevarer skjemaets tilstand (rulleposisjon) når oppsettet skifter.
        let oppsett = bred ? AnyLayout(HStackLayout(spacing: 0)) : AnyLayout(VStackLayout(spacing: 0))
        oppsett {
        overgangsflate(bred: bred)
            .frame(width: bred ? geo.size.width / 2 : nil)
        Form {
            // Første valg under feltene, som i Studio. Fargemodellen deles med Studio.
            Section {
                @Bindable var arbeidsbenk = arbeidsbenk
                Picker("Fargemodell", selection: $arbeidsbenk.modell) {
                    ForEach(Fargemodell.redigerbare) { Text($0.navn).tag($0) }
                }
            }
            Seksjon("Endepunkter") {
                FargeValgRad(tittel: String(localized: "Fra"), farge: Binding(get: { start }, set: { start = $0 }),
                             verditekst: arbeidsbenk.modell.kortTekst)
                FargeValgRad(tittel: String(localized: "Til"), farge: Binding(get: { slutt }, set: { slutt = $0 }),
                             verditekst: arbeidsbenk.modell.kortTekst)
                Button("Bytt om", systemImage: "arrow.left.arrow.right") {
                    let a = start
                    start = slutt
                    slutt = a
                }
            }
            // Sammenleggbare paneler i brukerens rekkefølge. I hvert panel ligger forhåndsvisningen over kontrollene,
            // så hånden som bruker kontrollen, ikke skjuler resultatet (iPhone og iPad).
            ForEach(Panelinnstillinger.delt.paneler(for: .overgang)) { panel in
                switch panel {
                case .overgangstoner: overgangspanel
                case .lysereMørkere: lysereMørkerePanel
                case .gradient:
                    CSSGradientSeksjon(start: start, slutt: slutt, toner: toner,
                                       oppsett: Gradientoppsett(fra: start, til: slutt, antall: antall, trinn: arbeidsbenk.lyshetstrinn),
                                       lagret: gradientLagret) {
                        gradientnavn = String(localized: "Overgang \(start.hex()) → \(slutt.hex())")
                        navngirGradient = true
                    }
                default: EmptyView()
                }
            }
            TilpassKnapp(skjerm: .overgang)
        }
        .formStyle(.grouped)
        // Grunnfarge-sirkelen fra lyshetsstigen løftet over fingeren, utenfor radens klipping.
        .lyshetslupe(lyshetslupe)
        }
        }
        .background(Color.skjemabakgrunn)
        .navigationTitle("Overgang")
        // Arket presenteres herfra, ikke fra menyen (iOS viser ikke ark fra et menyvalg som lukkes).
        .sheet(isPresented: $visMineFargerom) { MineProfilerArk(valgtID: $visOgsåID) }
        .alert("Lagre gradient", isPresented: $navngirGradient) {
            TextField("Navn", text: $gradientnavn)
            Button("Avbryt", role: .cancel) {}
            Button("Lagre") { lagreGradient() }
        } message: {
            Text("Gradienten lagres under «Gradienter» i Paletter og kan åpnes igjen her.")
        }
        .sheet(isPresented: Binding(get: { leggIPalett != nil }, set: { if !$0 { leggIPalett = nil } })) {
            VelgPalettArk(farger: leggIPalett ?? [])
        }
        .sheet(isPresented: Binding(get: { somPalett != nil }, set: { if !$0 { somPalett = nil } })) {
            VelgPalettArk(farger: somPalett ?? [],
                          foreslåttNavn: String(localized: "Overgang \(start.hex()) → \(slutt.hex())"))
        }
    }
}

/// Overgangen som CSS-gradient: forhåndsvisning, valg og kopiering.
struct CSSGradientSeksjon: View {
    let start: Farge
    let slutt: Farge
    let toner: [Farge]
    /// Hele oppsettet (endepunkter, antall toner, lysere/mørkere), til «Legg gradienten i palett».
    let oppsett: Gradientoppsett
    /// Viser en hake i «+»-knappen rett etter lagring.
    var lagret = false
    /// «Lagre gradient …» i «+»-menyen i hjørnet av gradienten: lagre hele gradienten under «Gradienter» i Paletter.
    var lagreGradient: () -> Void = {}
    @AppStorage("gradientForm") private var form: CSSGradient.Form = .lineær
    @AppStorage("gradientVinkel") private var vinkel = 90.0
    @AppStorage("gradientTrinnvis") private var trinnvis = false
    @State private var kopiert = false

    /// Glidende: bare endepunktene (CSS interpolerer selv i OKLab). Trinnvis: hver tone som et bånd.
    private var gradient: CSSGradient {
        CSSGradient(farger: trinnvis ? toner : [start, slutt], form: form, vinkel: vinkel, trinnvis: trinnvis)
    }

    /// Gradienten slik den kopieres til andre programmer.
    private var kopi: Gradientkopi {
        .overgang(fra: start, til: slutt, toner: toner, form: form, vinkel: vinkel, trinnvis: trinnvis)
    }

    private var stopp: [Gradient.Stop] {
        if trinnvis {
            let n = Double(toner.count)
            return toner.enumerated().flatMap { i, f in
                [Gradient.Stop(color: f.swiftUI, location: Double(i) / n), Gradient.Stop(color: f.swiftUI, location: Double(i + 1) / n)]
            }
        }
        let prøver = Overgang.toner(fra: start, til: slutt, antall: 24)
        return prøver.enumerated().map { Gradient.Stop(color: $1.swiftUI, location: Double($0) / 23) }
    }

    var body: some View {
        PanelSeksjon(panel: .gradient) {
            forhåndsvisning
                .frame(height: 96)
                .overlay(alignment: .topTrailing) {
                    Menu {
                        Button("Lagre gradient …", systemImage: "square.and.arrow.down", action: lagreGradient)
                        GradientKopierTilMeny(gradient: kopi, tittel: "Kopier gradienten til", inline: true)
                    } label: {
                        Image(systemName: lagret ? "checkmark.square.fill" : "plus.square")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(slutt.lesbarTekstfarge.swiftUI)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .menuIndicator(.hidden)
                    .menuOrder(.fixed)
                    .sensoryFeedback(.success, trigger: lagret) { _, ny in ny }
                    .accessibilityLabel(lagret ? String(localized: "Lagret") : String(localized: "Lagre eller kopier gradienten"))
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
            Picker("Form", selection: $form) {
                ForEach(CSSGradient.Form.allCases) { Text($0.navn).tag($0) }
            }
            .pickerStyle(.segmented)
            if form != .radiell {
                HStack {
                    Text(form == .lineær ? "Retning" : "Start")
                    Trinnglider(verdi: $vinkel, område: 0...360, steg: 15)
                    Text("\(Int(vinkel))°").monospacedDigit().frame(width: 44, alignment: .trailing)
                }
            }
            Toggle("Trinnvis (harde overganger, \(toner.count) bånd)", isOn: $trinnvis)
            Text(gradient.deklarasjon)
                .font(.caption.monospaced())
                .textSelection(.enabled)
                .foregroundStyle(Color.sekundærTekst)
            HStack {
                Button(kopiert ? "Kopiert" : "Kopier CSS", systemImage: kopiert ? "checkmark" : "doc.on.doc") {
                    Utklippstavle.kopierTekst(gradient.deklarasjon)
                    kopiert = true
                    Task { try? await Task.sleep(for: .seconds(1.5)); kopiert = false }
                }
                GradientKopierTilMeny(gradient: kopi, tittel: "Kopier gradient til")
                Spacer()
                Menu("Mer") {
                    LeggGradientIPalettMeny(oppsett: oppsett, navn: String(localized: "Overgang \(start.hex()) → \(slutt.hex())"))
                    Divider()
                    Button("Kopier bare moderne verdi") { Utklippstavle.kopierTekst(gradient.moderne) }
                    Button("Kopier bare reserve (sRGB)") { Utklippstavle.kopierTekst(gradient.reserve) }
                }
            }
            .buttonStyle(.borderless)
        } fot: {
            VStack(alignment: .leading, spacing: 6) {
                Text("Moderne nettlesere bruker OKLab og viser nøyaktig samme overgang som her. Eldre nettlesere får tette sRGB-stopp som etterligner den.")
                MetodeHenvisning(.cssColor4, .oklab)
            }
        }
    }

    @ViewBuilder private var forhåndsvisning: some View {
        let g = Gradient(stops: stopp)
        switch form {
        case .lineær:
            // CSS: 0° = opp, 90° = mot høyre. SwiftUI: enhetspunkter.
            let r = (vinkel - 90) * .pi / 180
            let dx = cos(r) / 2, dy = sin(r) / 2
            LinearGradient(gradient: g, startPoint: UnitPoint(x: 0.5 - dx, y: 0.5 - dy), endPoint: UnitPoint(x: 0.5 + dx, y: 0.5 + dy))
        case .radiell:
            GeometryReader { geo in
                RadialGradient(gradient: g, center: .center, startRadius: 0,
                               endRadius: hypot(geo.size.width, geo.size.height) / 2)
            }
        case .konisk:
            AngularGradient(gradient: g, center: .center, angle: .degrees(vinkel - 90))
        }
    }
}
