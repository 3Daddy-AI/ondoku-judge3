import SwiftUI

struct HomeView: View {
    @StateObject private var store = ProgressStore()
    @State private var referenceText: String = ""
    @State private var startPractice = false

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("おんどく チャレンジ！").font(.largeTitle).bold()
                Text("れんしゅう つづけて \(store.streakDays) にちめ！👍")
                if let last = store.history.first {
                    VStack {
                        Text("さいきんの けっか")
                        Text("🌟 x\(last.stars)  |  すこあ \(Int(last.overall))てん").font(.headline)
                    }.padding().background(.thinMaterial).cornerRadius(12)
                }
                if !store.history.isEmpty {
                    NavigationLink("きろくを エクスポート", destination: CSVExporter(rows: store.history))
                }
                NavigationLink(isActive: $startPractice) {
                    PracticeFlowView(store: store)
                } label: {
                    EmptyView()
                }
                Button {
                    startPractice = true
                } label: {
                    Text("れんしゅうを はじめる").font(.title2).bold().frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)

                HStack {
                    NavigationLink("クラシック フロー", destination: ContentView())
                    Spacer()
                    NavigationLink("せってい", destination: SettingsView())
                }

                List {
                    Section("れんしゅうの きろく") {
                        ForEach(store.history) { r in
                            HStack {
                                Text("🌟\(r.stars)")
                                VStack(alignment: .leading) {
                                    Text(r.title).lineLimit(1)
                                    Text("\(Int(r.overall))てん | せいかくさ \(Int(r.accuracy)) | すぴーど \(Int(r.speed))")
                                        .font(.footnote).foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                }.frame(maxHeight: 260)
                Spacer()
            }
            .padding()
            .navigationTitle("ホーム")
        }
    }
}
