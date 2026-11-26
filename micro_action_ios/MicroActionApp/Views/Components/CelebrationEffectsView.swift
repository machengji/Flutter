import SwiftUI

/// 四角微光星芒路径辅助
func fourPointStarPath(center: CGPoint, outerRadius: CGFloat, innerRadius: CGFloat) -> Path {
    var path = Path()
    for i in 0..<8 {
        let r = i.isMultiple(of: 2) ? outerRadius : innerRadius
        let angle = (CGFloat(i) * .pi / 4.0) - (.pi / 2.0)
        let pt = CGPoint(
            x: center.x + cos(angle) * r,
            y: center.y + sin(angle) * r
        )
        if i == 0 {
            path.move(to: pt)
        } else {
            path.addLine(to: pt)
        }
    }
    path.closeSubpath()
    return path
}

/// 0.75 秒视触三感合一蓄力发光按钮（支持按住 0.75s 三段式聚能蓄力 + 轻点直达；按住微颤与光晕同步）
struct ChargeToShineButton: View {
    let label: String
    var chargingLabel: String = "蓄力中..."
    var completedLabel: String = "已发光"
    var allowQuickTapClose: Bool = false
    var accentColor: Color = BotanicalTheme.primary
    var secondaryAccentColor: Color? = nil
    var borderColor: Color = Color.white.opacity(0.28)
    var textColor: Color = .white
    var chargingTextColor: Color = .white
    var onChargeTick: ((Double) -> Void)? = nil
    let onCharged: () -> Void
    var onQuickTap: (() -> Void)? = nil
    var onPressEnd: (() -> Void)? = nil
    var onShortPressHint: (() -> Void)? = nil
    var useOrbPulse: Bool = false

    private let chargeDuration: TimeInterval = 0.75

    @State private var fillProgress: CGFloat = 0
    @State private var isPressing: Bool = false
    @State private var completedOnce: Bool = false
    @State private var pressStartDate: Date? = nil
    @State private var chargeWorkItem: DispatchWorkItem? = nil
    @State private var burstRingScale: CGFloat = 1.0
    @State private var burstRingOpacity: Double = 0.0
    @State private var isIdleBreathing: Bool = false
    @State private var shatterStartDate: Date? = nil
    @State private var isShattering: Bool = false

