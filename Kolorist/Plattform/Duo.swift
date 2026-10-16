import FargeKjerne
import SwiftUI

/// En farge i panelet på iPhone Duo, med navnet den har (palettfarger) eller uten.
struct Duofarge: Equatable {
    let farge: Farge
    var navn: String = ""
}

extension EnvironmentValues {
    /// iPhone Duo (lukket eller åpen): de store fargeprøvene står i fargelinjen eller i venstre halvdel, ikke i fanen.
    @Entry var duo = false
}

extension View {
    /// Fargene fanen viser i de store fargeprøvene – på iPhone Duo vises de i fargelinjen (lukket) og i venstre
    /// halvdel (åpen). Ellers uten virkning.
    func duofarger(_ farger: [Duofarge], fane: Arbeidsbenk.Fane) -> some View {
        modifier(DuofargeRapport(farger: farger, fane: fane))
    }

    /// Rammen rundt appen på iPhone Duo: lukket en fargelinje på 20 pt langs venstre kant, åpen fargeprøvene i venstre
    /// halvdel og 20 pt inn på høyre, der appen står som på andre iPhoner.
    func duoramme() -> some View {
        modifier(Duoramme())
    }
}

private struct DuofargeRapport: ViewModifier {
    let farger: [Duofarge]
    let fane: Arbeidsbenk.Fane
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @Environment(\.duo) private var duo

    func body(content: Content) -> some View {
        content
            .onChange(of: farger, initial: true) {
                if duo, arbeidsbenk.duofarger[fane] != farger { arbeidsbenk.duofarger[fane] = farger }
            }
            .onChange(of: duo) {
                if duo { arbeidsbenk.duofarger[fane] = farger }
            }
            // Tilbake til visningen (fane eller navigasjon): fargene igjen. Borte: panelet viser aktiv farge.
            .onAppear { if duo { arbeidsbenk.duofarger[fane] = farger } }
            .onDisappear { if duo, arbeidsbenk.duofarger[fane] == farger { arbeidsbenk.duofarger[fane] = nil } }
    }
}

private struct Duoramme: ViewModifier {
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @Environment(\.horizontalSizeClass) private var breddeklasse
    /// Hengselen: `nil` uten hengsel (andre enheter), ellers lukket eller åpen (delvis og helt åpen likt).
    @State private var lukket: Bool?

    /// Bredden på fargelinjen (lukket) – og hvor langt fargeprøvene går inn på høyre halvdel (åpen).
    static let linje: CGFloat = 20

    private var farger: [Duofarge] {
        let f = arbeidsbenk.duofarger[arbeidsbenk.valgtFane] ?? []
        return f.isEmpty ? [Duofarge(farge: arbeidsbenk.aktivFarge)] : f
    }

    func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 27.1, *) {
            GeometryReader { geo in
                // Åpen (delvis eller helt) og liggende: delt ved brettelinjen – også når den ikke er aktiv (delvis
                // åpen) – eller midt på skjermen om systemet ikke oppgir den.
                let åpen = lukket == false && geo.size.width > geo.size.height
                let deling: CGRect? = åpen ? (geo.reservedRegions(kind: .division, options: .includeInactive)
                    .first { $0.frame.height > $0.frame.width }
                    .map { $0.frame.inset(by: UIEdgeInsets(top: $0.margins.top, left: $0.margins.leading,
                                                          bottom: $0.margins.bottom, right: $0.margins.trailing)) }
                    ?? CGRect(x: geo.size.width / 2, y: 0, width: 0, height: geo.size.height)) : nil
                let duo = deling != nil || lukket == true
                HStack(spacing: 0) {
                    if let deling {
                        Duoflater(farger: farger)
                            .frame(width: max(deling.minX, 0))
                        Fargelinje(farger: farger)
                            .frame(width: deling.width + Self.linje)
                    } else if lukket == true {
                        Fargelinje(farger: farger)
                            .frame(width: Self.linje)
                    }
                    // Appen står alltid sist, så den beholder tilstanden når telefonen åpnes og lukkes.
                    // Smal bredde som på andre iPhoner (vinduet er bredt når telefonen er åpen, men appen har én halvdel).
                    content
                        .environment(\.duo, duo)
                        .environment(\.horizontalSizeClass, duo ? .compact : breddeklasse)
                }
                .ignoresSafeArea(edges: duo ? .vertical : [])
            }
            .onHingeChange { _, ny in lukket = ny.hinge.map { $0.status == .closed } }
        } else {
            content
        }
        #else
        content
        #endif
    }
}

/// Fargelinjen: fargene over hverandre i like store felt, uten tekst.
private struct Fargelinje: View {
    let farger: [Duofarge]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(farger.enumerated()), id: \.offset) { _, f in
                Rectangle().fill(f.farge.swiftUI)
            }
        }
        .accessibilityHidden(true)
    }
}

/// Fargeprøvene i venstre halvdel (åpen iPhone Duo): fargene over hverandre, med navn og fargekoder.
private struct Duoflater: View {
    let farger: [Duofarge]
    @Environment(Arbeidsbenk.self) private var arbeidsbenk

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(farger.enumerated()), id: \.offset) { _, f in
                let tekst = f.farge.lesbarTekstfarge.swiftUI
                Rectangle()
                    .fill(f.farge.swiftUI)
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 2) {
                            if !f.navn.isEmpty {
                                Text(verbatim: f.navn).font(.headline)
                            }
                            Text(verbatim: f.farge.hex()).font(.subheadline.monospaced())
                            Text(verbatim: arbeidsbenk.modell.tekst(for: f.farge)).font(.caption.monospaced())
                        }
                        .foregroundStyle(tekst)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 20)
                        .padding(.vertical, farger.count > 6 ? 4 : 12)
                    }
                    .accessibilityElement(children: .combine)
            }
        }
    }
}
