import SwiftUI
import UIKit

/// 破框精灵立体弹窗庆祝卡（非全屏居中悬浮弹窗，顶部小新芽精灵物理破框探出，文字与水彩画布无缝融合）
struct CelebrationPosterView: View {
    let payload: CelebrationPayload
    let onDismiss: () -> Void
    var onChargedDismiss: (() -> Void)? = nil

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var proStore: ProStoreService

    @State private var currentQuote: String = ""
    @State private var currentAiQuote: String = ""
    @State private var isAiLoading: Bool = false
    @State private var isSavingPoster: Bool = false
    @State private var inlineTip: String? = nil

    // 分层入场与呼吸动效状态
    @State private var appearScale: CGFloat = 0.86
    @State private var appearOpacity: Double = 0
    @State private var mascotScale: CGFloat = 0.65
    @State private var mascotEnterY: CGFloat = 24
    @State private var mascotBreathing: Bool = false
    @State private var contentOpacity: Double = 0
    @State private var contentOffsetY: CGFloat = 12
    @State private var isChargingGlow: Bool = false
    @State private var innerBurstId: Int = 1

    private var theme: CelebrationThemeSkin {
        appState.themeSkin
    }

    var body: some View {
        ZStack {
            // 柔和压暗背景（保留任务列表景深）
            Color.black.opacity(0.42)
                .ignoresSafeArea()
                .onTapGesture { dismissWithCopy() }

            StarburstParticleLayer(burstId: innerBurstId, isGrand: true)
                .ignoresSafeArea()

            GeometryReader { geo in
                let cardWidth = min(geo.size.width * 0.83, 354)
                let cardHeight = min(geo.size.height * 0.60, 468)

                ZStack {
                    posterCardContent(width: cardWidth, height: cardHeight, forExport: false)
                }
                .frame(width: cardWidth, height: cardHeight)
                .scaleEffect(appearScale)
                .opacity(appearOpacity)
                // 向下微移 22pt 为顶部破框精灵留出舒适视觉重心
                .position(x: geo.size.width / 2, y: geo.size.height / 2 + 22)
            }
        }
        .onAppear {
            currentQuote = payload.quote
            currentAiQuote = payload.aiQuote ?? ""

            // 1. 底卡轻盈弹出
            withAnimation(.spring(response: 0.40, dampingFraction: 0.78)) {
                appearScale = 1.0
                appearOpacity = 1.0
            }
            // 2. 顶部破框小新芽精灵延迟 Q 弹跳出
            withAnimation(.spring(response: 0.48, dampingFraction: 0.66).delay(0.08)) {
                mascotScale = 1.0
                mascotEnterY = 0
            }
            // 3. 文案与按钮错落上浮显影
            withAnimation(.easeOut(duration: 0.34).delay(0.14)) {
                contentOpacity = 1.0
                contentOffsetY = 0
            }
            // 4. 精灵持续轻柔呼吸浮沉
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true).delay(0.35)) {
                mascotBreathing = true
            }
        }
        .onChange(of: payload.quote) { newQuote in
            if !newQuote.isEmpty {
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentQuote = newQuote
                }
            }
        }
        .onChange(of: payload.aiQuote) { newAi in
            if let text = newAi, !text.isEmpty {
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentAiQuote = text
                }
            }
        }
    }

    @ViewBuilder
    private func posterCardContent(width: CGFloat, height: CGFloat, forExport: Bool) -> some View {
        let inkPrimary = Color(hex: 0x1D4231)
        let inkSecondary = Color(hex: 0x4C6B5B)
        let mascotWidth = min(width * 0.66, 232)

        ZStack(alignment: .top) {
            // 第 1 层：暖奶油水彩纸底卡（内部裁圆角，零边框割裂感）
            ZStack {
                Color(hex: 0xFAF6ED)

                Image("IllustCelebrationPoster")
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
                    .opacity(0.96)

                // 右上角极简关闭按钮（导出图隐藏）
                if !forExport {
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                SensoryFeedbackService.shared.selection()
                                dismissWithCopy()
                            } label: {
                                BotanicalCloseIcon()
                                    .stroke(inkSecondary, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                                    .frame(width: 11, height: 11)
                                    .frame(width: 30, height: 30)
                                    .background(Color(hex: 0xFAF6ED).opacity(0.75))
                                    .overlay(Circle().stroke(Color(hex: 0xE2DAC8).opacity(0.8), lineWidth: 0.8))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(ScaleBounceButtonStyle(scale: 0.90))
                        }
                        .padding(.top, 14)
                        .padding(.trailing, 14)
                        Spacer()
                    }
                }

                // 卡片内容区：直接排版在水彩画布留白之上（无生硬白框）
                VStack(spacing: 0) {
                    Spacer(minLength: forExport ? 118 : 112)

                    // 步数与里程碑标签（带数字跳动）
                    HStack(spacing: 6) {
                        Text(payload.milestoneTag ?? "今日首胜")
                        Text("·")
                        HStack(spacing: 2) {
                            Text("第")
                            Text("\(appState.todayShineCount)")
                                .contentTransition(.numericText())
                            Text("步")
                        }
                    }
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(inkSecondary)
                    .tracking(0.6)

                    // 主标题（完成动作名）
                    Text(payload.actionTitle)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(inkPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.top, 8)
                        .padding(.horizontal, 20)

                    // 鼓励金句（直接融入水彩画布留白，轻点可复制）
                    let activeQuote = currentQuote.isEmpty ? payload.quote : currentQuote
                    Button {
                        guard !activeQuote.isEmpty else { return }
                        UIPasteboard.general.string = activeQuote
                        SensoryFeedbackService.shared.lightTap()
                        showTip("已复制这句鼓励")
                    } label: {
                        Group {
                            if activeQuote.isEmpty {
                                HStack(spacing: 6) {
                                    ProgressView()
                                        .tint(inkSecondary)
                                        .scaleEffect(0.78)
                                    Text("「\(appState.aiPersona.name)」正在写鼓励...")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(inkSecondary)
                                }
                            } else {
                                Text(activeQuote)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(inkSecondary)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4.5)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 26)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(ScaleBounceButtonStyle(scale: 0.98))
                    .padding(.top, 4)

                    Spacer(minLength: 10)

                    if let tip = inlineTip, !forExport {
                        Text(tip)
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(BotanicalTheme.primary)
                            .padding(.bottom, 6)
                            .transition(.opacity)
                    }

                    if forExport {
                        HStack(spacing: 6) {
                            FeatherStarPenIcon()
                                .stroke(inkSecondary, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                                .frame(width: 13, height: 13)
                            Text("微步 · 今日发光时刻")
                                .font(.system(size: 11.5, weight: .semibold))
                                .tracking(0.8)
                                .foregroundColor(inkSecondary)
                        }
                        .padding(.bottom, 22)
                    } else {
                        // 主交互按钮：与水彩画布融为一体的柔雾鼠尾草薄荷绿 + 极简「按住」文案
                        ChargeToShineButton(
                            label: "按住",
                            chargingLabel: "蓄力中...",
                            completedLabel: "已发光",
                            allowQuickTapClose: true,
                            accentColor: Color(hex: 0xD7EBDC),
                            secondaryAccentColor: Color(hex: 0xC1DFC9),
                            borderColor: Color(hex: 0xA8CEB2).opacity(0.78),
                            textColor: Color(hex: 0x1D4432),
                            chargingTextColor: Color(hex: 0x5C3A08),
                            onChargeTick: { p in
                                SensoryFeedbackService.shared.chargeTick(progress: p)
                                if !isChargingGlow {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        isChargingGlow = true
                                    }
                                }
                            },
                            onCharged: {
                                isChargingGlow = false
                                SensoryFeedbackService.shared.celebrateGrand(
                                    soundEnabled: appState.soundEnabled,
                                    soundPack: appState.soundPack
                                )
                                innerBurstId += 1
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
                                    UIPasteboard.general.string = combinedCopyText
                                    if let onChargedDismiss {
                                        onChargedDismiss()
                                    } else {
                                        onDismiss()
                                    }
                                }
                            },
                            onQuickTap: {
                                isChargingGlow = false
                                dismissWithCopy()
                            }
                        )
                        .frame(width: min(width * 0.62, 220))

                        // 极简辅助操作（融合在水彩纸底上的半透明轻文字）
                        HStack(spacing: 18) {
                            Button {
                                handleAiCustomCelebration()
                            } label: {
                                HStack(spacing: 4) {
                                    if isAiLoading {
                                        ProgressView()
                                            .tint(inkSecondary)
                                            .scaleEffect(0.68)
                                    } else {
                                        FeatherStarPenIcon()
                                            .stroke(inkSecondary, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
                                            .frame(width: 11.5, height: 11.5)
                                    }
                                    Text(isAiLoading ? "生成中" : "换一句")
                                        .font(.system(size: 11.5, weight: .semibold))
                                        .foregroundColor(inkSecondary)
                                    if !proStore.isPro {
                                        Text("PRO")
                                            .font(.system(size: 8.5, weight: .heavy))
                                            .foregroundColor(Color(hex: 0x8A5D12))
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Color(hex: 0xF5E0AC).opacity(0.85))
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                            }
                            .buttonStyle(ScaleBounceButtonStyle(scale: 0.94))
                            .disabled(isAiLoading)

                            Button {
                                savePosterToPhotos(width: width, height: height)
                            } label: {
                                HStack(spacing: 4) {
                                    if isSavingPoster {
                                        ProgressView()
                                            .tint(inkSecondary)
                                            .scaleEffect(0.68)
                                    } else {
                                        ArtFrameSaveIcon()
                                            .stroke(inkSecondary, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
                                            .frame(width: 11.5, height: 11.5)
                                    }
                                    Text(isSavingPoster ? "保存中" : "存海报")
                                        .font(.system(size: 11.5, weight: .semibold))
                                        .foregroundColor(inkSecondary)
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                            }
                            .buttonStyle(ScaleBounceButtonStyle(scale: 0.94))
                            .disabled(isSavingPoster)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    }
                }
                .opacity(forExport ? 1.0 : contentOpacity)
                .offset(y: forExport ? 0 : contentOffsetY)
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .stroke(Color(hex: 0xEFE6D3), lineWidth: 1.2)
            )
            .shadow(color: Color.black.opacity(0.24), radius: 34, y: 18)

            // 第 2 层：物理破框小新芽精灵贴纸（超出底卡顶部边界，独立呼吸微动）
            ZStack {
                if isChargingGlow && !forExport {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: 0xFFE38F).opacity(0.55), .clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: mascotWidth * 0.55
                            )
                        )
                        .frame(width: mascotWidth * 1.1, height: mascotWidth * 1.1)
                        .transition(.opacity)
                }

                Image("IllustCelebrationMascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: mascotWidth)
                    .shadow(color: Color(hex: 0x4A6B56).opacity(0.18), radius: 14, y: 8)
            }
            .offset(
                y: (forExport ? -58 : -64 + mascotEnterY + (mascotBreathing ? -4.5 : 2.5))
            )
            .rotationEffect(.degrees(forExport ? 0 : (mascotBreathing ? 1.2 : -1.2)))
            .scaleEffect(forExport ? 1.0 : (mascotScale * (isChargingGlow ? 1.06 : 1.0)))
            .allowsHitTesting(false)
        }
        // 为导出图保留顶部破框安全边距，避免导出截图头部被裁切
        .padding(.top, forExport ? 68 : 0)
    }

    private var combinedCopyText: String {
        let active = currentQuote.isEmpty ? payload.quote : currentQuote
        return active.isEmpty ? payload.actionTitle : active
    }

    private func dismissWithCopy() {
        UIPasteboard.general.string = combinedCopyText
        SensoryFeedbackService.shared.lightTap()
        onDismiss()
    }

    private func showTip(_ message: String) {
        inlineTip = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            if inlineTip == message {
                inlineTip = nil
            }
        }
    }

    private func handleAiCustomCelebration() {
        if !proStore.isPro {
            appState.showProPaywall = true
            return
        }
        isAiLoading = true
        inlineTip = nil
        Task {
            do {
                let text = try await appState.generateAiCelebration(actionTitle: payload.actionTitle)
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentQuote = text
                    }
                    innerBurstId += 1
                    SensoryFeedbackService.shared.celebrateGrand(
                        soundEnabled: appState.soundEnabled,
                        soundPack: appState.soundPack
                    )
                    showTip("AI「\(appState.aiPersona.name)」已为你定制专属庆祝语")
                    isAiLoading = false
                }
            } catch {
                await MainActor.run {
                    showTip(error.localizedDescription)
                    isAiLoading = false
                }
            }
        }
    }

    @MainActor
    private func savePosterToPhotos(width: CGFloat, height: CGFloat) {
        isSavingPoster = true
        let exportView = posterCardContent(width: width, height: height, forExport: true)
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
            .environmentObject(appState)
            .environmentObject(proStore)

        let renderer = ImageRenderer(content: exportView)
        renderer.scale = 3.0
        if let uiImage = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            SensoryFeedbackService.shared.celebrateGrand(
                soundEnabled: false,
                soundPack: appState.soundPack
            )
            showTip("高清发光海报已保存至系统相册")
        } else {
            showTip("海报生成失败，请重试")
        }
        isSavingPoster = false
    }
}

