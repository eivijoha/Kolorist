import AVFoundation
import FargeKjerne
import FargeMaaling
import SwiftUI

/// Menyen for lyskompensasjon i Utplukk: kompenser for målt lys, en valgt lyskilde, et gråkort eller et
/// referansekort, og lagre lyset som lysmiljø.
struct LyskompensasjonMeny: View {
    let plukker: KameraFargeplukker
    @Binding var kalibrerMed: Referansekort?
    @Binding var lagreLysmiljø: Lysmiljø?
    @State private var bibliotek = Lysbibliotek.delt
    @State private var egetKort = false

    var body: some View {
        let profil = bibliotek.kameraprofil(for: plukker.kameranavn)
        Menu {
            Button("Som kameraet ser fargene", systemImage: plukker.kompensasjon == nil ? "checkmark" : "") {
                plukker.slåAvKompensasjon()
            }
            Section("Kompenser til dagslys") {
                #if os(iOS)
                Button("For lyset kameraet måler", systemImage: "camera.metering.center.weighted") { plukker.kompenser(for: nil) }
                Menu("For en lyskilde") {
                    ForEach(Lyskilde.forslag, id: \.self) { lys in
                        Button(lys.navn) { plukker.kompenser(for: lys) }
                    }
                }
                #endif
                Menu(profil == nil ? "Med gråkort" : "Med gråkort og kameraprofil") {
                    Button("Gråkort 18 %") { plukker.ventPåGråkort(refleksjon: 0.18, profil: profil?.karakterisering) }
                    Button("Hvitt kort 90 %") { plukker.ventPåGråkort(refleksjon: 0.9, profil: profil?.karakterisering) }
                    Button("Eget kort …") { egetKort = true }
                    if profil != nil {
                        Divider()
                        Button("Glem kameraprofilen", systemImage: "trash", role: .destructive) {
                            bibliotek.fjernKameraprofil(for: plukker.kameranavn)
                        }
                    }
                }
                if bibliotek.referansekort.isEmpty {
                    // Referanseverdiene følger ikke med appen; brukeren importerer dem under Mine fargerom.
                    Button("Med referansekort (importer verdiene under Mine fargerom)", systemImage: "square.grid.3x2") {}
                        .disabled(true)
                } else {
                    Menu("Med referansekort") {
                        ForEach(bibliotek.referansekort) { kort in
                            Button(kort.navn) { kalibrerMed = kort }
                        }
                    }
                }
            }
            if let måling = plukker.lysmåling {
                Section {
                    Button("Lagre lyset som lysmiljø …", systemImage: "lightbulb.2") {
                        lagreLysmiljø = Lysmiljø(navn: String(localized: "Målt lys"), lyskilde: Self.lyskilde(fra: måling),
                                                 lux: måling.lux.map(LysmiljøRedigering.rundet) ?? 300, måling: måling)
                    }
                }
            }
        } label: {
            Label("Lys", systemImage: plukker.kompensasjon == nil ? "sun.max" : "sun.max.fill")
        }
        .help("Kompenser fargene for lyset de ble fotografert i")
        .modifier(EgetKortSpørsmål(vises: $egetKort) { plukker.ventPåGråkort(refleksjon: $0, profil: profil?.karakterisering) })
    }

    static func lyskilde(fra m: Lysmåling) -> Lyskilde {
        let p = Kolorimetri.xy(kelvin: m.kelvin, duv: m.duv)
        return .hvitpunkt(x: p.x, y: p.y)
    }
}

/// «Eget kort …»: refleksjonen (LRV i prosent) for et kort eller en flate med kjent verdi.
struct EgetKortSpørsmål: ViewModifier {
    @Binding var vises: Bool
    var bruk: (Double) -> Void
    @State private var tekst = "50"

