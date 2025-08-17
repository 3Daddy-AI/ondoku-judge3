import Foundation

struct JudgeReport {
    let cer: Double
    let errors: Int
    let refLen: Int
    let preview: String
    let opsPreview: String
    let durationSec: Double
    let charsPerMinute: Double
    let pauses: Int
    let maxPauseSec: Double
    let accuracyScore: Double
    let speedScore: Double
    let pauseScore: Double
    let overall: Double
    let stars: Int
    let advice: String
}

enum JudgeEngine {
    static func run(reference: String, hypothesis: String, durationSec: Double, pauses: Int, maxPauseSec: Double) -> JudgeReport {
        let normRef = Normalization.normalizeForAlignment(reference)
        let normHyp = Normalization.normalizeForAlignment(hypothesis)
        let ali = Aligner.levenshtein(ref: normRef, hyp: normHyp)
        let cpm = Scoring.charsPerMinute(refLen: ali.refLen, durationSec: durationSec)
        let scores = Scoring.score(cer: ali.cer, cpm: cpm, pauses: pauses)
        let preview = Aligner.preview(ali.ops)
        let stars = Self.stars(overall: scores.overall)
        let advice = Self.advice(cer: ali.cer, cpm: cpm, pauses: pauses)
        return .init(
            cer: round(ali.cer*10000)/10000,
            errors: ali.errors,
            refLen: ali.refLen,
            preview: preview,
            opsPreview: preview,
            durationSec: round(durationSec*1000)/1000,
            charsPerMinute: round(cpm*10)/10,
            pauses: pauses,
            maxPauseSec: round(maxPauseSec*100)/100,
            accuracyScore: scores.accuracy,
            speedScore: scores.speed,
            pauseScore: scores.pause,
            overall: scores.overall,
            stars: stars,
            advice: advice
        )
    }

    private static func stars(overall: Double) -> Int {
        if overall >= 90 { return 3 }
        if overall >= 75 { return 2 }
        if overall >= 60 { return 1 }
        return 0
    }

    private static func advice(cer: Double, cpm: Double, pauses: Int) -> String {
        var tips: [String] = []
        if cer > 0.15 { tips.append("ことばを ていねいに。 まちがえたら さいど ちょうせん！") }
        else if cer > 0.08 { tips.append("よく できたよ。 ゆっくり はっきり よもう！") }
        else { tips.append("ばっちり！ この ちょうし！") }
        if cpm < 200 { tips.append("すこし ゆっくりかも。 すこし はやく よんでみよう！") }
        else if cpm > 350 { tips.append("はやいかも。 きゅうてん（、。）で ひといき！") }
        if pauses >= 5 { tips.append("とちゅうで とまるかずを すこし へらそう！") }
        return tips.joined(separator: " ")
    }
}
