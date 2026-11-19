import SwiftUI

/// 发光星籽罐设置与自由庆祝面板
/// 支持：玻璃罐星籽可视化、主动夸夸自己、彩虹屁/冷笑话自定义比例滑块、AI四大人设、4套主题皮肤、3套音效包、自定义庆祝语
struct ShineJarSheet: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var proStore: ProStoreService
    @Environment(\.dismiss) private var dismiss

    @State private var newAffirmation: String = ""

    private var activeTheme: CelebrationThemeSkin {
        proStore.isPro ? appState.themeSkin : .emerald
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 1. 发光星籽罐可视化卡片
                    jarHeroCard

                    // 2. 主动夸夸自己按钮
                    Button {
                        Task {
                            let payload = await appState.celebrateFreely()
                            dismiss()
                            try? await Task.sleep(nanoseconds: 180_000_000)
                            appState.activeCelebration = payload
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .bold))
                            Text("现在就夸夸自己一次")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(BotanicalTheme.primaryGradient)
                        .clipShape(Capsule())
                    }

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
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(BotanicalTheme.backgroundTop.ignoresSafeArea())
            .navigationTitle("发光星籽罐")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(BotanicalTheme.primary)
                }
            }
        }
    }

    private var jarHeroCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(activeTheme.bgColor)

            VStack(spacing: 10) {
                HStack {
                    Text("今日 \(appState.todayShineCount) 颗 · 累计 \(appState.shineRecords.count) 颗")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(activeTheme.goldColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(activeTheme.creamColor.opacity(0.14))
                        .clipShape(Capsule())
                    Spacer()
                    Text(activeTheme.name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(activeTheme.creamColor.opacity(0.8))
                }

                // 玻璃罐与内部星籽
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(activeTheme.creamColor.opacity(0.35), lineWidth: 2)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(activeTheme.creamColor.opacity(0.06))
                        )
                        .frame(width: 148, height: 112)

                    let visibleCount = min(max(appState.shineRecords.count, 1), 24)
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(16), spacing: 4), count: 6), spacing: 4) {
                        ForEach(0..<visibleCount, id: \.self) { idx in
                            Image(systemName: "sparkle")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(
                                    idx % 3 == 0 ? activeTheme.goldColor :
                                    (idx % 3 == 1 ? activeTheme.peachColor : activeTheme.creamColor)
                                )
                        }
                    }
                    .frame(width: 126)
                    .padding(.bottom, 10)
                }
                .overlay(alignment: .top) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(hex: 0xC89F7B))
                        .frame(width: 74, height: 12)
                        .offset(y: -8)
                }
                .padding(.top, 10)
            }
            .padding(18)
        }
        .frame(height: 190)
    }

    private var ratioControlCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("庆祝方式比例（彩虹屁 / 冷笑话）")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(BotanicalTheme.textPrimary)

            HStack(spacing: 10) {
                ratioQuickChip(
                    title: "彩虹屁 \(appState.rainbowRatio)%",
                    selected: appState.rainbowRatio >= 50
                ) {
                    SensoryFeedbackService.shared.selection()
                    appState.setRainbowRatio(100)
                }

                ratioQuickChip(
                    title: "冷笑话 \(appState.coldJokeRatio)%",
                    selected: appState.rainbowRatio < 50
                ) {
                    SensoryFeedbackService.shared.selection()
                    appState.setRainbowRatio(0)
                }
            }

            HStack {
                Text("拖动滑块自由调节比例（点上方按钮可一键全选）")
                    .font(.system(size: 11))
                    .foregroundColor(BotanicalTheme.textSecondary)
                Spacer()
                Text("\(appState.rainbowRatio)% / \(appState.coldJokeRatio)%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(BotanicalTheme.primary)
            }

            Slider(
                value: Binding(
                    get: { Double(appState.rainbowRatio) },
                    set: { appState.setRainbowRatio(Int(($0 / 5.0).rounded() * 5)) }
                ),
                in: 0...100,
                step: 5
            )
            .tint(BotanicalTheme.primary)
        }
        .padding(16)
        .background(BotanicalTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(BotanicalTheme.border, lineWidth: 1))
    }

    private func ratioQuickChip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(selected ? .white : BotanicalTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(selected ? BotanicalTheme.primary : BotanicalTheme.surfaceMuted)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
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
                }
            }
        }
        .padding(16)
        .background(BotanicalTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(BotanicalTheme.border, lineWidth: 1))
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
                        if skin.isPro && !proStore.isPro {
                            appState.showProPaywall = true
                        } else {
                            appState.setThemeSkin(skin)
                        }
                    } label: {
                        VStack(spacing: 6) {
                            ZStack(alignment: .topTrailing) {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(skin.bgColor)
                                    .frame(height: 46)
                                    .overlay(
                                        Image(systemName: "sparkles")
                                            .foregroundColor(skin.goldColor)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(selected ? BotanicalTheme.primary : .clear, lineWidth: 2.5)
                                    )
                                if skin.isPro && !proStore.isPro {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 9))
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(Color.black.opacity(0.45))
                                        .clipShape(Circle())
                                        .padding(4)
                                }
                            }
                            Text(skin.name)
                                .font(.system(size: 11, weight: selected ? .bold : .medium))
                                .foregroundColor(selected ? BotanicalTheme.primaryDark : BotanicalTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(16)
        .background(BotanicalTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(BotanicalTheme.border, lineWidth: 1))
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
                    }
                }
            }
        }
        .padding(16)
        .background(BotanicalTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(BotanicalTheme.border, lineWidth: 1))
    }

    private var customAffirmationsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("专属庆祝语 / 小奖励")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(BotanicalTheme.textPrimary)

            HStack {
                TextField("例如：奖励自己一杯热拿铁", text: $newAffirmation)
                    .font(.system(size: 14))
                    .padding(.horizontal, 12)
                    .frame(height: 40)
                    .background(BotanicalTheme.surfaceMuted)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button("添加") {
                    appState.addCustomAffirmation(newAffirmation)
                    newAffirmation = ""
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .frame(height: 40)
                .background(BotanicalTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if !appState.customAffirmations.isEmpty {
                ForEach(appState.customAffirmations, id: \.self) { item in
                    HStack {
                        Text(item)
                            .font(.system(size: 13))
                            .foregroundColor(BotanicalTheme.textPrimary)
                        Spacer()
                        Button {
                            appState.removeCustomAffirmation(item)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(BotanicalTheme.textHint)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .background(BotanicalTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(BotanicalTheme.border, lineWidth: 1))
    }

    private var proBadge: some View {
        Text("PRO")
            .font(.system(size: 10, weight: .heavy))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(hex: 0xD97706))
            .clipShape(Capsule())
    }
}