    func body(content: Content) -> some View {
        content.alert("Eget kort", isPresented: $vises) {
            TextField("LRV i prosent", text: $tekst)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
            Button("Avbryt", role: .cancel) {}
            Button("Bruk") {
                if let v = Double(tekst.replacingOccurrences(of: ",", with: ".")), v > 0, v <= 100 { bruk(v / 100) }
            }
        } message: {
            Text("Oppgi refleksjonen (LRV) til et nøytralt kort eller en grå eller hvit flate med kjent verdi, for eksempel en malt vegg.")
        }
    }
}

/// Lysmålingen over kamerabildet: «≈ 3200 K · 450 lx · gråkort».
struct LysmålingMerke: View {
    let plukker: KameraFargeplukker

    var body: some View {
        if plukker.venterPåGråkort {
            Label("Trykk på kortet", systemImage: "hand.tap")
                .merke()
        } else if plukker.lysmåling == nil, let komp = plukker.kompensasjon {
            // Mac med Continuity-kamera: kompensert, men uten lysmåling.
            Label(komp.erReferansekort ? "Kompensert med referansekort" : "Kompensert med gråkort", systemImage: "sun.max.fill")
                .merke()
        } else if let m = plukker.lysmåling {
            HStack(spacing: 6) {
                Image(systemName: plukker.kompensasjon == nil ? "sun.max" : "sun.max.fill")
                Text(tekst(m)).monospacedDigit()
            }
            .merke()
            .accessibilityElement(children: .combine)
        }
    }

    private func tekst(_ m: Lysmåling) -> String {
        let kelvin = (Int((m.kelvin / 50).rounded()) * 50).formatted(.number.grouping(.never))
        var deler = [String(localized: "≈ \(kelvin) K")]
        if let lux = m.lux { deler.append(String(localized: "≈ \(lux.formatted(.number.precision(.significantDigits(2)))) lx")) }
        if plukker.kompensasjon != nil {
            switch m.metode {
            case .kamera: deler.append(String(localized: "kompensert"))
            case .gråkort:
                if case .kameraprofil = plukker.kompensasjon { deler.append(String(localized: "gråkort og kameraprofil")) }
                else { deler.append(String(localized: "gråkort")) }
            case .referansekort: deler.append(String(localized: "referansekort"))
            }
        }
        return deler.joined(separator: " · ")
    }
}

extension Lyskompensasjon {
    var erReferansekort: Bool { if case .referansekort = self { true } else { false } }
}

#if os(macOS)
/// Kameravalg på Mac: innebygd kamera, eksterne kameraer og Continuity-kamera (iPhone).
struct KameraMeny: View {
    let plukker: KameraFargeplukker

    var body: some View {
        if plukker.kameraer.count > 1 {
            Menu {
                ForEach(plukker.kameraer, id: \.uniqueID) { kamera in
                    Button {
                        plukker.velg(kamera: kamera)
                    } label: {
                        if kamera.uniqueID == plukker.kameraID { Label(kamera.localizedName, systemImage: "checkmark") }
                        else { Text(kamera.localizedName) }
                    }
                }
            } label: {
                Label("Kamera", systemImage: "web.camera")
            }
            .help("Velg kamera. Med iPhone som kamera (Continuity) kan fargene kompenseres for lyset med gråkort eller referansekort.")
        }
    }
}
#endif

extension View {
    /// Merke over et bilde (lysmåling, «Trykk på kortet»).
    func merke() -> some View {
        font(.callout.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.regularMaterial, in: Capsule())
            .padding(10)
            .allowsHitTesting(false)
    }
}

