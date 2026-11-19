import SwiftUI

/// 「星芽 / StarSprout」完全原创 IP 精灵：露珠星芽灵
/// - 半透明翡翠液态玻璃露珠水滴形态 + 头顶摇曳发光双嫩芽 + 悬浮暖金四角星芒 + 原创星光豆眼与治愈微笑
/// - 支持待机/开心/鼓励多态表情与 60fps 轻盈呼吸、嫩叶摇曳、星芒微颤动效
typealias StarSproutMascotView = TiimoMascotOrbView

struct TiimoMascotOrbView: View {
    enum Style {
        case hero
        case dockAvatar
    }

    enum Mood {
        case idle
        case happy
        case encourage
    }

    var style: Style = .hero
    var accentTopIcon: String = "sparkles"
    var mood: Mood = .idle

    @State private var isBreathing: Bool = false
    @State private var isStarGlowing: Bool = false

    var body: some View {
        switch style {
        case .hero:
            heroDewdropMascot
        case .dockAvatar:
            dockDewdropMascot
        }
    }

    /// 大号原创「露珠星芽灵」（适用于空状态、庆祝页、引导页）
    private var heroDewdropMascot: some View {
        ZStack {
            // 底部清晨森雾弥散光晕
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            BotanicalTheme.primaryLight.opacity(0.28),
                            BotanicalTheme.primarySoft.opacity(0.10),
                            .clear
                        ],
                        center: .center,
                        startRadius: 4,
                        endRadius: 56
                    )
                )
                .frame(width: 112, height: 34)
                .offset(y: 44)
                .scaleEffect(isBreathing ? 0.94 : 1.04)

            VStack(spacing: -6) {
                // 头顶悬浮暖金四角星芒 + 摇曳双嫩芽
                ZStack {
                    // 暖金星芒背光
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: 0xFFE08A).opacity(isStarGlowing ? 0.72 : 0.38),
                                    Color(hex: 0xF4B942).opacity(0.16),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 1,
                                endRadius: 22
                            )
                        )
                        .frame(width: 44, height: 44)
                        .offset(y: -14)

                    // 悬浮暖金四角星芒
                    FourPointStarShape()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0xFFF3C4), Color(hex: 0xF4B942)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 16, height: 16)
                        .shadow(color: Color(hex: 0xF4B942).opacity(0.65), radius: 6)
                        .offset(y: isBreathing ? -17 : -12)
                        .scaleEffect(isStarGlowing ? 1.12 : 0.94)

                    // 左小嫩叶（轻微摇曳）
                    SproutLeafShape()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0x95D5B2), Color(hex: 0x2D6A4F)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            SproutLeafShape()
                                .stroke(Color.white.opacity(0.65), lineWidth: 0.9)
                        )
                        .frame(width: 24, height: 14)
                        .rotationEffect(.degrees(isBreathing ? -34 : -26), anchor: .bottomTrailing)
                        .offset(x: -11, y: 2)

                    // 右小嫩叶（轻微对称摇曳）
                    SproutLeafShape()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0xB7E4C7), Color(hex: 0x40916C)],
                                startPoint: .topTrailing,
                                endPoint: .bottomLeading
                            )
                        )
                        .overlay(
                            SproutLeafShape()
                                .stroke(Color.white.opacity(0.72), lineWidth: 0.9)
                        )
                        .frame(width: 20, height: 12)
                        .scaleEffect(x: -1, y: 1)
                        .rotationEffect(.degrees(isBreathing ? 30 : 22), anchor: .bottomLeading)
                        .offset(x: 10, y: 3)
                }
                .frame(width: 72, height: 42)
                .zIndex(2)

                // 半透明液态翡翠露珠水滴主体
                ZStack {
                    // 主体通透翡翠液态玻璃渐变
                    DewdropBodyShape()
                        .fill(
                            RadialGradient(
                                stops: [
                                    .init(color: Color(hex: 0xEEFCF4), location: 0.0),
                                    .init(color: Color(hex: 0x95D5B2).opacity(0.92), location: 0.42),
                                    .init(color: Color(hex: 0x52B788).opacity(0.94), location: 0.74),
                                    .init(color: Color(hex: 0x2D6A4F), location: 1.0)
                                ],
                                center: UnitPoint(x: 0.36, y: 0.32),
                                startRadius: 4,
                                endRadius: 56
                            )
                        )
                        .frame(width: 84, height: 82)
                        .shadow(color: BotanicalTheme.primary.opacity(0.24), radius: 14, y: 8)

                    // 底部内部暖绿焦散折射光弧（液态玻璃灵魂质感）
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0xD8F3DC).opacity(0.72), Color(hex: 0xFFE08A).opacity(0.28)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 50, height: 14)
                        .blur(radius: 4)
                        .offset(y: 26)

                    // 左上晶莹玻璃弧形高光
                    Capsule()
                        .fill(Color.white.opacity(0.78))
                        .frame(width: 20, height: 8)
                        .rotationEffect(.degrees(-34))
                        .blur(radius: 1.2)
                        .offset(x: -18, y: -15)

                    // 外圈细腻液态玻璃折射描边
                    DewdropBodyShape()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.94),
                                    Color.white.opacity(0.32),
                                    Color(hex: 0xB7E4C7).opacity(0.55)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.4
                        )
                        .frame(width: 84, height: 82)

                    // 原创灵动治愈系五官
                    StarSproutFace(scale: 1.0, mood: mood)
                        .offset(y: 7)
                }
            }
            .offset(y: isBreathing ? -3.5 : 2.5)
        }
        .frame(width: 116, height: 120)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                isStarGlowing = true
            }
        }
    }

    /// 底部悬浮 Dock / 侧边栏头像专用的「微步」版画风小芽精灵头像（带克制优雅的呼吸微动）
    private var dockDewdropMascot: some View {
        ZStack {
            Image("MascotTinyStep")
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
                .scaleEffect(isBreathing ? 1.045 : 0.985)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.92),
                            Color.white.opacity(0.35),
                            BotanicalTheme.primaryLight.opacity(0.35)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.4
                )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
    }
}

