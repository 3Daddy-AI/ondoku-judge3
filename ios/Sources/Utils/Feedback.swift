import UIKit

enum Feedback {
    static func success() {
        let gen = UINotificationFeedbackGenerator(); gen.prepare(); gen.notificationOccurred(.success)
    }
    static func warning() {
        let gen = UINotificationFeedbackGenerator(); gen.prepare(); gen.notificationOccurred(.warning)
    }
    static func error() {
        let gen = UINotificationFeedbackGenerator(); gen.prepare(); gen.notificationOccurred(.error)
    }
}

