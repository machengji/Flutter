import Foundation
import UIKit
import AudioToolbox

/// 原生触觉反馈与 3 套庆祝微音效包服务
final class SensoryFeedbackService {
    static let shared = SensoryFeedbackService()

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGen = UISelectionFeedbackGenerator()
    private let notificationGen = UINotificationFeedbackGenerator()

    private init() {}

    func selection() {
        selectionGen.selectionChanged()
    }

    func lightTap() {
        lightImpact.impactOccurred()
    }

    func chargeTick(progress: Double) {
        let intensity = max(0.25, min(1.0, progress))
        lightImpact.impactOccurred(intensity: intensity)
    }

    func celebrateGrand(soundEnabled: Bool, soundPack: CelebrationSoundPack) {
        notificationGen.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.heavyImpact.impactOccurred(intensity: 0.85)
        }
        guard soundEnabled else { return }
        switch soundPack {
        case .crystalBell:
            AudioServicesPlaySystemSound(1057)
        case .warmMarimba:
            AudioServicesPlaySystemSound(1104)
        case .royalChord:
            AudioServicesPlaySystemSound(1025)
        }
    }
}
