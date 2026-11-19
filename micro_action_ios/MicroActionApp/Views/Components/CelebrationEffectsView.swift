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

/// 三段式「连点 3 次点亮星苞（Tap-to-Bloom）」互动按钮：萌芽 → 含苞 → 绽放（零 Timer 轮询、120Hz 原生 Spring 丝滑不卡顿）
struct ChargeToShineButton: View {
    let label: String
    var completedLabel: String = "星花盛放 · 已送入成长树"
    var allowQuickTapClose: Bool = false
    var accentColor: Color = BotanicalTheme.gold
    var textColor: Color = BotanicalTheme.textPrimary
    var chargingTextColor: Color = .white
    var onChargeTick: ((Double) -> Void)? = nil
    let onCharged: () -> Void
    var onQuickTap: (() -> Void)? = nil

    @State private var tapStep: Int = 0
    @State private var completedOnce: Bool = false
    @State private var rippleScale: CGFloat = 1.0
    @State private var rippleOpacity: Double = 0

    private let totalSteps: Int = 3

    var body: some View {
        let displayProgress = completedOnce ? 1.0 : Double(tapStep) / Double(totalSteps)

        Button {
            handleTap()
        } label: {
            GeometryReader { geo in
                ZStack {
                    // 底座底色
                    Capsule()
                        .fill(accentColor.opacity(0.28))

                    // 动态推进的阶段能量条（纯 GPU Spring 过渡，零主线程定时器）
                    HStack(spacing: 0) {
                        LinearGradient(
                            colors: [accentColor.opacity(0.85), accentColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: max(tapStep == 0 && !completedOnce ? 0 : 28, geo.size.width * CGFloat(max(0.10, displayProgress))))
                        Spacer(minLength: 0)
                    }
                    .clipShape(Capsule())
                    .opacity(tapStep == 0 && !completedOnce ? 0.35 : 1.0)

                    // 中心互动内容：星苞演进矢量图标 + 阶段文案 + 三颗星点指示器
                    HStack(spacing: 10) {
                        StarBudStageIcon(stage: completedOnce ? 3 : tapStep, color: textColor)
                            .frame(width: 24, height: 24)

                        Text(stageTitle)
                            .font(.system(size: 14.5, weight: .bold))
                            .foregroundColor(textColor)
                            .lineLimit(1)
                            .contentTransition(.numericText())

                        Spacer(minLength: 4)

                        HStack(spacing: 5) {
                            ForEach(1...totalSteps, id: \.self) { step in
                                Circle()
                                    .fill(step <= (completedOnce ? totalSteps : tapStep) ? textColor : textColor.opacity(0.28))
                                    .frame(width: step <= tapStep ? 7.5 : 6, height: step <= tapStep ? 7.5 : 6)
                                    .scaleEffect(step == tapStep ? 1.25 : 1.0)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                }
                .overlay(
                    Capsule()
                        .stroke(textColor.opacity(tapStep > 0 ? 0.65 : 0.35), lineWidth: tapStep > 0 ? 1.6 : 1.2)
                )
                .overlay(
                    Capsule()
                        .stroke(textColor.opacity(rippleOpacity), lineWidth: 2)
                        .scaleEffect(rippleScale)
                )
                .shadow(
                    color: tapStep > 0 ? accentColor.opacity(0.32) : .clear,
                    radius: CGFloat(6 + tapStep * 4),
                    y: 3
                )
            }
            .frame(height: 54)
        }
        .buttonStyle(ScaleBounceButtonStyle(scale: 0.96))
        .disabled(completedOnce)
    }

    private var stageTitle: String {
        if completedOnce || tapStep >= totalSteps {
            return completedLabel
        }
        switch tapStep {
        case 1: return "再点 2 下 · 星籽萌芽啦 (1/3)"
        case 2: return "最后 1 下 · 即将绽放光芒 (2/3)"
        default: return label
        }
    }

    private func handleTap() {
        guard !completedOnce else { return }

        // 触发轻盈波纹涟漪
        rippleScale = 1.0
        rippleOpacity = 0.55
        withAnimation(.easeOut(duration: 0.42)) {
            rippleScale = 1.06
            rippleOpacity = 0
        }

        withAnimation(.spring(response: 0.32, dampingFraction: 0.68)) {
            tapStep += 1
        }

        if tapStep < totalSteps {
            onChargeTick?(Double(tapStep) / Double(totalSteps))
        } else {
            completedOnce = true
            onCharged()
            if !allowQuickTapClose {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        completedOnce = false
                        tapStep = 0
                    }
                }
            }
        }
    }
}

/// 星苞三段成长动态矢量图标：0 星籽 -> 1 萌芽 -> 2 含苞 -> 3 星花绽放
private struct StarBudStageIcon: View {
    let stage: Int
    let color: Color

    var body: some View {
        Canvas { context, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let center = CGPoint(x: cx, y: cy)

            if stage == 0 {
                // 0: 静谧星籽
                let seed = Path(ellipseIn: CGRect(x: cx - 4.5, y: cy - 3.5, width: 9, height: 11))
                context.fill(seed, with: .color(color.opacity(0.9)))
                let ring = Path(ellipseIn: CGRect(x: cx - 9, y: cy - 9, width: 18, height: 18))
                context.stroke(ring, with: .color(color.opacity(0.35)), lineWidth: 1.5)
            } else if stage == 1 {
                // 1: 萌芽抽枝（茎 + 两片舒展小叶）
                var stem = Path()
                stem.move(to: CGPoint(x: cx, y: size.height * 0.82))
                stem.addLine(to: CGPoint(x: cx, y: size.height * 0.36))
                context.stroke(stem, with: .color(color), style: StrokeStyle(lineWidth: 2.0, lineCap: .round))

                var leftLeaf = Path()
                leftLeaf.move(to: CGPoint(x: cx, y: size.height * 0.52))
                leftLeaf.addQuadCurve(to: CGPoint(x: cx - 7, y: size.height * 0.30), control: CGPoint(x: cx - 6, y: size.height * 0.54))
                leftLeaf.addQuadCurve(to: CGPoint(x: cx, y: size.height * 0.52), control: CGPoint(x: cx - 1, y: size.height * 0.30))
                context.fill(leftLeaf, with: .color(color))

                var rightLeaf = Path()
                rightLeaf.move(to: CGPoint(x: cx, y: size.height * 0.46))
                rightLeaf.addQuadCurve(to: CGPoint(x: cx + 7, y: size.height * 0.24), control: CGPoint(x: cx + 6, y: size.height * 0.48))
                rightLeaf.addQuadCurve(to: CGPoint(x: cx, y: size.height * 0.46), control: CGPoint(x: cx + 1, y: size.height * 0.24))
                context.fill(rightLeaf, with: .color(color))
            } else if stage == 2 {
                // 2: 含苞欲放（饱满星苞 + 外围光晕环）
                let outerRing = Path(ellipseIn: CGRect(x: cx - 10, y: cy - 10, width: 20, height: 20))
                context.stroke(outerRing, with: .color(color.opacity(0.55)), lineWidth: 1.6)
                let star = fourPointStarPath(center: center, outerRadius: size.width * 0.34, innerRadius: size.width * 0.16)
                context.fill(star, with: .color(color))
            } else {
                // 3: 星花彻底绽放（主四角星 + 旋转45度副四角星）
                let mainStar = fourPointStarPath(center: center, outerRadius: size.width * 0.46, innerRadius: size.width * 0.17)
                context.fill(mainStar, with: .color(color))
                let subStar = fourPointStarPath(center: center, outerRadius: size.width * 0.30, innerRadius: size.width * 0.12)
                var rotated = subStar
                let transform = CGAffineTransform(translationX: cx, y: cy)
                    .rotated(by: .pi / 4)
                    .translatedBy(x: -cx, y: -cy)
                rotated = rotated.applying(transform)
                context.fill(rotated, with: .color(color.opacity(0.82)))
            }
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
