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

/// 0.6 秒丝滑蓄力发光按钮（支持按住 0.6s 蓄力鼓掌 + 简单轻点一下直接完成；纯 GPU 线性动画 + 单次 DispatchWorkItem，零 Timer 卡顿）
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

    @State private var fillProgress: CGFloat = 0
    @State private var isPressing: Bool = false
    @State private var completedOnce: Bool = false
    @State private var pressStartDate: Date? = nil
    @State private var chargeWorkItem: DispatchWorkItem? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack {
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

                // 按住时从左到右丝滑扫过的暖阳蜜金蓄力光层（100% GPU 硬件插值）
                HStack(spacing: 0) {
                    LinearGradient(
                        colors: [
                            Color(hex: 0xF7DA85).opacity(0.92),
                            Color(hex: 0xEEB95A).opacity(0.95)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * fillProgress)
                    Spacer(minLength: 0)
                }
                .clipShape(Capsule())
                .opacity(fillProgress > 0.001 ? 1.0 : 0.0)

                // 居中图标 + 极简文案
                HStack(spacing: 8) {
                    Image(systemName: completedOnce ? "sparkles" : (isPressing ? "hand.raised.fill" : "sun.max.fill"))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isPressing || completedOnce ? chargingTextColor : textColor)
                        .scaleEffect(isPressing ? 1.15 : 1.0)

                    Text(completedOnce ? completedLabel : (isPressing ? chargingLabel : label))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(isPressing || completedOnce ? chargingTextColor : textColor)
                        .lineLimit(1)
                }
                .padding(.horizontal, 18)
            }
            .overlay(
                Capsule()
                    .stroke(isPressing ? Color(hex: 0xE6B558).opacity(0.85) : borderColor, lineWidth: 1.1)
            )
            .shadow(color: accentColor.opacity(isPressing ? 0.30 : 0.14), radius: isPressing ? 12 : 6, y: 3)
            .scaleEffect(completedOnce ? 1.02 : (isPressing ? 0.97 : 1.0))
            .animation(.spring(response: 0.24, dampingFraction: 0.72), value: isPressing)
            .contentShape(Capsule())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isPressing, !completedOnce else { return }
                        beginPress()
                    }
                    .onEnded { _ in
                        guard isPressing else { return }
                        endPress()
                    }
            )
        }
        .frame(height: 52)
        .onDisappear {
            cancelScheduledCharge()
            isPressing = false
        }
    }

    private func beginPress() {
        isPressing = true
        pressStartDate = Date()
        onChargeTick?(0.02)

        withAnimation(.linear(duration: 0.6)) {
            fillProgress = 1.0
        }

        let item = DispatchWorkItem {
            guard isPressing, !completedOnce else { return }
            isPressing = false
            completedOnce = true
            onCharged()
            if !allowQuickTapClose {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                    withAnimation(.easeOut(duration: 0.22)) {
                        completedOnce = false
                        fillProgress = 0
                    }
                }
            }
        }
        chargeWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: item)
    }

    private func endPress() {
        cancelScheduledCharge()
        isPressing = false
        guard !completedOnce else { return }

        let heldMs = Date().timeIntervalSince(pressStartDate ?? Date()) * 1000.0
        if allowQuickTapClose && heldMs < 260 {
            withAnimation(.easeOut(duration: 0.15)) {
                fillProgress = 0
            }
            onQuickTap?()
            return
        }

        withAnimation(.easeOut(duration: 0.22)) {
            fillProgress = 0
        }
    }

    private func cancelScheduledCharge() {
        chargeWorkItem?.cancel()
        chargeWorkItem = nil
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
