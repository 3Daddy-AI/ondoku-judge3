import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsStore.shared
    var body: some View {
        Form {
            Section("がくねん") {
                Picker("がくねん", selection: $settings.grade) {
                    ForEach(Grade.allCases) { g in Text(g.rawValue).tag(g) }
                }
            }
            Section("おもさ（点のきめかた）") {
                HStack{ Text("せいかくさ"); Slider(value: $settings.weightAccuracy, in: 0...1) }
                HStack{ Text("すぴーど"); Slider(value: $settings.weightSpeed, in: 0...1) }
                HStack{ Text("ぽーず"); Slider(value: $settings.weightPause, in: 0...1) }
                Text("合計が1に近いほど良いですが、自由に調整できます。").font(.footnote).foregroundColor(.secondary)
            }
            Section("いまの 目安") {
                let r = settings.speedRange()
                Text("すぴーどの 目安: \(Int(r.lowerBound))〜\(Int(r.upperBound)) 文字/分")
            }
        }
        .navigationTitle("せってい")
    }
}