/// 10 条柔和旋转放射星芒光束
private struct SunburstHaloCanvas: View {
    let progress: Double
    let gold: Color
    let peach: Color

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width * 0.5, y: size.height * 0.45)
            let maxR = max(size.width, size.height) * 0.72
            let baseAngle = progress * 2 * .pi
            let pulse = 0.88 + sin(progress * 4 * .pi) * 0.12

            let haloRect = CGRect(
                x: center.x - maxR * 0.65,
                y: center.y - maxR * 0.65,
                width: maxR * 1.3,
                height: maxR * 1.3
            )
            context.fill(
                Path(ellipseIn: haloRect),
                with: .radialGradient(
                    Gradient(colors: [
                        gold.opacity(0.18 * pulse),
                        peach.opacity(0.08 * pulse),
                        .clear
                    ]),
                    center: center,
                    startRadius: 0,
                    endRadius: maxR * 0.65
                )
            )

            let rayCount = 10
            for i in 0..<rayCount {
                let a = baseAngle + Double(i) * (2 * .pi / Double(rayCount))
                let halfSpan = 0.085
                var path = Path()
                path.move(to: center)
                path.addLine(to: CGPoint(
                    x: center.x + cos(a - halfSpan) * maxR,
                    y: center.y + sin(a - halfSpan) * maxR
                ))
                path.addLine(to: CGPoint(
                    x: center.x + cos(a + halfSpan) * maxR,
                    y: center.y + sin(a + halfSpan) * maxR
                ))
                path.closeSubpath()
                context.fill(
                    path,
                    with: .radialGradient(
                        Gradient(colors: [gold.opacity(i % 2 == 0 ? 0.12 : 0.06), .clear]),
                        center: center,
                        startRadius: 0,
                        endRadius: maxR
                    )
                )
            }
        }
        .allowsHitTesting(false)
    }
}

