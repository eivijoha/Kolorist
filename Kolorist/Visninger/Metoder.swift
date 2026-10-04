import SwiftUI

/// Metodene appen bygger på, med kilde, forklaring og hvordan Kolorist bruker dem.
/// Vises per seksjon («Metode: …») og samlet under «Metoder og kilder», så brukeren alltid kan se
/// hva tallene og fargene bygger på – også hva som er utviklet for appen og hva som er etablert fag.
enum Metode: String, CaseIterable, Identifiable {
    case oklab, cssColor4, cieLab, ciede2000, wcag, lrv, munsell, machado, icc, renCMYK, harmonier, kunnskapsbase,
         cam16, kolorimetri, kamerakarakterisering, filamentfarger

    var id: String { rawValue }

    /// Kort navn i henvisningen under en seksjon.
    var kortnavn: String {
        switch self {
        case .oklab: "OKLab/OKLCH"
        case .cssColor4: "CSS Color 4"
        case .cieLab: "CIELab D50"
        case .ciede2000: "CIEDE2000"
        case .wcag: "WCAG 2.2"
        case .lrv: "LRV"
        case .munsell: "Munsell"
        case .machado: String(localized: "Machado mfl. 2009")
        case .icc: "ICC/ColorSync"
        case .renCMYK: String(localized: "UCR/GCR")
        case .harmonier: String(localized: "Fargesirkler")
        case .kunnskapsbase: String(localized: "Kunnskapsbase")
        case .cam16: "CAM16"
        case .kolorimetri: String(localized: "CIE-kolorimetri")
        case .kamerakarakterisering: String(localized: "Kamerakarakterisering")
        case .filamentfarger: "FilamentColors.xyz"
        }
    }

    var tittel: String {
        switch self {
        case .oklab: String(localized: "OKLab og OKLCH")
        case .cssColor4: String(localized: "CSS Color Module Level 4")
        case .cieLab: String(localized: "CIELab, CIE LCH og Bradford-tilpasning")
        case .ciede2000: String(localized: "CIEDE2000 (ΔE00)")
        case .wcag: String(localized: "WCAG 2.2 kontrast")
        case .lrv: String(localized: "Lysrefleksjonsverdi og luminanskontrast")
        case .munsell: String(localized: "Munsell-systemet")
        case .machado: String(localized: "Simulering av fargesynsavvik")
        case .icc: String(localized: "ICC-profiler og fargestyring")
        case .renCMYK: String(localized: "Rene CMYK-verdier (UCR/GCR)")
        case .harmonier: String(localized: "Fargesirkler og harmonier")
        case .kunnskapsbase: String(localized: "Fargesemantikk og KI")
        case .cam16: String(localized: "CAM16 og CAT16 – fargeinntrykk i ulikt lys")
        case .kolorimetri: String(localized: "Spektre, lyskilder og fargetemperatur")
        case .kamerakarakterisering: String(localized: "Kamerakarakterisering med referansekort")
        case .filamentfarger: String(localized: "Filamentfarger fra FilamentColors.xyz")
        }
    }

