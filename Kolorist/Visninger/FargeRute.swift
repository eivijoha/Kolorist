import FargeKjerne
import SwiftData
import SwiftUI

/// Hvor en farge hører hjemme. Bestemmer lagringsvalgene i fargemenyen, så samme slags farge får de samme valgene
/// overalt (se `Fargemeny`).
enum Fargeplass {
    /// Ikke lagret (harmoni, overgang, kamera, bilde, lys …): «Lagre som enkeltfarge» og «Legg i palett …».
    case løs
    /// Lagret som enkeltfarge: «Legg i palett …».
    case enkeltfarge
    /// I en palett: «Flytt til».
    case palett(PalettDokument)
    /// Lagret et annet sted og bare vist her (f.eks. i en fargevelger): ingen lagringsvalg.
    case lagret
}

/// Fargeprøve som kan kopieres, dras og deles. Brukes overalt der farger vises.
struct FargeRute: View {
    let farge: Farge
    var navn: String? = nil
    var visTekst = true
    var hjørne: CGFloat = 12
    /// Rette hjørner nederst (når ruten sitter oppå et felt, som i Studio).
    var retteBunnhjørner = false
    /// Ekstra innrykk for P3-merket (store flater, som i Studio).
    var ekstraMerkeInnrykk: CGFloat = 0
    /// Vis «P3»-merket for farger utenfor sRGB.
    var visMerke = true
    /// Skriftfargen på fargen (fra paletten, fra 1.3). `nil` = sort eller hvit etter lesbarhet.
    var tekstfarge: Farge? = nil
    /// Hvor godt skriftfargen holder (vises som et lite «Aa»-merke når paletten har skriftfarger).
    var skriftvurdering: Skriftfarger.Vurdering? = nil
    /// Hvor fargen hører hjemme; gir lagringsvalgene i menyen (se `Fargemeny`).
    var plass: Fargeplass = .løs
    /// Egne lagringshandlinger i stedet for standarden for `plass` (f.eks. når fargen skal begrenses først).
    var lagre: ((Farge) -> Void)? = nil
    var leggIPalett: ((Farge) -> Void)? = nil
    /// «Vis farge»: åpner fargen i Studio (Farge). Standard er å vise nettopp denne fargen; sett en egen handling når
    /// prøven viser en annen tone enn fargen den står for (f.eks. nærmeste tone i et fargekart).
    var åpneIStudio: ((Farge) -> Void)? = nil
    /// Med «Vis farge» i menyen (ikke for Studios egen fargeflate).
    var visFarge = true
    var fjern: (() -> Void)? = nil
    var navngi: (() -> Void)? = nil
    /// «Endre i Studio …»: fargen endres i et Studio-ark og gis tilbake hit (f.eks. en farge i en palett).
    var endre: ((Farge) -> Void)? = nil
    /// Tittelen på Studio-arket (standard fargens navn eller hex).
    var endreTittel: String? = nil
    /// Når satt, dras fargen med navn (mellom paletter); ellers som ren farge.
    var palettFarge: PalettFarge? = nil
    /// «Kopier verdier»: teksten som vises på prøven (f.eks. verdiene i Studio og harmonien).
    var kopierVerdier: String? = nil
    /// Valg som bare gjelder her (f.eks. «Lag toneskala»), etter Vis/Endre/Gi navn.
    var ekstraMeny: AnyView? = nil
    /// «Vis i 3D …», sist i menyen (før sletting).
    var vis3D: (() -> Void)? = nil

    /// Valgene vises i en boble ved prøven (trykk og hold) i stedet for som kontekstmeny.
    /// Brukes i lister/skjemaer: der gjelder iOS' kontekstmeny hele raden, så menyen og
    /// forhåndsvisningen kan høre til feil prøve når flere står på samme rad.
    var valgBoble = false
    /// Ekstra valg nederst i boblen (får en funksjon som lukker boblen). På Mac brukes `ekstraMeny` i stedet.
    var bobleEkstra: ((@escaping () -> Void) -> AnyView)? = nil

