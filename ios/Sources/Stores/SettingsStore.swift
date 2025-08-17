import Foundation

enum Grade: String, CaseIterable, Identifiable, Codable {
    case g1="小1", g2="小2", g3="小3", g4="小4", g5="小5", g6="小6"
    var id: String { rawValue }
}

final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    @Published var grade: Grade { didSet { save() } }
    @Published var weightAccuracy: Double { didSet { save() } }
    @Published var weightSpeed: Double { didSet { save() } }
    @Published var weightPause: Double { didSet { save() } }

    private let key = "ondoku.settings"

    private init(){
        if let data = UserDefaults.standard.data(forKey: key),
           let s = try? JSONDecoder().decode(Self.CodableSelf.self, from: data) {
            grade = s.grade; weightAccuracy = s.wa; weightSpeed = s.ws; weightPause = s.wp
        } else {
            grade = .g3; weightAccuracy = 0.7; weightSpeed = 0.2; weightPause = 0.1
        }
    }

    func speedRange() -> ClosedRange<Double> {
        switch grade {
        case .g1: return 120...220
        case .g2: return 150...260
        case .g3: return 180...300
        case .g4: return 200...330
        case .g5: return 220...360
        case .g6: return 240...380
        }
    }

    private func save(){
        let c = CodableSelf(grade: grade, wa: weightAccuracy, ws: weightSpeed, wp: weightPause)
        if let data = try? JSONEncoder().encode(c) { UserDefaults.standard.set(data, forKey: key) }
    }

    private struct CodableSelf: Codable { let grade: Grade; let wa: Double; let ws: Double; let wp: Double }
}