    /// Hvem som står bak, eller at metoden er laget for Kolorist.
    var kilde: String {
        switch self {
        case .oklab: "Björn Ottosson: «A perceptual color space for image processing» (2020)"
        case .cssColor4: "W3C: CSS Color Module Level 4 (Candidate Recommendation)"
        case .cieLab: "CIE 15:2018 Colorimetry; K. M. Lam (1985), Bradford-transformasjonen"
        case .ciede2000: "G. Sharma, W. Wu, E. N. Dalal: Color Research & Application 30(1), 2005; CIE 142-2001"
        case .wcag: "W3C: Web Content Accessibility Guidelines 2.2, suksesskriterium 1.4.3, 1.4.6 og 1.4.11"
        case .lrv: "CIE 15 (luminansfaktor Y); BS 8300-2:2018; NS 11001-1:2018 og Byggforsk 220.300"
        case .munsell: "Newhall, Nickerson & Judd: «Final Report of the O.S.A. Subcommittee on the Spacing of the Munsell Colors», JOSA 33(7), 1943; ASTM D1535"
        case .machado: "G. M. Machado, M. M. Oliveira, L. A. F. Fernandes: IEEE TVCG 15(6), 2009"
        case .icc: "International Color Consortium (ICC.1); Apple ColorSync via Core Graphics"
        case .renCMYK: String(localized: "Etablert trykkteknikk; søket er utviklet for Kolorist")
        case .harmonier: String(localized: "Klassisk fargelære (Johannes Itten for RYB); D. B. Judd og G. Wyszecki: «Color in Business, Science, and Industry» (naturlig fargeorden); avbildningene er utviklet for Kolorist")
        case .kunnskapsbase: String(localized: "Utviklet for Kolorist; språkmodell fra Apple (Foundation Models)")
        case .cam16: "C. Li, Z. Li, Z. Wang mfl.: «Comprehensive color solutions: CAM16, CAT16, and CAM16-UCS», Color Research & Application 42(6), 2017"
        case .kolorimetri: "CIE 15:2018 Colorimetry; Y. Ohno: «Practical use and calculation of CCT and Duv», LEUKOS 10(1), 2014; S. A. Burns: «Numerical methods for smoothest reflectance reconstruction», Color Research & Application 45(1), 2020"
        case .kamerakarakterisering: "G. D. Finlayson, M. Mackiewicz, A. Hurlbert: «Color correction using root-polynomial regression», IEEE TIP 24(5), 2015; ISO 17321-1"
        case .filamentfarger: String(localized: "FilamentColors.xyz, lisensiert under CC BY 4.0; uttrekk og omregning er laget for Kolorist, som ikke er tilknyttet FilamentColors.xyz")
        }
    }

