# NCヘッダージェネレーター 仕様・開発メモ

このドキュメントは、本アプリの仕様・よく使う計算式・コードパターンを
今後の開発（機能追加・保守・別アプリへの流用）のためにまとめた素材集です。
実装の一次情報は常に `index.html` / `logic.js` 側を参照してください。

## 1. アプリ概要

- **目的**：Bエリア（工場内の切削加工エリア）向けに、CNC旋盤プログラムの
  冒頭に貼り付けるヘッダーコメント（機械No./ゲタNo./オフセット値など）を
  対話形式（全13問のウィザード）で生成するツール。
- **利用者**：現場のプログラム作成担当者。日本語／ベトナム語（`vi`）に対応。
- **成果物**：`G10L2P0Z...` を含むテキストブロックをクリップボードにコピーし、
  CNCプログラムへ貼り付けて使う。

## 2. 技術構成

- 完全にクライアントサイドの Vanilla JS / HTML / CSS。ビルド不要、
  フレームワーク不使用、外部ライブラリへの依存もなし。
- ファイル構成：
  | ファイル | 役割 |
  |---|---|
  | `index.html` | 画面（UI）・状態管理・レンダリング・多言語辞書(`I18N`) |
  | `logic.js` | マスターデータと計算ロジック。`window.Logic` としてグローバル公開 |
  | `app-icon.png` | アプリアイコン（favicon・ホーム画面アイコン） |

### 設計方針（コード内コメントより）

- 「計算ロジックや単価マスターは `logic.js` 側を編集する」
- 「`index.html` は画面の出し方だけを担当する」
- 「多言語対応は `I18N` オブジェクトに言語キーを追加すれば画面の文言を
  増やせる」

この役割分担（**データ／計算 = logic.js、UI = index.html**）は
今後機能追加する際も踏襲すると保守しやすい。

## 3. 画面フロー（ウィザードのステップ定義）

`index.html` の `steps` 配列がステップの並び順そのもの：

```js
const steps = [
  { id: "kikai" },       // ① 機械No.選択
  { id: "zenchou" },     // ② 加工後の全長 入力
  { id: "kakou" },       // ③ 加工長さ 入力
  { id: "enbiGuide" },   // ④ 塩ビ高さ目安の確認（表示のみ）
  { id: "enbiNo" },      // ⑤ 塩ビゲタNo.選択（おすすめ表示）
  { id: "tetsugetaNo" }, // ⑥ 鉄ゲタNo.選択
  { id: "offset" },      // ⑦⑧ Zオフセット値 確認（表示のみ）
  { id: "chushin" },     // ⑨ 下アテ〜中心距離 入力
  { id: "ateNo" },       // ⑩⑪ アテNo.選択（おすすめ表示）
  { id: "toruku" },      // ⑫ 締め付けトルク 入力
  { id: "yokogeta" },    // ⑭ 横ゲタ有無 選択
  { id: "sakuseisha" },  // ⑬ 作成者名 入力
  { id: "summary" },     // 確認・コピー出力
];
```

- 状態は単一の `state` オブジェクトで一元管理し、`stepIndex` で現在位置を保持。
- `derive()` が毎回の再計算（マスター参照・計算式の実行）をまとめて行い、
  各ステップの描画時に呼び出す。
- 新しいステップを追加する場合は `steps` 配列に `id` を足し、
  `renderStep()` の `switch` に `case` を追加する。

## 4. マスターデータ構造（よく使うデータ形状）

`logic.js` 内、すべて `key → 属性オブジェクト` の形。新規追加はこの形に合わせる。

```js
// 機械No.マスター：爪長さ／鉄ゲタ高さ／鉄ゲタNo.初期値／機械オフセット／機種
kikaiMaster = {
  "NCL-004": { tumeNagasa: 62, tetsugetaTakasa: 5, tetsugetaNo: "T-8",
               offset: 150.925, kishu: "森精機CL-20" },
  // tumeNagasa / tetsugetaNo / offset のいずれかが null だと
  // isKikaiComplete() が false を返し、画面①でグレーアウト（選択不可）になる
};

// 鉄ゲタマスター：高さ／幅／穴
tetsugetaMaster = { "T-1": { takasa: 5, haba: 13.5, ana: "なし" }, ... };

// 塩ビゲタマスター：高さ／幅／（穴・穴深さは任意）
enbiGetaMaster = { "B-1": { height: 44, width: 13.5 }, ... };

// アテマスター：高さ／Φ
ateMaster = { "C-1-1": { takasa: 44, phi: 13 }, ... };

// 作成者名マスター：配列。テンキー(1-9,0)ショートカットの対象にもなる
sakuseishaMaster = ["Y.YAMADA", "R.SIKATA", ...];

// 手動オフセット機械のNo.配列（G10によるオフセット変更が
// オプション機能で自動切替できない機種）
MANUAL_OFFSET_KIKAI = ["NCL-003", "NCL-012", "NCL-013", "NCL-044"];
```

**機械を新規登録する手順**（`kikaiMaster` コメントより）：
1. `tumeNagasa`（爪長さ mm）を実測値に置き換える
2. `tetsugetaNo`（`tetsugetaMaster` のキー）を設定する
3. `offset`（機械オフセット値 mm）を設定する
4. 3項目すべて揃うと `isKikaiComplete()` が true になり選択可能になる

## 5. 主要な計算式（頻出仕様）

