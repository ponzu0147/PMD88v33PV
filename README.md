# PMD88v33PV

## 概要
`PMD88v33PV`は、PC-8801シリーズ向けの音楽ドライバ「PMD88」バージョン3.3を拡張するサポートツールです。このプログラムは、PMD88の既存の再生処理をフックし、以下の機能を提供します：
- **音色表示**: FM、SSG、ADPCM、リズム音源の各チャンネルで再生中の音名や状態をリアルタイムに表示。
- **ミュート制御**: キー入力により、FM（6チャンネル）、SSG（3チャンネル）、ADPCM、リズム音源の各パートを個別にミュートまたは再生状態に切り替え。
- **全音ミュート**: 「^」キーで全チャンネルを一括ミュート/解除。

このツールは、レトロコンピューティング愛好家やPMD88を使用した音楽制作・デバッグを行うユーザーに特に有用です。

## 主な機能と特徴

### 1. PMD88へのフック
プログラムは、PMD88v3.3の特定のサブルーチンをフックして動作を拡張します：
- **PMDHK1 (0AA5FH)**: 音楽再生メインルーチンをフックし、各チャンネルの再生処理を監視・制御。
- **PMDHK2 (0B9CAH)**: ボリューム制御（`VOLPUSH_CALC`）をフックし、ミュート状態を反映。
- **PMDHK3 (0B70EH)**: リズム音源のキーオン処理（`RHYSET`）をフックし、音色表示や制御を追加。

これにより、PMD88の動作を維持しつつ新たな機能をシームレスに統合しています。

### 2. 音色表示
- **FMチャンネル (FM1〜FM6)**: PMD88のワークエリアからFNUM（11ビット）を取得し、音名（例: C, C+, D）とオクターブを表示。
- **SSGチャンネル (SSG1〜SSG3)**: PSGのトーン値を解析し、96段階の音階から音名とオクターブを計算して表示。
- **ADPCM**: 再生中を示す「AD」を表示。
- **リズム音源**: 6種類（BD, SD, CY, HH, TM, RM）の発音状態を2文字で表示し、タイマーによる自動消去を実装。

表示は画面の特定位置（例: `0F440H`〜）にテキストとして出力され、アトリビュート設定により視認性を向上させています。

### 3. ミュートと再生制御
- **キー入力による操作**: ポート5〜7のキー状態を監視し、各チャンネルに対応するキーの押下でミュート/再生をトグル。
  - FM1〜FM6: ポート6のBIT0〜5
  - SSG1〜SSG3: ポート6のBIT6〜7、ポート7のBIT0
  - ADPCM: ポート7のBIT1
  - リズム: ポート5のBIT7
  - 全音ミュート: ポート5のBIT6（^キー）
- **ミュート実装**: ミュートフラグ（`MUTEFLG`）を操作し、ボリュームを最小値に設定（例: FMは-63、SSGは-15、ADPCMは-255、リズムは0）。
- **視覚的フィードバック**: ミュート状態ではアトリビュートを青色（`028H`）、再生中は白色（`0E8H`）に変更。

### 4. リズム音源の特殊処理
- **音色表示タイマー**: リズム音源の発音後、一定時間（`INITTMV`=80フレーム）経過で表示を消去。
- **キーオン処理**: PMD88のキーオンデータを解析し、発音中の音色を画面に反映。

### 5. 初期化とワークエリア
- **初期化**: FM/SSG/ADPCM/リズムのワークアドレスをポインタとして設定し、デフォルト音量（`3CH`）を適用。
- **ワークエリア**: PMD88の既存データ（例: `0BD60H`〜）を利用しつつ、独自の変数（`MUTEFLG`, `KEY_STATE`など）を定義。

## 使用方法

### 1. 環境準備
- **PC-8801エミュレータ**: M88などのエミュレータまたは実機。
- **Z80アセンブラ**: `zasm`（例: バージョン4.4.10）を使用。
- **シェル環境**: macOSやLinuxなど、シェルスクリプトを実行可能な環境。
- **Windows環境**: D88ファイル操作用にコマンドプロンプトと`d88saver`ツール。

### 2. ビルド方法
以下の手順で`test40.asm`をアセンブルし、実行可能なROMファイル（`main.rom`）を生成します。パスはユーザーの環境に合わせて適宜変更してください。

#### シェルスクリプト例
```bash
#!/bin/sh
# ユーザー名を自分の環境に置き換えてください（例: /Users/[YourUsername]/...）
cp /Users/[YourUsername]/PMD88v33PV/test40.asm ~/Documents/zasm-4.4.10-macos10.12/pc88-asm/test/main.z80
make PROJECT=test
cp ./test/main.rom /Users/[YourUsername]/Downloads/pvcg/pvc
```

### 3. 実行
- PMD88v3.3と一緒にメモリにロード（開始アドレス: 08800H）。
- キー操作でミュートや音色表示を確認。

### キー操作
- FM1〜FM6, SSG1〜3, ADPCM, リズム: 対応するキーでトグル。
- ^キー: 全チャンネルミュート/解除。

## 技術的詳細
- **開始アドレス**: 08800H
- **依存関係**: PMD88v3.3専用（他のバージョンではアドレスが異なる可能性あり）。

### 主要サブルーチン
- **MUTECHK**: キー入力とミュート状態の監視。
- **DSPCH**: 各チャンネルの音名表示。
- **RHYDSP**: リズム音源の表示とキーオン処理。
- **CHMUTE**: ミュート時のボリューム制御。

### 制限
PMD88のメモリレイアウトに依存するため、カスタム改造版PMDでは動作しない可能性があります。

## 開発者向け情報
- **拡張性**: 新しいキー操作や表示項目を追加する際は、MUTECHKやDSPCHを修正。
- **デバッグ**: 音名表示やミュート状態をログ出力する機能を追加可能。

## ライセンス

このプロジェクトは以下のデュアルライセンス構成で提供されています：

1. **PMD88オリジナルコード**：
   - PMD88の原作者が著作権を保持しています。
   - 原作者の同意なく改変・再配布することはできません。
   - 使用にあたっては原作者の利用条件に従ってください。

2. **PMD88v33PV拡張部分**（私が作成したコード）：
   - MIT License の下で提供されています。
   - 改変、再配布、商用利用が可能です。
   - ただし、著作権表示とライセンス表示を維持してください。

MIT License（拡張部分のみ適用）:
Copyright (c) 2023-2025 Ponzu/Masato Koshikawa

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.