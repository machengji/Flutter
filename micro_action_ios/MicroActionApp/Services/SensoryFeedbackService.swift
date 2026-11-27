import Foundation
import UIKit
import AudioToolbox
import CoreHaptics
import AVFoundation

/// 按住蓄力震动性格
enum HapticProfile: String, CaseIterable, Identifiable {
    case mechanicalRatchet = "机械发条"
    case warmHeartbeat = "心跳脉动"
    case crystalPulse = "水晶星芒"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .mechanicalRatchet: return "发条咬合到临界共振，爽脆有力"
        case .warmHeartbeat: return "双拍心跳律动渐强，柔和治愈"
        case .crystalPulse: return "高锐度晶莹星芒跳跃，轻盈灵动"
        }
    }
}

/// 原生触觉反馈 + CoreHaptics 0ms 连续聚能长震动 + AVAudioEngine 音画触同频微音效引擎
final class SensoryFeedbackService {
    static let shared = SensoryFeedbackService()

    private static let profileKey = "micro_action_haptic_profile"
    private static let soundEnabledKey = "micro_action_charge_sound_enabled"

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGen = UISelectionFeedbackGenerator()

    private var hapticEngine: CHHapticEngine?
    private var engineRunning: Bool = false
    private var prebuiltChargePattern: CHHapticPattern?
    private var chargePlayer: CHHapticPatternPlayer?

    // 内存合成音画同频引擎（遵守系统静音键 .ambient）
    private var audioEngine: AVAudioEngine?
    private var chargeAudioPlayer: AVAudioPlayerNode?
    private var burstAudioPlayer: AVAudioPlayerNode?
    private var prebuiltChargeAudioBuffer: AVAudioPCMBuffer?
    private var prebuiltBurstAudioBuffer: AVAudioPCMBuffer?

