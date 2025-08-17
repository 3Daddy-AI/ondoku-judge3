import Foundation

struct SessionResult: Codable, Identifiable {
    let id: UUID
    let date: Date
    let title: String
    let overall: Double
    let accuracy: Double
    let speed: Double
    let pause: Double
    let durationSec: Double
    let cer: Double
    let charsPerMinute: Double
    let stars: Int
    let advice: String
}

struct DailySummary: Codable {
    let dateKey: String
    var count: Int
    var bestScore: Double
}

