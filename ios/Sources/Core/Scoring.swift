import Foundation

struct Scores { let accuracy: Double; let speed: Double; let pause: Double; let overall: Double }

enum Scoring {
    static func charsPerMinute(refLen: Int, durationSec: Double) -> Double {
        guard durationSec > 0 else { return 0 }
        return 60.0 * Double(refLen) / durationSec
    }

    static func score(cer: Double, cpm: Double, pauses: Int, lowHigh: ClosedRange<Double>? = nil, weights: (Double,Double,Double)? = nil) -> Scores {
        let acc = max(0.0, min(100.0, (1.0 - cer) * 100.0))
        let range = lowHigh ?? SettingsStore.shared.speedRange()
        let low = range.lowerBound, high = range.upperBound
        let spd: Double
        if cpm >= low && cpm <= high { spd = 100.0 }
        else if cpm < low { spd = max(0.0, 100.0 - (low - cpm) * 0.5) }
        else { spd = max(0.0, 100.0 - (cpm - high) * 0.5) }
        let pausePenalty = min(10.0, Double(max(0, pauses)))
        let pauseScore = max(0.0, 100.0 - pausePenalty)
        let w = weights ?? (SettingsStore.shared.weightAccuracy, SettingsStore.shared.weightSpeed, SettingsStore.shared.weightPause)
        let overall = w.0 * acc + w.1 * spd + w.2 * pauseScore
        return .init(accuracy: round(acc*10)/10, speed: round(spd*10)/10, pause: round(pauseScore*10)/10, overall: round(overall*10)/10)
    }
}
