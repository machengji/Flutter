import SwiftUI

/// Tiimo 风格柔光精灵吉祥物组件（支持空状态大号 Hero 样式与底部悬浮 Dock 迷你圆形样式）
struct TiimoMascotOrbView: View {
    enum Style {
        case hero
        case dockAvatar
    }

    var style: Style = .hero
    var accentTopIcon: String = "clock"

    @State private var isFloating: Bool = false

    var body: some View {
        switch style {
        case .hero:
            heroMascot
        case .dockAvatar:
            dockAvatarMascot
        }
    }

    /// 居中柔光精灵球 + 极简手绘笑眼 + 顶部漂浮手绘风小物件（参考 Tiimo 主屏插画）
    private var heroMascot: some View {
        VStack(spacing: 2) {
            // 顶部轻盈漂浮小物件（手绘极简细线条风格）
            ZStack {
                // 左上小星芒
                Image(systemName: "sparkle")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(BotanicalTheme.textPrimary.opacity(0.75))
                    .offset(x: -18, y: -16)

                // 右上迷你圆点
                Circle()
                    .stroke(BotanicalTheme.textPrimary.opacity(0.80), lineWidth: 1.5)
                    .frame(width: 14, height: 14)
                    .offset(x: 16, y: -18)

                // 中央手绘风主题图标圆徽
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.65))
                        .frame(width: 40, height: 40)
                    Circle()
                        .stroke(BotanicalTheme.textPrimary.opacity(0.85), lineWidth: 1.5)
                        .frame(width: 40, height: 40)
                    Image(systemName: accentTopIcon)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(BotanicalTheme.textPrimary.opacity(0.88))
                }
                .offset(y: 4)
            }
            .frame(width: 72, height: 54)
            .offset(y: isFloating ? -4 : 3)
            .animation(
                .easeInOut(duration: 2.6).repeatForever(autoreverses: true),
                value: isFloating
            )

            // 柔光薰衣草紫渐变光球 + 手绘线条弯弯笑眼
            ZStack {
                // 外层柔焦漫射光晕
                Circle()
                    .fill(
                        RadialGradient(
                            stops: [
                                .init(color: Color(hex: 0x7A5BFF).opacity(0.88), location: 0.0),
                                .init(color: Color(hex: 0x9C80FF).opacity(0.65), location: 0.48),
                                .init(color: Color(hex: 0xCAB8FF).opacity(0.28), location: 0.78),
                                .init(color: .clear, location: 1.0)
                            ],
                            center: UnitPoint(x: 0.5, y: 0.62),
                            startRadius: 2,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: 5)

                // 顶部轻盈微白高光
                Circle()
                    .fill(Color.white.opacity(0.45))
                    .frame(width: 54, height: 24)
                    .blur(radius: 8)
                    .offset(y: -22)

                // 极简可爱表情（弯弯眯眼 + 小微笑）
                TiimoMascotFace(scale: 1.0)
                    .offset(y: -14)
            }
            .frame(width: 100, height: 92)
        }
        .onAppear {
            isFloating = true
        }
        .onDisappear {
            isFloating = false
        }
    }

    /// 底部右侧独立悬浮圆形精灵球（参考 Tiimo 底部右下角圆形图标）
    private var dockAvatarMascot: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: Color(hex: 0xEDE6FF), location: 0.0),
                            .init(color: Color(hex: 0xBBA6FF), location: 0.52),
                            .init(color: Color(hex: 0x8466FF), location: 1.0)
                        ],
                        center: UnitPoint(x: 0.36, y: 0.28),
                        startRadius: 2,
                        endRadius: 34
                    )
                )

            // 柔和顶部光斑
            Circle()
                .fill(Color.white.opacity(0.42))
                .frame(width: 22, height: 12)
                .blur(radius: 4)
                .offset(x: -6, y: -12)

            TiimoMascotFace(scale: 0.56)
                .offset(y: -3)
        }
    }
}

/// Tiimo 标志性上拱下平半月形眼廓
private struct TiimoHalfMoonEyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.55)
        )
        path.closeSubpath()
        return path
    }
}

/// 极简手绘风格半月大眼与俏皮微笑曲线（贴合 Tiimo 参考图精灵表情）
private struct TiimoMascotFace: View {
    var scale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 2.5 * scale) {
            HStack(spacing: 1.5 * scale) {
                eyeView(pupilOffsetX: 2.2)
                eyeView(pupilOffsetX: -2.2)
            }

            // 俏皮微笑嘴角
            Path { path in
                let w: CGFloat = 11 * scale
                let h: CGFloat = 4.5 * scale
                path.move(to: CGPoint(x: 0, y: h * 0.35))
                path.addQuadCurve(
                    to: CGPoint(x: w, y: h * 0.35),
                    control: CGPoint(x: w * 0.5, y: h * 1.15)
                )
            }
            .stroke(
                BotanicalTheme.textPrimary,
                style: StrokeStyle(lineWidth: 1.65 * scale, lineCap: .round)
            )
            .frame(width: 11 * scale, height: 4.5 * scale)
        }
    }

    private func eyeView(pupilOffsetX: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            TiimoHalfMoonEyeShape()
                .fill(Color.white.opacity(0.96))
                .frame(width: 24 * scale, height: 12 * scale)
                .overlay(
                    TiimoHalfMoonEyeShape()
                        .stroke(BotanicalTheme.textPrimary, style: StrokeStyle(lineWidth: 1.5 * scale, lineJoin: .round))
                )

            // 贴底黑色圆瞳孔（按 24x12 半月眼眶精确裁切）
            Circle()
                .fill(BotanicalTheme.textPrimary)
                .frame(width: 9.5 * scale, height: 9.5 * scale)
                .offset(x: pupilOffsetX * scale, y: 1.2 * scale)
                .frame(width: 24 * scale, height: 12 * scale, alignment: .bottom)
                .clipShape(TiimoHalfMoonEyeShape())
        }
    }
}

/// Tiimo 风格左对齐白底微边框快捷胶囊提示条
struct TiimoQuickActionPill: View {
    let icon: String
    let iconColor: Color
    let title: String
    let action: () -> Void

    var body: some View {
        Button {
            SensoryFeedbackService.shared.lightTap()
            action()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 22, height: 22)
                    .background(iconColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                Text(title)
                    .font(.system(size: 14.5, weight: .medium))
                    .foregroundColor(BotanicalTheme.textPrimary.opacity(0.88))
                    .lineLimit(1)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 11)
            .background(Color.white.opacity(0.92))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(BotanicalTheme.border.opacity(0.92), lineWidth: 1)
            )
            .shadow(color: BotanicalTheme.shadowLight, radius: 10, y: 3)
        }
        .buttonStyle(ScaleBounceButtonStyle(scale: 0.96))
    }
}

/// Tiimo 风格淡紫玻璃渐变横幅卡片（参考截图底部浅紫卡片 + 右侧柔光胶囊按钮）
struct TiimoSoftBannerCard: View {
    let title: String
    let subtitle: String
    let buttonLabel: String
    let action: () -> Void

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
                    .foregroundColor(BotanicalTheme.textPrimary.opacity(0.72))
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
                .foregroundColor(BotanicalTheme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(
                    Capsule()
                        .fill(Color(hex: 0xC6B6FA).opacity(0.68))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.55), lineWidth: 0.9)
                        )
                )
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
                        .stroke(Color.white.opacity(0.75), lineWidth: 1.1)
                )
        )
        .shadow(color: BotanicalTheme.primary.opacity(0.12), radius: 16, y: 6)
    }
}
