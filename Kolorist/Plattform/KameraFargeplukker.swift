@preconcurrency import AVFoundation
import CoreImage
import FargeKjerne
import FargeMaaling
import SwiftUI

/// Leser fargen i et valgt punkt i kamerabildet fortløpende (iPhone, iPad og Mac via
/// innebygd kamera eller Continuity Camera). Trykk/klikk i bildet flytter punktet og fanger fargen.
///
/// Fargen er et gjennomsnitt av et lite felt for å dempe støy. Kamerabufferens
/// fargerom (sRGB eller Display P3) leses fra bufferens metadata.
/// Automatisk hvitbalanse påvirker resultatet. Med lyskompensasjon låses hvitbalansen (iPhone/iPad) til dagslys,
/// og Kolorist kompenserer selv for lyset (`Lyskompensasjon`).
@Observable
final class KameraFargeplukker {
    /// Fargen i målpunktet, kompensert for lyset når kompensasjon er slått på.
    private(set) var gjeldende: Farge?
    /// Fargen slik kameraet så den.
    private(set) var rå: Farge?
    /// Kompensasjon for lyset (nil = fargene slik kameraet ser dem).
    private(set) var kompensasjon: Lyskompensasjon?
    /// Neste trykk i bildet registrerer et gråkort i stedet for å fange en farge.
    private(set) var venterPåGråkort = false
    @ObservationIgnored private var gråkortRefleksjon = 0.18
    @ObservationIgnored private var gråkortProfil: Kamerakarakterisering?
    /// Lyset slik kameraet anslår det: fra hvitbalansen (før låsing) og eksponeringen, eller fra et kort.
    private(set) var lysmåling: Lysmåling?
    @ObservationIgnored private var sistLysmåling = Date.distantPast
    /// Kalles når et stillbilde (for referansekortet) er tatt.
    @ObservationIgnored private var vedStillbilde: ((CGImage) -> Void)?
    private(set) var tilgangNektet = false
    /// Markørens plassering i forhåndsvisningen (SwiftUI-punkter); nil = midten.
    private(set) var markør: CGPoint?
    let økt = AVCaptureSession()
    /// Kalles på hovedtråden når et trykk/klikk har fanget en farge.
    @ObservationIgnored var vedFangst: ((Farge) -> Void)?

    @ObservationIgnored private let leser = BufferLeser()
    @ObservationIgnored private let kø = DispatchQueue(label: "no.engenett.kolorist.kamera")
    @ObservationIgnored private var erKonfigurert = false
    @ObservationIgnored private var enhet: AVCaptureDevice?

    /// Om kameraet har en lyskilde (bakkamera på iPhone/iPad, Continuity-iPhone på Mac).
    private(set) var harLykt = false
    private(set) var lyktPå = false
    /// Lysstyrke 0…1 (der enheten støtter trinnløs styrke).
    private(set) var lyktNivå: Float = 1
    /// Zoom relativt til vanlig 1×-utsnitt (0,5 = ultravidvinkel på iPhone).
    private(set) var zoom: CGFloat = 1
    @ObservationIgnored private var grunnZoom: CGFloat = 1

    /// Kamerabildet vist slik det ser ut med et fargesynsavvik (nil = normalt). Bare visningen
    /// filtreres; fargene som plukkes er de faktiske.
    var fargesyn: Fargesynstype? {
        didSet { oppdaterFilter() }
    }
    /// Alvorlighetsgrad 0…1 (1 = fullstendig avvik).
    var fargesynGrad: Double = 1 {
        didSet { oppdaterFilter() }
    }

    private func oppdaterFilter() {
        leser.settFilter(fargesyn.map { $0.lineærMatrise(grad: fargesynGrad) })
        if fargesyn == nil { filterlag.contents = nil }
    }
    /// Lag over forhåndsvisningen som viser det filtrerte bildet.
    @ObservationIgnored let filterlag: CALayer = {
        let lag = CALayer()
        lag.contentsGravity = .resizeAspectFill
        lag.masksToBounds = true
        return lag
    }()

    /// Forhåndsvisningens rotasjon og speiling, så det filtrerte bildet ligger likt med kamerabildet.
    func settVisningsorientering(vinkel: CGFloat, speilet: Bool) {
        leser.settOrientering(vinkel: vinkel, speilet: speilet)
    }
    @ObservationIgnored private var zoomVedStart: CGFloat = 1

