#if os(iOS)
import FargeKjerne
import FargeMaaling
import SwiftUI

/// Mål lyset med kameraet og lagre det som lysmiljø (fra Vurdering › Lys). Kameraets hvitbalanse gir lysets farge;
/// med et grått eller hvitt kort i lyset gir eksponeringen også belysningsstyrken.
struct LysmålingArk: View {
    @State private var plukker = KameraFargeplukker()
    @State private var egetKort = false
    @State private var lagreLysmiljø: Lysmiljø?
    /// Lysmiljøet er lagret: målearket lukkes når navnearket er borte.
    @State private var lagret = false
    @State private var bibliotek = Lysbibliotek.delt
    @Environment(\.dismiss) private var lukk

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GeometryReader { geo in
                    ZStack {
                        KameraForhåndsvisning(
                            økt: plukker.økt,
                            vedTrykk: { enhet, visning in plukker.plukk(enhetspunkt: enhet, visningspunkt: visning) },
                            vedKnip: { skala, begynner in plukker.knip(skala, begynner: begynner) },
                            vedDobbelttrykk: { plukker.settZoom(1) },
                            vedOrientering: { plukker.settVisningsorientering(vinkel: $0, speilet: $1) }
                        )
                        if plukker.venterPåGråkort {
                            Circle()
                                .strokeBorder(.white, lineWidth: 2)
                                .shadow(radius: 2)
                                .frame(width: 44, height: 44)
                                .position(plukker.markør ?? CGPoint(x: geo.size.width / 2, y: geo.size.height / 2))
                                .allowsHitTesting(false)
                        }
                        if plukker.tilgangNektet {
                            ContentUnavailableView("Ingen kameratilgang", systemImage: "camera.fill",
                                                   description: Text("Gi tilgang i Innstillinger for å måle lyset med kameraet."))
                                .background(.regularMaterial)
                        }
                    }
                    .overlay(alignment: .topLeading) {
                        LysmålingMerke(venterPåGråkort: plukker.venterPåGråkort, kompensasjon: plukker.kompensasjon,
                                       måling: plukker.lysmåling)
                    }
                }
                .clipped()

                VStack(alignment: .leading, spacing: 12) {
                    Text(veiledning)
                        .font(.callout)
                        .foregroundStyle(Color.sekundærTekst)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 10) {
                        Button("Mål lyset", systemImage: "camera.metering.center.weighted") { plukker.kompenser(for: nil) }
                        Menu {
                            Button("Gråkort 18 %") { plukker.ventPåGråkort(refleksjon: 0.18, profil: profil) }
                            Button("Hvitt kort 90 %") { plukker.ventPåGråkort(refleksjon: 0.9, profil: profil) }
                            Button("Eget kort …") { egetKort = true }
                        } label: {
                            Label("Med kort", systemImage: "rectangle.portrait")
                        }
                    }
                    .buttonStyle(.bordered)
                    Button {
                        guard let m = plukker.lysmåling else { return }
                        lagreLysmiljø = Lysmiljø(navn: String(localized: "Målt lys"), lyskilde: m.lyskilde,
                                                 lux: m.lux.map(LysmiljøRedigering.rundet) ?? 300, måling: m)
                    } label: {
                        Label("Lagre som lysmiljø …", systemImage: "lightbulb.2").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(plukker.lysmåling == nil)
                }
                .controlSize(.large)
                .padding()
                .background(.bar)
            }
            .navigationTitle("Mål lyset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Avbryt") { lukk() } } }
            .modifier(EgetKortSpørsmål(vises: $egetKort) { plukker.ventPåGråkort(refleksjon: $0, profil: profil) })
            // Lukk målearket først når navnearket er borte (to lukkinger samtidig gir hakk).
            .sheet(item: $lagreLysmiljø, onDismiss: { if lagret { lukk() } }) { miljø in
                LysmiljøRedigering(miljø: miljø) { nytt in
                    bibliotek.lagre(nytt)
                    bibliotek.valgtLysmiljø = nytt.id
                    // Det nye lysmiljøet vises med én gang i Vurdering › Lys.
                    if !bibliotek.erVist(nytt) { bibliotek.veksleVist(nytt) }
                    lagret = true
                }
            }
            // Kameraet står stille mens lysmiljøet navngis: målingen oppdateres ellers hvert sekund og tegner arket på
            // nytt, så skrivingen avbrytes.
            .onChange(of: lagreLysmiljø != nil) { _, åpent in
                if åpent { plukker.stopp() } else if !lagret { Task { await plukker.start() } }
            }
        }
        .task { await plukker.start() }
        .onDisappear { plukker.stopp() }
    }

    /// Kameraprofilen for dette kameraet, om den er laget med et referansekort.
    private var profil: Kamerakarakterisering? { bibliotek.kameraprofil(for: plukker.kameranøkkel)?.karakterisering }

    private var veiledning: LocalizedStringKey {
        if plukker.venterPåGråkort { return "Trykk på kortet i bildet. Kortet må ligge i lyset du måler, uten skygge eller gjenskinn." }
        if plukker.lysmåling != nil { return "Lyset er målt. Lagre det som lysmiljø, eller mål på nytt. Med et grått eller hvitt kort blir også lysstyrken målt." }
        return "Stå der fargene skal brukes og mål lyset. Kameraet gir lysets farge og anslår lysstyrken; med et grått eller hvitt kort i lyset blir den målt."
    }
}
#endif
