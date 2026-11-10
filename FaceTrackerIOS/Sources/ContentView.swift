import SwiftUI
import UIKit

// 注意：這個畫面完全沒有相機預覽元件，只顯示狀態文字。
struct ContentView: View {
    @StateObject private var tracker = Tracker()
    @AppStorage("host") private var host = ""
    @AppStorage("port") private var port = "39539"
    @AppStorage("fps") private var fps = 60
    @AppStorage("blackout") private var blackout = true
    @AppStorage("autostart") private var autostart = false

    @State private var dimmed = false
    @State private var savedBrightness: CGFloat = 0.5
    @State private var didAutoStart = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            mainView
            if dimmed { dimOverlay }
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

                Toggle("開始後黑畫面省電（點一下螢幕離開）", isOn: $blackout)
                Toggle("開啟 App 時自動開始追蹤", isOn: $autostart)

                Button(action: toggle) {
                    Text(tracker.isRunning ? "停止" : "開始追蹤")
                        .frame(maxWidth: .infinity).padding()
                        .background(tracker.isRunning ? Color.red : Color.blue)
                        .foregroundColor(.white).cornerRadius(12)
                }

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
