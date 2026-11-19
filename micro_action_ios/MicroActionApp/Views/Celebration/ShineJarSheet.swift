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
        proStore.isPro ? appState.themeSkin : .emerald
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

                        // 2. 0.6 秒圆环蓄力「随时夸夸自己」练习按钮
                        ChargeToShineButton(
                            label: "按住 0.6 秒夸夸自己",
                            completedLabel: "星籽 +1",
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
                .background(BotanicalTheme.backgroundBottom.ignoresSafeArea())

                StarburstParticleLayer(burstId: burstId, isGrand: true)
                    .ignoresSafeArea()
            }
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
        .presentationDragIndicator(.visible)
    }

    private var jarHeroCard: some View {
        ZStack(alignment: .top) {
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
                        .stroke(BotanicalTheme.gold.opacity(0.28), lineWidth: 1)
                )

            ShineJarCanvasView(records: appState.shineRecords, bounceStart: bounceStart)
                .frame(height: 204)

            HStack {
                Text("今日 \(appState.todayShineCount) · 累计 \(appState.shineRecords.count)")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(activeTheme.goldColor)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background(activeTheme.creamColor.opacity(0.14))
                    .clipShape(Capsule())
                Spacer()
                Text("轻触罐身摇晃星籽")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(activeTheme.creamColor.opacity(0.75))
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
        }
        .frame(height: 204)
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
                Text("自定义比例（点上方按钮可一键全选）")
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

/// 复刻原版 _ShineJarPainter：Canvas 真实玻璃星籽罐（软木瓶塞 + 弧形高光折射 + 金色星沙底衬 + 最多72颗四角发光星籽 + 物理跃动波）
private struct ShineJarCanvasView: View {
    let records: [ShineRecord]
    let bounceStart: Date?

    private static let seedColors: [Color] = [
        Color(hex: 0xFFD166),
        Color(hex: 0xE9C46A),
        Color(hex: 0x52B788),
        Color(hex: 0xF4A261),
        Color(hex: 0x95D5B2),
        Color(hex: 0xFFF3B0)
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: bounceStart == nil)) { timeline in
            let bounceProgress: Double = {
                guard let start = bounceStart else { return 0 }
                let elapsed = timeline.date.timeIntervalSince(start)
                if elapsed < 0 || elapsed >= 0.56 { return 0 }
                return elapsed / 0.56
            }()

            Canvas { context, size in
                let cx = size.width * 0.5
                let jarWidth = min(size.width * 0.44, 152.0)
                let jarTop: CGFloat = 46.0
                let jarBottom = size.height - 18.0
                let jarHeight = jarBottom - jarTop
                let jarRect = CGRect(x: cx - jarWidth / 2, y: jarTop, width: jarWidth, height: jarHeight)

                // 背景柔和金色光晕
                let glowCenter = CGPoint(x: cx, y: jarTop + jarHeight * 0.6)
                let glowR = jarWidth * 0.9
                context.fill(
                    Path(ellipseIn: CGRect(x: glowCenter.x - glowR, y: glowCenter.y - glowR, width: glowR * 2, height: glowR * 2)),
                    with: .radialGradient(
                        Gradient(colors: [Color(hex: 0xE9C46A).opacity(0.18), .clear]),
                        center: glowCenter,
                        startRadius: 0,
                        endRadius: glowR
                    )
                )

                // 软木瓶塞
                let corkRect = CGRect(x: cx - jarWidth * 0.26, y: jarTop - 13, width: jarWidth * 0.52, height: 12)
                context.fill(
                    Path(roundedRect: corkRect, cornerRadius: 4),
                    with: .color(Color(hex: 0xC89B6E))
                )

                // 瓶口玻璃颈部
                let neckRect = CGRect(x: cx - jarWidth * 0.32, y: jarTop - 4, width: jarWidth * 0.64, height: 8)
                context.fill(
                    Path(roundedRect: neckRect, cornerRadius: 4),
                    with: .color(Color.white.opacity(0.24))
                )

                // 罐体圆角路径
                let bodyPath = Path(roundedRect: jarRect, cornerSize: CGSize(width: 24, height: 24))
                context.fill(bodyPath, with: .color(Color.white.opacity(0.08)))

                // 裁切在罐体内部绘制星沙与星籽
                context.drawLayer { layer in
                    layer.clip(to: bodyPath)

                    if records.count > 24 {
                        let sandRatio = min(0.36, max(0.06, Double(records.count - 24) / 160.0))
                        let sandH = jarHeight * CGFloat(sandRatio)
                        let sandRect = CGRect(x: jarRect.minX, y: jarRect.maxY - sandH, width: jarWidth, height: sandH)
                        layer.fill(
                            Path(sandRect),
                            with: .linearGradient(
                                Gradient(colors: [Color(hex: 0xE9C46A).opacity(0.12), Color(hex: 0xE9C46A).opacity(0.38)]),
                                startPoint: CGPoint(x: sandRect.midX, y: sandRect.minY),
                                endPoint: CGPoint(x: sandRect.midX, y: sandRect.maxY)
                            )
                        )
                    }

                    let visibleCount = min(records.count, 72)
                    let jumpWave = sin(bounceProgress * .pi)

                    for i in 0..<visibleCount {
                        let item = records[visibleCount - 1 - i]
                        let hash = abs(item.id.utf8.reduce(5381) { (($0 << 5) &+ $0) &+ Int($1) })
                        let colCount = 6
                        let row = i / colCount
                        let col = i % colCount

                        let jitterX = (CGFloat(hash % 100) / 100.0 - 0.5) * 12.0
                        let jitterY = (CGFloat((hash / 100) % 100) / 100.0 - 0.5) * 7.0
                        let usableW = jarWidth - 28.0
                        let x = jarRect.minX + 14.0 + (CGFloat(col) + 0.5) * (usableW / CGFloat(colCount)) + jitterX
                        let baseBottom = jarRect.maxY - 14.0 - CGFloat(row) * 10.5 + jitterY
                        let jumpOffset = CGFloat(jumpWave) * CGFloat(8 + (hash % 14)) * CGFloat(1.0 - min(0.5, Double(row) * 0.04))
                        let y = min(jarRect.maxY - 10.0, max(jarRect.minY + 14.0, baseBottom - jumpOffset))

                        let center = CGPoint(x: x, y: y)
                        let color = Self.seedColors[abs(item.colorSeed) % Self.seedColors.count]
                        let radius: CGFloat = item.isGrand ? 6.6 : 5.0

                        let glowR = radius * 1.45
                        layer.fill(
                            Path(ellipseIn: CGRect(x: center.x - glowR, y: center.y - glowR, width: glowR * 2, height: glowR * 2)),
                            with: .radialGradient(
                                Gradient(colors: [color.opacity(0.42), .clear]),
                                center: center,
                                startRadius: 0,
                                endRadius: glowR
                            )
                        )

                        let star = fourPointStarPath(center: center, outerRadius: radius, innerRadius: radius * 0.40)
                        layer.fill(star, with: .color(color))
                    }
                }

                // 罐体玻璃描边
                context.stroke(bodyPath, with: .color(Color.white.opacity(0.32)), lineWidth: 1.5)

                // 左侧玻璃高光折射条
                var highlight = Path()
                highlight.move(to: CGPoint(x: jarRect.minX + 11, y: jarRect.minY + 22))
                highlight.addLine(to: CGPoint(x: jarRect.minX + 11, y: jarRect.maxY - 26))
                context.stroke(
                    highlight,
                    with: .color(Color.white.opacity(0.24)),
                    style: StrokeStyle(lineWidth: 3.2, lineCap: .round)
                )
            }
        }
    }
}
