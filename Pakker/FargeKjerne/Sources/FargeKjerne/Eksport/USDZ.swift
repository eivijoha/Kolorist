import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
import simd

/// En enkel 3D-scene som kan skrives som USDZ – til Hurtigvisning på Mac og AR Quick Look på iPhone og iPad. Flatene har
/// enten en tekstur (fargene i et PNG-bilde, med UV per punkt) eller én farge, og ser «ulyste» ut (fargen også som
/// emissiv), så lyssettingen i viseren ikke endrer fargene. Gjennomsiktige flater får ikke emissiv farge (de ville
/// ellers gløde).
public struct USDScene: Sendable {
    public struct Mesh: Sendable {
        public var navn: String
        public var punkter: [SIMD3<Float>]
        /// UV per punkt (0…1, v oppover), eller tom for ensfarget.
        public var uv: [SIMD2<Float>]
        public var trekanter: [SIMD3<Int32>]
        /// Navnet på teksturen i `USDScene.teksturer`, eller `nil` for ensfarget.
        public var tekstur: String?
        /// Fargen (sRGB 0…1) når flaten ikke har tekstur.
        public var farge: SIMD3<Float>
        /// 1 = heldekkende.
        public var opasitet: Float

        public init(navn: String, punkter: [SIMD3<Float>], uv: [SIMD2<Float>] = [], trekanter: [SIMD3<Int32>],
                    tekstur: String? = nil, farge: SIMD3<Float> = .init(0.6, 0.6, 0.6), opasitet: Float = 1) {
            self.navn = navn
            self.punkter = punkter
            self.uv = uv
            self.trekanter = trekanter
            self.tekstur = tekstur
            self.farge = farge
            self.opasitet = opasitet
        }
    }

    public var navn: String
    public var mesher: [Mesh]
    /// PNG-data per teksturnavn (f.eks. «kule.png»), i sRGB.
    public var teksturer: [String: Data]

    public init(navn: String, mesher: [Mesh], teksturer: [String: Data] = [:]) {
        self.navn = navn
        self.mesher = mesher
        self.teksturer = teksturer
    }

    /// Scenen som USDZ-fil.
    public func usdz() -> Data {
        var filer = [(navn: "scene.usda", data: Data(usda().utf8))]
        for (navn, data) in teksturer.sorted(by: { $0.key < $1.key }) { filer.append((navn, data)) }
        return USDZPakke.pakk(filer)
    }

    /// Scenen som USDA-tekst (Y opp, meter).
    public func usda() -> String {
        let rot = Self.identifikator(navn)
        var navnIBruk = Set<String>()
        let meshnavn = mesher.map { m -> String in
            var n = Self.identifikator(m.navn), k = 2
            while navnIBruk.contains(n) { n = Self.identifikator(m.navn) + "_\(k)"; k += 1 }
            navnIBruk.insert(n)
            return n
        }
        var u = """
        #usda 1.0
        (
            defaultPrim = "\(rot)"
            metersPerUnit = 1
            upAxis = "Y"
        )

        def Xform "\(rot)" (
            kind = "component"
        )
        {

        """
        for (m, mn) in zip(mesher, meshnavn) {
            // Hver trekant i begge retninger: AR Quick Look ser bort fra doubleSided og skjuler baksidene, så flater
            // (f.eks. sidene i et gamutskall) forsvant når de ble sett fra den andre siden. Med baksidene skjult er bare
            // én av de to synlig om gangen – også gjennomsiktige flater blir ikke dobbelt så dekkende.
            let trekanter = m.trekanter + m.trekanter.map { SIMD3($0.x, $0.z, $0.y) }
            u += """
                def Mesh "\(mn)" (
                    prepend apiSchemas = ["MaterialBindingAPI"]
                )
                {
                    uniform bool doubleSided = 0
                    int[] faceVertexCounts = [\(Array(repeating: "3", count: trekanter.count).joined(separator: ", "))]
                    int[] faceVertexIndices = [\(trekanter.map { "\($0.x), \($0.y), \($0.z)" }.joined(separator: ", "))]
                    point3f[] points = [\(m.punkter.map { "(\(Self.tall($0.x)), \(Self.tall($0.y)), \(Self.tall($0.z)))" }.joined(separator: ", "))]

            """
            if !m.uv.isEmpty {
                u += """
                        texCoord2f[] primvars:st = [\(m.uv.map { "(\(Self.tall($0.x)), \(Self.tall($0.y)))" }.joined(separator: ", "))] (
                            interpolation = "vertex"
                        )

                """
            }
            u += """
                    uniform token subdivisionScheme = "none"
                    rel material:binding = </\(rot)/Materialer/\(mn)>
                }

            """
        }
        u += "    def Scope \"Materialer\"\n    {\n"
        for (m, mn) in zip(mesher, meshnavn) {
            let sti = "/\(rot)/Materialer/\(mn)"
            let heldekkende = m.opasitet >= 1
            if let t = m.tekstur {
                u += """
                        def Material "\(mn)"
                        {
                            token outputs:surface.connect = <\(sti)/Overflate.outputs:surface>
                            def Shader "Overflate"
                            {
                                uniform token info:id = "UsdPreviewSurface"
                                color3f inputs:diffuseColor.connect = <\(sti)/Tekstur.outputs:rgb>
                \(heldekkende ? "                color3f inputs:emissiveColor.connect = <\(sti)/Tekstur.outputs:rgb>\n" : "")\
                                float inputs:roughness = 1
                                float inputs:metallic = 0
                \(heldekkende ? "" : "                float inputs:opacity = \(Self.tall(m.opasitet))\n")\
                                token outputs:surface
                            }
                            def Shader "StLeser"
                            {
                                uniform token info:id = "UsdPrimvarReader_float2"
                                string inputs:varname = "st"
                                float2 outputs:result
                            }
                            def Shader "Tekstur"
                            {
                                uniform token info:id = "UsdUVTexture"
                                asset inputs:file = @\(t)@
                                float2 inputs:st.connect = <\(sti)/StLeser.outputs:result>
                                token inputs:sourceColorSpace = "sRGB"
                                token inputs:wrapS = "clamp"
                                token inputs:wrapT = "clamp"
                                float3 outputs:rgb
                            }
                        }

                """
            } else {
                let f = "(\(Self.tall(m.farge.x)), \(Self.tall(m.farge.y)), \(Self.tall(m.farge.z)))"
                u += """
                        def Material "\(mn)"
                        {
                            token outputs:surface.connect = <\(sti)/Overflate.outputs:surface>
                            def Shader "Overflate"
                            {
                                uniform token info:id = "UsdPreviewSurface"
                                color3f inputs:diffuseColor = \(f)
                \(heldekkende ? "                color3f inputs:emissiveColor = \(f)\n" : "")\
                                float inputs:roughness = 1
                                float inputs:metallic = 0
                \(heldekkende ? "" : "                float inputs:opacity = \(Self.tall(m.opasitet))\n")\
                                token outputs:surface
                            }
                        }

                """
            }
        }
        u += "    }\n}\n"
        return u
    }

