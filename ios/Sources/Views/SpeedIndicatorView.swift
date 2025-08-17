import SwiftUI

struct SpeedIndicatorView: View {
    let elapsed: Double
    let refChars: Int
    let targetCpmRange: ClosedRange<Double> = 200...350

    var body: some View {
        let expectedMin = elapsed * targetCpmRange.lowerBound / 60.0
        let expectedMax = elapsed * targetCpmRange.upperBound / 60.0
        let ratio = min(1.0, Double(refChars) / max(1.0, expectedMin))
        let status: String
        let color: Color
        if Double(refChars) < expectedMin { status = "ゆっくり"; color = .blue }
        else if Double(refChars) > expectedMax { status = "はやい"; color = .orange }
        else { status = "ちょうどいい"; color = .green }
        return VStack {
            Text("よみの はやさ: \(status)").foregroundColor(color)
            ProgressView(value: ratio).tint(color)
        }
    }
}

