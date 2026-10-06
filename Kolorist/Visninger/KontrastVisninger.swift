import FargeKjerne
import FargeMaaling
import SwiftUI

/// Hvilken kontrastsjekk som vises i Vurdering › Kontrast: tekst og grafikk etter WCAG 2.2, lesekontrast etter APCA
/// (WCAG 3-utkastet), eller flater etter lysrefleksjonsverdi (LRV).
enum Kontrasttype: String, CaseIterable, Identifiable {
    case wcag, apca, lrv
    var id: String { rawValue }
    var navn: String {
        switch self {
        case .wcag: "WCAG 2.2"
        case .apca: "APCA"
        case .lrv: "LRV"
        }
    }
    var hjelp: String {
        switch self {
        case .wcag: String(localized: "Tekst og grafikk etter WCAG 2.2 (kontrastforhold)")
        case .apca: String(localized: "Opplevd lesekontrast etter APCA (WCAG 3-utkast)")
        case .lrv: String(localized: "Flater for bygg og universell utforming (LRV og luminanskontrast)")
        }
    }
}

/// Kontrastbakgrunnen lagres som tekst: sRGB-hex, ellers CSS i Display P3, så P3-bakgrunner ikke rundes av til sRGB.
enum Kontrastbakgrunn {
    static let standard = Farge(hex: "#FFFFFF")!
    static func farge(_ tekst: String) -> Farge { Fargetolk.tolk(tekst) ?? standard }
    static func tekst(_ farge: Farge) -> String { farge.erISRGB ? farge.hex() : Fargemodell.displayP3.tekst(for: farge) }
}

/// WCAG 2.2-kravene for fargen som tekst/grafikk mot bakgrunnen, med «Rett opp».
struct KontrastSeksjon: View {
    @Binding var forgrunn: Farge
    @AppStorage("kontrastBakgrunn") private var bakgrunnHex = "#FFFFFF"

    private var bakgrunn: Farge { Kontrastbakgrunn.farge(bakgrunnHex) }

    var body: some View {
        let test = Kontrasttest(forgrunn: forgrunn, bakgrunn: bakgrunn)
        Section {
            ForEach(WCAGKrav.allCases) { krav in
                KravRad(krav: krav, test: test) { forgrunn = test.rettet(for: krav) }
            }
        } header: {
            Text("Tekst og grafikk (WCAG 2.2)")
        } footer: {
            VStack(alignment: .leading, spacing: 6) {
                Text("Fargen testes som tekst og grafikk mot bakgrunnen. «Rett opp» endrer bare lysheten, og beholder kulør og metning. Regelverket for universell utforming viser til WCAG 2.")
                MetodeHenvisning(.wcag, .oklab)
            }
        }
    }
}

/// APCAs veiledende nivåer for lesekontrast (|Lc|), for tekst i vanlig vekt.
enum APCANivå: Double, CaseIterable, Identifiable {
    case lc90 = 90, lc75 = 75, lc60 = 60, lc45 = 45, lc30 = 30, lc15 = 15
    var id: Double { rawValue }

    var bruk: String {
        switch self {
        case .lc90: String(localized: "Godt nok for all tekst, også brødtekst")
        case .lc75: String(localized: "Brødtekst (minimum)")
        case .lc60: String(localized: "Større tekst, ikke brødtekst")
        case .lc45: String(localized: "Store eller fete overskrifter")
        case .lc30: String(localized: "Ikke-viktig tekst, som plassholdere")
        case .lc15: String(localized: "Ikoner og grafikk, ikke tekst")
        }
    }

    /// Det høyeste nivået Lc når, eller nil når den er for lav til tekst og grafikk.
    static func nådd(_ lc: Double) -> APCANivå? { allCases.first { abs(lc) >= $0.rawValue } }

    static func bruk(_ lc: Double) -> String { nådd(lc)?.bruk ?? String(localized: "For lav til tekst og grafikk") }

    static func retning(_ lc: Double) -> String {
        lc >= 0 ? String(localized: "mørk tekst på lys bakgrunn") : String(localized: "lys tekst på mørk bakgrunn")
    }

    /// «Lc 75» – kuttet mot null, så tallet aldri viser et nivå som ikke er nådd (som WCAG-forholdet).
    static func formatert(_ lc: Double) -> String {
        "Lc " + lc.rounded(.towardZero).formatted(.number.precision(.fractionLength(0)))
    }
}