    var body: some View {
        #if os(macOS)
        // På Mac kan alle prøver dras (til paletter, fargebrønner og andre apper), og valgene ligger i
        // høyreklikkmenyen – der gjelder menyen bare prøven, ikke hele raden som på iOS.
        let boble = false
        #else
        let boble = valgBoble
        #endif
        let medMeny = rute.modifier(meny(boble: boble))
        if boble {
            medMeny
        } else {
            #if os(macOS)
            medMeny.onDrag { dragLeverandør(farge: farge, palettFarge: palettFarge) } preview: {
                FargeRute(farge: farge, visTekst: false, hjørne: 8).frame(width: 56, height: 56)
            }
            #else
            if let palettFarge {
                medMeny.draggable(palettFarge) { FargeRute(farge: farge, visTekst: false, hjørne: 8).frame(width: 56, height: 56) }
            } else {
                medMeny.draggable(farge)
            }
            #endif
        }
    }

    private func meny(boble: Bool) -> Fargemeny {
        Fargemeny(farge: farge, navn: navn, palettFarge: palettFarge, plass: plass, lagre: lagre, leggIPalett: leggIPalett,
                  åpneIStudio: visFarge ? (åpneIStudio ?? { Arbeidsbenk.delt.visIStudio($0) }) : nil,
                  endre: endre, endreTittel: endreTittel, navngi: navngi, fjern: fjern, kopierVerdier: kopierVerdier,
                  ekstraMeny: ekstraMeny, vis3D: vis3D, boble: boble, bobleEkstra: bobleEkstra)
    }

    private var form: UnevenRoundedRectangle {
        let bunn = retteBunnhjørner ? 0 : hjørne
        return UnevenRoundedRectangle(topLeadingRadius: hjørne, bottomLeadingRadius: bunn,
                                      bottomTrailingRadius: bunn, topTrailingRadius: hjørne, style: .continuous)
    }

