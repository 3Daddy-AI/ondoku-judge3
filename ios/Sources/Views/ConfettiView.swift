import SwiftUI
import UIKit

struct ConfettiView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: UIScreen.main.bounds.width/2, y: -10)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: UIScreen.main.bounds.width, height: 2)
        emitter.birthRate = 1
        var cells: [CAEmitterCell] = []
        for color in [UIColor.systemPink, .systemTeal, .systemYellow, .systemGreen, .systemOrange] {
            let cell = CAEmitterCell()
            cell.birthRate = 6
            cell.lifetime = 6
            cell.velocity = 140
            cell.velocityRange = 60
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi/4
            cell.spin = 3.5
            cell.spinRange = 1.0
            cell.scale = 0.6
            cell.scaleRange = 0.3
            cell.color = color.cgColor
            cell.contents = UIImage(systemName: "seal.fill")?.withTintColor(color, renderingMode: .alwaysOriginal).cgImage
            cells.append(cell)
        }
        emitter.emitterCells = cells
        view.layer.addSublayer(emitter)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            emitter.birthRate = 0
        }
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

