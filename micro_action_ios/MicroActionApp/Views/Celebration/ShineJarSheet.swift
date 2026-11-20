import SwiftUI

/// 庆祝仪式与 AI 夸夸官设置抽屉（由全屏成长树右上角齿轮唤起）
struct ShineJarSheet: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var proStore: ProStoreService
    @Environment(\.dismiss) private var dismiss

    @State private var newAffirmation: String = ""

    private var activeTheme: CelebrationThemeSkin {
        appState.themeSkin
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // 1. 彩虹屁 & 冷笑话 & AI 自定义比例调节卡
                    ratioControlCard

                    // 2. AI 专属夸夸官四大人设（Pro）
                    aiPersonaCard

                    // 3. 庆祝仪式主题皮肤（4 套）
                    themeSkinCard

                    // 4. 微音效开关与 3 套风格包
                    soundPackCard

                    // 5. 自定义专属庆祝语
                    customAffirmationsCard
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 16)
            }
            .liquidSheetCanvasBackground()
            .navigationTitle("庆祝与 AI 设置")
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
