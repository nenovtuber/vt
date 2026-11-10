import ARKit
import Network
import Combine
import UIKit

final class Tracker: NSObject, ObservableObject, ARSessionDelegate {
    // 封包中 bs 陣列的固定順序（Windows 端必須使用相同順序）
    static let names: [String] = [
        "browDownLeft", "browDownRight", "browInnerUp", "browOuterUpLeft", "browOuterUpRight",
        "cheekPuff", "cheekSquintLeft", "cheekSquintRight",
        "eyeBlinkLeft", "eyeBlinkRight",
        "eyeLookDownLeft", "eyeLookDownRight", "eyeLookInLeft", "eyeLookInRight",
        "eyeLookOutLeft", "eyeLookOutRight", "eyeLookUpLeft", "eyeLookUpRight",
        "eyeSquintLeft", "eyeSquintRight", "eyeWideLeft", "eyeWideRight",
        "jawForward", "jawLeft", "jawOpen", "jawRight",
        "mouthClose", "mouthFrownLeft", "mouthFrownRight",
        "mouthFunnel", "mouthLeft", "mouthLowerDownLeft", "mouthLowerDownRight",
        "mouthPressLeft", "mouthPressRight", "mouthPucker", "mouthRight",
        "mouthRollLower", "mouthRollUpper", "mouthShrugLower", "mouthShrugUpper",
        "mouthSmileLeft", "mouthSmileRight", "mouthStretchLeft", "mouthStretchRight",
        "mouthUpperUpLeft", "mouthUpperUpRight",
        "noseSneerLeft", "noseSneerRight", "tongueOut"
    ]

    @Published var connection = "未連線"
    @Published var faceStatus = "-"
    @Published var sentPerSec = 0
    @Published var isRunning = false
    @Published var pcReachable = false      // 電腦端有回應（收到 FBACK）

    private let session = ARSession()
    private let arQueue = DispatchQueue(label: "ar.delegate")
    private let netQueue = DispatchQueue(label: "udp.send")

    // 注意：ARKit 的左右參數 rawValue 是 "eyeBlink_L" 這種格式，不能用 "eyeBlinkLeft" 去建立，
    // 必須使用系統提供的常數。順序必須與 names 完全相同。
    private let locations: [ARFaceAnchor.BlendShapeLocation] = [
        .browDownLeft, .browDownRight, .browInnerUp, .browOuterUpLeft, .browOuterUpRight,
        .cheekPuff, .cheekSquintLeft, .cheekSquintRight,
        .eyeBlinkLeft, .eyeBlinkRight,
        .eyeLookDownLeft, .eyeLookDownRight, .eyeLookInLeft, .eyeLookInRight,
        .eyeLookOutLeft, .eyeLookOutRight, .eyeLookUpLeft, .eyeLookUpRight,
        .eyeSquintLeft, .eyeSquintRight, .eyeWideLeft, .eyeWideRight,
        .jawForward, .jawLeft, .jawOpen, .jawRight,
        .mouthClose, .mouthFrownLeft, .mouthFrownRight,
        .mouthFunnel, .mouthLeft, .mouthLowerDownLeft, .mouthLowerDownRight,
        .mouthPressLeft, .mouthPressRight, .mouthPucker, .mouthRight,
        .mouthRollLower, .mouthRollUpper, .mouthShrugLower, .mouthShrugUpper,
        .mouthSmileLeft, .mouthSmileRight, .mouthStretchLeft, .mouthStretchRight,
        .mouthUpperUpLeft, .mouthUpperUpRight,
        .noseSneerLeft, .noseSneerRight, .tongueOut
    ]

    // 以下變數被多個執行緒存取時，用 lock 保護
    private let lock = NSLock()
    private var conn: NWConnection?
    private var counter = 0
    private var lastAck: Date? = nil

    // 只在 arQueue 使用
    private var lastTracked: Bool? = nil
    private var minInterval: Double = 0
    private var lastSend: Double = 0

    // 只在主執行緒使用
    private var host = ""
    private var port: UInt16 = 39539
    private var netReady = false
    private var timer: Timer?

    private func currentConn() -> NWConnection? {
        lock.lock(); defer { lock.unlock() }
        return conn
    }

    // MARK: - 啟動／停止

    func start(host: String, port: UInt16, fps: Int) {
        guard ARFaceTrackingConfiguration.isSupported else {
            connection = "此裝置不支援臉部追蹤（需要 Face ID 機型）"
            return
        }
        guard !host.isEmpty, NWEndpoint.Port(rawValue: port) != nil else {
            connection = "請輸入正確的 IP 與 Port"
            return
        }
        self.host = host
        self.port = port
        arQueue.async {
            self.minInterval = fps >= 60 ? 0 : max(0, 1.0 / Double(max(fps, 1)) - 0.004)
            self.lastSend = 0
            self.lastTracked = nil
        }
        lock.lock(); lastAck = nil; counter = 0; lock.unlock()
        pcReachable = false
        netReady = false
        isRunning = true

        openConnection()

        session.delegate = self
        session.delegateQueue = arQueue
        runSession()

        UIApplication.shared.isIdleTimerDisabled = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
    }