    private static func tall(_ v: Float) -> String { String(format: "%.5g", v) }

    /// Gyldig USD-navn: bokstaver, tall og understrek (ASCII), og en bokstav først.
    private static func identifikator(_ s: String) -> String {
        let r = String(s.unicodeScalars.map { $0.isASCII && CharacterSet.alphanumerics.contains($0) ? Character($0) : "_" })
        return r.first?.isLetter == true ? r : "M_" + r
    }

    /// PNG (sRGB) fra en pikselfunksjon som gir sRGB 0…1; rad 0 er øverst.
    public static func png(bredde: Int, høyde: Int, piksel: (Int, Int) -> SIMD3<Double>) -> Data? {
        guard let rom = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(data: nil, width: bredde, height: høyde, bitsPerComponent: 8, bytesPerRow: bredde * 4,
                                  space: rom, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue),
              let p = ctx.data?.assumingMemoryBound(to: UInt8.self)
        else { return nil }
        for y in 0..<høyde {
            for x in 0..<bredde {
                let c = piksel(x, y)
                let i = (y * bredde + x) * 4
                p[i] = UInt8((min(1, max(0, c.x)) * 255).rounded())
                p[i + 1] = UInt8((min(1, max(0, c.y)) * 255).rounded())
                p[i + 2] = UInt8((min(1, max(0, c.z)) * 255).rounded())
                p[i + 3] = 255
            }
        }
        guard let bilde = ctx.makeImage() else { return nil }
        let data = NSMutableData()
        guard let mål = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(mål, bilde, nil)
        return CGImageDestinationFinalize(mål) ? data as Data : nil
    }
}

// MARK: - Enkle former

public extension USDScene.Mesh {
    /// Kule (UV-kule) med sentrum og radius, ensfarget.
    static func kule(navn: String, sentrum: SIMD3<Float>, radius: Float, farge: SIMD3<Float>, opasitet: Float = 1,
                     oppløsning: Int = 12) -> USDScene.Mesh {
        let lengde = oppløsning * 2, bredde = oppløsning
        var punkter: [SIMD3<Float>] = [], trekanter: [SIMD3<Int32>] = []
        for j in 0...bredde {
            let θ = Float(j) / Float(bredde) * .pi
            for i in 0...lengde {
                let φ = Float(i) / Float(lengde) * 2 * .pi
                punkter.append(sentrum + radius * SIMD3(sin(θ) * cos(φ), cos(θ), sin(θ) * sin(φ)))
            }
        }
        let rad = Int32(lengde + 1)
        for j in 0..<Int32(bredde) {
            for i in 0..<Int32(lengde) {
                let a = j * rad + i, b = a + 1, c = a + rad, d = c + 1
                trekanter.append(.init(a, d, b))
                trekanter.append(.init(a, c, d))
            }
        }
        return .init(navn: navn, punkter: punkter, trekanter: trekanter, farge: farge, opasitet: opasitet)
    }

