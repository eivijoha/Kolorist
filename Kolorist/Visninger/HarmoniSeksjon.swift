import FargeKjerne
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Fargeharmonier rundt aktiv farge, med en liten fargesirkel som viser vinklene.
struct HarmoniSeksjon: View {
    let grunnfarge: Farge
    var gamut: Gamut = .displayP3
    var begrens: (Farge) -> Farge = { $0 }
    var velg: (Farge) -> Void
    var lagre: ([PalettFarge], String) -> Void
    /// Melder harmoniens farger og grunnfargens plass, så Studio kan vise dem i fargeflaten øverst.
    var vis: ([Farge], Int?) -> Void = { _, _ in }

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var bredde
    #endif

    /// iPhone: 220 pt. iPad (vanlig bredde) og Mac: 320 pt.
    private var sirkelhøyde: CGFloat {
        #if os(iOS)
        bredde == .regular ? 320 : 220
        #else
        320
        #endif
    }
    @AppStorage("harmoni") private var harmoni: Harmoni = .splittKomplementær
    @AppStorage("harmoniAntall") private var antall = 3
    @AppStorage("harmoniVinkel") private var vinkel = 30.0
    @AppStorage("harmoniSirkel") private var sirkel: Fargesirkel = .okLCH
    @AppStorage("harmoniLyshetsrekkefølge") private var lyshetsrekkefølge: Lyshetsrekkefølge = .lik
    /// Monokromatisk: streken i lyshet–metning-planet (tom = standardstreken rundt grunnfargen) og kuløren
    /// (OKLCH-grader). Kuløren huskes for seg, så den ikke forsvinner når grunnfargen er grå.
    @AppStorage("harmoniMonokrom") private var monokromTekst = ""
    @AppStorage("harmoniMonokromKulør") private var monokromKulør = 254.0
    /// Grunnfargen satt herfra (trykk på en tone, kulørglideren): den skal ikke flytte streken.
    @State private var egenGrunnfarge: Farge?
    /// Grunnfargen streken sist ble stilt etter (OKLab som tekst), så en farge valgt mens Harmoni ikke var åpen
    /// også flytter streken når Harmoni åpnes.
    @AppStorage("harmoniMonokromGrunn") private var monokromGrunn = ""

    /// Felles metning og lyshet for hele harmonien (0…1), som i HSL. `nil` = følg hver farge.
    /// Med HSL- og RYB-sirkelen er det HSL-metning og -lyshet; ellers OKLCH-lyshet og metning som andel av
    /// høyeste kroma innenfor gamut (100 % = så mettet som fargen kan bli).
    @State private var metning: Double?
    @State private var lyshet: Double?
    /// Ark for å velge grunnfarge blant lagrede farger og paletter (trykk i midten av sirkelen).
    @State private var velgerGrunnfarge = false
    #if SIRKELEKSPORT
    /// Midlertidig: eksport av fargesirkelen som vektor (SVG/PDF) til arbeidet med app-ikonet.
    @State private var sirkeleksport: (data: Data, type: UTType, navn: String)?
    #endif

    private var råfarger: [Farge] {
        harmoni.farger(fra: grunnfarge, antall: antall, vinkel: harmoni.harVinkel ? vinkel : nil, sirkel: sirkel, gamut: gamut)
    }

    /// Harmoniens eksakte vinkler i sirkelen, i samme rekkefølge som fargene. Markørene tegnes her, ikke på
    /// fargenes målte kulør: gamut-kartlegging og metning/lyshet flytter kuløren noen grader, så markørene
    /// ellers ble ujevnt fordelt.
    private var vinkler: [Double] {
        let basis = sirkel.vinkel(for: grunnfarge)
        // Grunnfargen står der den er; de andre på sirkelens trinn (Munsell: 2,5 kulør), som fargene.
        return harmoni.forskyvninger(antall: antall, vinkel: harmoni.harVinkel ? vinkel : nil).map { $0 == 0 ? basis : sirkel.avrundet(basis + $0) }
    }

