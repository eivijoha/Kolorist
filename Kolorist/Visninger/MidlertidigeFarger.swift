import FargeKjerne
import SwiftData
import SwiftUI

/// Farger plukket fra kamera, bilder og skjermen som ikke er lagret ennå. Vises øverst i Paletter og
/// palettkolonnen, tydelig merket som ulagret: de forsvinner når appen lukkes.
/// Valgene for plukkede farger: lagre alle som enkeltfarger, eller tøm.
struct PlukkedeFargerValg: View {
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @Environment(\.modelContext) private var kontekst
    @State private var somPalett: [PalettFarge]?

    var body: some View {
        Menu {
            Button("Legg alle i ny palett …", systemImage: "swatchpalette") {
                somPalett = arbeidsbenk.målinger.reversed().map { PalettFarge(farge: $0, opphav: .kamera) }
            }
            Button("Lagre alle som enkeltfarger", systemImage: "square.and.arrow.down") {
                let farger = arbeidsbenk.målinger.reversed().map { PalettFarge(farge: $0, opphav: .kamera) }
                lagreEnkeltfarger(farger, i: kontekst, navngi: false)
                arbeidsbenk.tømMålinger()
            }
            Button("Tøm", systemImage: "trash", role: .destructive) { arbeidsbenk.tømMålinger() }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .menuIndicator(.hidden)
        .fixedSize()
        .accessibilityLabel("Valg for plukkede farger")
        // Arket henger på menyen, ikke på menyvalget (iOS viser ikke ark fra et menyvalg som lukkes).
        // Når fargene er lagt i en palett, tømmes listen, som ved «Lagre alle som enkeltfarger».
        .sheet(isPresented: Binding(get: { somPalett != nil }, set: { if !$0 { somPalett = nil } })) {
            VelgPalettArk(farger: somPalett ?? [], foreslåttNavn: String(localized: "Plukkede farger"),
                          tilbyEnkeltfarger: false, nyPalett: true, lagret: { arbeidsbenk.tømMålinger() })
        }
    }
}

struct MidlertidigeFarger: View {
    /// Kompakt utgave til palettkolonnen (rutenett i stedet for rad).
    var kompakt = false
    /// Uten egen overskrift (i Paletter står tittel og valg i seksjonsoverskriften).
    var medTittel = true
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @Environment(\.modelContext) private var kontekst

    private var farger: [PalettFarge] {
        arbeidsbenk.målinger.reversed().map { PalettFarge(farge: $0, opphav: .kamera) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if medTittel {
                HStack(spacing: 8) {
                    Label("Plukkede farger", systemImage: "eyedropper.halffull").font(kompakt ? .subheadline.weight(.semibold) : .headline)
                    IkkeLagretMerke()
                    Spacer()
                    PlukkedeFargerValg()
                }
            }
            Group {
                if kompakt {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 34, maximum: 48), spacing: 4)], alignment: .leading, spacing: 4) { ruter }
                } else {
                    ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 4) { ruter } }
                }
            }
            Text("Fra kamera, bilder og skjermpipetten. Forsvinner når appen lukkes – dra en farge til en palett, eller lagre dem.")
                .font(.caption)
                .foregroundStyle(Color.sekundærTekst)
        }
    }

    @ViewBuilder private var ruter: some View {
        ForEach(farger) { pf in
            FargeRute(farge: pf.farge, visTekst: false, hjørne: 6,
                      lagre: { lagreEnkeltfarger([PalettFarge(farge: $0, opphav: .kamera)], i: kontekst) },
                      palettFarge: pf)
                .frame(width: kompakt ? nil : 36, height: kompakt ? nil : 36)
                .aspectRatio(1, contentMode: .fit)
                // Stiplet kant viser at fargen ikke er lagret.
                .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.sekundærTekst.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [3, 2])))
                .onTapGesture { arbeidsbenk.aktivFarge = pf.farge }
                .help(String(localized: "\(pf.farge.hex()) – ikke lagret"))
                .accessibilityLabel(String(localized: "\(pf.farge.hex()), ikke lagret"))
                .accessibilityAction(named: "Gjør til aktiv farge") { arbeidsbenk.aktivFarge = pf.farge }
        }
    }
}

/// Blå merkelapp «Ikke lagret» for plukkede farger.
struct IkkeLagretMerke: View {
    var body: some View {
        Text("Ikke lagret")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .foregroundStyle(Color.blue)
            .background(Color.blue.opacity(0.12), in: Capsule())
    }
}

/// De plukkede fargene som en vannrett rad under kamera og bilde – de samme som «Plukkede farger» i
/// Paletter (nyeste først). Trykk gjør fargen aktiv; menyen kan lagre, legge i palett eller fjerne den.
struct PlukkedeFargerRad: View {
    let opphav: PalettFarge.Opphav
    var størrelse: CGFloat = 36
    var leggIPalett: (Farge) -> Void
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @Environment(\.modelContext) private var kontekst

    private func visIStudio(_ farge: Farge) {
        arbeidsbenk.visIStudio(farge)
    }

    var body: some View {
        let målinger = arbeidsbenk.målinger
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(målinger.indices.reversed()), id: \.self) { i in
                    let farge = målinger[i]
                    FargeRute(farge: farge, visTekst: false, hjørne: 6,
                              lagre: { lagreEnkeltfarger([PalettFarge(farge: $0, opphav: opphav)], i: kontekst) },
                              leggIPalett: leggIPalett,
                              fjern: { arbeidsbenk.fjernMåling(i) },
                              palettFarge: PalettFarge(farge: farge, opphav: opphav))
                        .frame(width: størrelse, height: størrelse)
                        .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.sekundærTekst.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [3, 2])))
                        // Trykk tar den fangede fargen rett til Studio.
                        .onTapGesture { visIStudio(farge) }
                        .accessibilityAction(named: "Vis i Studio") { visIStudio(farge) }
                        .help(String(localized: "\(farge.hex()) – ikke lagret. Klikk for å vise den i Studio."))
                }
            }
        }
    }
}
