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

    // 双卡互动状态
    @State private var isJokeRevealed: Bool = false
    @State private var jokeLaughCount: Int = 0
    @State private var jokeHeartBurstId: Int = 0
    @State private var isSwitchingRainbow: Bool = false
    @State private var isSwitchingJoke: Bool = false
    @State private var sharePosterItem: SharePosterItem? = nil

    // 幸运签与森林动物来信印章状态
    @State private var currentFortune: MicroFortuneSlip? = nil
    @State private var currentStamp: ForestStampCard? = nil
    @State private var stampScale: CGFloat = 2.0
    @State private var stampOpacity: Double = 0
    @State private var showStampLetterBubble: Bool = false

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
                let cardWidth = min(geo.size.width * (isClassic ? 0.87 : 0.85), isClassic ? 382 : 368)
                let cardHeight = min(geo.size.height * (isClassic ? 0.80 : 0.75), isClassic ? 636 : 600)

                ZStack {
                    posterCardContent(width: cardWidth, height: cardHeight, forExport: false)
                }
                .frame(width: cardWidth, height: cardHeight)
                .scaleEffect(appearScale)
                .opacity(appearOpacity)
                // 破框精灵卡向下微移 22pt 为顶部破框留白；其余卡片物理正中
                .position(x: geo.size.width / 2, y: geo.size.height / 2 + (cardStyle == .morningSprout ? 22 : 0))
            }

            if showStampLetterBubble, let activeStamp = currentStamp ?? payload.droppedStamp {
                StampLetterOverlay(
                    stamp: activeStamp,
                    isNewlyUnlocked: payload.isStampNewlyUnlocked,
                    onClose: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showStampLetterBubble = false
                        }
                    }
                )
                .ignoresSafeArea()
                .transition(.opacity.combined(with: .scale(scale: 0.92)))
                .zIndex(20)
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
            currentStamp = payload.droppedStamp
            isJokeRevealed = false
            jokeLaughCount = 0
            stampScale = 2.0
            stampOpacity = 0

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
            // 4. 左上角复古印章啪嗒落印
            withAnimation(.spring(response: 0.36, dampingFraction: 0.62).delay(0.28)) {
                stampScale = 1.0
                stampOpacity = 1.0
            }
            // 5. 精灵持续轻柔呼吸浮沉
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
                    jokeLaughCount = 0
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

                // 顶部四角层：左上角复古动物邮戳印章（交互与导出图均保留）+ 右上角关闭按钮（导出图隐藏）
                VStack {
                    HStack(alignment: .top) {
                        if let stamp = currentStamp ?? payload.droppedStamp {
                            Button {
                                guard !forExport else { return }
                                SensoryFeedbackService.shared.lightTap()
                                withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                                    showStampLetterBubble = true
                                }
                            } label: {
                                ForestStampSealBadge(
                                    stamp: stamp,
                                    isNewlyUnlocked: payload.isStampNewlyUnlocked,
                                    isDarkSurface: style == .starryNight || style == .classicAstro,
                                    forExport: forExport
                                )
                                .scaleEffect(forExport ? 1.0 : stampScale)
                                .opacity(forExport ? 1.0 : stampOpacity)
                            }
                            .buttonStyle(ScaleBounceButtonStyle(scale: 0.92))
                            .disabled(forExport)
                        }

                        Spacer()

                        if !forExport {
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
                    }
                    .padding(.top, 14)
                    .padding(.horizontal, 14)
                    Spacer()
                }
                .zIndex(5)

                // 卡片内容区：直接排版在画布之上
                VStack(spacing: 0) {
                    if style == .classicAstro {
                        Spacer(minLength: height * 0.445)
                    } else if style == .morningSprout {
                        Spacer(minLength: forExport ? 114 : 110)
                    } else {
                        Spacer(minLength: style == .blossomWreath ? 54 : 46)
                        // 第 2 / 3 套卡顶部中央精致主题微徽章
                        Image(systemName: style == .starryNight ? "sparkles" : "leaf.circle.fill")
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
                        .font(.system(size: style == .classicAstro ? 20.5 : 20, weight: .heavy, design: .rounded))
                        .foregroundColor(inkPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 7)
                        .padding(.horizontal, style == .blossomWreath ? 30 : 22)

                    // 双卡互动区 1：彩虹屁（抽签动画换一条 + 一键复制）
                    let activeQuote = currentQuote.isEmpty ? payload.quote : currentQuote
                    RainbowPraiseCard(
                        quote: activeQuote,
                        isClassic: style == .classicAstro,
                        isDarkSurface: style == .starryNight || style == .classicAstro,
                        inkPrimary: inkPrimary,
                        inkSecondary: inkSecondary,
                        borderColor: style.borderColor,
                        isSwitching: isSwitchingRainbow,
                        forExport: forExport,
                        onCopy: {
                            guard !activeQuote.isEmpty else { return }
                            UIPasteboard.general.string = activeQuote
                            SensoryFeedbackService.shared.lightTap()
                            showTip("已复制夸夸金句 ✨")
                        },
                        onSwitch: {
                            handleSwitchRainbowQuote()
                        }
                    )
                    .padding(.horizontal, style == .blossomWreath ? 24 : 18)
                    .padding(.top, style == .classicAstro ? 8 : 7)

                    // 双卡互动区 2：冷笑话（先出问句，轻点翻牌揭晓梗底 + 好笑点赞飘心）
                    let activeJoke = currentJoke.isEmpty ? (payload.jokeQuote ?? "") : currentJoke
                    if !activeJoke.isEmpty {
                        ColdJokeFlipCard(
                            rawJoke: activeJoke,
                            isRevealed: forExport ? true : isJokeRevealed,
                            laughCount: jokeLaughCount,
                            heartBurstId: jokeHeartBurstId,
                            isSwitching: isSwitchingJoke,
                            isClassic: style == .classicAstro,
                            isDarkSurface: style == .starryNight || style == .classicAstro,
                            inkPrimary: inkPrimary,
                            inkSecondary: inkSecondary,
                            borderColor: style.borderColor,
                            forExport: forExport,
                            onFlipReveal: {
                                withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
                                    isJokeRevealed.toggle()
                                }
                                SensoryFeedbackService.shared.lightTap()
                            },
                            onLaughTap: {
                                jokeLaughCount += 1
                                jokeHeartBurstId += 1
                                SensoryFeedbackService.shared.lightTap()
                            },
                            onSwitchJoke: {
                                handleSwitchColdJoke()
                            }
                        )
                        .padding(.horizontal, style == .blossomWreath ? 24 : 18)
                        .padding(.top, 7)
                    }

                    // 幸运签条：微步宜忌（支持轻点重抽）
                    if let activeFortune = currentFortune ?? payload.fortuneSlip {
                        FortuneSlipStrip(
                            fortune: activeFortune,
                            isDarkSurface: style == .starryNight || style == .classicAstro,
                            inkPrimary: inkPrimary,
                            inkSecondary: inkSecondary,
                            borderColor: style.borderColor,
                            forExport: forExport,
                            onRedraw: {
                                let next = CelebrationLibrary.fortuneSlips
                                    .filter { $0.id != activeFortune.id }
                                    .randomElement() ?? CelebrationLibrary.fortuneSlips[0]
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.74)) {
                                    currentFortune = next
                                }
                                SensoryFeedbackService.shared.selection()
                            }
                        )
                        .padding(.horizontal, style == .blossomWreath ? 24 : 18)
                        .padding(.top, 7)
                    }

                    Spacer(minLength: 6)

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
                            inkSecondary: inkSecondary,
                            borderColor: style.borderColor,
                            isDarkSurface: style == .starryNight || style == .classicAstro
                        )
                        .padding(.horizontal, style == .blossomWreath ? 26 : 20)
                        .padding(.bottom, 18)
                    } else {
                        // 福格微庆祝动作同步指引（按住上弦时微微放大共振）
                        let ritualPrompt = appState.pickCelebrationRitual(seed: payload.id)
                        Text(ritualPrompt)
                            .font(.system(size: 12, weight: isChargingGlow ? .bold : .semibold))
                            .foregroundColor(
                                isChargingGlow
                                    ? ((style == .classicAstro || style == .starryNight) ? Color(hex: 0xFFE38F) : BotanicalTheme.primaryDark)
                                    : inkSecondary
                            )
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(
                                        (style == .classicAstro || style == .starryNight)
                                            ? Color.white.opacity(isChargingGlow ? 0.18 : 0.09)
                                            : BotanicalTheme.primary.opacity(isChargingGlow ? 0.14 : 0.07)
                                    )
                            )
                            .scaleEffect(isChargingGlow ? 1.04 : 1.0)
                            .animation(.spring(response: 0.25, dampingFraction: 0.72), value: isChargingGlow)
                            .padding(.horizontal, 18)
                            .padding(.bottom, 8)

                        // 主交互按钮：必须按住 0.6s 上弦收下，把“按住+做动作”练成条件反射（右上角×仍可随时关闭）
                        ChargeToShineButton(
                            label: "按住庆祝",
                            chargingLabel: "感受此刻发光...",
                            completedLabel: "已发光",
                            allowQuickTapClose: false,
                            accentColor: style.buttonAccent,
                            secondaryAccentColor: style.buttonSecondaryAccent,
                            borderColor: style.buttonBorder,
                            textColor: style.buttonTextColor,
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
                                UIPasteboard.general.string = combinedCopyText
                                if let onChargedDismiss {
                                    onChargedDismiss()
                                } else {
                                    onDismiss()
                                }
                            },
                            onPressEnd: {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    isChargingGlow = false
                                }
                            },
                            onShortPressHint: {
                                SensoryFeedbackService.shared.selection()
                                showTip("按住 0.6 秒上弦，配合上面动作感受发光 ✨")
                            }
                        )
                        .frame(width: min(width * 0.64, 228))

                        // 极简辅助操作：存海报 & 一键社交分享（微信/小红书/系统分享）
                        HStack(spacing: 16) {
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
                                .padding(.horizontal, 12)
                                .background(
                                    Capsule()
                                        .fill(
                                            (style == .classicAstro || style == .starryNight)
                                                ? Color.white.opacity(0.08)
                                                : BotanicalTheme.primary.opacity(0.06)
                                        )
                                )
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
                                .padding(.horizontal, 12)
                                .background(
                                    Capsule()
                                        .fill(
                                            (style == .classicAstro || style == .starryNight)
                                                ? Color.white.opacity(0.12)
                                                : BotanicalTheme.primary.opacity(0.09)
                                        )
                                )
                            }
                            .buttonStyle(ScaleBounceButtonStyle(scale: 0.94))
                            .disabled(isSavingPoster || isPreparingShare)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 14)
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

    private func handleSwitchRainbowQuote() {
        guard !isSwitchingRainbow else { return }
        isSwitchingRainbow = true
        Task {
            let nextQuote = await appState.pickNextRainbowQuote()
            await MainActor.run {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.72)) {
                    currentQuote = nextQuote
                }
                innerBurstId += 1
                SensoryFeedbackService.shared.selection()
                isSwitchingRainbow = false
            }
        }
    }

    private func handleSwitchColdJoke() {
        guard !isSwitchingJoke else { return }
        isSwitchingJoke = true
        Task {
            let nextJoke = await appState.pickNextColdJokeQuote()
            await MainActor.run {
                withAnimation(.spring(response: 0.36, dampingFraction: 0.76)) {
                    currentJoke = nextJoke
                    isJokeRevealed = false
                    jokeLaughCount = 0
                }
                SensoryFeedbackService.shared.selection()
                isSwitchingJoke = false
            }
        }
    }

    @MainActor
    private func renderPosterImage(width: CGFloat, height: CGFloat) -> UIImage? {
        let exportView = posterCardContent(width: width, height: height, forExport: true)
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
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
            let caption = "刚完成「\(payload.actionTitle)」，喜提「\(socialPersonaTitle)」称号（今日第 \(appState.todayShineCount) 步）✨ #微步MicroAction"
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

/// 双卡互动区 1：彩虹屁抽签 & 复制卡
private struct RainbowPraiseCard: View {
    let quote: String
    let isClassic: Bool
    let isDarkSurface: Bool
    let inkPrimary: Color
    let inkSecondary: Color
    let borderColor: Color
    let isSwitching: Bool
    let forExport: Bool
    let onCopy: () -> Void
    let onSwitch: () -> Void

    private var cardBg: Color {
        if isClassic { return Color(hex: 0xFBF3E0) }
        return isDarkSurface ? Color.white.opacity(0.08) : Color.white.opacity(0.55)
    }

    private var textInk: Color {
        if isClassic { return Color(hex: 0x005251) }
        return isDarkSurface ? Color(hex: 0xFBF6E8) : inkPrimary
    }

    private var subInk: Color {
        if isClassic { return Color(hex: 0x005251).opacity(0.68) }
        return inkSecondary
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Text("✨ 嘴甜夸夸")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(subInk)

                Spacer()

                if !forExport {
                    Button(action: onSwitch) {
                        HStack(spacing: 3) {
                            Image(systemName: "dice")
                                .font(.system(size: 10, weight: .semibold))
                            Text("换一条")
                                .font(.system(size: 10.5, weight: .semibold))
                        }
                        .foregroundColor(subInk)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(isClassic ? Color(hex: 0x005251).opacity(0.09) : Color.primary.opacity(0.06))
                        )
                    }
                    .buttonStyle(ScaleBounceButtonStyle(scale: 0.92))
                    .disabled(isSwitching)

                    Button(action: onCopy) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(subInk)
                            .padding(5)
                            .background(
                                Circle()
                                    .fill(isClassic ? Color(hex: 0x005251).opacity(0.09) : Color.primary.opacity(0.06))
                            )
                    }
                    .buttonStyle(ScaleBounceButtonStyle(scale: 0.90))
                }
            }

            if quote.isEmpty {
                HStack(spacing: 6) {
                    ProgressView()
                        .tint(subInk)
                        .scaleEffect(0.75)
                    Text("正在准备专属鼓励...")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(subInk)
                }
                .padding(.vertical, 4)
            } else {
                Text(quote)
                    .id(quote)
                    .font(.system(size: isClassic ? 14.5 : 14, weight: isClassic ? .bold : .medium))
                    .foregroundColor(textInk)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3.5)
                    .lineLimit(3)
                    .minimumScaleFactor(0.78)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.94)),
                        removal: .opacity
                    ))
                    .onTapGesture {
                        if !forExport { onCopy() }
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isClassic ? Color.clear : borderColor.opacity(0.72), lineWidth: 0.9)
        )
    }
}

