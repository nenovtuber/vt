// 由產生器建立：手機端模型顯示用的網頁（內含引擎與介面腳本）。
// 使用原始字串，內容中的反斜線不需要跳脫。
enum Live2DHTML {
    static let page = #"""
<!doctype html>
<html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no,viewport-fit=cover">
<style>
html,body{margin:0;height:100%;overflow:hidden;background:#000;font-family:-apple-system,sans-serif;color:#eee;-webkit-user-select:none;user-select:none}
canvas{position:fixed;left:0;top:0;width:100%;height:100%;touch-action:none}
#msg{position:fixed;left:12px;right:12px;bottom:calc(env(safe-area-inset-bottom) + 16px);background:rgba(0,0,0,.7);padding:8px 12px;border-radius:10px;font-size:13px;display:none;z-index:5}
#gear{position:fixed;top:calc(env(safe-area-inset-top) + 8px);right:12px;z-index:6;width:44px;height:44px;border-radius:22px;border:0;background:rgba(0,0,0,.55);color:#fff;font-size:22px}
#hk{position:fixed;left:8px;top:calc(env(safe-area-inset-top) + 64px);z-index:6;display:flex;flex-direction:column;gap:8px}
.hkb{padding:10px 14px;border-radius:18px;border:0;background:rgba(0,0,0,.55);color:#fff;font-size:14px}
.hkb.on{background:#2a7}
#panel{position:fixed;left:0;right:0;bottom:0;max-height:72vh;overflow:auto;-webkit-overflow-scrolling:touch;background:rgba(18,18,22,.96);z-index:7;padding:12px 12px calc(env(safe-area-inset-bottom) + 16px);font-size:13px;box-sizing:border-box;border-radius:16px 16px 0 0}
.hide{display:none !important}
.row{display:flex;align-items:center;gap:8px;margin:6px 0;flex-wrap:wrap}
details.sec{border-top:1px solid #333;margin:6px 0;padding:2px 0}
details.sec>summary{font-weight:700;color:#8cf;padding:8px 0;list-style:none}
details.sec>summary::-webkit-details-marker{display:none}
.grp{margin:10px 0 2px;color:#fc8;font-weight:700}
.map{border:1px solid #444;border-radius:10px;padding:6px 8px;margin:8px 0}
.brief{color:#aaa;font-size:12px;margin:2px 0}
.sl{display:flex;align-items:center;gap:6px;margin:4px 0}
.sl .lab{width:72px;flex:none}
.sl input{flex:1;min-width:0}
.val{color:#9f9;min-width:60px;font-size:12px}
.bar{flex:1;min-width:40px;height:8px;background:#333;border-radius:4px;overflow:hidden}
.bar i{display:block;height:100%;background:#6c6;width:0}
select,button,input[type=text]{font-size:13px;padding:6px 8px;border-radius:8px;border:1px solid #555;background:#2a2a30;color:#eee;max-width:100%}
select,input[type=text]{flex:1;min-width:0}
.chk{display:flex;align-items:center;gap:6px;margin:4px 0}
</style></head><body>
<canvas id="c"></canvas>
<div id="msg"></div>
<div id="hk"></div>
<button id="gear">&#9881;</button>
<div id="panel" class="hide"></div>
<script src="lib/live2dcubismcore.min.js"></script>
<script src="lib/pixi.min.js"></script>
<script src="lib/cubism4.min.js"></script>
<script>
(function (root) {
'use strict';
const BLEND = ["browDownLeft","browDownRight","browInnerUp","browOuterUpLeft","browOuterUpRight","cheekPuff","cheekSquintLeft","cheekSquintRight","eyeBlinkLeft","eyeBlinkRight","eyeLookDownLeft","eyeLookDownRight","eyeLookInLeft","eyeLookInRight","eyeLookOutLeft","eyeLookOutRight","eyeLookUpLeft","eyeLookUpRight","eyeSquintLeft","eyeSquintRight","eyeWideLeft","eyeWideRight","jawForward","jawLeft","jawOpen","jawRight","mouthClose","mouthFrownLeft","mouthFrownRight","mouthFunnel","mouthLeft","mouthLowerDownLeft","mouthLowerDownRight","mouthPressLeft","mouthPressRight","mouthPucker","mouthRight","mouthRollLower","mouthRollUpper","mouthShrugLower","mouthShrugUpper","mouthSmileLeft","mouthSmileRight","mouthStretchLeft","mouthStretchRight","mouthUpperUpLeft","mouthUpperUpRight","noseSneerLeft","noseSneerRight","tongueOut"];
const HEAD = ["headX","headY","headZ","headPitch","headYaw","headRoll"];
const DERIVED = ["teethClench","mouthTwist","jawSide","mouthSmile","mouthFrown","eyeLookX","eyeLookY","eyeSmileLeft","eyeSmileRight","eyeSmile","browLeftY","browRightY","browAngry","browSad","browSurprise","browAngleLeft","browAngleRight","browMood"];
const ALL = BLEND.concat(HEAD, DERIVED);
const INFO = {"eyeBlinkLeft": ["眼睛", "眨眼（左）", "左眼閉合程度，0＝睜開，1＝完全閉上。", "眨左眼或閉上左眼。", "ParamEyeLOpen，輸出範圍要設成 1→0。"], "eyeBlinkRight": ["眼睛", "眨眼（右）", "右眼閉合程度，0＝睜開，1＝完全閉上。", "眨右眼或閉上右眼。", "ParamEyeROpen，輸出範圍要設成 1→0。"], "eyeSquintLeft": ["眼睛", "瞇眼（左）", "左眼下眼瞼上提，眼睛變小。", "用力瞇左眼，或笑到眼睛瞇起來。", "瞇眼表情；笑眼建議用衍生的 eyeSmileLeft。"], "eyeSquintRight": ["眼睛", "瞇眼（右）", "右眼下眼瞼上提，眼睛變小。", "用力瞇右眼，或笑到眼睛瞇起來。", "瞇眼表情；笑眼建議用衍生的 eyeSmileRight。"], "eyeWideLeft": ["眼睛", "睜大眼（左）", "左眼上眼瞼上提，眼睛比平常睜得更大。", "做出驚訝、瞪大眼睛的樣子。", "驚訝表情、放大眼睛的參數。"], "eyeWideRight": ["眼睛", "睜大眼（右）", "右眼上眼瞼上提，眼睛比平常睜得更大。", "做出驚訝、瞪大眼睛的樣子。", "驚訝表情、放大眼睛的參數。"], "eyeLookUpLeft": ["眼睛", "視線向上（左眼）", "左眼珠往上看。", "頭不動，眼睛往上看。", "通常用衍生的 eyeLookY 接 ParamEyeBallY。"], "eyeLookUpRight": ["眼睛", "視線向上（右眼）", "右眼珠往上看。", "頭不動，眼睛往上看。", "通常用衍生的 eyeLookY 接 ParamEyeBallY。"], "eyeLookDownLeft": ["眼睛", "視線向下（左眼）", "左眼珠往下看。", "頭不動，眼睛往下看。", "通常用衍生的 eyeLookY 接 ParamEyeBallY。"], "eyeLookDownRight": ["眼睛", "視線向下（右眼）", "右眼珠往下看。", "頭不動，眼睛往下看。", "通常用衍生的 eyeLookY 接 ParamEyeBallY。"], "eyeLookInLeft": ["眼睛", "視線向內（左眼）", "左眼珠往鼻子方向轉。", "眼睛往鼻子方向看。", "通常用衍生的 eyeLookX 接 ParamEyeBallX。"], "eyeLookInRight": ["眼睛", "視線向內（右眼）", "右眼珠往鼻子方向轉。", "眼睛往鼻子方向看。", "通常用衍生的 eyeLookX 接 ParamEyeBallX。"], "eyeLookOutLeft": ["眼睛", "視線向外（左眼）", "左眼珠往耳朵方向轉。", "眼睛往旁邊看。", "通常用衍生的 eyeLookX 接 ParamEyeBallX。"], "eyeLookOutRight": ["眼睛", "視線向外（右眼）", "右眼珠往耳朵方向轉。", "眼睛往旁邊看。", "通常用衍生的 eyeLookX 接 ParamEyeBallX。"], "browDownLeft": ["眉毛", "皺眉（左）", "左邊眉毛往下壓。", "皺眉、生氣、專注。", "ParamBrowLY 的負向（往下）；或衍生的 browAngry。"], "browDownRight": ["眉毛", "皺眉（右）", "右邊眉毛往下壓。", "皺眉、生氣、專注。", "ParamBrowRY 的負向（往下）；或衍生的 browAngry。"], "browInnerUp": ["眉毛", "內眉上提（雙邊）", "兩邊眉頭一起上揚，形成八字眉。", "做出擔心、委屈、困擾的表情。", "困擾表情；衍生的 browSad 已扣掉皺眉成分。"], "browOuterUpLeft": ["眉毛", "挑眉（左）", "左邊眉尾往上揚。", "單挑左眉，或驚訝時把眉毛抬高。", "ParamBrowLY 的正向（往上）。"], "browOuterUpRight": ["眉毛", "挑眉（右）", "右邊眉尾往上揚。", "單挑右眉，或驚訝時把眉毛抬高。", "ParamBrowRY 的正向（往上）。"], "cheekPuff": ["臉頰與鼻子", "鼓頰", "兩邊臉頰鼓起的程度。", "嘴巴閉著，把空氣吹進臉頰。", "ParamCheek 或鼓頰參數。"], "cheekSquintLeft": ["臉頰與鼻子", "臉頰上提（左）", "左臉頰被往上推，常在微笑時出現。", "開心地用力微笑。", "笑眼的主要來源，見 eyeSmileLeft。"], "cheekSquintRight": ["臉頰與鼻子", "臉頰上提（右）", "右臉頰被往上推，常在微笑時出現。", "開心地用力微笑。", "笑眼的主要來源，見 eyeSmileRight。"], "noseSneerLeft": ["臉頰與鼻子", "皺鼻（左）", "左側鼻翼上提。", "做出嫌棄、厭惡的表情。", "自訂的皺鼻參數。"], "noseSneerRight": ["臉頰與鼻子", "皺鼻（右）", "右側鼻翼上提。", "做出嫌棄、厭惡的表情。", "自訂的皺鼻參數。"], "jawOpen": ["下巴", "張嘴（下巴張開）", "下巴往下的程度，0＝閉嘴，1＝最大張開。", "張嘴、說話。", "最常接 ParamMouthOpenY。"], "jawForward": ["下巴", "下巴前伸", "下巴往前推（戽斗）。", "下巴往前伸出。", "自訂參數，很少用。"], "jawLeft": ["下巴", "下巴往左", "下巴往左側移。", "下巴往左挪。", "想要單一正負值，請用衍生的 jawSide。"], "jawRight": ["下巴", "下巴往右", "下巴往右側移。", "下巴往右挪。", "想要單一正負值，請用衍生的 jawSide。"], "mouthClose": ["嘴巴", "嘴唇閉合", "下巴張開時，嘴唇仍閉上的程度。", "張開下巴但把嘴唇閉著，像發「ㄇ」的音。", "一般不單獨使用；下巴閉著時它也是 0。"], "mouthFunnel": ["嘴巴", "圓口（發「喔」）", "嘴唇收成圓形並微微張開。", "發「喔」「哇」的口型。", "O 形嘴型參數。"], "mouthPucker": ["嘴巴", "嘟嘴", "嘴唇往前噘起、變小。", "親親，或發「嗚」的口型。", "ParamMouthPucker 或嘟嘴參數。"], "mouthLeft": ["嘴巴", "嘴巴往左歪", "整個嘴巴往左側偏。", "把嘴巴往左邊歪。", "要單一正負值，請用衍生的 mouthTwist。"], "mouthRight": ["嘴巴", "嘴巴往右歪", "整個嘴巴往右側偏。", "把嘴巴往右邊歪。", "要單一正負值，請用衍生的 mouthTwist。"], "mouthSmileLeft": ["嘴巴", "微笑（左嘴角）", "左嘴角上揚。", "單邊微笑或一般微笑。", "ParamMouthForm 的正向；雙邊平均見 mouthSmile。"], "mouthSmileRight": ["嘴巴", "微笑（右嘴角）", "右嘴角上揚。", "單邊微笑或一般微笑。", "ParamMouthForm 的正向；雙邊平均見 mouthSmile。"], "mouthFrownLeft": ["嘴巴", "嘴角下壓（左）", "左嘴角往下拉。", "難過、不開心、撇嘴。", "ParamMouthForm 的負向；雙邊平均見 mouthFrown。"], "mouthFrownRight": ["嘴巴", "嘴角下壓（右）", "右嘴角往下拉。", "難過、不開心、撇嘴。", "ParamMouthForm 的負向；雙邊平均見 mouthFrown。"], "mouthStretchLeft": ["嘴巴", "嘴角橫拉（左）", "左嘴角往側邊拉開。", "發「咿」的口型、露齒、害怕的表情。", "露齒、咬牙表情的來源之一。"], "mouthStretchRight": ["嘴巴", "嘴角橫拉（右）", "右嘴角往側邊拉開。", "發「咿」的口型、露齒、害怕的表情。", "露齒、咬牙表情的來源之一。"], "mouthPressLeft": ["嘴巴", "抿嘴（左）", "左側嘴唇用力壓緊。", "用力閉緊嘴唇、忍耐的樣子。", "抿嘴、忍耐表情。"], "mouthPressRight": ["嘴巴", "抿嘴（右）", "右側嘴唇用力壓緊。", "用力閉緊嘴唇、忍耐的樣子。", "抿嘴、忍耐表情。"], "mouthUpperUpLeft": ["嘴巴", "上唇上提（左）", "左側上唇往上抬，露出上排牙。", "露出上排牙齒、齜牙。", "露牙、咬牙表情的來源之一。"], "mouthUpperUpRight": ["嘴巴", "上唇上提（右）", "右側上唇往上抬，露出上排牙。", "露出上排牙齒、齜牙。", "露牙、咬牙表情的來源之一。"], "mouthLowerDownLeft": ["嘴巴", "下唇下壓（左）", "左側下唇往下，露出下排牙。", "露出下排牙齒；張嘴時也會出現。", "露牙表情。"], "mouthLowerDownRight": ["嘴巴", "下唇下壓（右）", "右側下唇往下，露出下排牙。", "露出下排牙齒；張嘴時也會出現。", "露牙表情。"], "mouthRollUpper": ["嘴巴", "上唇內捲", "上唇往內收進嘴裡。", "把上嘴唇包進嘴裡。", "自訂參數，很少用。"], "mouthRollLower": ["嘴巴", "下唇內捲", "下唇往內收進嘴裡。", "把下嘴唇包進嘴裡。", "自訂參數，很少用。"], "mouthShrugUpper": ["嘴巴", "上唇聳起", "上唇往前上推。", "撇嘴、不屑地噘起上唇。", "自訂參數。"], "mouthShrugLower": ["嘴巴", "下唇聳起", "下唇往上推，下巴會皺起。", "一臉不滿、委屈地噘下唇。", "自訂參數。"], "tongueOut": ["舌頭", "吐舌", "舌頭伸出嘴外的程度；只能偵測伸出，無法偵測舌頭位置。", "把舌頭吐出來。", "ParamTongueOut 或吐舌參數。"], "headX": ["頭部", "頭部左右位置", "頭相對於校正點往左右移動的距離（公尺）。", "頭或身體往左右平移。", "少用；可接身體左右晃動。"], "headY": ["頭部", "頭部上下位置", "頭相對於校正點往上下移動的距離（公尺）。", "頭往上或往下移動。", "少用；可接身體上下晃動。"], "headZ": ["頭部", "頭部前後位置", "頭靠近或遠離 iPhone 的距離（公尺）。", "頭往前湊近，或往後退。", "可接身體前傾、模型縮放。"], "headPitch": ["頭部", "點頭／抬頭", "頭上下轉動的角度（度）。", "點頭、抬頭。", "ParamAngleY（通常要勾「反向」）。"], "headYaw": ["頭部", "搖頭／轉頭", "頭左右轉動的角度（度）。", "左右轉頭。", "ParamAngleX（通常要勾「反向」）。"], "headRoll": ["頭部", "歪頭", "頭往左右肩膀傾斜的角度（度）。", "把頭歪向一邊。", "ParamAngleZ。"], "teethClench": ["衍生：嘴與下巴", "咬牙", "下巴閉著、嘴唇分開露出牙齒的程度，由程式推算，不是 ARKit 直接輸出。", "咬緊牙齒，嘴角往兩側拉開露出牙齒（像發「嘶」）。", "模型的牙齒或咬牙參數；門檻在設定區的「咬牙判定」調整。"], "mouthTwist": ["衍生：嘴與下巴", "歪嘴（單一數值）", "嘴巴左右歪斜：-1＝往左，+1＝往右，0＝正中。", "把嘴巴往左或往右歪。", "ParamMouthX 之類的左右歪嘴參數。"], "jawSide": ["衍生：嘴與下巴", "下巴左右（單一數值）", "下巴左右偏移：-1＝往左，+1＝往右。", "下巴往左或往右挪。", "下巴左右參數。"], "mouthSmile": ["衍生：嘴與下巴", "微笑（左右平均）", "兩邊嘴角上揚的平均，只看嘴角，不含眼睛。", "微笑。", "ParamMouthForm 的正向。"], "mouthFrown": ["衍生：嘴與下巴", "不悅（左右平均）", "兩邊嘴角下壓的平均。", "嘴角往下拉。", "ParamMouthForm 的負向。"], "eyeLookX": ["衍生：眼睛", "視線左右（單一數值）", "兩眼合併的左右視線：-1＝看左，+1＝看右。", "眼睛看左邊或右邊。", "ParamEyeBallX（預設已翻轉，方向不對就切換「反向」）。"], "eyeLookY": ["衍生：眼睛", "視線上下（單一數值）", "兩眼合併的上下視線：正值往上，負值往下。", "眼睛往上或往下看。", "ParamEyeBallY。"], "eyeSmileLeft": ["衍生：眼睛", "笑眼（左）", "左眼因微笑而彎起的程度（臉頰上提加下眼瞼上提），眨眼時自動抑制。", "開心地笑到眼睛彎起來。", "ParamEyeLSmile。"], "eyeSmileRight": ["衍生：眼睛", "笑眼（右）", "右眼因微笑而彎起的程度（臉頰上提加下眼瞼上提），眨眼時自動抑制。", "開心地笑到眼睛彎起來。", "ParamEyeRSmile。"], "eyeSmile": ["衍生：眼睛", "笑眼（左右平均）", "兩眼笑眼的平均。", "開心地笑到眼睛彎起來。", "只有單一笑眼參數的模型用。"], "browLeftY": ["衍生：眉毛", "左眉上下", "左眉毛上揚為正、下壓為負（-1～+1）。", "挑眉或皺眉（左）。", "ParamBrowLY。"], "browRightY": ["衍生：眉毛", "右眉上下", "右眉毛上揚為正、下壓為負（-1～+1）。", "挑眉或皺眉（右）。", "ParamBrowRY。"], "browAngry": ["衍生：眉毛", "皺眉／生氣", "兩邊眉毛下壓的平均（0～1）。", "皺眉、生氣、專注。", "生氣表情參數。"], "browSad": ["衍生：眉毛", "困擾／委屈", "眉頭上提的程度，已扣掉皺眉成分（0～1）。", "做出八字眉、擔心的表情。", "困擾表情參數。"], "browSurprise": ["衍生：眉毛", "驚訝", "眉頭與眉尾同時上提（0～1）。", "驚訝、睜大眼睛並挑高眉毛。", "驚訝表情參數。"], "browAngleLeft": ["衍生：眉毛", "左眉角度", "困擾為正、生氣為負（-1～+1）。", "八字眉（困擾）或倒八字眉（生氣）。", "ParamBrowLAngle。"], "browAngleRight": ["衍生：眉毛", "右眉角度", "困擾為正、生氣為負（-1～+1）。", "八字眉（困擾）或倒八字眉（生氣）。", "ParamBrowRAngle。"], "browMood": ["衍生：眉毛", "眉毛心情", "困擾為正、生氣為負的單一數值，左右眉一起。", "八字眉（困擾）或倒八字眉（生氣）。", "ParamBrowLForm、ParamBrowRForm。"]};
const ORDER = Object.keys(INFO);

const clamp = (v, a, b) => Math.min(b, Math.max(a, v));
const clamp01 = v => clamp(v, 0, 1);
const invLerp = (a, b, v) => (a === b ? 0 : clamp01((v - a) / (b - a)));
const zh = n => (INFO[n] ? INFO[n][1] : n);
const brief = n => (INFO[n] ? INFO[n][2] : '');
const how = n => (INFO[n] ? INFO[n][3] : '');
const use = n => (INFO[n] ? INFO[n][4] : '');
const group = n => (INFO[n] ? INFO[n][0] : '');

function defaultSettings() {
  return { swapLR: false, filterMin: 1.5, filterBeta: 1.0, jawLo: 0.05, jawHi: 0.25, lipMin: 0.15,
           headBase: [0, 0, 0, 0, 0, 0], fadeOnLost: true,
           useCal: false, calNeutral: new Array(50).fill(0), calMax: new Array(50).fill(1) };
}

// 左右對調用的索引表
const SWAP = BLEND.map(n => {
  let o = n;
  if (n.endsWith('Left')) o = n.slice(0, -4) + 'Right';
  else if (n.endsWith('Right')) o = n.slice(0, -5) + 'Left';
  return BLEND.indexOf(o);
});

// One Euro：慢動作強力平滑、快動作低延遲
class OneEuro {
  constructor() { this.init = false; this.x = 0; this.dx = 0; }
  static alpha(c, dt) { const tau = 1 / (2 * Math.PI * Math.max(0.0001, c)); return 1 / (1 + tau / dt); }
  filter(x, dt, minC, beta) {
    if (!this.init) { this.init = true; this.x = x; this.dx = 0; return x; }
    const dx = (x - this.x) / dt;
    const ad = OneEuro.alpha(1, dt);
    const dxh = ad * dx + (1 - ad) * this.dx;
    const c = minC + beta * Math.abs(dxh);
    const a = OneEuro.alpha(c, dt);
    const xh = a * x + (1 - a) * this.x;
    this.x = xh; this.dx = dxh;
    return xh;
  }
}

class Inputs {
  constructor() {
    this.V = {};
    for (const n of ALL) this.V[n] = 0;
    this.eb = BLEND.map(() => new OneEuro());
    this.eh = HEAD.map(() => new OneEuro());
    this.rawHead = [0, 0, 0, 0, 0, 0];
  }
  update(bs, head, dt, s) {
    const V = this.V;
    dt = Math.max(0.001, dt);
    const cal = s.useCal && s.calNeutral && s.calMax && s.calNeutral.length === 50 && s.calMax.length === 50;
    for (let i = 0; i < 50; i++) {
      const src = s.swapLR ? SWAP[i] : i;
      let v = +bs[src] || 0;
      if (cal) v = clamp01((v - s.calNeutral[src]) / Math.max(0.12, s.calMax[src] - s.calNeutral[src]));
      V[BLEND[i]] = this.eb[i].filter(v, dt, s.filterMin, s.filterBeta);
    }
    const sg = s.swapLR ? -1 : 1;
    const hb = s.headBase;
    for (let i = 0; i < 6; i++) this.rawHead[i] = +head[i] || 0;
    const hv = [(this.rawHead[0] - hb[0]) * sg, this.rawHead[1] - hb[1], this.rawHead[2] - hb[2],
                this.rawHead[3] - hb[3], (this.rawHead[4] - hb[4]) * sg, (this.rawHead[5] - hb[5]) * sg];
    for (let i = 0; i < 6; i++) V[HEAD[i]] = this.eh[i].filter(hv[i], dt, s.filterMin, s.filterBeta * 0.03);

    const avg = (a, b) => (V[a] + V[b]) * 0.5;
    // 咬牙：下巴幾乎沒張開，但嘴唇分開（露出牙齒）
    const closed = 1 - invLerp(s.jawLo, s.jawHi, V.jawOpen);
    const rawLip = Math.max(avg('mouthUpperUpLeft', 'mouthUpperUpRight'),
                   Math.max(avg('mouthLowerDownLeft', 'mouthLowerDownRight'), avg('mouthStretchLeft', 'mouthStretchRight')));
    const apart = invLerp(s.lipMin, 1, rawLip) * (1 - V.mouthClose);
    V.teethClench = clamp01(closed) * clamp01(apart);
    V.mouthTwist = V.mouthRight - V.mouthLeft;
    V.jawSide = V.jawRight - V.jawLeft;
    V.mouthSmile = avg('mouthSmileLeft', 'mouthSmileRight');
    V.mouthFrown = avg('mouthFrownLeft', 'mouthFrownRight');
    V.eyeLookX = ((V.eyeLookInLeft + V.eyeLookOutRight) - (V.eyeLookOutLeft + V.eyeLookInRight)) * 0.5;
    V.eyeLookY = ((V.eyeLookUpLeft + V.eyeLookUpRight) - (V.eyeLookDownLeft + V.eyeLookDownRight)) * 0.5;
    const openL = 1 - clamp01((V.eyeBlinkLeft - 0.5) * 2);
    const openR = 1 - clamp01((V.eyeBlinkRight - 0.5) * 2);
    V.eyeSmileLeft = clamp01(V.cheekSquintLeft * 0.7 + V.eyeSquintLeft * 0.3) * openL;
    V.eyeSmileRight = clamp01(V.cheekSquintRight * 0.7 + V.eyeSquintRight * 0.3) * openR;
    V.eyeSmile = (V.eyeSmileLeft + V.eyeSmileRight) * 0.5;
    const browDownAvg = avg('browDownLeft', 'browDownRight');
    V.browLeftY = V.browOuterUpLeft - V.browDownLeft;
    V.browRightY = V.browOuterUpRight - V.browDownRight;
    V.browAngry = browDownAvg;
    V.browSad = clamp01(V.browInnerUp - 0.5 * browDownAvg);
    V.browMood = V.browSad - V.browAngry;
    V.browSurprise = Math.min(V.browInnerUp, avg('browOuterUpLeft', 'browOuterUpRight'));
    V.browAngleLeft = V.browInnerUp - V.browDownLeft;
    V.browAngleRight = V.browInnerUp - V.browDownRight;
  }
}

// ---------------- 對應 ----------------
function mk(i, o, a, b, c, d, sm, inv) {
  return { enabled: true, input: i, output: o, inMin: a, inMax: b, outMin: c, outMax: d,
           smooth: sm === undefined ? 0.3 : sm, invert: !!inv };
}

function applyMappings(maps, V, params, dt, setFn) {
  const sums = {};
  for (const m of maps) {
    if (!m.enabled || !m.output) continue;
    const x = V[m.input];
    if (x === undefined) continue;
    let t = invLerp(m.inMin, m.inMax, x);
    if (m.invert) t = 1 - t;
    const target = m.outMin + (m.outMax - m.outMin) * t;
    if (!m._init) { m._cur = target; m._init = true; }
    const a = 1 - Math.pow(clamp(m.smooth, 0, 0.97), dt * 60);
    m._cur += (target - m._cur) * a;
    sums[m.output] = (sums[m.output] || 0) + m._cur;
  }
  for (const id in sums) {
    const p = params[id];
    if (!p) continue;
    setFn(id, clamp(sums[id], p.min, p.max));
  }
  return sums;
}

// ---------------- 自動對應（與 Windows 版 AutoMapper 相同規則）----------------
const norm = id => { const r = id.toLowerCase().replace(/[^a-z0-9]/g, ''); return r.startsWith('param') ? r.slice(5) : r; };
const BLEND_KEY = {};
BLEND.forEach(n => { BLEND_KEY[n.toLowerCase()] = n; });
function tryLR(k) {
  if (k.length > 1 && k.endsWith('l') && BLEND_KEY[k.slice(0, -1) + 'left']) return BLEND_KEY[k.slice(0, -1) + 'left'];
  if (k.length > 1 && k.endsWith('r') && BLEND_KEY[k.slice(0, -1) + 'right']) return BLEND_KEY[k.slice(0, -1) + 'right'];
  return null;
}
function addFor(L, id, k, p) {
  const mn = p.min, mx = p.max, zero = clamp(0, mn, mx);
  const pos = (input, sm) => L.push(mk(input, id, 0, 1, zero, mx, sm));
  const bi = input => L.push(mk(input, id, -1, 1, mn, mx, 0.3));
  switch (k) {
    case 'anglex': L.push(mk('headYaw', id, -30, 30, mn, mx, 0.3, false)); return;
    case 'angley': L.push(mk('headPitch', id, -25, 25, mn, mx, 0.3, true)); return;
    case 'anglez': L.push(mk('headRoll', id, -30, 30, mn, mx, 0.3, true)); return;
    case 'bodyanglex': L.push(mk('headYaw', id, -30, 30, mn, mx, 0.5, false)); return;
    case 'bodyangley': L.push(mk('headPitch', id, -25, 25, mn, mx, 0.5, true)); return;
    case 'bodyanglez': L.push(mk('headRoll', id, -30, 30, mn, mx, 0.5, true)); return;
    case 'eyelopen': case 'eyeopenl': case 'eyeopenleft': case 'eyeblinkleft':
      L.push(mk('eyeBlinkLeft', id, 0.1, 0.8, Math.min(1, mx), zero, 0.1)); return;
    case 'eyeropen': case 'eyeopenr': case 'eyeopenright': case 'eyeblinkright':
      L.push(mk('eyeBlinkRight', id, 0.1, 0.8, Math.min(1, mx), zero, 0.1)); return;
    case 'eyeblink':
      L.push(mk('eyeBlinkLeft', id, 0.1, 0.8, Math.min(1, mx), zero, 0.1));
      L.push(mk('eyeBlinkRight', id, 0.1, 0.8, Math.min(1, mx), zero, 0.1)); return;
    case 'eyeballx': L.push(mk('eyeLookX', id, -0.6, 0.6, mn, mx, 0.3, true)); return;
    case 'eyebally': L.push(mk('eyeLookY', id, -0.6, 0.6, mn, mx, 0.3, false)); return;
    case 'browly':
      L.push(mk('browOuterUpLeft', id, 0, 1, zero, mx)); L.push(mk('browDownLeft', id, 0, 1, zero, mn)); return;
    case 'browry':
      L.push(mk('browOuterUpRight', id, 0, 1, zero, mx)); L.push(mk('browDownRight', id, 0, 1, zero, mn)); return;
    case 'mouthopeny': case 'mouthy': L.push(mk('jawOpen', id, 0, 0.7, zero, mx, 0.2)); return;
    case 'mouthform':
      L.push(mk('mouthSmile', id, 0, 0.7, zero, mx)); L.push(mk('mouthFrown', id, 0, 0.7, zero, mn)); return;
    case 'cheek': pos('cheekPuff', 0.3); return;
    case 'eyelsmile': case 'eyesmilel': pos('eyeSmileLeft', 0.2); return;
    case 'eyersmile': case 'eyesmiler': pos('eyeSmileRight', 0.2); return;
    case 'eyesmile': pos('eyeSmile', 0.2); return;
    case 'browlangle': bi('browAngleLeft'); return;
    case 'browrangle': bi('browAngleRight'); return;
    case 'browlform': case 'browrform': bi('browMood'); return;
  }
  const direct = BLEND_KEY[k] || tryLR(k);
  if (direct) { pos(direct, 0.3); return; }
  if (k.includes('teeth') || k.includes('clench') || k.includes('bite')) { pos('teethClench', 0.2); return; }
  if (k.includes('tongue')) { pos('tongueOut', 0.3); return; }
  if (k.includes('mouthopen')) { pos('jawOpen', 0.2); return; }
  if (k === 'mouthx' || k.includes('mouthtwist') || k.includes('mouthleftright')) { bi('mouthTwist'); return; }
  if (k === 'jawx' || k.includes('jawside') || k.includes('jawleftright')) { bi('jawSide'); return; }
  if (k.includes('puff')) { pos('cheekPuff', 0.3); return; }
  if (k.includes('pucker')) { pos('mouthPucker', 0.3); return; }
  if (k.includes('funnel')) { pos('mouthFunnel', 0.3); return; }
  if (k.includes('angry') || k.includes('furrow')) { pos('browAngry', 0.3); return; }
  if (k.includes('sad') || k.includes('worried')) { pos('browSad', 0.3); return; }
  if (k.includes('surprise')) { pos('browSurprise', 0.3); return; }
  if (k.includes('eye') && k.includes('smile')) { pos('eyeSmile', 0.2); return; }
  if (k.includes('smile')) { pos('mouthSmile', 0.3); return; }
  if (k.includes('frown')) { pos('mouthFrown', 0.3); return; }
}
function autoMap(params) {
  const maps = [], unmatched = [];
  for (const id of Object.keys(params)) {
    const before = maps.length;
    addFor(maps, id, norm(id), params[id]);
    if (maps.length === before) unmatched.push(id);
  }
  return { maps, unmatched };
}

// ---------------- 個人校正 ----------------
class Calibrator {
  constructor() { this.stage = 0; this.end = 0; this.count = 0; this.sum = new Array(50).fill(0); this.peak = new Array(50).fill(0); }
  start(stage, seconds, nowMs) {
    this.stage = stage; this.end = nowMs + seconds * 1000; this.count = 0;
    this.sum.fill(0); this.peak.fill(0);
  }
  // 回傳 null（還在記錄）或結果字串（已結束）
  sample(bs, nowMs, settings) {
    if (!this.stage) return null;
    if (bs) {
      this.count++;
      for (let i = 0; i < 50; i++) { const v = +bs[i] || 0; this.sum[i] += v; if (v > this.peak[i]) this.peak[i] = v; }
    }
    if (nowMs < this.end) return null;
    const stage = this.stage; this.stage = 0;
    if (this.count < 5) return '校正失敗：沒有收到足夠的資料，請確認追蹤正在進行';
    if (stage === 1) {
      settings.calNeutral = this.sum.map(x => x / this.count);
      return '已記錄平常臉。接著按「② 記錄最大表情」';
    }
    if (!settings.calNeutral || settings.calNeutral.length !== 50) settings.calNeutral = new Array(50).fill(0);
    settings.calMax = this.peak.map((p, i) => {
      const n = settings.calNeutral[i], range = p - n;
      return range >= 0.15 ? n + range * 0.92 : 1;   // 沒做到的表情維持預設，避免放大雜訊
    });
    settings.useCal = true;
    return '已完成個人校正並啟用';
  }
}

// ---------------- 快捷按鈕（取代電腦版的鍵盤快捷鍵）----------------
function mkHotkey() { return { enabled: true, label: '快捷', output: '', value: 1, mode: 0, fade: 0.15, active: false, weight: 0 }; }
function applyHotkeys(list, dt, params, getFn, setFn) {
  for (const h of list) {
    if (!h.enabled) { h.weight = 0; continue; }
    h.weight = Math.min(1, Math.max(0, h.weight + (h.active ? 1 : -1) * dt / Math.max(0.01, h.fade)));
    if (h.weight <= 0.0001) continue;
    const p = params[h.output];
    if (!p) continue;
    setFn(h.output, getFn(h.output) * (1 - h.weight) + clamp(h.value, p.min, p.max) * h.weight);
  }
}

// ---------------- 測試動作（不需要追蹤，驗證模型會不會動）----------------
function fakeFrame(tSec) {
  const bs = new Array(50).fill(0);
  const set = (n, v) => { bs[BLEND.indexOf(n)] = clamp01(v); };
  const wave = (f, ph) => (Math.sin(tSec * f + (ph || 0)) + 1) / 2;
  set('jawOpen', wave(3) * 0.7);
  const blink = Math.max(0, Math.sin(tSec * 2) * 2 - 1);
  set('eyeBlinkLeft', blink); set('eyeBlinkRight', blink);
  set('mouthSmileLeft', wave(0.8) * 0.7); set('mouthSmileRight', wave(0.8) * 0.7);
  set('cheekSquintLeft', wave(0.6) * 0.8); set('cheekSquintRight', wave(0.6) * 0.8);
  set('browInnerUp', Math.max(0, Math.sin(tSec * 0.5 + 3))); set('browDownLeft', Math.max(0, Math.sin(tSec * 0.5)));
  set('browDownRight', Math.max(0, Math.sin(tSec * 0.5)));
  set('browOuterUpLeft', Math.max(0, Math.sin(tSec * 1.1))); set('browOuterUpRight', Math.max(0, Math.sin(tSec * 1.1 + 1)));
  set('mouthRight', Math.max(0, Math.sin(tSec * 0.9))); set('mouthLeft', Math.max(0, -Math.sin(tSec * 0.9)));
  set('eyeLookInLeft', Math.max(0, Math.sin(tSec))); set('eyeLookOutRight', Math.max(0, Math.sin(tSec)));
  set('eyeLookOutLeft', Math.max(0, -Math.sin(tSec))); set('eyeLookInRight', Math.max(0, -Math.sin(tSec)));
  const head = [0, 0, -0.4, 15 * Math.sin(tSec * 0.9), 25 * Math.sin(tSec * 1.2), 15 * Math.sin(tSec * 0.7)];
  return { bs, head };
}

function rangeFor(name) {
  if (name === 'headPitch' || name === 'headYaw' || name === 'headRoll') return [-60, 60];
  if (name.startsWith('head')) return [-0.5, 0.5];
  return [-1, 1];
}

const api = { BLEND, HEAD, DERIVED, ALL, INFO, ORDER, zh, brief, how, use, group, clamp, clamp01, invLerp,
              defaultSettings, OneEuro, Inputs, mk, applyMappings, autoMap, rangeFor,
              Calibrator, mkHotkey, applyHotkeys, fakeFrame };
if (typeof module !== 'undefined' && module.exports) module.exports = api;
else root.FBEngine = api;
})(typeof window !== 'undefined' ? window : globalThis);

</script>
<script>
(function () {
'use strict';
const E = window.FBEngine;
const $ = id => document.getElementById(id);
const post = o => { try { window.webkit.messageHandlers.fb.postMessage(o); } catch (e) {} };
const BG = ['#00b140', '#0047bb', '#000000', '#ffffff', '#808080'];
const BGN = ['綠幕', '藍幕', '黑', '白', '灰'];

let app = null, model = null, core = null, bgSprite = null;
let params = {}, paramIds = [], unmatched = [];
let modelName = '', bgImage = '', testMode = false;
let profile = { maps: [], hotkeys: [], settings: E.defaultSettings(), view: { x: 0, y: 0, s: 1 }, bg: 0, res: 2, fps: 60 };
const inputs = new E.Inputs();
const cal = new E.Calibrator();
let lastBs = new Array(50).fill(0), lastHead = [0, 0, 0, 0, 0, 0];
let lastData = 0, haveData = false, lastFrame = performance.now();
let rowRefs = [], guideRefs = [], hkRefs = [], saveTimer = null, msgTimer = null;
let guideBox = null, calInfo = null;

function setMsg(t, ms) {
  const m = $('msg');
  m.textContent = t || '';
  m.style.display = t ? 'block' : 'none';
  clearTimeout(msgTimer);
  if (t && ms) msgTimer = setTimeout(() => { m.style.display = 'none'; }, ms);
}

// ---------- 儲存 ----------
function doSave() {
  const json = JSON.stringify(profile, (k, v) => (k === '_cur' || k === '_init' || k === 'active' || k === 'weight' ? undefined : v));
  post({ type: 'save', profile: json });
}
function scheduleSave() { clearTimeout(saveTimer); saveTimer = setTimeout(doSave, 600); }
function changed() { scheduleSave(); }

// ---------- Pixi 與模型 ----------
function ensureApp() {
  if (app) return;
  app = new PIXI.Application({
    view: $('c'), resizeTo: window, antialias: true, autoDensity: true,
    resolution: profile.res || 2,
    backgroundColor: parseInt(BG[profile.bg || 0].slice(1), 16)
  });
  window.addEventListener('resize', () => { layout(); layoutBg(); });
  applyFps();
}
function applyBg() { if (app) app.renderer.backgroundColor = parseInt(BG[profile.bg || 0].slice(1), 16); }
function applyFps() {
  try { PIXI.Ticker.shared.maxFPS = profile.fps || 60; } catch (e) {}
  try { if (app && app.ticker) app.ticker.maxFPS = profile.fps || 60; } catch (e) {}
}
function setRes(r) {
  profile.res = r;
  if (app) { app.renderer.resolution = r; app.renderer.resize(window.innerWidth, window.innerHeight); layout(); layoutBg(); }
}

function layout() {
  if (!model || !app) return;
  const w = app.screen.width, h = app.screen.height;
  model.scale.set(1);
  const k = (h * 0.9) / Math.max(1, model.height);
  model.anchor.set(0.5, 0.5);
  model.scale.set(k * profile.view.s);
  model.position.set(w / 2 + profile.view.x * w, h / 2 + profile.view.y * h);
}

// ---------- 背景圖片 ----------
function layoutBg() {
  if (!bgSprite || !app) return;
  const tw = bgSprite.texture.width || 1, th = bgSprite.texture.height || 1;
  const w = app.screen.width, h = app.screen.height;
  const k = Math.max(w / tw, h / th);
  bgSprite.anchor.set(0.5, 0.5);
  bgSprite.scale.set(k);
  bgSprite.position.set(w / 2, h / 2);
}
function setBgImage(dataUrl) {
  bgImage = dataUrl || '';
  if (!app) return;
  if (bgSprite) { app.stage.removeChild(bgSprite); bgSprite.destroy(); bgSprite = null; }
  if (!bgImage) return;
  const tex = PIXI.Texture.from(bgImage);
  bgSprite = new PIXI.Sprite(tex);
  app.stage.addChildAt(bgSprite, 0);
  if (tex.baseTexture && tex.baseTexture.valid) layoutBg();
  else if (tex.baseTexture && tex.baseTexture.on) tex.baseTexture.on('loaded', layoutBg);
}
function pickBgImage() {
  const inp = document.createElement('input');
  inp.type = 'file'; inp.accept = 'image/*';
  inp.onchange = () => {
    const f = inp.files && inp.files[0];
    if (!f) return;
    const rd = new FileReader();
    rd.onload = () => {
      const img = new Image();
      img.onload = () => {
        const k = Math.min(1, 1280 / Math.max(img.width, img.height));
        const c = document.createElement('canvas');
        c.width = Math.round(img.width * k); c.height = Math.round(img.height * k);
        c.getContext('2d').drawImage(img, 0, 0, c.width, c.height);
        const url = c.toDataURL('image/jpeg', 0.85);
        setBgImage(url);
        post({ type: 'saveBg', data: url });
        setMsg('已套用背景圖片', 1500);
      };
      img.src = rd.result;
    };
    rd.readAsDataURL(f);
  };
  inp.click();
}

function readParams(c) {
  const out = {}, ids = [];
  try {
    const P = c._model.parameters;
    for (let i = 0; i < P.count; i++) {
      out[P.ids[i]] = { min: P.minimumValues[i], max: P.maximumValues[i], def: P.defaultValues[i] };
      ids.push(P.ids[i]);
    }
    if (ids.length) return { out, ids };
  } catch (e) {}
  try {
    const n = c.getParameterCount();
    for (let i = 0; i < n; i++) {
      let id = c.getParameterId(i);
      id = (id && id.getString) ? id.getString().s : String(id);
      out[id] = { min: c.getParameterMinimumValue(i), max: c.getParameterMaximumValue(i), def: c.getParameterDefaultValue(i) };
      ids.push(id);
    }
  } catch (e) {}
  return { out, ids };
}

async function loadModel(o) {
  try {
    if (!(window.PIXI && PIXI.live2d && window.Live2DCubismCore)) {
      setMsg('執行庫沒有載入成功。請回到主畫面，按「下載執行庫」後再開啟。');
      return;
    }
    modelName = o.name;
    let saved = null;
    try { saved = o.profile ? JSON.parse(o.profile) : null; } catch (e) {}
    if (saved) {
      profile.settings = Object.assign(E.defaultSettings(), saved.settings || {});
      profile.view = Object.assign({ x: 0, y: 0, s: 1 }, saved.view || {});
      profile.bg = saved.bg || 0;
      profile.res = saved.res || 2;
      profile.fps = saved.fps || 60;
      profile.hotkeys = (saved.hotkeys || []).map(x => Object.assign(E.mkHotkey(), x, { active: false, weight: 0 }));
    }
    ensureApp();
    applyBg();
    setBgImage(o.bgImage || '');
    if (model) { app.stage.removeChild(model); model.destroy(); model = null; }
    setMsg('載入模型中…');
    const url = 'models/' + encodeURIComponent(o.name) + '/' + o.path.split('/').map(encodeURIComponent).join('/');
    model = await PIXI.live2d.Live2DModel.from(url, { autoInteract: false });
    app.stage.addChild(model);

    const im = model.internalModel;
    // 停用模型內建的待機動作、自動眨眼、呼吸，避免蓋掉追蹤
    try { im.motionManager.stopAllMotions(); if (im.motionManager.groups) im.motionManager.groups.idle = undefined; } catch (e) {}
    try { im.eyeBlink = undefined; } catch (e) {}
    try { im.breath = undefined; } catch (e) {}
    core = im.coreModel;
    const r = readParams(core);
    params = r.out; paramIds = r.ids;

    if (saved && saved.maps && saved.maps.length) { profile.maps = saved.maps; }
    else { profile.maps = E.autoMap(params).maps; }
    unmatched = paramIds.filter(id => !profile.maps.some(m => m.output === id));
    im.on('beforeModelUpdate', onBeforeUpdate);
    layout();
    buildPanel();
    renderHotkeyBar();
    setMsg('已載入：' + modelName + '（' + paramIds.length + ' 個參數）', 2500);
  } catch (e) {
    setMsg('載入失敗：' + (e && e.message ? e.message : e));
    post({ type: 'log', text: String(e && e.stack ? e.stack : e) });
  }
}

// ---------- 每幀：算輸入、套用對應與快捷按鈕 ----------
function onBeforeUpdate() {
  if (!core) return;
  const now = performance.now();
  const dt = Math.min(0.1, Math.max(0.001, (now - lastFrame) / 1000));
  lastFrame = now;
  let bs = lastBs, head = lastHead;
  let alive = haveData && (now - lastData) < 1000;
  if (testMode) { const f = E.fakeFrame(now / 1000); bs = f.bs; head = f.head; alive = true; }

  const r = cal.sample(alive && !testMode ? lastBs : null, now, profile.settings);
  if (r) { setMsg(r, 3500); changed(); }

  if (alive) {
    inputs.update(bs, head, dt, profile.settings);
    E.applyMappings(profile.maps, inputs.V, params, dt, (id, v) => core.setParameterValueById(id, v));
  } else if (profile.settings.fadeOnLost) {
    const k = 1 - Math.exp(-3 * dt);
    for (const m of profile.maps) {
      m._init = false;
      const p = params[m.output];
      if (!p) continue;
      try { core.setParameterValueById(m.output, core.getParameterValueById(m.output) * (1 - k) + p.def * k); } catch (e) {}
    }
  }
  E.applyHotkeys(profile.hotkeys, dt, params, id => core.getParameterValueById(id), (id, v) => core.setParameterValueById(id, v));
}

// ---------- 手勢：單指拖曳、雙指縮放 ----------
let g = null;
function snap(e) {
  const t = e.touches;
  if (t.length >= 2) {
    const dx = t[0].clientX - t[1].clientX, dy = t[0].clientY - t[1].clientY;
    return { n: 2, x: (t[0].clientX + t[1].clientX) / 2, y: (t[0].clientY + t[1].clientY) / 2, d: Math.hypot(dx, dy) };
  }
  if (t.length === 1) return { n: 1, x: t[0].clientX, y: t[0].clientY, d: 0 };
  return null;
}
const cv = $('c');
cv.addEventListener('touchstart', e => { e.preventDefault(); g = snap(e); }, { passive: false });
cv.addEventListener('touchmove', e => {
  e.preventDefault();
  if (!g || !model || !app) return;
  const n = snap(e);
  if (!n) return;
  if (n.n === 1 && g.n === 1) {
    profile.view.x += (n.x - g.x) / app.screen.width;
    profile.view.y += (n.y - g.y) / app.screen.height;
  } else if (n.n === 2 && g.n === 2 && g.d > 0) {
    profile.view.s = E.clamp(profile.view.s * n.d / g.d, 0.2, 5);
  }
  g = n;
  layout();
  scheduleSave();
}, { passive: false });
cv.addEventListener('touchend', e => { g = e.touches.length ? snap(e) : null; });

// ---------- 小工具 ----------
function h(tag, attrs, children) {
  const e = document.createElement(tag);
  for (const k in (attrs || {})) {
    if (k === 'class') e.className = attrs[k];
    else if (k.startsWith('on')) e[k] = attrs[k];
    else e.setAttribute(k, attrs[k]);
  }
  (Array.isArray(children) ? children : [children]).forEach(c => {
    if (c === null || c === undefined) return;
    e.appendChild(typeof c === 'string' ? document.createTextNode(c) : c);
  });
  return e;
}
function checkbox(label, get, set) {
  const i = h('input', { type: 'checkbox' });
  i.checked = !!get();
  i.onchange = () => { set(i.checked); changed(); };
  return h('label', { class: 'chk' }, [i, label]);
}
function slider(label, get, set, min, max, step) {
  const i = h('input', { type: 'range' });
  i.min = min; i.max = max; i.step = step || 0.01; i.value = get();
  const v = h('span', { class: 'val' }, (+get()).toFixed(2));
  i.oninput = () => { set(parseFloat(i.value)); v.textContent = (+i.value).toFixed(2); changed(); };
  return h('div', { class: 'sl' }, [h('span', { class: 'lab' }, label), i, v]);
}
function select(options, value, onchange, allowEmpty) {
  const s = h('select', {});
  const vals = options.map(o => o[0]);
  if (allowEmpty && value && !vals.includes(value)) options = [[value, '（模型沒有）' + value]].concat(options);
  if (allowEmpty && !value) options = [['', '（選擇參數）']].concat(options);
  options.forEach(o => { const op = h('option', { value: o[0] }, o[1]); if (o[0] === value) op.selected = true; s.appendChild(op); });
  s.onchange = () => onchange(s.value);
  return s;
}
function sec(title, children, open) {
  const d = h('details', { class: 'sec' }, [h('summary', {}, title)].concat(children));
  if (open) d.open = true;
  return d;
}
function btn(text, fn) { return h('button', { onclick: fn }, text); }

// ---------- 設定面板 ----------
function buildPanel() {
  const p = $('panel');
  p.innerHTML = '';
  guideRefs = [];
  const S = profile.settings;

  p.appendChild(h('div', { class: 'row' }, [h('b', {}, '設定：' + modelName), btn('關閉', () => p.classList.add('hide'))]));

  // 一般
  p.appendChild(sec('一般', [
    btn('僅傳送數據（關閉手機上的模型畫面）', () => { doSave(); post({ type: 'sendOnly' }); }),
    checkbox('測試動作（不需要追蹤，驗證模型會不會動）', () => testMode, v => { testMode = v; }),
    checkbox('左右對調（眨眼、歪嘴方向反了就勾）', () => S.swapLR, v => { S.swapLR = v; }),
    checkbox('追蹤中斷時模型回到中立姿勢', () => S.fadeOnLost, v => { S.fadeOnLost = v; }),
    slider('靜止平滑', () => S.filterMin, v => { S.filterMin = v; }, 0.3, 6),
    slider('快速跟隨', () => S.filterBeta, v => { S.filterBeta = v; }, 0, 5),
    h('div', { class: 'brief' }, '靜止平滑越低越穩（慢動作延遲增加）；快速跟隨越高，眨眼這類快動作延遲越小。預設 1.5 / 1.0。'),
    h('div', { class: 'row' }, [
      btn('校正頭部（面向正前方時按）', () => { S.headBase = inputs.rawHead.slice(); setMsg('已校正頭部', 1500); changed(); }),
      btn('取消', () => { S.headBase = [0, 0, 0, 0, 0, 0]; setMsg('已取消校正', 1500); changed(); })
    ]),
    btn('重設模型位置與大小（也可單指拖曳、雙指縮放）', () => { profile.view = { x: 0, y: 0, s: 1 }; layout(); changed(); })
  ], true));

  // 個人校正
  calInfo = h('div', { class: 'brief' }, '');
  p.appendChild(sec('個人校正（提高精確度）', [
    h('div', { class: 'brief' }, '先做①再做②。校正後，每個表情的 0~1 會對應到「你的」平常臉到最大表情。需要追蹤正在進行。'),
    calInfo,
    h('div', { class: 'row' }, [
      btn('① 記錄平常臉（3 秒）', () => { cal.start(1, 3, performance.now()); }),
      btn('② 記錄最大表情（12 秒）', () => { cal.start(2, 12, performance.now()); })
    ]),
    h('div', { class: 'row' }, [
      checkbox('使用個人校正', () => S.useCal, v => { S.useCal = v; }),
      btn('清除校正', () => { S.useCal = false; S.calNeutral = new Array(50).fill(0); S.calMax = new Array(50).fill(1); changed(); setMsg('已清除個人校正', 1500); buildPanel(); })
    ])
  ]));

  // 咬牙判定
  p.appendChild(sec('咬牙判定（teethClench）', [
    slider('下巴閉合', () => S.jawLo, v => { S.jawLo = v; }, 0, 0.5),
    slider('下巴張開', () => S.jawHi, v => { S.jawHi = v; }, 0.05, 0.8),
    slider('唇分開門檻', () => S.lipMin, v => { S.lipMin = v; }, 0, 0.8),
    h('div', { class: 'brief', id: 'teethLive' }, '')
  ]));

  // 畫質與背景
  p.appendChild(sec('畫質與背景', [
    h('div', { class: 'row' }, [h('span', {}, '背景色')].concat(BGN.map((n, i) => btn(n, () => { profile.bg = i; applyBg(); changed(); })))),
    h('div', { class: 'row' }, [btn('選擇背景圖片', pickBgImage), btn('清除背景圖片', () => { setBgImage(''); post({ type: 'saveBg', data: '' }); })]),
    h('div', { class: 'row' }, [h('span', {}, '渲染精度')].concat([1, 1.5, 2, 3].map(r => btn(r + 'x', () => { setRes(r); changed(); })))),
    h('div', { class: 'row' }, [h('span', {}, '更新頻率')].concat([30, 60].map(f => btn(f + ' FPS', () => { profile.fps = f; applyFps(); changed(); })))),
    h('div', { class: 'brief' }, '模型模糊就調高渲染精度；手機發燙或要省電就選 30 FPS。')
  ]));

  // 參數手冊
  guideBox = h('div', {}, '');
  p.appendChild(sec('參數手冊（每個表情的中文說明）', [
    h('div', { class: 'brief' }, '對著鏡頭做表情，看哪條數值條在動。點中文名稱展開說明。'), guideBox
  ]));
  buildGuide(guideBox);

  // 參數對應
  p.appendChild(sec('參數對應（輸入 → Live2D 參數）', [
    h('div', { class: 'row' }, [
      btn('重新自動對應', () => {
        const a = E.autoMap(params); profile.maps = a.maps;
        unmatched = paramIds.filter(id => !profile.maps.some(m => m.output === id));
        changed(); renderMaps(); setMsg('已自動對應 ' + (paramIds.length - a.unmatched.length) + ' 個參數', 2000);
      }),
      btn('＋新增對應', () => { profile.maps.push(E.mk('jawOpen', '', 0, 1, 0, 1)); changed(); renderMaps(); })
    ]),
    h('div', { id: 'maps' }, ''),
    h('div', { class: 'brief' }, '未對應的模型參數（頭髮、呼吸等通常由模型自己處理）：'),
    h('div', { class: 'brief', id: 'unm' }, '')
  ]));
  renderMaps();

  // 快捷按鈕
  p.appendChild(sec('快捷按鈕（點一下切換／按住）', [
    h('div', { class: 'brief' }, '畫面左側會出現按鈕，點一下就把模型的某個參數設成指定值，可切換表情、道具、手勢（模型需要有對應的參數）。'),
    btn('＋新增快捷按鈕', () => { profile.hotkeys.push(E.mkHotkey()); changed(); renderHotkeyEditor(); renderHotkeyBar(); }),
    h('div', { id: 'hkEdit' }, '')
  ]));
  renderHotkeyEditor();
}

function buildGuide(box) {
  let last = null;
  E.ORDER.forEach(n => {
    const grp = E.group(n);
    if (grp !== last) { last = grp; box.appendChild(h('div', { class: 'grp' }, grp)); }
    const fill = h('i', {});
    const bar = h('div', { class: 'bar' }, [fill]);
    const live = h('span', { class: 'val' }, '');
    const detail = h('div', { class: 'hide brief' }, [
      h('div', {}, n),
      h('div', {}, '說明：' + E.brief(n)),
      h('div', {}, '怎麼做：' + E.how(n)),
      h('div', {}, '常接：' + E.use(n))
    ]);
    box.appendChild(h('div', {}, [h('div', { class: 'row' }, [btn(E.zh(n), () => detail.classList.toggle('hide')), bar, live]), detail]));
    guideRefs.push({ n, fill, live });
  });
}

function renderMaps() {
  const box = $('maps');
  if (!box) return;
  box.innerHTML = '';
  rowRefs = [];
  profile.maps.forEach((m, idx) => {
    const en = h('input', { type: 'checkbox' });
    en.checked = !!m.enabled;
    en.onchange = () => { m.enabled = en.checked; changed(); };
    const selIn = select(E.ORDER.map(n => [n, E.zh(n) + '　' + n]), m.input, v => { m.input = v; changed(); renderMaps(); });
    const selOut = select(paramIds.map(id => [id, id]), m.output, v => { m.output = v; changed(); renderMaps(); }, true);
    const inv = checkbox('反向', () => m.invert, v => { m.invert = v; });
    const live = h('span', { class: 'val' }, '');
    const [iLo, iHi] = E.rangeFor(m.input);
    const po = params[m.output];
    const oLo = po ? po.min : -30, oHi = po ? po.max : 30;
    const detail = h('div', { class: 'hide' }, [
      slider('輸入最小', () => m.inMin, v => { m.inMin = v; }, iLo, iHi),
      slider('輸入最大', () => m.inMax, v => { m.inMax = v; }, iLo, iHi),
      slider('輸出最小', () => m.outMin, v => { m.outMin = v; }, oLo, oHi),
      slider('輸出最大', () => m.outMax, v => { m.outMax = v; }, oLo, oHi),
      slider('平滑', () => m.smooth, v => { m.smooth = v; }, 0, 0.95)
    ]);
    box.appendChild(h('div', { class: 'map' }, [
      h('div', { class: 'row' }, [en, selIn]),
      h('div', { class: 'row' }, [h('span', {}, '→'), selOut]),
      h('div', { class: 'row' }, [inv, btn('展開', () => detail.classList.toggle('hide')),
        btn('×', () => { profile.maps.splice(idx, 1); changed(); renderMaps(); }), live]),
      h('div', { class: 'brief' }, E.zh(m.input) + '：' + E.brief(m.input)),
      detail
    ]));
    rowRefs.push({ m, live });
  });
  const u = $('unm');
  if (u) u.textContent = unmatched.length ? unmatched.join('、') : '（無）';
}

// ---------- 快捷按鈕 ----------
function renderHotkeyEditor() {
  const box = $('hkEdit');
  if (!box) return;
  box.innerHTML = '';
  profile.hotkeys.forEach((k, idx) => {
    const name = h('input', { type: 'text' });
    name.value = k.label || '';
    name.onchange = () => { k.label = name.value; changed(); renderHotkeyBar(); };
    const po = params[k.output];
    box.appendChild(h('div', { class: 'map' }, [
      h('div', { class: 'row' }, [checkbox('啟用', () => k.enabled, v => { k.enabled = v; renderHotkeyBar(); }), name]),
      h('div', { class: 'row' }, [select(paramIds.map(id => [id, id]), k.output, v => { k.output = v; changed(); renderHotkeyEditor(); renderHotkeyBar(); }, true)]),
      slider('數值', () => k.value, v => { k.value = v; }, po ? po.min : -30, po ? po.max : 30),
      slider('淡入淡出秒', () => k.fade, v => { k.fade = v; }, 0.01, 2),
      h('div', { class: 'row' }, [
        btn(k.mode === 0 ? '模式：點一下切換' : '模式：按住才有效', () => { k.mode = 1 - k.mode; changed(); renderHotkeyEditor(); renderHotkeyBar(); }),
        btn('×', () => { profile.hotkeys.splice(idx, 1); changed(); renderHotkeyEditor(); renderHotkeyBar(); })
      ])
    ]));
  });
}
function renderHotkeyBar() {
  const bar = $('hk');
  if (!bar) return;
  bar.innerHTML = '';
  hkRefs = [];
  profile.hotkeys.forEach(k => {
    if (!k.enabled || !k.output) return;
    const b = h('button', { class: 'hkb' }, k.label || k.output);
    const refresh = () => b.classList.toggle('on', !!k.active);
    if (k.mode === 0) {
      b.onclick = () => { k.active = !k.active; refresh(); };
    } else {
      const down = e => { e.preventDefault(); k.active = true; refresh(); };
      const up = () => { k.active = false; refresh(); };
      b.addEventListener('touchstart', down, { passive: false });
      b.addEventListener('touchend', up);
      b.addEventListener('touchcancel', up);
    }
    bar.appendChild(b);
    hkRefs.push(refresh);
  });
}

// ---------- 即時數值更新（每 250ms）----------
setInterval(() => {
  const open = !$('panel').classList.contains('hide');
  if (cal.stage && calInfo) {
    const left = Math.max(0, Math.ceil((cal.end - performance.now()) / 1000));
    calInfo.textContent = (cal.stage === 1 ? '記錄平常臉：請放鬆、面向前方不要動… '
      : '記錄最大表情：請依序做誇張表情：張嘴、眨眼、微笑、挑眉、皺眉、嘟嘴、鼓頰、歪嘴、上下左右看… ') + left + ' 秒';
  } else if (calInfo) calInfo.textContent = profile.settings.useCal ? '目前：已啟用個人校正' : '目前：未使用個人校正';
  if (!open) return;
  for (const r of rowRefs) {
    const x = inputs.V[r.m.input];
    r.live.textContent = (x === undefined ? 0 : x).toFixed(2) + ' → ' + (r.m._cur === undefined ? 0 : r.m._cur).toFixed(2);
  }
  for (const r of guideRefs) {
    const v = inputs.V[r.n] || 0;
    const [lo, hi] = E.rangeFor(r.n);
    r.fill.style.width = Math.round(E.clamp((v - lo) / (hi - lo), 0, 1) * 100) + '%';
    r.live.textContent = v.toFixed(2);
  }
  const t = $('teethLive');
  if (t) t.textContent = '目前咬牙值：' + inputs.V.teethClench.toFixed(2) + '　jawOpen：' + inputs.V.jawOpen.toFixed(2);
}, 250);

$('gear').onclick = () => { $('panel').classList.toggle('hide'); };

// ---------- 給 Swift 呼叫的介面 ----------
window.fb = {
  update(bs, head) { lastBs = bs; lastHead = head; lastData = performance.now(); haveData = true; },
  load(o) { loadModel(o); },
  flush() { clearTimeout(saveTimer); if (model) doSave(); }
};
if (!(window.PIXI && PIXI.live2d && window.Live2DCubismCore)) {
  setMsg('執行庫尚未安裝或載入失敗。請回到主畫面按「下載執行庫」。');
}
post({ type: 'ready' });
})();

</script>
</body></html>
"""#
}
