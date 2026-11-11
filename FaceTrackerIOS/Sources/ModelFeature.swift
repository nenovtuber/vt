import SwiftUI
import WebKit
import UIKit
import UniformTypeIdentifiers

// 手機端「顯示 Live2D 模型」功能。
// 預設關閉；關閉時完全不會載入或使用這裡的任何東西。
// Live2D 的執行庫（Cubism Core）不隨 App 附帶，而是在你的手機上從官方網址下載。

enum ModelPaths {
    static var docs: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] }
    static var libs: URL { docs.appendingPathComponent("Libs", isDirectory: true) }
    static var models: URL { docs.appendingPathComponent("Models", isDirectory: true) }
    static var profiles: URL { docs.appendingPathComponent("Profiles", isDirectory: true) }
}

// MARK: - 模型與執行庫管理

final class ModelStore: ObservableObject {
    // 檔名與下載網址。pixi.js 需要 6.x，pixi-live2d-display 的 cubism4 版本需要 Live2D 官方的 Core。
    static let libFiles: [(String, String)] = [
        ("live2dcubismcore.min.js", "https://cubism.live2d.com/sdk-web/cubismcore/live2dcubismcore.min.js"),
        ("pixi.min.js", "https://cdn.jsdelivr.net/npm/pixi.js@6/dist/browser/pixi.min.js"),
        ("cubism4.min.js", "https://cdn.jsdelivr.net/npm/pixi-live2d-display/dist/cubism4.min.js")
    ]

    @Published var libsReady = false
    @Published var models: [String] = []
    @Published var status = ""
    @Published var busy = false

    init() { refresh() }

    func refresh() {
        let fm = FileManager.default
        try? fm.createDirectory(at: ModelPaths.libs, withIntermediateDirectories: true)
        try? fm.createDirectory(at: ModelPaths.models, withIntermediateDirectories: true)
        try? fm.createDirectory(at: ModelPaths.profiles, withIntermediateDirectories: true)
        libsReady = ModelStore.libFiles.allSatisfy {
            fm.fileExists(atPath: ModelPaths.libs.appendingPathComponent($0.0).path)
        }
        let items = (try? fm.contentsOfDirectory(atPath: ModelPaths.models.path)) ?? []
        models = items.filter { findModelJSON($0) != nil }.sorted()
    }

    // 回傳模型資料夾內 .model3.json 的相對路徑
    func findModelJSON(_ name: String) -> String? {
        let base = ModelPaths.models.appendingPathComponent(name, isDirectory: true)
        guard let en = FileManager.default.enumerator(at: base, includingPropertiesForKeys: nil) else { return nil }
        let marker = "/Models/" + name + "/"
        for case let u as URL in en {
            if u.lastPathComponent.hasSuffix(".model3.json"), let r = u.path.range(of: marker) {
                return String(u.path[r.upperBound...])
            }
        }
        return nil
    }

    func importModel(from url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let name = url.lastPathComponent
        let dest = ModelPaths.models.appendingPathComponent(name, isDirectory: true)
        let fm = FileManager.default
        do {
            if fm.fileExists(atPath: dest.path) { try fm.removeItem(at: dest) }
            try fm.copyItem(at: url, to: dest)
            if findModelJSON(name) == nil {
                try? fm.removeItem(at: dest)
                status = "這個資料夾裡找不到 .model3.json，請選擇模型的主資料夾"
            } else {
                status = "已匯入：\(name)"
            }
        } catch {
            status = "匯入失敗：\(error.localizedDescription)（檔案需要已下載到手機，不能只在雲端）"
        }
        refresh()
    }

    func deleteModel(_ name: String) {
        let fm = FileManager.default
        try? fm.removeItem(at: ModelPaths.models.appendingPathComponent(name, isDirectory: true))
        try? fm.removeItem(at: profileURL(name))
        refresh()
    }

    func downloadLibs() {
        if busy { return }
        busy = true
        status = "下載執行庫中…"
        let group = DispatchGroup()
        let lock = NSLock()
        var errors = [String]()
        for (name, urlString) in ModelStore.libFiles {
            guard let url = URL(string: urlString) else { continue }
            group.enter()
            URLSession.shared.dataTask(with: url) { data, resp, err in
                defer { group.leave() }
                let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
                if let d = data, code == 200, d.count > 10_000 {
                    do { try d.write(to: ModelPaths.libs.appendingPathComponent(name), options: .atomic) }
                    catch {
                        lock.lock(); errors.append("\(name)：\(error.localizedDescription)"); lock.unlock()
                    }
                } else {
                    lock.lock()
                    errors.append("\(name)：下載失敗（\(err?.localizedDescription ?? "HTTP \(code)")）")
                    lock.unlock()
                }
            }.resume()
        }
        group.notify(queue: .main) {
            self.busy = false
            self.refresh()
            self.status = errors.isEmpty ? "執行庫下載完成" : errors.joined(separator: "\n")
        }
    }

    // 每個模型各自的對應設定（由網頁端產生的 JSON）
    private func profileURL(_ name: String) -> URL {
        ModelPaths.profiles.appendingPathComponent(name.replacingOccurrences(of: "/", with: "_") + ".json")
    }
    func loadProfile(name: String) -> String {
        (try? String(contentsOf: profileURL(name), encoding: .utf8)) ?? ""
    }
    func saveProfile(name: String, json: String) {
        try? json.write(to: profileURL(name), atomically: true, encoding: .utf8)
    }
}

// MARK: - 選擇模型資料夾

struct FolderPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let vc = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.folder], asCopy: false)
        vc.delegate = context.coordinator
        vc.allowsMultipleSelection = false
        return vc
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let u = urls.first { onPick(u) }
        }
    }
}

