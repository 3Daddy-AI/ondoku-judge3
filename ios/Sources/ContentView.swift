import SwiftUI

enum Step: Int { case importText, confirmText, record, result }

struct ContentView: View {
    @State private var step: Step = .importText
    @State private var referenceText: String = ""
    @State private var resultSummary: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                switch step {
                case .importText:
                    ImportTextView(referenceText: $referenceText) {
                        step = .confirmText
                    }
                case .confirmText:
                    ConfirmTextView(text: $referenceText) {
                        step = .record
                    }
                case .record:
                    RecordView(referenceText: referenceText) { summary in
                        resultSummary = summary
                        step = .result
                    }
                case .result:
                    ResultView(summary: resultSummary) {
                        step = .importText
                    }
                }
            }
            .padding()
            .navigationTitle("おんどくチェック")
        }
    }
}

struct ImportTextView: View {
    @Binding var referenceText: String
    var onNext: () -> Void
    @State private var showCamera = false
    @State private var showPhotos = false
    @State private var showPDF = false
    var body: some View {
        VStack(spacing: 12) {
            Text("きょうかしょのぶんしょうを よみこもう！")
            HStack {
                Button("カメラ") { showCamera = true }
                if #available(iOS 16.0, *) {
                    Button("写真") { showPhotos = true }
                }
                Button("PDF") { showPDF = true }
            }
            if !referenceText.isEmpty {
                Text(referenceText).font(.footnote).lineLimit(4)
                Button("つぎへ") { onNext() }.buttonStyle(.borderedProminent)
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker { image in
                OCRService.extractText(from: image) { text in
                    referenceText = text
                }
            }
        }
        .sheet(isPresented: $showPDF) {
            PDFPicker { url in
                OCRService.extractText(from: url) { text in
                    referenceText = text
                }
            }
        }
        .sheet(isPresented: $showPhotos) {
            if #available(iOS 16.0, *) {
                PhotoLibraryPicker { image in
                    OCRService.extractText(from: image) { text in
                        referenceText = text
                    }
                }
            } else {
                Text("iOS 16 いじょうで しゃしん せんたくが できます")
            }
        }
    }
}

struct ConfirmTextView: View {
    @Binding var text: String
    var onNext: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            Text("よみあげる ぶんしょうを かくにんしよう")
            TextEditor(text: $text).border(.gray)
            Button("よみはじめる") { onNext() }.buttonStyle(.borderedProminent)
        }
    }
}

struct RecordView: View {
    var referenceText: String
    var onFinish: (String) -> Void
    @State private var isRecording = false
    @State private var coordinator: RecordingCoordinator? = nil
    @State private var partial: String = ""
    var body: some View {
        VStack(spacing: 12) {
            Text("おちついて はっきり よもう！")
            Button(isRecording ? "よみあげ中... 停止" : "よみはじめる") {
                if !isRecording {
                    #if canImport(WhisperKit)
                    coordinator = RecordingCoordinator(asr: WhisperASRService())
                    #else
                    coordinator = RecordingCoordinator(asr: StubASRService())
                    #endif
                    do { try coordinator?.start { txt in partial = txt } ; isRecording = true }
                    catch { print("record start error: \(error)") }
                } else {
                    coordinator?.stop(referenceText: referenceText) { report in
                        isRecording = false
                        let summary = "スコア \(Int(report.overall))点 / せいかくさ \(Int(report.accuracyScore)) / すぴーど \(Int(report.speedScore)) / ぽーず \(Int(report.pauseScore))"
                        onFinish(summary)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            Text("みぎの みほんを みながら よんでね！")
            ScrollView { Text(referenceText).frame(maxWidth: .infinity, alignment: .leading) }
            if !partial.isEmpty { Text("いまのききとり: \(partial)").font(.footnote) }
        }
    }
}

struct ResultView: View {
    var summary: String
    var onRestart: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            Text("けっか").font(.title)
            Text(summary).font(.headline)
            // TODO: JudgeReport（opsPreview）を渡して DiffTextView を表示
            // DiffTextView(preview: report.opsPreview)
            Button("もういちど") { onRestart() }
        }
    }
}