/// 双卡互动区 2：冷笑话（先出问句、轻点翻牌揭晓梗底 + 好笑点赞飘心）
private struct ColdJokeFlipCard: View {
    let rawJoke: String
    let isRevealed: Bool
    let laughCount: Int
    let heartBurstId: Int
    let isSwitching: Bool
    let isClassic: Bool
    let isDarkSurface: Bool
    let inkPrimary: Color
    let inkSecondary: Color
    let borderColor: Color
    let forExport: Bool
    let onFlipReveal: () -> Void
    let onLaughTap: () -> Void
    let onSwitchJoke: () -> Void

    private var split: (setup: String, punchline: String?) {
        CelebrationLibrary.splitColdJoke(rawJoke)
    }

    private var cardBg: Color {
        if isClassic { return Color(hex: 0x004B4A).opacity(0.65) }
        return isDarkSurface ? Color.white.opacity(0.06) : Color.white.opacity(0.42)
    }

    private var accentPillBg: Color {
        isDarkSurface ? Color(hex: 0xFFE38F).opacity(0.18) : BotanicalTheme.primary.opacity(0.12)
    }

    private var accentText: Color {
        isDarkSurface ? Color(hex: 0xFFE38F) : BotanicalTheme.primaryDark
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text("❄️ 今日冷笑话")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundColor(inkSecondary)

                    Spacer()

                    if !forExport {
                        if isRevealed {
                            Button(action: onLaughTap) {
                                HStack(spacing: 3) {
                                    Text("😂")
                                        .font(.system(size: 10.5))
                                    Text(laughCount > 0 ? "+\(laughCount)" : "好笑")
                                        .font(.system(size: 10.5, weight: .bold))
                                        .contentTransition(.numericText())
                                }
                                .foregroundColor(accentText)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(accentPillBg))
                            }
                            .buttonStyle(ScaleBounceButtonStyle(scale: 0.90))

                            Button(action: onSwitchJoke) {
                                Text("换个梗")
                                    .font(.system(size: 10.5, weight: .semibold))
                                    .foregroundColor(inkSecondary)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(isDarkSurface ? Color.white.opacity(0.10) : Color.primary.opacity(0.06))
                                    )
                            }
                            .buttonStyle(ScaleBounceButtonStyle(scale: 0.92))
                            .disabled(isSwitching)
                        } else {
                            Text("轻点揭晓 ↻")
                                .font(.system(size: 10.5, weight: .bold))
                                .foregroundColor(accentText)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(accentPillBg))
                        }
                    }
                }

                Group {
                    if isRevealed {
                        if let punchline = split.punchline {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(split.setup)
                                    .font(.system(size: 11.5, weight: .medium))
                                    .foregroundColor(inkSecondary)
                                    .lineLimit(2)
                                Text(punchline)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(inkPrimary)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.84)
                            }
                        } else {
                            Text(split.setup)
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(inkPrimary)
                                .lineLimit(3)
                                .minimumScaleFactor(0.82)
                        }
                    } else {
                        let previewText = split.punchline != nil
                            ? split.setup
                            : "点击拆开今天的小幽默盲盒，让嘴角上扬一下 🎁"
                        Text(previewText)
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundColor(inkPrimary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(cardBg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(
                        isRevealed ? borderColor.opacity(0.85) : accentText.opacity(0.32),
                        style: StrokeStyle(lineWidth: 0.9, dash: isRevealed ? [] : [4, 3])
                    )
            )
            .rotation3DEffect(.degrees(isRevealed ? 0 : 3), axis: (x: 1, y: 0, z: 0))
            .contentShape(Rectangle())
            .onTapGesture {
                if !forExport {
                    onFlipReveal()
                }
            }

            if !forExport {
                FloatingHeartBurst(burstId: heartBurstId)
                    .allowsHitTesting(false)
            }
        }
    }
}

