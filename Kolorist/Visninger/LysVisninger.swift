import FargeKjerne
import FargeMaaling
import SwiftUI

extension Lysmiljø {
    /// Lysrør, LED og målte spektre: ujevne spektre der det anslåtte spekteret for fargen betyr noe.
    var harUjevntSpekter: Bool {
        switch lyskilde {
        case .cie, .spekter: true
        default: false
        }
    }
}

enum Lysbeskrivelse {
    /// «≈ 2700 K · 100 lx».
    static func tekst(_ miljø: Lysmiljø) -> String {
        let lux = miljø.lux.formatted(.number.precision(.significantDigits(2)))
        if let t = miljø.lyskilde.fargetemperatur {
            let kelvin = (Int((t.kelvin / 10).rounded()) * 10).formatted(.number.grouping(.never))
            return String(localized: "≈ \(kelvin) K · \(lux) lx")
        }
        return String(localized: "\(lux) lx")
    }
}

/// Lysmiljøene som seksjoner i Vurdering › Lys: egne (kan redigeres), eksempler, standarder og skjulte. Haken til
/// høyre merker lysmiljøene fargen vises i øverst.
struct LysmiljøSeksjoner: View {
    @State private var bibliotek = Lysbibliotek.delt
    @State private var redigerer: Lysmiljø?
    @State private var måler = false

    var body: some View {
        Section {
            ForEach(bibliotek.lysmiljøer) { miljø in
                HStack {
                    Button { redigerer = miljø } label: { rad(miljø) }
                        .buttonStyle(.plain)
                    visningsmerke(miljø)
                }
                .swipeActions { Button("Slett", systemImage: "trash", role: .destructive) { bibliotek.slett(miljø) } }
                .contextMenu { Button("Slett", systemImage: "trash", role: .destructive) { bibliotek.slett(miljø) } }
            }
            #if os(iOS)
            Button("Mål lyset med kameraet …", systemImage: "camera.metering.center.weighted") { måler = true }
            #endif
            Button("Nytt lysmiljø", systemImage: "plus") {
                redigerer = Lysmiljø(navn: String(localized: "Nytt lysmiljø"), lyskilde: .sortlegeme(kelvin: 3000), lux: 300)
            }
        } header: {
            Text("Mine lysmiljøer")
        } footer: {
            #if os(macOS)
            Text("Lagre lyset der fargene skal brukes – stua, kontoret, butikken – med fargetemperatur og lysstyrke. Lysmiljøer målt med kameraet på iPhone og iPad kommer hit via iCloud.")
            #else
            Text("Lagre lyset der fargene skal brukes – stua, kontoret, butikken. Mål det med kameraet der du står, eller legg inn fargetemperatur og lysstyrke selv.")
            #endif
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $måler) { LysmålingArk() }
        #endif
        .sheet(item: $redigerer) { miljø in
            LysmiljøRedigering(miljø: miljø) { lagret in
                let nytt = !bibliotek.lysmiljøer.contains { $0.id == lagret.id }
                bibliotek.lagre(lagret)
                bibliotek.valgtLysmiljø = lagret.id
                // Et nytt lysmiljø vises med én gang øverst.
                if nytt && !bibliotek.erVist(lagret) { bibliotek.veksleVist(lagret) }
            }
        }
        if !bibliotek.synligeEksempler.isEmpty {
            Section {
                ForEach(bibliotek.synligeEksempler) { innebygdRad($0) }
            } header: {
                Text("Eksempler")
            } footer: {
                #if os(macOS)
                Text("Skjul eksempler og standarder du ikke bruker med øyet til høyre på raden.")
                #else
                Text("Sveip eller trykk og hold for å skjule eksempler og standarder du ikke bruker.")
                #endif
            }
        }
        if !bibliotek.synligeStandarder.isEmpty {
            Section {
                ForEach(bibliotek.synligeStandarder) { innebygdRad($0) }
            } header: {
                Text("Standarder")
            } footer: {
                Text("Belysningsstyrken følger standardene: ISO 3664 for vurdering av trykk og bilder, NS-EN 12464-1 for arbeidsplasser og skoler, og CIE 157 for museer. Lysets spekter er et typisk valg – D50 for grafisk vurdering, nøytral LED (4000 K) for arbeidsplasser og varmt lys (3000 K) i museer.")
            }
        }
        if !bibliotek.skjulteLysmiljøer.isEmpty {
            Section {
                ForEach(bibliotek.skjulteLysmiljøer) { miljø in
                    HStack {
                        rad(miljø).opacity(0.6)
                        Button("Vis") { withAnimation { bibliotek.settSkjult(miljø, false) } }
                            .buttonStyle(.borderless)
                    }
                }
            } header: {
                Text("Skjulte")
            } footer: {
                Text("Skjulte lysmiljøer vises ikke i valgene for lysmiljø og i vurderingen av paletter.")
            }
        }
    }

    /// Et eksempel eller en standard: trykk for å velge; kan skjules (sveip eller trykk og hold, knapp på Mac).
    private func innebygdRad(_ miljø: Lysmiljø) -> some View {
        let skjul = { withAnimation { bibliotek.settSkjult(miljø, true) } }
        return HStack {
            // Trykk merker lysmiljøet for visning øverst (eller fjerner merket).
            Button { withAnimation { bibliotek.veksleVist(miljø) } } label: { rad(miljø) }
                .buttonStyle(.plain)
            visningsmerke(miljø)
            #if os(macOS)
            Button("Skjul", systemImage: "eye.slash", action: skjul)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .help("Skjul lysmiljøet")
            #endif
        }
        .swipeActions { Button("Skjul", systemImage: "eye.slash", action: skjul).tint(.gray) }
        .contextMenu { Button("Skjul", systemImage: "eye.slash", action: skjul) }
    }

