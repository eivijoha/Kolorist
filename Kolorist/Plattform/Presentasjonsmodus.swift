import SwiftUI

/// Presentasjonsmodus: større tekst og kontroller for prosjektør og deling av skjerm. Brukes av Kolorist underviser og har
/// ikke eget valg i appen: den slås på fra en delingslenke (`DeltVisning.presentasjon`) eller med `-presentasjon YES`.
///
/// Etter lærdommen fra Studieblikk (tekstskalering): macOS har ingen dynamisk tekststørrelse – `dynamicTypeSize` gir samme
/// punktstørrelse på alle nivåer (målt). På Mac løftes derfor punktstørrelsen med et tillegg: fonten i miljøet ved
/// vindusroten (for tekst uten egen font), `koloristFont` der Kolorist setter font selv, og `controlSize(.large)` for
/// knappenes kropp. iPhone og iPad bruker større dynamisk tekst, som gjelder alle tekststiler. Av: ingenting røres, så
/// utseendet er nøyaktig som før. PDF og utskrift (`ImageRenderer`) har egen rot og påvirkes ikke.
///
/// Kjente grenser på Mac (som i Studieblikk): menyvelgere (`Picker` i menystil, `NSPopUpButton`) og segmenterte velgere
/// skalerer ikke; menyer og menylinja følger systemets størrelse.
enum Presentasjonsmodus {
    /// Punkttillegget på Mac (tilsvarer Studieblikks nivå 3).
    static let løft: CGFloat = 5

    /// Basestørrelser i punkt for tekststilene på macOS (før tillegg).
    static let basestørrelser: [Font.TextStyle: CGFloat] = [
        .largeTitle: 26, .title: 22, .title2: 17, .title3: 15,
        .headline: 13, .body: 13, .callout: 12, .subheadline: 11,
        .footnote: 10, .caption: 10, .caption2: 10,
    ]
}

extension EnvironmentValues {
    /// Punkttillegg for tekst i presentasjonsmodus på Mac (0 = av).
    @Entry var presentasjonsløft: CGFloat = 0
    /// Sann når appen er i presentasjonsmodus (for oppsett som skal bli større, f.eks. fargeflaten).
    @Entry var presentasjonsmodus = false
}

private struct KoloristFont: ViewModifier {
    let stil: Font.TextStyle
    let vekt: Font.Weight?
    let design: Font.Design?
    @Environment(\.presentasjonsløft) private var løft

    func body(content: Content) -> some View {
        if løft == 0 {
            content.font(.system(stil, design: design, weight: vekt))
        } else {
            let størrelse = (Presentasjonsmodus.basestørrelser[stil] ?? 13) + løft
            content.font(.system(size: størrelse, weight: vekt ?? .regular, design: design ?? .default))
        }
    }
}

private struct PresentasjonsRot: ViewModifier {
    let på: Bool

    func body(content: Content) -> some View {
        if !på {
            content
        } else {
            #if os(macOS)
            content
                .environment(\.presentasjonsmodus, true)
                .environment(\.presentasjonsløft, Presentasjonsmodus.løft)
                .font(.system(size: (Presentasjonsmodus.basestørrelser[.body] ?? 13) + Presentasjonsmodus.løft))
                .controlSize(.large)
            #else
            content
                .environment(\.presentasjonsmodus, true)
                .dynamicTypeSize(DynamicTypeSize.xxxLarge ... DynamicTypeSize.accessibility5)
            #endif
        }
    }
}

extension View {
    /// Font som følger presentasjonsmodus på Mac (på iPhone og iPad gjør dynamisk tekst det samme). Utenfor
    /// presentasjonsmodus er den lik `.font(.system(stil, design:, weight:))`.
    func koloristFont(_ stil: Font.TextStyle, weight vekt: Font.Weight? = nil, design: Font.Design? = nil) -> some View {
        modifier(KoloristFont(stil: stil, vekt: vekt, design: design))
    }

    /// Settes én gang, på vindusroten.
    func presentasjonsmodus(_ på: Bool) -> some View {
        modifier(PresentasjonsRot(på: på))
    }
}
