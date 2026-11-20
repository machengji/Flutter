import Foundation
import UIKit
import AudioToolbox
import CoreHaptics

/// 原生触觉反馈与 CoreHaptics 连续渐强长震动 + 3 套庆祝微音效包服务
final class SensoryFeedbackService {
    static let shared = SensoryFeedbackService()

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGen = UISelectionFeedbackGenerator()
    private let notificationGen = UINotificationFeedbackGenerator()

    private var hapticEngine: CHHapticEngine?
    private var chargePlayer: CHHapticPatternPlayer?

    private init() {
        prepareHapticEngineIfNeeded()
    }

    private func prepareHapticEngineIfNeeded() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let engine = try CHHapticEngine()
            engine.stoppedHandler = { [weak self] _ in
                self?.chargePlayer = nil
            }
            engine.resetHandler = { [weak self] in
                try? self?.hapticEngine?.start()
            }
            try engine.start()
            self.hapticEngine = engine
        } catch {
            self.hapticEngine = nil
        }
    }

    func selection() {
        selectionGen.prepare()
        selectionGen.selectionChanged()
    }

    func lightTap() {
        lightImpact.prepare()
        lightImpact.impactOccurred()
    }

    /// 0ms 瞬发：启动 0.6s 由弱到强的 CoreHaptics 连续绵密长震动
    func startContinuousChargeHaptic(duration: TimeInterval = 0.6) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            mediumImpact.prepare()
            mediumImpact.impactOccurred(intensity: 0.72)
            return
        }

        if hapticEngine == nil {
            prepareHapticEngineIfNeeded()
        }
        guard let engine = hapticEngine else {
            mediumImpact.prepare()
            mediumImpact.impactOccurred(intensity: 0.72)
            return
        }

        do {
            try engine.start()
            try chargePlayer?.stop(atTime: CHHapticTimeImmediate)

            let continuousEvent = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.30),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.18)
                ],
                relativeTime: 0,
                duration: duration
            )

            let intensityCurve = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    .init(relativeTime: 0.0, value: 0.28),
                    .init(relativeTime: duration * 0.45, value: 0.62),
                    .init(relativeTime: duration, value: 1.0)
                ],
                relativeTime: 0
            )

            let sharpnessCurve = CHHapticParameterCurve(
                parameterID: .hapticSharpnessControl,
                controlPoints: [
                    .init(relativeTime: 0.0, value: 0.15),
                    .init(relativeTime: duration * 0.5, value: 0.45),
                    .init(relativeTime: duration, value: 0.85)
                ],
                relativeTime: 0
            )

            let pattern = try CHHapticPattern(
                events: [continuousEvent],
                parameterCurves: [intensityCurve, sharpnessCurve]
            )
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            self.chargePlayer = player
        } catch {
            mediumImpact.prepare()
            mediumImpact.impactOccurred(intensity: 0.72)
        }
    }

    /// 立即停止蓄力长震动（松手取消或蓄力完成时调用）
    func stopContinuousChargeHaptic() {
        try? chargePlayer?.stop(atTime: CHHapticTimeImmediate)
        chargePlayer = nil
    }

    func chargeTick(progress: Double) {
        if progress <= 0.05 {
            startContinuousChargeHaptic(duration: 0.6)
        }
    }

    func celebrateGrand(soundEnabled: Bool, soundPack: CelebrationSoundPack) {
        stopContinuousChargeHaptic()
        notificationGen.prepare()
        notificationGen.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            self?.heavyImpact.prepare()
            self?.heavyImpact.impactOccurred(intensity: 0.90)
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
