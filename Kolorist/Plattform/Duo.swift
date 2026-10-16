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
    /// iPhone Duo lukket: fargelinjen står til venstre, og fanene har bare inndataene øverst (se `Kortoppsett`).
    @Entry var duoLukket = false
    /// iPhone Duo åpen (delvis eller helt): brettelinjen i vinduets koordinater. Faner med eget fargekort
    /// (`Kortoppsett`) legger kortet til venstre for den.
    @Entry var duoDeling: CGRect? = nil
}

extension View {
    /// Fargene fanen viser i de store fargeprøvene – på iPhone Duo vises de i fargelinjen (lukket) og i venstre
    /// halvdel (åpen). Ellers uten virkning.
    /// `ramme`: streken rundt fargefeltet (Overgang), som da også går rundt fargelinjen.
    func duofarger(_ farger: [Duofarge], fane: Arbeidsbenk.Fane, ramme: Color? = nil) -> some View {
        modifier(DuofargeRapport(farger: farger, fane: fane, ramme: ramme))
    }

    /// Fargeområdet i et kort (`Kortoppsett`): på åpen iPhone Duo fortsetter fargene herfra 20 pt over brettelinjen,
    /// i samme høyde som området.
    func duokant() -> some View {
        anchorPreference(key: DuokantNøkkel.self, value: .bounds) { $0 }
    }

    /// Rammen rundt appen på iPhone Duo: lukket en fargelinje på 20 pt langs venstre kant, åpen fargeprøvene i venstre
    /// halvdel og 20 pt inn på høyre, der appen står som på andre iPhoner.
    func duoramme() -> some View {
        modifier(Duoramme())
    }
}

private struct DuokantNøkkel: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) { value = value ?? nextValue() }
}

private struct DuofargeRapport: ViewModifier {
    let farger: [Duofarge]
    let fane: Arbeidsbenk.Fane
    let ramme: Color?
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @Environment(\.duo) private var duo

    private func meld() {
        if arbeidsbenk.duofarger[fane] != farger { arbeidsbenk.duofarger[fane] = farger }
        if arbeidsbenk.duorammer[fane] != ramme { arbeidsbenk.duorammer[fane] = ramme }
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: farger, initial: true) { if duo { meld() } }
            .onChange(of: ramme) { if duo { meld() } }
            .onChange(of: duo) { if duo { meld() } }
            // Tilbake til visningen (fane eller navigasjon): fargene igjen. Borte: panelet viser aktiv farge.
            .onAppear { if duo { meld() } }
            .onDisappear {
                if duo, arbeidsbenk.duofarger[fane] == farger {
                    arbeidsbenk.duofarger[fane] = nil
                    arbeidsbenk.duorammer[fane] = nil
                }
            }
    }
}