    /// Plassen til grunnfargen blant fargene (i midten for analog). Monokromatisk: ingen – streken trenger ikke gå
    /// gjennom grunnfargen.
    private var grunnIndeks: Int? {
        guard harmoni != .monokrom else { return nil }
        return harmoni.forskyvninger(antall: antall, vinkel: harmoni.harVinkel ? vinkel : nil).firstIndex(of: 0)
    }

    private var strek: Binding<Monokromstrek> {
        Binding(get: { Monokromstrek(tekst: monokromTekst) ?? .standard(for: grunnfarge, gamut: gamut) },
                set: { monokromTekst = $0.tekst })
    }

    private var farger: [Farge] {
        if harmoni == .monokrom {
            return strek.wrappedValue.toner(kulør: monokromKulør, antall: antall, gamut: gamut).map(begrens)
        }
        let justert = råfarger.map(juster)
        var ordnet = lyshetsrekkefølge.anvendt(på: justert, grunn: juster(grunnfarge), gamut: gamut)
        if brukerMunsell {
            // Munsell: bare valøren flyttes, i bokas trinn; kroma som i resten av harmonien.
            ordnet = zip(justert, ordnet).map { før, etter in
                guard før != etter else { return før }
                var m = før.munsell
                m.valør = Munsell.avrundetValør(etter.munsell.valør)
                var f = munsellfarge(m) ?? etter
                f.alfa = før.alfa
                return f
            }
        }
        return ordnet.map { begrens($0.gamutKartlagt(til: gamut)) }
    }

    private func juster(_ f: Farge) -> Farge {
        if brukerMunsell {
            // Munsell: gliderne er valør og kroma, og fargene er ekte Munsell-farger med gyldige notasjoner
            // (valør og kroma i trinn, også før gliderne er rørt).
            var m = f.munsell
            m.valør = (lyshet ?? grunnLyshet) * 10
            m.kroma = (metning ?? grunnMetning) * Self.munsellMaksKroma
            var farge = munsellfarge(m) ?? f
            farge.alfa = f.alfa
            return farge
        }
        guard metning != nil || lyshet != nil else { return f }
        if sirkel == .hsl || sirkel == .ryb {
            var h = f.hsl
            if let metning { h.s = metning }
            if let lyshet { h.l = lyshet }
            return Farge(hsl: h, alfa: f.alfa)
        }
        let lch = f.okLCH
        let l = lyshet ?? lch.l
        let andel = metning ?? relativMetning(f)
        return Farge(okLCH: OKLCH(l: l, c: andel * Farge.maksKroma(lyshet: l, kulør: lch.h, i: gamut), h: lch.h), alfa: f.alfa)
    }

    private func relativMetning(_ f: Farge) -> Double {
        let lch = f.okLCH
        let maks = Farge.maksKroma(lyshet: lch.l, kulør: lch.h, i: gamut)
        return maks > 0 ? min(lch.c / maks, 1) : 0
    }

    /// Fargen i ringen ved en vinkel, med gjeldende metning og lyshet (grunnfargens når gliderne ikke er rørt).
    private func ringfarge(vinkel: Double) -> Farge {
        let m = metning ?? grunnMetning, l = lyshet ?? grunnLyshet
        if brukerMunsell {
            // Ekte Munsell-farger på hvert trinn, med gjeldende valør og kroma (senket der kuløren ikke når så høyt).
            let munsell = Munsell(kulør: sirkel.avrundet(vinkel) / 3.6, valør: l * 10, kroma: m * Self.munsellMaksKroma)
            return munsellfarge(munsell) ?? grunnfarge.gamutKartlagt(til: gamut)
        }
        let f = sirkel.farge(grunnfarge, vinkel: vinkel, gamut: gamut)
        if sirkel == .hsl || sirkel == .ryb {
            var h = f.hsl
            h.s = m
            h.l = l
            return Farge(hsl: h)
        }
        let h = f.okLCH.h
        return Farge(okLCH: OKLCH(l: l, c: m * Farge.maksKroma(lyshet: l, kulør: h, i: gamut), h: h)).gamutKartlagt(til: gamut)
    }