    func start() async {
        guard await AVCaptureDevice.requestAccess(for: .video) else {
            tilgangNektet = true
            return
        }
        if !erKonfigurert { konfigurer() }
        #if os(macOS)
        følgTilkoblinger()
        #endif
        leser.vedFarge = { [weak self] farge, erFangst in
            Task { @MainActor in self?.mottatt(farge, erFangst: erFangst) }
        }
        leser.vedStillbilde = { [weak self] bilde in
            Task { @MainActor in
                self?.vedStillbilde?(bilde)
                self?.vedStillbilde = nil
            }
        }
        leser.vedFiltrertBilde = { [weak self] bilde in
            Task { @MainActor in
                guard let self, self.fargesyn != nil else { return }
                // Filterlaget ligger i forhåndsvisningslaget. Dets forbindelse finnes først når økten
                // kjører, og vinkelen endres ved rotasjon – les den her, så bildet alltid ligger likt.
                if let lag = self.filterlag.superlayer as? AVCaptureVideoPreviewLayer, let k = lag.connection {
                    self.leser.settOrientering(vinkel: k.videoRotationAngle, speilet: k.isVideoMirrored)
                }
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                self.filterlag.contents = bilde
                CATransaction.commit()
            }
        }
        let økt = self.økt
        kø.async { økt.startRunning() }
    }

    /// Slår lykten av/på med valgt styrke. Jevnt, kjent lys gir mer stabile målinger
    /// i mørke omgivelser; merk at lyktens fargetemperatur også påvirker resultatet.
    func settLykt(på: Bool, nivå: Float? = nil) {
        guard let enhet, enhet.hasTorch else { return }
        if let nivå { lyktNivå = min(max(nivå, 0.05), 1) }
        let styrke = lyktNivå
        kø.async {
            guard (try? enhet.lockForConfiguration()) != nil else { return }
            defer { enhet.unlockForConfiguration() }
            if på {
                #if os(iOS)
                try? enhet.setTorchModeOn(level: min(styrke, AVCaptureDevice.maxAvailableTorchLevel))
                #else
                if enhet.isTorchModeSupported(.on) { enhet.torchMode = .on }
                #endif
            } else if enhet.isTorchModeSupported(.off) {
                enhet.torchMode = .off
            }
        }
        lyktPå = på
    }

    // MARK: Lyskompensasjon

    private func mottatt(_ farge: Farge, erFangst: Bool) {
        rå = farge
        if erFangst && venterPåGråkort {
            registrerGråkort(farge)
            return
        }
        gjeldende = kompensasjon?.kompensert(farge) ?? farge
        if erFangst { vedFangst?(gjeldende ?? farge) }
        if kompensasjon == nil, Date.now.timeIntervalSince(sistLysmåling) > 1 {
            sistLysmåling = .now
            lysmåling = målLysFraKamera()
        }
    }

    /// Kompenserer for en valgt lyskilde, eller for lyset kameraet måler nå (`nil`).
    func kompenser(for lys: Lyskilde?) {
        venterPåGråkort = false
        #if os(iOS)
        let målt = lys ?? målLysFraKamera().map { Lyskilde.hvitpunkt(x: Kolorimetri.xy(kelvin: $0.kelvin, duv: $0.duv).x,
                                                                     y: Kolorimetri.xy(kelvin: $0.kelvin, duv: $0.duv).y) }
        guard let målt else { return }
        låsHvitbalanseTilDagslys()
        kompensasjon = .hvitpunkt(målt)
        if let t = målt.fargetemperatur {
            lysmåling = Lysmåling(kelvin: t.kelvin, duv: t.duv, metode: .kamera)
        }
        #endif
    }

    /// Neste trykk i bildet er på et grått eller hvitt kort med kjent refleksjon.
    /// Med en kameraprofil (iPhone/iPad) gir gråkortet også lysets farge gjennom profilen.
    func ventPåGråkort(refleksjon: Double, profil: Kamerakarakterisering? = nil) {
        gråkortRefleksjon = refleksjon
        #if os(iOS)
        gråkortProfil = profil
        #else
        gråkortProfil = nil
        #endif
        venterPåGråkort = true
        #if os(iOS)
        låsHvitbalanseTilDagslys()
        #else
        låsGjeldendeHvitbalanse()
        #endif
    }