/// Kalibrering med et referansekort i et bilde (kamera eller bildefil): hjørnene foreslås automatisk og kan dras
/// på plass, og resultatet viser fasit mot kompensert farge per felt.
struct KortkalibreringArk: View {
    let kort: Referansekort
    let bilde: CGImage
    /// Anslå lyset (fargetemperatur, fargegjengivelse, lystype): bare med kamera med hvitbalanse låst til dagslys.
    var målLys = false
    /// Lux fra kortet: (kamerafarge for et nøytralt felt, feltets refleksjon) → lux.
    var lux: ((Farge, Double) -> Double?)? = nil
    /// Lagre en kameraprofil, så et gråkort holder neste gang (bare kamera med låst hvitbalanse).
    var lagreProfil: ((Kamerakarakterisering) -> Void)? = nil
    var bruk: (Kamerakarakterisering, Lysmåling?) -> Void
    @Environment(\.dismiss) private var lukk
    /// Hjørnene i bildets koordinater (0–1): øverst til venstre, øverst til høyre, nederst til høyre, nederst til venstre.
    @State private var hjørner: [CGPoint] = [CGPoint(x: 0.2, y: 0.3), CGPoint(x: 0.8, y: 0.3), CGPoint(x: 0.8, y: 0.7), CGPoint(x: 0.2, y: 0.7)]
    @State private var resultat: Resultat?
    @State private var prøve: Bildeprøve?
    @State private var leter = true
    @State private var fantKortet = false
    @State private var lagreSomProfil = true

    struct Resultat {
        var karakterisering: Kamerakarakterisering
        var målt: [Farge]
        var måling: Lysmåling?
        var profil: Kamerakarakterisering?
    }