/// Lesekontrast etter APCA: nivåene fargen når som tekst på bakgrunnen, med «Rett opp».
struct APCASeksjon: View {
    @Binding var forgrunn: Farge
    @AppStorage("kontrastBakgrunn") private var bakgrunnHex = "#FFFFFF"

    private var bakgrunn: Farge { Kontrastbakgrunn.farge(bakgrunnHex) }

    var body: some View {
        let lc = bakgrunn.apcaKontrast(tekst: forgrunn.lagtOver(bakgrunn))
        Section {
            ForEach(APCANivå.allCases) { nivå in
                let bestått = abs(lc) >= nivå.rawValue
                HStack {
                    Image(systemName: bestått ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(bestått ? Color.suksess : Color.feil)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(nivå.bruk)
                        Text("minst Lc \(Int(nivå.rawValue))")
                            .font(.caption)
                            .foregroundStyle(Color.sekundærTekst)
                    }
                    Spacer()
                    if !bestått {
                        Button("Rett opp") { forgrunn = forgrunn.medAPCA(mot: bakgrunn, minst: nivå.rawValue) }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityValue(bestått ? "Bestått" : "Ikke bestått")
            }
        } header: {
            Text("Lesekontrast (APCA)")
        } footer: {
            VStack(alignment: .leading, spacing: 6) {
                Text("APCA er forslaget til lesekontrast i WCAG 3 og følger opplevd lesbarhet bedre enn WCAG 2, særlig for lys tekst på mørk bakgrunn. Lc er positiv for mørk tekst på lys bakgrunn og negativ for lys tekst på mørk. Nivåene er veiledende og gjelder tekst i vanlig vekt; tynnere og mindre tekst trenger mer. «Rett opp» endrer bare lysheten. Regelverket viser fortsatt til WCAG 2.")
                MetodeHenvisning(.apca, .oklab)
            }
        }
    }
}

/// «Vis med»: simuler et fargesynsavvik i flaten øverst i kontrastsjekken.
struct KontrastVisMedSeksjon: View {
    /// «normalt» = ingen simulering.
    @AppStorage("kontrastFargesyn") private var fargesyn = "normalt"

    var body: some View {
        Section {
            Picker("Vis med", selection: $fargesyn) {
                Text("Normalt syn").tag("normalt")
                ForEach(Fargesynstype.allCases) { Text($0.navn).tag($0.rawValue) }
            }
        } footer: {
            VStack(alignment: .leading, spacing: 6) {
                Text("Velg fargene rett i flaten øverst: trykk på teksten eller fargeknappene for lagrede farger, kjent verdi, kamera eller bilde. «Vis med» simulerer et fargesynsavvik i flaten; kravene gjelder alltid de faktiske fargene.")
                MetodeHenvisning(.machado)
            }
        }
    }
}

/// Den store flaten øverst i kontrastsjekken: bakgrunnen med fargen som tekst og grafikk (WCAG, APCA) eller som
/// to likeverdige flater side om side (LRV), og nøkkeltallet for valgt sjekk. Fargene velges rett i flaten: trykk på prøven
/// eller fargeknappene (tekst) eller på en av flatene (LRV). Tallene står i en lesbar farge, prøvene i fargen som testes.
struct Kontrastflate: View {
    let type: Kontrasttype
    @Binding var forgrunn: Farge
    @Binding var bakgrunn: Farge
    /// Simulert fargesynsavvik i flaten (tallene gjelder de faktiske fargene).
    var fargesyn: Fargesynstype? = nil

    private var forgrunnTittel: String { type == .lrv ? String(localized: "Flate") : String(localized: "Tekst eller grafikk") }
    private var bakgrunnTittel: String { type == .lrv ? String(localized: "Tilstøtende flate") : String(localized: "Bakgrunn") }

    private var nøkkeltall: (tall: String, vurdering: String, detalj: String) {
        switch type {
        case .wcag:
            let test = Kontrasttest(forgrunn: forgrunn, bakgrunn: bakgrunn)
            let bestått = WCAGKrav.allCases.filter(test.består).count
            return (test.formatert, test.sammendrag,
                    String(localized: "\(bestått) av \(WCAGKrav.allCases.count) krav i WCAG 2.2"))
        case .apca:
            let lc = bakgrunn.apcaKontrast(tekst: forgrunn.lagtOver(bakgrunn))
            return (APCANivå.formatert(lc), APCANivå.bruk(lc), APCANivå.retning(lc))
        case .lrv:
            let k = Flatekontrast(forgrunn, bakgrunn)
            let bestått = Flatekrav.allCases.filter(k.består).count
            let poeng = k.lrvForskjell.formatted(.number.precision(.fractionLength(0)))
            let luminans = k.michelson.formatted(.number.precision(.fractionLength(2)))
            return (String(localized: "\(poeng) poeng"), String(localized: "\(bestått) av \(Flatekrav.allCases.count) krav"),
                    String(localized: "Forskjell i LRV · luminanskontrast \(luminans)"))
        }
    }

    var body: some View {
        let f = fargesyn.map { forgrunn.simulert($0) } ?? forgrunn
        let b = fargesyn.map { bakgrunn.simulert($0) } ?? bakgrunn
        if type == .lrv {
            // LRV: tallene over to likeverdige flater side om side; trykk på en flate for å velge fargen.
            VStack(spacing: 0) {
                topptekst
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 0) {
                    lrvFelt(forgrunnTittel, farge: $forgrunn, vist: f, visAktivFarge: false)
                    lrvFelt(bakgrunnTittel, farge: $bakgrunn, vist: b, visHvitOgSort: true)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.kortbakgrunn)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                topptekst
                Spacer(minLength: 6)
                FargeVelgerMeny(tittel: forgrunnTittel, farge: $forgrunn, visAktivFarge: false) {
                    prøvetekst.foregroundStyle(f.swiftUI).contentShape(Rectangle())
                }
                // Med korte etiketter når det er plass, ellers bare fargeprøve og hex.
                ViewThatFits(in: .horizontal) {
                    fargeknapper(f, b, merket: true)
                    fargeknapper(f, b, merket: false)
                }
                .padding(.top, 6)
            }
            .foregroundStyle(b.lesbarTekstfarge.swiftUI)
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(b.swiftUI)
        }
    }

    /// Nøkkeltallet med vurdering og detaljer øverst i flaten.
    private var topptekst: some View {
        let n = nøkkeltall
        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                // Tallet kortes aldri ned; vurderingen brytes eller krymper.
                Text(n.tall).koloristFont(.largeTitle, weight: .bold).monospacedDigit()
                    .fixedSize()
                    .layoutPriority(1)
                Text(n.vurdering).koloristFont(.headline).lineLimit(2).minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }
            HStack(spacing: 8) {
                Text(n.detalj).lineLimit(2).opacity(0.8)
                if let fargesyn { Label(fargesyn.navn, systemImage: "eye").lineLimit(1).fontWeight(.semibold) }
            }
            .koloristFont(.subheadline)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(type.navn): \(n.tall), \(n.vurdering). \(n.detalj)")
    }