/// 原创露珠水滴精灵廓形（顶部圆润微收，底部饱满柔和）
private struct DewdropBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: w * 0.50, y: h * 0.04))
        path.addCurve(
            to: CGPoint(x: w * 0.96, y: h * 0.60),
            control1: CGPoint(x: w * 0.78, y: h * 0.06),
            control2: CGPoint(x: w * 0.96, y: h * 0.32)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.50, y: h * 0.98),
            control1: CGPoint(x: w * 0.96, y: h * 0.85),
            control2: CGPoint(x: w * 0.76, y: h * 0.98)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.04, y: h * 0.60),
            control1: CGPoint(x: w * 0.24, y: h * 0.98),
            control2: CGPoint(x: w * 0.04, y: h * 0.85)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.50, y: h * 0.04),
            control1: CGPoint(x: w * 0.04, y: h * 0.32),
            control2: CGPoint(x: w * 0.22, y: h * 0.06)
        )
        path.closeSubpath()
        return path
    }
}

/// 原创自然曲线小嫩叶形状
private struct SproutLeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: w, y: h * 0.85))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: h * 0.15),
            control: CGPoint(x: w * 0.55, y: -h * 0.25)
        )
        path.addQuadCurve(
            to: CGPoint(x: w, y: h * 0.85),
            control: CGPoint(x: w * 0.32, y: h * 1.12)
        )
        path.closeSubpath()
        return path
    }
}

/// 原创暖金四角星芒形状
private struct FourPointStarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let rx = rect.width * 0.5
        let ry = rect.height * 0.5
        var path = Path()
        path.move(to: CGPoint(x: cx, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: cy), control: CGPoint(x: cx + rx * 0.18, y: cy - ry * 0.18))
        path.addQuadCurve(to: CGPoint(x: cx, y: rect.maxY), control: CGPoint(x: cx + rx * 0.18, y: cy + ry * 0.18))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: cy), control: CGPoint(x: cx - rx * 0.18, y: cy + ry * 0.18))
        path.addQuadCurve(to: CGPoint(x: cx, y: rect.minY), control: CGPoint(x: cx - rx * 0.18, y: cy - ry * 0.18))
        path.closeSubpath()
        return path
    }
}

/// 原创「露珠星芽灵」治愈系五官（星光豆眼 + 柔光嫩桃腮红 + 温柔弧形微笑）
private struct StarSproutFace: View {
    var scale: CGFloat = 1.0
    var mood: TiimoMascotOrbView.Mood = .idle

    var body: some View {
        VStack(spacing: 4 * scale) {
            HStack(spacing: 14 * scale) {
                eyeView
                eyeView
            }

            ZStack {
                // 两侧柔光嫩桃腮红
                HStack(spacing: 26 * scale) {
                    Ellipse()
                        .fill(Color(hex: 0xFF9E80).opacity(0.42))
                        .frame(width: 9.5 * scale, height: 5.5 * scale)
                        .blur(radius: 1.2 * scale)
                    Ellipse()
                        .fill(Color(hex: 0xFF9E80).opacity(0.42))
                        .frame(width: 9.5 * scale, height: 5.5 * scale)
                        .blur(radius: 1.2 * scale)
                }
                .offset(y: -2 * scale)

                // 治愈系微笑嘴角
                Path { path in
                    let w: CGFloat = 11 * scale
                    let h: CGFloat = 5 * scale
                    path.move(to: CGPoint(x: 0, y: h * 0.25))
                    path.addQuadCurve(
                        to: CGPoint(x: w, y: h * 0.25),
                        control: CGPoint(x: w * 0.5, y: h * 1.15)
                    )
                }
                .stroke(
                    Color(hex: 0x1B4332),
                    style: StrokeStyle(lineWidth: 2.0 * scale, lineCap: .round)
                )
                .frame(width: 11 * scale, height: 5 * scale)
            }
        }
    }

