import SwiftUI
import UIKit

/// 全屏高光庆祝海报（挂载于最顶层，绝不被任何 Sheet 遮挡）
/// 完整复刻原版 SuccessPopup 动效与布局，并保留 Pro 四套主题皮肤、DeepSeek 四大人设、ImageRenderer 3x 海报导出与 0.6s 蓄力星芒环按钮
struct CelebrationPosterView: View {
    let payload: CelebrationPayload
    let onDismiss: () -> Void
    var onChargedDismiss: (() -> Void)? = nil

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var proStore: ProStoreService

    @State private var currentQuote: String = ""
    @State private var useClassicArt: Bool = false
    @State private var isAiLoading: Bool = false
    @State private var isSavingPoster: Bool = false
    @State private var inlineTip: String? = nil
    @State private var appearScale: CGFloat = 0.88
    @State private var appearOpacity: Double = 0
    @State private var innerBurstId: Int = 1

    private var theme: CelebrationThemeSkin {
        appState.themeSkin
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { dismissWithCopy() }

            StarburstParticleLayer(burstId: innerBurstId, isGrand: true)
                .ignoresSafeArea()

            GeometryReader { geo in
                let cardWidth = min(geo.size.width * 0.90, 420)
                let cardHeight = min(geo.size.height * 0.82, 710)

                ZStack {
                    posterCardContent(width: cardWidth, height: cardHeight, forExport: false)
                }
                .frame(width: cardWidth, height: cardHeight)
                .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
                .shadow(color: Color.black.opacity(0.32), radius: 40, y: 22)
                .scaleEffect(appearScale)
                .opacity(appearOpacity)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
        .onAppear {
            currentQuote = payload.quote
            useClassicArt = (payload.id % 2 == 1)
            withAnimation(.spring(response: 0.40, dampingFraction: 0.76)) {
                appearScale = 1.0
                appearOpacity = 1.0
            }
        }
        .onChange(of: payload.quote) { newQuote in
            if !newQuote.isEmpty {
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentQuote = newQuote
                }
            }
        }
    }

