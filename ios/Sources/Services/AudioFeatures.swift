import Foundation
import AVFoundation

struct AudioStats { let durationSec: Double; let rmsDb: Double; let pauses: Int; let maxPauseSec: Double }

enum AudioFeatures {
    static func rmsDb(_ x: [Float]) -> Double {
        let eps: Double = 1e-12
        let meanSq = x.reduce(0.0) { $0 + Double($1 * $1) } / max(1.0, Double(x.count))
        let rms = sqrt(meanSq + eps)
        return 20.0 * log10(max(rms, eps))
    }

    static func countPauses(_ x: [Float], sr: Double, th: Double = 0.01, minPause: Double = 0.5) -> (Int, Double) {
        let frame = Int(0.02 * sr)
        let hop = Int(0.01 * sr)
        guard x.count >= frame else { return (0, 0.0) }
        var energies: [Double] = []
        var i = 0
        while i + frame <= x.count {
            var sum: Double = 0
            for j in 0..<frame { let v = x[i+j]; sum += Double(v*v) }
            energies.append(sqrt(sum / Double(frame)))
            i += hop
        }
        var pauses = 0
        var maxlen = 0
        var cur = 0
        for e in energies {
            if e < th { cur += 1; maxlen = max(maxlen, cur) }
            else { if cur > 0 { let dur = Double(cur*hop)/sr; if dur >= minPause { pauses += 1 } }; cur = 0 }
        }
        if cur > 0 {
            let dur = Double(cur*hop)/sr
            if dur >= minPause { pauses += 1 }
            maxlen = max(maxlen, cur)
        }
        let maxPause = Double(maxlen*hop)/sr
        return (pauses, maxPause)
    }

    static func analyze(buffer: AVAudioPCMBuffer, sampleRate: Double) -> AudioStats {
        let frameLength = Int(buffer.frameLength)
        let ch = buffer.floatChannelData![0]
        let arr = Array(UnsafeBufferPointer(start: ch, count: frameLength))
        let duration = Double(frameLength) / sampleRate
        let rms = rmsDb(arr)
        let (pauses, maxPause) = countPauses(arr, sr: sampleRate)
        return .init(durationSec: duration, rmsDb: rms, pauses: pauses, maxPauseSec: maxPause)
    }
}