    private func registrerGråkort(_ målt: Farge) {
        venterPåGråkort = false
        låsEksponering()
        let komp: Lyskompensasjon = gråkortProfil.map { .kameraprofil($0, gråkort: målt, refleksjon: gråkortRefleksjon) }
            ?? .gråkort(målt: målt, refleksjon: gråkortRefleksjon)
        kompensasjon = komp
        #if os(macOS)
        // macOS gir ikke hvitbalanse eller eksponering, og bildet er allerede hvitbalansert: ingen lysmåling.
        lysmåling = nil
        #else
        if let t = komp.fargetemperatur {
            lysmåling = Lysmåling(kelvin: t.kelvin, duv: t.duv, lux: luxFraKort(målt, refleksjon: gråkortRefleksjon),
                                  metode: .gråkort)
        }
        #endif
        gjeldende = komp.kompensert(målt)
    }

    /// Bruker en karakterisering fra et referansekort i samme lys.
    func bruk(_ karakterisering: Kamerakarakterisering, måling: Lysmåling?) {
        venterPåGråkort = false
        kompensasjon = .referansekort(karakterisering)
        if let måling { lysmåling = måling }
    }

    func slåAvKompensasjon() {
        kompensasjon = nil
        venterPåGråkort = false
        låsOpp()
    }

    /// Låser hvitbalanse og eksponering og tar et stillbilde av hele bildet (for referansekortet).
    func taStillbilde(_ ferdig: @escaping (CGImage) -> Void) {
        #if os(iOS)
        låsHvitbalanseTilDagslys()
        #else
        låsGjeldendeHvitbalanse()
        #endif
        låsEksponering()
        vedStillbilde = ferdig
        leser.taStillbilde()
    }

    /// Lyset fra kameraets automatiske hvitbalanse (iPhone/iPad). Lux vises bare med kort i bildet (for grovt uten).
    private func målLysFraKamera() -> Lysmåling? {
        #if os(iOS)
        guard let enhet, enhet.whiteBalanceMode != .locked else { return lysmåling }
        let g = Self.begrenset(enhet.deviceWhiteBalanceGains, enhet: enhet)
        let c = enhet.chromaticityValues(for: g)
        guard let t = Kolorimetri.fargetemperatur(x: Double(c.x), y: Double(c.y)) else { return nil }
        return Lysmåling(kelvin: t.kelvin, duv: t.duv, metode: .kamera)
        #else
        return nil
        #endif
    }

    /// Lux fra kamerafargen til et kort eller felt med kjent refleksjon og gjeldende eksponering (iPhone/iPad).
    func luxFraKort(_ målt: Farge, refleksjon: Double) -> Double? {
        #if os(iOS)
        guard let enhet else { return nil }
        let l = Eksponeringsmåling.luminans(lineærVerdi: målt.xyz.y, blender: Double(enhet.lensAperture),
                                            lukkertid: CMTimeGetSeconds(enhet.exposureDuration), iso: Double(enhet.iso))
        return Eksponeringsmåling.lux(luminans: l, refleksjon: refleksjon)
        #else
        return nil
        #endif
    }

    #if os(iOS)
    private static func begrenset(_ g: AVCaptureDevice.WhiteBalanceGains, enhet: AVCaptureDevice) -> AVCaptureDevice.WhiteBalanceGains {
        let maks = enhet.maxWhiteBalanceGain
        return .init(redGain: min(max(g.redGain, 1), maks), greenGain: min(max(g.greenGain, 1), maks),
                     blueGain: min(max(g.blueGain, 1), maks))
    }

    /// Låser hvitbalansen til D65, så bildet viser lysets farge og Kolorist kan kompensere selv.
    private func låsHvitbalanseTilDagslys() {
        guard let enhet, enhet.isWhiteBalanceModeSupported(.locked) else { return }
        kø.async {
            guard (try? enhet.lockForConfiguration()) != nil else { return }
            defer { enhet.unlockForConfiguration() }
            let d65 = enhet.deviceWhiteBalanceGains(for: .init(x: 0.3127, y: 0.3290))
            enhet.setWhiteBalanceModeLocked(with: Self.begrenset(d65, enhet: enhet))
        }
    }
    #endif

    #if os(macOS)
    /// Mac: hvitbalansen kan bare låses der den er (ikke settes til dagslys), så den ikke endrer seg etter kortet.
    private func låsGjeldendeHvitbalanse() {
        guard let enhet, enhet.isWhiteBalanceModeSupported(.locked) else { return }
        kø.async {
            guard (try? enhet.lockForConfiguration()) != nil else { return }
            enhet.whiteBalanceMode = .locked
            enhet.unlockForConfiguration()
        }
    }
    #endif

    private func låsEksponering() {
        guard let enhet, enhet.isExposureModeSupported(.locked) else { return }
        kø.async {
            guard (try? enhet.lockForConfiguration()) != nil else { return }
            enhet.exposureMode = .locked
            enhet.unlockForConfiguration()
        }
    }

