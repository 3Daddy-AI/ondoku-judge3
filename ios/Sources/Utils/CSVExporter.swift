import Foundation
import UniformTypeIdentifiers
import SwiftUI

struct CSVExporter: UIViewControllerRepresentable {
    let rows: [SessionResult]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let csv = makeCSV(rows: rows)
        let url = writeTemp(csv: csv)
        return UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}

    private func makeCSV(rows: [SessionResult]) -> String {
        var out = "id,date,title,overall,accuracy,speed,pause,duration,cer,cpm,stars,advice\n"
        let f = ISO8601DateFormatter()
        for r in rows {
            let line = [
                r.id.uuidString,
                f.string(from: r.date),
                r.title.replacingOccurrences(of: ",", with: " "),
                String(Int(r.overall)),
                String(Int(r.accuracy)),
                String(Int(r.speed)),
                String(Int(r.pause)),
                String(format: "%.2f", r.durationSec),
                String(format: "%.3f", r.cer),
                String(format: "%.1f", r.charsPerMinute),
                String(r.stars),
                r.advice.replacingOccurrences(of: ",", with: " ")
            ].joined(separator: ",")
            out.append(line+"\n")
        }
        return out
    }

    private func writeTemp(csv: String) -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ondoku_history.csv")
        try? csv.data(using: .utf8)?.write(to: url)
        return url
    }
}

