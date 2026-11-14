"""測試工具（不需要 iPhone）。
發送模擬資料： python fake_sender.py 127.0.0.1
監聽並顯示收到的封包： python fake_sender.py --listen
"""
import json, math, socket, sys, time

PORT = 39539
NAMES = ["browDownLeft","browDownRight","browInnerUp","browOuterUpLeft","browOuterUpRight",
"cheekPuff","cheekSquintLeft","cheekSquintRight","eyeBlinkLeft","eyeBlinkRight",
"eyeLookDownLeft","eyeLookDownRight","eyeLookInLeft","eyeLookInRight","eyeLookOutLeft","eyeLookOutRight",
"eyeLookUpLeft","eyeLookUpRight","eyeSquintLeft","eyeSquintRight","eyeWideLeft","eyeWideRight",
"jawForward","jawLeft","jawOpen","jawRight","mouthClose",
"mouthFrownLeft","mouthFrownRight","mouthFunnel","mouthLeft","mouthLowerDownLeft","mouthLowerDownRight",
"mouthPressLeft","mouthPressRight","mouthPucker","mouthRight","mouthRollLower","mouthRollUpper",
"mouthShrugLower","mouthShrugUpper","mouthSmileLeft","mouthSmileRight","mouthStretchLeft","mouthStretchRight",
"mouthUpperUpLeft","mouthUpperUpRight","noseSneerLeft","noseSneerRight","tongueOut"]

def listen():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.bind(("0.0.0.0", PORT))
    print(f"監聽 UDP {PORT} ...")
    n = 0
    while True:
        data, addr = s.recvfrom(65535)
        d = json.loads(data)
        n += 1
        if n % 30 == 0:
            bs = dict(zip(NAMES, d["bs"]))
            print(addr[0], f"{len(data)} bytes", "jawOpen=", bs["jawOpen"],
                  "mouthLeft=", bs["mouthLeft"], "head=", d["head"][3:])

def send(host):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    t0 = time.time()
    while True:
        t = time.time() - t0
        bs = [round((math.sin(t * 1.3 + i) + 1) / 2, 3) for i in range(50)]
        head = [0, 0, -0.4, 10 * math.sin(t), 20 * math.sin(t * 0.7), 5 * math.sin(t * 0.5)]
        s.sendto(json.dumps({"v": 1, "bs": bs, "head": head}).encode(), (host, PORT))
        time.sleep(1 / 60)

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--listen":
        listen()
    else:
        send(sys.argv[1] if len(sys.argv) > 1 else "127.0.0.1")