    private func rad(_ miljø: Lysmiljø) -> some View {
        HStack {
            Circle()
                .fill(miljø.sett(Farge(hex: "#FFFFFF")!).swiftUI)
                .overlay(Circle().strokeBorder(.separator))
                .frame(width: 24, height: 24)
            VStack(alignment: .leading) {
                Text(miljø.navn).foregroundStyle(Color.primary)
                Text("\(miljø.lyskilde.navn) · \(Lysbeskrivelse.tekst(miljø))")
                    .font(.caption).foregroundStyle(Color.sekundærTekst)
            }
            Spacer()
        }
        .contentShape(Rectangle())
    }

    /// Merket for visning øverst: sirkel med hake når fargen vises i lysmiljøet.
    private func visningsmerke(_ miljø: Lysmiljø) -> some View {
        let vist = bibliotek.erVist(miljø)
        return Button { withAnimation { bibliotek.veksleVist(miljø) } } label: {
            Image(systemName: vist ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(vist ? Color.accentColor : Color.sekundærTekst)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(vist ? String(localized: "Fargen vises i dette lyset") : String(localized: "Vis fargen i dette lyset"))
        .help(vist ? "Ikke vis fargen i dette lyset" : "Vis fargen i dette lyset")
    }
}

/// Redigering av ett lysmiljø: navn, lyskilde og lysstyrke.
struct LysmiljøRedigering: View {
    @State var miljø: Lysmiljø
    var lagre: (Lysmiljø) -> Void
    @Environment(\.dismiss) private var lukk

    /// Valget i lyskildelisten: en av forslagene, eller egen fargetemperatur.
    private enum Valg: Hashable { case forslag(Lyskilde), egen }

    private var valg: Valg {
        if Lyskilde.forslag.contains(miljø.lyskilde) { return .forslag(miljø.lyskilde) }
        return .egen
    }

    private var kelvin: Double { miljø.lyskilde.fargetemperatur?.kelvin ?? 3000 }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Navn", text: $miljø.navn)
                Section {
                    Picker("Lyskilde", selection: Binding(get: { valg }, set: { ny in
                        switch ny {
                        case .forslag(let l): miljø.lyskilde = l
                        case .egen: miljø.lyskilde = Self.lyskilde(kelvin: kelvin)
                        }
                    })) {
                        ForEach(Lyskilde.forslag, id: \.self) { Text($0.navn).tag(Valg.forslag($0)) }
                        if case .hvitpunkt = miljø.lyskilde { Text(miljø.lyskilde.navn).tag(Valg.egen) }
                        else { Text("Egen fargetemperatur").tag(Valg.egen) }
                    }
                    if valg == .egen {
                        LabeledContent("Fargetemperatur") { Text("\(Int(kelvin.rounded()).formatted(.number.grouping(.never))) K").monospacedDigit() }
                        Slider(value: Binding(get: { kelvin }, set: { miljø.lyskilde = Self.lyskilde(kelvin: $0) }),
                               in: 1800...10000, step: 100)
                    }
                } footer: {
                    Text("Under 4000 K regnes lyset som glødelys (sortlegeme), over som dagslys. Lysrør og LED har ujevne spektre som kan endre enkelte farger mer enn fargetemperaturen tilsier.")
                }
                Section {
                    LabeledContent("Belysningsstyrke") { Text("\(miljø.lux.formatted(.number.precision(.significantDigits(2)))) lx").monospacedDigit() }
                    Slider(value: Binding(get: { log10(max(miljø.lux, 10)) }, set: { miljø.lux = Self.rundet(pow(10, $0)) }),
                           in: 1...4.3)
                } footer: {
                    Text("Typisk 50–150 lx i en stue om kvelden, 500 lx på et kontor og over 10 000 lx ute på dagtid.")
                }
                if let m = miljø.måling {
                    Section("Målt") {
                        LabeledContent("Tidspunkt") { Text(m.tidspunkt, format: .dateTime) }
                        LabeledContent("Fargetemperatur") { Text("\(Int(m.kelvin.rounded()).formatted(.number.grouping(.never))) K, Duv \(m.duv, format: .number.precision(.fractionLength(3)))").monospacedDigit() }
                        if let r = m.fargegjengivelse {
                            LabeledContent("Fargegjengivelse (anslått)") { Text(r, format: .number.precision(.fractionLength(0))) }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(miljø.navn)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Avbryt") { lukk() } }
                ToolbarItem(placement: .confirmationAction) { Button("Lagre") { lagre(miljø); lukk() } }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 460)
        #endif
    }

    static func lyskilde(kelvin: Double) -> Lyskilde {
        kelvin < 4000 ? .sortlegeme(kelvin: kelvin) : .dagslys(kelvin: kelvin)
    }

    /// 10, 20, 50, 100, 150, 200, 300 … – to gjeldende siffer.
    static func rundet(_ lux: Double) -> Double {
        let størrelse = pow(10, floor(log10(lux)) - 1)
        return (lux / størrelse).rounded() * størrelse
    }
}
