import SwiftUI

// MARK: - 热启动/冷启动动画重播令牌

private struct HeaderReplayTokenKey: EnvironmentKey {
    static let defaultValue: Int = 0
}

extension EnvironmentValues {
    var headerReplayToken: Int {
        get { self[HeaderReplayTokenKey.self] }
        set { self[HeaderReplayTokenKey.self] = newValue }
    }
}

// MARK: - 1. 共享莫兰迪高定手绘插画横幅外壳（支持各页完全自定义的左侧内容结构 + 右侧细节微动效叠加）

struct EditorialHeaderBannerShell<LeftContent: View, Artwork: View>: View {
    let backgroundImageName: String
    let borderColor: Color
    let shadowColor: Color
    @ViewBuilder let leftContent: (_ entered: Bool) -> LeftContent
    @ViewBuilder let artwork: (_ pulseTick: Int, _ entered: Bool) -> Artwork
    var onTapBanner: () -> Void

    @Environment(\.headerReplayToken) private var headerReplayToken
    @State private var entered: Bool = false
    @State private var tapPulseTick: Int = 0
    @State private var isPressed: Bool = false

    var body: some View {
        ZStack(alignment: .trailing) {
            // 1. 高定莫兰迪细粒纸感手绘插画底图
            Image(backgroundImageName)
                .resizable()
                .scaledToFill()
                .frame(height: 102)
                .clipped()

            // 2. 右侧插画细节微动效叠加层（透明微光、涟漪、星轨等与原画无缝融合）
            artwork(tapPulseTick, entered)
                .frame(width: 148, height: 102)
                .clipped()
                .allowsHitTesting(false)

            // 3. 左侧完全自定义的专属业务内容区
            HStack(spacing: 0) {
                leftContent(entered)
                    .padding(.leading, 16)
                    .padding(.trailing, 122)

                Spacer(minLength: 0)
            }
        }
        .frame(height: 102)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(borderColor, lineWidth: 1.0)
        )
        .shadow(color: shadowColor, radius: 6, y: 2.5)
        .scaleEffect(isPressed ? 0.985 : 1.0)
        .onAppear {
            if !entered {
                entered = true
            }
        }
        .onChange(of: headerReplayToken) { _ in
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) {
                entered = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
                entered = true
            }
        }
        .onTapGesture {
            SensoryFeedbackService.shared.selection()
            withAnimation(.spring(response: 0.22, dampingFraction: 0.68)) {
                isPressed = true
                tapPulseTick += 1
            }
            onTapBanner()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                    isPressed = false
                }
            }
        }
    }
}

// MARK: - 2. 愿望页细节微动画叠加层（对位原画金色星籽：柔和星芒脉冲 + 漂浮星尘）

struct PlanStarryCanopyArtwork: View {
    let pulseTick: Int
    let entered: Bool

    @State private var twinkle: Bool = false
    @State private var floatPhase: Bool = false
    @State private var burstRipple: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: 0xF59E0B).opacity(twinkle ? 0.30 : 0.10), lineWidth: 1.1)
                .frame(width: twinkle ? 38 : 28, height: twinkle ? 38 : 28)
                .offset(x: -4, y: -14)
                .scaleEffect(entered ? 1.0 : 0.4)
                .opacity(entered ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: twinkle)

            Circle()
                .stroke(Color(hex: 0xFBBF24).opacity(burstRipple ? 0.0 : 0.45), lineWidth: 1.5)
                .frame(width: burstRipple ? 62 : 20, height: burstRipple ? 62 : 20)
                .offset(x: -4, y: -14)

            FourPointStarShape()
                .fill(Color(hex: 0xF59E0B).opacity(twinkle ? 0.78 : 0.32))
                .frame(width: 9, height: 9)
                .offset(x: -24, y: floatPhase ? -24 : -18)
                .scaleEffect(entered ? (twinkle ? 1.15 : 0.85) : 0.1)
                .opacity(entered ? 1.0 : 0.0)
                .animation(.spring(response: 0.44, dampingFraction: 0.68).delay(0.16), value: entered)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: twinkle)
                .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: floatPhase)

            FourPointStarShape()
                .fill(Color(hex: 0x52B788).opacity(twinkle ? 0.45 : 0.80))
                .frame(width: 7.5, height: 7.5)
                .offset(x: 18, y: floatPhase ? -26 : -21)
                .scaleEffect(entered ? (twinkle ? 0.88 : 1.14) : 0.1)
                .opacity(entered ? 1.0 : 0.0)
                .animation(.spring(response: 0.44, dampingFraction: 0.68).delay(0.22), value: entered)
                .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: floatPhase)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
                twinkle = true
                floatPhase = true
            }
        }
        .onChange(of: pulseTick) { _ in
            burstRipple = false
            withAnimation(.easeOut(duration: 0.55)) {
                burstRipple = true
            }
        }
    }
}

// MARK: - 3. 习惯页细节微动画叠加层（对位原画荷叶池塘与露珠：向外扩散的水波光环 + 露珠闪烁）

