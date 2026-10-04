import Foundation
import Synchronization

/// Hindrer at innhold fra fargebiblioteker brukeren har importert – ofte rettighetsbelagte fargekart med navngitte
/// toner – deles videre i lenker. Fargen selv deles (en enkelt fargeverdi), men ikke tonens navn, bibliotekets
/// verdier eller kilden.
///
/// Toner fra importerte bibliotek er merket (`Fargekilde.importert`). Farger lagret før merket fantes, kjennes igjen
/// på navnet: appen melder navnene i de importerte bibliotekene med `oppdater(tonenavn:)`. Rene tall (toner uten
/// navn i ACO-filer) tas ikke med, så egne farger med tallnavn ikke rammes.
public enum Delingsvern {
    private static let tonenavn = Mutex<Set<String>>([])

    /// Navnene på tonene i bibliotekene brukeren har importert på denne enheten.
    public static func oppdater(tonenavn navn: some Sequence<String>) {
        let sett = Set(navn.lazy.map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.allSatisfy(\.isNumber) })
        tonenavn.withLock { $0 = sett }
    }

    public static func erFraImportertBibliotek(_ pf: PalettFarge) -> Bool {
        if pf.kilde?.importert == true { return true }
        let navn = pf.navn.trimmingCharacters(in: .whitespaces)
        return !navn.isEmpty && tonenavn.withLock { $0.contains(navn) }
    }

    /// Fargen uten navn, verdier og kilde fra et importert bibliotek; andre farger uendret.
    public static func renset(_ pf: PalettFarge) -> PalettFarge {
        guard erFraImportertBibliotek(pf) else { return pf }
        return PalettFarge(id: pf.id, farge: pf.farge, opphav: .manuell)
    }
}
