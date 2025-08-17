import Foundation
import Vision
import PDFKit
import UIKit

enum OCRService {
    static func extractText(from image: UIImage, completion: @escaping (String) -> Void) {
        let request = VNRecognizeTextRequest { req, _ in
            guard let obs = req.results as? [VNRecognizedTextObservation] else {
                completion(""); return
            }
            // ルビ抑制: 小さすぎるバウンディングは除外（閾値は経験的に0.02〜0.03）
            let minH: CGFloat = 0.022
            let filtered = obs.filter { $0.boundingBox.height >= minH }
            let texts = filtered.compactMap { $0.topCandidates(1).first?.string }
            let joined = texts.joined(separator: "\n")
            completion(joined)
        }
        request.recognitionLanguages = ["ja-JP"]
        request.usesLanguageCorrection = true
        request.minimumTextHeight = 0.01
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        try? handler.perform([request])
    }

    static func extractText(from pdfUrl: URL, completion: @escaping (String) -> Void) {
        guard let doc = PDFDocument(url: pdfUrl) else { completion(""); return }
        let group = DispatchGroup()
        var all: [String] = []
        for i in 0..<doc.pageCount {
            guard let page = doc.page(at: i) else { continue }
            group.enter()
            DispatchQueue.global().async {
                let img = page.thumbnail(of: CGSize(width: 2048, height: 2048), for: .cropBox)
                extractText(from: img) { text in
                    all.append(text)
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) {
            completion(all.joined(separator: "\n"))
        }
    }
}