    var body: some View {
        TimelineView(.animation(paused: !isPressing)) { timeline in
            let elapsed = isPressing ? max(0, timeline.date.timeIntervalSince(pressStartDate ?? timeline.date)) : 0
            let progress = isPressing ? min(1.0, elapsed / chargeDuration) : (completedOnce ? 1.0 : 0.0)
            let sprintRatio = isPressing ? pow(max(0.0, (progress - 0.65) / 0.35), 1.2) : 0.0
            let dx = isPressing ? CGFloat(sin(elapsed * 116.0) * 2.3 * sprintRatio) : 0
            let dy = isPressing ? CGFloat(cos(elapsed * 134.0) * 1.8 * sprintRatio) : 0

            Group {
                if useOrbPulse {
                    orbPulseBody(elapsed: elapsed, progress: progress, dx: dx, dy: dy)
                } else {
                    capsuleBody(progress: progress, dx: dx, dy: dy)
                }
            }
            .onChange(of: progress) { newProgress in
                if isPressing {
                    onChargeTick?(newProgress)
                }
            }
        }
        .frame(height: useOrbPulse ? 78 : 52)
        .onAppear {
            SensoryFeedbackService.shared.warmUpHapticEngine()
            if useOrbPulse {
                withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                    isIdleBreathing = true
                }
            }
        }
        .onDisappear {
            cancelScheduledCharge()
            SensoryFeedbackService.shared.stopContinuousChargeHaptic()
            isPressing = false
        }
    }

    /// 76pt 吉卜力手绘水彩「翡翠小芽火漆印章」双帧绽放按钮 + 柔光波纹（纯净无文字）
    @ViewBuilder
    private func orbPulseBody(elapsed: TimeInterval, progress: Double, dx: CGFloat, dy: CGFloat) -> some View {
        let bloomOpacity = completedOnce ? 1.0 : (isPressing ? min(1.0, progress * 1.15) : 0.0)

        ZStack {
            // 待机时极轻呼吸外晕
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: 0xF5D076).opacity(isIdleBreathing ? 0.30 : 0.10),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 46
                    )
                )
                .frame(width: 90, height: 90)
                .scaleEffect(isIdleBreathing ? 1.07 : 0.94)
                .opacity(isPressing || completedOnce ? 0 : 1)
                .allowsHitTesting(false)

            // 按住时温柔向外扩散的暖金柔光波纹（柔和无硬边）
            if isPressing {
                ForEach(0..<2, id: \.self) { idx in
                    let wavePhase = (elapsed * 1.35 + Double(idx) * 0.5).truncatingRemainder(dividingBy: 1.0)
                    let ringAlpha = sin(wavePhase * .pi) * (0.38 + 0.32 * progress)
                    Circle()
                        .stroke(
                            Color(hex: 0xFFE38F).opacity(ringAlpha),
                            lineWidth: 3.5 * (1.0 - wavePhase * 0.55)
                        )
                        .blur(radius: 2.2)
                        .frame(width: 72, height: 72)
                        .scaleEffect(1.0 + wavePhase * 0.58)
                        .allowsHitTesting(false)
                }
            }

            // 蓄满瞬间扩散柔光涟漪
            if burstRingOpacity > 0.001 {
                Circle()
                    .stroke(Color(hex: 0xFFE38F), lineWidth: 4.0)
                    .blur(radius: 2.5)
                    .frame(width: 74, height: 74)
                    .scaleEffect(burstRingScale * 1.24)
                    .opacity(burstRingOpacity)
                    .allowsHitTesting(false)
            }

            // 手绘水彩火漆印章本体（沉睡嫩芽 -> 按住由内而外绽放发光花芽，无任何机械正圆线切边）
            ZStack {
                // 印章背后随蓄力渐强的温柔暖金背光晕
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: 0xFFE38F).opacity(isPressing ? (0.28 + 0.45 * progress) : (completedOnce ? 0.55 : 0)),
                                Color(hex: 0xF5B942).opacity(isPressing ? 0.16 * progress : 0),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 12,
                            endRadius: 56
                        )
                    )
                    .frame(width: 112, height: 112)
                    .allowsHitTesting(false)

                if isShattering {
                    CrystalShatterBurstLayer(startDate: shatterStartDate ?? Date())
                        .frame(width: 220, height: 220)
                        .allowsHitTesting(false)
                }

                Image("IllustWaxSealIdle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 76)
                    .opacity(1.0 - bloomOpacity * 0.88)

                Image("IllustWaxSealBlooming")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 76)
                    .opacity(bloomOpacity)
                    .scaleEffect(0.96 + 0.06 * bloomOpacity)
            }
            .shadow(
                color: isPressing
                    ? Color(hex: 0xFFD86B).opacity(0.35 + 0.45 * progress)
                    : Color.black.opacity(0.14),
                radius: isPressing ? (14 + 14 * CGFloat(progress)) : 7,
                y: 3
            )
            .scaleEffect(completedOnce ? 1.05 : (isPressing ? 0.95 : 1.0))
            .offset(x: dx, y: dy)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: isPressing)
            .animation(.spring(response: 0.28, dampingFraction: 0.60), value: completedOnce)
            .overlay {
                TouchDownControlOverlay(
                    onTouchDown: {
                        guard !isPressing, !completedOnce else { return }
                        beginPress()
                    },
                    onTouchUp: {
                        guard isPressing else { return }
                        endPress()
                    }
                )
            }
            .contentShape(Circle())
        }
        .frame(width: 90, height: 78)
    }

    @ViewBuilder
    private func capsuleBody(progress: Double, dx: CGFloat, dy: CGFloat) -> some View {
        GeometryReader { geo in
            ZStack {
                // 蓄满瞬间扩散光环涟漪
                if burstRingOpacity > 0.001 {
                    Capsule()
                        .stroke(Color(hex: 0xF5C259), lineWidth: 2.2)
                        .scaleEffect(x: burstRingScale, y: 1.0 + (burstRingScale - 1.0) * 1.55)
                        .opacity(burstRingOpacity)
                }

                // 完整饱满的胶囊底色，可柔和融入插画水彩调性
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                accentColor,
                                secondaryAccentColor ?? accentColor.opacity(0.84)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // 按住时从左到右丝滑扫过的暖阳蜜金蓄力光层 + 高光流光（100% GPU 硬件插值）
                HStack(spacing: 0) {
                    ZStack(alignment: .trailing) {
                        LinearGradient(
                            colors: [
                                Color(hex: 0xF9E08D).opacity(0.94),
                                Color(hex: 0xEEB95A).opacity(0.96)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )

                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.0),
                                Color.white.opacity(0.45),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 34)
                        .opacity(isPressing ? 1.0 : 0.0)
                    }
                    .frame(width: geo.size.width * fillProgress)
                    Spacer(minLength: 0)
                }
                .clipShape(Capsule())
                .opacity(fillProgress > 0.001 ? 1.0 : 0.0)

                // 居中图标 + 极简文案
                HStack(spacing: 8) {
                    Image(systemName: completedOnce ? "sun.max.fill" : (isPressing ? "hand.raised.fill" : "sun.max.fill"))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isPressing || completedOnce ? chargingTextColor : textColor)
                        .scaleEffect(completedOnce ? 1.2 : (isPressing ? 1.1 + 0.14 * CGFloat(progress) : 1.0))

                    Text(completedOnce ? completedLabel : (isPressing ? chargingLabel : label))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(isPressing || completedOnce ? chargingTextColor : textColor)
                        .lineLimit(1)
                }
                .padding(.horizontal, 18)
            }
            .overlay(
                Capsule()
                    .stroke(
                        isPressing
                            ? Color(hex: 0xF2BA49).opacity(0.55 + 0.45 * progress)
                            : (completedOnce ? Color(hex: 0xF2BA49).opacity(0.9) : borderColor),
                        lineWidth: isPressing ? (1.2 + 1.1 * CGFloat(progress)) : 1.1
                    )
            )
            .shadow(
                color: isPressing
                    ? Color(hex: 0xF2BA49).opacity(0.22 + 0.32 * progress)
                    : accentColor.opacity(0.14),
                radius: isPressing ? (10 + 10 * CGFloat(progress)) : 6,
                y: 3
            )
            .scaleEffect(completedOnce ? 1.04 : (isPressing ? 0.965 - 0.01 * CGFloat(progress) : 1.0))
            .offset(x: dx, y: dy)
            .animation(.spring(response: 0.22, dampingFraction: 0.68), value: isPressing)
            .animation(.spring(response: 0.24, dampingFraction: 0.56), value: completedOnce)
            .overlay {
                TouchDownControlOverlay(
                    onTouchDown: {
                        guard !isPressing, !completedOnce else { return }
                        beginPress()
                    },
                    onTouchUp: {
                        guard isPressing else { return }
                        endPress()
                    }
                )
            }
            .contentShape(Capsule())
        }
    }

    private func beginPress() {
        isPressing = true
        pressStartDate = Date()
        burstRingScale = 1.0
        burstRingOpacity = 0.0
        SensoryFeedbackService.shared.startContinuousChargeHaptic(duration: chargeDuration)
        onChargeTick?(0.02)

        withAnimation(.linear(duration: chargeDuration)) {
            fillProgress = 1.0
        }

        let item = DispatchWorkItem {
            guard isPressing, !completedOnce else { return }
            isPressing = false
            completedOnce = true
            SensoryFeedbackService.shared.stopContinuousChargeHaptic()

            // 蓄满瞬间触发金光结晶与外环清脆震碎飞散 + 扩散光环涟漪
            shatterStartDate = Date()
            isShattering = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.56) {
                isShattering = false
            }

            burstRingScale = 1.0
            burstRingOpacity = 0.72
            withAnimation(.easeOut(duration: 0.45)) {
                burstRingScale = 1.24
                burstRingOpacity = 0.0
            }

            onCharged()
            if !allowQuickTapClose {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                    withAnimation(.easeOut(duration: 0.20)) {
                        completedOnce = false
                        fillProgress = 0
                    }
                }
            }
        }
        chargeWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + chargeDuration, execute: item)
    }

    private func endPress() {
        cancelScheduledCharge()
        isPressing = false
        onPressEnd?()
        guard !completedOnce else {
            SensoryFeedbackService.shared.stopContinuousChargeHaptic()
            return
        }

        let heldMs = Date().timeIntervalSince(pressStartDate ?? Date()) * 1000.0
        if allowQuickTapClose && heldMs < 240 {
            SensoryFeedbackService.shared.stopContinuousChargeHaptic()
            withAnimation(.easeOut(duration: 0.12)) {
                fillProgress = 0
            }
            onQuickTap?()
            return
        }

        SensoryFeedbackService.shared.cancelChargeHaptic()

        if !allowQuickTapClose && heldMs < 680 {
            onShortPressHint?()
        }

        withAnimation(.easeOut(duration: 0.18)) {
            fillProgress = 0
        }
    }

    private func cancelScheduledCharge() {
        chargeWorkItem?.cancel()
        chargeWorkItem = nil
    }
}