/// 14 颗缓缓飘升闪烁的四角星尘
private struct FloatingSparklesCanvas: View {
    let progress: Double
    let gold: Color
    let cream: Color
    let peach: Color

    private let seeds: [(Double, Double, Double, Double, Int)] = [
        (0.12, 0.85, 0.00, 4.5, 0),
        (0.24, 0.72, 0.14, 3.2, 1),
        (0.36, 0.90, 0.28, 5.0, 2),
        (0.52, 0.80, 0.41, 3.8, 0),
        (0.68, 0.88, 0.56, 4.6, 1),
        (0.82, 0.76, 0.72, 3.4, 2),
        (0.91, 0.92, 0.19, 4.0, 0),
        (0.18, 0.45, 0.63, 3.0, 1),
        (0.44, 0.36, 0.84, 3.8, 2),
        (0.75, 0.42, 0.35, 4.2, 0),
        (0.60, 0.58, 0.91, 3.1, 1),
        (0.30, 0.62, 0.48, 3.6, 2),
        (0.86, 0.55, 0.08, 3.2, 0),
        (0.08, 0.54, 0.76, 2.8, 1)
    ]

    var body: some View {
        Canvas { context, size in
            let palette = [gold, cream, peach]
            for s in seeds {
                let t = (progress + s.2).truncatingRemainder(dividingBy: 1.0)
                let x = size.width * s.0 + sin(t * 4 * .pi) * 6.0
                let y = size.height * (s.1 - t * 0.55)
                let alpha = max(0, min(1, sin(t * .pi))) * 0.85
                let r = s.3 * (0.7 + 0.3 * sin(t * .pi))
                let color = palette[s.4].opacity(alpha)

                var star = Path()
                star.move(to: CGPoint(x: x, y: y - r))
                star.addQuadCurve(to: CGPoint(x: x + r, y: y), control: CGPoint(x: x, y: y))
                star.addQuadCurve(to: CGPoint(x: x, y: y + r), control: CGPoint(x: x, y: y))
                star.addQuadCurve(to: CGPoint(x: x - r, y: y), control: CGPoint(x: x, y: y))
                star.addQuadCurve(to: CGPoint(x: x, y: y - r), control: CGPoint(x: x, y: y))
                star.closeSubpath()
                context.fill(star, with: .color(color))
            }
        }
        .allowsHitTesting(false)
    }
}

