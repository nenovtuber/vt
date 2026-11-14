import SwiftUI
import UIKit

// 注意：這個畫面完全沒有相機預覽元件，只顯示狀態文字。
struct ContentView: View {
    @StateObject private var tracker = Tracker()
    @StateObject private var store = ModelStore()
    @AppStorage("host") private var host = ""
    @AppStorage("port") private var port = "39539"
    @AppStorage("fps") private var fps = 60
    @AppStorage("blackout") private var blackout = true
    @AppStorage("autostart") private var autostart = false
    @AppStorage("sendOnly") private var sendOnly = true      // 僅傳送數據（預設）
    @AppStorage("alsoSend") private var alsoSend = true      // 完整模式下是否同時傳到電腦
    @AppStorage("selectedModel") private var selectedModel = ""

    @State private var dimmed = false
    @State private var savedBrightness: CGFloat = 0.5
    @State private var didAutoStart = false
    @State private var showModel = false
    @State private var showPicker = false
    @State private var localOnlyStarted = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            mainView
            if dimmed { dimOverlay }
        }
        .fullScreenCover(isPresented: $showModel, onDismiss: modelClosed) {
            ModelScreen(modelName: selectedModel,
                        store: store,
                        tracker: tracker,
                        onClose: { showModel = false },
                        onSendOnly: {
                            sendOnly = true
                            showModel = false
                        })
        }
        .sheet(isPresented: $showPicker) {
            FolderPicker { url in
                store.importModel(from: url)
                showPicker = false
            }
        }
        .onAppear {
            if autostart && !didAutoStart && !host.isEmpty && !tracker.isRunning {
                didAutoStart = true
                startAll()
            }
        }
        .onChange(of: scenePhase) { phase in
            // 離開前景時還原亮度（相機在背景也會被系統暫停）
            if phase != .active && dimmed { exitDim() }
        }
    }

    private var mainView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("FaceTracker").font(.largeTitle).bold()
                Text("只傳送表情數字，不顯示、不儲存、不傳送任何影像")
                    .font(.footnote).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                TextField("電腦 IP（例如 192.168.1.20）", text: $host)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numbersAndPunctuation)
                    .autocapitalization(.none).disableAutocorrection(true)
                    .disabled(tracker.isRunning)
                TextField("Port", text: $port)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .disabled(tracker.isRunning)

                VStack(alignment: .leading, spacing: 6) {
                    Text("傳送頻率（省電選 30，要流暢選 60）").font(.footnote).foregroundColor(.secondary)
                    Picker("傳送頻率", selection: $fps) {
                        Text("30").tag(30)
                        Text("60").tag(60)
                    }
                    .pickerStyle(.segmented)
                    .disabled(tracker.isRunning)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Toggle("僅傳送數據", isOn: $sendOnly)
                    Text(sendOnly
                         ? "開啟：手機只當追蹤器，把表情數字傳到電腦，不載入、不顯示模型。"
                         : "關閉：手機也能匯入並顯示 Live2D 模型，並使用個人校正、參數對應、快捷按鈕等和電腦版相同的功能。")
                        .font(.footnote).foregroundColor(.secondary)
                }

                Toggle("開始後黑畫面省電（點一下螢幕離開）", isOn: $blackout)
                Toggle("開啟 App 時自動開始追蹤", isOn: $autostart)

                Button(action: toggle) {
                    Text(tracker.isRunning ? "停止" : "開始追蹤")
                        .frame(maxWidth: .infinity).padding()
                        .background(tracker.isRunning ? Color.red : Color.blue)
                        .foregroundColor(.white).cornerRadius(12)
                }

                modelSection

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(!tracker.isRunning ? Color.gray : (tracker.pcReachable ? Color.green : Color.orange))
                            .frame(width: 12, height: 12)
                        Text("連線：\(tracker.connection)")
                    }
                    Text("臉部：\(tracker.faceStatus)")
                    Text("傳送速率：\(tracker.sentPerSec) 包/秒")
                    Text("追蹤時請保持 App 在前景，切到其他 App 相機會被系統暫停。")
                        .font(.footnote).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

            }
            .padding()
        }
    }

    // MARK: - 手機顯示模型（預設關閉）

    private func actionLabel(_ text: String, _ color: Color) -> some View {
        Text(text)
            .frame(maxWidth: .infinity).padding(10)
            .background(color).foregroundColor(.white).cornerRadius(10)
    }

    private var modelSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !sendOnly {
                Divider()
                Text("手機完整功能（實驗）").font(.headline)
                Toggle("同時傳送到電腦", isOn: $alsoSend)
                Text(store.libsReady ? "執行庫：已安裝 ✓" : "執行庫：尚未安裝（需要網路，約 1～2 MB）")
                    .font(.footnote)
                if !store.libsReady {
                    Button(action: { store.downloadLibs() }) {
                        actionLabel(store.busy ? "下載中…" : "下載執行庫", Color.blue.opacity(0.85))
                    }
                    .disabled(store.busy)
                }
                Button(action: { showPicker = true }) {
                    actionLabel("匯入模型（選擇模型資料夾）", Color.gray)
                }
                if store.models.isEmpty {
                    Text("還沒有模型。請先在「檔案」App 把模型 zip 解壓縮成資料夾，再按上面的按鈕選擇那個資料夾（資料夾裡要有 .model3.json）。")
                        .font(.footnote).foregroundColor(.secondary)
                }
                ForEach(store.models, id: \.self) { name in
                    HStack {
                        Button(action: { selectedModel = name }) {
                            Text((selectedModel == name ? "● " : "○ ") + name)
                        }
                        Spacer()
                        Button("刪除") {
                            store.deleteModel(name)
                            if selectedModel == name { selectedModel = "" }
                        }
                        .foregroundColor(.red)
                    }
                }
                Button(action: openModel) {
                    actionLabel("開啟模型畫面", Color.green.opacity(0.85))
                }
                .disabled(!store.libsReady || selectedModel.isEmpty || !store.models.contains(selectedModel))
                Text("「同時傳送到電腦」開啟且有填電腦 IP 時，會一邊顯示一邊傳到電腦；否則只在手機上顯示。模型畫面右上角的齒輪裡有全部設定，也可以在裡面切回「僅傳送數據」。")
                    .font(.footnote).foregroundColor(.secondary)
                if !store.status.isEmpty {
                    Text(store.status).font(.footnote)
                }
            }
        }
    }

    private func openModel() {
        let trimmed = host.trimmingCharacters(in: .whitespaces)
        if !tracker.isRunning {
            tracker.start(host: trimmed, port: UInt16(port) ?? 39539, fps: fps, sendToPC: alsoSend && !trimmed.isEmpty)
            if !tracker.isRunning { return }   // 啟動失敗（例如裝置不支援臉部追蹤）
            localOnlyStarted = true
        }
        showModel = true
    }

    private func modelClosed() {
        if localOnlyStarted {
            tracker.stop()
            localOnlyStarted = false
        }
    }

    // MARK: - 黑畫面省電

    private var dimOverlay: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 8) {
                Text(tracker.pcReachable ? "追蹤中・電腦已連線" : "追蹤中・等待電腦回應")
                    .foregroundColor(Color(white: 0.3))
                Text("點一下螢幕離開省電模式")
                    .font(.footnote).foregroundColor(Color(white: 0.22))
            }
        }
        .onTapGesture { exitDim() }
    }

    private func enterDim() {
        savedBrightness = UIScreen.main.brightness
        UIScreen.main.brightness = 0.01
        dimmed = true
    }

    private func exitDim() {
        UIScreen.main.brightness = savedBrightness
        dimmed = false
    }

    private func toggle() {
        if tracker.isRunning { stopAll() } else { startAll() }
    }

    private func startAll() {
        tracker.start(host: host.trimmingCharacters(in: .whitespaces),
                      port: UInt16(port) ?? 39539,
                      fps: fps)
        if tracker.isRunning && blackout { enterDim() }
    }

    private func stopAll() {
        tracker.stop()
        if dimmed { exitDim() }
    }
}