/// 0ms 物理触屏直达监听器（绕过 SwiftUI DragGesture 与父视图 TapGesture 的手势消歧延迟）
private struct TouchDownControlOverlay: UIViewRepresentable {
    let onTouchDown: () -> Void
    let onTouchUp: () -> Void

    func makeUIView(context: Context) -> TouchDetectorView {
        let v = TouchDetectorView()
        v.backgroundColor = .clear
        v.isMultipleTouchEnabled = false
        v.onTouchDown = onTouchDown
        v.onTouchUp = onTouchUp
        return v
    }

    func updateUIView(_ uiView: TouchDetectorView, context: Context) {
        uiView.onTouchDown = onTouchDown
        uiView.onTouchUp = onTouchUp
    }

    final class TouchDetectorView: UIView {
        var onTouchDown: (() -> Void)?
        var onTouchUp: (() -> Void)?

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesBegan(touches, with: event)
            onTouchDown?()
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesEnded(touches, with: event)
            onTouchUp?()
        }

        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesCancelled(touches, with: event)
            onTouchUp?()
        }
    }
}

/// 屏内无阻断星光粒子绽放层（复刻原版 StarburstParticleLayer，42 颗四角星芒与星尘抛物线绽放）
struct StarburstParticleLayer: View {
    let burstId: Int
    var isGrand: Bool = true