/// 定制手绘感交叉关闭图标
private struct BotanicalCloseIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let inset = rect.width * 0.08
        p.move(to: CGPoint(x: rect.minX + inset, y: rect.minY + inset))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX - inset, y: rect.maxY - inset),
            control: CGPoint(x: rect.midX + rect.width * 0.06, y: rect.midY - rect.height * 0.04)
        )
        p.move(to: CGPoint(x: rect.maxX - inset, y: rect.minY + inset))
        p.addQuadCurve(
            to: CGPoint(x: rect.minX + inset, y: rect.maxY - inset),
            control: CGPoint(x: rect.midX - rect.width * 0.06, y: rect.midY - rect.height * 0.04)
        )
        return p
    }
}

/// 定制星芒羽毛笔矢量图标（替代通用 sparkles）
private struct FeatherStarPenIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        // 四角小星芒
        p.move(to: CGPoint(x: w * 0.72, y: h * 0.06))
        p.addLine(to: CGPoint(x: w * 0.72, y: h * 0.34))
        p.move(to: CGPoint(x: w * 0.58, y: h * 0.20))
        p.addLine(to: CGPoint(x: w * 0.86, y: h * 0.20))
        // 羽毛笔叶片弧线
        p.move(to: CGPoint(x: w * 0.14, y: h * 0.88))
        p.addQuadCurve(
            to: CGPoint(x: w * 0.64, y: h * 0.36),
            control: CGPoint(x: w * 0.26, y: h * 0.52)
        )
        p.addQuadCurve(
            to: CGPoint(x: w * 0.24, y: h * 0.78),
            control: CGPoint(x: w * 0.56, y: h * 0.68)
        )
        return p
    }
}

/// 定制画框收藏矢量图标（替代通用下载图标）
private struct ArtFrameSaveIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        // 下方相框托盘
        p.move(to: CGPoint(x: w * 0.12, y: h * 0.58))
        p.addLine(to: CGPoint(x: w * 0.12, y: h * 0.86))
        p.addLine(to: CGPoint(x: w * 0.88, y: h * 0.86))
        p.addLine(to: CGPoint(x: w * 0.88, y: h * 0.58))
        // 中央落下小箭头
        p.move(to: CGPoint(x: w * 0.50, y: h * 0.14))
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.64))
        p.move(to: CGPoint(x: w * 0.31, y: h * 0.45))
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.65))
        p.addLine(to: CGPoint(x: w * 0.69, y: h * 0.45))
        return p
    }
}