    func stop() {
        isRunning = false
        session.pause()
        lock.lock(); conn?.cancel(); conn = nil; lastAck = nil; lock.unlock()
        timer?.invalidate(); timer = nil
        UIApplication.shared.isIdleTimerDisabled = false
        netReady = false
        pcReachable = false
        connection = "未連線"
        faceStatus = "-"
        sentPerSec = 0
    }

    private func runSession() {
        let cfg = ARFaceTrackingConfiguration()
        cfg.maximumNumberOfTrackedFaces = 1
        cfg.isLightEstimationEnabled = false
        cfg.worldAlignment = .camera
        session.run(cfg, options: [.resetTracking, .removeExistingAnchors])
    }

    // MARK: - 網路

    private func openConnection() {
        guard let p = NWEndpoint.Port(rawValue: port) else { return }
        let c = NWConnection(host: NWEndpoint.Host(host), port: p, using: .udp)
        c.stateUpdateHandler = { [weak self, weak c] st in
            DispatchQueue.main.async {
                guard let self = self, let c = c, self.isRunning, self.currentConn() === c else { return }
                switch st {
                case .ready:
                    self.netReady = true
                    self.connection = "已就緒，等待電腦回應…"
                case .failed(let e):
                    self.netReady = false
                    self.connection = "連線失敗，2 秒後重試：\(e.localizedDescription)"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        if self.isRunning { self.openConnection() }
                    }
                case .waiting(let e):
                    self.netReady = false
                    self.connection = "等待網路：\(e.localizedDescription)"
                default:
                    break
                }
            }
        }
        lock.lock()
        let old = conn
        conn = c
        lock.unlock()
        old?.cancel()
        c.start(queue: netQueue)
        receiveLoop(c)
    }

    // 電腦端每秒會回一個 "FBACK"，用來確認真的連得到
    private func receiveLoop(_ c: NWConnection) {
        c.receiveMessage { [weak self, weak c] data, _, _, error in
            guard let self = self, let c = c else { return }
            if let d = data, d.count >= 5, d.starts(with: Array("FBACK".utf8)) {
                self.lock.lock(); self.lastAck = Date(); self.lock.unlock()
            }
            if error == nil, self.currentConn() === c { self.receiveLoop(c) }
        }
    }

    private func tick() {
        lock.lock()
        let n = counter; counter = 0
        let ack = lastAck
        lock.unlock()
        sentPerSec = n
        let alive = ack.map { Date().timeIntervalSince($0) < 3 } ?? false
        pcReachable = alive
        if netReady {
            connection = alive ? "電腦已回應 ✓" : "已送出，但電腦沒回應（檢查 IP、防火牆、是否同一個 Wi-Fi）"
        }
    }

    // MARK: - ARSessionDelegate

    // 只使用 anchor（數字），完全不碰 ARFrame 的相機影像
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let face = anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }

        if lastTracked != face.isTracked {
            lastTracked = face.isTracked
            let t = face.isTracked
            DispatchQueue.main.async { self.faceStatus = t ? "追蹤中" : "找不到臉" }
        }
        guard face.isTracked else { return }

        if minInterval > 0 {
            let now = CACurrentMediaTime()
            if now - lastSend < minInterval { return }
            lastSend = now
        }

        var parts = [String]()
        parts.reserveCapacity(50)
        for loc in locations {
            let v = face.blendShapes[loc]?.floatValue ?? 0
            parts.append(String(format: "%.3f", v))
        }

        let m = face.transform
        let rad2deg: Float = 180 / .pi
        let pitch = atan2(m.columns.1.z, m.columns.2.z) * rad2deg
        let yaw = asin(max(-1, min(1, -m.columns.0.z))) * rad2deg
        let roll = atan2(m.columns.0.y, m.columns.0.x) * rad2deg
        let head = [m.columns.3.x, m.columns.3.y, m.columns.3.z, pitch, yaw, roll]
            .map { String(format: "%.3f", $0) }.joined(separator: ",")

        let json = "{\"v\":1,\"bs\":[\(parts.joined(separator: ","))],\"head\":[\(head)]}"
        currentConn()?.send(content: json.data(using: .utf8), completion: .idempotent)

        lock.lock(); counter += 1; lock.unlock()
    }

    func sessionWasInterrupted(_ session: ARSession) {
        DispatchQueue.main.async { self.faceStatus = "暫停（被系統中斷，例如來電或切換 App）" }
    }

    // 中斷結束後自動恢復追蹤
    func sessionInterruptionEnded(_ session: ARSession) {
        arQueue.async { self.lastTracked = nil }
        DispatchQueue.main.async { if self.isRunning { self.runSession() } }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.faceStatus = "錯誤：\(error.localizedDescription)，重新啟動中…"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if self.isRunning { self.runSession() }
            }
        }
    }
}
