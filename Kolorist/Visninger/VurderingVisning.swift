import FargeKI
import FargeKjerne
import SwiftData
import SwiftUI

/// Vurdering: kontrast (WCAG), forskjell (ΔE2000), fargesyn (CVD) og lys (fargen i lysmiljøer). Hele paletter vurderes fra paletten selv.
struct VurderingVisning: View {
    enum Del: String, CaseIterable, Identifiable {
        case kontrast, sammenlign, fargesyn, lys
        var id: String { rawValue }
        var navn: String {
            switch self {
            case .kontrast: String(localized: "Kontrast")
            case .sammenlign: "ΔE"
            // Kort på engelsk («CVD»), så alle fire valgene får plass.
            case .fargesyn: String(localized: "Fargesyn (valg)", defaultValue: "Fargesyn")
            case .lys: String(localized: "Lys")
            }
        }
    }

    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @AppStorage("vurderingDel") private var del: Del = .kontrast

    var body: some View {
        Group {
            switch del {
            case .kontrast: KontrastVurdering()
            case .sammenlign:
                // A/B hentes fra aktiv farge og siste måling; A følger aktiv farge (se SammenligningVisning).
                SammenligningVisning(a: arbeidsbenk.aktivFarge,
                                     b: arbeidsbenk.målinger.last(where: { $0 != arbeidsbenk.aktivFarge }) ?? Farge(hex: "#FFFFFF")!,
                                     innebygd: true)
            case .fargesyn: FargesynVurdering()
            case .lys: LysVurdering()
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        // iPhone: valget står fast øverst i innholdet, ikke i verktøylinjen. I verktøylinjen kunne iOS 26 tegne det
        // sammenpresset, med etikettene oppå hverandre, etter at innholdet under byttet (feilmelding fra 1.1).
        // Fanen sier allerede «Vurdering», så tittellinjen trengs ikke (som i Studio).
        .safeAreaInset(edge: .top, spacing: 0) {
            if påTelefon {
                ViewThatFits(in: .horizontal) {
                    delvalg.pickerStyle(.segmented).fixedSize()
                    delvalg.pickerStyle(.menu).menuIndicator(.visible).fixedSize()
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.skjemabakgrunn)
            }
        }
        .toolbar(påTelefon ? .hidden : .automatic, for: .navigationBar)
        #endif
        .toolbar {
            #if os(macOS)
            ToolbarItem(placement: .principal) { delvalg.pickerStyle(.segmented).fixedSize() }
            #else
            if !påTelefon {
                ToolbarItem(placement: .principal) { delvalg.pickerStyle(.segmented).fixedSize() }
            }
            #endif
        }
    }

    private var påTelefon: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .phone
        #else
        false
        #endif
    }
}

extension VurderingVisning {
    private var delvalg: some View {
        Picker("Vurdering", selection: $del) {
            ForEach(Del.allCases) { Text($0.navn).tag($0) }
        }
    }
}

/// Kontrast for aktiv farge mot en valgt bakgrunn: en stor flate øverst med nøkkeltallet for valgt sjekk (WCAG 2.2,
/// APCA eller LRV) og fargevalgene i flaten, og kravene rett under. Bred visning: flaten til venstre, som i Studio.
private struct KontrastVurdering: View {
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @Environment(\.presentasjonsmodus) private var presentasjon
    @AppStorage("kontrastBakgrunn") private var bakgrunnHex = "#FFFFFF"
    @AppStorage("kontrastType") private var type: Kontrasttype = .wcag
    @AppStorage("kontrastFargesyn") private var fargesyn = "normalt"

    private var bakgrunn: Farge { Kontrastbakgrunn.farge(bakgrunnHex) }

    var body: some View {
        @Bindable var arbeidsbenk = arbeidsbenk
        GeometryReader { geo in
            let bred = Breddeoppsett.erBred(geo.size)
            // AnyLayout bevarer skjemaets tilstand når enheten roteres.
            let oppsett = bred ? AnyLayout(HStackLayout(spacing: 0)) : AnyLayout(VStackLayout(spacing: 0))
            oppsett {
                kort(bred: bred)
                    .frame(width: bred ? geo.size.width / 2 : nil)
                Form {
                    // Vurderingen rett under flaten og typevalget (fargene velges i flaten).
                    switch type {
                    case .wcag: KontrastSeksjon(forgrunn: $arbeidsbenk.aktivFarge)
                    case .apca: APCASeksjon(forgrunn: $arbeidsbenk.aktivFarge)
                    case .lrv: FlatekontrastSeksjon(flate: $arbeidsbenk.aktivFarge, bakgrunn: bakgrunn)
                    }
                    KontrastVisMedSeksjon()
                }
                .formStyle(.grouped)
                #if os(iOS)
                .listSectionSpacing(.compact)
                #endif
                .contentMargins(.top, 0, for: .scrollContent)
            }
            .background(Color.skjemabakgrunn)
        }
        .navigationTitle("Kontrast")
    }

