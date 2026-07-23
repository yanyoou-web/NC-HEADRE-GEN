/* =========================================================
   logic.js
   Bエリア プログラム作成フォーム - 計算ロジック・マスターデータ
   ---------------------------------------------------------
   ★ ここを編集すれば計算ロジック・マスター値を更新できます。
   ★ 画面側（index.html）は基本的に編集不要です。
   ========================================================= */

const Logic = (() => {

  /* ----------------------------------------------------
     1) 機械No. マスター
     爪長さ / 鉄ゲタNo.初期値 / 機械オフセット値 / 機種
     機種は "森精機〇〇" か "ツガミ" のどちらかを正確に入力。

     ■ 鉄ゲタの高さ・幅などの詳細値について
       ここには「その機械が標準で使う鉄ゲタNo.（tetsugetaNo）」だけを登録する。
       高さ・幅などの詳細な数値は、下の tetsugetaMaster 側にのみ登録し、
       ここには重複して持たせない（tetsugetaNo を頼りに tetsugetaMaster を参照する）。
       ※ 今後 tetsugetaMaster にピッチなどの項目が増えても、
          tetsugetaMaster 側を1回直すだけで済み、機械側との食い違いが起きない。

     ■ グレーアウト（プルダウン選択不可）について
       tumeNagasa / tetsugetaNo / offset のいずれかが null の
       行は、「加工する機械No.を選んでください」の画面で「（データ未登録）」と表示され選択できません。

     ■ グレーアウトを解除する方法
       下記 3項目を実際の値に書き換えてください。
         tumeNagasa  … 爪長さ（数値 mm。例: 62）
         tetsugetaNo … 鉄ゲタNo.（例: "T-8"）。下の tetsugetaMaster を参照。
         offset      … 機械オフセット値（数値 mm。例: 150.925）

     ■ グレーアウト判定箇所の確認方法
       このファイル（logic.js）で 「isKikaiComplete」 を検索すると
       「3項目がすべて入力済みか確認する処理」が見つかります。
       また index.html で 「isKikaiComplete」 を検索すると
       プルダウンで選択不可にしている箇所を確認できます。
  ---------------------------------------------------------- */
  const kikaiMaster = {
    "NCL-001":          { tumeNagasa: null, tetsugetaNo: null, offset: null,  kishu: "森精機CL-25-2" },
    "NCL-003":          { tumeNagasa: null, tetsugetaNo: null, offset: null,  kishu: "森精機CL-25-1" },
    "NCL-004":          { tumeNagasa: 62, tetsugetaNo: "T-8", offset: 150.925,  kishu: "森精機CL-20" },
    "NCL-010":          { tumeNagasa: null, tetsugetaNo: null, offset: 239.606,  kishu: "森精機CL-25-2" },
    "NCL-012":          { tumeNagasa: 62, tetsugetaNo: "T-8", offset: 165.494,  kishu: "森精機CL-20" },
    "NCL-013":          { tumeNagasa: 62, tetsugetaNo: "T-8", offset: 166.329,  kishu: "森精機CL-20" },
    "NCL-014":          { tumeNagasa: null, tetsugetaNo: null, offset: 238.179,  kishu: "森精機CL-25-2" },
    "NCL-015":          { tumeNagasa: 50, tetsugetaNo: "T-1", offset: 125.708,  kishu: "森精機CL-150" },
    "NCL-015長爪":      { tumeNagasa: null, tetsugetaNo: "T-10", offset: 128.502,  kishu: "森精機CL-150" },
    "NCL-044":          { tumeNagasa: 62, tetsugetaNo: "T-1", offset: 125.404,  kishu: "森精機CL-2000-1" },
    "NCL-045":          { tumeNagasa: 62, tetsugetaNo: "T-8", offset: 252.558,  kishu: "森精機NL-2000" },
    "NCL-077":          { tumeNagasa: 62, tetsugetaNo: "T-1", offset: 124.988,  kishu: "森精機CL-2000-2" },
    "NCL-078":          { tumeNagasa: 62, tetsugetaNo: "T-1", offset: 124.816,  kishu: "森精機CL-2000-2" },
    "NCL-079":          { tumeNagasa: 62, tetsugetaNo: "T-1", offset: 124.885,  kishu: "森精機CL-2000-2" },
    "NCL-085":          { tumeNagasa: 62, tetsugetaNo: "T-9", offset: 199.575,  kishu: "森精機NLX2500" },
    "NCL-093":          { tumeNagasa: 68, tetsugetaNo: "T-2", offset: -199.044, kishu: "ツガミ" },
    "NCL-094":          { tumeNagasa: 68, tetsugetaNo: "T-2", offset: -199.015, kishu: "ツガミ" },
    "NCL-0116":         { tumeNagasa: 63, tetsugetaNo: "T-9", offset: 87.896, kishu: "森精機NLX2500" },
  };


  /*
   * 【isKikaiComplete】機械No.のデータが揃っているか確認する
   *
   * tumeNagasa / tetsugetaNo / offset の3項目がすべて入力済みなら true を返す。
   * いずれかが null の場合は false → 「加工する機械No.を選んでください」の画面のプルダウンでグレーアウト（選択不可）になる。
   */
  function isKikaiComplete(kikaiNo) {
    const m = kikaiMaster[kikaiNo];
    if (!m) return false;
    return m.tumeNagasa !== null && m.tetsugetaNo !== null && m.offset !== null;
  }

  /* ----------------------------------------------------
     2) 鉄ゲタ マスター（T-1 〜 T-12）
     takasa = 高さ / haba = 幅 / ana = 穴（"なし" または 数値）
  ---------------------------------------------------------- */
  const tetsugetaMaster = {
    "T-1":  { takasa: 5,  haba: 13.5, ana: "なし" },
    "T-2":  { takasa: 11, haba: 13.5, ana: "なし" },
    "T-3":  { takasa: 5,  haba: 31.5, ana: "なし" },
    "T-4":  { takasa: 5,  haba: 41,   ana: "なし" },
    "T-5":  { takasa: 40, haba: 13.5, ana: "なし" },
    "T-6":  { takasa: 5,  haba: 24,   ana: 19 },
    "T-7":  { takasa: 20, haba: 24,   ana: 16 },
    "T-8":  { takasa: 5,  haba: 13.5, ana: "なし" },
    "T-9":  { takasa: 5,  haba: 13.5, ana: "なし" },
    "T-10": { takasa: 17.48, haba: 13.5, ana: "なし" },
    "T-11": { takasa: 52, haba: 8.5,  ana: "なし" },
    "T-12": { takasa: 54, haba: 8.5,  ana: "なし" },
  };

  /* ----------------------------------------------------
     3) 塩ビゲタ マスター（B-1〜B-40, BA-1〜BA-7）
     height = 高さ(mm) / width = 幅(mm) / ana = 穴 / anaFukasa = 穴深さ
  ---------------------------------------------------------- */
  const enbiGetaMaster = {
    "なし 0": { height: 0,  width: null },
    "B-1":  { height: 44,   width: 13.5 },
    "B-2":  { height: 41,   width: 16 },
    "B-3":  { height: 38,   width: 19 },
    "B-4":  { height: 34,   width: 23 },
    "B-5":  { height: 25.5, width: 31.5 },
    "B-6":  { height: 16,   width: 41 },
    "B-7":  { height: 35,   width: 13.5 },
    "B-8":  { height: 33,   width: 13.5 },
    "B-9":  { height: 33.5, width: 16 },
    "B-10": { height: 31.5, width: 16 },
    "B-11": { height: 28.5, width: 16 },
    "B-12": { height: 31,   width: 19 },
    "B-13": { height: 29,   width: 19 },
    "B-14": { height: 26,   width: 19 },
    "B-15": { height: 23,   width: 19 },
    "B-16": { height: 28.5, width: 23 },
    "B-17": { height: 26.5, width: 23 },
    "B-18": { height: 23.5, width: 23 },
    "B-19": { height: 20.5, width: 23 },
    "B-20": { height: 16.5, width: 23 },
    "B-21": { height: 24,   width: 31.5 },
    "B-22": { height: 22,   width: 31.5 },
    "B-23": { height: 19,   width: 31.5 },
    "B-24": { height: 16,   width: 31.5 },
    "B-25": { height: 12,   width: 31.5 },
    "B-26": { height: 19,   width: 41 },
    "B-27": { height: 17,   width: 41 },
    "B-28": { height: 14,   width: 41 },
    "B-29": { height: 11,   width: 41 },
    "B-30": { height: 7,    width: 41 },
    "B-31": { height: 7,    width: 28 },
    "B-32": { height: 9,    width: 23 },
    "B-33": { height: 7,    width: 31.5 },
    "B-34": { height: 41.5, width: 16 },
    "B-35": { height: 29.5, width: 23 },
    "B-36": { height: 38,   width: 13.5 },
    "B-37": { height: 36.5, width: 16 },
    "B-38": { height: 34,   width: 19 },
    "B-39": { height: 49,   width: 13.5 },
    "B-40": { height: 10,   width: 17 },
    "BA-1": { height: 44,   width: 13.5, ana: 9,  anaFukasa: 42 },
    "BA-2": { height: 41,   width: 16,   ana: 12, anaFukasa: 39 },
    "BA-3": { height: 38,   width: 19,   ana: 15, anaFukasa: 36 },
    "BA-4": { height: 34,   width: 23,   ana: 19, anaFukasa: 32 },
    "BA-5": { height: 25.5, width: 31.5, ana: 19, anaFukasa: 23.5 },
    "BA-6": { height: 16,   width: 41,   ana: 19, anaFukasa: 14 },
    "BA-7": { height: 17,   width: 23,   ana: 19, anaFukasa: 15.5 },
  };

  /* ----------------------------------------------------
     4) アテ マスター（C-x-x）
     takasa = 高さ / phi = Φ数
  ---------------------------------------------------------- */
  const ateMaster = {
    "C-1-1": { takasa: 44, phi: 13 }, "C-1-2": { takasa: 44, phi: 9 },
    "C-2-1": { takasa: 43, phi: 13 }, "C-2-2": { takasa: 43, phi: 9 },
    "C-3-1": { takasa: 42, phi: 12 }, "C-3-2": { takasa: 42, phi: 13 },
    "C-4-1": { takasa: 40, phi: 15 },
    "C-5-1": { takasa: 39.5, phi: 13 }, "C-5-2": { takasa: 39.5, phi: 15 },
    "C-6-1": { takasa: 39, phi: 18 },
    "C-7-1": { takasa: 37, phi: 18 },
    "C-8-1": { takasa: 36.75, phi: 19 },
    "C-9-1": { takasa: 35, phi: 23 },
    "C-10-1": { takasa: 33.25, phi: 20 },
    "C-11-1": { takasa: 33, phi: 23 },
    "C-13-1": { takasa: 32, phi: 20 },
    "C-14-1": { takasa: 30, phi: 20 },
    "C-15-1": { takasa: 28.5, phi: 13 }, "C-15-2": { takasa: 28.5, phi: 22 },
    "C-16-1": { takasa: 28, phi: 22 },
    "C-17-1": { takasa: 27.5, phi: 13 },
    "C-18-1": { takasa: 25, phi: 20 },
    "C-19-1": { takasa: 24.5, phi: 20 },
    "C-20-1": { takasa: 22, phi: 30 }, "C-20-2": { takasa: 22, phi: 23 },
    "C-21-1": { takasa: 21.5, phi: 15 },
    "C-22-1": { takasa: 18, phi: 20 },
    "C-23-1": { takasa: 17.5, phi: 30 },
    "C-24-1": { takasa: 15, phi: 30 },
    "C-25-1": { takasa: 12, phi: 30 },
    "C-26-1": { takasa: 11.5, phi: 30 },
    "C-27-1": { takasa: 11.25, phi: 30 },
    "C-28-1": { takasa: 10.25, phi: 30 },
    "C-29-1": { takasa: 5, phi: 30 },
    "C-30-1": { takasa: 3, phi: 30 }, "C-30-2": { takasa: 3, phi: 35 },
    "C-31-1": { takasa: 4.5, phi: 35 },
    "C-32-1": { takasa: 6, phi: 30 },
    "C-33-1": { takasa: 7, phi: 30 },
    "C-34-1": { takasa: 8, phi: 30 },
    "C-35-1": { takasa: 9, phi: 30 },
    "C-36-1": { takasa: 10, phi: 25 }, "C-36-2": { takasa: 10, phi: 30 }, "C-36-3": { takasa: 10, phi: 39 },
    "C-37-1": { takasa: 10.5, phi: 25 }, "C-37-2": { takasa: 10.5, phi: 30 }, "C-37-3": { takasa: 10.5, phi: 39 },
    "C-38-1": { takasa: 11, phi: 30 },
    "C-39-1": { takasa: 11.5, phi: 25 },
    "C-40-1": { takasa: 12, phi: 25 }, "C-40-2": { takasa: 12, phi: 39 },
    "C-41-1": { takasa: 13, phi: 25 }, "C-41-2": { takasa: 13, phi: 30 },
    "C-42-1": { takasa: 13.3, phi: 61.4 },
    "C-43-1": { takasa: 14.45, phi: 25 },
    "C-44-1": { takasa: 14.5, phi: 25 },
    "C-45-1": { takasa: 15, phi: 20 },
    "C-46-1": { takasa: 15.5, phi: 30 }, "C-46-2": { takasa: 15.5, phi: 39 }, "C-46-3": { takasa: 15.5, phi: 45 },
    "C-47-1": { takasa: 17, phi: 20 }, "C-47-2": { takasa: 17, phi: 30 },
    "C-48-1": { takasa: 17.5, phi: 30.6 },
    "C-49-1": { takasa: 18.5, phi: 19 },
    "C-50-1": { takasa: 19, phi: 30 },
    "C-51-1": { takasa: 20, phi: 20 }, "C-51-2": { takasa: 20, phi: 25 },
    "C-52-1": { takasa: 20.5, phi: 20 },
    "C-53-1": { takasa: 22.4, phi: 40 },
    "C-54-1": { takasa: 23.5, phi: 60 },
    "C-55-1": { takasa: 24, phi: 20 },
    "C-56-1": { takasa: 25.5, phi: 16 },
    "C-57-1": { takasa: 27, phi: 16 },
    "C-58-1": { takasa: 27.5, phi: 16 },
    "C-59-1": { takasa: 28, phi: 18 }, "C-59-2": { takasa: 28, phi: 20 },
    "C-60-1": { takasa: 29, phi: 14 },
    "C-61-1": { takasa: 29.5, phi: 13 },
    "C-62-1": { takasa: 30, phi: 18 }, "C-62-2": { takasa: 30, phi: 23 }, "C-62-3": { takasa: 30, phi: 31.7 },
    "C-63-1": { takasa: 30.5, phi: 15.5 }, "C-63-2": { takasa: 30.5, phi: 50.4 },
    "C-64-1": { takasa: 31, phi: 18 },
    "C-65-1": { takasa: 31.5, phi: 12 }, "C-65-2": { takasa: 31.5, phi: 13 },
    "C-66-1": { takasa: 32.5, phi: 16 },
    "C-67-1": { takasa: 33, phi: 20 }, "C-67-2": { takasa: 33, phi: 22 },
    "C-68-1": { takasa: 33.25, phi: 20 }, "C-68-2": { takasa: 33.25, phi: 18 },
    "C-69-1": { takasa: 34, phi: 20 }, "C-69-2": { takasa: 34, phi: 22 },
    "C-70-1": { takasa: 35, phi: 18 }, "C-70-2": { takasa: 35, phi: 23 },
    "C-71-1": { takasa: 35.5, phi: 13 },
    "C-72-1": { takasa: 36, phi: 13 },
    "C-73-1": { takasa: 36.75, phi: 19 },
    "C-74-1": { takasa: 37, phi: 16.2 }, "C-74-2": { takasa: 37, phi: 18 },
    "C-75-1": { takasa: 37.5, phi: 15 }, "C-75-2": { takasa: 37.5, phi: 18 }, "C-75-3": { takasa: 37.5, phi: 20 },
    "C-76-1": { takasa: 38, phi: 15 }, "C-76-2": { takasa: 38, phi: 13.3 }, "C-76-3": { takasa: 38, phi: 18 },
    "C-77-1": { takasa: 38.5, phi: 18 }, "C-77-2": { takasa: 38.5, phi: 13.3 },
    "C-78-1": { takasa: 39, phi: 30 },
    "C-79-1": { takasa: 40.5, phi: 13 }, "C-79-2": { takasa: 40.5, phi: 15 }, "C-79-3": { takasa: 40.5, phi: 17 }, "C-79-4": { takasa: 40.5, phi: 20 },
    "C-80-1": { takasa: 41, phi: 15 },
    "C-81-1": { takasa: 41.5, phi: 13 },
    "C-82-1": { takasa: 42, phi: 9 },
    "C-83-1": { takasa: 42.5, phi: 9 }, "C-83-2": { takasa: 42.5, phi: 13 },
    "C-84-1": { takasa: 45, phi: 9 },
    "C-85-1": { takasa: 6.3, phi: 39 },
    "C-86-1": { takasa: 12.5, phi: 40 },
  };

  /* ----------------------------------------------------
     5) ワークオフセット手動入力機械
     G10 によるオフセット変更がオプション機能のため自動切替できない機械。
     該当機械を選択した場合、出力テキストの ATE 行は mm 表記なし、
     最終行は G10L2P0Z...(WORK-OFFSET)
              M1(NYUURYOKU) 形式になる。
  ---------------------------------------------------------- */
  const MANUAL_OFFSET_KIKAI = ["NCL-003", "NCL-012", "NCL-013", "NCL-044"];

  function isManualOffsetKikai(kikaiNo) {
    return MANUAL_OFFSET_KIKAI.includes(kikaiNo);
  }

  /* ----------------------------------------------------
     6) トルク デフォルト値
     基本値を変更したい場合はこの数値を書き換えてください。
  ---------------------------------------------------------- */
  const DEFAULT_TORUKU = 7;

  /* ----------------------------------------------------
     7) 作成者名 マスター
     ここに名前を追加・削除すると、画面のボタンに反映されます（自動で列が増減します）。
     追加する名前は次のルールを守ってください（NCプログラムのヘッダーにそのまま出力されるため）：
       ・10文字以内
       ・半角英数字・ピリオド（.）・スラッシュ（/）のみ使用可
  ---------------------------------------------------------- */
  const sakuseishaMaster = [
    "Y.YAMADA",
    "R.SIKATA",
    "H.SAWADA",
    "Y.MURAKAMI",
    "K.TANIGUTI",
    "T.SIKATA",
    "D.MORISITA",
    "Y.YANO",
    "RIN",
    "H.SASAKI",
    "DAI",
    "NAKATANI",
    "FUJIMOTO",
  ];

  /* ----------------------------------------------------
     8) 計算関数
     ─────────────────────────────────────────────────────
     【処理の全体的な流れ】

       「加工する機械No.を選んでください」 → kikaiMaster から爪長さ・オフセット値・鉄ゲタNo.初期値などを取得
                                          （同じ画面内で鉄ゲタNo.も自動セット・手動変更が可能）
                ↓
       「加工後の全長を入力してください」「加工長さを入力してください」を入力
                ↓
       「塩ビ高さの目安を確認してください」 calcEnbiGuide → 塩ビゲタの「目安の高さ」を計算して画面に表示
                ↓
       「塩ビゲタNo.を選んでください」 getEnbiRecommendations → 目安に近い塩ビゲタを上位5件に絞って
                                   画面のおすすめカードに表示。作業者が選ぶ。
                ↓
       「オフセット値を確認してください」 calcOffset → 選んだ塩ビ・鉄ゲタ・全長をもとに
                       Z軸のワーク原点オフセット値を計算して画面に表示
                ↓
       「下アテから中心までの距離を入力してください」「アテNo.を選んでください」 → calcAteTakasa でアテ高さを計算
                ↓
       「締め付けトルクを入力してください（N）」以降はトルク・横ゲタ・作成者を入力
                ↓
       最終 generateOutputText → すべての入力値と計算結果を
                                  CNCプログラムに貼り付けるテキストとして組み立てる
     ─────────────────────────────────────────────────────
  ---------------------------------------------------------- */

  /*
   * 【calcEnbiGuide】「塩ビ高さの目安を確認してください」の画面で表示される「塩ビゲタ 目安の高さ」を計算する
   *
   * 目的：
   *   ワークをチャックで正しくつかんだとき、ゲタ頂点が加工原点にぴったり
   *   合うために必要な塩ビゲタの高さを逆算する。
   *
   * 式：
   *   ツメ長さ － 鉄ゲタ高さ － (全長 － 加工長さ) ＋ 突き出し量(2mm)
   *
   * 受け取る値：
   *   tumeNagasa      … 機械のツメ長さ（kikaiMaster から自動取得）
   *   tetsugetaTakasa … 「加工する機械No.を選んでください」の画面で選んだ鉄ゲタNo.をもとに
   *                     tetsugetaMaster から取得した高さ
   *   zenchou         … 「加工後の全長を入力してください」の画面で入力した「加工後の全長」
   *   kakouNagasa     … 「加工長さを入力してください」の画面で入力した「加工長さ」
   *
   * 渡す先：
   *   → 「塩ビ高さの目安を確認してください」の画面に「目安 〇〇mm」として表示
   *   → getEnbiRecommendations に渡して、近い塩ビゲタを絞り込む
   */
  function calcEnbiGuide(tumeNagasa, tetsugetaTakasa, zenchou, kakouNagasa) {
    if ([tumeNagasa, tetsugetaTakasa, zenchou, kakouNagasa].some(v => v === null || v === undefined || v === "" || isNaN(v))) {
      return null;
    }
    return tumeNagasa - tetsugetaTakasa - (zenchou - kakouNagasa) + 2;
  }

  /*
   * 【calcOffset】「オフセット値を確認してください」の画面で表示される「Zオフセット値」を計算する
   *
   * 目的：
   *   機械に G10 L2 P0 Z〇〇 として書き込む数値を求める。
   *   これがCNCプログラムのワーク原点（Z軸の基準位置）になる。
   *
   * 機種によって計算式が異なる（座標の基準方向が逆のため）：
   *   森精機：機械オフセット値 － 塩ビ高さ － 全長 － 鉄ゲタ高さ
   *   ツガミ ：機械オフセット値 ＋ (塩ビ高さ ＋ 全長 ＋ 鉄ゲタ高さ)
   *
   * 受け取る値：
   *   kishu           … 機種区分（"森精機〇〇" or "ツガミ"、kikaiMaster から自動取得）
   *   kikaiOffset     … 機械固有のオフセット値（kikaiMaster に登録済みの固定値）
   *   enbiTakasa      … 「塩ビゲタNo.を選んでください」の画面で選んだ塩ビゲタの高さ（enbiGetaMaster から自動取得）
   *   zenchou         … 「加工後の全長を入力してください」の画面で入力した「加工後の全長」
   *   tetsugetaTakasa … 「加工する機械No.を選んでください」の画面で選んだ鉄ゲタの高さ（tetsugetaMaster から自動取得）
   *
   * 渡す先：
   *   → 「オフセット値を確認してください」の画面に「Zオフセット値：〇〇」として表示（作業者が確認）
   *   → generateOutputText に渡して "G10 L2 P0 Z〇〇" の行を生成する
   */
  function calcOffset(kishu, kikaiOffset, enbiTakasa, zenchou, tetsugetaTakasa) {
    if ([kikaiOffset, enbiTakasa, zenchou, tetsugetaTakasa].some(v => v === null || v === undefined || v === "" || isNaN(v))) {
      return null;
    }
    if (kishu === "ツガミ") {
      return kikaiOffset + (enbiTakasa + zenchou + tetsugetaTakasa);
    }
    return kikaiOffset - enbiTakasa - zenchou - tetsugetaTakasa;
  }

  /*
   * 【calcAteTakasa】「アテNo.を選んでください」の画面で表示される「アテの高さ」を計算する
   *
   * 目的：
   *   下アテの中心位置から、使うべきアテの高さを逆算する。
   *   チャックの中心高さ（50mm 固定）から中心距離を引いた値がアテ高さになる。
   *
   * 式：  50 － 下アテから中心までの距離
   *
   * 受け取る値：
   *   chushinKyori … 「下アテから中心までの距離を入力してください」の画面で入力した「下アテから中心までの距離（mm）」
   *
   * 渡す先：
   *   → 「アテNo.を選んでください」の画面に「計算されたアテ高さ：〇〇mm」として表示
   *   → 表示された高さをもとに作業者がアテNo.（C-xx-xx）を選ぶ
   */
  function calcAteTakasa(chushinKyori, kijunTakasa = 50) {
    if (chushinKyori === null || chushinKyori === undefined || chushinKyori === "" || isNaN(chushinKyori)) {
      return null;
    }
    return Number(kijunTakasa) - Number(chushinKyori);
  }

  /*
   * 【getEnbiRecommendations】「塩ビゲタNo.を選んでください」の画面のおすすめカードを作る
   *
   * 目的：
   *   calcEnbiGuide で求めた「目安の高さ」に近い塩ビゲタを
   *   差が小さい順に並べ替え、上位5件をおすすめとして返す。
   *   目安が計算できない場合は高さ順で全件を返す。
   *
   * 受け取る値：
   *   guideHeight … calcEnbiGuide の計算結果（目安の高さ mm）
   *
   * 渡す先：
   *   → 「塩ビゲタNo.を選んでください」の画面のおすすめカード（上位5件）と「全件リスト」の両方に渡す
   */
  function getEnbiRecommendations(guideHeight) {
    const hasGuide = !(guideHeight === null || guideHeight === undefined || isNaN(guideHeight));

    const entries = Object.entries(enbiGetaMaster).map(([key, v]) => {
      const diff = hasGuide ? Math.abs(v.height - guideHeight) : null;
      return {
        key,
        height: v.height,
        width: v.width,
        ana: v.ana ?? null,
        anaFukasa: v.anaFukasa ?? null,
        diff,
      };
    });

    if (hasGuide) {
      const sorted = [...entries].sort((a, b) => a.diff - b.diff);
      const recommended = sorted.filter(item => item.height >= guideHeight && item.diff <= 3);
      return { recommended, all: sorted };
    } else {
      const byHeight = [...entries].sort((a, b) => a.height - b.height);
      return { recommended: [], all: byHeight };
    }
  }

  /*
   * 【getAteRecommendations】「アテNo.を選んでください」の画面のおすすめアテカードを作る
   *
   * 目的：
   *   calcAteTakasa で求めた「アテ高さ目安」に対して、差が3mm以内の
   *   アテを高さ差が小さい順に並べておすすめとして返す（Φ＝13を含む全アテが対象）。
   *   目安が計算できない場合は高さ順で全件を返す。
   *
   * 受け取る値：
   *   guideHeight … calcAteTakasa の計算結果（アテ高さの目安 mm）
   *
   * 渡す先：
   *   → 「アテNo.を選んでください」の画面のおすすめカードと「全件リスト」の両方に渡す
   */
  function getAteRecommendations(guideHeight) {
    const hasGuide = !(guideHeight === null || guideHeight === undefined || isNaN(guideHeight));

    const entries = Object.entries(ateMaster).map(([key, v]) => {
      const diff = hasGuide ? Math.abs(v.takasa - guideHeight) : null;
      return { key, takasa: v.takasa, phi: v.phi, diff };
    });

    if (hasGuide) {
      const sorted = [...entries].sort((a, b) => a.diff - b.diff);
      const recommended = sorted.filter(item => item.diff <= 3);
      return { recommended, all: sorted };
    } else {
      const byHeight = [...entries].sort((a, b) => a.takasa - b.takasa);
      return { recommended: [], all: byHeight };
    }
  }

  /*
   * 【fmt】数値の見た目を整える（内部用ヘルパー）
   *
   * 目的：
   *   計算結果の小数点以下に不要な 0 が並ばないよう整形する。
   *   例）150.9250 → "150.925"、101.0000 → "101"
   *
   * 渡す先：
   *   → 画面上の表示と、generateOutputText 内の G10 行の数値に使用
   */
  function fmt(num) {
    if (num === null || num === undefined || isNaN(num)) return "";
    return Number(num.toFixed(4)).toString();
  }

  /*
   * 【generateOutputText】CNCプログラムに貼り付けるヘッダーテキストを組み立てる
   *
   * 目的：
   *   フォームで集めた全情報（機械No.・ゲタNo.・アテNo.・トルク・作成者など）と
   *   calcOffset で計算したZオフセット値を使って、最終的なテキストを生成する。
   *   作業者はこのテキストをコピーしてCNCプログラムの先頭に貼り付ける。
   *
   * 受け取る値：
   *   date        … 実行日（自動取得）
   *   kikaiNo     … 選んだ機械No.
   *   tetsugetaNo … 選んだ鉄ゲタNo.
   *   enbiGetaNo  … 選んだ塩ビゲタNo.
   *   ateNo       … 選んだアテNo.
   *   toruku      … 入力した締め付けトルク
   *   yokogeta    … 横ゲタ あり／なし
   *   sakuseisha  … 入力した作成者名
   *   offsetValue … calcOffset の計算結果（Zオフセット値）
   *
   * 出力形式（半角のみ）：
   *   (日付)
   *   (作成者)
   *   (TETUGETA=鉄ゲタNo.)
   *   (ATE=アテNo.)(調整用ワッシャーmm)  … すべての機械で共通表記
   *   (ENNBI=塩ビNo.)
   *   (KIKAI=機械No.)
   *   (TORUKU=トルク)
   *   (YOKOGETA=横塩ビ)
   *   G10L2P0Zオフセット値(WORK-OFFSET)M1(NYUURYOKU)
   */
  function generateOutputText(data) {
    const {
      date, kikaiNo, tetsugetaNo, enbiGetaNo, ateNo,
      toruku, yokogeta, sakuseisha, offsetValue, ateDiff
    } = data;

    const labeled = (label, value) => `(${label}=${value ?? ""})`;

    const yokogetaOut = yokogeta === "なし" ? "0" : yokogeta === "あり" ? "1" : (yokogeta ?? "");
    const enbiOut = enbiGetaNo === "なし 0" ? "0" : (enbiGetaNo ?? "");

    let ateLine = labeled("ATE", ateNo);
    if (ateDiff !== null && ateDiff !== undefined && !isNaN(ateDiff) && Math.abs(ateDiff) >= 0.01) {
      const diffStr = ateDiff >= 0 ? fmt(ateDiff) : `-${fmt(Math.abs(ateDiff))}`;
      ateLine += `(${diffStr}mm)`;
    }

    const lines = [
      `(${date ?? ""})`,
      `(${sakuseisha ?? ""})`,
      labeled("TETUGETA", tetsugetaNo),
      ateLine,
      labeled("ENNBI", enbiOut),
      labeled("KIKAI", kikaiNo),
      labeled("TORUKU", toruku),
      labeled("YOKOGETA", yokogetaOut),
      `G10L2P0Z${fmt(offsetValue)}(WORK-OFFSET)
M1(NYUURYOKU)`,];

    return lines.join("\n");
  }

  /*
   * 【getEnbiWidthOptions】塩ビゲタに登録されている「幅」の種類を取り出す
   *
   * 目的：
   *   「塩ビゲタNo.を選んでください」の画面にある「幅で絞り込み」ボタンの選択肢を作る。
   *   一覧データ（enbiGetaMaster）から自動で集めるので、
   *   今後ゲタを追加しても選択肢は自動で増える。
   *
   * 渡す先：
   *   → 「塩ビゲタNo.を選んでください」の画面の絞り込みボタン
   */
  function getEnbiWidthOptions() {
    const set = new Set();
    Object.values(enbiGetaMaster).forEach(v => {
      if (v.width !== null && v.width !== undefined) set.add(v.width);
    });
    return [...set].sort((a, b) => a - b);
  }

  /*
   * 【getAtePhiOptions】アテに登録されている「Φ」の種類を取り出す
   *
   * 目的：
   *   「アテNo.を選んでください」の画面にある「Φで絞り込み」ボタンの選択肢を作る。
   *   一覧データ（ateMaster）から自動で集めるので、
   *   今後アテを追加しても選択肢は自動で増える。
   *
   * 渡す先：
   *   → 「アテNo.を選んでください」の画面の絞り込みボタン
   */
  function getAtePhiOptions() {
    const set = new Set();
    Object.values(ateMaster).forEach(v => {
      if (v.phi !== null && v.phi !== undefined) set.add(v.phi);
    });
    return [...set].sort((a, b) => a - b);
  }

  /*
   * 【getEnbiAnaOptions】塩ビゲタに登録されている「穴Φ」の種類を取り出す
   *
   * 目的：
   *   「塩ビゲタNo.を選んでください」の画面にある「Φで絞り込み」ボタンの選択肢を作る。
   *   穴あき治具（BA-*）の ana から自動で集めるので、
   *   今後ゲタを追加しても選択肢は自動で増える。
   *
   * 渡す先：
   *   → 「塩ビゲタNo.を選んでください」の画面の絞り込みボタン
   */
  function getEnbiAnaOptions() {
    const set = new Set();
    Object.values(enbiGetaMaster).forEach(v => {
      if (v.ana !== null && v.ana !== undefined) set.add(v.ana);
    });
    return [...set].sort((a, b) => a - b);
  }

  return {
    kikaiMaster,
    tetsugetaMaster,
    enbiGetaMaster,
    ateMaster,
    sakuseishaMaster,
    MANUAL_OFFSET_KIKAI,
    DEFAULT_TORUKU,
    isKikaiComplete,
    isManualOffsetKikai,
    calcEnbiGuide,
    calcOffset,
    calcAteTakasa,
    getEnbiRecommendations,
    getAteRecommendations,
    getEnbiWidthOptions,
    getEnbiAnaOptions,
    getAtePhiOptions,
    fmt,
    generateOutputText,
  };

})();

// ブラウザのグローバルスコープに公開（index.html から Logic.xxx で参照）
if (typeof window !== "undefined") {
  window.Logic = Logic;
}