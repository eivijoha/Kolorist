import FargeKjerne
import SwiftUI

/// En farge i panelet på iPhone Duo, med navnet den har (palettfarger) eller uten.
struct Duofarge: Equatable {
    let farge: Farge
    var navn: String = ""
    /// Merket med ramme, som grunnfargen i en harmoni – rammen går da også rundt feltet i fargelinjen.
    var markert = false
}

extension EnvironmentValues {
    /// iPhone Duo (lukket eller åpen): de store fargeprøvene står i fargelinjen eller i venstre halvdel, ikke i fanen.
    @Entry var duo = false
    /// iPhone Duo lukket: fargelinjen står til venstre, og fanene har bare inndataene øverst (se `Kortoppsett`).
    @Entry var duoLukket = false
    /// iPhone Duo åpen (delvis eller helt): brettelinjen i vinduets koordinater. Faner med eget fargekort
    /// (`Kortoppsett`) legger kortet til venstre for den.
    @Entry var duoDeling: CGRect? = nil
    /// Hvor langt fargene i venstre halvdel har vokst ut fra brettelinjen når telefonen brettes ut (0…1).
    @Entry var duoUtfolding: CGFloat = 1
    /// Fanen 3D-visningen kan legges i venstre halvdel for (bredt oppsett med fargekort, eller åpen iPhone Duo);
    /// `nil`: ark (iPhone, iPad) eller eget vindu (Mac).
    @Entry var venstre3DFane: Arbeidsbenk.Fane? = nil

}