    #if SIRKELEKSPORT
    private func eksporterSirkel(svg: Bool) {
        let tegning = Fargesirkeltegning(grunnfarge: grunnfarge, farger: farger, sirkel: sirkel, vinkler: vinkler, grunnIndeks: grunnIndeks,
                                         ringfarge: { ringfarge(vinkel: $0) },
                                         midtfarge: juster(grunnfarge).gamutKartlagt(til: gamut))
        sirkeleksport = svg ? (Data(tegning.svg.utf8), .svg, "Fargesirkel.svg") : (tegning.pdf, .pdf, "Fargesirkel.pdf")
    }
    #endif

    /// Grunnfargens egne verdier, som gliderne starter på.
    private var brukerHSL: Bool { sirkel == .hsl || sirkel == .ryb }
    /// Munsell-sirkelen: «Metning» er Munsell-kroma (0–24) og «Lyshet» er valør (0–10).
    private var brukerMunsell: Bool { sirkel == .munsell }
    private static let munsellMaksKroma = 24.0
    /// En Munsell-farge innenfor gamut. Når kuløren ikke når valgt kroma, senkes den til nærmeste lavere trinn
    /// (partall), så notasjonen fortsatt er gyldig («5GY 5/10», ikke «5GY 5/11.6»).
    private func munsellfarge(_ m: Munsell) -> Farge? {
        guard let f = Farge.innenforMunsell(m, gamut: gamut) else { return nil }
        let oppnådd = f.munsell.kroma
        guard oppnådd < m.kroma - 0.1 else { return f }
        let trinn = (oppnådd / Munsell.kromasteg).rounded(.down) * Munsell.kromasteg
        return Farge.innenforMunsell(Munsell(kulør: m.kulør, valør: m.valør, kroma: trinn), gamut: gamut) ?? f
    }

    private var grunnMetning: Double {
        if brukerMunsell { return min(Munsell.avrundetKroma(grunnfarge.munsell.kroma) / Self.munsellMaksKroma, 1) }
        return brukerHSL ? grunnfarge.hsl.s : relativMetning(grunnfarge)
    }
    private var grunnLyshet: Double {
        if brukerMunsell { return Munsell.avrundetValør(grunnfarge.munsell.valør) / 10 }
        return brukerHSL ? grunnfarge.hsl.l : grunnfarge.okLCH.l
    }

    /// Grunnfargen med gitt metning og lyshet (samme regler som harmonien).
    private func grunnfarge(metning m: Double, lyshet l: Double) -> Farge {
        if brukerMunsell {
            var g = grunnfarge.munsell
            g.valør = l * 10
            g.kroma = m * Self.munsellMaksKroma
            return munsellfarge(g) ?? grunnfarge.gamutKartlagt(til: gamut)
        }
        if brukerHSL {
            var h = grunnfarge.hsl
            h.s = m
            h.l = l
            return Farge(hsl: h)
        }
        let h = grunnfarge.okLCH.h
        return Farge(okLCH: OKLCH(l: l, c: m * Farge.maksKroma(lyshet: l, kulør: h, i: gamut), h: h))
    }

    /// Sporfarger: grunnfargen langs gliderens akse, med den andre verdien som den er.
    private func spor(metningsakse: Bool) -> [Color] {
        let m = metning ?? grunnMetning, l = lyshet ?? grunnLyshet
        return (0..<24).map { n in
            let t = Double(n) / 23
            return grunnfarge(metning: metningsakse ? t : m, lyshet: metningsakse ? l : t).swiftUI
        }
    }