    /// Rør langs en rekke punkter (som en strek i rommet), ensfarget.
    static func rør(navn: String, langs stien: [SIMD3<Float>], radius: Float, farge: SIMD3<Float>, opasitet: Float = 1,
                    sider: Int = 8) -> USDScene.Mesh {
        // Punkter som faller sammen (f.eks. en farge og nærmeste tone med ΔE 0), gir ingen retning – de hoppes over.
        var sti: [SIMD3<Float>] = []
        for p in stien where sti.last.map({ simd_distance($0, p) > 1e-6 }) ?? true { sti.append(p) }
        guard sti.count > 1 else { return .init(navn: navn, punkter: [], trekanter: [], farge: farge, opasitet: opasitet) }
        var punkter: [SIMD3<Float>] = [], trekanter: [SIMD3<Int32>] = []
        // Rammen føres videre fra punkt til punkt (parallelltransport), så røret ikke vrir seg der retningen skifter.
        var u = SIMD3<Float>(0, 0, 0)
        for (k, p) in sti.enumerated() {
            let fram = simd_normalize(sti[min(k + 1, sti.count - 1)] - sti[max(k - 1, 0)])
            if k == 0 {
                let hjelp: SIMD3<Float> = abs(fram.y) < 0.9 ? [0, 1, 0] : [1, 0, 0]
                u = simd_normalize(simd_cross(fram, hjelp))
            } else {
                let rettet = u - simd_dot(u, fram) * fram
                if simd_length(rettet) > 1e-6 { u = simd_normalize(rettet) }
            }
            let v = simd_cross(fram, u)
            for s in 0..<sider {
                let a = Float(s) / Float(sider) * 2 * .pi
                punkter.append(p + radius * (cos(a) * u + sin(a) * v))
            }
        }
        let n = Int32(sider)
        for k in 0..<Int32(sti.count - 1) {
            for s in 0..<n {
                let a = k * n + s, b = k * n + (s + 1) % n, c = a + n, d = b + n
                trekanter.append(.init(a, b, d))
                trekanter.append(.init(a, d, c))
            }
        }
        return .init(navn: navn, punkter: punkter, trekanter: trekanter, farge: farge, opasitet: opasitet)
    }
}

// MARK: - USDZ-pakking

/// USDZ er et zip-arkiv uten komprimering der dataene i hver fil starter på et multiplum av 64 byte, og den første filen
/// er scenen.
enum USDZPakke {
    static func pakk(_ filer: [(navn: String, data: Data)]) -> Data {
        var ut = Data(), katalog = Data()
        for fil in filer {
            let navn = Data(fil.navn.utf8)
            let crc = crc32(fil.data)
            let posisjon = UInt32(ut.count)
            // Utfylling i ekstrafeltet (id 0x1986, som Apple bruker) så dataene havner på en 64-byte-grense.
            var ekstra = Data()
            let start = ut.count + 30 + navn.count
            if start % 64 != 0 {
                let fyll = (64 - (start + 4) % 64) % 64
                ekstra.le16(0x1986); ekstra.le16(UInt16(fyll)); ekstra.append(Data(count: fyll))
            }
            ut.le32(0x0403_4b50); ut.le16(20); ut.le16(0); ut.le16(0); ut.le16(0); ut.le16(0x21)
            ut.le32(crc); ut.le32(UInt32(fil.data.count)); ut.le32(UInt32(fil.data.count))
            ut.le16(UInt16(navn.count)); ut.le16(UInt16(ekstra.count))
            ut.append(navn); ut.append(ekstra); ut.append(fil.data)

            katalog.le32(0x0201_4b50); katalog.le16(20); katalog.le16(20); katalog.le16(0); katalog.le16(0); katalog.le16(0)
            katalog.le16(0x21); katalog.le32(crc); katalog.le32(UInt32(fil.data.count)); katalog.le32(UInt32(fil.data.count))
            katalog.le16(UInt16(navn.count)); katalog.le16(0); katalog.le16(0); katalog.le16(0); katalog.le16(0)
            katalog.le32(0); katalog.le32(posisjon); katalog.append(navn)
        }
        let katalogstart = UInt32(ut.count)
        ut.append(katalog)
        ut.le32(0x0605_4b50); ut.le16(0); ut.le16(0); ut.le16(UInt16(filer.count)); ut.le16(UInt16(filer.count))
        ut.le32(UInt32(katalog.count)); ut.le32(katalogstart); ut.le16(0)
        return ut
    }

    static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for b in data { crc = tabell[Int((crc ^ UInt32(b)) & 0xFF)] ^ (crc >> 8) }
        return crc ^ 0xFFFF_FFFF
    }

    private static let tabell: [UInt32] = (0..<256).map { i in
        var c = UInt32(i)
        for _ in 0..<8 { c = (c & 1) != 0 ? 0xEDB8_8320 ^ (c >> 1) : c >> 1 }
        return c
    }
}

private extension Data {
    mutating func le16(_ v: UInt16) { append(UInt8(v & 0xFF)); append(UInt8(v >> 8)) }
    mutating func le32(_ v: UInt32) { for i in 0..<4 { append(UInt8((v >> (8 * UInt32(i))) & 0xFF)) } }
}
