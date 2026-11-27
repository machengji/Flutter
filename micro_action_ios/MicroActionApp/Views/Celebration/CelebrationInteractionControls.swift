import SwiftUI
import CoreMotion

// MARK: - 1. 下拉放飞（拉弓弹射天灯）

struct PullLaunchControlView: View {
    let accentColor: Color
    let textColor: Color
    let onProgress: (Double) -> Void
    let onComplete: () -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var lastDetentStep: Int = 0
    @State private var hasTriggered: Bool = false
    @State private var isLaunching: Bool = false

    private let maxPull: CGFloat = 78
    private let triggerThreshold: CGFloat = 52

    var body: some View {
        let progress = min(1.0, max(0.0, Double(dragOffset / triggerThreshold)))
        let isReady = dragOffset >= triggerThreshold

        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: 0xFFE38F).opacity(0.25 + 0.55 * progress),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 6,
                            endRadius: 52
                        )
                    )
                    .frame(width: 92, height: 92)
                    .scaleEffect(0.88 + 0.28 * CGFloat(progress))

                Image("IllustLaunchSprout")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 68)
                    .offset(y: isLaunching ? -120 : dragOffset * 0.24)
                    .scaleEffect(x: 1.0 + CGFloat(progress) * 0.08, y: 1.0 - CGFloat(progress) * 0.09)
                    .opacity(isLaunching ? 0.0 : 1.0)
            }

            // 向下拉伸弓弦拉环
            ZStack {
                Capsule()
                    .fill(accentColor.opacity(0.22))
                    .frame(width: 150, height: 38)
                    .overlay(
                        Capsule()
                            .stroke(
                                isReady ? Color(hex: 0xE59A38) : accentColor.opacity(0.55),
                                lineWidth: isReady ? 1.6 : 1.0
                            )
                    )

                HStack(spacing: 6) {
                    Image(systemName: isReady ? "arrow.up.circle.fill" : "arrow.down")
                        .font(.system(size: 13, weight: .bold))
                    Text(isReady ? "松手放飞!" : "按住下拉放飞")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .foregroundColor(isReady ? Color(hex: 0x9A5408) : textColor)
            }
            .offset(y: dragOffset * 0.65)
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { val in
                        guard !hasTriggered else { return }
                        let clamped = min(maxPull, max(0, val.translation.height))
                        dragOffset = clamped
                        let p = min(1.0, Double(clamped / triggerThreshold))
                        onProgress(p)

                        let step = Int((p * 6.0).rounded(.down))
                        if step > lastDetentStep {
                            lastDetentStep = step
                            if step >= 6 {
                                SensoryFeedbackService.shared.glassSwitchSnap()
                            } else {
                                SensoryFeedbackService.shared.mechanicalDialTick()
                            }
                        }
                    }
                    .onEnded { _ in
                        guard !hasTriggered else { return }
                        if dragOffset >= triggerThreshold {
                            hasTriggered = true
                            withAnimation(.spring(response: 0.34, dampingFraction: 0.65)) {
                                isLaunching = true
                                dragOffset = 0
                            }
                            onProgress(1.0)
                            onComplete()
                        } else {
                            lastDetentStep = 0
                            withAnimation(.spring(response: 0.34, dampingFraction: 0.72)) {
                                dragOffset = 0
                            }
                            onProgress(0.0)
                        }
                    }
            )
        }
        .frame(height: 118)
    }
}

// MARK: - 2. 划亮一笔（指尖绘制微笑金粉轨迹）

struct SwipeLightControlView: View {
    let accentColor: Color
    let textColor: Color
    let onProgress: (Double) -> Void
    let onComplete: () -> Void

    @State private var swipeRatio: CGFloat = 0.0
    @State private var lastStep: Int = 0
    @State private var hasTriggered: Bool = false

    private let trackWidth: CGFloat = 216

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                Image("IllustBrushSprout")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
                    .rotationEffect(.degrees(Double(swipeRatio) * 8.0 - 4.0))