    @ViewBuilder
    private var eyeView: some View {
        if mood == .happy {
            // 开心弯弯月牙笑眼
            Path { path in
                let w: CGFloat = 10 * scale
                let h: CGFloat = 5.5 * scale
                path.move(to: CGPoint(x: 0, y: h))
                path.addQuadCurve(
                    to: CGPoint(x: w, y: h),
                    control: CGPoint(x: w * 0.5, y: -h * 0.2)
                )
            }
            .stroke(
                Color(hex: 0x1B4332),
                style: StrokeStyle(lineWidth: 2.2 * scale, lineCap: .round)
            )
            .frame(width: 10 * scale, height: 6 * scale)
        } else {
            // 灵动深森星光豆眼 + 白色星芒高光点
            ZStack {
                Circle()
                    .fill(Color(hex: 0x1B4332))
                    .frame(width: 8.5 * scale, height: 8.5 * scale)

                Circle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: 3.0 * scale, height: 3.0 * scale)
                    .offset(x: -1.6 * scale, y: -1.6 * scale)

                Circle()
                    .fill(Color(hex: 0xFFE08A).opacity(0.85))
                    .frame(width: 1.6 * scale, height: 1.6 * scale)
                    .offset(x: 1.8 * scale, y: 1.8 * scale)
            }
        }
    }
}

/// 液态玻璃快捷行动胶囊提示条（带柔和上浮淡入动效）
struct TiimoQuickActionPill: View {
    let icon: String
    let iconColor: Color
    let title: String
    let action: () -> Void

    @State private var appeared: Bool = false

    var body: some View {
        Button {
            SensoryFeedbackService.shared.lightTap()
            action()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                    .background(iconColor.opacity(0.13))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(title)
                    .font(.system(size: 14.5, weight: .medium))
                    .foregroundColor(BotanicalTheme.textPrimary.opacity(0.90))
                    .lineLimit(1)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 11)
            .liquidGlassCapsule(
                tint: BotanicalTheme.primaryLight,
                interactive: true,
                shadowRadius: 10
            )
        }
        .buttonStyle(ScaleBounceButtonStyle(scale: 0.96))
        .offset(y: appeared ? 0 : 12)
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
                appeared = true
            }
        }
    }
}

/// 森系翡翠液态玻璃柔光横幅卡片（带柔和上浮淡入动效）
struct TiimoSoftBannerCard: View {
    let title: String
    let subtitle: String
    let buttonLabel: String
    let action: () -> Void

    @State private var appeared: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(BotanicalTheme.textPrimary)
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(BotanicalTheme.primary)
                }

                Text(subtitle)
                    .font(.system(size: 12.5))
                    .foregroundColor(BotanicalTheme.textPrimary.opacity(0.74))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button {
                SensoryFeedbackService.shared.selection()
                action()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 11, weight: .bold))
                    Text(buttonLabel)
                        .font(.system(size: 13.5, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(BotanicalTheme.primaryGradient)
                .clipShape(Capsule())
                .shadow(color: BotanicalTheme.primary.opacity(0.24), radius: 8, y: 3)
            }
            .buttonStyle(ScaleBounceButtonStyle(scale: 0.94))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(BotanicalTheme.tiimoBannerGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.82), lineWidth: 1.1)
                )
        )
        .shadow(color: BotanicalTheme.primary.opacity(0.12), radius: 16, y: 6)
        .offset(y: appeared ? 0 : 16)
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.54, dampingFraction: 0.84).delay(0.08)) {
                appeared = true
            }
        }
    }
}

/// 原创版画插画展示视图（无框透明底，优雅缩放淡入 + 持续轻盈呼吸漂浮与柔和微摆）
struct StarSproutIllustrationBadge: View {
    let imageName: String
    var size: CGFloat = 196

    @State private var appeared: Bool = false
    @State private var isFloating: Bool = false
    @State private var isSwaying: Bool = false

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .scaleEffect(appeared ? (isFloating ? 1.02 : 0.99) : 0.84)
            .rotationEffect(.degrees(isSwaying ? 1.4 : -1.4))
            .offset(y: appeared ? (isFloating ? -5 : 3) : 18)
            .opacity(appeared ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.spring(response: 0.58, dampingFraction: 0.78)) {
                    appeared = true
                }
                withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true).delay(0.35)) {
                    isFloating = true
                }
                withAnimation(.easeInOut(duration: 3.6).repeatForever(autoreverses: true).delay(0.45)) {
                    isSwaying = true
                }
            }
    }
}

