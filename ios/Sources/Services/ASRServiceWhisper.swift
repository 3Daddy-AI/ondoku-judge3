import Foundation
import AVFoundation

#if canImport(WhisperKit)
import WhisperKit

final class WhisperASRService: ASRServiceProtocol {
    private var pipeline: WhisperKit? = nil
    private var audioData = Data()

    func start(session: AVAudioSession, onText: @escaping (String) -> Void) {
        // WhisperKitは現状バッチ推奨。録音中は蓄積のみ行う。
        audioData.removeAll(keepingCapacity: true)
    }

    func appendBuffer(_ buffer: AVAudioPCMBuffer, sampleRate: Double) {
        // 16kHzモノラル16bitリトルエンディアンに正規化しDataに追記
        let frameLen = Int(buffer.frameLength)
        guard let ch = buffer.floatChannelData?[0] else { return }
        var pcm16 = [Int16](repeating: 0, count: frameLen)
        for i in 0..<frameLen { pcm16[i] = Int16(max(-1.0, min(1.0, ch[i])) * 32767.0) }
        pcm16.withUnsafeBytes { audioData.append($0.bindMemory(to: UInt8.self)) }
    }

    func stop(completion: @escaping (String) -> Void) {
        // 簡易にWAVラッパを生成し、WhisperKitで一括認識
        guard let pipeline = try? WhisperKit() else { completion(""); return }
        self.pipeline = pipeline
        let wav = Self.makeWav(fromPCM16: audioData, sampleRate: 16000)
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("rec.wav")
        try? wav.write(to: tmp)
        Task {
            let result = try? await pipeline.transcribe(audioPath: tmp.path, model: .base)
            completion(result?.text ?? "")
        }
    }

    private static func makeWav(fromPCM16 data: Data, sampleRate: Int) -> Data {
        // 最小限のWAVヘッダ生成（PCM16 mono）
        var out = Data()
        func append(_ v: UInt32) { var x = v.littleEndian; withUnsafeBytes(of: &x) { out.append($0) } }
        func append16(_ v: UInt16) { var x = v.littleEndian; withUnsafeBytes(of: &x) { out.append($0) } }
        out.append("RIFF".data(using: .ascii)!)
        append(UInt32(36 + data.count))
        out.append("WAVEfmt ".data(using: .ascii)!)
        append(UInt32(16))
        append16(1) // PCM
        append16(1) // mono
        append(UInt32(sampleRate))
        append(UInt32(sampleRate * 2)) // byte rate
        append16(2) // block align
        append16(16) // bits
        out.append("data".data(using: .ascii)!)
        append(UInt32(data.count))
        out.append(data)
        return out
    }
}
#endif