    /// Én av de to LRV-flatene: navn, LRV og hex i flatens farge. Hele flaten åpner valgene for fargen.
    private func lrvFelt(_ tittel: String, farge: Binding<Farge>, vist: Farge, visAktivFarge: Bool = true,
                         visHvitOgSort: Bool = false) -> some View {
        // Fargen som eget lag bak menyen, så flatene møtes i en rett kant (menyen avrunder både etiketten og
        // bakgrunner lagt på den på iOS 26).
        ZStack {
        vist.swiftUI
        FargeVelgerMeny(tittel: tittel, farge: farge, visAktivFarge: visAktivFarge, visHvitOgSort: visHvitOgSort) {
            VStack(alignment: .leading, spacing: 2) {
                Text(tittel).koloristFont(.caption, weight: .semibold).lineLimit(1).minimumScaleFactor(0.8)
                Text("LRV \(farge.wrappedValue.lrv, format: .number.precision(.fractionLength(0)))")
                    .koloristFont(.title2, weight: .bold).monospacedDigit()
                Spacer(minLength: 4)
                HStack(spacing: 4) {
                    Text(farge.wrappedValue.hex()).koloristFont(.caption, design: .monospaced)
                    Image(systemName: "chevron.up.chevron.down").font(.caption2)
                }
                .opacity(0.85)
            }
            .foregroundStyle(vist.lesbarTekstfarge.swiftUI)
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .contentShape(Rectangle())
        }
        }
    }