    private func låsOpp() {
        guard let enhet else { return }
        kø.async {
            guard (try? enhet.lockForConfiguration()) != nil else { return }
            defer { enhet.unlockForConfiguration() }
            if enhet.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) { enhet.whiteBalanceMode = .continuousAutoWhiteBalance }
            if enhet.isExposureModeSupported(.continuousAutoExposure) { enhet.exposureMode = .continuousAutoExposure }
        }
    }

    /// Kameraets navn, for å knytte en karakterisering til det.
    var kameranavn: String { enhet?.localizedName ?? String(localized: "Kamera") }

    func stopp() {
        if lyktPå { settLykt(på: false) }
        let økt = self.økt
        kø.async { økt.stopRunning() }
    }

    /// Velger kamera. På iPhone foretrekkes de virtuelle multikameraene, som automatisk bytter til
    /// ultravidvinkel (makro) på kort hold – vidvinkelen alene fokuserer ikke nærmere enn ca. 15–20 cm.
    private static func velgKamera() -> AVCaptureDevice? {
        #if os(iOS)
        let typer: [AVCaptureDevice.DeviceType] = [.builtInTripleCamera, .builtInDualWideCamera, .builtInWideAngleCamera]
        let søk = AVCaptureDevice.DiscoverySession(deviceTypes: typer, mediaType: .video, position: .back)
        for type in typer {
            if let enhet = søk.devices.first(where: { $0.deviceType == type }) { return enhet }
        }
        #else
        // Mac: Continuity-kameraet (iPhone) foretrekkes når det er tilkoblet.
        if let iphone = mackameraer().first(where: { $0.deviceType == .continuityCamera }) { return iphone }
        #endif
        return AVCaptureDevice.default(for: .video)
    }

    #if os(macOS)
    static func mackameraer() -> [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(deviceTypes: [.continuityCamera, .builtInWideAngleCamera, .external],
                                         mediaType: .video, position: .unspecified).devices
    }

    /// Kameraene brukeren kan velge mellom på Mac.
    private(set) var kameraer: [AVCaptureDevice] = []
    @ObservationIgnored private var tilkoblingsobservatører: [NSObjectProtocol] = []

    /// Oppdaterer listen når et kamera (f.eks. en iPhone) kobles til eller fra.
    private func følgTilkoblinger() {
        guard tilkoblingsobservatører.isEmpty else { return }
        kameraer = Self.mackameraer()
        for navn in [AVCaptureDevice.wasConnectedNotification, AVCaptureDevice.wasDisconnectedNotification] {
            tilkoblingsobservatører.append(NotificationCenter.default.addObserver(forName: navn, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.kameraer = Self.mackameraer() }
            })
        }
    }

    /// Bytter kamera (Mac).
    func velg(kamera ny: AVCaptureDevice) {
        guard ny.uniqueID != enhet?.uniqueID, let inn = try? AVCaptureDeviceInput(device: ny) else { return }
        slåAvKompensasjon()
        økt.beginConfiguration()
        økt.inputs.forEach(økt.removeInput)
        if økt.canAddInput(inn) { økt.addInput(inn) }
        økt.commitConfiguration()
        grunnZoom = Self.stillInnFokus(ny)
        enhet = ny
        harLykt = ny.hasTorch
        oppdaterKamerainfo()
    }
    #endif

    /// Om kameraet er en iPhone (eget kamera på iPhone/iPad, eller Continuity-kamera på Mac). Lyskompensasjon med
    /// kort tilbys bare da.
    private(set) var erIPhoneKamera = false
    /// Om lyset kan måles (hvitbalansen kan låses til dagslys): iPhone og iPad, ikke Mac.
    var målerLys: Bool {
        #if os(iOS)
        true
        #else
        false
        #endif
    }
    /// Kameraet som er i bruk (for valget på Mac).
    private(set) var kameraID: String?

    private func oppdaterKamerainfo() {
        kameraID = enhet?.uniqueID
        #if os(iOS)
        erIPhoneKamera = true
        #else
        erIPhoneKamera = enhet?.deviceType == .continuityCamera
        #endif
    }

    /// Kontinuerlig autofokus med vekt på korte avstander, og kontinuerlig eksponering.
    /// Returnerer zoomfaktoren som tilsvarer vanlig 1×.
    @discardableResult
    private static func stillInnFokus(_ enhet: AVCaptureDevice) -> CGFloat {
        var grunn: CGFloat = 1
        guard (try? enhet.lockForConfiguration()) != nil else { return grunn }
        defer { enhet.unlockForConfiguration() }
        if enhet.isFocusModeSupported(.continuousAutoFocus) { enhet.focusMode = .continuousAutoFocus }
        if enhet.isExposureModeSupported(.continuousAutoExposure) { enhet.exposureMode = .continuousAutoExposure }
        #if os(iOS)
        // Virtuelt multikamera: start på vanlig 1×-utsnitt (første overgang), og la iOS bytte til
        // ultravidvinkel automatisk når motivet er for nært for vidvinkelen (som makro i Kamera-appen).
        if let overgang = enhet.virtualDeviceSwitchOverVideoZoomFactors.first {
            grunn = CGFloat(truncating: overgang)
            enhet.videoZoomFactor = grunn
            if enhet.activePrimaryConstituentDeviceSwitchingBehavior != .unsupported {
                enhet.setPrimaryConstituentDeviceSwitchingBehavior(.auto, restrictedSwitchingBehaviorConditions: [])
            }
        }
        if enhet.isAutoFocusRangeRestrictionSupported { enhet.autoFocusRangeRestriction = .near }
        if enhet.isSmoothAutoFocusSupported { enhet.isSmoothAutoFocusEnabled = false }
        #endif
        return grunn
    }

    #if os(iOS)
    /// Knip i forhåndsvisningen: `skala` er relativ til zoomen da knipet startet.
    func knip(_ skala: CGFloat, begynner: Bool) {
        if begynner { zoomVedStart = zoom }
        settZoom(zoomVedStart * skala)
    }

    /// Setter zoom relativt til 1× (0,5× … 10×, innenfor det kameraet støtter).
    func settZoom(_ relativ: CGFloat) {
        guard let enhet else { return }
        let minst = enhet.minAvailableVideoZoomFactor / grunnZoom
        let mest = min(enhet.maxAvailableVideoZoomFactor / grunnZoom, 10)
        let ny = min(max(relativ, minst), mest)
        zoom = ny
        let faktor = ny * grunnZoom
        kø.async {
            guard (try? enhet.lockForConfiguration()) != nil else { return }
            enhet.videoZoomFactor = faktor
            enhet.unlockForConfiguration()
        }
    }
    #endif

    /// Fokus og eksponering på punktet brukeren trykket på (normaliserte enhetskoordinater).
    private func fokuser(på punkt: CGPoint) {
        guard let enhet else { return }
        kø.async {
            guard (try? enhet.lockForConfiguration()) != nil else { return }
            defer { enhet.unlockForConfiguration() }
            if enhet.isFocusPointOfInterestSupported {
                enhet.focusPointOfInterest = punkt
                if enhet.isFocusModeSupported(.continuousAutoFocus) { enhet.focusMode = .continuousAutoFocus }
            }
            if enhet.isExposurePointOfInterestSupported && enhet.exposureMode != .locked {
                enhet.exposurePointOfInterest = punkt
                if enhet.isExposureModeSupported(.continuousAutoExposure) { enhet.exposureMode = .continuousAutoExposure }
            }
        }
    }

    /// Flytter målpunktet og fanger fargen der fra neste bilde.
    /// - Parameters:
    ///   - enhetspunkt: normalisert punkt (0…1) i kamerabufferens koordinater.
    ///   - visningspunkt: samme punkt i forhåndsvisningen, for markøren.
    func plukk(enhetspunkt: CGPoint, visningspunkt: CGPoint) {
        markør = visningspunkt
        fokuser(på: enhetspunkt)
        leser.sett(mål: enhetspunkt, fang: true)
    }

    /// Flytter målpunktet uten å fange (Mac: følger pekeren over forhåndsvisningen).
    func sikt(enhetspunkt: CGPoint, visningspunkt: CGPoint) {
        markør = visningspunkt
        leser.sett(mål: enhetspunkt, fang: false)
    }

    /// Fanger fargen i gjeldende målpunkt (utløserknappen).
    func fang() {
        if let gjeldende { vedFangst?(gjeldende) }
    }

    /// Målpunkt, fokus og eksponering tilbake til midten av bildet.
    func tilbakestillMarkør() {
        let midten = CGPoint(x: 0.5, y: 0.5)
        markør = nil
        fokuser(på: midten)
        leser.sett(mål: midten, fang: false)
    }

    private func konfigurer() {
        økt.beginConfiguration()
        defer { økt.commitConfiguration() }
        økt.sessionPreset = .high
        guard let enhet = Self.velgKamera(),
              let inn = try? AVCaptureDeviceInput(device: enhet), økt.canAddInput(inn)
        else { return }
        grunnZoom = Self.stillInnFokus(enhet)
        zoom = 1
        økt.addInput(inn)
        self.enhet = enhet
        harLykt = enhet.hasTorch
        oppdaterKamerainfo()
        let ut = AVCaptureVideoDataOutput()
        ut.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        ut.alwaysDiscardsLateVideoFrames = true
        ut.setSampleBufferDelegate(leser, queue: kø)
        if økt.canAddOutput(ut) { økt.addOutput(ut) }
        erKonfigurert = true
    }
}

