# FaceTracker（iPhone 端）

## 兩種模式（主畫面的「僅傳送數據」開關）
- **開啟（預設）**：手機只當追蹤器，把表情數字傳到電腦，不載入、不顯示模型。
- **關閉**：手機也能匯入並顯示 Live2D 模型，使用和電腦版相同的功能：個人校正、參數對應編輯、快捷按鈕、參數手冊、背景、畫質。可選「同時傳送到電腦」。

## 建置（GitHub Actions，不需要 Mac）
1. 把這個資料夾的**內容**放到 GitHub 倉庫根目錄：`project.yml`、`Sources/`（5 個 .swift）、`.github/workflows/build.yml`。
2. Actions 分頁 → Build IPA。
3. Releases → Latest build 下載 `FaceTracker.ipa`，用 AltStore／Sideloadly 側載。

## 使用手機模型功能
1. 關閉「僅傳送數據」。
2. 按「下載執行庫」（一次性，需要網路）。
3. 把模型 zip 在「檔案」App 解壓縮，按「匯入模型」選那個資料夾（要有 .model3.json）。
4. 選模型，按「開啟模型畫面」。右上角齒輪是全部設定。