    private func glider(_ tittel: LocalizedStringKey, verdi: Binding<Double?>, grunn: Double, metningsakse: Bool) -> some View {
        let gjeldende = verdi.wrappedValue ?? grunn
        // Munsell viser egne tall (kroma og valør); de andre sirklene prosent.
        let tekst: String = brukerMunsell
            ? (metningsakse ? String(format: "%.0f", gjeldende * Self.munsellMaksKroma) : String(format: "%.1f", gjeldende * 10))
            : gjeldende.formatted(.percent.precision(.fractionLength(0)))
        return HStack(spacing: 10) {
            Text(tittel).lineLimit(1).minimumScaleFactor(0.8).frame(width: 96, alignment: .leading)
            FargeGlider(verdi: Binding(get: { gjeldende }, set: { ny in
                // Lås den andre verdien der den er: grunnfargen oppdateres underveis (og kan begrenses
                // av valgt profil), og en verdi som «følger grunnfargen» ville da krype.
                if metning == nil { metning = grunnMetning }
                if lyshet == nil { lyshet = grunnLyshet }
                // Munsell i trinn som i Munsell-boka: kroma 2, 4, 6 … og valør 1, 2, 3 …
                verdi.wrappedValue = brukerMunsell
                    ? (metningsakse ? Munsell.avrundetKroma(ny * Self.munsellMaksKroma) / Self.munsellMaksKroma
                                    : Munsell.avrundetValør(ny * 10) / 10)
                    : ny
            }), område: 0...1,
                        spor: spor(metningsakse: metningsakse),
                        gjeldende: grunnfarge(metning: metning ?? grunnMetning, lyshet: lyshet ?? grunnLyshet).swiftUI,
                        tittel: Text(tittel),
                        verdiTekst: tekst,
                        stegForTilgjengelighet: brukerMunsell
                            ? (metningsakse ? Munsell.kromasteg / Self.munsellMaksKroma : Munsell.valørsteg / 10) : 0.05)
            Text(tekst)
                .font(.callout.monospacedDigit())
                .foregroundStyle(Color.sekundærTekst)
                .frame(width: 48, alignment: .trailing)
        }
    }

    private var lyshetsforklaring: String {
        switch lyshetsrekkefølge {
        case .lik: ""
        case .naturlig: " " + String(localized: "Naturlig lyshetsrekkefølge: gule farger blir lysere og blå og fiolette mørkere, som i naturen – det oppleves ofte som harmonisk.")
        case .omvendt: " " + String(localized: "Omvendt lyshetsrekkefølge: gule farger blir mørkere og blå og fiolette lysere – det gir bevisst spenning.")
        }
    }

    /// Velger en farge herfra (monokromatisk), så endringen ikke flytter streken (se `grunnfargeEndret`).
    private func velgHerfra(_ f: Farge) {
        egenGrunnfarge = f
        velg(f)
    }

    /// Monokromatisk: en grunnfarge valgt et annet sted (palett, felt, pipette) flytter streken, så den ene enden
    /// (grunnfargens ende, `b`) står der fargen er. Tom strek følger grunnfargen av seg selv.
    private func grunnfargeEndret() {
        følgGrunnfargensKulør()
        guard harmoni == .monokrom else { return }
        let lab = grunnfarge.okLab
        let nøkkel = String(format: "%.4f %.4f %.4f", lab.l, lab.a, lab.b)
        guard nøkkel != monokromGrunn else { return }
        monokromGrunn = nøkkel
        if let egen = egenGrunnfarge {
            egenGrunnfarge = nil
            if egen.avstandOK(til: grunnfarge) < 0.002 { return }
        }
        guard var ny = Monokromstrek(tekst: monokromTekst) else { return }
        let lch = grunnfarge.okLCH
        ny.b = .fra(lyshet: lch.l, kroma: lch.c, kulør: lch.h, gamut: gamut)
        monokromTekst = ny.tekst
    }

    /// Monokromatisk: kuløren følger grunnfargen, unntatt når den er (nesten) grå og ikke har noen kulør.
    private func følgGrunnfargensKulør() {
        let lch = grunnfarge.okLCH
        if lch.c > 0.02, abs(lch.h - monokromKulør) > 0.01 { monokromKulør = lch.h }
    }

    /// En farge med kuløren, til å regne vinkelen i valgt fargesirkel og tegne kulørsporet.
    private func referansefarge(okLCHKulør h: Double) -> Farge {
        Farge(okLCH: OKLCH(l: 0.68, c: 0.13, h: h)).gamutKartlagt(til: gamut)
    }