    private func fargeknapper(_ f: Farge, _ b: Farge, merket: Bool) -> some View {
        HStack(spacing: 8) {
            fargeknapp(forgrunnTittel, merke: merket ? String(localized: "Tekst") : nil,
                       farge: $forgrunn, vist: f, visAktivFarge: false)
            fargeknapp(bakgrunnTittel, merke: merket ? String(localized: "Bakgrunn") : nil,
                       farge: $bakgrunn, vist: b, visHvitOgSort: true)
            Spacer(minLength: 0)
        }
    }

    /// Fargeknapp nederst i flaten: fargeprøve og hex; åpner valgene for fargen, og tar imot fargen man slipper på den.
    private func fargeknapp(_ tittel: String, merke: String?, farge: Binding<Farge>, vist: Farge, visAktivFarge: Bool = true,
                            visHvitOgSort: Bool = false) -> some View {
        FargeVelgerMeny(tittel: tittel, farge: farge, visAktivFarge: visAktivFarge, visHvitOgSort: visHvitOgSort) {
            HStack(spacing: 6) {
                if let merke { Text(merke).koloristFont(.caption, weight: .semibold).lineLimit(1) }
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(vist.swiftUI)
                    .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).strokeBorder(.secondary.opacity(0.5), lineWidth: 1))
                    .frame(width: 18, height: 18)
                Text(farge.wrappedValue.hex()).koloristFont(.caption, design: .monospaced)
                Image(systemName: "chevron.up.chevron.down").font(.caption2).foregroundStyle(Color.sekundærTekst)
            }
            // Fast kortbakgrunn og vanlig tekstfarge, så knappen er lesbar på alle bakgrunner.
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.kortbakgrunn, in: Capsule())
            .contentShape(Capsule())
        }
    }

    /// Tekst i stor og vanlig størrelse og grafikk, i fargen som testes.
    private var prøvetekst: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Stor tekst").koloristFont(.title)
            Text("Brødtekst i vanlig størrelse.").koloristFont(.body).lineLimit(1)
            HStack(spacing: 10) {
                Image(systemName: "heart.fill")
                Image(systemName: "star.fill")
                RoundedRectangle(cornerRadius: 4).strokeBorder(lineWidth: 2).frame(width: 36, height: 20)
            }
            .koloristFont(.title3)
            .accessibilityHidden(true)
        }
    }
}

struct KontrastForhåndsvisning: View {
    let forgrunn: Farge
    let bakgrunn: Farge
    let test: Kontrasttest
    /// Vises i hjørnet når forhåndsvisningen er simulert (f.eks. «Deuteranopi»).
    var merknad: String? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Stor tekst").font(.system(size: 24, weight: .regular))
                Text("Brødtekst i vanlig størrelse, slik den leses i appen.").font(.system(size: 15))
                HStack(spacing: 10) {
                    Image(systemName: "heart.fill")
                    Image(systemName: "star.fill")
                    RoundedRectangle(cornerRadius: 4).strokeBorder(lineWidth: 2).frame(width: 36, height: 20)
                }
                .font(.title3)
                .accessibilityHidden(true)
            }
            .foregroundStyle(forgrunn.swiftUI)
            Spacer(minLength: 0)
            VStack(spacing: 0) {
                Text(test.formatert).font(.title2.weight(.semibold).monospacedDigit())
                Text(test.sammendrag).font(.caption.weight(.medium))
            }
            .foregroundStyle(forgrunn.swiftUI)
        }
        .padding(14)
        .padding(.top, merknad == nil ? 0 : 14)
        .background(bakgrunn.swiftUI, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(alignment: .topLeading) {
            if let merknad {
                Label(merknad, systemImage: "eye")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(forgrunn.swiftUI)
                    .padding(8)
            }
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(merknad.map { String(localized: "\($0): kontrast \(test.formatert), \(test.sammendrag)") }
                            ?? String(localized: "Kontrast \(test.formatert), \(test.sammendrag)"))
    }
}

struct KravRad: View {
    let krav: WCAGKrav
    let test: Kontrasttest
    var rettOpp: () -> Void