    var currentProfile: HapticProfile {
        get {
            let raw = UserDefaults.standard.string(forKey: Self.profileKey) ?? ""
            return HapticProfile(rawValue: raw) ?? .mechanicalRatchet
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Self.profileKey)
            rebuildChargeAssets()
        }
    }

    var chargeSoundEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: Self.soundEnabledKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: Self.soundEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.soundEnabledKey)
        }
    }

    private init() {
        setupHapticEngine()
        setupAudioEngineAsync()
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
            self.prebuiltChargePattern = try buildChargePattern(duration: 0.75, profile: currentProfile)
            warmUpHapticEngine()
        } catch {
            self.hapticEngine = nil
        }
    }

    private func setupAudioEngineAsync() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])

            let engine = AVAudioEngine()
            let chargeNode = AVAudioPlayerNode()
            let burstNode = AVAudioPlayerNode()
            let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!

            engine.attach(chargeNode)
            engine.attach(burstNode)
            engine.connect(chargeNode, to: engine.mainMixerNode, format: format)
            engine.connect(burstNode, to: engine.mainMixerNode, format: format)
            engine.mainMixerNode.outputVolume = 0.85

            let chargeBuf = self.synthesizeChargeAudioBuffer(format: format, duration: 0.75, profile: self.currentProfile)
            let burstBuf = self.synthesizeBurstChordBuffer(format: format)

            DispatchQueue.main.async {
                self.audioEngine = engine
                self.chargeAudioPlayer = chargeNode
                self.burstAudioPlayer = burstNode
                self.prebuiltChargeAudioBuffer = chargeBuf
                self.prebuiltBurstAudioBuffer = burstBuf
            }
        }
    }

    private func rebuildChargeAssets() {
        let profile = currentProfile
        prebuiltChargePattern = try? buildChargePattern(duration: 0.75, profile: profile)
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self, let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1) else { return }
            let buf = self.synthesizeChargeAudioBuffer(format: format, duration: 0.75, profile: profile)
            DispatchQueue.main.async {
                self.prebuiltChargeAudioBuffer = buf
            }
        }
    }

    /// 异步预热 CoreHaptics 引擎（绝不阻塞 UI 主线程）
    func warmUpHapticEngine() {
        if CHHapticEngine.capabilitiesForHardware().supportsHaptics {
            if hapticEngine == nil {
                setupHapticEngine()
                return
            }
            if let engine = hapticEngine, !engineRunning {
                engine.start { [weak self] error in
                    if error == nil {
                        self?.engineRunning = true
                    }
                }
            }
        }
        heavyImpact.prepare()
        lightImpact.prepare()
    }

    // MARK: - 触觉波形构建（3 套震动性格）

    private func buildChargePattern(duration: TimeInterval, profile: HapticProfile) throws -> CHHapticPattern {
        let scale = max(0.3, duration / 0.75)
        switch profile {
        case .mechanicalRatchet:
            return try buildRatchetPattern(duration: duration, scale: scale)
        case .warmHeartbeat:
            return try buildHeartbeatPattern(duration: duration, scale: scale)
        case .crystalPulse:
            return try buildCrystalPattern(duration: duration, scale: scale)
        }
    }

    private func buildRatchetPattern(duration: TimeInterval, scale: Double) throws -> CHHapticPattern {
        var events: [CHHapticEvent] = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.78),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.80)
                ],
                relativeTime: 0
            )
        ]

        let times: [TimeInterval] = [
            0.068, 0.140, 0.208,
            0.268, 0.322, 0.370, 0.412, 0.450, 0.485, 0.517,
            0.546, 0.572, 0.596, 0.618, 0.639, 0.659, 0.678, 0.696, 0.713, 0.730
        ]
        for (idx, t) in times.enumerated() {
            let p = Float(idx) / Float(max(1, times.count - 1))
            events.append(
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: min(1.0, 0.48 + 0.52 * pow(p, 0.95))),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: min(1.0, 0.42 + 0.54 * pow(p, 1.1)))
                    ],
                    relativeTime: t * scale
                )
            )
        }

        events.append(
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                ],
                relativeTime: 0.015,
                duration: max(0.08, duration - 0.015)
            )
        )

        let intensityCurve = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                .init(relativeTime: 0.0, value: 0.28),
                .init(relativeTime: duration * 0.35, value: 0.46),
                .init(relativeTime: duration * 0.72, value: 0.72),
                .init(relativeTime: duration * 0.95, value: 0.94),
                .init(relativeTime: duration, value: 0.96)
            ],
            relativeTime: 0
        )
        let sharpnessCurve = CHHapticParameterCurve(
            parameterID: .hapticSharpnessControl,
            controlPoints: [
                .init(relativeTime: 0.0, value: 0.18),
                .init(relativeTime: duration * 0.45, value: 0.34),
                .init(relativeTime: duration * 0.80, value: 0.58),
                .init(relativeTime: duration, value: 0.76)
            ],
            relativeTime: 0
        )
        return try CHHapticPattern(events: events, parameterCurves: [intensityCurve, sharpnessCurve])
    }

    private func buildHeartbeatPattern(duration: TimeInterval, scale: Double) throws -> CHHapticPattern {
        // 渐快双拍心跳（咚-咚... 咚-咚... 咚咚咚）
        let beats: [(TimeInterval, Float, Float)] = [
            (0.00, 0.62, 0.24), (0.11, 0.46, 0.18),
            (0.25, 0.74, 0.26), (0.35, 0.58, 0.22),
            (0.47, 0.86, 0.32), (0.55, 0.72, 0.28),
            (0.63, 0.94, 0.40), (0.69, 0.98, 0.48)
        ]
        var events: [CHHapticEvent] = beats.map { (t, intensity, sharp) in
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharp)
                ],
                relativeTime: t * scale
            )
        }
        events.append(
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.22)
                ],
                relativeTime: 0.02,
                duration: max(0.08, duration - 0.02)
            )
        )
        let intensityCurve = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                .init(relativeTime: 0.0, value: 0.22),
                .init(relativeTime: duration * 0.50, value: 0.52),
                .init(relativeTime: duration, value: 0.88)
            ],
            relativeTime: 0
        )
        return try CHHapticPattern(events: events, parameterCurves: [intensityCurve])
    }

    private func buildCrystalPattern(duration: TimeInterval, scale: Double) throws -> CHHapticPattern {
        let times: [TimeInterval] = [
            0.00, 0.075, 0.145, 0.210, 0.270, 0.325, 0.375, 0.422,
            0.466, 0.507, 0.546, 0.583, 0.618, 0.651, 0.682, 0.712
        ]
        var events: [CHHapticEvent] = []
        for (idx, t) in times.enumerated() {
            let p = Float(idx) / Float(max(1, times.count - 1))
            events.append(
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: min(1.0, 0.44 + 0.54 * p)),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: min(1.0, 0.82 + 0.18 * p))
                    ],
                    relativeTime: t * scale
                )
            )
        }
        events.append(
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.38),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.65)
                ],
                relativeTime: 0.05,
                duration: max(0.08, duration - 0.05)
            )
        )
        return try CHHapticPattern(events: events, parameterCurves: [])
    }

    // MARK: - 内存微音效合成（与震动严格同频）

    private func synthesizeChargeAudioBuffer(format: AVAudioFormat, duration: TimeInterval, profile: HapticProfile) -> AVAudioPCMBuffer? {
        let sr = format.sampleRate
        let frameCount = AVAudioFrameCount(sr * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        guard let ch = buffer.floatChannelData?[0] else { return nil }

        let noteTimes: [Double]
        switch profile {
        case .mechanicalRatchet:
            noteTimes = [0.00, 0.068, 0.140, 0.208, 0.268, 0.322, 0.370, 0.412, 0.450, 0.485, 0.517, 0.546, 0.572, 0.596, 0.618, 0.639, 0.659, 0.678, 0.696, 0.713]
        case .warmHeartbeat:
            noteTimes = [0.00, 0.11, 0.25, 0.35, 0.47, 0.55, 0.63, 0.69]
        case .crystalPulse:
            noteTimes = [0.00, 0.075, 0.145, 0.210, 0.270, 0.325, 0.375, 0.422, 0.466, 0.507, 0.546, 0.583, 0.618, 0.651, 0.682, 0.712]
        }

        let baseFreq: Double = (profile == .warmHeartbeat) ? 330.0 : 523.25
        let topFreq: Double = (profile == .warmHeartbeat) ? 659.25 : 1046.50

        for i in 0..<Int(frameCount) {
            ch[i] = 0
        }

        for (idx, startT) in noteTimes.enumerated() {
            let p = Double(idx) / Double(max(1, noteTimes.count - 1))
            let freq = baseFreq + (topFreq - baseFreq) * pow(p, 1.05)
            let amp = Float(0.05 + 0.09 * p)
            let startSample = Int(startT * sr)
            let grainLen = Int(0.048 * sr)
            for j in 0..<grainLen {
                let sIdx = startSample + j
                if sIdx >= Int(frameCount) { break }
                let lt = Double(j) / sr
                let env = Float(exp(-lt * 55.0) * min(1.0, lt / 0.002))
                let wave = Float(sin(2.0 * .pi * freq * lt) + 0.35 * sin(2.0 * .pi * freq * 2.0 * lt))
                ch[sIdx] += wave * env * amp
            }
        }
        return buffer
    }

    private func synthesizeBurstChordBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sr = format.sampleRate
        let duration = 0.55
        let frameCount = AVAudioFrameCount(sr * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        guard let ch = buffer.floatChannelData?[0] else { return nil }

        // 温暖清亮大三和弦 C6 - E6 - G6 错峰拨弦
        let freqs = [1046.50, 1318.51, 1567.98]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sr
            var val: Double = 0
            for (k, f) in freqs.enumerated() {
                let offset = Double(k) * 0.028
                if t >= offset {
                    let lt = t - offset
                    let env = exp(-lt * 6.5) * min(1.0, lt / 0.004)
                    val += sin(2.0 * .pi * f * lt) * env * 0.14
                }
            }
            ch[i] = Float(val)
        }
        return buffer
    }

    private func playChargeAudioIfEnabled() {
        guard chargeSoundEnabled,
              let engine = audioEngine,
              let player = chargeAudioPlayer,
              let buf = prebuiltChargeAudioBuffer else { return }
        if !engine.isRunning {
            try? engine.start()
        }
        player.stop()
        player.scheduleBuffer(buf, at: nil, options: [])
        player.play()
    }

    private func stopChargeAudio() {
        chargeAudioPlayer?.stop()
    }

    // MARK: - 公开触觉 API

    func selection() {
        selectionGen.selectionChanged()
        selectionGen.prepare()
    }

    func lightTap() {
        lightImpact.impactOccurred()
        lightImpact.prepare()
    }

    /// 日常勾选完成微步时的“精密小磁扣”双脉冲微震
    func microStepComplete() {
        if CHHapticEngine.capabilitiesForHardware().supportsHaptics,
           let engine = hapticEngine,
           engineRunning {
            do {
                let click = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.72),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.88)
                    ],
                    relativeTime: 0.0
                )
                let cushion = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.42),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25)
                    ],
                    relativeTime: 0.048
                )
                let pattern = try CHHapticPattern(events: [click, cushion], parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: CHHapticTimeImmediate)
                return
            } catch {}
        }
        mediumImpact.impactOccurred(intensity: 0.72)
        mediumImpact.prepare()
    }

    /// 0ms 瞬发：同时启动预编译 CoreHaptics 波形与同频攀升微音效
    func startContinuousChargeHaptic(duration: TimeInterval = 0.75) {
        playChargeAudioIfEnabled()

        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = hapticEngine else {
            mediumImpact.impactOccurred(intensity: 0.78)
            return
        }

        if !engineRunning {
            mediumImpact.impactOccurred(intensity: 0.72)
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
            let pattern = try (abs(duration - 0.75) < 0.01 ? prebuiltChargePattern : nil)
                ?? buildChargePattern(duration: duration, profile: currentProfile)
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            self.chargePlayer = player
        } catch {
            mediumImpact.impactOccurred(intensity: 0.78)
        }
    }

    /// 设置页切换触觉性格时的即时试震体验
    func previewProfile(_ profile: HapticProfile) {
        currentProfile = profile
        startContinuousChargeHaptic(duration: 0.75)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { [weak self] in
            self?.celebrateGrand(soundEnabled: self?.chargeSoundEnabled ?? true, soundPack: .crystalBell)
        }
    }

    /// 立即停止蓄力长震动与过程音效
    func stopContinuousChargeHaptic() {
        try? chargePlayer?.stop(atTime: CHHapticTimeImmediate)
        chargePlayer = nil
        stopChargeAudio()
    }

    /// 提前松手取消时的轻柔卸力回弹
    func cancelChargeHaptic() {
        stopContinuousChargeHaptic()
        lightImpact.impactOccurred(intensity: 0.36)
        lightImpact.prepare()
    }

    func chargeTick(progress: Double) {
        // 已由 ChargeToShineButton.beginPress() 唯一触发，避免重复启动打断震动
    }

    /// 蓄满完成瞬间：清脆“咔哒”破壳解锁 + 沉厚物理共鸣 + 温暖余韵和弦
    func celebrateGrand(soundEnabled: Bool, soundPack: CelebrationSoundPack) {
        stopContinuousChargeHaptic()
        if CHHapticEngine.capabilitiesForHardware().supportsHaptics,
           let engine = hapticEngine,
           engineRunning {
            do {
                let snapClick = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                    ],
                    relativeTime: 0.0
                )
                let deepBoom = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.96),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.22)
                    ],
                    relativeTime: 0.055
                )
                let afterglow = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.54),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.48)
                    ],
                    relativeTime: 0.135
                )
                let warmTail = CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.32),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.16)
                    ],
                    relativeTime: 0.055,
                    duration: 0.10
                )
                let pattern = try CHHapticPattern(events: [snapClick, deepBoom, afterglow, warmTail], parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: CHHapticTimeImmediate)
            } catch {
                heavyImpact.impactOccurred(intensity: 1.0)
                heavyImpact.prepare()
            }
        } else {
            heavyImpact.impactOccurred(intensity: 1.0)
            heavyImpact.prepare()
        }

        guard soundEnabled else { return }
        if let engine = audioEngine, let burstNode = burstAudioPlayer, let buf = prebuiltBurstAudioBuffer {
            if !engine.isRunning {
                try? engine.start()
            }
            burstNode.stop()
            burstNode.scheduleBuffer(buf, at: nil, options: [])
            burstNode.play()
        } else {
            switch soundPack {
            case .crystalBell: AudioServicesPlaySystemSound(1057)
            case .warmMarimba: AudioServicesPlaySystemSound(1104)
            case .royalChord: AudioServicesPlaySystemSound(1025)
            }
        }
    }

    // MARK: - 精密机械与自然共鸣微交互触觉

    /// 机械表冠微刻度棘轮（滑块调步、流体 Tab 跨格滑动等精密操作）
    func mechanicalDialTick() {
        if CHHapticEngine.capabilitiesForHardware().supportsHaptics,
           let engine = hapticEngine,
           engineRunning {
            do {
                let tick = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.42),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.90)
                    ],
                    relativeTime: 0.0
                )
                let pattern = try CHHapticPattern(events: [tick], parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: CHHapticTimeImmediate)
                return
            } catch {}
        }
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    /// 液态玻璃“玉石轻碰”双拍反馈（Tab 切换、按钮确认）
    func glassSwitchSnap() {
        if CHHapticEngine.capabilitiesForHardware().supportsHaptics,
           let engine = hapticEngine,
           engineRunning {
            do {
                let snap = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.62),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.78)
                    ],
                    relativeTime: 0.0
                )
                let echo = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.26),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.35)
                    ],
                    relativeTime: 0.022
                )
                let pattern = try CHHapticPattern(events: [snap, echo], parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: CHHapticTimeImmediate)
                return
            } catch {}
        }
        lightImpact.impactOccurred(intensity: 0.55)
        lightImpact.prepare()
    }

    /// 成长树树干/树冠敲击共鸣（木质轻叩 + 树干低频共鸣 + 轻风拂叶）
    func treeTapResonance() {
        if CHHapticEngine.capabilitiesForHardware().supportsHaptics,
           let engine = hapticEngine,
           engineRunning {
            do {
                let knock = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.64),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.36)
                    ],
                    relativeTime: 0.0
                )
                let trunkResonance = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.48),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.18)
                    ],
                    relativeTime: 0.052
                )
                let rustle = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.24),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.62)
                    ],
                    relativeTime: 0.118
                )
                let pattern = try CHHapticPattern(events: [knock, trunkResonance, rustle], parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: CHHapticTimeImmediate)
                return
            } catch {}
        }
        mediumImpact.impactOccurred(intensity: 0.65)
        mediumImpact.prepare()
    }
}
