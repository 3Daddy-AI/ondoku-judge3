import Foundation

final class ProgressStore: ObservableObject {
    @Published private(set) var history: [SessionResult] = []
    @Published private(set) var streakDays: Int = 0

    private let historyKey = "ondoku.history"
    private let streakKey = "ondoku.streak"
    private let lastDayKey = "ondoku.lastDay"

    init() { load() }

    func add(_ result: SessionResult) {
        history.insert(result, at: 0)
        saveHistory()
        updateStreak()
    }

    private func load() {
        let ud = UserDefaults.standard
        if let data = ud.data(forKey: historyKey), let arr = try? JSONDecoder().decode([SessionResult].self, from: data) {
            history = arr
        }
        streakDays = ud.integer(forKey: streakKey)
    }

    private func saveHistory() {
        let ud = UserDefaults.standard
        if let data = try? JSONEncoder().encode(history) { ud.set(data, forKey: historyKey) }
    }

    private func updateStreak() {
        let ud = UserDefaults.standard
        let dayKey = Self.dayKey(Date())
        let last = ud.string(forKey: lastDayKey)
        if last == dayKey { return }
        let cal = Calendar.current
        if let lastStr = last, let lastDate = Self.date(fromDayKey: lastStr), let diff = cal.dateComponents([.day], from: lastDate, to: Date()).day {
            if diff == 1 { streakDays = ud.integer(forKey: streakKey) + 1 }
            else { streakDays = 1 }
        } else {
            streakDays = max(1, ud.integer(forKey: streakKey))
        }
        ud.set(streakDays, forKey: streakKey)
        ud.set(dayKey, forKey: lastDayKey)
    }

    static func dayKey(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = .init(identifier: "ja_JP")
        return f.string(from: date)
    }

    static func date(fromDayKey s: String) -> Date? {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = .init(identifier: "ja_JP")
        return f.date(from: s)
    }
}