    var body: some View {
        NavigationStack {
            Group {
                if let resultat { resultatvisning(resultat) } else { plassering }
            }
            .navigationTitle(kort.navn)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Avbryt") { lukk() } }
                ToolbarItem(placement: .confirmationAction) {
                    if let resultat {
                        Button("Bruk") {
                            if lagreSomProfil, let profil = resultat.profil { lagreProfil?(profil) }
                            bruk(resultat.karakterisering, resultat.måling)
                            lukk()
                        }
                    } else {
                        Button("Beregn") { beregn() }.disabled(prøve == nil)
                    }
                }
            }
        }
        .task { await foreslåHjørner() }
        #if os(macOS)
        .frame(minWidth: 640, minHeight: 600)
        #endif
    }

    private var plassering: some View {
        VStack(spacing: 12) {
            GeometryReader { geo in
                let størrelse = Self.tilpasset(CGSize(width: bilde.width, height: bilde.height), i: geo.size)
                let origo = CGPoint(x: (geo.size.width - størrelse.width) / 2, y: (geo.size.height - størrelse.height) / 2)
                let tilVisning = { (p: CGPoint) in CGPoint(x: origo.x + p.x * størrelse.width, y: origo.y + p.y * størrelse.height) }
                ZStack(alignment: .topLeading) {
                    Image(decorative: bilde, scale: 1)
                        .resizable()
                        .frame(width: størrelse.width, height: størrelse.height)
                        .offset(x: origo.x, y: origo.y)
                    // Rutenett med feltsentrene, så man ser at feltene treffes.
                    let punkter = hjørner.map(tilVisning)
                    Path { p in p.addLines(punkter); p.closeSubpath() }
                        .stroke(.white, lineWidth: 1.5)
                        .shadow(radius: 1)
                    ForEach(Array(Kortgeometri.sentre(hjørner: punkter, rader: kort.rader, kolonner: kort.kolonner).enumerated()),
                            id: \.offset) { i, sentrum in
                        Circle()
                            .strokeBorder(.white, lineWidth: 1.5)
                            .background(Circle().fill(kort.felt[i].verdi.farge.swiftUI))
                            .frame(width: 12, height: 12)
                            .position(sentrum)
                    }
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .fill(.tint.opacity(0.35))
                            .strokeBorder(.white, lineWidth: 2)
                            .frame(width: 34, height: 34)
                            .overlay(Text("\(i + 1)").font(.caption.bold()).foregroundStyle(.white))
                            .position(punkter[i])
                            .gesture(DragGesture().onChanged { verdi in
                                hjørner[i] = CGPoint(x: min(max((verdi.location.x - origo.x) / størrelse.width, 0), 1),
                                                     y: min(max((verdi.location.y - origo.y) / størrelse.height, 0), 1))
                            })
                            .accessibilityLabel(Text("Hjørne \(i + 1)"))
                    }
                    if leter { ProgressView().position(x: geo.size.width / 2, y: geo.size.height / 2) }
                }
            }
            HStack {
                Button("Roter", systemImage: "rotate.right") { hjørner = [hjørner[3], hjørner[0], hjørner[1], hjørner[2]] }
                Button("Speil", systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right") {
                    hjørner = [hjørner[1], hjørner[0], hjørner[3], hjørner[2]]
                }
                Button("Finn kortet", systemImage: "viewfinder") { Task { await foreslåHjørner() } }
            }
            .buttonStyle(.bordered)
            .disabled(leter)
            Text(fantKortet
                 ? "Kortet ble funnet. Juster hjørnene 1–4 om nødvendig: de små prikkene viser fasiten og skal ligge på riktig felt."
                 : "Dra hjørnene 1–4 til kortets hjørner, med de grå feltene langs den nederste kanten. De små prikkene viser fasiten og skal ligge på riktig felt.")
                .font(.footnote)
                .foregroundStyle(Color.sekundærTekst)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func resultatvisning(_ r: Resultat) -> some View {
        let s = r.karakterisering.statistikk
        return Form {
            Section {
                Grid(horizontalSpacing: 3, verticalSpacing: 3) {
                    ForEach(0..<kort.rader, id: \.self) { rad in
                        GridRow {
                            ForEach(0..<kort.kolonner, id: \.self) { kolonne in
                                let i = rad * kort.kolonner + kolonne
                                VStack(spacing: 0) {
                                    kort.felt[i].verdi.farge.swiftUI
                                    r.karakterisering.farge(fraKamera: r.målt[i]).swiftUI
                                }
                                .frame(height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .overlay(alignment: .bottomTrailing) {
                                    if s.avvik.indices.contains(i), s.avvik[i] >= 5 {
                                        Image(systemName: "exclamationmark.circle.fill").font(.caption2).foregroundStyle(.white).padding(2)
                                    }
                                }
                            }
                        }
                    }
                }
            } footer: {
                Text("Øverst i hvert felt: fasiten i dagslys. Nederst: fargen fra bildet etter kompensasjon.")
            }
            Section("Nøyaktighet") {
                LabeledContent("Snitt ΔE00") { Text(s.kryssvalidertSnittΔE, format: .number.precision(.fractionLength(1))) }
                LabeledContent("Maks ΔE00") { Text(s.kryssvalidertMaksΔE, format: .number.precision(.fractionLength(1))) }
                LabeledContent("Modell (valgt automatisk)") {
                    Text(r.karakterisering.modell == .matrise ? "Matrise 3 × 3" : "Rotpolynom")
                }
            }
            if let m = r.måling {
                Section("Lyset") {
                    LabeledContent("Fargetemperatur") {
                        Text("≈ \((Int((m.kelvin / 50).rounded()) * 50).formatted(.number.grouping(.never))) K").monospacedDigit()
                    }
                    if let lux = m.lux {
                        LabeledContent("Belysningsstyrke") {
                            Text("≈ \(lux.formatted(.number.precision(.significantDigits(2)))) lx").monospacedDigit()
                        }
                    }
                    if let g = m.fargegjengivelse {
                        LabeledContent("Fargegjengivelse (anslått)") { Text(g, format: .number.precision(.fractionLength(0))) }
                    }
                    LabeledContent("Sannsynlig lystype") {
                        Text(Lystype.anslå(kelvin: m.kelvin, duv: m.duv, fargegjengivelse: m.fargegjengivelse).navn)
                    }
                }
            }
            if r.profil != nil, lagreProfil != nil {
                Section {
                    Toggle("Lagre som kameraprofil", isOn: $lagreSomProfil)
                } footer: {
                    Text("Med en kameraprofil holder det med et gråkort neste gang, også i et annet lys: Kolorist kjenner da kameraets farger, og gråkortet gir lysets farge og styrke.")
                }
            }
            Section {
                Button("Plasser hjørnene på nytt", systemImage: "arrow.uturn.backward") { resultat = nil }
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tallene er kryssvalidert: hvert felt er forutsagt av en modell tilpasset uten det. Under 3 er godt for et telefonkamera. Kompensasjonen gjelder dette lyset og dette kameraet.")
                    MetodeHenvisning(.kamerakarakterisering, .kolorimetri, .ciede2000)
                }
            }
        }
        .formStyle(.grouped)
    }

    /// Finner kortet med Vision og velger retningen der lysheten i feltene stemmer best med fasiten.
    private func foreslåHjørner() async {
        leter = true
        defer { leter = false }
        let bilde = self.bilde, kort = self.kort
        let (funnet, prøve) = await Task.detached(priority: .userInitiated) { () -> ([CGPoint]?, Bildeprøve?) in
            guard let prøve = Bildeprøve(bilde: bilde) else { return (nil, nil) }
            return (Kortgjenkjenning.foreslå(kort: kort, i: bilde, prøve: prøve), prøve)
        }.value
        self.prøve = prøve
        if let funnet {
            hjørner = funnet
            fantKortet = true
        }
    }

    private func beregn() {
        guard let prøve else { return }
        let punkter = hjørner.map { CGPoint(x: $0.x * Double(prøve.bredde), y: $0.y * Double(prøve.høyde)) }
        let sentre = Kortgeometri.sentre(hjørner: punkter, rader: kort.rader, kolonner: kort.kolonner)
        // Gjennomsnitt over ca. en tredjedel av feltets bredde.
        let feltbredde = hypot(punkter[1].x - punkter[0].x, punkter[1].y - punkter[0].y) / Double(kort.kolonner)
        let radius = max(1, Int(feltbredde / 6))
        let målt = sentre.map { prøve.farge(x: Int($0.x), y: Int($0.y), radius: radius) }
        guard let k = Kamerakarakterisering.beste(kamera: målt, referanse: kort) else { return }
        var måling: Lysmåling?
        var profil: Kamerakarakterisering?
        if målLys {
            // Lyset: kameraets farge for de grå feltene (hvitbalansen er låst til dagslys under opptaket).
            let p = Kolorimetri.xy(k.kameraHvit)
            if let t = Kolorimetri.fargetemperatur(x: p.x, y: p.y) {
                var gjengivelse: Double?
                let spektre = kort.felt.compactMap { if case .spekter(let s) = $0.verdi { s } else { nil } }
                if kort.harSpektre {
                    // Kamerafargene med låst hvitbalanse er et grovt mål på fargene under lyset.
                    gjengivelse = Fargegjengivelse.anslag(målt: målt.map(\.xyz), hvit: k.kameraHvit, prøver: spektre)?.indeks
                }
                // Lux fra et mellomgrått felt (det hviteste kan være overeksponert).
                let nøytrale = kort.nøytrale
                let felt = nøytrale.count > 2 ? nøytrale[1] : nøytrale.first
                let luxverdi = felt.flatMap { lux?(målt[$0], kort.felt[$0].verdi.xyz(under: .d65).y) }
                måling = Lysmåling(kelvin: t.kelvin, duv: t.duv, lux: luxverdi, fargegjengivelse: gjengivelse, metode: .referansekort)
                // Kameraprofil: fasiten under lyset i bildet (anslått fra fargetemperaturen), så profilen beskriver
                // kameraet og ikke lyset.
                let scenelys: Lyskilde = kort.harSpektre ? .spekter(Fargegjengivelse.referanselys(kelvin: t.kelvin)) : .hvitpunkt(x: p.x, y: p.y)
                profil = Kamerakarakterisering.beste(kamera: målt, referanse: kort, lys: scenelys)
            }
        }
        resultat = Resultat(karakterisering: k, målt: målt, måling: måling, profil: profil)
    }

    static func tilpasset(_ bilde: CGSize, i ramme: CGSize) -> CGSize {
        let skala = min(ramme.width / max(bilde.width, 1), ramme.height / max(bilde.height, 1))
        return CGSize(width: bilde.width * skala, height: bilde.height * skala)
    }
}

