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
    @State private var currentJoke: String = ""
    @State private var currentAiQuote: String = ""
    @State private var isAiLoading: Bool = false
    @State private var isSavingPoster: Bool = false
    @State private var isPreparingShare: Bool = false
    @State private var inlineTip: String? = nil

    // 单焦点互动状态
    @State private var spotlightMode: SpotlightMode = .praise
    @State private var isJokeRevealed: Bool = false
    @State private var isSwitchingSpotlight: Bool = false
    @State private var sharePosterItem: SharePosterItem? = nil

    // 幸运签状态
    @State private var currentFortune: MicroFortuneSlip? = nil

    // 分层入场与呼吸动效状态
    @State private var appearScale: CGFloat = 0.86
    @State private var appearOpacity: Double = 0
    @State private var mascotScale: CGFloat = 0.65
    @State private var mascotEnterY: CGFloat = 24
    @State private var mascotBreathing: Bool = false
    @State private var contentOpacity: Double = 0
    @State private var contentOffsetY: CGFloat = 12
    @State private var isChargingGlow: Bool = false
    @State private var chargeProgress: Double = 0
    @State private var innerBurstId: Int = 1

    private var theme: CelebrationThemeSkin {
        appState.themeSkin
    }

    private enum CelebrationCardStyle: Int, CaseIterable {
        case morningSprout = 0   // 破框小芽晨光卡
        case starryNight = 1     // 星空许愿夜光卡
        case blossomWreath = 2   // 水彩花环奖章卡
        case classicAstro = 3    // 经典欢呼卡通卡（阿童木飞天挥拳 + 旋转放射星芒）

        var backgroundImage: String {
            switch self {
            case .morningSprout: return "IllustCelebrationPoster"
            case .starryNight: return "IllustCelebrationStarry"
            case .blossomWreath: return "IllustCelebrationBlossom"
            case .classicAstro: return "IllustCelebrationClassic"
            }
        }

        var canvasBaseColor: Color {
            switch self {
            case .morningSprout: return Color(hex: 0xFAF6ED)
            case .starryNight: return Color(hex: 0x1A3630)
            case .blossomWreath: return Color(hex: 0xFDF8F2)
            case .classicAstro: return Color(hex: 0x006766)
            }
        }

        var inkPrimary: Color {
            switch self {
            case .morningSprout: return Color(hex: 0x1D4231)
            case .starryNight: return Color(hex: 0xFBF6E8)
            case .blossomWreath: return Color(hex: 0x4A2B20)
            case .classicAstro: return Color(hex: 0xFDF6E7)
            }
        }

        var inkSecondary: Color {
            switch self {
            case .morningSprout: return Color(hex: 0x4C6B5B)
            case .starryNight: return Color(hex: 0xE6D7B3)
            case .blossomWreath: return Color(hex: 0x7E5747)
            case .classicAstro: return Color(hex: 0xF5D28C)
            }
        }

        var borderColor: Color {
            switch self {
            case .morningSprout: return Color(hex: 0xEFE6D3)
            case .starryNight: return Color(hex: 0xD9C496).opacity(0.42)
            case .blossomWreath: return Color(hex: 0xECD6C8)
            case .classicAstro: return Color(hex: 0xF5D28C).opacity(0.46)
            }
        }

        var buttonAccent: Color {
            switch self {
            case .morningSprout: return Color(hex: 0xD7EBDC)
            case .starryNight: return Color(hex: 0xF3E2BA)
            case .blossomWreath: return Color(hex: 0xF7DDD2)
            case .classicAstro: return Color(hex: 0xF9E4B7)
            }
        }

        var buttonSecondaryAccent: Color {
            switch self {
            case .morningSprout: return Color(hex: 0xC1DFC9)
            case .starryNight: return Color(hex: 0xE5CD96)
            case .blossomWreath: return Color(hex: 0xEFC8B7)
            case .classicAstro: return Color(hex: 0xEBC57A)
            }
        }

        var buttonBorder: Color {
            switch self {
            case .morningSprout: return Color(hex: 0xA8CEB2).opacity(0.78)
            case .starryNight: return Color(hex: 0xF5E7C6).opacity(0.85)
            case .blossomWreath: return Color(hex: 0xE4B29D).opacity(0.82)
            case .classicAstro: return Color(hex: 0xFFF2D4).opacity(0.88)
            }
        }

        var buttonTextColor: Color {
            switch self {
            case .morningSprout: return Color(hex: 0x1D4432)
            case .starryNight: return Color(hex: 0x193630)
            case .blossomWreath: return Color(hex: 0x4A2B20)
            case .classicAstro: return Color(hex: 0x005251)
            }
        }
    }

    private var cardStyle: CelebrationCardStyle {
        let styles = CelebrationCardStyle.allCases
        if !appState.isCelebrationRandomStyle,
           let fixed = CelebrationCardStyle(rawValue: appState.fixedCelebrationStyleIndex) {
            return fixed
        }
        return styles[abs(payload.id) % styles.count]
    }

    private var socialPersonaTitle: String {
        CelebrationLibrary.computeSocialPersona(
            todayCount: appState.todayShineCount,
            totalCount: appState.shineRecords.count
        )
    }

    private var currentTreeSpeciesName: String {
        let idx = appState.shineRecords.isEmpty ? 0 : (max(0, appState.shineRecords.count - 1) / 100)
        return ForestTreeSpecies.forIndex(idx).displayName
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
                let isClassic = (cardStyle == .classicAstro)
                let cardWidth = min(geo.size.width * (isClassic ? 0.86 : 0.84), isClassic ? 378 : 362)
                let cardHeight = min(geo.size.height * (isClassic ? 0.72 : 0.66), isClassic ? 560 : 520)

                ZStack {
                    posterCardContent(width: cardWidth, height: cardHeight, forExport: false)
                }
                .frame(width: cardWidth, height: cardHeight)
                .scaleEffect(appearScale)
                .opacity(appearOpacity)
                // 破框精灵卡向下微移 22pt 为顶部破框留白；其余卡片物理正中
                .position(x: geo.size.width / 2, y: geo.size.height / 2 + (cardStyle == .morningSprout ? 22 : 0))
            }
        }
        .sheet(item: $sharePosterItem) { item in
            ShareActivitySheet(items: [item.image, item.caption])
        }
        .onAppear {
            currentQuote = payload.quote
            currentJoke = payload.jokeQuote ?? ""
            currentAiQuote = payload.aiQuote ?? ""
            currentFortune = payload.fortuneSlip
            isJokeRevealed = false

            // 每次仅按设置中的概率随机呈现 1 种焦点内容
            spotlightMode = pickWeightedSpotlightMode()

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
        .onChange(of: payload.jokeQuote) { newJoke in
            if let text = newJoke, !text.isEmpty {
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentJoke = text
                    isJokeRevealed = false
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
        let style = cardStyle
        let inkPrimary = style.inkPrimary
        let inkSecondary = style.inkSecondary
        let mascotWidth = min(width * 0.66, 232)

        ZStack(alignment: .top) {
            // 第 1 层：主题底卡
            ZStack {
                style.canvasBaseColor

                if style == .classicAstro {
                    // 经典阿童木卡通舞台：旋转金色放射星芒 + 飞天挥拳插画 + 闪烁星尘 + 柔和渐变过渡
                    let artHeight = height * 0.50
                    VStack(spacing: 0) {
                        ZStack {
                            if forExport {
                                SunburstHaloCanvas(
                                    progress: 0.15,
                                    gold: Color(hex: 0xF7C86A),
                                    peach: Color(hex: 0xF16C52)
                                )
                                Image("IllustCelebrationClassic")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: width * 0.88, height: artHeight * 0.94)
                                    .offset(y: 4)
                                FloatingSparklesCanvas(
                                    progress: 0.25,
                                    gold: Color(hex: 0xFFE38F),
                                    cream: Color(hex: 0xFFF6E0),
                                    peach: Color(hex: 0xFF7B61)
                                )
                            } else {
                                TimelineView(.animation) { timeline in
                                    let elapsed = timeline.date.timeIntervalSinceReferenceDate
                                    let t = (elapsed.truncatingRemainder(dividingBy: 9.0)) / 9.0
                                    let bobY = sin(t * 2 * .pi * 2) * 4.0
                                    let scale = 1.0 + sin(t * 2 * .pi) * 0.018

                                    ZStack {
                                        SunburstHaloCanvas(
                                            progress: t,
                                            gold: Color(hex: 0xF7C86A),
                                            peach: Color(hex: 0xF16C52)
                                        )
                                        Image("IllustCelebrationClassic")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: width * 0.88, height: artHeight * 0.94)
                                            .scaleEffect(scale)
                                            .offset(y: 4 + bobY)
                                        FloatingSparklesCanvas(
                                            progress: t,
                                            gold: Color(hex: 0xFFE38F),
                                            cream: Color(hex: 0xFFF6E0),
                                            peach: Color(hex: 0xFF7B61)
                                        )
                                    }
                                    .frame(width: width, height: artHeight)
                                    .clipped()
                                }
                            }

                            VStack {
                                Spacer()
                                LinearGradient(
                                    stops: [
                                        .init(color: style.canvasBaseColor.opacity(0.0), location: 0.0),
                                        .init(color: style.canvasBaseColor.opacity(0.42), location: 0.50),
                                        .init(color: style.canvasBaseColor, location: 1.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 64)
                            }
                            .allowsHitTesting(false)
                        }
                        .frame(width: width, height: artHeight)
                        .clipped()

                        Spacer(minLength: 0)
                    }
                } else {
                    Image(style.backgroundImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: height)
                        .clipped()
                        .opacity(0.96)

                    if !forExport {
                        TimelineView(.animation) { timeline in
                            let elapsed = timeline.date.timeIntervalSinceReferenceDate
                            let t = (elapsed.truncatingRemainder(dividingBy: 10.0)) / 10.0
                            FloatingSparklesCanvas(
                                progress: t,
                                gold: Color(hex: 0xF5D076),
                                cream: style.canvasBaseColor == Color(hex: 0x1A3630) ? Color(hex: 0xFFF6E0) : Color(hex: 0xFFE8B3),
                                peach: Color(hex: 0xF29E74)
                            )
                            .opacity(0.55)
                        }
                    }
                }

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
                                    .background(style.canvasBaseColor.opacity(0.75))
                                    .overlay(Circle().stroke(style.borderColor.opacity(0.85), lineWidth: 0.8))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(ScaleBounceButtonStyle(scale: 0.90))
                        }
                        .padding(.top, 14)
                        .padding(.trailing, 14)
                        Spacer()
                    }
                    .zIndex(5)
                }

                // 卡片内容区：直接排版在画布之上
                VStack(spacing: 0) {
                    if style == .classicAstro {
                        Spacer(minLength: height * 0.445)
                    } else if style == .morningSprout {
                        Spacer(minLength: forExport ? 114 : 110)
                    } else {
                        Spacer(minLength: style == .blossomWreath ? 54 : 46)
                        // 第 2 / 3 套卡顶部中央精致主题微徽章
                        Image(systemName: style == .starryNight ? "moon.fill" : "leaf.circle.fill")
                            .font(.system(size: style == .starryNight ? 24 : 26, weight: .semibold))
                            .foregroundColor(style == .starryNight ? Color(hex: 0xF5D076) : Color(hex: 0xD97757))
                            .padding(.bottom, 8)
                    }

                    // 趣味人设称号 + 今日步数战绩（社交晒单一眼看懂）
                    HStack(spacing: 6) {
                        Text(socialPersonaTitle)
                        Text("·")
                        HStack(spacing: 2) {
                            Text("今日第")
                            Text("\(appState.todayShineCount)")
                                .contentTransition(.numericText())
                            Text("步")
                        }
                    }
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(inkSecondary)
                    .tracking(0.5)
                    .padding(.horizontal, style == .classicAstro ? 12 : 10)
                    .padding(.vertical, 4)
                    .background(
                        (style == .classicAstro || style == .starryNight)
                            ? Color(hex: 0xFDF6E7).opacity(0.13)
                            : BotanicalTheme.primary.opacity(0.08)
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                (style == .classicAstro || style == .starryNight)
                                    ? Color(hex: 0xF5D28C).opacity(0.38)
                                    : style.borderColor.opacity(0.9),
                                lineWidth: 0.9
                            )
                    )
                    .clipShape(Capsule())

                    // 主标题（完成动作名）
                    Text(payload.actionTitle)
                        .font(.system(size: forExport ? 22.5 : (style == .classicAstro ? 22 : 21.5), weight: .heavy, design: .rounded))
                        .foregroundColor(inkPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, forExport ? 12 : 8)
                        .padding(.horizontal, style == .blossomWreath ? 32 : 22)

                    if forExport {
                        Capsule()
                            .fill(inkSecondary.opacity(0.22))
                            .frame(width: 32, height: 2)
                            .padding(.top, 14)
                    }

                    // 唯一焦点区（无边框融于画布留白，每次只随机呈现 1 种惊喜：夸夸 / 冷笑话轻点揭晓 / 宜忌签）
                    SingleSpotlightContent(
                        mode: spotlightMode,
                        quote: currentQuote.isEmpty ? payload.quote : currentQuote,
                        joke: currentJoke.isEmpty ? (payload.jokeQuote ?? "") : currentJoke,
                        fortune: currentFortune ?? payload.fortuneSlip,
                        isJokeRevealed: isJokeRevealed,
                        isClassic: style == .classicAstro,
                        isDarkSurface: style == .starryNight || style == .classicAstro,
                        inkPrimary: inkPrimary,
                        inkSecondary: inkSecondary,
                        isBlossom: style == .blossomWreath,
                        forExport: forExport,
                        onTap: {
                            handleSpotlightTap()
                        }
                    )
                    .layoutPriority(1)
                    .padding(.horizontal, style == .classicAstro ? 20 : 0)
                    .padding(.top, forExport ? 10 : (style == .classicAstro ? 10 : 6))

                    Spacer(minLength: forExport ? 14 : 8)

                    if let tip = inlineTip, !forExport {
                        Text(tip)
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor((style == .classicAstro || style == .starryNight) ? Color(hex: 0xFFE38F) : BotanicalTheme.primary)
                            .padding(.bottom, 5)
                            .transition(.opacity)
                    }

                    if forExport {
                        ExportSocialFooter(
                            treeName: currentTreeSpeciesName,
                            totalShineCount: appState.shineRecords.count,
                            inkPrimary: inkPrimary,
                            inkSecondary: inkSecondary,
                            borderColor: style.borderColor,
                            isDarkSurface: style == .starryNight || style == .classicAstro
                        )
                        .padding(.horizontal, style == .blossomWreath ? 26 : 20)
                        .padding(.bottom, 20)
                    } else {
                        // 福格微庆祝动作同步指引（黄金视线区 + 随按住震动进度流光蓄满共振）
                        let ritualPrompt = appState.pickCelebrationRitual(seed: payload.id)
                        RitualResonanceBanner(
                            prompt: ritualPrompt,
                            isCharging: isChargingGlow,
                            chargeProgress: chargeProgress,
                            isDarkSurface: style == .classicAstro || style == .starryNight,
                            inkPrimary: inkPrimary,
                            borderColor: style.borderColor
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)

                        // 主交互按钮：68pt 脉冲能量光环（按住 0.75s 水波涟漪共振 + 上方动作文字中心辐射发光）
                        ChargeToShineButton(
                            label: "按住发光",
                            chargingLabel: "正在共振...",
                            completedLabel: "已发光",
                            allowQuickTapClose: false,
                            accentColor: style.buttonAccent,
                            secondaryAccentColor: style.buttonSecondaryAccent,
                            borderColor: style.buttonBorder,
                            textColor: style.buttonTextColor,
                            chargingTextColor: Color(hex: 0x5C3A08),
                            onChargeTick: { p in
                                SensoryFeedbackService.shared.chargeTick(progress: p)
                                chargeProgress = max(0, min(1, p))
                                if !isChargingGlow {
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                                        isChargingGlow = true
                                    }
                                }
                            },
                            onCharged: {
                                isChargingGlow = false
                                chargeProgress = 1.0
                                withAnimation(.spring(response: 0.26, dampingFraction: 0.48)) {
                                    mascotScale = 1.14
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                    withAnimation(.spring(response: 0.34, dampingFraction: 0.65)) {
                                        mascotScale = 1.0
                                    }
                                }
                                SensoryFeedbackService.shared.celebrateGrand(
                                    soundEnabled: appState.soundEnabled,
                                    soundPack: appState.soundPack
                                )
                                innerBurstId += 1
                                UIPasteboard.general.string = combinedCopyText
                                if let onChargedDismiss {
                                    onChargedDismiss()
                                } else {
                                    onDismiss()
                                }
                            },
                            onPressEnd: {
                                withAnimation(.easeOut(duration: 0.22)) {
                                    isChargingGlow = false
                                    chargeProgress = 0
                                }
                            },
                            onShortPressHint: {
                                SensoryFeedbackService.shared.selection()
                                showTip("长按下方能量球，配合上面动作感受发光")
                            },
                            useOrbPulse: true
                        )
                        .frame(width: 120)

                        // 极简辅助操作（融合在水彩纸底上的半透明轻文字：换一个 · 存海报 · 分享海报）
                        HStack(spacing: 14) {
                            Button {
                                handleSwitchSpotlight()
                            } label: {
                                HStack(spacing: 4) {
                                    if isSwitchingSpotlight {
                                        ProgressView()
                                            .tint(inkSecondary)
                                            .scaleEffect(0.68)
                                    } else {
                                        FeatherStarPenIcon()
                                            .stroke(inkSecondary, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
                                            .frame(width: 11.5, height: 11.5)
                                    }
                                    Text("换一个")
                                        .font(.system(size: 11.5, weight: .semibold))
                                        .foregroundColor(inkSecondary)
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                            }
                            .buttonStyle(ScaleBounceButtonStyle(scale: 0.94))
                            .disabled(isSwitchingSpotlight)

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
                                .padding(.horizontal, 8)
                            }
                            .buttonStyle(ScaleBounceButtonStyle(scale: 0.94))
                            .disabled(isSavingPoster || isPreparingShare)

                            Button {
                                sharePosterToSystem(width: width, height: height)
                            } label: {
                                HStack(spacing: 4) {
                                    if isPreparingShare {
                                        ProgressView()
                                            .tint(inkSecondary)
                                            .scaleEffect(0.68)
                                    } else {
                                        SharePlaneIcon()
                                            .stroke(inkSecondary, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
                                            .frame(width: 11.5, height: 11.5)
                                    }
                                    Text(isPreparingShare ? "生成中" : "分享海报")
                                        .font(.system(size: 11.5, weight: .semibold))
                                        .foregroundColor(inkSecondary)
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                            }
                            .buttonStyle(ScaleBounceButtonStyle(scale: 0.94))
                            .disabled(isSavingPoster || isPreparingShare)
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
                    .stroke(style.borderColor, lineWidth: 1.2)
            )
            .shadow(color: Color.black.opacity(0.24), radius: 34, y: 18)

            // 第 2 层：仅晨光精灵卡展示物理破框小新芽精灵贴纸
            if style == .morningSprout {
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
        }
        // 为导出图保留顶部破框安全边距，避免导出截图头部被裁切
        .padding(.top, (forExport && style == .morningSprout) ? 68 : 0)
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

    private func handleSpotlightTap() {
        switch spotlightMode {
        case .praise:
            let active = currentQuote.isEmpty ? payload.quote : currentQuote
            guard !active.isEmpty else { return }
            UIPasteboard.general.string = active
            SensoryFeedbackService.shared.lightTap()
            showTip("已复制这句鼓励")
        case .joke:
            let active = currentJoke.isEmpty ? (payload.jokeQuote ?? "") : currentJoke
            guard !active.isEmpty else { return }
            UIPasteboard.general.string = active
            SensoryFeedbackService.shared.lightTap()
            showTip("已复制冷笑话 ❄️")
        case .fortune:
            if let f = currentFortune ?? payload.fortuneSlip {
                UIPasteboard.general.string = "【\(f.rarity.badgeText) \(f.signTitle)】宜：\(f.yiText) · 忌：\(f.jiText)"
                SensoryFeedbackService.shared.lightTap()
                showTip("已复制今日幸运签 🎋")
            }
        }
    }

    private func pickWeightedSpotlightMode() -> SpotlightMode {
        let r = max(0, appState.rainbowRatio)
        let f = max(0, appState.fortuneRatio)
        let j = max(0, appState.coldJokeRatio)
        let total = r + f + j
        if total <= 0 { return .praise }
        let roll = Int.random(in: 0..<total)
        if roll < r {
            return .praise
        } else if roll < r + f {
            return .fortune
        } else {
            return .joke
        }
    }

    private func handleSwitchSpotlight() {
        guard !isSwitchingSpotlight else { return }
        isSwitchingSpotlight = true
        let nextMode = pickWeightedSpotlightMode()
        Task {
            switch nextMode {
            case .praise:
                let nextQuote = await appState.pickNextRainbowQuote()
                await MainActor.run {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.76)) {
                        spotlightMode = .praise
                        currentQuote = nextQuote
                    }
                    innerBurstId += 1
                    SensoryFeedbackService.shared.selection()
                    isSwitchingSpotlight = false
                }
            case .joke:
                let nextJoke = await appState.pickNextColdJokeQuote()
                await MainActor.run {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.76)) {
                        spotlightMode = .joke
                        currentJoke = nextJoke
                        isJokeRevealed = false
                    }
                    innerBurstId += 1
                    SensoryFeedbackService.shared.selection()
                    isSwitchingSpotlight = false
                }
            case .fortune:
                let currentId = (currentFortune ?? payload.fortuneSlip)?.id
                let nextFortune = CelebrationLibrary.fortuneSlips
                    .filter { $0.id != currentId }
                    .randomElement() ?? CelebrationLibrary.fortuneSlips[0]
                await MainActor.run {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.76)) {
                        spotlightMode = .fortune
                        currentFortune = nextFortune
                    }
                    innerBurstId += 1
                    SensoryFeedbackService.shared.selection()
                    isSwitchingSpotlight = false
                }
            }
        }
    }

    @MainActor
    private func renderPosterImage(width: CGFloat, height: CGFloat) -> UIImage? {
        let style = cardStyle
        let exportCardW: CGFloat = 356
        let exportCardH: CGFloat = (style == .classicAstro) ? 476 : 426
        let topPad: CGFloat = (style == .morningSprout) ? 74 : 26
        let sidePad: CGFloat = 24
        let bottomPad: CGFloat = 26

        let backdropColors: [Color] = {
            switch style {
            case .morningSprout:
                return [Color(hex: 0xE7F1EA), Color(hex: 0xF5EFE2)]
            case .starryNight:
                return [Color(hex: 0x10231F), Color(hex: 0x1E3D36)]
            case .blossomWreath:
                return [Color(hex: 0xF7EBE6), Color(hex: 0xFBF4EC)]
            case .classicAstro:
                return [Color(hex: 0x004B4A), Color(hex: 0x0A7876)]
            }
        }()

        let exportView = ZStack {
            LinearGradient(
                colors: backdropColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            posterCardContent(width: exportCardW, height: exportCardH, forExport: true)
                .frame(width: exportCardW, height: exportCardH)
                .padding(.top, topPad)
                .padding(.bottom, bottomPad)
                .padding(.horizontal, sidePad)
        }
        .frame(
            width: exportCardW + sidePad * 2,
            height: exportCardH + topPad + bottomPad
        )
        .environmentObject(appState)
        .environmentObject(proStore)

        let renderer = ImageRenderer(content: exportView)
        renderer.scale = 3.0
        return renderer.uiImage
    }

    @MainActor
    private func savePosterToPhotos(width: CGFloat, height: CGFloat) {
        isSavingPoster = true
        if let uiImage = renderPosterImage(width: width, height: height) {
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

    @MainActor
    private func sharePosterToSystem(width: CGFloat, height: CGFloat) {
        isPreparingShare = true
        if let uiImage = renderPosterImage(width: width, height: height) {
            SensoryFeedbackService.shared.lightTap()
            let caption = "刚完成「\(payload.actionTitle)」，喜提「\(socialPersonaTitle)」称号（今日第 \(appState.todayShineCount) 步）#微步MicroAction"
            sharePosterItem = SharePosterItem(image: uiImage, caption: caption)
        } else {
            showTip("海报生成失败，请重试")
        }
        isPreparingShare = false
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

                let dot = Path(ellipseIn: CGRect(x: x - r * 0.55, y: y - r * 0.55, width: r * 1.1, height: r * 1.1))
                context.fill(dot, with: .color(color))
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

/// 定制纸飞机分享矢量图标
private struct SharePlaneIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.move(to: CGPoint(x: w * 0.10, y: h * 0.48))
        p.addLine(to: CGPoint(x: w * 0.90, y: h * 0.14))
        p.addLine(to: CGPoint(x: w * 0.60, y: h * 0.88))
        p.addLine(to: CGPoint(x: w * 0.44, y: h * 0.56))
        p.closeSubpath()
        p.move(to: CGPoint(x: w * 0.44, y: h * 0.56))
        p.addLine(to: CGPoint(x: w * 0.90, y: h * 0.14))
        return p
    }
}

private struct SharePosterItem: Identifiable {
    let id = UUID()
    let image: UIImage
    let caption: String
}

/// iOS 原生分享面板封装（一键直发微信/小红书/朋友圈/相册）
private struct ShareActivitySheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// 庆祝页唯一焦点模式（每次只展示其中 1 种，彻底避免多卡片堆砌）
private enum SpotlightMode: CaseIterable {
    case praise
    case joke
    case fortune
}

/// 极简呼吸感主内容区：无多余边框盒子，文字直接融于水彩留白之上（classicAstro 保留奶油复古底块）
private struct SingleSpotlightContent: View {
    let mode: SpotlightMode
    let quote: String
    let joke: String
    let fortune: MicroFortuneSlip?
    let isJokeRevealed: Bool
    let isClassic: Bool
    let isDarkSurface: Bool
    let inkPrimary: Color
    let inkSecondary: Color
    let isBlossom: Bool
    let forExport: Bool
    let onTap: () -> Void

    private var textColor: Color {
        if isClassic { return Color(hex: 0x005251) }
        return inkSecondary
    }

    private var highlightColor: Color {
        if isClassic { return Color(hex: 0x005251) }
        return inkPrimary
    }

    var body: some View {
        Button(action: onTap) {
            Group {
                switch mode {
                case .praise:
                    if quote.isEmpty {
                        HStack(spacing: 6) {
                            ProgressView()
                                .tint(textColor)
                                .scaleEffect(0.78)
                            Text("正在准备专属鼓励...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(textColor.opacity(0.82))
                        }
                    } else {
                        Text(quote)
                            .id("praise-\(quote)")
                            .font(.system(size: isClassic ? 15.5 : 15.5, weight: isClassic ? .bold : .medium))
                            .foregroundColor(textColor)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4.5)
                            .lineLimit(5)
                            .minimumScaleFactor(0.78)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                case .joke:
                    if joke.isEmpty {
                        HStack(spacing: 6) {
                            ProgressView()
                                .tint(textColor)
                                .scaleEffect(0.78)
                            Text("正在准备冷笑话...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(textColor.opacity(0.82))
                        }
                    } else {
                        Text(joke)
                            .id("joke-\(joke)")
                            .font(.system(size: 15, weight: isClassic ? .bold : .medium))
                            .foregroundColor(textColor)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4.2)
                            .lineLimit(6)
                            .minimumScaleFactor(0.76)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                case .fortune:
                    if let f = fortune {
                        VStack(spacing: 6) {
                            Text("🎋 \(f.rarity.badgeText) · \(f.signTitle)")
                                .font(.system(size: 13.5, weight: .bold))
                                .foregroundColor(
                                    f.rarity == .ssr
                                        ? (isClassic ? Color(hex: 0xA85800) : Color(hex: 0xD99021))
                                        : highlightColor
                                )

                            Text("宜 \(f.yiText)   ·   忌 \(f.jiText)")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(textColor)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(quote)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(textColor)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, isClassic ? 18 : (isBlossom ? 32 : 24))
            .padding(.vertical, isClassic ? 13 : 10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isClassic ? Color(hex: 0xFBF3E0) : Color.clear)
            )
        }
        .buttonStyle(ScaleBounceButtonStyle(scale: 0.98))
        .disabled(forExport)
    }
}

/// 社交晒单级海报导出底栏（杂志日签日历印章 + 森林成长印记 + 微步署名）
private struct ExportSocialFooter: View {
    let treeName: String
    let totalShineCount: Int
    let inkPrimary: Color
    let inkSecondary: Color
    let borderColor: Color
    let isDarkSurface: Bool

    private var dayText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: Date())
    }

    private var monthText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月"
        return formatter.string(from: Date())
    }

    var body: some View {
        HStack(spacing: 11) {
            // 左侧日历印章
            VStack(spacing: 0) {
                Text(monthText)
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(inkSecondary.opacity(0.85))
                Text(dayText)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(inkPrimary)
                    .lineLimit(1)
            }
            .frame(width: 38, height: 38)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isDarkSurface ? Color.white.opacity(0.10) : Color.white.opacity(0.65))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(borderColor.opacity(0.80), lineWidth: 0.9)
            )

            // 中间森林印记
            VStack(alignment: .leading, spacing: 2.5) {
                HStack(spacing: 4) {
                    Image(systemName: "tree.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(treeName) · 累计 \(totalShineCount) 次发光")
                        .font(.system(size: 11, weight: .bold))
                        .lineLimit(1)
                }
                .foregroundColor(inkPrimary.opacity(0.90))

                Text("把每一件小事，种成心里的森林")
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundColor(inkSecondary.opacity(0.85))
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            // 右侧微步署名
            HStack(spacing: 3.5) {
                FeatherStarPenIcon()
                    .stroke(inkSecondary, style: StrokeStyle(lineWidth: 1.3, lineCap: .round, lineJoin: .round))
                    .frame(width: 10, height: 10)
                Text("微步记")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.6)
            }
            .foregroundColor(inkSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(isDarkSurface ? Color.white.opacity(0.08) : Color.white.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(borderColor.opacity(0.75), lineWidth: 0.9)
        )
    }
}

/// 福格微庆祝动作共振引导条（14.5pt 高亮醒目 + 随按住震动进度从左向右暖金流光蓄满 + 同步放大高频律动）
private struct RitualResonanceBanner: View {
    let prompt: String
    let isCharging: Bool
    let chargeProgress: Double
    let isDarkSurface: Bool
    let inkPrimary: Color
    let borderColor: Color

    private var idleTextColor: Color {
        isDarkSurface ? Color(hex: 0xFBF6E8).opacity(0.80) : inkPrimary.opacity(0.78)
    }

    private var litGradient: LinearGradient {
        LinearGradient(
            colors: isDarkSurface
                ? [Color(hex: 0xFFE38F), Color(hex: 0xFFF9E6), Color(hex: 0xFFD25A)]
                : [Color(hex: 0xB8730E), Color(hex: 0xE29D28), Color(hex: 0x1D5C3F)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func ritualLabel(tracking: CGFloat) -> some View {
        Text(prompt)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .tracking(tracking)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.84)
            .fixedSize(horizontal: false, vertical: true)
    }

    var body: some View {
        let clamped = max(0, min(1, chargeProgress))
        let activeProgress = isCharging ? clamped : (clamped >= 0.99 ? 1.0 : 0.0)
        let scale: CGFloat = isCharging ? (1.02 + clamped * 0.08) : (clamped >= 0.99 ? 1.10 : 1.0)
        let liftY: CGFloat = isCharging ? (-2.0 - clamped * 4.0) : (clamped >= 0.99 ? -6.0 : 0)
        let letterTracking: CGFloat = activeProgress * 1.1

        ZStack {
            // 按住时背后柔和弥散暖金光晕（由中心向四周绽放）
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: 0xFFE38F).opacity(activeProgress > 0.01 ? (0.20 + activeProgress * 0.34) : 0),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 4,
                        endRadius: 112
                    )
                )
                .frame(height: 40)
                .scaleEffect(0.85 + activeProgress * 0.35)
                .blur(radius: 7)
                .allowsHitTesting(false)

            // 底层柔和文案 + 顶层从中心向两侧辐射点亮（告别机械从左向右拉条）
            ritualLabel(tracking: letterTracking)
                .foregroundColor(idleTextColor)
                .overlay {
                    ritualLabel(tracking: letterTracking)
                        .foregroundStyle(litGradient)
                        .mask(
                            GeometryReader { geo in
                                let w = max(1, geo.size.width)
                                let h = max(1, geo.size.height)
                                Capsule()
                                    .frame(
                                        width: max(0, w * 1.08 * activeProgress),
                                        height: h * 1.6
                                    )
                                    .frame(width: w, height: h, alignment: .center)
                            }
                        )
                }
                .shadow(
                    color: isDarkSurface
                        ? Color(hex: 0xFFD86B).opacity(activeProgress * 0.45)
                        : Color(hex: 0xE5A93B).opacity(activeProgress * 0.28),
                    radius: 9,
                    y: 0
                )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .scaleEffect(scale)
        .offset(y: liftY)
        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isCharging)
    }
}
