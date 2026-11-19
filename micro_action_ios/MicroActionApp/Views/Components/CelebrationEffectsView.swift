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

/// 0.6 秒圆环蓄力发光按钮（复刻原版 ChargeToShineButton：迷你星芒蓄力环 + 水平渐变充能 + 轻点/长按双模式 + 阶段触觉反馈）
struct ChargeToShineButton: View {
    let label: String
    var completedLabel: String = "已为自己喝彩"
    var allowQuickTapClose: Bool = false
    var accentColor: Color = BotanicalTheme.gold
    var textColor: Color = BotanicalTheme.textPrimary
    var chargingTextColor: Color = .white
    var onChargeTick: ((Double) -> Void)? = nil
    let onCharged: () -> Void
    var onQuickTap: (() -> Void)? = nil

    @State private var progress: Double = 0
    @State private var completedOnce: Bool = false
    @State private var isPressing: Bool = false
    @State private var pressStartDate: Date? = nil
    @State private var lastTickStage: Int = 0
    @State private var timer: Timer? = nil

    var body: some View {
        let displayProgress = completedOnce ? 1.0 : progress
        let scale = completedOnce ? 1.02 : (isPressing ? 0.975 + displayProgress * 0.055 : 1.0)
        let labelColor: Color = textColor

        GeometryReader { geo in
            ZStack {
                // 稳定底衬（按住时不再突然变浅闪烁）
                Capsule()
                    .fill(accentColor.opacity(0.32))

                if !completedOnce && !isPressing && progress == 0 {
                    Capsule()
                        .fill(accentColor.opacity(0.92))
                }

                // 水平充能进度层 + 右沿高光亮斑
                if displayProgress > 0 {
                    HStack(spacing: 0) {
                        LinearGradient(
                            colors: [accentColor.opacity(0.92), accentColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .overlay(alignment: .trailing) {
                            Circle()
                                .fill(Color.white.opacity(0.55))
                                .frame(width: 18, height: 48)
                                .blur(radius: 6)
                                .offset(x: 4)
                        }
                        .frame(width: max(18, geo.size.width * CGFloat(displayProgress)))
                        Spacer(minLength: 0)
                    }
                    .clipShape(Capsule())
                }

                // 迷你星芒充能环 + 文案
                HStack(spacing: 10) {
                    MiniStarRingView(progress: displayProgress, color: labelColor)
                        .frame(width: 22, height: 22)

                    Text(completedOnce ? completedLabel : (isPressing ? "继续按住蓄力..." : label))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(labelColor)
                        .lineLimit(1)
                }
                .padding(.horizontal, 18)
            }
            .overlay(
                Capsule()
                    .stroke(
                        isPressing ? Color.white.opacity(0.72) : accentColor.opacity(0.58),
                        lineWidth: isPressing ? 1.8 : 1.4
                    )
            )
            .shadow(
                color: progress > 0.02 ? accentColor.opacity(0.38 * max(0.35, progress)) : .clear,
                radius: CGFloat(10 + 14 * progress),
                y: 4
            )
            .scaleEffect(scale)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: isPressing)
            .contentShape(Capsule())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isPressing, !completedOnce else { return }
                        startCharging()
                    }
                    .onEnded { _ in
                        guard isPressing else { return }
                        endCharging()
                    }
            )
        }
        .frame(height: 54)
        .onDisappear {
            timer?.invalidate()
            timer = nil
            isPressing = false
        }
    }

    private func startCharging() {
        isPressing = true
        lastTickStage = 0
        progress = 0.02
        // 按下瞬间即刻给予明确触觉按压反馈
        onChargeTick?(0.02)

        let start = Date()
        pressStartDate = start
        timer?.invalidate()
        let newTimer = Timer(timeInterval: 1.0 / 120.0, repeats: true) { t in
            guard isPressing, !completedOnce else {
                t.invalidate()
                return
            }
            let elapsed = Date().timeIntervalSince(start)
            let p = min(1.0, max(0.02, elapsed / 0.6))
            progress = p
            let stage: Int
            if p >= 0.82 { stage = 3 }
            else if p >= 0.54 { stage = 2 }
            else if p >= 0.26 { stage = 1 }
            else { stage = 0 }

            if stage > lastTickStage {
                lastTickStage = stage
                onChargeTick?(p)
            }

            if p >= 1.0 && !completedOnce {
                t.invalidate()
                timer = nil
                isPressing = false
                completedOnce = true
                onCharged()
                if !allowQuickTapClose {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) {
                        withAnimation(.easeOut(duration: 0.22)) {
                            completedOnce = false
                            progress = 0
                            lastTickStage = 0
                        }
                    }
                }
            }
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }

    private func endCharging() {
        isPressing = false
        timer?.invalidate()
        timer = nil
        guard !completedOnce else { return }

        let heldMs = (Date().timeIntervalSince(pressStartDate ?? Date())) * 1000.0
        if allowQuickTapClose && heldMs < 220 && progress < 0.38 {
            progress = 0
            onQuickTap?()
            return
        }
        withAnimation(.easeOut(duration: 0.22)) {
            progress = 0
        }
    }
}

/// 按钮内的迷你星芒充能圆环
private struct MiniStarRingView: View {
    let progress: Double
    let color: Color

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = size.width * 0.44

            let baseCircle = Path(ellipseIn: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            ))
            context.stroke(baseCircle, with: .color(color.opacity(0.32)), lineWidth: 1.8)

            if progress > 0 {
                var arc = Path()
                arc.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .radians(-.pi / 2),
                    endAngle: .radians(-.pi / 2 + .pi * 2 * progress),
                    clockwise: false
                )
                context.stroke(
                    arc,
                    with: .color(color),
                    style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
                )
            }

            let star = fourPointStarPath(
                center: center,
                outerRadius: size.width * 0.28,
                innerRadius: size.width * 0.11
            )
            context.fill(star, with: .color(color))
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