/// Et importert referansekort: feltene slik de ser ut i dagslys og i et valgt lys, og siste karakterisering.
struct ReferansekortDetalj: View {
    @State var kort: Referansekort
    @State private var lys: Lyskilde = .d65
    @State private var bibliotek = Lysbibliotek.delt
    @Environment(\.dismiss) private var lukk

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Grid(horizontalSpacing: 3, verticalSpacing: 3) {
                        ForEach(0..<kort.rader, id: \.self) { rad in
                            GridRow {
                                ForEach(0..<kort.kolonner, id: \.self) { kolonne in
                                    let i = rad * kort.kolonner + kolonne
                                    if i < kort.felt.count {
                                        Farge(xyz: CAT16.tilpass(kort.felt[i].verdi.xyz(under: lys), fra: lys.hvitpunkt,
                                                                 til: Lyskilde.d65.hvitpunkt, grad: 0.7)).swiftUI
                                            .frame(height: 40)
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                            .help(kort.felt[i].navn)
                                    }
                                }
                            }
                        }
                    }
                    if kort.harSpektre {
                        Picker("Lys", selection: $lys) {
                            ForEach(Lyskilde.forslag, id: \.self) { Text($0.navn).tag($0) }
                        }
                    }
                } footer: {
                    Text(kort.harSpektre
                         ? "Med spektre kan fasiten regnes ut i ethvert lys. Feltene vises slik de ser ut i valgt lys når øyet har tilpasset seg delvis."
                         : "Verdiene er målt i ett lys (CIELab D50). I andre lys brukes kromatisk tilpasning.")
                }
                if let tolkning = kort.tolkning {
                    Section {
                        Picker("Verdiene er", selection: Binding(get: { tolkning }, set: { ny in
                            kort = kort.tolket(som: ny)
                            bibliotek.oppdater(kort)
                        })) {
                            Text("CIELab (D50)").tag(Referansekort.Tolkning.lab)
                            Text("XYZ (D50)").tag(Referansekort.Tolkning.xyz)
                        }
                    } footer: {
                        Text("Filen har tre tallkolonner uten overskrift, så Kolorist har gjettet hva de er. Sjekk at feltene over ser riktige ut.")
                    }
                }
                Section("Kortet") {
                    LabeledContent("Felt") { Text("\(kort.felt.count) (\(kort.rader) × \(kort.kolonner))") }
                    LabeledContent("Grå felt") { Text("\(kort.nøytrale.count)") }
                    if let kilde = kort.kilde { LabeledContent("Fil") { Text(kilde).lineLimit(1) } }
                }
                if let lagret = bibliotek.karakteriseringer[kort.id] {
                    let s = lagret.karakterisering.statistikk
                    Section("Siste kalibrering") {
                        LabeledContent("Dato") { Text(lagret.dato, format: .dateTime) }
                        LabeledContent("Kamera") { Text(lagret.kamera) }
                        LabeledContent("Snitt / maks ΔE00") {
                            Text("\(s.kryssvalidertSnittΔE, format: .number.precision(.fractionLength(1))) / \(s.kryssvalidertMaksΔE, format: .number.precision(.fractionLength(1)))")
                                .monospacedDigit()
                        }
                    }
                }
                Section {
                    Group {
                        #if os(macOS)
                        Text("Bruk kortet under Utplukk › Lys › Med referansekort, med iPhone som kamera (Continuity). Lyset kan ikke måles fra Macen; mål lysmiljøer med Kolorist på iPhone, så kommer de hit via iCloud.")
                        #else
                        Text("Bruk kortet under Utplukk › Lys › Med referansekort: hold kortet i samme lys som fargene, og plasser hjørnene i bildet.")
                        #endif
                    }
                    .font(.footnote)
                    .foregroundStyle(Color.sekundærTekst)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(kort.navn)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Ferdig") { lukk() } } }
        }
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 560)
        #endif
    }
}
