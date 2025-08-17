# iPad 向け 音読判定 アプリ（設計とスケルトン）

要件に合わせたiOS（iPadOS）ネイティブ構成の最小スケルトンです。

- OCR: Visionの`VNRecognizeTextRequest`で画像/カメラ/PDFレンダリング結果をOCR
- ASR: Whisper（on-device, WhisperKit など）または Vosk-iOS（軽量）
- 判定: 文字整列（CER）、速度（文字/分）、ポーズ、音量、総合スコア
- UI: 児童向け（録音ガイド→読み→結果フィードバック）

## 推奨構成

- 最初は WhisperKit（CoreML化済みのwhisperモデル）を提案
  - `base`/`small`モデルで短文向け、Wi‑Fi可ならサーバ推論も併用可能
- PDF処理は PDFKit で各ページを UIImage にレンダリング→VisionでOCR
- 参照テキストはOCR後に児童/先生が画面で最小修正できるよう簡易エディタを用意

## セキュリティ/プライバシー

- 既定はオンデバイス処理（音声・画像の外部送信なし）
- サーバASRを使う場合は保護者/校内ポリシーに従い、匿名化/同意/削除方針を明示

## ビルドのポイント

- ターゲット iPadOS 16 以降推奨（Vision/AVAudio/PDFKitが安定）
- マイク/カメラ/フォトライブラリ利用許可（`Info.plist`）
- WhisperKit or Vosk-iOS を Swift Package / CocoaPods で追加

このディレクトリには SwiftUI スケルトンと、判定ロジックのSwift実装が含まれます。

## ソース構成

- `Sources/App.swift` / `Sources/ContentView.swift`: SwiftUI画面（児童向けの4ステップ）
- `Sources/Views/HomeView.swift`: ホーム（連続日数・履歴・練習開始）
- `Sources/Views/PracticeFlowView.swift`: 段落ごと練習フロー（録音→判定→助言）
- `Sources/Views/DiffTextView.swift`: 差分の色分け表示
- `Sources/Views/SpeedIndicatorView.swift`: 速度の目安表示（シンプル）
- `Sources/Core/Normalization.swift`: NFKC＋句読点/空白除去の正規化
- `Sources/Core/Alignment.swift`: 文字単位レーベンシュタイン整列＋CER
- `Sources/Core/Scoring.swift`: 速度算出と重み付きスコア
- `Sources/Services/OCRService.swift`: Vision＋PDFKitでOCR
- `Sources/Services/ASRService.swift`: ASRプロトコルとスタブ（Whisper/Vosk差し替え想定）
- `Sources/Services/AudioFeatures.swift`: RMS/ポーズ検出（20ms/10ms）
- `Sources/Services/RecordingCoordinator.swift`: 録音→ASR→判定の統合
- `Sources/JudgeEngine.swift`: 一括判定（プレビュー文字列含む）
- `Sources/Models/SessionModels.swift` / `Sources/Stores/ProgressStore.swift`: 結果履歴・連続日数の管理

## 実装タスク（次の一手）

- ASR統合: WhisperKit（CoreML Whisper）または Vosk-iOS を採用し `ASRServiceProtocol` を実装
- 録音: `AVAudioEngine` で16kPCMを収集、ASRに流しつつ `AudioFeatures` で統計を計算
- OCR改善: ルビ除去のヒューリスティクス（小さなバウンディングボックスを除外）
- 児童向けUI: 大ボタン、色分け、結果のわかりやすい言い換え
- バッジ/ごほうび: スコアしきい値でアイコン付与、連続日数で特別スタンプ
- データ保護: 端末内のみ保存（既定は保存しない）、保存時は暗号化/日付別フォルダ

## メモ

- 参照テキストが漢字を含む前提で、ASR出力も漢字仮名交じり（Whisper推奨）。
- すべてひらがな比較にしたい場合は、辞書ベースの読み仮名化が必要（別途検討）。

## WhisperKit 導入のヒント

1) Swift Package Manager で追加
   - Xcode → Project → Package Dependencies → `https://github.com/argmaxinc/WhisperKit`（例）
2) モデルダウンロード（初回）
   - アプリ初回起動時に Wi‑Fi 経由で `base` などをダウンロード→端末内保存
3) 実装
   - `ASRServiceWhisper.swift` を参照（`canImport(WhisperKit)` ガード）
   - 現状はバッチ推論例。必要に応じて分割録音→並列推論→連結でレイテンシ低減
4) Info.plist の権限
   - `NSMicrophoneUsageDescription`
   - `NSCameraUsageDescription`
   - `NSPhotoLibraryUsageDescription`
   - `NSPhotoLibraryAddUsageDescription`

## 画像/PDF読み込み（子ども向けUI）
- カメラ: `CameraPicker`（撮影→OCR）
- 写真: `PhotoLibraryPicker`（iOS16+のPhotosPicker）
- PDF: `PDFPicker`（DocumentPickerでPDF→PDFKit→Vision OCR）
  - ルビ除去は今後: 小さな領域のテキストを除外するヒューリスティクスを追加予定