    @State private var burstStart: Date? = nil
    @State private var activeSeed: Int = 0
    @State private var particles: [StarParticle] = []

    private struct StarParticle {
        let angle: Double
        let distance: Double
        let size: CGFloat
        let color: Color
        let isStar: Bool
        let rotationSpeed: Double
    }

    private static let palette: [Color] = [
        Color(hex: 0xE9C46A),
        Color(hex: 0xF4A261),
        Color(hex: 0x2D6A4F),
        Color(hex: 0x52B788),
        Color(hex: 0x95D5B2),
        Color(hex: 0xFFF8E7)
    ]

    var body: some View {
        Group {
            if let start = burstStart {
                TimelineView(.animation) { timeline in
                    let elapsed = timeline.date.timeIntervalSince(start)
                    let progress = min(1.0, max(0.0, elapsed / 0.92))

                    if progress < 1.0 {
                        Canvas { context, size in
                            let origin = CGPoint(
                                x: size.width * 0.5,
                                y: size.height * (isGrand ? 0.44 : 0.28)
                            )
                            let eased = 1.0 - pow(1.0 - progress, 3.0)
                            let opacity = max(0.0, min(1.0, 1.0 - progress * progress))

                            for p in particles {
                                let dx = origin.x + cos(p.angle) * p.distance * eased
                                let dy = origin.y + sin(p.angle) * p.distance * eased + (42.0 * progress * progress)
                                let currentSize = p.size * CGFloat(1.0 - progress * 0.35)
                                let color = p.color.opacity(opacity)

                                if p.isStar {
                                    var ctx = context
                                    ctx.translateBy(x: dx, y: dy)
                                    ctx.rotate(by: .radians(p.rotationSpeed * progress))
                                    let star = fourPointStarPath(
                                        center: .zero,
                                        outerRadius: currentSize,
                                        innerRadius: currentSize * 0.38
                                    )
                                    ctx.fill(star, with: .color(color))
                                } else {
                                    let r = currentSize * 0.55
                                    let dot = Path(ellipseIn: CGRect(x: dx - r, y: dy - r, width: r * 2, height: r * 2))
                                    context.fill(dot, with: .color(color))
                                }
                            }
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: burstId) { newId in
            guard newId > 0 else { return }
            spawnBurst(seed: newId)
        }
        .onAppear {
            if burstId > 0 {
                spawnBurst(seed: burstId)
            }
        }
    }

    private func spawnBurst(seed: Int) {
        let count = isGrand ? 42 : 22
        var generated: [StarParticle] = []
        generated.reserveCapacity(count)

        for i in 0..<count {
            let hash = Double(((seed * 9973 + i * 3571) % 10000)) / 10000.0
            let hash2 = Double(((seed * 4219 + i * 7919) % 10000)) / 10000.0
            let hash3 = Double(((seed * 1811 + i * 6133) % 10000)) / 10000.0
            let angle = (Double(i) / Double(count)) * .pi * 2.0 + (hash - 0.5) * 0.35
            let speed = (isGrand ? 130.0 : 85.0) + hash2 * 145.0
            let size = CGFloat((isGrand ? 5.5 : 4.2) + hash3 * 4.8)
            generated.append(StarParticle(
                angle: angle,
                distance: speed,
                size: size,
                color: Self.palette[i % Self.palette.count],
                isStar: i % 3 != 0,
                rotationSpeed: (hash2 - 0.5) * 4.0
            ))
        }
        particles = generated
        activeSeed = seed
        burstStart = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.96) {
            if activeSeed == seed {
                burstStart = nil
            }
        }
    }
}

/// 星籽沿二次贝塞尔弧线飞入顶部「发光星籽罐」胶囊动效层（复刻原版 FlyingStarSeedOverlay）
struct FlyingStarSeedOverlay: View {
    let flightId: Int
    let startPoint: CGPoint
    let targetPoint: CGPoint
    let onLanded: () -> Void

    @State private var flightStart: Date? = nil
    @State private var landedForId: Int = 0

    var body: some View {
        Group {
            if let start = flightStart {
                TimelineView(.animation) { timeline in
                    let elapsed = timeline.date.timeIntervalSince(start)
                    let rawT = min(1.0, max(0.0, elapsed / 0.46))

                    if rawT < 1.0 {
                        Canvas { context, _ in
                            let t = rawT < 0.5
                                ? 4 * rawT * rawT * rawT
                                : 1 - pow(-2 * rawT + 2, 3) / 2
                            let oneMinusT = 1.0 - t
                            let control = CGPoint(
                                x: (startPoint.x + targetPoint.x) * 0.5 - 36,
                                y: min(startPoint.y, targetPoint.y) - 64
                            )
                            let curX = oneMinusT * oneMinusT * startPoint.x
                                + 2 * oneMinusT * t * control.x
                                + t * t * targetPoint.x
                            let curY = oneMinusT * oneMinusT * startPoint.y
                                + 2 * oneMinusT * t * control.y
                                + t * t * targetPoint.y
                            let pos = CGPoint(x: curX, y: curY)
                            let scale = CGFloat(1.15 - 0.45 * t)

                            let glowR = 14.0 * scale
                            let glowRect = CGRect(x: pos.x - glowR, y: pos.y - glowR, width: glowR * 2, height: glowR * 2)
                            context.fill(
                                Path(ellipseIn: glowRect),
                                with: .radialGradient(
                                    Gradient(colors: [Color(hex: 0xE9C46A).opacity(0.55), .clear]),
                                    center: pos,
                                    startRadius: 0,
                                    endRadius: glowR
                                )
                            )

                            let star = fourPointStarPath(center: pos, outerRadius: 10 * scale, innerRadius: 4 * scale)
                            context.fill(star, with: .color(Color(hex: 0xFFD166)))
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: flightId) { newId in
            guard newId > 0 else { return }
            flightStart = Date()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.46) {
                if landedForId != newId {
                    landedForId = newId
                    flightStart = nil
                    onLanded()
                }
            }
        }
    }
}

/// 蓄力满格瞬间的「金光结晶 + 印章外环震碎飞散」120fps Canvas 物理粒子层
private struct CrystalShatterBurstLayer: View {
    let startDate: Date

    private struct ShardSpec {
        let angle: Double
        let startRadius: CGFloat
        let travelDistance: CGFloat
        let size: CGFloat
        let spinSpeed: Double
        let aspect: CGFloat
        let color: Color
    }

    private let shards: [ShardSpec] = {
        let palette: [Color] = [
            Color(hex: 0xFFFDF0),
            Color(hex: 0xFFE699),
            Color(hex: 0xF5C259),
            Color(hex: 0xFAD375)
        ]
        return (0..<16).map { i in
            let baseAngle = (Double(i) / 16.0) * (2.0 * .pi) + Double((i * 13) % 7 - 3) * 0.06
            return ShardSpec(
                angle: baseAngle,
                startRadius: CGFloat(35 + (i % 3) * 3),
                travelDistance: CGFloat(46 + ((i * 19) % 34)),
                size: CGFloat(4.5 + Double((i * 7) % 5) * 1.3),
                spinSpeed: (i % 2 == 0 ? 1.0 : -1.0) * (6.0 + Double(i % 5) * 2.2),
                aspect: CGFloat(0.55 + Double(i % 3) * 0.22),
                color: palette[i % palette.count]
            )
        }
    }()

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = max(0, timeline.date.timeIntervalSince(startDate))
            let duration: Double = 0.52
            let p = min(1.0, elapsed / duration)

            Canvas { ctx, size in
                guard p < 1.0 else { return }
                let cx = size.width * 0.5
                let cy = size.height * 0.5
                let easeOut = 1.0 - pow(1.0 - p, 2.5)
                let alpha = p < 0.15 ? 1.0 : max(0.0, 1.0 - (p - 0.15) / 0.85)

                // 1. 8 段断裂的金色外环弧线向四周震碎弹开
                for k in 0..<8 {
                    let aStart = (Double(k) / 8.0) * 2.0 * .pi + 0.06
                    let aMid = aStart + 0.24
                    let aEnd = aStart + 0.48
                    let r = 38.0 + CGFloat(easeOut) * (28.0 + CGFloat(k % 3) * 6.0)
                    let driftAngle = aMid + (k % 2 == 0 ? 0.12 : -0.12) * p

                    var arcPath = Path()
                    arcPath.addArc(
                        center: CGPoint(
                            x: cx + CGFloat(cos(driftAngle)) * CGFloat(easeOut) * 10.0,
                            y: cy + CGFloat(sin(driftAngle)) * CGFloat(easeOut) * 10.0
                        ),
                        radius: r,
                        startAngle: .radians(aStart),
                        endAngle: .radians(aEnd),
                        clockwise: false
                    )
                    ctx.stroke(
                        arcPath,
                        with: .color(Color(hex: 0xFFE38F).opacity(alpha * 0.85)),
                        style: StrokeStyle(lineWidth: max(0.8, 2.6 * CGFloat(1.0 - p * 0.7)), lineCap: .round)
                    )
                }

                // 2. 16 枚多边形金光结晶碎片高速飞溅与自旋
                for s in shards {
                    let dist = s.startRadius + s.travelDistance * CGFloat(easeOut)
                    let px = cx + CGFloat(cos(s.angle)) * dist
                    let py = cy + CGFloat(sin(s.angle)) * dist
                    let rot = s.angle + s.spinSpeed * elapsed
                    let curSize = s.size * CGFloat(1.0 - p * 0.45)

                    var poly = Path()
                    let pts: [(CGFloat, CGFloat)] = [
                        (curSize, 0),
                        (0, curSize * s.aspect),
                        (-curSize * 0.85, 0),
                        (0, -curSize * s.aspect * 0.8)
                    ]
                    for (idx, pt) in pts.enumerated() {
                        let rx = pt.0 * CGFloat(cos(rot)) - pt.1 * CGFloat(sin(rot))
                        let ry = pt.0 * CGFloat(sin(rot)) + pt.1 * CGFloat(cos(rot))
                        let target = CGPoint(x: px + rx, y: py + ry)
                        if idx == 0 { poly.move(to: target) } else { poly.addLine(to: target) }
                    }
                    poly.closeSubpath()
                    ctx.fill(poly, with: .color(s.color.opacity(alpha)))
                }
            }
        }
    }
}

