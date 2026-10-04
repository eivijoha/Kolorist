import FargeKjerne
import SwiftUI

/// «+»-meny på en farge: lagre den (som enkeltfarge eller i en palett), og – når fargen er gitt – kopiere verdiene,
/// dele den som lenke eller kopiere den til andre programmer. Alt ligger rett i menyen (ingen undermenyer, som
/// lukker seg selv på iOS). Viser en kort hake etter lagring som enkeltfarge.
struct LagreMeny: View {
    var lagre: () -> Void
    var leggIPalett: () -> Void
    var størrelse: CGFloat = 44
    /// Fargen som deles og kopieres (med navn og verdier). Uten den har menyen bare lagring.
    var palettFarge: PalettFarge? = nil
    /// Teksten «Kopier verdier» kopierer (verdiene slik feltet viser dem).
    var verdier: String? = nil
    @State private var lagret = false

    var body: some View {
        Menu {
            Section {
                Button("Lagre som enkeltfarge", systemImage: "plus.square") {
                    lagre()
                    lagret = true
                    Task { try? await Task.sleep(for: .seconds(1.5)); lagret = false }
                }
                Button("Legg i palett …", systemImage: "plus.square.on.square") { leggIPalett() }
            }
            if let pf = palettFarge {
                Section {
                    if let verdier { Button("Kopier verdier", systemImage: "doc.on.doc") { Utklippstavle.kopierTekst(verdier) } }
                    Button("Kopier hex", systemImage: "number") { Utklippstavle.kopier(pf.farge) }
                    DelSomLenke(navn: pf.navn.isEmpty ? pf.farge.hex() : pf.navn) { Lenkedeling.farge(pf) }
                }
                KopierTilMeny(farger: [pf], navn: pf.navn, inline: true)
            }
        } label: {
            Image(systemName: lagret ? "checkmark.square.fill" : "plus.square")
                .frame(width: størrelse, height: størrelse)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .menuOrder(.fixed)
        .sensoryFeedback(.success, trigger: lagret) { _, ny in ny }
        .accessibilityLabel(lagret ? String(localized: "Lagret") : String(localized: "Lagre og del farge"))
    }
}