extension View {
    /// Venstre halvdel (åpen iPhone Duo) vokser ut fra brettelinjen når telefonen brettes ut (`duoUtfolding`).
    fileprivate func vokserFraBrettelinjen(_ utfolding: CGFloat) -> some View {
        mask(alignment: .trailing) {
            GeometryReader { geo in
                Rectangle().frame(width: geo.size.width * utfolding).frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
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

    /// Hele kortet (`Kortoppsett`): på åpen iPhone Duo fortsetter kortbakgrunnen 20 pt over brettelinjen, så raden under
    /// fargene ikke får et hakk.
    func duokortflate() -> some View {
        anchorPreference(key: DuokortNøkkel.self, value: .bounds) { $0 }
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

private struct DuokortNøkkel: PreferenceKey {
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
    /// Satt når telefonen nettopp er brettet ut, til venstre halvdel har vokst ut fra brettelinjen.
    @State private var utfoldes = false
    @State private var utfolding: CGFloat = 1

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
                        Group {
                            if let v = arbeidsbenk.venstre3D[arbeidsbenk.valgtFane] {
                                Venstre3D(v: v, fane: arbeidsbenk.valgtFane)
                            } else {
                                Duoflater(farger: farger)
                                    .ignoresSafeArea(edges: .vertical)
                            }
                        }
                        .vokserFraBrettelinjen(utfolding)
                        .frame(width: max(deling.minX, 0))
                        Fargelinje(farger: farger)
                            .frame(width: deling.width + Self.linje)
                            .ignoresSafeArea(edges: .vertical)
                    } else if lukket == true {
                        Fargelinje(farger: farger, ramme: arbeidsbenk.duorammer[arbeidsbenk.valgtFane] ?? nil)
                            .frame(width: Self.linje)
                            .ignoresSafeArea(edges: .vertical)
                    }
                    // Appen står alltid sist, så den beholder tilstanden når telefonen åpnes og lukkes.
                    // Smal bredde som på andre iPhoner (vinduet er bredt når telefonen er åpen, men appen har én halvdel).
                    content
                        .environment(\.duo, duo)
                        .environment(\.duoLukket, lukket == true)
                        // Bare når fanen selv strekker seg over brettelinjen (eget kort); ellers står den i høyre halvdel.
                        .environment(\.duoDeling, egetKort ? deling.map { $0.offsetBy(dx: global.x, dy: global.y) } : nil)
                        .environment(\.horizontalSizeClass, duo ? .compact : breddeklasse)
                        .environment(\.duoUtfolding, utfolding)
                        .environment(\.venstre3DFane, deling != nil && !egetKort ? arbeidsbenk.valgtFane : nil)

                }
                // Bare fargene (fargelinjen og fargeprøvene) går helt ut i kanten; appen holder seg innenfor den trygge
                // sonen, så toppen ikke blir trang mot de avrundede hjørnene.
                // Brettet ut: fargene vokser fra stripen ved brettelinjen og fyller venstre halvdel.
                .onChange(of: deling != nil, initial: true) { _, åpen in
                    if arbeidsbenk.duoÅpen != åpen { arbeidsbenk.duoÅpen = åpen }
                    guard åpen, utfoldes else { return }
                    utfoldes = false
                    utfolding = 0
                    withAnimation(.smooth(duration: 0.6)) { utfolding = 1 }
                }
            }
            .onHingeChange { gammel, ny in
                if gammel.hinge?.status == .closed, let s = ny.hinge?.status, s != .closed { utfoldes = true }
                lukket = ny.hinge.map { $0.status == .closed }
                // Lukket: 3D-visningen i venstre halvdel forsvinner (den åpnes som ark igjen ved behov).
                if lukket == true { arbeidsbenk.venstre3D = [:] }
            }
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
    /// Luft øverst på iPhone Duo (ingen trygg sone øverst: statuslinjen står loddrett til høyre).
    static var duoTopp: CGFloat { 12 }
    private static var erIPad: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .pad
        #else
        false
        #endif
    }
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
    /// Sidetittelen (stor tittel). Åpen iPhone Duo: navigasjonslinjen går over hele bredden, så den store tittelen ville
    /// lagt seg over kortet i venstre halvdel – den står i stedet øverst i skjemaet til høyre, og linjen skjules.
    var tittel: LocalizedStringKey? = nil
    @ViewBuilder let kort: (_ bred: Bool) -> Kort
    @ViewBuilder let topp: () -> Topp
    @ViewBuilder let skjema: () -> Skjema
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @Environment(\.duoLukket) private var lukket
    @Environment(\.duoDeling) private var deling
    @Environment(\.duoUtfolding) private var utfolding

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
                        .padding(.top, Self.duoTopp)
                } else if bred, let fane, let v = arbeidsbenk.venstre3D[fane] {
                    // 3D-visningen i stedet for kortet (bredt oppsett).
                    Venstre3D(v: v, fane: fane)
                        .padding(.top, delt == nil ? 0 : Self.duoTopp)
                        .frame(width: delt.map { $0.minX - felt.minX } ?? geo.size.width / 2)
                } else {
                    kort(bred)
                        .vokserFraBrettelinjen(delt == nil ? 1 : utfolding)
                        .frame(width: bred ? (delt.map { $0.minX - felt.minX } ?? geo.size.width / 2) : nil)
                        // Åpen iPhone Duo: kortet fyller hele høyden, med samme marg øverst, nederst og til venstre, så
                        // hjørnene følger skjermens.
                        // iPad liggende: ned til bunnen, så hjørnet nede til venstre følger skjermens (øverst står
                        // fanelinjen).
                        .ignoresSafeArea(edges: delt != nil ? .vertical : (bred && Self.erIPad ? .bottom : []))
                }
                if let delt {
                    // Plassen for fargene over brettelinjen; selve fargene tegnes i høyde med fargeområdet (under).
                    Color.clear.frame(width: delt.width + Duoramme.linje)
                }
                // Bredt: luft mellom fargene og boksene i skjemaet (som når skjemaet står alene), ikke kant i kant.
                // iPhone Duo: luft øverst – statuslinjen står loddrett til høyre, så toppen har ingen trygg sone mot
                // de avrundede hjørnene.
                skjema()
                    .safeAreaInset(edge: .top, spacing: 0) {
                        if delt != nil, let tittel {
                            Text(tittel)
                                .font(.largeTitle.bold())
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 8)
                                .background(Color.skjemabakgrunn)
                        }
                    }
                    .safeAreaPadding(.leading, bred ? 16 : 0)
                    .safeAreaPadding(.top, delt != nil || lukket ? Self.duoTopp : 0)
            }
            #if os(iOS)
            .toolbar(delt != nil && tittel != nil ? .hidden : .automatic, for: .navigationBar)
            #endif
            // Bredt oppsett: 3D kan legges i venstre halvdel. Smalt igjen: 3D-visningen der forsvinner.
            .environment(\.venstre3DFane, bred && !lukket ? fane : nil)
            .onChange(of: bred, initial: true) { _, ny in
                guard let fane else { return }
                if !ny { arbeidsbenk.venstre3D[fane] = nil }
                if ny != arbeidsbenk.bredeKort.contains(fane) {
                    if ny { arbeidsbenk.bredeKort.insert(fane) } else { arbeidsbenk.bredeKort.remove(fane) }
                }
            }
            // Åpen: kortbakgrunnen fortsetter over brettelinjen i hele kortets høyde (under fargene).
            .backgroundPreferenceValue(DuokortNøkkel.self) { anker in
                if let delt, !lukket, let anker {
                    GeometryReader { p in
                        let r = p[anker]
                        let bredde = delt.width + Duoramme.linje
                        Rectangle().fill(Color.kortbakgrunn)
                            .frame(width: bredde, height: r.height)
                            .position(x: r.maxX + bredde / 2, y: r.midY)
                    }
                }
            }
            .overlayPreferenceValue(DuokantNøkkel.self) { anker in
                if let delt, !lukket, let anker {
                    GeometryReader { p in
                        let r = p[anker]
                        let bredde = delt.width + Duoramme.linje
                        Fargelinje(farger: kant ?? farger, merk: false)
                            .frame(width: bredde, height: r.height)
                            .position(x: r.maxX + bredde / 2, y: r.midY)
                        // Merkede felt (grunnfargen): rammen rundt feltet i kortet og fargene over brettelinjen samlet.
                        let felter = kant ?? farger
                        let høyde = r.height / CGFloat(max(felter.count, 1))
                        ForEach(Array(felter.enumerated()), id: \.offset) { i, f in
                            if f.markert {
                                Kortform.kantstrek(ConcentricRectangle(topLeadingCorner: i == 0 ? Kortform.hjørne : .fixed(0),
                                                                       topTrailingCorner: .fixed(0), bottomLeadingCorner: .fixed(0),
                                                                       bottomTrailingCorner: .fixed(0)),
                                                   f.farge.lesbarTekstfarge.swiftUI)
                                    .frame(width: r.width + bredde, height: høyde)
                                    .position(x: r.minX + (r.width + bredde) / 2, y: r.minY + høyde * (CGFloat(i) + 0.5))
                                    .allowsHitTesting(false)
                            }
                        }
                        if let ramme {
                            Kortform.kantstrek(Kortform.toppflate(høyre: 0), ramme)
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

/// 3D-visningen i venstre halvdel (bredt oppsett), med «Ferdig» tilbake til fargene.
private struct Venstre3D: View {
    let v: Fargerom3DVindu
    let fane: Arbeidsbenk.Fane
    @Environment(Arbeidsbenk.self) private var arbeidsbenk

    var body: some View {
        // Uten `.id(kilde)`: levende 3D bygger modellen på nytt i samme visning, så dreiningen beholdes.
        Fargerom3DArk(kilde: v.kilde, gamut: v.gamut, startprofil: v.startprofil, ferdig: { arbeidsbenk.venstre3D[fane] = nil })
    }
}

/// Fargelinjen: fargene over hverandre i like store felt, uten tekst – med streken rundt når fanen har en (Overgang).
private struct Fargelinje: View {
    let farger: [Duofarge]
    var ramme: Color? = nil
    /// Rammen rundt merkede felt (lukket); åpen tegner Kortoppsett den rundt kortet og fargelinjen samlet.
    var merk = true

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(farger.enumerated()), id: \.offset) { _, f in
                Rectangle().fill(f.farge.swiftUI)
                    .overlay { if merk && f.markert { Rectangle().strokeBorder(f.farge.lesbarTekstfarge.swiftUI, lineWidth: 3) } }
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