    /// Kulørglider (i valgt fargesirkel) og lyshet–metning-flaten med streken.
    @ViewBuilder private var monokromKontroller: some View {
        let ref = referansefarge(okLCHKulør: monokromKulør)
        let vinkel = sirkel.vinkel(for: ref)
        let tekst = brukerMunsell ? String(Fargemodell.munsell.kortTekst(for: ref).split(separator: " ").first ?? "")
                                  : "\(Int(vinkel.rounded()))°"
        HStack(spacing: 10) {
            Text("Kulør").lineLimit(1).frame(width: 96, alignment: .leading)
            FargeGlider(verdi: Binding(get: { vinkel }, set: { ny in
                let h = sirkel.farge(ref, vinkel: ny, gamut: gamut).okLCH.h
                monokromKulør = h
                // Grunnfargen får samme kulør, så resten av Studio følger med (grå grunnfarge har ingen kulør).
                var lch = grunnfarge.okLCH
                if lch.c > 0.02 {
                    lch.h = h
                    velgHerfra(Farge(okLCH: lch, alfa: grunnfarge.alfa).gamutKartlagt(til: gamut))
                }
            }), område: 0...360,
                        spor: (0..<36).map { sirkel.farge(ref, vinkel: Double($0) * 10, gamut: gamut).swiftUI },
                        gjeldende: ref.swiftUI,
                        tittel: Text("Kulør"),
                        verdiTekst: tekst,
                        stegForTilgjengelighet: sirkel.trinn ?? 5)
            Text(tekst)
                .font(.callout.monospacedDigit())
                .foregroundStyle(Color.sekundærTekst)
                .frame(width: 48, alignment: .trailing)
        }
        // Kvadratisk, like høy som fargesirkelen i de andre harmoniene.
        LyshetMetningFlate(kulør: monokromKulør, gamut: gamut, strek: strek, toner: farger, grunnfarge: grunnfarge, velg: velgHerfra)
            .frame(width: sirkelhøyde, height: sirkelhøyde)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        if !monokromTekst.isEmpty {
            Button("Tilbakestill streken", systemImage: "arrow.uturn.backward") { monokromTekst = "" }
        }
    }