/// Kjører på kamerakøen; rapporterer en farge omtrent 10 ganger i sekundet.
///
/// Bufferne er ikke rotert, så de ligger i sensorens orientering – samme koordinatsystem
/// som `AVCaptureVideoPreviewLayer.captureDevicePointConverted(fromLayerPoint:)` gir.
nonisolated private final class BufferLeser: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    var vedFarge: (@Sendable (Farge, Bool) -> Void)?
    var vedFiltrertBilde: (@Sendable (CGImage) -> Void)?
    var vedStillbilde: (@Sendable (CGImage) -> Void)?
    private var ønskerStillbilde = false
    private var sist = Date.distantPast
    private var filter: [[Double]]?
    private var sistFiltrert = Date.distantPast
    private var orientering: CGImagePropertyOrientation = .right
    private let ciKontekst = CIContext(options: [.cacheIntermediates: false])
    private let utRom = CGColorSpace(name: CGColorSpace.displayP3)!

    func settFilter(_ matrise: [[Double]]?) {
        lås.withLock { filter = matrise; sistFiltrert = .distantPast }
    }

    func settOrientering(vinkel: CGFloat, speilet: Bool) {
        let o: CGImagePropertyOrientation
        switch (Int(vinkel.rounded()) % 360 + 360) % 360 {
        case 90: o = speilet ? .leftMirrored : .right
        case 180: o = speilet ? .downMirrored : .down
        case 270: o = speilet ? .rightMirrored : .left
        default: o = speilet ? .upMirrored : .up
        }
        lås.withLock { orientering = o }
    }

    /// Kamerabildet gjennom fargesynsmatrisen. Core Image arbeider i lineær (utvidet) sRGB, som er
    /// rommet Machado-matrisene er definert i. Nedskalert og ca. 20 bilder i sekundet.
    private func filtrer(_ buffer: CVPixelBuffer, matrise m: [[Double]], orientering: CGImagePropertyOrientation) {
        var bilde = CIImage(cvPixelBuffer: buffer).oriented(orientering)
        let skala = min(1, 900 / max(bilde.extent.width, bilde.extent.height))
        if skala < 1 { bilde = bilde.transformed(by: CGAffineTransform(scaleX: skala, y: skala)) }
        let v = { (rad: [Double]) in CIVector(x: rad[0], y: rad[1], z: rad[2], w: 0) }
        bilde = bilde.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": v(m[0]), "inputGVector": v(m[1]), "inputBVector": v(m[2]),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1), "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0),
        ])
        if let cg = ciKontekst.createCGImage(bilde, from: bilde.extent, format: .RGBA8, colorSpace: utRom) {
            vedFiltrertBilde?(cg)
        }
    }
    private let lås = NSLock()
    private var mål = CGPoint(x: 0.5, y: 0.5)
    private var ventendeFangst = false

    func sett(mål nytt: CGPoint, fang: Bool) {
        lås.withLock {
            // En ventende fangst (klikk) skal ikke avbrytes eller flyttes av at pekeren beveger seg.
            if !fang && ventendeFangst { return }
            mål = CGPoint(x: min(max(nytt.x, 0), 1), y: min(max(nytt.y, 0), 1))
            ventendeFangst = fang
            sist = .distantPast  // les neste bilde med en gang
        }
    }

    func taStillbilde() { lås.withLock { ønskerStillbilde = true } }

    /// Hele bildet, orientert som forhåndsvisningen, i bufferens fargerom.
    private func stillbilde(_ buffer: CVPixelBuffer, orientering: CGImagePropertyOrientation) {
        let bilde = CIImage(cvPixelBuffer: buffer).oriented(orientering)
        let primærer = CVBufferCopyAttachment(buffer, kCVImageBufferColorPrimariesKey, nil) as? String
        let rom = primærer == (kCVImageBufferColorPrimaries_P3_D65 as String) ? utRom : CGColorSpace(name: CGColorSpace.sRGB)!
        if let cg = ciKontekst.createCGImage(bilde, from: bilde.extent, format: .RGBA8, colorSpace: rom) {
            vedStillbilde?(cg)
        }
    }

    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let (stillbilde, stillOrientering) = lås.withLock { () -> (Bool, CGImagePropertyOrientation) in
            defer { ønskerStillbilde = false }
            return (ønskerStillbilde, orientering)
        }
        if stillbilde, let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            self.stillbilde(buffer, orientering: stillOrientering)
        }
        let (matrise, orientering) = lås.withLock { () -> ([[Double]]?, CGImagePropertyOrientation) in
            guard let filter, Date.now.timeIntervalSince(sistFiltrert) >= 0.05 else { return (nil, .up) }
            sistFiltrert = .now
            return (filter, orientering)
        }
        if let matrise, let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            filtrer(buffer, matrise: matrise, orientering: orientering)
        }
        let (punkt, fangst, forTidlig) = lås.withLock { () -> (CGPoint, Bool, Bool) in
            let forTidlig = Date.now.timeIntervalSince(sist) <= 0.1
            if forTidlig { return (mål, false, true) }
            sist = .now
            defer { ventendeFangst = false }
            return (mål, ventendeFangst, false)
        }
        guard !forTidlig, let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(buffer) else { return }
        let bredde = CVPixelBufferGetWidth(buffer), høyde = CVPixelBufferGetHeight(buffer)
        let radbytes = CVPixelBufferGetBytesPerRow(buffer)
        let piksler = base.assumingMemoryBound(to: UInt8.self)

        // Gjennomsnitt i lineært lys over et 9×9-felt rundt målpunktet.
        let halv = 4
        let cx = min(max(Int(punkt.x * Double(bredde)), halv), bredde - 1 - halv)
        let cy = min(max(Int(punkt.y * Double(høyde)), halv), høyde - 1 - halv)
        var sum = (r: 0.0, g: 0.0, b: 0.0), antall = 0.0
        for y in (cy - halv)...(cy + halv) {
            for x in (cx - halv)...(cx + halv) {
                let p = piksler + y * radbytes + x * 4  // BGRA
                sum.b += Self.lineær(p[0]); sum.g += Self.lineær(p[1]); sum.r += Self.lineær(p[2])
                antall += 1
            }
        }
        let gamma = { (v: Double) in v <= 0.0031308 ? v * 12.92 : 1.055 * pow(v, 1 / 2.4) - 0.055 }
        let (r, g, b) = (gamma(sum.r / antall), gamma(sum.g / antall), gamma(sum.b / antall))

        let primærer = CVBufferCopyAttachment(buffer, kCVImageBufferColorPrimariesKey, nil) as? String
        let farge = primærer == (kCVImageBufferColorPrimaries_P3_D65 as String)
            ? Farge(displayP3: DisplayP3(r: r, g: g, b: b))
            : Farge(sRGB: SRGB(r: r, g: g, b: b))
        vedFarge?(farge, fangst)
    }

    private static func lineær(_ v: UInt8) -> Double {
        let c = Double(v) / 255
        return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }
}