/// 好笑点赞飘心气泡粒子
private struct FloatingHeartBurst: View {
    let burstId: Int
    @State private var animateOffset: Bool = false
    @State private var isVisible: Bool = false

    var body: some View {
        ZStack {
            if isVisible {
                ForEach(0..<4, id: \.self) { i in
                    Text(i % 2 == 0 ? "💗" : "✨")
                        .font(.system(size: 13))
                        .offset(
                            x: CGFloat((i - 1) * 16) + (animateOffset ? CGFloat((i % 2 == 0 ? -8 : 10)) : 0),
                            y: animateOffset ? -34 - CGFloat(i * 6) : 0
                        )
                        .opacity(animateOffset ? 0 : 1)
                        .scaleEffect(animateOffset ? 1.15 : 0.65)
                }
            }
        }
        .onChange(of: burstId) { newVal in
            guard newVal > 0 else { return }
            animateOffset = false
            isVisible = true
            withAnimation(.easeOut(duration: 0.72)) {
                animateOffset = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                if burstId == newVal {
                    isVisible = false
                }
            }
        }
    }
}

/// 社交晒单级海报导出底栏（群落树印记 + 累计发光次数 + 微步品牌标识）
private struct ExportSocialFooter: View {
    let treeName: String
    let totalShineCount: Int
    let inkSecondary: Color
    let borderColor: Color
    let isDarkSurface: Bool

