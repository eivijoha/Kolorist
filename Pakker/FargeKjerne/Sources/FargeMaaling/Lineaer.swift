import FargeKjerne
import Foundation

/// 3×3-matriser (FargeKjernes `Matrise3`) brukt på XYZ.
extension Matrise3 {
    func ganget(_ v: XYZ) -> XYZ {
        let r = self * Vektor3(v.x, v.y, v.z)
        return XYZ(x: r.x, y: r.y, z: r.z)
    }
}

/// Minste kvadraters metode for modelltilpasning.
enum Lineær {
    /// Løser A·x = b med gausseliminasjon og delvis pivotering. `nil` hvis A er (nesten) singulær.
    static func løs(_ a: [[Double]], _ b: [[Double]]) -> [[Double]]? {
        let n = a.count
        var m = a, h = b
        for k in 0..<n {
            guard let p = (k..<n).max(by: { abs(m[$0][k]) < abs(m[$1][k]) }), abs(m[p][k]) > 1e-12 else { return nil }
            m.swapAt(k, p); h.swapAt(k, p)
            for i in (k + 1)..<n where m[i][k] != 0 {
                let f = m[i][k] / m[k][k]
                for j in k..<n { m[i][j] -= f * m[k][j] }
                for j in h[i].indices { h[i][j] -= f * h[k][j] }
            }
        }
        var x = h
        for i in stride(from: n - 1, through: 0, by: -1) {
            for j in x[i].indices {
                var s = h[i][j]
                for k in (i + 1)..<n { s -= m[i][k] * x[k][j] }
                x[i][j] = s / m[i][i]
            }
        }
        return x
    }

    /// Minste kvadraters tilpasning X·K ≈ Y (rader er observasjoner), med valgfri ridge-regularisering.
    /// Returnerer koeffisientene K (egenskaper × utganger).
    static func minsteKvadrater(_ x: [[Double]], _ y: [[Double]], ridge: Double = 0) -> [[Double]]? {
        guard let p = x.first?.count, x.count == y.count, x.count >= p else { return nil }
        var xtx = Array(repeating: Array(repeating: 0.0, count: p), count: p)
        var xty = Array(repeating: Array(repeating: 0.0, count: y[0].count), count: p)
        for (rad, mål) in zip(x, y) {
            for i in 0..<p {
                for j in 0..<p { xtx[i][j] += rad[i] * rad[j] }
                for j in mål.indices { xty[i][j] += rad[i] * mål[j] }
            }
        }
        if ridge > 0 { for i in 0..<p { xtx[i][i] += ridge } }
        return løs(xtx, xty)
    }
}
