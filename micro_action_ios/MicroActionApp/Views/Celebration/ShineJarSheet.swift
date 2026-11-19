import SwiftUI

/// 发光星籽罐设置与自由庆祝面板
/// 复刻原版 Canvas 真实玻璃星籽罐（轻点整罐星籽跃动 + 金色星沙底衬）与 0.6s 蓄力练习按钮，完整保留 Pro AI人设/皮肤/音效包
struct ShineJarSheet: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var proStore: ProStoreService
    @Environment(\.dismiss) private var dismiss

    @State private var newAffirmation: String = ""
    @State private var bounceStart: Date? = nil
    @State private var bounceToken: Int = 0
    @State private var burstId: Int = 0
    @State private var lastFreeCelebration: CelebrationPayload? = nil

    private var activeTheme: CelebrationThemeSkin {
        appState.themeSkin
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 1. 真实 Canvas 发光星籽玻璃罐（轻触微光跃动）
                        jarHeroCard

                        // 刚完成的自由练习肯定语卡片（可轻点直达全屏庆祝海报）
                        if let freePayload = lastFreeCelebration {
                            Button {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                    appState.activeCelebration = freePayload
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    Text(freePayload.quote)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(BotanicalTheme.textPrimary)
                                        .multilineTextAlignment(.center)
                                    Text("轻点可展开全屏发光海报保存或 AI 再夸我")
                                        .font(.system(size: 11.5, weight: .medium))
                                        .foregroundColor(BotanicalTheme.primaryDark)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(BotanicalTheme.primary.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(BotanicalTheme.primary.opacity(0.18), lineWidth: 1)
                                )
                            }
                            .buttonStyle(ScaleBounceButtonStyle(scale: 0.98))
                        }

                        // 2. 连点 3 下点亮星苞「浇灌微步成长树」互动按钮
                        ChargeToShineButton(
                            label: "连点 3 下点亮星苞 (0/3)",
                            completedLabel: "星花盛放 · 成长值 +1",
                            allowQuickTapClose: false,
                            accentColor: BotanicalTheme.primaryDark,
                            textColor: .white,
                            chargingTextColor: BotanicalTheme.primaryDark,
                            onChargeTick: { p in
                                SensoryFeedbackService.shared.chargeTick(progress: p)
                            },
                            onCharged: {
                                Task {
                                    let payload = await appState.celebrateFreely()
                                    await MainActor.run {
                                        lastFreeCelebration = payload
                                        burstId += 1
                                        triggerJarBounce()
                                    }
                                }
                            }
                        )

                        // 3. 彩虹屁 & 冷笑话自定义比例调节卡
                        ratioControlCard

                        // 4. AI 专属夸夸官四大人设（Pro）
                        aiPersonaCard

                        // 5. 庆祝仪式主题皮肤（4 套）
                        themeSkinCard

                        // 6. 微音效开关与 3 套风格包
                        soundPackCard

                        // 7. 自定义专属庆祝语
                        customAffirmationsCard
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 16)
                }
                .liquidSheetCanvasBackground()

                StarburstParticleLayer(burstId: burstId, isGrand: true)
                    .ignoresSafeArea()
            }
            .navigationTitle("微步成长树")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(BotanicalTheme.primary)
                }
            }
        }
        .liquidGlassSheet(detents: [.large], cornerRadius: 34)
    }

    private var treeGrowthStage: (name: String, nextTarget: Int?) {
        let total = appState.shineRecords.count
        switch total {
        case 0: return ("休眠种子", 1)
        case 1...4: return ("破土嫩芽", 5)
        case 5...14: return ("抽枝幼苗", 15)
        case 15...34: return ("茂密小树", 35)
        case 35...69: return ("繁花绿冠", 70)
        default: return ("森境大树", nil)
        }
    }

    private var jarHeroCard: some View {
        let stage = treeGrowthStage
        return ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            activeTheme.bgColor,
                            activeTheme.bgColor.opacity(0.86)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(BotanicalTheme.primaryLight.opacity(0.32), lineWidth: 1)
                )

            GrowingTreeCanvasView(records: appState.shineRecords, bounceStart: bounceStart)
                .frame(height: 220)

            HStack {
                Text("\(stage.name) · 今日 +\(appState.todayShineCount) / 累计 \(appState.shineRecords.count)")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(activeTheme.goldColor)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background(activeTheme.creamColor.opacity(0.14))
                    .clipShape(Capsule())
                Spacer()
                Text(stage.nextTarget.map { "距下阶段还差 \(max(0, $0 - appState.shineRecords.count)) 步" } ?? "轻触树冠微风轻拂")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(activeTheme.creamColor.opacity(0.80))
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
        }
        .frame(height: 220)
        .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .onTapGesture {
            SensoryFeedbackService.shared.lightTap()
            triggerJarBounce()
        }
    }

    private func triggerJarBounce() {
        bounceToken += 1
        let currentToken = bounceToken
        bounceStart = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.60) {
            if bounceToken == currentToken {
                bounceStart = nil
            }
        }
    }

    private var ratioControlCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("庆祝方式比例（AI / 彩虹屁 / 冷笑话）")
                    .font(.system(size: 14.5, weight: .bold))
                    .foregroundColor(BotanicalTheme.textPrimary)
                Spacer()
                Text("合计 100%")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(BotanicalTheme.textHint)
            }

            // 三色比例分布条
            GeometryReader { geo in
                HStack(spacing: 2) {
                    if appState.aiRatio > 0 {
                        Capsule()
                            .fill(BotanicalTheme.gold)
                            .frame(width: max(8, geo.size.width * CGFloat(appState.aiRatio) / 100.0))
                    }
                    if appState.rainbowRatio > 0 {
                        Capsule()
                            .fill(BotanicalTheme.primary)
                            .frame(width: max(8, geo.size.width * CGFloat(appState.rainbowRatio) / 100.0))
                    }
                    if appState.coldJokeRatio > 0 {
                        Capsule()
                            .fill(BotanicalTheme.warning)
                            .frame(width: max(8, geo.size.width * CGFloat(appState.coldJokeRatio) / 100.0))
                    }
                }
            }
            .frame(height: 8)

            HStack(spacing: 8) {
                ratioQuickChip(
                    title: "AI \(appState.aiRatio)%",
                    selected: appState.aiRatio >= 50
                ) {
                    SensoryFeedbackService.shared.selection()
                    appState.setCelebrationRatios(ai: 100, rainbow: 0)
                }

                ratioQuickChip(
                    title: "彩虹屁 \(appState.rainbowRatio)%",
                    selected: appState.rainbowRatio >= 50 && appState.aiRatio < 50
                ) {
                    SensoryFeedbackService.shared.selection()
                    appState.setCelebrationRatios(ai: 0, rainbow: 100)
                }

                ratioQuickChip(
                    title: "冷笑话 \(appState.coldJokeRatio)%",
                    selected: appState.coldJokeRatio >= 50
                ) {
                    SensoryFeedbackService.shared.selection()
                    appState.setCelebrationRatios(ai: 0, rainbow: 0)
                }
            }

            VStack(spacing: 6) {
                HStack {
                    Text("AI 专属鼓励")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(BotanicalTheme.textSecondary)
                    Spacer()
                    Text("\(appState.aiRatio)%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(BotanicalTheme.gold)
                }
                Slider(
                    value: Binding(
                        get: { Double(appState.aiRatio) },
                        set: {
                            let newAi = Int(($0 / 5.0).rounded() * 5)
                            appState.setCelebrationRatios(ai: newAi, rainbow: appState.rainbowRatio)
                        }
                    ),
                    in: 0...100,
                    step: 5
                )
                .tint(BotanicalTheme.gold)

                HStack {
                    Text("彩虹屁")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(BotanicalTheme.textSecondary)
                    Spacer()
                    Text("\(appState.rainbowRatio)%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(BotanicalTheme.primary)
                }
                Slider(
                    value: Binding(
                        get: { Double(appState.rainbowRatio) },
                        set: {
                            let newRainbow = Int(($0 / 5.0).rounded() * 5)
                            appState.setCelebrationRatios(ai: appState.aiRatio, rainbow: newRainbow)
                        }
                    ),
                    in: 0...Double(max(0, 100 - appState.aiRatio)),
                    step: 5
                )
                .tint(BotanicalTheme.primary)
                .disabled(appState.aiRatio >= 100)

                HStack {
                    Text("冷笑话（自动补足剩余比例）")
                        .font(.system(size: 11.5))
                        .foregroundColor(BotanicalTheme.textHint)
                    Spacer()
                    Text("\(appState.coldJokeRatio)%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(BotanicalTheme.warning)
                }
            }
        }
        .padding(16)
        .background(BotanicalTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(BotanicalTheme.border.opacity(0.75), lineWidth: 1))
    }

    private func ratioQuickChip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(selected ? .white : BotanicalTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(selected ? BotanicalTheme.primary : BotanicalTheme.surfaceMuted)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(selected ? BotanicalTheme.primary : BotanicalTheme.border.opacity(0.7), lineWidth: 1)
                )
        }
        .buttonStyle(ScaleBounceButtonStyle(scale: 0.96))
    }

    private var aiPersonaCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("AI 专属夸夸官人设")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(BotanicalTheme.textPrimary)
                proBadge
                Spacer()
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(AiCelebrationPersona.allCases) { persona in
                    let isSelected = appState.aiPersona == persona
                    Button {
                        SensoryFeedbackService.shared.selection()
                        if !proStore.isPro {
                            appState.showProPaywall = true
                        } else {
                            appState.setAiPersona(persona)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: persona.iconName)
                                .font(.system(size: 13))
                            Text(persona.name)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(isSelected ? .white : BotanicalTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(isSelected ? BotanicalTheme.primary : BotanicalTheme.surfaceMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(ScaleBounceButtonStyle(scale: 0.96))
                }
            }
        }
        .padding(16)
        .background(BotanicalTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(BotanicalTheme.border.opacity(0.75), lineWidth: 1))
    }

    private var themeSkinCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("庆祝仪式主题皮肤")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(BotanicalTheme.textPrimary)
                Spacer()
                Text("影响海报与桌面小组件")
                    .font(.system(size: 11))
                    .foregroundColor(BotanicalTheme.textHint)
            }

            HStack(spacing: 10) {
                ForEach(CelebrationThemeSkin.allCases) { skin in
                    let selected = activeTheme == skin
                    Button {
                        SensoryFeedbackService.shared.selection()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            appState.setThemeSkin(skin)
                        }
                    } label: {
                        VStack(spacing: 6) {
                            ZStack(alignment: .topTrailing) {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [skin.bgColor, skin.bgColor.opacity(0.82)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(height: 48)
                                    .overlay(
                                        HStack(spacing: 4) {
                                            Circle().fill(skin.peachColor).frame(width: 10, height: 10)
                                            Circle().fill(skin.goldColor).frame(width: 10, height: 10)
                                            Circle().fill(skin.accentColor).frame(width: 10, height: 10)
                                        }
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(selected ? BotanicalTheme.primary : Color.white.opacity(0.18), lineWidth: selected ? 2.5 : 1)
                                    )
                                if selected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(skin.goldColor)
                                        .padding(4)
                                }
                            }
                            Text(skin.name)
                                .font(.system(size: 11, weight: selected ? .bold : .medium))
                                .foregroundColor(selected ? BotanicalTheme.primaryDark : BotanicalTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ScaleBounceButtonStyle(scale: 0.95))
                }
            }
        }
        .padding(16)
        .background(BotanicalTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(BotanicalTheme.border.opacity(0.75), lineWidth: 1))
    }

    private var soundPackCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: Binding(
                get: { appState.soundEnabled },
                set: { appState.setSoundEnabled($0) }
            )) {
                Text("庆祝微音效")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(BotanicalTheme.textPrimary)
            }
            .tint(BotanicalTheme.primary)

            if appState.soundEnabled {
                HStack(spacing: 8) {
                    ForEach(CelebrationSoundPack.allCases) { pack in
                        let selected = appState.soundPack == pack
                        Button {
                            if pack.isPro && !proStore.isPro {
                                appState.showProPaywall = true
                            } else {
                                appState.setSoundPack(pack)
                                SensoryFeedbackService.shared.celebrateGrand(soundEnabled: true, soundPack: pack)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(pack.name)
                                    .font(.system(size: 12, weight: .semibold))
                                if pack.isPro && !proStore.isPro {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 9))
                                }
                            }
                            .foregroundColor(selected ? .white : BotanicalTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(selected ? BotanicalTheme.primary : BotanicalTheme.surfaceMuted)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(ScaleBounceButtonStyle(scale: 0.96))
                    }
                }
            }
        }
        .padding(16)
        .background(BotanicalTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(BotanicalTheme.border.opacity(0.75), lineWidth: 1))
    }

    private var customAffirmationsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("专属庆祝语 / 小奖励")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(BotanicalTheme.textPrimary)

            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(BotanicalTheme.primary.opacity(0.8))

                TextField("添加专属庆祝语或小奖励", text: $newAffirmation)
                    .font(.system(size: 13.5))
                    .submitLabel(.done)
                    .onSubmit { submitAffirmation() }

                if !newAffirmation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        submitAffirmation()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 26, height: 26)
                            .background(BotanicalTheme.primary)
                            .clipShape(Circle())
                    }
                    .buttonStyle(ScaleBounceButtonStyle(scale: 0.90))
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 42)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(BotanicalTheme.primary.opacity(0.22), lineWidth: 1)
            )

            if !appState.customAffirmations.isEmpty {
                VStack(spacing: 6) {
                    ForEach(appState.customAffirmations, id: \.self) { item in
                        HStack {
                            Text(item)
                                .font(.system(size: 13.5))
                                .foregroundColor(BotanicalTheme.textPrimary)
                            Spacer()
                            Button {
                                SensoryFeedbackService.shared.selection()
                                appState.removeCustomAffirmation(item)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(BotanicalTheme.textHint)
                                    .padding(4)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(BotanicalTheme.primary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
        }
        .padding(16)
        .background(BotanicalTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(BotanicalTheme.border.opacity(0.75), lineWidth: 1))
    }

    private func submitAffirmation() {
        let trimmed = newAffirmation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        SensoryFeedbackService.shared.selection()
        appState.addCustomAffirmation(trimmed)
        newAffirmation = ""
    }

    private var proBadge: some View {
        Text("PRO")
            .font(.system(size: 10, weight: .heavy))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(BotanicalTheme.accentWarm)
            .clipShape(Capsule())
    }
}

/// 「微步成长树」6 阶段真实生长 Canvas 画布
/// 随累计微步次数真实长大（0 休眠种子 → 1-4 破土嫩芽 → 5-14 抽枝幼苗 → 15-34 茂密小树 → 35-69 繁花绿冠 → 70+ 森境大树），轻触树冠可触发微风轻拂摇曳与花叶光点
private struct GrowingTreeCanvasView: View {
    let records: [ShineRecord]
    let bounceStart: Date?

    private var totalCount: Int { records.count }

    private var stageLevel: Int {
        switch totalCount {
        case 0: return 0
        case 1...4: return 1
        case 5...14: return 2
        case 15...34: return 3
        case 35...69: return 4
        default: return 5
        }
    }

    var body: some View {
        TimelineView(.animation(paused: bounceStart == nil)) { timeline in
            let swayProgress: Double = {
                guard let start = bounceStart else { return 0 }
                let elapsed = timeline.date.timeIntervalSince(start)
                if elapsed < 0 || elapsed >= 0.60 { return 0 }
                return elapsed / 0.60
            }()

            Canvas { context, size in
                let cx = size.width * 0.5
                let groundY = size.height - 26.0
                let sway = sin(swayProgress * .pi * 2.5) * exp(-swayProgress * 2.4) * 7.0

                // 1. 树后柔光晨曦圆晕
                let sunCenter = CGPoint(x: cx - 38, y: groundY - 88)
                let sunR: CGFloat = 54
                context.fill(
                    Path(ellipseIn: CGRect(x: sunCenter.x - sunR, y: sunCenter.y - sunR, width: sunR * 2, height: sunR * 2)),
                    with: .radialGradient(
                        Gradient(colors: [
                            Color(hex: 0xFFE08A).opacity(0.28),
                            Color(hex: 0x74C69D).opacity(0.10),
                            .clear
                        ]),
                        center: sunCenter,
                        startRadius: 2,
                        endRadius: sunR
                    )
                )

                // 2. 底部翡翠青苔微坡
                var hill = Path()
                hill.move(to: CGPoint(x: cx - 96, y: groundY + 12))
                hill.addQuadCurve(
                    to: CGPoint(x: cx + 96, y: groundY + 12),
                    control: CGPoint(x: cx, y: groundY - 22)
                )
                hill.closeSubpath()
                context.fill(
                    hill,
                    with: .linearGradient(
                        Gradient(colors: [Color(hex: 0x52B788).opacity(0.45), Color(hex: 0x1B4332).opacity(0.75)]),
                        startPoint: CGPoint(x: cx, y: groundY - 12),
                        endPoint: CGPoint(x: cx, y: groundY + 14)
                    )
                )

                // 坡前 3 块微步小踏石
                let stones: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
                    (-36, 4, 14, 5.5),
                    (-18, 1, 12, 4.8),
                    (-4, -2, 10, 4.2)
                ]
                for s in stones {
                    let rect = CGRect(x: cx + s.0 - s.2 / 2, y: groundY + s.1 - s.3 / 2, width: s.2, height: s.3)
                    context.fill(Path(ellipseIn: rect), with: .color(Color(hex: 0xFAF6EC).opacity(0.78)))
                }

                // 3. 按成长阶段绘制种子 / 嫩芽 / 幼苗 / 茂密小树 / 繁花大树
                if stageLevel == 0 {
                    // 阶段 0：静待发芽的翡翠种子
                    let seedRect = CGRect(x: cx - 10, y: groundY - 14 + CGFloat(sway * 0.25), width: 20, height: 15)
                    context.fill(
                        Path(ellipseIn: seedRect),
                        with: .linearGradient(
                            Gradient(colors: [Color(hex: 0xB7E4C7), Color(hex: 0x40916C)]),
                            startPoint: CGPoint(x: seedRect.minX, y: seedRect.minY),
                            endPoint: CGPoint(x: seedRect.maxX, y: seedRect.maxY)
                        )
                    )
                    context.stroke(Path(ellipseIn: seedRect), with: .color(Color.white.opacity(0.45)), lineWidth: 1)
                } else if stageLevel == 1 {
                    // 阶段 1：破土嫩芽
                    var stem = Path()
                    stem.move(to: CGPoint(x: cx, y: groundY - 2))
                    stem.addQuadCurve(
                        to: CGPoint(x: cx + CGFloat(sway * 0.4), y: groundY - 36),
                        control: CGPoint(x: cx - 3, y: groundY - 20)
                    )
                    context.stroke(stem, with: .color(Color(hex: 0x74C69D)), style: StrokeStyle(lineWidth: 4.5, lineCap: .round))

                    drawLeaf(&context, base: CGPoint(x: cx + CGFloat(sway * 0.4), y: groundY - 34), angle: -0.75, length: 24, width: 13, color: Color(hex: 0x95D5B2))
                    drawLeaf(&context, base: CGPoint(x: cx + CGFloat(sway * 0.4), y: groundY - 34), angle: 0.72, length: 22, width: 12, color: Color(hex: 0x52B788))
                } else {
                    // 阶段 2–5：随阶段成长的树干、枝丫、多层翡翠树冠与花朵/微步光点
                    let trunkHeight: CGFloat = {
                        switch stageLevel {
                        case 2: return 62
                        case 3: return 86
                        case 4: return 102
                        default: return 114
                        }
                    }()
                    let trunkWidth: CGFloat = {
                        switch stageLevel {
                        case 2: return 7
                        case 3: return 10.5
                        case 4: return 13
                        default: return 15
                        }
                    }()
                    let topX = cx + CGFloat(sway * 0.65)
                    let topY = groundY - trunkHeight

                    // 暖陶土色优雅弧形树干
                    var trunk = Path()
                    trunk.move(to: CGPoint(x: cx - trunkWidth * 0.55, y: groundY - 1))
                    trunk.addQuadCurve(
                        to: CGPoint(x: topX - trunkWidth * 0.22, y: topY),
                        control: CGPoint(x: cx - trunkWidth * 0.1, y: groundY - trunkHeight * 0.48)
                    )
                    trunk.addLine(to: CGPoint(x: topX + trunkWidth * 0.22, y: topY))
                    trunk.addQuadCurve(
                        to: CGPoint(x: cx + trunkWidth * 0.65, y: groundY - 1),
                        control: CGPoint(x: cx + trunkWidth * 0.25, y: groundY - trunkHeight * 0.48)
                    )
                    trunk.closeSubpath()
                    context.fill(
                        trunk,
                        with: .linearGradient(
                            Gradient(colors: [Color(hex: 0xE09F72), Color(hex: 0xB86B43)]),
                            startPoint: CGPoint(x: cx - 10, y: topY),
                            endPoint: CGPoint(x: cx + 10, y: groundY)
                        )
                    )

                    // 左右分枝
                    var leftBranch = Path()
                    leftBranch.move(to: CGPoint(x: cx + CGFloat(sway * 0.35), y: groundY - trunkHeight * 0.56))
                    leftBranch.addQuadCurve(
                        to: CGPoint(x: topX - 28, y: topY + 18),
                        control: CGPoint(x: topX - 16, y: topY + 32)
                    )
                    context.stroke(leftBranch, with: .color(Color(hex: 0xC97D52)), style: StrokeStyle(lineWidth: trunkWidth * 0.34, lineCap: .round))

                    var rightBranch = Path()
                    rightBranch.move(to: CGPoint(x: cx + CGFloat(sway * 0.35), y: groundY - trunkHeight * 0.62))
                    rightBranch.addQuadCurve(
                        to: CGPoint(x: topX + 30, y: topY + 14),
                        control: CGPoint(x: topX + 16, y: topY + 28)
                    )
                    context.stroke(rightBranch, with: .color(Color(hex: 0xC97D52)), style: StrokeStyle(lineWidth: trunkWidth * 0.32, lineCap: .round))

                    // 多层云朵翡翠树冠（随阶段越来越丰茂）
                    let canopies: [(dx: CGFloat, dy: CGFloat, rx: CGFloat, ry: CGFloat, color: Color, minStage: Int)] = [
                        (-30, 12, 26, 20, Color(hex: 0x2D6A4F), 2),
                        (30, 10, 26, 20, Color(hex: 0x40916C), 2),
                        (0, -10, 32, 24, Color(hex: 0x52B788), 2),
                        (-44, 24, 22, 16, Color(hex: 0x1B4332), 3),
                        (44, 20, 22, 16, Color(hex: 0x2D6A4F), 3),
                        (-18, -22, 24, 18, Color(hex: 0x74C69D), 3),
                        (22, -20, 24, 18, Color(hex: 0x95D5B2), 4),
                        (0, -34, 26, 18, Color(hex: 0xB7E4C7), 5)
                    ]

                    for c in canopies where stageLevel >= c.minStage {
                        let scale: CGFloat = stageLevel == 2 ? 0.78 : (stageLevel == 3 ? 0.92 : 1.0)
                        let center = CGPoint(x: topX + c.dx * scale, y: topY + c.dy * scale)
                        let rect = CGRect(
                            x: center.x - c.rx * scale,
                            y: center.y - c.ry * scale,
                            width: c.rx * 2 * scale,
                            height: c.ry * 2 * scale
                        )
                        context.fill(Path(ellipseIn: rect), with: .color(c.color.opacity(0.95)))
                    }

                    // 每一片树冠上的微步成果光点/小白花（最多展示 28 枚）
                    let blossomCount = min(totalCount, 28)
                    for i in 0..<blossomCount {
                        let item = records[totalCount - 1 - i]
                        let hash = abs(item.id.utf8.reduce(5381) { (($0 << 5) &+ $0) &+ Int($1) })
                        let angle = Double(hash % 360) * .pi / 180.0
                        let dist = CGFloat(10 + (hash / 360) % (stageLevel >= 4 ? 36 : 24))
                        let bx = topX + cos(angle) * dist * 1.15
                        let by = topY + sin(angle) * dist * 0.72 - 4 + CGFloat(abs(sway) * 0.35)
                        let r: CGFloat = stageLevel >= 4 ? 3.8 : 3.0
                        let blossomColor = (i % 3 == 0) ? Color(hex: 0xFFF8E7) : Color(hex: 0xFFE08A)
                        context.fill(
                            Path(ellipseIn: CGRect(x: bx - r, y: by - r, width: r * 2, height: r * 2)),
                            with: .color(blossomColor.opacity(0.92))
                        )
                    }
                }
            }
        }
    }

    private func drawLeaf(
        _ context: inout GraphicsContext,
        base: CGPoint,
        angle: Double,
        length: CGFloat,
        width: CGFloat,
        color: Color
    ) {
        var leaf = Path()
        leaf.move(to: .zero)
        leaf.addQuadCurve(to: CGPoint(x: 0, y: -length), control: CGPoint(x: -width, y: -length * 0.55))
        leaf.addQuadCurve(to: .zero, control: CGPoint(x: width, y: -length * 0.55))
        leaf.closeSubpath()

        var transform = CGAffineTransform(translationX: base.x, y: base.y)
        transform = transform.rotated(by: angle)
        context.fill(leaf.applying(transform), with: .color(color))
    }
}