    private var dateBadge: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        return formatter.string(from: Date())
    }

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "tree.fill")
                    .font(.system(size: 10.5, weight: .semibold))
                Text("\(treeName) · 累计 \(totalShineCount) 次发光")
                    .font(.system(size: 10.5, weight: .semibold))
            }
            .foregroundColor(inkSecondary)

            Spacer()

            HStack(spacing: 4) {
                FeatherStarPenIcon()
                    .stroke(inkSecondary, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
                    .frame(width: 11, height: 11)
                Text("微步 · \(dateBadge)")
                    .font(.system(size: 10.5, weight: .bold))
                    .tracking(0.5)
            }
            .foregroundColor(inkSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isDarkSurface ? Color.white.opacity(0.08) : Color.white.opacity(0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(borderColor.opacity(0.65), lineWidth: 0.8)
        )
    }
}

/// 左上角复古邮戳印章（带有 SSR/SR/R 稀有度与 NEW 首次解锁标）
private struct ForestStampSealBadge: View {
    let stamp: ForestStampCard
    let isNewlyUnlocked: Bool
    let isDarkSurface: Bool
    let forExport: Bool

    private var ringColor: Color {
        switch stamp.rarity {
        case .ssr:
            return Color(hex: 0xE5A93B)
        case .sr:
            return isDarkSurface ? Color(hex: 0x8BE0B5) : BotanicalTheme.primary
        case .r:
            return isDarkSurface ? Color(hex: 0xE6D7B3) : Color(hex: 0xB97A57)
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                Circle()
                    .fill(isDarkSurface ? Color.black.opacity(0.28) : Color(hex: 0xFFFDF8).opacity(0.86))
                    .frame(width: 56, height: 56)

                Circle()
                    .stroke(ringColor.opacity(0.82), style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                    .frame(width: 52, height: 52)

                Circle()
                    .stroke(ringColor.opacity(0.45), lineWidth: 0.8)
                    .frame(width: 44, height: 44)

                VStack(spacing: 1) {
                    Text(stamp.animalEmoji)
                        .font(.system(size: 18))
                    Text(stamp.rarity.badgeText)
                        .font(.system(size: 8.5, weight: .black, design: .rounded))
                        .foregroundColor(ringColor)
                        .tracking(0.6)
                }
            }
            .rotationEffect(.degrees(-12))

            if isNewlyUnlocked && !forExport {
                Text("NEW")
                    .font(.system(size: 7.5, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4.5)
                    .padding(.vertical, 1.5)
                    .background(Capsule().fill(Color(hex: 0xE56B4E)))
                    .offset(x: 4, y: -2)
            }
        }
        .shadow(color: ringColor.opacity(stamp.rarity == .ssr ? 0.34 : 0.16), radius: 6, y: 2)
    }
}

/// 紧凑型微步宜忌幸运签条（支持轻点再抽一签）
private struct FortuneSlipStrip: View {
    let fortune: MicroFortuneSlip
    let isDarkSurface: Bool
    let inkPrimary: Color
    let inkSecondary: Color
    let borderColor: Color
    let forExport: Bool
    let onRedraw: () -> Void