    private var rute: some View {
        form
            .fill(farge.swiftUI)
            .overlay(alignment: .bottomLeading) {
                if visTekst {
                    VStack(alignment: .leading, spacing: 0) {
                        if let navn, !navn.isEmpty { Text(navn).font(.caption.weight(.semibold)) }
                        if let rep = palettFarge?.representasjon {
                            Text(rep.romnavn).font(.caption2.weight(.medium)).lineLimit(1)
                            Text(rep.tekst).font(.caption2.monospaced()).lineLimit(1).minimumScaleFactor(0.6)
                        }
                        Text(farge.hex()).font(.caption2.monospaced())
                    }
                    .foregroundStyle((tekstfarge ?? farge.lesbarTekstfarge).swiftUI)
                    .padding(8)
                }
            }
            .overlay(alignment: .topLeading) {
                if let skriftvurdering, let tekstfarge {
                    // «Aa» i skriftfargen: hake når den holder for all tekst (4,5:1), ellers kontrastforholdet.
                    HStack(spacing: 3) {
                        Text("Aa").font(.caption.weight(.semibold))
                        if skriftvurdering == .tekst {
                            Image(systemName: "checkmark").font(.caption2.weight(.bold))
                        } else {
                            Text(Kontrasttest(forgrunn: tekstfarge, bakgrunn: farge).formatert)
                                .font(.caption2.weight(.semibold).monospacedDigit())
                        }
                    }
                    .foregroundStyle(tekstfarge.swiftUI)
                    .padding(min(hjørne * 0.3 + 4, 6) + ekstraMerkeInnrykk)
                }
            }
            .overlay(alignment: .topTrailing) {
                if visMerke && !farge.erISRGB {
                    // Varseltrekant: fargen ligger utenfor sRGB og vises ulikt på vanlige skjermer.
                    // Ikon og tekst når det er plass, bare ikonet på små prøver.
                    ViewThatFits(in: .horizontal) {
                        Label("P3", systemImage: "exclamationmark.triangle.fill").labelStyle(.titleAndIcon)
                        Image(systemName: "exclamationmark.triangle.fill")
                    }
                        .font(.caption2.weight(.bold))
                        .imageScale(.small)
                        // Innrykket følger hjørneradiusen, så merket ikke klippes av det avrundede hjørnet.
                        .padding(min(hjørne * 0.3 + 4, 6) + ekstraMerkeInnrykk)
                        .foregroundStyle(farge.lesbarTekstfarge.swiftUI)
                        .accessibilityLabel("Utenfor sRGB")
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(navn.flatMap { $0.isEmpty ? nil : $0 } ?? farge.hex())
            .accessibilityValue(Fargemodell.okLCH.tekst(for: farge) + (skriftvurdering.map { v in
                ". " + (v == .tekst ? String(localized: "Skriftfargen holder for all tekst")
                        : v == .storTekst ? String(localized: "Skriftfargen holder bare for stor tekst")
                        : String(localized: "Skriftfargen har for lav kontrast"))
            } ?? ""))
    }
}

/// Lenke til kilden for en farge fra et innebygd bibliotek (f.eks. prøven hos FilamentColors.xyz), i menyen på
/// fargen. Vises ikke når kilden ikke har noen lenke.
struct Kildelenke: View {
    let kilde: Fargekilde

    var body: some View {
        if let lenke = kilde.lenke {
            Link(destination: lenke) {
                Label(kilde.kildenavn.map { String(localized: "Se fargen hos \($0)") } ?? String(localized: "Se kilden"),
                      systemImage: "arrow.up.right.square")
            }
        }
    }
}

/// Lenkene til kildene for farger som har en (f.eks. filamentprøvene hos FilamentColors.xyz), samme valg for én farge og
/// for mange: én farge gir lenken rett i menyen, flere gir en undermeny med én lenke per farge. Vises ikke når ingen av
/// fargene har en lenke.
struct KildeMeny: View {
    let farger: [PalettFarge]

    var body: some View {
        let medLenke = farger.filter { $0.kilde?.lenke != nil }
        if medLenke.count == 1, let kilde = medLenke.first?.kilde {
            Kildelenke(kilde: kilde)
        } else if medLenke.count > 1 {
            let kildenavn = Set(medLenke.compactMap { $0.kilde?.kildenavn })
            Menu {
                ForEach(medLenke) { pf in
                    if let k = pf.kilde, let lenke = k.lenke {
                        Link(destination: lenke) { Text(Self.navn(pf)) }
                    }
                }
            } label: {
                Label(kildenavn.count == 1 ? String(localized: "Se fargene hos \(kildenavn.first!)") : String(localized: "Se fargene hos kildene"),
                      systemImage: "arrow.up.right.square")
            }
        }
    }

    /// «Produsent – navn», ellers fargens navn eller hex.
    private static func navn(_ pf: PalettFarge) -> String {
        if let k = pf.kilde, let navn = k.navn {
            return [k.produsent, navn].compactMap { $0 }.joined(separator: " – ")
        }
        return pf.navn.isEmpty ? pf.farge.hex() : pf.navn
    }
}

/// «Kopier som …»-meny, felles for kontekstmenyer og verktøylinjer.
struct KopierMeny: View {
    let farge: Farge

    var body: some View {
        Button("Kopier hex", systemImage: "doc.on.doc") { Utklippstavle.kopier(farge) }
        Menu("Kopier som") {
            ForEach(Fargemodell.allCases) { modell in
                Button(modell.tekst(for: farge)) { Utklippstavle.kopier(farge, som: modell) }
            }
        }
        ShareLink(item: farge, preview: SharePreview(farge.hex()))
    }
}

/// Valg for én fargeprøve, vist i en boble ved prøven: stor forhåndsvisning av nøyaktig
/// den trykkede fargen, og lagring/kopiering.
struct FargeValgBoble: View {
    let farge: Farge
    var navn: String = ""
    /// Fargen med navn og kilde (f.eks. en filamentprøve), til «Del som lenke».
    var palettFarge: PalettFarge? = nil
    var lagre: ((Farge) -> Void)?
    var leggIPalett: ((Farge) -> Void)?
    var åpneIStudio: ((Farge) -> Void)? = nil
    /// Kilden til fargen (f.eks. filamentprøven): lenke til den.
    var kilde: Fargekilde? = nil
    /// Ekstra valg nederst (f.eks. for hele settet fargen hører til).
    var ekstra: AnyView? = nil
    var lukk: () -> Void
    @State private var lagret = false
    @AppStorage(Kopiinnstillinger.rekkefølgeNøkkel) private var rekkefølge = ""
    @AppStorage(Kopiinnstillinger.skjultNøkkel) private var skjult = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(farge.swiftUI)
                .frame(width: 220, height: 96)
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(farge.hex()).font(.callout.monospaced().weight(.semibold))
                        Text(Fargemodell.okLCH.tekst(for: farge)).font(.caption2.monospaced())
                    }
                    .foregroundStyle(farge.lesbarTekstfarge.swiftUI)
                    .padding(10)
                }
            VStack(alignment: .leading, spacing: 4) {
                if let åpneIStudio {
                    Button("Vis farge", systemImage: "slider.horizontal.3") {
                        lukk()
                        åpneIStudio(farge)
                    }
                }
                if let lagre {
                    Button(lagret ? "Lagret" : "Lagre som enkeltfarge", systemImage: lagret ? "checkmark.square.fill" : "plus.square") {
                        lagre(farge)
                        lagret = true
                        // Lukk før navnearket for den nye fargen vises.
                        Task { try? await Task.sleep(for: .seconds(0.4)); lukk() }
                    }
                    .disabled(lagret)
                    .sensoryFeedback(.success, trigger: lagret) { _, ny in ny }
                }
                if let leggIPalett {
                    Button("Legg i palett …", systemImage: "plus.square.on.square") {
                        lukk()
                        leggIPalett(farge)
                    }
                }
                // «Kopier til …»: formatet målprogrammet tar imot (også via universell utklippstavle).
                Menu {
                    ForEach(Kopiinnstillinger.synlige(Kopimål.tilgjengelige.map(\.rawValue), rekkefølge: rekkefølge, skjult: skjult)
                        .compactMap(Kopimål.init(rawValue:))) { mål in
                        Button {
                            Utklippstavle.kopier([PalettFarge(farge: farge)], navn: "", til: mål)
                            lukk()
                        } label: {
                            Label { Text(mål.navn); Text(mål.forklaring) } icon: { Image(systemName: mål.symbol) }
                        }
                    }
                    Button("Tilpass listen …", systemImage: "slider.horizontal.3") {
                        lukk()
                        Kopitilpasning.delt.vises = true
                    }
                } label: {
                    Label("Kopier til", systemImage: "arrow.up.doc.on.clipboard")
                }
                let pf = palettFarge ?? PalettFarge(navn: navn, farge: farge)
                DelSomLenke(navn: pf.navn.isEmpty ? farge.hex() : pf.navn) { Lenkedeling.farge(pf) }
                Button("Kopier hex", systemImage: "doc.on.doc") {
                    Utklippstavle.kopier(farge)
                    lukk()
                }
                if let kilde { Kildelenke(kilde: kilde) }
                if let ekstra {
                    Divider()
                    ekstra
                }
            }
            // .plain, ikke .borderless: .borderless toner hele etiketten (også teksten) i aksentfarge.
            .buttonStyle(.plain)
            .menuStyle(.button)
            .labelStyle(Handlingsetikett())
        }
        .padding(16)
        // Boblen skal få hele høyden innholdet trenger (ellers klippes de nederste valgene).
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// Etikett med fast ikonbredde, så teksten i en knappeliste står på linje.
/// Handlinger i bobler og halvhøye ark (glassbakgrunn): ikonet i aksentfarge, teksten i vanlig tekstfarge – blå tekst
/// leses dårlig på glass.
struct Handlingsetikett: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 10) {
            configuration.icon.frame(width: 24).foregroundStyle(.tint)
            // Color.primary, ikke .primary: i knapper i et skjema er .primary knappens aksentfarge.
            configuration.title.foregroundStyle(Color.primary)
        }
        .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
        .contentShape(Rectangle())
    }
}
