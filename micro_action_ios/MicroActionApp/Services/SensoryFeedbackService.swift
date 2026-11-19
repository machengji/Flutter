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
        selectionGen.prepare()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.055) { [weak self] in
            self?.selectionGen.selectionChanged()
        }
    }

    func lightTap() {
        lightImpact.prepare()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.055) { [weak self] in
            self?.lightImpact.impactOccurred()
        }
    }

    func chargeTick(progress: Double) {
        if progress <= 0.05 {
            mediumImpact.prepare()
            mediumImpact.impactOccurred(intensity: 0.72)
        } else {
            let intensity = max(0.45, min(1.0, progress))
            mediumImpact.prepare()
            mediumImpact.impactOccurred(intensity: intensity)
        }
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