// MARK: - Forhåndsvisning

#if canImport(UIKit)
/// Forhåndsvisning som melder trykk som (enhetspunkt, visningspunkt).
struct KameraForhåndsvisning: UIViewRepresentable {
    let økt: AVCaptureSession
    var vedTrykk: (CGPoint, CGPoint) -> Void = { _, _ in }
    /// (skala relativt til start av knipet, om knipet nettopp begynte)
    var vedKnip: (CGFloat, Bool) -> Void = { _, _ in }
    var vedDobbelttrykk: () -> Void = {}
    /// Lag med det fargesynsfiltrerte bildet, og mottaker av forhåndsvisningens orientering.
    var filterlag: CALayer? = nil
    var vedOrientering: (CGFloat, Bool) -> Void = { _, _ in }

    final class Visning: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var lag: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
        var filterlag: CALayer?
        var vedOrientering: (CGFloat, Bool) -> Void = { _, _ in }

        override func layoutSubviews() {
            super.layoutSubviews()
            filterlag?.frame = bounds
            meldOrientering()
        }

        func meldOrientering() {
            guard let k = lag.connection else { return }
            vedOrientering(k.videoRotationAngle, k.isVideoMirrored)
        }
        var vedTrykk: (CGPoint, CGPoint) -> Void = { _, _ in }
        var vedKnip: (CGFloat, Bool) -> Void = { _, _ in }
        var vedDobbelttrykk: () -> Void = {}

