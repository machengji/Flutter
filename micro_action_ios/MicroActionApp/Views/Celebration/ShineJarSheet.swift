import SwiftUI

/// 庆祝仪式与 AI 夸夸官设置抽屉（由全屏成长树右上角齿轮唤起）
struct ShineJarSheet: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var proStore: ProStoreService
    @Environment(\.dismiss) private var dismiss

    @State private var newAffirmation: String = ""
    @State private var newRitual: String = ""

    private var activeTheme: CelebrationThemeSkin {
        appState.themeSkin
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // 1. 彩虹屁 & 冷笑话比例调节卡
                    ratioControlCard

                    // 2. 福格微庆祝动作库（随机提示 / 固定招牌 + 勾选与自定义）
                    celebrationRitualCard

                    // 3. 庆祝页面皮肤（随机轮换 / 固定选择）
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
            .navigationTitle("庆祝仪式设置")
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
        CelebrationRatioControlCard(useLiquidGlass: false)
    }

    private var celebrationRitualCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("我的庆祝微动作")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(BotanicalTheme.textPrimary)
                Spacer()
                Text(appState.isCelebrationRitualRandom ? "已启用 \(appState.enabledCelebrationRituals.count) 项" : "已固定招牌动作")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(BotanicalTheme.textHint)
            }

            Text("按住庆祝按钮的 0.6 秒内同步做这个小动作，帮大脑记住「发光感」")
                .font(.system(size: 11.5))
                .foregroundColor(BotanicalTheme.textSecondary)

            Picker("提示方式", selection: Binding(
                get: { appState.isCelebrationRitualRandom },
                set: { newVal in
                    SensoryFeedbackService.shared.selection()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                        appState.setCelebrationRitualMode(isRandom: newVal)
                    }
                }
            )) {
                Text("随机提示").tag(true)
                Text("固定招牌").tag(false)
            }
            .pickerStyle(.segmented)

            VStack(spacing: 7) {
                ForEach(appState.allCelebrationRituals, id: \.self) { ritual in
                    let isCustom = appState.customCelebrationRituals.contains(ritual)
                    let isSelected = appState.isCelebrationRitualRandom
                        ? appState.enabledCelebrationRituals.contains(ritual)
                        : (appState.fixedCelebrationRitual == ritual)

                    HStack(spacing: 8) {
                        Button {
                            SensoryFeedbackService.shared.selection()
                            withAnimation(.spring(response: 0.24, dampingFraction: 0.84)) {
                                if appState.isCelebrationRitualRandom {
                                    appState.toggleCelebrationRitual(ritual)
                                } else {
                                    appState.setCelebrationRitualMode(isRandom: false, fixed: ritual)
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(isSelected ? BotanicalTheme.primary : BotanicalTheme.textHint)
                                Text(ritual)
                                    .font(.system(size: 12.5, weight: isSelected ? .semibold : .regular))
                                    .foregroundColor(isSelected ? BotanicalTheme.textPrimary : BotanicalTheme.textSecondary)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 4)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if isCustom {
                            Button {
                                SensoryFeedbackService.shared.selection()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    appState.deleteCustomCelebrationRitual(ritual)
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(BotanicalTheme.textHint.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(isSelected ? BotanicalTheme.primarySoft.opacity(0.45) : BotanicalTheme.surfaceMuted.opacity(0.75))
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                }
            }

            HStack(spacing: 8) {
                TextField("添加你的专属庆祝动作，如：打个响指微笑", text: $newRitual)
                    .font(.system(size: 12.5))
                    .submitLabel(.done)
                    .onSubmit { submitCustomRitual() }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(BotanicalTheme.surfaceMuted)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button {
                    submitCustomRitual()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(newRitual.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? BotanicalTheme.textHint.opacity(0.4) : BotanicalTheme.primary)
                        .clipShape(Circle())
                }
                .disabled(newRitual.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .background(BotanicalTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 3)
    }

    private func submitCustomRitual() {
        let trimmed = newRitual.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        SensoryFeedbackService.shared.lightTap()
        appState.addCustomCelebrationRitual(trimmed)
        newRitual = ""
    }

    private var themeSkinCard: some View {
        let posterPresets: [(index: Int, name: String, imageName: String, badgeColor: Color)] = [
            (0, "晨光小芽", "IllustCelebrationPoster", Color(hex: 0x2D6A4F)),
            (1, "星空夜光", "IllustCelebrationStarry", Color(hex: 0xD9A441)),
            (2, "蜜桃花环", "IllustCelebrationBlossom", Color(hex: 0xD97757)),
            (3, "经典欢呼", "IllustCelebrationClassic", Color(hex: 0x054B4A))
        ]

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("庆祝页面皮肤")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(BotanicalTheme.textPrimary)
                Spacer()
                Text(appState.isCelebrationRandomStyle ? "每次自动轮换" : "已固定样式")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(BotanicalTheme.textHint)
            }

            Picker("切换方式", selection: Binding(
                get: { appState.isCelebrationRandomStyle },
                set: { newVal in
                    SensoryFeedbackService.shared.selection()
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.84)) {
                        appState.setCelebrationPosterMode(isRandom: newVal)
                    }
                }
            )) {
                Text("随机轮换").tag(true)
                Text("固定选择").tag(false)
            }
            .pickerStyle(.segmented)

            if appState.isCelebrationRandomStyle {
                Text("每次完成愿望或习惯，将在「晨光小芽 / 星空夜光 / 蜜桃花环 / 经典欢呼」4 套庆祝卡间自动轮换呈现。")
                    .font(.system(size: 11.5))
                    .foregroundColor(BotanicalTheme.textSecondary)
                    .lineSpacing(3)
            } else {
                HStack(spacing: 8) {
                    ForEach(posterPresets, id: \.index) { item in
                        let selected = appState.fixedCelebrationStyleIndex == item.index
                        Button {
                            SensoryFeedbackService.shared.selection()
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                appState.setCelebrationPosterMode(isRandom: false, fixedIndex: item.index)
                            }
                        } label: {
                            VStack(spacing: 6) {
                                ZStack(alignment: .topTrailing) {
                                    Image(item.imageName)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 76)
                                        .frame(maxWidth: .infinity)
                                        .background(item.index == 3 ? Color(hex: 0x006766) : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(
                                                    selected ? BotanicalTheme.primary : Color.black.opacity(0.08),
                                                    lineWidth: selected ? 2.4 : 0.8
                                                )
                                        )

                                    if selected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                            .background(Circle().fill(item.badgeColor).padding(2))
                                            .padding(4)
                                    }
                                }

                                Text(item.name)
                                    .font(.system(size: 10.5, weight: selected ? .bold : .medium))
                                    .foregroundColor(selected ? BotanicalTheme.primaryDark : BotanicalTheme.textSecondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(ScaleBounceButtonStyle(scale: 0.95))
                    }
                }
                .transition(.opacity)
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

/// 可复用的「庆祝焦点内容出现概率」调节卡（彩虹屁 / 宜忌幸运签 / 冷笑话，合计 100%）
struct CelebrationRatioControlCard: View {
    @EnvironmentObject private var appState: AppState
    var useLiquidGlass: Bool = false

    var body: some View {
        let content = VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                if useLiquidGlass {
                    Image(systemName: "sparkles.rectangle.stack")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(BotanicalTheme.primary)
                }
                Text("庆祝内容出现概率")
                    .font(.system(size: useLiquidGlass ? 15.5 : 14.5, weight: .bold))
                    .foregroundColor(BotanicalTheme.textPrimary)
                Spacer()
                Text("合计 100%")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(BotanicalTheme.textHint)
            }

            // 三色比例分布条（彩虹屁 / 宜忌幸运签 / 冷笑话）
            GeometryReader { geo in
                HStack(spacing: 2) {
                    if appState.rainbowRatio > 0 {
                        Capsule()
                            .fill(BotanicalTheme.primary)
                            .frame(width: max(8, geo.size.width * CGFloat(appState.rainbowRatio) / 100.0))
                    }
                    if appState.fortuneRatio > 0 {
                        Capsule()
                            .fill(Color(hex: 0xE5A93B))
                            .frame(width: max(8, geo.size.width * CGFloat(appState.fortuneRatio) / 100.0))
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
                quickChip(
                    title: "均衡 60/20/20",
                    selected: appState.rainbowRatio == 60 && appState.fortuneRatio == 20
                ) {
                    SensoryFeedbackService.shared.selection()
                    appState.setSpotlightRatios(rainbow: 60, fortune: 20)
                }

                quickChip(
                    title: "彩虹屁 100%",
                    selected: appState.rainbowRatio == 100 && appState.fortuneRatio == 0
                ) {
                    SensoryFeedbackService.shared.selection()
                    appState.setSpotlightRatios(rainbow: 100, fortune: 0)
                }

                quickChip(
                    title: "三项均分",
                    selected: appState.rainbowRatio == 35 && appState.fortuneRatio == 35
                ) {
                    SensoryFeedbackService.shared.selection()
                    appState.setSpotlightRatios(rainbow: 35, fortune: 35)
                }
            }

            VStack(spacing: 8) {
                VStack(spacing: 4) {
                    HStack {
                        Text("✨ 彩虹屁（嘴甜夸夸）")
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
                                let maxFortune = 100 - newRainbow
                                appState.setSpotlightRatios(
                                    rainbow: newRainbow,
                                    fortune: min(appState.fortuneRatio, maxFortune)
                                )
                            }
                        ),
                        in: 0...100,
                        step: 5
                    )
                    .tint(BotanicalTheme.primary)
                }

                VStack(spacing: 4) {
                    HStack {
                        Text("🎋 宜忌幸运签")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(BotanicalTheme.textSecondary)
                        Spacer()
                        Text("\(appState.fortuneRatio)%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: 0xC68314))
                    }
                    Slider(
                        value: Binding(
                            get: { Double(appState.fortuneRatio) },
                            set: {
                                let newFortune = Int(($0 / 5.0).rounded() * 5)
                                let maxRainbow = 100 - newFortune
                                appState.setSpotlightRatios(
                                    rainbow: min(appState.rainbowRatio, maxRainbow),
                                    fortune: newFortune
                                )
                            }
                        ),
                        in: 0...100,
                        step: 5
                    )
                    .tint(Color(hex: 0xE5A93B))
                }

                HStack {
                    Text("❄️ 冷笑话（自动补足剩余比例）")
                        .font(.system(size: 11.5))
                        .foregroundColor(BotanicalTheme.textHint)
                    Spacer()
                    Text("\(appState.coldJokeRatio)%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(BotanicalTheme.warning)
                }
            }
        }
        .padding(useLiquidGlass ? 18 : 16)

        if useLiquidGlass {
            content
                .liquidGlassCard(cornerRadius: 24, tint: BotanicalTheme.primaryLight, interactive: false, shadowRadius: 12)
        } else {
            content
                .background(BotanicalTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(BotanicalTheme.border.opacity(0.75), lineWidth: 1))
        }
    }

    private func quickChip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(selected ? .white : BotanicalTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 35)
                .background(selected ? BotanicalTheme.primary : BotanicalTheme.surfaceMuted)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(selected ? BotanicalTheme.primary : BotanicalTheme.border.opacity(0.7), lineWidth: 1)
                )
        }
        .buttonStyle(ScaleBounceButtonStyle(scale: 0.96))
    }
}