    var body: some View {
        Section {
            // Gruppert med skillelinjer: én kulør, naboer, motsatte kulører, jevnt rundt sirkelen.
            Picker("Harmoni", selection: $harmoni) {
                ForEach(Harmoni.grupper, id: \.self) { gruppe in
                    Section { ForEach(gruppe) { Text($0.navn).tag($0) } }
                }
            }
            .onChange(of: harmoni) { _, ny in
                grunnfargeEndret()
                if ny.harVinkel { vinkel = ny.standardVinkel }
                antall = min(max(antall, ny.antallOmråde.lowerBound), ny.antallOmråde.upperBound)
            }

            if harmoni.harAntall {
                Stepper(harmoni == .analogMedAksent ? "Analoge farger: \(antall)" : harmoni == .monokrom ? "Toner: \(antall)" : "Antall farger: \(antall)",
                        value: $antall, in: harmoni.antallOmråde)
            }
            if harmoni.harVinkel {
                HStack {
                    Text("Vinkel")
                    Trinnglider(verdi: $vinkel, område: 5...90, steg: 1)
                    Text("\(Int(vinkel))°").monospacedDigit().frame(width: 44, alignment: .trailing)
                }
            }
            Picker("Fargesirkel", selection: $sirkel) {
                ForEach(Fargesirkel.allCases) { Text($0.navn).tag($0) }
            }

            if harmoni == .monokrom {
                monokromKontroller
            } else {
            // Ringen og midten tegnes med gjeldende metning og lyshet, så gliderne under virker direkte på sirkelen.
            Fargesirkelvisning(grunnfarge: grunnfarge, farger: farger, sirkel: sirkel, vinkler: vinkler, grunnIndeks: grunnIndeks,
                               velg: velg, ringfarge: { ringfarge(vinkel: $0) }, midtfarge: juster(grunnfarge).gamutKartlagt(til: gamut),
                               vedMidttrykk: { velgerGrunnfarge = true })
                .sheet(isPresented: $velgerGrunnfarge) {
                    LagretFargeArk(tittel: String(localized: "Grunnfarge")) { f in
                        // Start harmonien fra den valgte fargen som den er.
                        metning = nil
                        lyshet = nil
                        velg(f)
                    }
                }
                // Fargene vises i fargeflaten øverst i Studio; sirkelen får plassen. Større på iPad og Mac.
                .frame(height: sirkelhøyde)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            #if SIRKELEKSPORT
            Menu("Eksporter sirkelen (midlertidig)", systemImage: "square.and.arrow.up") {
                Button("SVG") { eksporterSirkel(svg: true) }
                Button("PDF (Display P3)") { eksporterSirkel(svg: false) }
            }
            #endif
            glider(brukerMunsell ? "Kroma" : "Metning", verdi: $metning, grunn: grunnMetning, metningsakse: true)
            glider(brukerMunsell ? "Valør" : "Lyshet", verdi: $lyshet, grunn: grunnLyshet, metningsakse: false)
            HStack(spacing: 4) {
                Text(brukerMunsell ? "Valørrekkefølge" : "Lyshetsrekkefølge")
                InfoKnapp(tittel: brukerMunsell ? "Om valørrekkefølge" : "Om lyshetsrekkefølge") {
                    if brukerMunsell {
                        Text("Hvor lyse fargene i harmonien er i forhold til hverandre (valør).")
                    } else {
                        Text("Hvor lyse fargene i harmonien er i forhold til hverandre.")
                    }
                    Text("**Lik:** samme lyshet, så fargene veier likt.")
                    Text("**Naturlig:** følger kulørenes egen lyshet – gult lysest, blått og fiolett mørkest – slik vi kjenner det fra naturen. Oppleves ofte som harmonisk.")
                    Text("**Omvendt:** snur dette og gir bevisst spenning.")
                }
                Spacer(minLength: 8)
                Picker(brukerMunsell ? "Valørrekkefølge" : "Lyshetsrekkefølge", selection: $lyshetsrekkefølge) {
                    ForEach(Lyshetsrekkefølge.allCases) { Text($0.navn).tag($0) }
                }
                .labelsHidden()
                .fixedSize()
            }
            if metning != nil || lyshet != nil {
                Button("Tilbakestill til grunnfargen", systemImage: "arrow.uturn.backward") {
                    metning = nil
                    lyshet = nil
                }
            }
            }
            Button("Legg harmonien i palett", systemImage: "plus.square.on.square") {
                lagre(farger.map { PalettFarge(farge: $0, opphav: .manuell) }, harmoni.navn)
            }
            KopierTilMeny(farger: farger.map { PalettFarge(farge: $0, opphav: .manuell) }, navn: harmoni.navn)
            Button("Skriv ut harmonien …", systemImage: "printer") {
                PalettUtskrift.skrivUt(Palett(navn: harmoni.navn, farger: farger.map { PalettFarge(farge: $0, opphav: .manuell) }))
            }
            let (h, s, f, a, v, o, i) = (harmoni, sirkel, farger, antall, vinkel, lyshetsrekkefølge, grunnIndeks)
            let grunn = i.flatMap { f.indices.contains($0) ? f[$0] : nil } ?? juster(grunnfarge).gamutKartlagt(til: gamut)
            DelSomLenke(navn: harmoni.navn, tittel: "Del harmonien som lenke") {
                Lenkedeling.harmoni(h, sirkel: s, grunn: grunn, farger: f, antall: a, vinkel: v, lyshetsrekkefølge: o, grunnIndeks: i)
            }
        } header: {
            Text("Fargeharmonier")
        } footer: {
            VStack(alignment: .leading, spacing: 6) {
                if harmoni == .monokrom {
                    Text("Én kulør i flere toner. Dra endepunktene i flaten – lyshet loddrett, metning vannrett – så fordeler tonene seg jevnt langs streken. Trykk på en tone for å gjøre den aktiv. Metningen går fra grå til så mettet som kuløren kan bli ved hver lyshet.")
                } else {
                Text(sirkel.forklaring + " " + (brukerMunsell
                    ? String(localized: "Dra i sirkelen for å endre grunnfargens kulør, eller trykk i midten for å starte fra en lagret farge. Kroma og valør gjelder hele harmonien.")
                    : String(localized: "Dra i sirkelen for å endre grunnfargens kulør, eller trykk i midten for å starte fra en lagret farge. Metning og lyshet gjelder hele harmonien."))
                    + lyshetsforklaring)
                }
                MetodeHenvisning(.harmonier, .oklab, .cieLab)
            }
        }
        #if SIRKELEKSPORT
        .fileExporter(isPresented: Binding(get: { sirkeleksport != nil }, set: { if !$0 { sirkeleksport = nil } }),
                      document: EksportDokument(data: sirkeleksport?.data ?? Data()),
                      contentType: sirkeleksport?.type ?? .data,
                      defaultFilename: sirkeleksport?.navn) { _ in }
        #endif
        // Ikke onDisappear: radene i et Form fjernes og lages på nytt ved rulling. Studio viser harmonien i
        // fargeflaten bare i Harmoni-modus, så gamle verdier gjør ikke noe.
        .onAppear {
            vis(farger, grunnIndeks)
            grunnfargeEndret()
        }
        .onChange(of: grunnfarge) { _, _ in grunnfargeEndret() }
        .onChange(of: farger) { _, nye in vis(nye, grunnIndeks) }
        // Gliderne betyr noe annet i HSL enn i OKLCH; start på nytt ved bytte av sirkel.
        .onChange(of: sirkel) { _, _ in metning = nil; lyshet = nil }
        // Primærfargen (grunnfargen med gjeldende metning/lyshet) blir aktiv farge, så den vises i
        // fargefeltet øverst. Justeringen er idempotent, så den nye grunnfargen gir samme harmoni.
        .onChange(of: metning) { _, _ in velg(juster(grunnfarge).gamutKartlagt(til: gamut)) }
        .onChange(of: lyshet) { _, _ in velg(juster(grunnfarge).gamutKartlagt(til: gamut)) }
    }
}