```js
// ④ 塩ビゲタ 目安の高さ
//   ツメ長さ − 鉄ゲタ高さ − (全長 − 加工長さ) + 突き出し量(2mm)
function calcEnbiGuide(tumeNagasa, tetsugetaTakasa, zenchou, kakouNagasa) {
  return tumeNagasa - tetsugetaTakasa - (zenchou - kakouNagasa) + 2;
}

// ⑦ Zオフセット値（機種によって式が異なる）
//   森精機：機械オフセット − 塩ビ高さ − 全長 − 鉄ゲタ高さ
//   ツガミ：機械オフセット + (塩ビ高さ + 全長 + 鉄ゲタ高さ)
function calcOffset(kishu, kikaiOffset, enbiTakasa, zenchou, tetsugetaTakasa) {
  if (kishu === "ツガミ") return kikaiOffset + (enbiTakasa + zenchou + tetsugetaTakasa);
  return kikaiOffset - enbiTakasa - zenchou - tetsugetaTakasa;
}

// ⑨ アテの高さ = 基準高さ(50 or 70) − 下アテから中心までの距離
function calcAteTakasa(chushinKyori, kijunTakasa = 50) {
  return Number(kijunTakasa) - Number(chushinKyori);
}
```

- `getEnbiRecommendations(guideHeight)` / `getAteRecommendations(guideHeight)`：
  目安の高さとの差の絶対値でソートし、**差が3mm以内**（塩ビは「目安以上かつ
  差3mm以内」）のものを `recommended` として返す共通パターン。
  目安が計算不能な場合は高さ順の全件のみ返す。
- `fmt(num)`：小数第4位で丸め、末尾の余計な0を除去して表示用文字列にする
  （`150.9250` → `"150.925"`）。金額・座標など小数を扱う数値表示に流用可。

## 6. 出力テキストのフォーマット（CNCプログラムヘッダー）

`generateOutputText()` が組み立てる最終テキスト（半角のみ）：

```
(日付)
(作成者)
(TETUGETA=鉄ゲタNo.)
(ATE=アテNo.)(調整用ワッシャーmm)
(ENNBI=塩ビNo.)
(KIKAI=機械No.)
(TORUKU=トルク)
(YOKOGETA=横塩ビ)
G10L2P0Zオフセット値(WORK-OFFSET)M1(NYUURYOKU)
```

- `ATE` 行の差分（調整用ワッシャー）は `Math.abs(ateDiff) >= 0.01` の
  ときだけ付与。手動オフセット機械（`MANUAL_OFFSET_KIKAI`）では単位 `mm`
  表記を省略する。
- `塩ビゲタNo. === "なし 0"` のときは出力上 `0` に変換する。
- `横ゲタ`：`"なし"→"0"`、`"あり"→"1"` に変換して出力。

## 7. バリデーションルール一覧

| 項目 | ルール |
|---|---|
| 加工後の全長 | 1〜200mm |
| 加工長さ | 1〜50mm、かつ全長以下 |
| 下アテ〜中心距離 | 0 < 値 < 基準高さ（50 or 70mm） |
| 締め付けトルク | 1〜30N（デフォルト7N。7/8以上で変形しやすい製品は4〜5N推奨） |
| 作成者名 | 10文字以内、半角英数字・ピリオド・スラッシュのみ（例: `T.SIKATA`） |

## 8. UI/UXパターン（再利用できる実装テクニック）

- **ウィザード管理**：`steps` 配列 + `stepIndex`。`render()` = `renderProgress()`
  + `renderStep()`。`goNext()` / `goBack()` で `stepIndex` を増減して再描画。
- **キーボードショートカット**：`setDocKeydown(fn)` で画面遷移ごとに
  `document` の `keydown` ハンドラを差し替える（Enterで次へ、テンキー
  1〜9,0でおすすめ候補・機械No.・作成者名などを直接選択）。
- **おすすめ＋全件切替パターン**：上位候補をカード表示（`.geta-card`）し、
  「すべてから選ぶ」ボタンで全件セレクトを開閉する UI（塩ビゲタ選択・
  アテ選択の両方で同じ構造を使用）。
- **警告モーダル**：塩ビ高さが目安を下回る場合に `showWarnModal()` で
  工具干渉の注意喚起を表示し、「選び直す」／「このまま進む」を選択させる。
- **多言語辞書**：`I18N.ja` / `I18N.vi` に文言キーを追加するだけで
  UI 文言を切り替え可能。関数を値に持たせて動的文言（`step(n, total)` 等）
  にも対応。
- **コピー機能**：`navigator.clipboard.writeText()` を試し、失敗したら
  `document.execCommand("copy")` にフォールバック。
- **ホーム画面**：`#homeScreen` と `#appMain` の表示切替のみで画面遷移
  （SPA的なルーティングライブラリは使わない）。

## 9. 今後の開発で注意すべき点

- 新しい機械を追加する場合：`kikaiMaster` に `tumeNagasa` / `tetsugetaNo` /
  `offset` を入れないと選択不可のままなので、この3点セットを忘れない。
- 新しい言語を追加する場合：`I18N` にキーを追加し、`LANGS` 配列にも
  言語コードを追加する（`langSelect` の生成は `LANGS` 走査で自動化されている）。
- 「生成履歴」ボタン（`#btnHistory`）は現状未実装（トースト「準備中です」
  のみ）。履歴機能を実装する際の導線として既に用意されている。
- 機種区分 `kishu` は `calcOffset` の分岐条件で `"ツガミ"` という
  文字列に厳密一致させているため、新機種追加時は既存の命名規則
  （`"森精機〇〇"` or `"ツガミ"`）を崩さないこと。
