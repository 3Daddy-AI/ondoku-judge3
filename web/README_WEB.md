# 音読判定 Web PWA（GitHub Pages 配布向け）

リンクを知っていれば誰でも使える、クライアントサイドPWAの最小実装です。
- ASR: Vosk-browser（WASM, オフライン実行; 初回モデルDLが必要）
- 代替: Web Speech API（ブラウザ依存, オンライン）
- 判定: 文字整列（CER）/ 速度 / ポーズ / 総合スコア（端末内計算）

## かんたんモード（小学生向け）

- URL: `/web/kids.html`
- てきすと/しゃしん/PDF から ぶんしょうを えらぶ（しゃしん/PDF はTesseract.jsでOCR）
- ▶ よみはじめる → ■ とめる（Web Speech API）
- すこあ/🌟/さぶん（色つき）が でます

注意: iPadのSafariはWeb Speechが使えないため、かんたんモードでは録音できません。その場合はトップのしっかりモードでVoskモデルを読み込むか、PCのChromeを推奨します。

## 使い方（ローカル予行）

1) 静的サーバで起動

```
cd web
python -m http.server 8080
# ブラウザで http://localhost:8080 を開く
```

2) モデルの準備
- 右上の「モデルURL設定」に、Vosk日本語モデルのURLを入力して「読み込み」
  - 例: 自前でホストした `vosk-model-small-ja-0.22` を `https://<your-pages>/models/...` で公開
  - モデルサイズが大きい（50–150MB）ため、初回DLに時間がかかります

3) 音読判定
- 課題テキストを貼り付け or テキストファイルを読み込み
- 「録音開始」→「停止」でASR→判定、結果が表示されます

Web Speech APIを選ぶ場合は、右上のASR選択で「WebSpeech」を選択してください（Chrome推奨, iOS Safariは非対応）。

## GitHub Pages へのデプロイ

- この `web` ディレクトリの中身を、GitHub Pages の公開ルートに配置（`/` か `/docs`）
- リポジトリ → Settings → Pages でブランチを指定
- モデルは容量が大きいため、以下いずれかの方法で公開してください
  - 別リポ/ブランチでLFS管理してPages公開
  - 学内サーバやCDNへ配置し、アプリ内の「モデルURL設定」で指定

## 既知の注意
- iOS Safari はマイク利用に https が必須（Pagesはhttps対応）
- iOS SafariはWeb Speech APIの音声認識に非対応（kidsは録音不可）。
- ブラウザ/端末メモリによりWASMモデル読込が失敗する場合があります
- モデル読込に失敗した場合はエラーが出ます（WebSpeechに切替可能）