    var body: some View {
        let bestått = test.består(krav)
        HStack {
            Image(systemName: bestått ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(bestått ? Color.suksess : Color.feil)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(krav.navn)
                Text("\(krav.suksesskriterium) · minst \(krav.minimum, format: .number.precision(.fractionLength(1))):1")
                    .font(.caption)
                    .foregroundStyle(Color.sekundærTekst)
            }
            Spacer()
            if !bestått {
                Button("Rett opp", action: rettOpp)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(bestått ? "Bestått" : "Ikke bestått")
    }
}

/// Skriftkontrast i en palett: hver farge som tekst på hver av de andre, med valgt WCAG-krav. Står rett i
/// palettvisningen (og i et ark fra palettlista).
struct Kontrastmatrise: View {
    let farger: [PalettFarge]
    @AppStorage("kontrast.krav") private var krav: WCAGKrav = .aaTekst
    @State private var valgt: Kontrasttest?

    var body: some View {
        // Kontrasten er lik begge veier, så hvert fargepar telles én gang.
        let par = farger.indices.flatMap { i in farger.indices.filter { $0 > i }.map { (i, $0) } }
        let bestått = par.filter { Kontrasttest(forgrunn: farger[$0.0].farge, bakgrunn: farger[$0.1].farge).består(krav) }.count
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "a.square.fill").foregroundStyle(Color.accentColor)
                Picker("Krav", selection: $krav) {
                    ForEach(WCAGKrav.allCases) { Text($0.navn).tag($0) }
                }
                .labelsHidden()
                .fixedSize()
                Spacer(minLength: 0)
                Text("\(bestått) av \(par.count) fargepar består")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Color.sekundærTekst)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                Grid(horizontalSpacing: 4, verticalSpacing: 4) {
                    GridRow {
                        Text("Tekst ↓ / bakgrunn →").font(.caption2).foregroundStyle(Color.sekundærTekst).frame(width: 60)
                        ForEach(farger) { bg in
                            FargeRute(farge: bg.farge, visTekst: false, hjørne: 6).frame(width: 56, height: 28)
                        }
                    }
                    ForEach(farger) { fg in
                        GridRow {
                            FargeRute(farge: fg.farge, visTekst: false, hjørne: 6).frame(width: 60, height: 52)
                            ForEach(farger) { bg in
                                celle(Kontrasttest(forgrunn: fg.farge, bakgrunn: bg.farge), sammeFarge: fg.id == bg.id)
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
            }
            Text("Trykk på en rute for kontrasten mot alle kravene og forslag til en farge som består.")
                .font(.footnote)
                .foregroundStyle(Color.sekundærTekst)
        }
        .sheet(item: $valgt) { t in
            NavigationStack {
                Form {
                    KontrastForhåndsvisning(forgrunn: t.forgrunn, bakgrunn: t.bakgrunn, test: t)
                    ForEach(WCAGKrav.allCases) { k in KravRad(krav: k, test: t) { Utklippstavle.kopier(t.rettet(for: k)) } }
                }
                .formStyle(.grouped)
                .navigationTitle("\(t.forgrunn.hex()) på \(t.bakgrunn.hex())")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
            }
            .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    private func celle(_ t: Kontrasttest, sammeFarge: Bool) -> some View {
        if sammeFarge {
            Color.clear.frame(width: 56, height: 52)
        } else {
            let bestått = t.består(krav)
            Button { valgt = t } label: {
                VStack(spacing: 2) {
                    Text("Aa").font(.headline)
                    Text(t.formatert).font(.caption2.monospacedDigit())
                }
                .foregroundStyle(t.forgrunn.swiftUI)
                .frame(width: 56, height: 52)
                .background(t.bakgrunn.swiftUI, in: RoundedRectangle(cornerRadius: 6))
                .overlay(alignment: .topTrailing) {
                    Image(systemName: bestått ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(bestått ? Color.suksess : Color.feil)
                        .background(Circle().fill(.background))
                        .offset(x: 4, y: -4)
                }
                .opacity(bestått ? 1 : 0.55)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(t.forgrunn.hex()) på \(t.bakgrunn.hex()), \(t.formatert), \(bestått ? String(localized: "bestått") : String(localized: "ikke bestått"))")
        }
    }
}

/// Skriftkontrasten for en palett i et ark (fra menyen i palettlista).
struct KontrastmatriseArk: View {
    let palett: Palett
    @Environment(\.dismiss) private var lukk

    var body: some View {
        NavigationStack {
            ScrollView {
                Kontrastmatrise(farger: palett.farger).padding()
            }
            .navigationTitle("Skriftkontrast")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { Button("Ferdig") { lukk() } }
        }
    }
}

extension Kontrasttest: @retroactive Identifiable {
    public var id: String { forgrunn.hex(medAlfa: true) + bakgrunn.hex(medAlfa: true) }
}

/// Kontrast mellom flater for bygg og universell utforming: forskjell i lysrefleksjonsverdi (LRV)
/// og luminanskontrast, slik arkitekter og NS 11001 / BS 8300 bruker det.
struct FlatekontrastSeksjon: View {
    @Binding var flate: Farge
    let bakgrunn: Farge
    /// Lysmiljøet flatene ses i (nil = dagslys, som LRV er definert for).
    @AppStorage("lrvLysmiljø") private var lysmiljøID = ""
    @State private var lys = Lysbibliotek.delt

    private var lysmiljø: Lysmiljø? { lys.alleLysmiljøer.first { $0.id.uuidString == lysmiljøID } }

    var body: some View {
        let k = Flatekontrast(flate, bakgrunn)
        Section {
            HStack(spacing: 0) {
                verdi(String(localized: "LRV flate"), flate.lrv.formatted(.number.precision(.fractionLength(0))))
                verdi(String(localized: "LRV bakgrunn"), bakgrunn.lrv.formatted(.number.precision(.fractionLength(0))))
                verdi(String(localized: "Forskjell"), k.lrvForskjell.formatted(.number.precision(.fractionLength(0))) + " p.")
                verdi(String(localized: "Luminanskontrast"), k.michelson.formatted(.number.precision(.fractionLength(2))))
            }
            .padding(.vertical, 4)
            LysmiljøVelger(tittel: "Lys", valgt: Binding(get: { lysmiljø?.id }, set: { lysmiljøID = $0?.uuidString ?? "" }),
                           ingen: "Dagslys (LRV)")
            if let miljø = lysmiljø {
                // Refleksjonen under lyset: spektralt for lysrør og LED, så flater kan få en annen kontrast enn LRV tilsier.
                let yf = miljø.xyzUnderLyset(flate).y * 100, yb = miljø.xyzUnderLyset(bakgrunn).y * 100
                let kontrast = yf + yb > 0 ? abs(yf - yb) / (yf + yb) : 0
                HStack(spacing: 0) {
                    verdi(String(localized: "Flate i lyset"), yf.formatted(.number.precision(.fractionLength(0))))
                    verdi(String(localized: "Bakgrunn i lyset"), yb.formatted(.number.precision(.fractionLength(0))))
                    verdi(String(localized: "Forskjell"), abs(yf - yb).formatted(.number.precision(.fractionLength(0))) + " p.")
                    verdi(String(localized: "Luminanskontrast"), kontrast.formatted(.number.precision(.fractionLength(2))))
                }
                .padding(.vertical, 4)
            }
            ForEach(Flatekrav.allCases) { krav in
                let bestått = k.består(krav)
                HStack {
                    Image(systemName: bestått ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(bestått ? Color.suksess : Color.feil)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(krav.navn)
                        Text("\(krav.kilde) · \(krav.kravtekst)")
                            .font(.caption)
                            .foregroundStyle(Color.sekundærTekst)
                    }
                    Spacer()
                    if !bestått {
                        Button("Rett opp") { flate = k.rettet(for: krav) }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityValue(bestått ? "Bestått" : "Ikke bestått")
            }
        } header: {
            Text("Flater (LRV)")
        } footer: {
            VStack(alignment: .leading, spacing: 6) {
                Text("For vegg, gulv, dør og håndlist: lysrefleksjonsverdien (LRV) er andelen lys flaten reflekterer, som på malingskart. BS 8300 ber om minst 30 poeng forskjell mellom tilstøtende flater; NS 11001 bruker luminanskontrast (Y₁ − Y₂)/(Y₁ + Y₂), minst 0,4 for viktige flater og 0,8 for skilt.")
                if lysmiljø != nil {
                    Text("Kravene gjelder LRV (dagslys). Verdiene «i lyset» viser hvor mye lys flatene reflekterer under valgte betraktningsforhold – med lysrør og LED kan kontrasten bli en annen. Spektrene er anslått fra fargene.")
                }
                MetodeHenvisning(.lrv, .oklab)
            }
        }
    }

    private func verdi(_ tittel: String, _ tekst: String) -> some View {
        VStack(spacing: 2) {
            Text(tekst).font(.title3.weight(.semibold).monospacedDigit())
            Text(tittel).font(.caption2).foregroundStyle(Color.sekundærTekst).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
