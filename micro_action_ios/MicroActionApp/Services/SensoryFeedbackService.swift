import Foundation
import UIKit
import AudioToolbox
import CoreHaptics

/// 原生触觉反馈与 CoreHaptics 零延迟连续渐强长震动 + 3 套庆祝微音效包服务
final class SensoryFeedbackService {
    static let shared = SensoryFeedbackService()

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGen = UISelectionFeedbackGenerator()
    private let notificationGen = UINotificationFeedbackGenerator()

    private var hapticEngine: CHHapticEngine?
    private var engineRunning: Bool = false
    private var prebuiltChargePattern: CHHapticPattern?
    private var chargePlayer: CHHapticPatternPlayer?

    private init() {
        setupHapticEngine()
    }

    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let engine = try CHHapticEngine()
            engine.isAutoShutdownEnabled = false
            engine.stoppedHandler = { [weak self] _ in
                self?.engineRunning = false
                self?.chargePlayer = nil
            }
            engine.resetHandler = { [weak self] in
                self?.engineRunning = false
                self?.chargePlayer = nil
                self?.warmUpHapticEngine()
            }
            self.hapticEngine = engine
            self.prebuiltChargePattern = try buildChargePattern(duration: 0.6)
            warmUpHapticEngine()
        } catch {
            self.hapticEngine = nil
        }
    }

    /// 异步预热 CoreHaptics 引擎（绝不阻塞 UI 主线程，在庆祝卡或蓄力按钮出现时提前调用）
    func warmUpHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        if hapticEngine == nil {
            setupHapticEngine()
            return
        }
        guard let engine = hapticEngine, !engineRunning else { return }
        engine.start { [weak self] error in
            if error == nil {
                self?.engineRunning = true
            }
        }
        heavyImpact.prepare()
        lightImpact.prepare()
    }

    /// 预编译 0.6s 绵密渐强触觉波形（起手轻脆确认 + 0.6s 真实 0.35->1.0 渐强连续震动）
    private func buildChargePattern(duration: TimeInterval) throws -> CHHapticPattern {
        // 1. 0ms 起手轻脆触感确认，消除按下去无响应的空窗感
        let startTap = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.50),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.45)
            ],
            relativeTime: 0
        )

        // 2. 连续震动基底（基础 intensity 必须设为 1.0，由 intensityCurve 精确调制 0.32 -> 1.0）
        let continuousEvent = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            ],
            relativeTime: 0.01,
            duration: max(0.1, duration - 0.01)
        )

        let intensityCurve = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                .init(relativeTime: 0.0, value: 0.32),
                .init(relativeTime: duration * 0.45, value: 0.62),
                .init(relativeTime: duration * 0.85, value: 0.92),
                .init(relativeTime: duration, value: 1.0)
            ],
            relativeTime: 0
        )

        let sharpnessCurve = CHHapticParameterCurve(
            parameterID: .hapticSharpnessControl,
            controlPoints: [
                .init(relativeTime: 0.0, value: 0.22),
                .init(relativeTime: duration * 0.50, value: 0.52),
                .init(relativeTime: duration, value: 0.88)
            ],
            relativeTime: 0
        )

        return try CHHapticPattern(
            events: [startTap, continuousEvent],
            parameterCurves: [intensityCurve, sharpnessCurve]
        )
    }

    func selection() {
        selectionGen.selectionChanged()
        selectionGen.prepare()
    }

    func lightTap() {
        lightImpact.impactOccurred()
        lightImpact.prepare()
    }

    /// 0ms 瞬发：直接播放已预编译好的 0.6s 连续渐强长震动（不阻塞主线程）
    func startContinuousChargeHaptic(duration: TimeInterval = 0.6) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = hapticEngine else {
            mediumImpact.impactOccurred(intensity: 0.72)
            return
        }

        // 若引擎已休眠则先瞬发轻触感并异步唤醒，绝不在主线程同步阻塞 engine.start()
        if !engineRunning {
            lightImpact.impactOccurred(intensity: 0.65)
            engine.start { [weak self] error in
                guard let self, error == nil else { return }
                self.engineRunning = true
                self.playPrebuiltChargePattern(on: engine, duration: duration)
            }
            return
        }

        playPrebuiltChargePattern(on: engine, duration: duration)
    }

    private func playPrebuiltChargePattern(on engine: CHHapticEngine, duration: TimeInterval) {
        do {
            try chargePlayer?.stop(atTime: CHHapticTimeImmediate)
            let pattern = try (duration == 0.6 ? prebuiltChargePattern : nil) ?? buildChargePattern(duration: duration)
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            self.chargePlayer = player
        } catch {
            mediumImpact.impactOccurred(intensity: 0.72)
        }
    }

    /// 立即停止蓄力长震动（松手取消或蓄力完成时调用）
    func stopContinuousChargeHaptic() {
        try? chargePlayer?.stop(atTime: CHHapticTimeImmediate)
        chargePlayer = nil
    }

    func chargeTick(progress: Double) {
        // 已由 ChargeToShineButton.beginPress() 唯一触发，避免重复启动打断震动
    }

    func celebrateGrand(soundEnabled: Bool, soundPack: CelebrationSoundPack) {
        stopContinuousChargeHaptic()
        heavyImpact.impactOccurred(intensity: 0.88)
        heavyImpact.prepare()
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