    @ViewBuilder
    private func posterCardContent(width: CGFloat, height: CGFloat, forExport: Bool) -> some View {
        let artHeight = height * 0.56

        ZStack(alignment: .bottom) {
            theme.bgColor
                .animation(.easeInOut(duration: 0.3), value: theme)

            // 上半部分：动态旋转放射星芒 + 呼吸插画（1.12x 超采样裁剪，彻底消除上下浮动缝隙）+ 漂浮闪烁星尘
            VStack(spacing: 0) {
                ZStack {
                    if forExport {
                        SunburstHaloCanvas(progress: 0.15, gold: theme.goldColor, peach: theme.peachColor)
                        posterArtImage
                            .frame(width: width, height: artHeight)
                            .scaleEffect(1.06)
                            .clipped()
                        FloatingSparklesCanvas(progress: 0.25, gold: theme.goldColor, cream: theme.creamColor, peach: theme.peachColor)
                    } else {
                        TimelineView(.animation) { timeline in
                            let elapsed = timeline.date.timeIntervalSinceReferenceDate
                            let t = (elapsed.truncatingRemainder(dividingBy: 9.0)) / 9.0
                            let bobY = sin(t * 2 * .pi * 2) * 3.5
                            let scale = 1.0 + sin(t * 2 * .pi) * 0.014

                            ZStack {
                                SunburstHaloCanvas(progress: t, gold: theme.goldColor, peach: theme.peachColor)
                                posterArtImage
                                    .frame(width: width, height: artHeight)
                                    .scaleEffect(1.12 * scale)
                                    .offset(y: bobY)
                                FloatingSparklesCanvas(progress: t, gold: theme.goldColor, cream: theme.creamColor, peach: theme.peachColor)
                            }
                            .frame(width: width, height: artHeight)
                            .clipped()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            SensoryFeedbackService.shared.lightTap()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                useClassicArt.toggle()
                            }
                        }
                    }

                    // 底部柔和过渡遮罩，与下半区自然融合
                    VStack {
                        Spacer()
                        LinearGradient(
                            stops: [
                                .init(color: theme.bgColor.opacity(0.0), location: 0.0),
                                .init(color: theme.bgColor.opacity(0.24), location: 0.30),
                                .init(color: theme.bgColor.opacity(0.70), location: 0.65),
                                .init(color: theme.bgColor.opacity(0.95), location: 0.88),
                                .init(color: theme.bgColor, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 120)
                    }
                    .allowsHitTesting(false)
                }
                .frame(width: width, height: artHeight)
                .clipped()
                Spacer(minLength: 0)
            }

            // 顶部工具栏：左侧皮肤快速切换圆点 + 切换画作按钮，右侧手绘关闭按钮（导出时隐藏）
            if !forExport {
                VStack {
                    HStack(spacing: 8) {
                        HStack(spacing: 6) {
                            ForEach(CelebrationThemeSkin.allCases) { skin in
                                let active = theme == skin
                                Button {
                                    SensoryFeedbackService.shared.selection()
                                    withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                                        appState.setThemeSkin(skin)
                                    }
                                } label: {
                                    Circle()
                                        .fill(skin.bgColor)
                                        .frame(width: 18, height: 18)
                                        .overlay(
                                            Circle()
                                                .stroke(active ? skin.goldColor : Color.white.opacity(0.45), lineWidth: active ? 2.2 : 1)
                                        )
                                        .scaleEffect(active ? 1.15 : 1.0)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(skin.name)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.24))
                        .clipShape(Capsule())

                        Button {
                            SensoryFeedbackService.shared.lightTap()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                useClassicArt.toggle()
                            }
                        } label: {
                            Text(useClassicArt ? "经典插画" : "版画插画")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(theme.creamColor)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(Color.black.opacity(0.24))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button {
                            SensoryFeedbackService.shared.selection()
                            dismissWithCopy()
                        } label: {
                            BotanicalCloseIcon()
                                .stroke(theme.darkColor, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                                .frame(width: 14, height: 14)
                                .frame(width: 38, height: 38)
                                .background(theme.creamColor.opacity(0.95))
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.12), radius: 6, y: 2)
                        }
                        .buttonStyle(ScaleBounceButtonStyle(scale: 0.90))
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
                    Spacer()
                }
            }

            // 下半部分：里程碑徽章 + 完成事项 + 奶油色庆祝语大卡片 + 操作区
            VStack(alignment: .leading, spacing: 10) {
                Text(payload.milestoneTag ?? "行动庆祝")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(theme.goldColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(theme.creamColor.opacity(0.16))
                    .overlay(
                        Capsule().stroke(theme.creamColor.opacity(0.26), lineWidth: 1)
                    )
                    .clipShape(Capsule())

                Text(payload.actionTitle)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(theme.creamColor)
                    .lineLimit(2)

                // 奶油色庆祝语大卡片（轻点单复制）
                Button {
                    UIPasteboard.general.string = currentQuote.isEmpty ? payload.quote : currentQuote
                    SensoryFeedbackService.shared.lightTap()
                    showTip("已复制庆祝文案")
                } label: {
                    Text(currentQuote.isEmpty ? payload.quote : currentQuote)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(theme.darkColor)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(theme.creamColor.opacity(0.97))
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: theme.goldColor.opacity(0.18), radius: 18, y: 6)
                }
                .buttonStyle(ScaleBounceButtonStyle(scale: 0.98))

                if forExport {
                    HStack(spacing: 6) {
                        Spacer()
                        FeatherStarPenIcon()
                            .stroke(theme.goldColor, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                            .frame(width: 14, height: 14)
                        Text("微步 · 今日发光时刻")
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(0.8)
                            .foregroundColor(theme.creamColor.opacity(0.88))
                        Spacer()
                    }
                    .padding(.top, 10)
                } else {
                    // AI 定制夸夸官 + 保存发光海报 双胶囊条
                    HStack(spacing: 8) {
                        Button {
                            handleAiCustomCelebration()
                        } label: {
                            HStack(spacing: 6) {
                                if isAiLoading {
                                    ProgressView()
                                        .tint(theme.goldColor)
                                        .scaleEffect(0.75)
                                } else {
                                    FeatherStarPenIcon()
                                        .stroke(theme.goldColor, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                                        .frame(width: 14, height: 14)
                                }
                                Text(isAiLoading ? "AI 生成中..." : "换一句·\(appState.aiPersona.name)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(theme.creamColor)
                                    .lineLimit(1)
                                if !proStore.isPro {
                                    Text("PRO")
                                        .font(.system(size: 9, weight: .heavy))
                                        .foregroundColor(theme.darkColor)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(theme.goldColor)
                                        .clipShape(Capsule())
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(theme.creamColor.opacity(0.15))
                            .overlay(Capsule().stroke(theme.goldColor.opacity(0.35), lineWidth: 1))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(ScaleBounceButtonStyle(scale: 0.95))
                        .disabled(isAiLoading)

                        Button {
                            savePosterToPhotos(width: width, height: height)
                        } label: {
                            HStack(spacing: 6) {
                                if isSavingPoster {
                                    ProgressView()
                                        .tint(theme.goldColor)
                                        .scaleEffect(0.75)
                                } else {
                                    ArtFrameSaveIcon()
                                        .stroke(theme.goldColor, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                                        .frame(width: 14, height: 14)
                                }
                                Text(isSavingPoster ? "生成海报中..." : "保存发光海报")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(theme.creamColor)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(theme.creamColor.opacity(0.15))
                            .overlay(Capsule().stroke(theme.goldColor.opacity(0.35), lineWidth: 1))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(ScaleBounceButtonStyle(scale: 0.95))
                        .disabled(isSavingPoster)
                    }

                    if let tip = inlineTip {
                        Text(tip)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(theme.goldColor)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    // 0.6s 圆环蓄力发光按钮（复刻原版 ChargeToShineButton）
                    ChargeToShineButton(
                        label: "按住 0.6 秒为自己鼓掌",
                        completedLabel: "已复制并浇灌成长树",
                        allowQuickTapClose: true,
                        accentColor: theme.accentColor,
                        textColor: theme.creamColor,
                        onChargeTick: { p in
                            SensoryFeedbackService.shared.chargeTick(progress: p)
                        },
                        onCharged: {
                            SensoryFeedbackService.shared.celebrateGrand(
                                soundEnabled: appState.soundEnabled,
                                soundPack: appState.soundPack
                            )
                            innerBurstId += 1
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
                                UIPasteboard.general.string = currentQuote.isEmpty ? payload.quote : currentQuote
                                if let onChargedDismiss {
                                    onChargedDismiss()
                                } else {
                                    onDismiss()
                                }
                            }
                        },
                        onQuickTap: {
                            dismissWithCopy()
                        }
                    )
                    .padding(.top, 2)
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 20)
        }
    }

    private var posterArtImage: some View {
        Group {
            if useClassicArt {
                Image("IllustCelebrationClassic")
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            } else {
                Image("IllustCelebrationPoster")
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            }
        }
    }

    private func dismissWithCopy() {
        UIPasteboard.general.string = currentQuote.isEmpty ? payload.quote : currentQuote
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
