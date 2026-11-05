# FaceTracker（iPhone 端）

## 取得 .ipa
1. 建立**公開** GitHub 倉庫，把這個資料夾全部上傳。
2. Actions 分頁 → Build IPA → 完成後下載 artifact `FaceTracker-ipa`。
3. 用 AltStore 側載 `FaceTracker.ipa`。

## 封包格式（UDP，port 39539）
`{"v":1,"bs":[50 個 0~1 數值],"head":[x,y,z,pitch,yaw,roll]}`
bs 順序見 `Tracker.names`。head 位置單位為公尺、角度為度。

## 測試
`python tools/fake_sender.py --listen` 監聽；iPhone 填電腦 IP 即可看到數值。
沒有 iPhone 時：`python tools/fake_sender.py 127.0.0.1`