    private var badgeColor: Color {
        switch fortune.rarity {
        case .ssr: return Color(hex: 0xE5A93B)
        case .sr: return isDarkSurface ? Color(hex: 0x8BE0B5) : BotanicalTheme.primary
        case .r: return inkSecondary
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 3) {
                Text(fortune.rarity.badgeText)
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundColor(fortune.rarity == .ssr ? Color(hex: 0x5C3A08) : .white)
                    .padding(.horizontal, 4.5)
                    .padding(.vertical, 1.5)
                    .background(Capsule().fill(badgeColor))

                Text(fortune.signTitle)
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(badgeColor)
            }

            Text("宜:\(fortune.yiText)")
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundColor(inkPrimary)
                .lineLimit(1)

            Text("·")
                .font(.system(size: 10))
                .foregroundColor(inkSecondary)

            Text("忌:\(fortune.jiText)")
                .font(.system(size: 10.5, weight: .medium))
                .foregroundColor(inkSecondary)
                .lineLimit(1)

            if !forExport {
                Spacer(minLength: 2)
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundColor(inkSecondary.opacity(0.85))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(isDarkSurface ? Color.white.opacity(0.08) : Color.white.opacity(0.48))
        )
        .overlay(
            Capsule()
                .stroke(
                    fortune.rarity == .ssr ? Color(hex: 0xE5A93B).opacity(0.55) : borderColor.opacity(0.75),
                    lineWidth: 0.85
                )
        )
        .contentShape(Capsule())
        .onTapGesture {
            if !forExport { onRedraw() }
        }
    }
}

/// 森林动物来信彩蛋浮层（轻点印章弹出）
private struct StampLetterOverlay: View {
    let stamp: ForestStampCard
    let isNewlyUnlocked: Bool
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.32)
                .onTapGesture { onClose() }

            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Text(stamp.animalEmoji)
                        .font(.system(size: 28))
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            Text(stamp.stampName)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(BotanicalTheme.textPrimary)
                            Text(stamp.rarity.badgeText)
                                .font(.system(size: 9.5, weight: .black))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Capsule().fill(stamp.rarity == .ssr ? Color(hex: 0xE5A93B) : BotanicalTheme.primary))
                        }
                        Text("来自 \(stamp.senderName) 的森林来信")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(BotanicalTheme.textSecondary)
                    }
                    Spacer()
                }

                Text("“\(stamp.letterText)”")
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundColor(BotanicalTheme.textPrimary)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Text(isNewlyUnlocked ? "✨ 新解锁！已盖章收录至「我的森林图鉴」" : "📖 已收录至「我的森林图鉴」")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(BotanicalTheme.primaryDark)
                    Spacer()
                    Button("收好啦") {
                        onClose()
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(BotanicalTheme.primary))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(hex: 0xFAF6ED))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color(hex: 0xE5A93B).opacity(0.45), lineWidth: 1.2)
            )
            .shadow(color: Color.black.opacity(0.22), radius: 18, y: 10)
            .padding(.horizontal, 24)
        }
    }
}
