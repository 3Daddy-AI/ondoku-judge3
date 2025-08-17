import SwiftUI

struct PracticeFlowView: View {
    @ObservedObject var store: ProgressStore
    @State private var textSource: String = ""
    @State private var sentences: [String] = []
    @State private var idx: Int = 0
    @State private var isRecording = false
    @State private var coordinator: RecordingCoordinator? = nil
    @State private var startTime: Date = .init()
    @State private var lastReport: JudgeReport? = nil
    @State private var advice: String = ""
    @State private var stars: Int = 0

    var body: some View {
        VStack(spacing: 12) {
            if sentences.isEmpty {
                ImportTextView(referenceText: $textSource) {
                    sentences = SentenceSplitter.split(textSource)
                }
            } else {
                Text("だんらく \(idx+1) / \(sentences.count)")
                ScrollView { Text(sentences[idx]).font(.title3).frame(maxWidth: .infinity, alignment: .leading) }
                HStack { Button("まえへ") { idx = max(0, idx-1) }.disabled(idx==0); Spacer(); Button("つぎへ") { idx = min(sentences.count-1, idx+1) } }
                Button(isRecording ? "よみあげ中... 停止" : "この だんらくを よむ") {
                    if !isRecording {
                        #if canImport(WhisperKit)
                        coordinator = RecordingCoordinator(asr: WhisperASRService())
                        #else
                        coordinator = RecordingCoordinator(asr: StubASRService())
                        #endif
                        do { try coordinator?.start { _ in } ; isRecording = true; startTime = Date() } catch { print(error) }
                    } else {
                        coordinator?.stop(referenceText: sentences[idx]) { report in
                            isRecording = false
                            lastReport = report
                            advice = report.advice
                            stars = report.stars
                            let result = SessionResult(
                                id: UUID(),
                                date: Date(),
                                title: String(sentences[idx].prefix(18)),
                                overall: report.overall,
                                accuracy: report.accuracyScore,
                                speed: report.speedScore,
                                pause: report.pauseScore,
                                durationSec: report.durationSec,
                                cer: report.cer,
                                charsPerMinute: report.charsPerMinute,
                                stars: report.stars,
                                advice: report.advice
                            )
                            store.add(result)
                            if report.stars >= 2 { Feedback.success() } else { Feedback.warning() }
                        }
                    }
                }.buttonStyle(.borderedProminent)

                if let r = lastReport {
                    ZStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            DiffTextView(preview: r.opsPreview)
                            Text("🌟 x\(stars)  すこあ \(Int(r.overall))てん").font(.headline)
                            Text(advice).foregroundColor(.secondary)
                            HStack {
                                Button("もういちど この だんらく") {
                                    lastReport = nil
                                }
                                .buttonStyle(.bordered)
                                Spacer()
                            }
                        }
                        if stars >= 3 { ConfettiView().frame(height: 0) }
                    }
                }

                Spacer()
            }
        }
        .padding()
        .navigationTitle("れんしゅう")
        .onChange(of: isRecording) { now in
            if now == false {
                // `RecordingCoordinator` の stop 内で JudgeEngine が走るので、
                // ここでは Progress への保存をまとめて行うには、Coordinator から詳細を返す拡張が必要。
            }
        }
    }
}
