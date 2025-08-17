import Foundation
import AVFoundation

final class RecordingCoordinator: NSObject {
    private let engine = AVAudioEngine()
    private let session = AVAudioSession.sharedInstance()
    private let asr: ASRServiceProtocol
    private var startTime: TimeInterval = 0
    private var sampleRate: Double = 16000
    private var collectedBuffer: AVAudioPCMBuffer?

    init(asr: ASRServiceProtocol) { self.asr = asr }

    func start(onPartial: @escaping (String) -> Void) throws {
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)

        let input = engine.inputNode
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)!
        sampleRate = format.sampleRate

        let frameCapacity = AVAudioFrameCount(sampleRate * 60) // up to 60s buffer
        collectedBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity)

        asr.start(session: session) { text in onPartial(text) }

        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self = self, let dst = self.collectedBuffer else { return }
            let writable = min(dst.frameCapacity - dst.frameLength, buffer.frameLength)
            if writable > 0 {
                let dstPtr = dst.floatChannelData![0].advanced(by: Int(dst.frameLength))
                let srcPtr = buffer.floatChannelData![0]
                dstPtr.assign(from: srcPtr, count: Int(writable))
                dst.frameLength += writable
            }
            #if canImport(WhisperKit)
            if let w = self.asr as? WhisperASRService {
                w.appendBuffer(buffer, sampleRate: self.sampleRate)
            }
            #endif
        }

        engine.prepare()
        try engine.start()
        startTime = Date().timeIntervalSince1970
    }

    func stop(referenceText: String, completion: @escaping (JudgeReport) -> Void) {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        let duration = Date().timeIntervalSince1970 - startTime
        let stats = analyzeAudio()
        asr.stop { hyp in
            let report = JudgeEngine.run(
                reference: referenceText,
                hypothesis: hyp,
                durationSec: stats?.durationSec ?? duration,
                pauses: stats?.pauses ?? 0,
                maxPauseSec: stats?.maxPauseSec ?? 0
            )
            completion(report)
        }
    }

    private func analyzeAudio() -> AudioStats? {
        guard let buf = collectedBuffer else { return nil }
        return AudioFeatures.analyze(buffer: buf, sampleRate: sampleRate)
    }
}