                VStack(alignment: .leading, spacing: 3) {
                    Text(hasTriggered ? "一笔生花 · 已点亮" : "向右划过画亮微光")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(textColor)
                    Text("指尖拖着小金笔一路生花")
                        .font(.system(size: 11))
                        .foregroundColor(textColor.opacity(0.72))
                }
            }

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(accentColor.opacity(0.22))
                    .frame(width: trackWidth, height: 42)
                    .overlay(
                        Capsule()
                            .stroke(accentColor.opacity(0.50), lineWidth: 1.0)
                    )

                // 已划过的金色水彩笔迹
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0xF7D070), Color(hex: 0xE59A38)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(42, trackWidth * swipeRatio), height: 42)
                    .opacity(0.85)

                HStack {
                    Spacer()
                    Text("→→→")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(textColor.opacity(0.45 * Double(1.0 - swipeRatio)))
                        .padding(.trailing, 18)
                }
                .frame(width: trackWidth)

                // 滑动金笔头圆钮
                Circle()
                    .fill(Color.white)
                    .frame(width: 34, height: 34)
                    .shadow(color: Color(hex: 0xD98B26).opacity(0.35), radius: 6, y: 2)
                    .overlay(
                        Image(systemName: "pencil.tip")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: 0xB86A08))
                    )
                    .offset(x: 4 + (trackWidth - 42) * swipeRatio)
            }
            .frame(width: trackWidth, height: 42)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { val in
                        guard !hasTriggered else { return }
                        let usable = max(1, trackWidth - 42)
                        let r = min(1.0, max(0.0, val.translation.width / usable))
                        swipeRatio = r
                        onProgress(Double(r))

                        let step = Int((r * 8.0).rounded(.down))
                        if step > lastStep {
                            lastStep = step
                            SensoryFeedbackService.shared.mechanicalDialTick()
                        }
                        if r >= 0.88 {
                            hasTriggered = true
                            withAnimation(.spring(response: 0.24, dampingFraction: 0.78)) {
                                swipeRatio = 1.0
                            }
                            onProgress(1.0)
                            onComplete()
                        }
                    }
                    .onEnded { _ in
                        guard !hasTriggered else { return }
                        lastStep = 0
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                            swipeRatio = 0.0
                        }
                        onProgress(0.0)
                    }
            )
        }
        .frame(height: 112)
    }
}

// MARK: - 3. 三连暴击（太鼓连击蓄能）

struct TapComboControlView: View {
    let accentColor: Color
    let textColor: Color
    let onProgress: (Double) -> Void
    let onComplete: () -> Void

    @State private var comboCount: Int = 0
    @State private var drumScale: CGFloat = 1.0
    @State private var hasTriggered: Bool = false

    private let targetCombos = 3

    var body: some View {
        let progress = Double(comboCount) / Double(targetCombos)

        VStack(spacing: 4) {
            ZStack {
                if comboCount > 0 {
                    Circle()
                        .stroke(Color(hex: 0xE59A38).opacity(0.45), lineWidth: 2)
                        .frame(width: 72 + CGFloat(comboCount) * 14, height: 72 + CGFloat(comboCount) * 14)
                }

                Image("IllustComboSprout")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 66)
                    .scaleEffect(drumScale)
            }

            Button {
                handleTap()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text(
                        hasTriggered
                            ? "连击引爆!"
                            : (comboCount == 0 ? "连击 3 下发光 (0/3)" : "再来! (\(comboCount)/3)")
                    )
                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                }
                .foregroundColor(comboCount > 0 ? .white : textColor)
                .padding(.horizontal, 18)
                .frame(height: 42)
                .background(
                    Capsule()
                        .fill(comboCount > 0 ? Color(hex: 0xE59A38) : accentColor.opacity(0.32))
                )
                .overlay(
                    Capsule()
                        .stroke(accentColor.opacity(0.65), lineWidth: 1.0)
                )
                .scaleEffect(drumScale)
            }
            .buttonStyle(ScaleBounceButtonStyle(scale: 0.90))
        }
        .frame(height: 116)
        .onChange(of: comboCount) { val in
            onProgress(min(1.0, Double(val) / Double(targetCombos)))
        }
    }

    private func handleTap() {
        guard !hasTriggered else { return }
        comboCount += 1
        withAnimation(.spring(response: 0.16, dampingFraction: 0.45)) {
            drumScale = 1.15
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.65)) {
                drumScale = 1.0
            }
        }

        if comboCount == 1 {
            SensoryFeedbackService.shared.microStepComplete()
        } else if comboCount == 2 {
            SensoryFeedbackService.shared.glassSwitchSnap()
        } else if comboCount >= targetCombos {
            hasTriggered = true
            onProgress(1.0)
            onComplete()
        }
    }
}