    var forklaring: String {
        switch self {
        case .oklab:
            String(localized: "Et perseptuelt fargerom der like tallsteg oppleves som like store fargeforskjeller. Kolorist regner overganger i OKLab, og toneskalaer, lysere/mørkere trinn, harmonier og metning i OKLCH (lyshet, kroma, kulør).")
        case .cssColor4:
            String(localized: "Standarden for farger på nettet. Kolorist bruker spesifikasjonens matriser og overføringsfunksjoner for sRGB, Display P3, Adobe RGB, Lab og OKLab, dens gamut-kartlegging (kroma reduseres i OKLCH mens lyshet og kulør bevares) og dens tekstsyntaks for farger.")
        case .cieLab:
            String(localized: "CIEs fargerom basert på menneskets fargesyn. Kolorist oppgir Lab og LCH med hvitpunkt D50, som ICC-profiler og Photoshop, og bruker Bradford-transformasjonen mellom D65 og D50.")
        case .ciede2000:
            String(localized: "CIEs formel for opplevd fargeforskjell. Brukes ved sammenligning av farger, gamutavvik og i analysen av farger som blir vanskelige å skille med fargesynsavvik. Implementasjonen er kontrollert mot testdataene i Sharma mfl.")
        case .wcag:
            String(localized: "W3Cs krav til kontrast mellom tekst/grafikk og bakgrunn, regnet ut fra relativ luminans. «Rett opp» endrer bare lysheten (OKLCH) til kravet er oppfylt.")
        case .lrv:
            String(localized: "LRV er CIE-luminansen Y i prosent – andelen synlig lys en flate reflekterer, slik malingsprodusentene oppgir den. Kolorist regner den for fargen slik den vises i sRGB. Kontrast mellom flater oppgis som forskjell i LRV-poeng (BS 8300: minst 30) og som luminanskontrast (Y₁ − Y₂)/(Y₁ + Y₂) etter NS 11001 (0,4 for viktige flater, 0,8 for skilt). «Rett opp» endrer bare lysheten i OKLCH.")
        case .munsell:
            String(localized: "Kulør, valør og kroma etter Munsell. Omregningen bruker renotasjonsdataene fra 1943 (CIE xyY under lyskilde C, offentlige data) med interpolasjon i kroma, kulør og valør, Bradford-tilpasning til D65, og ASTM D1535 for sammenhengen mellom valør og luminans. Notasjonen er en tilnærming; fysiske Munsell-prøver kan avvike.")
        case .machado:
            String(localized: "Fysiologisk basert modell for protan-, deutan- og tritanavvik, med matriser i lineær sRGB og alvorlighetsgrad som blanding med normalt syn. Akromatopsi vises som luminans alene. Brukes i Vurdering › Fargesyn, kontrastforhåndsvisningen og kamerafilteret. Simuleringen er en tilnærming; opplevelsen varierer mellom personer.")
        case .icc:
            String(localized: "Konvertering mellom fargerom via ICC-profiler, med valgt gjengivelseshensikt. Gjøres av Apples fargestyring (ColorSync). Profiler følger ikke med appen; Kolorist bruker systemets profiler og profiler du importerer.")
        case .renCMYK:
            String(localized: "Felles grått innslag i C, M og Y flyttes til sort, og Kolorist søker etter separasjonen med færrest trykkfarger som holder seg innenfor 1 ΔE00 av profilens egen separasjon.")
        case .harmonier:
            String(localized: "Komplementær, split-komplementær, analog (også med komplementær aksent), triade, kvadrat, dobbelt komplementær og jevn fordeling beregnes som vinkler på valgt fargesirkel: OKLCH, CIE LCH, HSL, RYB, Munsell eller Herings motfargesirkel. Med Munsell brukes ekte Munsell-farger i bokas trinn (kulør 2,5, valør 1, kroma 2). RYB- og Hering-sirklene er stykkevis lineære avbildninger laget for appen. Naturlig lyshetsrekkefølge flytter lysheten etter kulørens egen lyshet – lysheten der kuløren er mest mettet innenfor gamut – med 60 % av forskjellen fra grunnfargen (etter Judds prinsipp om naturlig fargeorden); omvendt rekkefølge speiler forskyvningen.")
        case .cam16:
            String(localized: "En modell for hvordan farger oppleves under gitte forhold: lysets farge, hvor sterkt det er, og omgivelsene. «Se i lys» regner først ut flaten under lyset – spektralt når lysets spekter er kjent, med et glatt anslått refleksjonsspekter for fargen – og deretter inntrykket i rommet, der øyet bare delvis tilpasser seg lysets farge og svakt lys gir mindre fargerike farger. Til slutt vises den skjermfargen som gir samme lyshet og fargerikhet. Kompensasjon for lys bruker CAT16 med full tilpasning til dagslys (D65).")
        case .kolorimetri:
            String(localized: "Lyskilder beskrives med spektre fra CIE (dagslysserien, standardlys A, lysrør og LED-typer) eller som sortlegemer. Korrelert fargetemperatur og avstand fra Plancks kurve (Duv) regnes etter Ohno. Farger uten målt spekter får det glatteste spekteret som gir fargen i dagslys (Burns). Fargegjengivelse anslås fra referansekortets spektre, sammenlignet med et referanselys med samme fargetemperatur; tallet er skalert så det ligger nær Ra, men er ikke en offisiell fargegjengivelsesindeks. Standard betraktningsforhold følger belysningsstyrken i ISO 3664, NS-EN 12464-1 og CIE 157.")
        case .kamerakarakterisering:
            String(localized: "Med et referansekort i bildet tilpasser Kolorist en tonekurve per kanal fra de grå feltene og deretter en matrise eller et rotpolynom fra kamerafarger til fasiten i dagslys – den modellen som forutsier best. Nøyaktigheten oppgis som snitt og maks ΔE00, kryssvalidert: hvert felt forutsies av en modell tilpasset uten det. En kameraprofil laget én gang gjør at et gråkort holder i nytt lys. Kortet finnes automatisk i bildet (Vision), og lysheten i feltene avgjør hvilken vei det ligger. Referanseverdiene for kortet følger ikke med appen; du importerer dem selv.")
        case .filamentfarger:
            String(localized: "Filamentfargene kommer fra FilamentColors.xyz, som skriver ut prøver av filament fra mange produsenter og måler dem med kolorimeter (CHNSpec DS-220). Verdiene er CIELab under D65 med 10°-observatør, slik det står i kildekoden deres. Kolorist regner Lab om til XYZ med D65-hvitpunktet for 10° og tilpasser til 2° med Bradford; forskjellen mellom observatørene kan ikke regnes om nøyaktig uten spektre, men er liten. Eldre prøver uten måling har en farge fra et fotografi og er merket som anslått. Hver farge lenker til prøven hos FilamentColors.xyz, der du finner bilder og mer om filamentet. Uttrekket følger med appen og oppdateres med nye versjoner; appen henter ingenting fra nettet. Bilder, kjøpslenker og koblinger til andre fargesystemer er ikke tatt med. Farger varierer mellom produksjonspartier og etter overflate, så se på en fysisk prøve før du bestemmer deg.")
        case .kunnskapsbase:
            String(localized: "Paletter fra verdiord og «Beskriv en farge» bygger på en kunnskapsbase med fargebegreper laget for appen. Språkmodellen på enheten tolker ordene og velger kulørfamilier og uttrykk. Selve paletten komponeres deretter etter faste regler i OKLCH: harmoniprinsipp, lik valør eller lik metning, én aksent, lys eller mørk bakgrunn og tekst med minst 7:1 kontrast. Tekst om fargebetydning er konvensjoner, ikke vitenskapelige fakta.")
        }
    }

