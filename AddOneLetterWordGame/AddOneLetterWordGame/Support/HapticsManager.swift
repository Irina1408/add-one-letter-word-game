import CoreHaptics
import UIKit

final class HapticsManager {
    static let shared = HapticsManager()

    private var impactGenerator: UIImpactFeedbackGenerator?
    private var notificationGenerator: UINotificationFeedbackGenerator?
    var isEnabled: Bool = true

    private init() {
        prepareGenerators()
    }

    func prepareGenerators() {
        impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactGenerator?.prepare()
        notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator?.prepare()
    }

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    func success() {
        guard isEnabled else { return }
        notificationGenerator?.notificationOccurred(.success)
    }

    func warning() {
        guard isEnabled else { return }
        notificationGenerator?.notificationOccurred(.warning)
    }

    func error() {
        guard isEnabled else { return }
        notificationGenerator?.notificationOccurred(.error)
    }
}