struct Duoramme: ViewModifier {
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
                // Fanen har eget fargekort (Kortoppsett): kortet står selv til venstre, og appen får hele vinduet.
                let egetKort = arbeidsbenk.duoEgetKort[arbeidsbenk.valgtFane, default: 0] > 0
                let global = geo.frame(in: .global).origin
                HStack(spacing: 0) {
                    if let deling, !egetKort {
                        Duoflater(farger: farger)
                            .frame(width: max(deling.minX, 0))
                        Fargelinje(farger: farger)
                            .frame(width: deling.width + Self.linje)
                    } else if lukket == true {
                        Fargelinje(farger: farger, ramme: arbeidsbenk.duorammer[arbeidsbenk.valgtFane] ?? nil)
                            .frame(width: Self.linje)
                    }
                    // Appen står alltid sist, så den beholder tilstanden når telefonen åpnes og lukkes.
                    // Smal bredde som på andre iPhoner (vinduet er bredt når telefonen er åpen, men appen har én halvdel).
                    content
                        .environment(\.duo, duo)
                        .environment(\.duoLukket, lukket == true)
                        // Bare når fanen selv strekker seg over brettelinjen (eget kort); ellers står den i høyre halvdel.
                        .environment(\.duoDeling, egetKort ? deling.map { $0.offsetBy(dx: global.x, dy: global.y) } : nil)
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

/// Felles oppsett for faner med et fargekort og et skjema (Studio, Overgang, Vurdering):
/// - smalt (iPhone): kortet øverst og skjemaet under; bredt (iPad, Mac): kortet i venstre halvdel og skjemaet til høyre
/// - iPhone Duo åpen: kortet til venstre for brettelinjen, fargene 20 pt inn på høyre halvdel, skjemaet til høyre
/// - iPhone Duo lukket: bare `topp` (inndataene) over skjemaet – fargene står i fargelinjen langs venstre kant
struct Kortoppsett<Kort: View, Topp: View, Skjema: View>: View {
    /// Fanen kortet hører til (`nil` i ark, f.eks. Studio for én farge).
    let fane: Arbeidsbenk.Fane?
    /// Fargene i kortet – fargelinjen (lukket) og de 20 pt over brettelinjen (åpen).
    let farger: [Duofarge]
    /// Fargene langs kortets høyre kant, som fortsetter over brettelinjen (åpen) – når de ikke er `farger` over hverandre
    /// (f.eks. B til høyre i ΔE).
    var kant: [Duofarge]? = nil
    /// Streken rundt fargefeltet (Overgang): åpen går den rundt kortets fargeområde og fargene over brettelinjen samlet
    /// (kortet tegner da ikke sin egen), lukket rundt fargelinjen.
    var ramme: Color? = nil
    @ViewBuilder let kort: (_ bred: Bool) -> Kort
    @ViewBuilder let topp: () -> Topp
    @ViewBuilder let skjema: () -> Skjema
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @Environment(\.duoLukket) private var lukket
    @Environment(\.duoDeling) private var deling

    var body: some View {
        GeometryReader { geo in
            let felt = geo.frame(in: .global)
            // Åpen: bare når visningen strekker seg over brettelinjen (hele vinduet).
            let delt = deling.flatMap { d in d.minX > felt.minX && d.maxX < felt.maxX ? d : nil }
            let bred = delt != nil || (!lukket && Breddeoppsett.erBred(geo.size))
            // AnyLayout bevarer skjemaets tilstand (rulleposisjon, glidere) når enheten roteres eller brettes.
            let oppsett = bred ? AnyLayout(HStackLayout(spacing: 0)) : AnyLayout(VStackLayout(spacing: 0))
            oppsett {
                if lukket {
                    topp()
                } else {
                    kort(bred)
                        .frame(width: bred ? (delt.map { $0.minX - felt.minX } ?? geo.size.width / 2) : nil)
                }
                if let delt {
                    // Plassen for fargene over brettelinjen; selve fargene tegnes i høyde med fargeområdet (under).
                    Color.clear.frame(width: delt.width + Duoramme.linje)
                }
                // Bredt: luft mellom fargene og boksene i skjemaet (som når skjemaet står alene), ikke kant i kant.
                skjema()
                    .safeAreaPadding(.leading, bred ? 16 : 0)
            }
            .overlayPreferenceValue(DuokantNøkkel.self) { anker in
                if let delt, !lukket, let anker {
                    GeometryReader { p in
                        let r = p[anker]
                        let bredde = delt.width + Duoramme.linje
                        Fargelinje(farger: kant ?? farger)
                            .frame(width: bredde, height: r.height)
                            .position(x: r.maxX + bredde / 2, y: r.midY)
                        if let ramme {
                            UnevenRoundedRectangle(topLeadingRadius: 20, style: .continuous)
                                .strokeBorder(ramme, lineWidth: 3)
                                .frame(width: r.width + bredde, height: r.height)
                                .position(x: r.minX + (r.width + bredde) / 2, y: r.midY)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
        }
        .duofarger(fane == nil ? [] : farger, fane: fane ?? .studio, ramme: ramme)
        .onAppear { if let fane { arbeidsbenk.duoEgetKort[fane, default: 0] += 1 } }
        .onDisappear { if let fane { arbeidsbenk.duoEgetKort[fane, default: 1] -= 1 } }
    }
}

/// Fargelinjen: fargene over hverandre i like store felt, uten tekst – med streken rundt når fanen har en (Overgang).
private struct Fargelinje: View {
    let farger: [Duofarge]
    var ramme: Color? = nil

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(farger.enumerated()), id: \.offset) { _, f in
                Rectangle().fill(f.farge.swiftUI)
            }
        }
        .overlay { if let ramme { Rectangle().strokeBorder(ramme, lineWidth: 3) } }
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

/// Et fargevalg som liten brikke (lukket iPhone Duo): prøven, tittelen og hex-verdien, med samme meny som feltet i
/// kortet (lagrede farger, utplukk, Studio).
struct Fargevalgbrikke: View {
    let tittel: String
    @Binding var farge: Farge
    var visAktivFarge = true
    var visHvitOgSort = false

    var body: some View {
        FargeVelgerMeny(tittel: tittel, farge: $farge, visAktivFarge: visAktivFarge, visHvitOgSort: visHvitOgSort) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(farge.swiftUI)
                    .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(.primary.opacity(0.2)))
                    .frame(width: 28, height: 28)
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: tittel).font(.caption).foregroundStyle(Color.sekundærTekst)
                    Text(verbatim: farge.hex()).font(.subheadline.monospaced())
                }
                .lineLimit(1)
                Image(systemName: "chevron.up.chevron.down").font(.caption2).foregroundStyle(Color.sekundærTekst)
            }
            .contentShape(Rectangle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