struct HabitRippleSproutArtwork: View {
    let pulseTick: Int
    let entered: Bool

    @State private var rippleExpand: Bool = false
    @State private var dewGlow: Bool = false
    @State private var tapWave: Bool = false

    var body: some View {
        ZStack {
            Ellipse()
                .stroke(Color.white.opacity(rippleExpand ? 0.0 : 0.55), lineWidth: 1.3)
                .frame(width: rippleExpand ? 86 : 32, height: rippleExpand ? 24 : 9)
                .offset(x: 16, y: 24)
                .opacity(entered ? 1.0 : 0.0)
                .animation(.easeOut(duration: 2.8).repeatForever(autoreverses: false), value: rippleExpand)

            Ellipse()
                .stroke(Color(hex: 0x34D399).opacity(rippleExpand ? 0.0 : 0.36), lineWidth: 1.1)
                .frame(width: rippleExpand ? 72 : 24, height: rippleExpand ? 20 : 7)
                .offset(x: 16, y: 24)
                .opacity(entered ? 1.0 : 0.0)
                .animation(.easeOut(duration: 2.8).delay(1.3).repeatForever(autoreverses: false), value: rippleExpand)

            Ellipse()
                .stroke(Color.white.opacity(tapWave ? 0.0 : 0.72), lineWidth: 1.6)
                .frame(width: tapWave ? 96 : 26, height: tapWave ? 28 : 8)
                .offset(x: 16, y: 24)

            Circle()
                .fill(Color.white.opacity(dewGlow ? 0.85 : 0.25))
                .frame(width: 5, height: 5)
                .blur(radius: 0.6)
                .offset(x: -6, y: dewGlow ? -14 : -10)
                .scaleEffect(entered ? (dewGlow ? 1.2 : 0.8) : 0.1)
                .opacity(entered ? 1.0 : 0.0)
                .animation(.spring(response: 0.44, dampingFraction: 0.70).delay(0.18), value: entered)
                .animation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true), value: dewGlow)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
                rippleExpand = true
                dewGlow = true
            }
        }
        .onChange(of: pulseTick) { _ in
            tapWave = false
            withAnimation(.easeOut(duration: 0.60)) {
                tapWave = true
            }
        }
    }
}

// MARK: - 4. 锚点页细节微动画叠加层（对位原画金色弯月与虚线星轨：公转微光星点 + 柔光脉动）

struct AnchorOrbitClockArtwork: View {
    let pulseTick: Int
    let entered: Bool

    @State private var orbitAngle: Double = 0
    @State private var glowPulse: Bool = false

    var body: some View {
        ZStack {
            ZStack {
                Circle()
                    .fill(Color(hex: 0xF59E0B).opacity(0.82))
                    .frame(width: 5.5, height: 5.5)
                    .shadow(color: Color(hex: 0xF59E0B).opacity(0.65), radius: 3)
                    .offset(y: -35)

                Circle()
                    .fill(Color.white.opacity(0.75))
                    .frame(width: 4, height: 4)
                    .offset(y: 35)
            }
            .offset(x: 16, y: 2)
            .rotationEffect(.degrees(entered ? orbitAngle : -45))
            .opacity(entered ? 1.0 : 0.0)
            .animation(.spring(response: 0.56, dampingFraction: 0.78).delay(0.10), value: entered)

            Circle()
                .stroke(Color(hex: 0xFBBF24).opacity(glowPulse ? 0.34 : 0.10), lineWidth: 1.2)
                .frame(width: glowPulse ? 56 : 48, height: glowPulse ? 56 : 48)
                .offset(x: 16, y: 2)
                .scaleEffect(entered ? 1.0 : 0.6)
                .opacity(entered ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: glowPulse)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
                glowPulse = true
                withAnimation(.linear(duration: 26).repeatForever(autoreverses: false)) {
                    orbitAngle = 360
                }
            }
        }
        .onChange(of: pulseTick) { _ in
            withAnimation(.spring(response: 0.45, dampingFraction: 0.68)) {
                orbitAngle += 72
            }
        }
    }
}

// MARK: - 矢量形状辅助

private struct FourPointStarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let rx = rect.width * 0.5
        let ry = rect.height * 0.5
        let inner = min(rx, ry) * 0.26

        var p = Path()
        p.move(to: CGPoint(x: cx, y: cy - ry))
        p.addQuadCurve(to: CGPoint(x: cx + rx, y: cy), control: CGPoint(x: cx + inner, y: cy - inner))
        p.addQuadCurve(to: CGPoint(x: cx, y: cy + ry), control: CGPoint(x: cx + inner, y: cy + inner))
        p.addQuadCurve(to: CGPoint(x: cx - rx, y: cy), control: CGPoint(x: cx - inner, y: cy + inner))
        p.addQuadCurve(to: CGPoint(x: cx, y: cy - ry), control: CGPoint(x: cx - inner, y: cy - inner))
        p.closeSubpath()
        return p
    }
}