        @objc func trykket(_ g: UITapGestureRecognizer) {
            let p = g.location(in: self)
            vedTrykk(lag.captureDevicePointConverted(fromLayerPoint: p), p)
        }

        @objc func knepet(_ g: UIPinchGestureRecognizer) {
            switch g.state {
            case .began: vedKnip(g.scale, true)
            case .changed: vedKnip(g.scale, false)
            default: break
            }
        }

        @objc func dobbelttrykket(_ g: UITapGestureRecognizer) { vedDobbelttrykk() }
    }

    func makeUIView(context: Context) -> Visning {
        let v = Visning()
        v.lag.session = økt
        v.lag.videoGravity = .resizeAspectFill
        let enkelt = UITapGestureRecognizer(target: v, action: #selector(Visning.trykket(_:)))
        let dobbelt = UITapGestureRecognizer(target: v, action: #selector(Visning.dobbelttrykket(_:)))
        dobbelt.numberOfTapsRequired = 2
        enkelt.require(toFail: dobbelt)
        v.addGestureRecognizer(enkelt)
        v.addGestureRecognizer(dobbelt)
        v.addGestureRecognizer(UIPinchGestureRecognizer(target: v, action: #selector(Visning.knepet(_:))))
        v.isAccessibilityElement = true
        v.accessibilityLabel = String(localized: "Kamerabilde. Trykk for å plukke fargen der, knip for å zoome.")
        return v
    }

    func updateUIView(_ uiView: Visning, context: Context) {
        if let filterlag, filterlag.superlayer !== uiView.layer {
            uiView.layer.addSublayer(filterlag)
            filterlag.frame = uiView.bounds
        }
        uiView.filterlag = filterlag
        uiView.vedOrientering = vedOrientering
        uiView.meldOrientering()
        uiView.vedTrykk = vedTrykk
        uiView.vedKnip = vedKnip
        uiView.vedDobbelttrykk = vedDobbelttrykk
    }
}
#elseif canImport(AppKit)
struct KameraForhåndsvisning: NSViewRepresentable {
    let økt: AVCaptureSession
    var vedTrykk: (CGPoint, CGPoint) -> Void = { _, _ in }
    /// Pekeren over forhåndsvisningen (enhetspunkt, visningspunkt): målpunktet følger den.
    var vedSveve: (CGPoint, CGPoint) -> Void = { _, _ in }
    var filterlag: CALayer? = nil
    var vedOrientering: (CGFloat, Bool) -> Void = { _, _ in }

    final class Visning: NSView {
        let lag: AVCaptureVideoPreviewLayer
        var vedTrykk: (CGPoint, CGPoint) -> Void = { _, _ in }
        var vedSveve: (CGPoint, CGPoint) -> Void = { _, _ in }

        init(økt: AVCaptureSession) {
            lag = AVCaptureVideoPreviewLayer(session: økt)
            super.init(frame: .zero)
            lag.videoGravity = .resizeAspectFill
            layer = lag
            wantsLayer = true
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) er ikke støttet") }

        /// Punktet under pekeren som (enhetspunkt, visningspunkt). Visning og lag har begge origo nede
        /// til venstre; SwiftUI har origo oppe til venstre.
        private func punkter(_ event: NSEvent) -> (CGPoint, CGPoint) {
            let p = convert(event.locationInWindow, from: nil)
            return (lag.captureDevicePointConverted(fromLayerPoint: p), CGPoint(x: p.x, y: bounds.height - p.y))
        }

        override func mouseDown(with event: NSEvent) { let (e, v) = punkter(event); vedTrykk(e, v) }
        override func mouseMoved(with event: NSEvent) { let (e, v) = punkter(event); vedSveve(e, v) }

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            trackingAreas.forEach(removeTrackingArea)
            addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseMoved, .activeInKeyWindow, .inVisibleRect],
                                           owner: self))
        }

        override func resetCursorRects() { addCursorRect(bounds, cursor: .crosshair) }

        override func layout() {
            super.layout()
            lag.sublayers?.forEach { $0.frame = lag.bounds }
        }

        /// Første klikk plukker farge også når vinduet ikke er aktivt.
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    }

    func makeNSView(context: Context) -> Visning { Visning(økt: økt) }

    func updateNSView(_ nsView: Visning, context: Context) {
        if let filterlag, filterlag.superlayer !== nsView.lag {
            filterlag.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
            nsView.lag.addSublayer(filterlag)
            filterlag.frame = nsView.lag.bounds
        }
        if let k = nsView.lag.connection { vedOrientering(k.videoRotationAngle, k.isVideoMirrored) }
        nsView.vedTrykk = vedTrykk
        nsView.vedSveve = vedSveve
    }
}
#endif