    /// Flaten med valget av kontrastsjekk under – fast øverst mens skjemaet ruller.
    private func kort(bred: Bool) -> some View {
        @Bindable var arbeidsbenk = arbeidsbenk
        return VStack(spacing: 0) {
            Kontrastflate(type: type, forgrunn: $arbeidsbenk.aktivFarge,
                          bakgrunn: Binding(get: { bakgrunn }, set: { bakgrunnHex = Kontrastbakgrunn.tekst($0) }),
                          fargesyn: Fargesynstype(rawValue: fargesyn))
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: bred ? 0 : 20, style: .continuous))
                // Smal visning: fast høyde (større i presentasjonsmodus). Bred visning: fyller høyden til venstre.
                .frame(height: bred ? nil : (presentasjon ? 330 : 250))
                .frame(maxHeight: bred ? .infinity : nil)
            HStack(spacing: 12) {
                Picker("Kontrastsjekk", selection: $type) {
                    ForEach(Kontrasttype.allCases) { Text(verbatim: $0.navn).help($0.hjelp).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                Button("Bytt tekst og bakgrunn", systemImage: "arrow.up.arrow.down") {
                    let gammel = bakgrunn
                    bakgrunnHex = Kontrastbakgrunn.tekst(arbeidsbenk.aktivFarge)
                    arbeidsbenk.aktivFarge = gammel
                }
                .labelStyle(.iconOnly)
                .help("Bytt tekst og bakgrunn")
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 48)
        }
        .frame(maxWidth: .infinity)
        .background(Color.kortbakgrunn, in: Kortform.fargepanel(bred: bred))
        .padding(.leading, 16)
        .padding(.trailing, bred ? 0 : 16)
        .padding(.top, bred ? 16 : 4)
        .padding(.bottom, bred ? 16 : 8)
    }
}

/// Resultatet av en palettvurdering som seksjoner i en liste/et skjema. Brukes i vurderingsarket,
/// både fra en åpen palett og fra palettens meny i oversikten.
struct PalettVurderingInnhold: View {
    let vurdering: PalettVurdering
    /// Palettens farger, for lysdelen (beregnet i appen, ikke av vurdereren).
    var farger: [PalettFarge] = []

    var body: some View {
        // Hva vurderingen bygger på – før selve vurderingen, så det er tydelig hva den sier noe om.
        Section {
            grunnlagsrad("a.square", "Kontrast", "WCAG 2.2-kontrast mellom alle fargepar, og hvor mange som kan brukes til tekst (4,5:1).")
            grunnlagsrad("sun.max", "Lyshet", "Spennet i lyshet (OKLCH) – om paletten har lyse og mørke farger nok til hierarki og lesbarhet.")
            grunnlagsrad("circle.hexagongrid", "Kulører", "Hvilke kulører paletten består av, og om det bare er nøytrale.")
            grunnlagsrad("eye", "Fargesyn", "Fargepar som er tydelig ulike med normalt syn, men blir vanskelige å skille med protan-, deutan- eller tritanavvik eller akromatopsi (ΔE2000 under 10).")
            grunnlagsrad("square.dashed", "Fargerom", "Farger utenfor sRGB, som bare vises riktig på P3-skjermer.")
        } header: { Group {
            Text("Grunnlag for vurderingen")
        }.foregroundStyle(Color.sekundærTekst) } footer: {
            VStack(alignment: .leading, spacing: 6) {
                KortForklaring("Vurderingen gjelder kontrast, lesbarhet og skillbarhet – ikke smak.") {
                    Text(vurdering.kilde == .appleIntelligence
                         ? "Tallene regnes ut nøyaktig i appen. Apple Intelligence på enheten skriver vurderingen ut fra dem, og regner ikke selv."
                         : "Tallene regnes ut nøyaktig i appen, og vurderingen lages etter faste regler: lyshetsspenn minst 0,50, minst ett fargepar på 4,5:1, og ingen fargepar som forveksles ved rød-grønt fargesynsavvik.")
                    Text("Vurderingen sier ikke noe om smak, stemning eller om fargene passer til et formål – bare om kontrast, lesbarhet og skillbarhet.")
                }
                MetodeHenvisning(.wcag, .oklab, .machado, .ciede2000)
            }
            .foregroundStyle(Color.sekundærTekst)
        }
        Seksjon("Oppsummering") { Text(vurdering.oppsummering) }
        punkter(String(localized: "Styrker"), vurdering.styrker, "plus.circle.fill", Color.suksess)
        punkter(String(localized: "Svakheter"), vurdering.svakheter, "minus.circle.fill", Color.advarsel)
        punkter(String(localized: "Forslag"), vurdering.forslag, "arrow.right.circle.fill", Color.accentColor)
        if !farger.isEmpty { LysVurderingSeksjon(farger: farger) }
        Section {
            DisclosureGroup("Tallene for denne paletten") {
                ForEach(vurdering.fakta, id: \.self) { Text($0).font(.callout) }
            }
        } footer: { Group {
            Text(vurdering.kilde == .appleIntelligence
                 ? "Laget med Apple Intelligence på enheten. Kontrast og fargesyn er beregnet eksakt."
                 : "Regelbasert vurdering (Apple Intelligence er ikke tilgjengelig). Kontrast og fargesyn er beregnet eksakt.")
        }.foregroundStyle(Color.sekundærTekst) }
    }

    private func grunnlagsrad(_ symbol: String, _ tittel: LocalizedStringKey, _ tekst: LocalizedStringKey) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(tittel).font(.callout.weight(.semibold))
                Text(tekst).font(.callout).foregroundStyle(Color.sekundærTekst)
            }
        } icon: {
            Image(systemName: symbol).foregroundStyle(Color.accentColor)
        }
    }

    @ViewBuilder
    private func punkter(_ tittel: String, _ liste: [String], _ symbol: String, _ farge: Color) -> some View {
        if !liste.isEmpty {
            Seksjon(tittel) {
                ForEach(liste, id: \.self) { p in
                    Label { Text(p) } icon: { Image(systemName: symbol).foregroundStyle(farge) }
                }
            }
        }
    }
}
