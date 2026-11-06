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

    private let session = ARSession()
    private let arQueue = DispatchQueue(label: "ar.delegate")
    private let netQueue = DispatchQueue(label: "udp.send")
    private var conn: NWConnection?
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

    private let lock = NSLock()
    private var counter = 0
    private var lastTracked: Bool? = nil
    private var timer: Timer?

    func start(host: String, port: UInt16) {
        guard ARFaceTrackingConfiguration.isSupported else {
            connection = "此裝置不支援臉部追蹤（需要 Face ID 機型）"
            return
        }
        guard !host.isEmpty, let p = NWEndpoint.Port(rawValue: port) else {
            connection = "請輸入正確的 IP 與 Port"
            return
        }
        let c = NWConnection(host: NWEndpoint.Host(host), port: p, using: .udp)
        c.stateUpdateHandler = { [weak self] st in
            DispatchQueue.main.async {
                switch st {
                case .ready: self?.connection = "已就緒（UDP 無連線確認，請看電腦端）"
                case .failed(let e): self?.connection = "失敗：\(e.localizedDescription)"
                case .waiting(let e): self?.connection = "等待中：\(e.localizedDescription)"
                default: break
                }
            }
        }
        c.start(queue: netQueue)
        conn = c

        session.delegate = self
        session.delegateQueue = arQueue
        let cfg = ARFaceTrackingConfiguration()
        cfg.maximumNumberOfTrackedFaces = 1
        cfg.isLightEstimationEnabled = false
        cfg.worldAlignment = .camera
        session.run(cfg, options: [.resetTracking, .removeExistingAnchors])

        UIApplication.shared.isIdleTimerDisabled = true
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.lock.lock(); let n = self.counter; self.counter = 0; self.lock.unlock()
            self.sentPerSec = n
        }
    }

    func stop() {
        session.pause()
        conn?.cancel(); conn = nil
        timer?.invalidate(); timer = nil
        UIApplication.shared.isIdleTimerDisabled = false
        isRunning = false
        connection = "未連線"
        faceStatus = "-"
        sentPerSec = 0
    }

    // 只使用 anchor（數字），完全不碰 ARFrame 的相機影像
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let face = anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }

        if lastTracked != face.isTracked {
            lastTracked = face.isTracked
            let t = face.isTracked
            DispatchQueue.main.async { self.faceStatus = t ? "追蹤中" : "找不到臉" }
        }
        guard face.isTracked else { return }

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
        conn?.send(content: json.data(using: .utf8), completion: .idempotent)

        lock.lock(); counter += 1; lock.unlock()
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        DispatchQueue.main.async { self.faceStatus = "錯誤：\(error.localizedDescription)" }
    }
}