    var lenke: URL? {
        switch self {
        case .oklab: URL(string: "https://bottosson.github.io/posts/oklab/")
        case .cssColor4: URL(string: "https://www.w3.org/TR/css-color-4/")
        case .cieLab: URL(string: "https://cie.co.at/publications/colorimetry-4th-edition")
        case .ciede2000: URL(string: "https://doi.org/10.1002/col.20070")
        case .wcag: URL(string: "https://www.w3.org/TR/WCAG22/")
        case .lrv: URL(string: "https://www.standard.no/no/Nettbutikk/produktkatalogen/Produktpresentasjon/?ProductID=1000883")
        case .munsell: URL(string: "https://doi.org/10.1364/JOSA.33.000385")
        case .machado: URL(string: "https://doi.org/10.1109/TVCG.2009.113")
        case .icc: URL(string: "https://www.color.org/specification/ICC.1-2022-05.pdf")
        case .cam16: URL(string: "https://doi.org/10.1002/col.22131")
        case .kolorimetri: URL(string: "https://cie.co.at/publications/colorimetry-4th-edition")
        case .kamerakarakterisering: URL(string: "https://doi.org/10.1109/TIP.2015.2405336")
        case .filamentfarger: URL(string: "https://filamentcolors.xyz/about/")
        case .renCMYK, .harmonier, .kunnskapsbase: nil
        }
    }
}

/// «Metode: OKLab/OKLCH · CSS Color 4 ⓘ» under en seksjon. Trykk viser kilde og forklaring.
struct MetodeHenvisning: View {
    let metoder: [Metode]
    @State private var vis = false

    init(_ metoder: Metode...) { self.metoder = metoder }

    var body: some View {
        Button { vis = true } label: {
            // Én tekst, så navnene flyter over flere linjer sammen med ledeteksten.
            let navn = Text(metoder.map(\.kortnavn).joined(separator: " · ")).underline()
            let info = Text(Image(systemName: "info.circle"))
            Group {
                if metoder.count == 1 { Text("Metode: \(navn) \(info)") } else { Text("Metoder: \(navn) \(info)") }
            }
            .font(.footnote)
            .foregroundStyle(Color.sekundærTekst)
            .multilineTextAlignment(.leading)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "Metoder: \(metoder.map(\.tittel).joined(separator: ", "))"))
        .accessibilityHint("Viser kilder og forklaring")
        .sheet(isPresented: $vis) { MetoderArk(metoder: metoder) }
    }
}

/// Kilde og forklaring for utvalgte metoder, med lenke til alle.
struct MetoderArk: View {
    var metoder: [Metode] = Metode.allCases
    @Environment(\.dismiss) private var lukk

    var body: some View {
        NavigationStack {
            List {
                ForEach(metoder) { MetodeRad(metode: $0) }
                if metoder.count < Metode.allCases.count {
                    Section {
                        NavigationLink("Alle metoder og kilder") {
                            List { ForEach(Metode.allCases) { MetodeRad(metode: $0) } }
                                .navigationTitle("Metoder og kilder")
                        }
                    }
                }
            }
            .navigationTitle(metoder.count == Metode.allCases.count ? "Metoder og kilder" : metoder.count == 1 ? "Metode" : "Metoder")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Ferdig") { lukk() } } }
        }
        .presentationDetents([.medium, .large])
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 420)
        #endif
    }
}

private struct MetodeRad: View {
    let metode: Metode

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(metode.forklaring)
                Text(metode.kilde)
                    .font(.footnote)
                    .foregroundStyle(Color.sekundærTekst)
                    .textSelection(.enabled)
                if let lenke = metode.lenke {
                    Link(destination: lenke) {
                        Label("Les kilden", systemImage: "arrow.up.right.square")
                    }
                    .font(.footnote)
                }
            }
            .padding(.vertical, 2)
        } header: {
            Text(metode.tittel).foregroundStyle(Color.sekundærTekst)
        }
    }
}
