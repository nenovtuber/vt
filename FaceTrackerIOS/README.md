# FaceTracker（iPhone 端）

## 建置（GitHub Actions，不需要 Mac）
1. 把這個資料夾的**內容**放到 GitHub 倉庫根目錄：`project.yml`、`Sources/`（共 5 個 .swift）、`.github/workflows/build.yml`。
2. Actions 分頁 → Build IPA（push 會自動執行，也可手動 Run workflow）。
3. 完成後到 Releases → Latest build 下載 `FaceTracker.ipa`，用 AltStore／Sideloadly 側載。

## Sources 裡的檔案
- `FaceTrackerApp.swift`：App 進入點
- `ContentView.swift`：主畫面（含「手機顯示 Live2D 模型」開關）
- `Tracker.swift`：臉部追蹤與傳送
- `ModelFeature.swift`：模型匯入、執行庫下載、模型畫面（預設關閉）
- `Live2DHTML.swift`：模型畫面用的網頁（自動產生，內含引擎與設定介面）

## 手機顯示模型
1. 主畫面打開「手機顯示 Live2D 模型（實驗功能）」。
2. 按「下載執行庫」（一次性，需要網路）。
3. 把模型 zip 在「檔案」App 解壓縮，按「匯入模型」選那個資料夾。
4. 選模型，按「開啟模型畫面」。右上角齒輪可調整對應。