/// Fargesirkel med markører for harmoniens kulører. Dra for å flytte grunnfargen rundt sirkelen.
struct Fargesirkelvisning: View {
    let grunnfarge: Farge
    let farger: [Farge]
    let sirkel: Fargesirkel
    /// Markørenes vinkler, i samme rekkefølge som `farger`. Uten dem brukes fargenes målte kulør.
    var vinkler: [Double]? = nil
    /// Hvilken av fargene som er grunnfargen (større markør). Uten den sammenlignes med midtfargen.
    var grunnIndeks: Int? = nil
    var velg: ((Farge) -> Void)? = nil
    /// Ringens farge ved en vinkel; standard er sirkelens egen ringfarge.
    var ringfarge: ((Double) -> Farge)? = nil
    /// Fargen i midten; standard er grunnfargen.
    var midtfarge: Farge? = nil
    /// Trykk på midten (f.eks. velg grunnfarge blant lagrede farger).
    var vedMidttrykk: (() -> Void)? = nil

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let senter = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            Canvas { ctx, _ in
                let r = side / 2
                if let trinn = sirkel.trinn {
                    // Trinnvis sirkel (Munsell): ett felt per kulør, sentrert på kuløren, med en smal fuge mellom
                    // feltene som i Munsells fargekart.
                    let antallTrinn = Int((360 / trinn).rounded())
                    for i in 0..<antallTrinn {
                        let midt = Double(i) * trinn
                        var sti = Path()
                        sti.addArc(center: senter, radius: r * 0.8, startAngle: .degrees(midt - trinn / 2 - 90 + 0.6),
                                   endAngle: .degrees(midt + trinn / 2 - 90 - 0.6), clockwise: false)
                        ctx.stroke(sti, with: .color((ringfarge?(midt) ?? sirkel.ringfarge(vinkel: midt, grunn: grunnfarge)).swiftUI), lineWidth: r * 0.3)
                    }
                } else {
                    let segmenter = 120
                    for i in 0..<segmenter {
                        let a0 = Double(i) / Double(segmenter) * 360, a1 = Double(i + 1) / Double(segmenter) * 360
                        var sti = Path()
                        sti.addArc(center: senter, radius: r * 0.8, startAngle: .degrees(a0 - 90), endAngle: .degrees(a1 - 89.5), clockwise: false)
                        ctx.stroke(sti, with: .color((ringfarge?(a0) ?? sirkel.ringfarge(vinkel: a0, grunn: grunnfarge)).swiftUI), lineWidth: r * 0.3)
                    }
                }
                for i in farger.indices.reversed() {
                    let f = farger[i]
                    let vinkel = vinkler.flatMap { i < $0.count ? $0[i] : nil } ?? sirkel.vinkel(for: f)
                    let v = (vinkel - 90) * .pi / 180
                    let p = CGPoint(x: senter.x + cos(v) * r * 0.8, y: senter.y + sin(v) * r * 0.8)
                    var linje = Path()
                    linje.move(to: senter)
                    linje.addLine(to: p)
                    ctx.stroke(linje, with: .color(.primary.opacity(0.35)), lineWidth: 1)
                    let erGrunn = grunnIndeks.map { $0 == i } ?? (f == (midtfarge ?? grunnfarge))
                    let d = erGrunn ? r * 0.26 : r * 0.19
                    let rute = CGRect(x: p.x - d / 2, y: p.y - d / 2, width: d, height: d)
                    ctx.fill(Path(ellipseIn: rute), with: .color(f.swiftUI))
                    // Grunnfargen får samme ramme som flaten øverst: fargens lesbare tekstfarge i stedet for hvitt.
                    ctx.stroke(Path(ellipseIn: rute), with: .color(erGrunn ? f.lesbarTekstfarge.swiftUI : .white),
                               lineWidth: erGrunn ? 4 : 2)
                }
                // Midten viser grunnfargen.
                let m = r * 0.34
                ctx.fill(Path(ellipseIn: CGRect(x: senter.x - m, y: senter.y - m, width: m * 2, height: m * 2)),
                         with: .color((midtfarge ?? grunnfarge).swiftUI))
            }
            .contentShape(Circle())
            .overlay {
                // Midten er en egen knapp: velg grunnfarge blant lagrede farger.
                if let vedMidttrykk {
                    Button(action: vedMidttrykk) {
                        Circle().fill(.clear).contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .frame(width: side * 0.34, height: side * 0.34)
                    .position(senter)
                    .help("Velg grunnfarge fra lagrede farger")
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { g in
                    guard let velg else { return }
                    // Dra som starter i midten, flytter ikke kuløren (midten er en knapp).
                    guard hypot(g.startLocation.x - senter.x, g.startLocation.y - senter.y) > side * 0.17 else { return }
                    let dx = g.location.x - senter.x, dy = g.location.y - senter.y
                    guard hypot(dx, dy) > side * 0.15 else { return }
                    let vinkel = atan2(dy, dx) * 180 / .pi + 90
                    velg(sirkel.farge(grunnfarge, vinkel: vinkel))
                }
            )
        }
        .accessibilityElement()
        .accessibilityLabel("\(sirkel.navn) fargesirkel med \(farger.count) markerte kulører")
        .accessibilityValue("Grunnfarge \(Int(sirkel.vinkel(for: grunnfarge))) grader")
        .accessibilityAction(named: "Velg grunnfarge fra lagrede farger") { vedMidttrykk?() }
        .accessibilityAdjustableAction { retning in
            let steg: Double = retning == .increment ? 15 : -15
            velg?(sirkel.farge(grunnfarge, vinkel: sirkel.vinkel(for: grunnfarge) + steg))
        }
    }
}
