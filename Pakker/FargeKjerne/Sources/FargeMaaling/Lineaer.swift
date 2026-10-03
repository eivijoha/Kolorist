import FargeKjerne
import Foundation

/// Litt lineær algebra for modultilpasning: 3×3-matriser og minste kvadraters metode.
public struct Matrise3x3: Hashable, Codable, Sendable {
    public var rader: [[Double]]

    public init(_ rader: [[Double]]) { self.rader = rader }

    public static let identitet = Matrise3x3([[1, 0, 0], [0, 1, 0], [0, 0, 1]])

    public static func diagonal(_ a: Double, _ b: Double, _ c: Double) -> Matrise3x3 {
        Matrise3x3([[a, 0, 0], [0, b, 0], [0, 0, c]])
    }

    public func ganget(_ v: (Double, Double, Double)) -> (Double, Double, Double) {
        let r = rader
        return (r[0][0] * v.0 + r[0][1] * v.1 + r[0][2] * v.2,
                r[1][0] * v.0 + r[1][1] * v.1 + r[1][2] * v.2,
                r[2][0] * v.0 + r[2][1] * v.1 + r[2][2] * v.2)
    }

    public func ganget(_ v: XYZ) -> XYZ {
        let (x, y, z) = ganget((v.x, v.y, v.z))
        return XYZ(x: x, y: y, z: z)
    }

    public static func * (a: Matrise3x3, b: Matrise3x3) -> Matrise3x3 {
        Matrise3x3((0..<3).map { i in (0..<3).map { j in (0..<3).reduce(0) { $0 + a.rader[i][$1] * b.rader[$1][j] } } })
    }

    public var invertert: Matrise3x3 {
        let m = rader
        let a = m[1][1] * m[2][2] - m[1][2] * m[2][1]
        let b = m[1][2] * m[2][0] - m[1][0] * m[2][2]
        let c = m[1][0] * m[2][1] - m[1][1] * m[2][0]
        let det = m[0][0] * a + m[0][1] * b + m[0][2] * c
        let d = 1 / det
        return Matrise3x3([
            [a * d, (m[0][2] * m[2][1] - m[0][1] * m[2][2]) * d, (m[0][1] * m[1][2] - m[0][2] * m[1][1]) * d],
            [b * d, (m[0][0] * m[2][2] - m[0][2] * m[2][0]) * d, (m[0][2] * m[1][0] - m[0][0] * m[1][2]) * d],
            [c * d, (m[0][1] * m[2][0] - m[0][0] * m[2][1]) * d, (m[0][0] * m[1][1] - m[0][1] * m[1][0]) * d],
        ])
    }
}

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