// MARK: - 網頁端用的自訂網址（fb://app/...）

final class FBSchemeHandler: NSObject, WKURLSchemeHandler {
    var indexHTML = ""

    static func mime(for ext: String) -> String {
        switch ext.lowercased() {
        case "json": return "application/json"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "js": return "application/javascript"
        default: return "application/octet-stream"
        }
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(URLError(.badURL))
            return
        }
        let path = url.path
        var data: Data? = nil
        var mime = "application/octet-stream"

        if path == "/index.html" || path == "/" {
            data = indexHTML.data(using: .utf8)
            mime = "text/html; charset=utf-8"
        } else if path.hasPrefix("/lib/") {
            let name = String(path.dropFirst(5))
            if !name.contains("/") && !name.contains("..") {
                data = try? Data(contentsOf: ModelPaths.libs.appendingPathComponent(name))
                mime = "application/javascript"
            }
        } else if path.hasPrefix("/models/") {
            let rel = String(path.dropFirst(8))
            if !rel.contains("..") {
                let fileURL = ModelPaths.models.appendingPathComponent(rel)
                data = try? Data(contentsOf: fileURL)
                mime = FBSchemeHandler.mime(for: fileURL.pathExtension)
            }
        }

        guard let body = data else {
            if let resp = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: nil) {
                urlSchemeTask.didReceive(resp)
            }
            urlSchemeTask.didFinish()
            return
        }
        let headers = ["Content-Type": mime,
                       "Content-Length": "\(body.count)",
                       "Access-Control-Allow-Origin": "*"]
        if let resp = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers) {
            urlSchemeTask.didReceive(resp)
            urlSchemeTask.didReceive(body)
        }
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
}

// MARK: - 網頁控制器（把追蹤數值送進網頁、接收網頁的儲存要求）

final class Live2DController: NSObject, ObservableObject, WKScriptMessageHandler {
    let webView: WKWebView
    private let handler: FBSchemeHandler
    private var ready = false
    private var closed = false
    private var pendingLoad: String? = nil
    private let lock = NSLock()
    private var inFlight = false
    var onSaveProfile: ((String) -> Void)?

    override init() {
        let cfg = WKWebViewConfiguration()
        let h = FBSchemeHandler()
        cfg.setURLSchemeHandler(h, forURLScheme: "fb")
        cfg.allowsInlineMediaPlayback = true
        webView = WKWebView(frame: .zero, configuration: cfg)
        handler = h
        super.init()
        h.indexHTML = Live2DHTML.page
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.configuration.userContentController.add(self, name: "fb")
        if let u = URL(string: "fb://app/index.html") {
            webView.load(URLRequest(url: u))
        }
    }

    func load(path: String, name: String, profile: String) {
        let obj: [String: Any] = ["path": path, "name": name, "profile": profile]
        guard let data = try? JSONSerialization.data(withJSONObject: obj),
              let json = String(data: data, encoding: .utf8) else { return }
        let js = "fb.load(\(json));"
        if ready { webView.evaluateJavaScript(js, completionHandler: nil) } else { pendingLoad = js }
    }

    func flush() {
        if ready { webView.evaluateJavaScript("fb.flush();", completionHandler: nil) }
    }

    // 可在任何執行緒呼叫；來不及處理的幀會直接丟掉，不會堆積
    func receive(_ bs: [Float], _ head: [Float]) {
        lock.lock()
        if inFlight || !ready || closed { lock.unlock(); return }
        inFlight = true
        lock.unlock()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let a = bs.map { String(format: "%.3f", $0) }.joined(separator: ",")
            let b = head.map { String(format: "%.3f", $0) }.joined(separator: ",")
            self.webView.evaluateJavaScript("fb.update([\(a)],[\(b)]);", completionHandler: nil)
            self.lock.lock(); self.inFlight = false; self.lock.unlock()
        }
    }

    func shutdown() {
        closed = true
        onSaveProfile = nil
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "fb")
        webView.stopLoading()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], let type = body["type"] as? String else { return }
        switch type {
        case "ready":
            ready = true
            if let js = pendingLoad {
                pendingLoad = nil
                webView.evaluateJavaScript(js, completionHandler: nil)
            }
        case "save":
            if let p = body["profile"] as? String { onSaveProfile?(p) }
        default:
            break
        }
    }
}

struct Live2DWebView: UIViewRepresentable {
    let controller: Live2DController
    func makeUIView(context: Context) -> WKWebView { controller.webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// MARK: - 模型畫面（全螢幕）

struct ModelScreen: View {
    let modelName: String
    let store: ModelStore
    let tracker: Tracker
    let onClose: () -> Void
    @StateObject private var controller = Live2DController()

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            Live2DWebView(controller: controller).ignoresSafeArea()
            Button(action: close) {
                Text("關閉")
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Color.black.opacity(0.55))
                    .foregroundColor(.white)
                    .cornerRadius(18)
            }
            .padding(.leading, 12).padding(.top, 8)
        }
        .onAppear { start() }
        .onDisappear { stop() }
    }

    private func start() {
        let name = modelName
        let st = store
        controller.onSaveProfile = { json in st.saveProfile(name: name, json: json) }
        let ctrl = controller
        tracker.setFrameHandler { [weak ctrl] bs, head in ctrl?.receive(bs, head) }
        if let path = store.findModelJSON(modelName) {
            controller.load(path: path, name: modelName, profile: store.loadProfile(name: modelName))
        }
    }

    private func stop() {
        tracker.setFrameHandler(nil)
        controller.shutdown()
    }

    private func close() {
        controller.flush()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { onClose() }
    }
}
