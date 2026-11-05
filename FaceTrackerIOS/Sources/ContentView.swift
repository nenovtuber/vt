import SwiftUI

// 注意：這個畫面完全沒有相機預覽元件，只顯示狀態文字。
struct ContentView: View {
    @StateObject private var tracker = Tracker()
    @AppStorage("host") private var host = ""
    @AppStorage("port") private var port = "39539"

    var body: some View {
        VStack(spacing: 20) {
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

            Button(action: toggle) {
                Text(tracker.isRunning ? "停止" : "開始追蹤")
                    .frame(maxWidth: .infinity).padding()
                    .background(tracker.isRunning ? Color.red : Color.blue)
                    .foregroundColor(.white).cornerRadius(12)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("連線：\(tracker.connection)")
                Text("臉部：\(tracker.faceStatus)")
                Text("傳送速率：\(tracker.sentPerSec) 包/秒")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
        }
        .padding()
    }

    private func toggle() {
        if tracker.isRunning {
            tracker.stop()
        } else {
            tracker.start(host: host.trimmingCharacters(in: .whitespaces),
                          port: UInt16(port) ?? 39539)
        }
    }
}