// MARK: - 4. 摇摇许愿（CoreMotion 摇晃玻璃花瓣瓶）

struct ShakeWishControlView: View {
    let accentColor: Color
    let textColor: Color
    let onProgress: (Double) -> Void
    let onComplete: () -> Void

    @State private var shakeCount: Int = 0
    @State private var jarTilt: Double = 0
    @State private var hasTriggered: Bool = false
    @StateObject private var motionObserver = ShakeMotionObserver()

    private let targetShakes = 3

    var body: some View {
        VStack(spacing: 4) {
            Button {
                // 也允许轻点瓶身显式充能（便于桌面静置场景使用）
                registerShakeImpulse()
            } label: {
                ZStack {
                    Circle()
                        .trim(from: 0, to: CGFloat(shakeCount) / CGFloat(targetShakes))
                        .stroke(Color(hex: 0xE59A38), style: StrokeStyle(lineWidth: 3.0, lineCap: .round))
                        .frame(width: 78, height: 78)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.3, dampingFraction: 0.72), value: shakeCount)

                    Image("IllustJarSprout")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 68)
                        .rotationEffect(.degrees(jarTilt))
                }
            }
            .buttonStyle(ScaleBounceButtonStyle(scale: 0.94))

            Text(
                hasTriggered
                    ? "许愿瓶已满 · 正在绽放!"
                    : "轻轻摇一摇手机 (\(shakeCount)/3) · 或轻点瓶身"
            )
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(textColor)
        }
        .frame(height: 108)
        .onAppear {
            motionObserver.start {
                registerShakeImpulse()
            }
        }
        .onDisappear {
            motionObserver.stop()
        }
    }

    private func registerShakeImpulse() {
        guard !hasTriggered else { return }
        shakeCount += 1
        onProgress(min(1.0, Double(shakeCount) / Double(targetShakes)))
        SensoryFeedbackService.shared.treeTapResonance()

        withAnimation(.spring(response: 0.16, dampingFraction: 0.36)) {
            jarTilt = (shakeCount % 2 == 0) ? 14 : -14
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.6)) {
                jarTilt = 0
            }
        }

        if shakeCount >= targetShakes {
            hasTriggered = true
            motionObserver.stop()
            onComplete()
        }
    }
}

private final class ShakeMotionObserver: ObservableObject {
    private let manager = CMMotionManager()
    private var lastTriggerTime: TimeInterval = 0

    func start(onShake: @escaping @MainActor () -> Void) {
        guard manager.isAccelerometerAvailable, !manager.isAccelerometerActive else { return }
        manager.accelerometerUpdateInterval = 0.08
        manager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let acc = data?.acceleration else { return }
            let magnitude = sqrt(acc.x * acc.x + acc.y * acc.y + acc.z * acc.z)
            let now = Date().timeIntervalSince1970
            // 超过重力 1g 的显著晃动阈值 (1.85g) 且冷却 0.34s
            if magnitude > 1.85 && (now - self.lastTriggerTime) > 0.34 {
                self.lastTriggerTime = now
                Task { @MainActor in
                    onShake()
                }
            }
        }
    }

    func stop() {
        if manager.isAccelerometerActive {
            manager.stopAccelerometerUpdates()
        }
    }

    deinit {
        stop()
    }
}
