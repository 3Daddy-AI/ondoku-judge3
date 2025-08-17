# 音読判定ミニプロトタイプ（オフラインASR想定）

小学生の「音読」宿題向けに、オフラインASR（例: Vosk 日本語モデル）を用いて以下を判定する最小構成のCLIツールです。

- 正確さ: 文字ベースCER（Character Error Rate）、差分ハイライト
- 流暢さ: 文字/分、無音ポーズ回数・最長ポーズ
- 音量: RMSベースの相対dB目安

Voskモデルは別途ダウンロードが必要です（ネットワーク利用が可能な環境で取得してください）。

## セットアップ

1) 必要パッケージのインストール

```
python -m venv .venv
source .venv/bin/activate  # Windowsは .venv\Scripts\activate
pip install -r requirements.txt
```

2) Vosk日本語モデルの取得（例）

- 小サイズ: `vosk-model-small-ja-0.22`
- 標準サイズ: `vosk-model-ja-0.22`

モデルフォルダのパスを控えてください（例: `models/vosk-model-small-ja-0.22`）。

## 使い方

```
python -m ondoku_judge.judge \
  --text-file sample/passage.txt \
  --audio-file sample/passage.wav \
  --vosk-model-dir models/vosk-model-small-ja-0.22 \
  --json out.json
```

- `--text-file`: 教科書等の課題本文（UTF-8）
- `--audio-file`: 児童の音読音声（WAV, 16k/16bit/mono 推奨）
- `--vosk-model-dir`: ダウンロードしたVosk日本語モデルのディレクトリ
- `--json`: 結果のJSONを書き出し（任意）

## スコアリングの目安（暫定）

- 正確さ: `accuracy = (1 - CER) * 100` を0–100点にクリップ
- 速度: 基準 200–350 字/分（範囲内=満点、外側へ線形減点）
- ポーズ: 0.5秒以上のポーズ回数に応じて少額減点（例: 1回あたり-1点, 上限-10）
- 総合: `0.7*正確さ + 0.2*速度 + 0.1*ポーズ項`（調整可）

※ 学校や学年に合わせて閾値や重みは調整してください。

## プライバシーと運用

- すべてローカルで処理可能（クラウド送信なし）
- 音声は端末内一時ファイルで完結
- 記録保管の可否や保管期間は校内ルールに従ってください

## 既知の限界と次の一手

- ASR誤りの影響: 低年齢の発話や環境ノイズでCERが悪化
  - 対策: 環境ノイズ低減、語彙制約、強制アライメントの導入（例: aeneas, MFA）
- かな化の揺れ: 漢字読みの多様性
  - 対策: 教師用リファレンス（ふりがな）で基準読みを固定
- 音質依存: ボリューム・マイク距離・部屋の響き
  - 対策: 録音ガイダンス、簡易レベルメータ

---

このプロトタイプは学内PoC向けの最小構成です。要件に合わせてWebフロント、記録管理、判定ロジックの拡張が可能です。

