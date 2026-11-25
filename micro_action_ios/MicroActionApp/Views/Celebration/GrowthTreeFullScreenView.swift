import SwiftUI

/// 全屏沉浸式「微步成长树 2.0」独立页面
/// 六大独立手绘水彩群落 + 专属树干与树冠排布 + 群落生态彩蛋 + 第7棵起高阶天光变体 + 森林图鉴总览
struct GrowthTreeFullScreenView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var showSettingsSheet: Bool = false
    @State private var showForestGallery: Bool = false
    @State private var selectedTreeIndex: Int? = nil // nil 表示当前正在成长的最新一棵
    @State private var burstId: Int = 0
    @State private var petalBurstId: Int = 0
    @State private var newestLeafIndex: Int? = nil
    @State private var rippleTrigger: Int = 0
    @State private var energyPulseProgress: CGFloat = 0
    @State private var showEnergyPulse: Bool = false
    @State private var selectedRecord: ShineRecord? = nil
    @State private var freeQuoteBanner: String? = nil
    @State private var isWatering: Bool = false

    private let leavesPerTree = 100

    /// 按时间从早到晚排列的全部微步记录
    private var chronologicalRecords: [ShineRecord] {
        Array(appState.shineRecords.reversed())
    }

    private var totalTreesCount: Int {
        max(1, (chronologicalRecords.count + leavesPerTree - 1) / leavesPerTree)
    }

    private var activeTreeIndex: Int {
        min(selectedTreeIndex ?? (totalTreesCount - 1), totalTreesCount - 1)
    }

    private var currentSpecies: ForestTreeSpecies {
        ForestTreeSpecies.forIndex(activeTreeIndex)
    }

    private var currentVariant: ForestCosmicVariant {
        ForestCosmicVariant.forTreeIndex(activeTreeIndex)
    }

    private var isMirroredTree: Bool {
        currentSpecies.isMirrored(treeIndex: activeTreeIndex)
    }

    private var currentTreeRecords: [ShineRecord] {
        let start = activeTreeIndex * leavesPerTree
        let end = min(start + leavesPerTree, chronologicalRecords.count)
        guard start < end else { return [] }
        return Array(chronologicalRecords[start..<end])
    }

    /// 群落专属 5 阶生态进化彩蛋解锁进度提示（10步伴侣 · 25步灯火/螃蟹 · 45步飞羽 · 65步灵兽 · 85步暖茶篝火）
    private var ecoMilestoneHint: String? {
        let count = currentTreeRecords.count
        let groundName = currentSpecies.groundEasterEggLabel
        let midName = currentSpecies.midEcoLabel
        let canopyName = currentSpecies.canopyEasterEggLabel
        let companionName = currentSpecies.companionAnimalLabel
        let campName = currentSpecies.campEasterEggLabel

        if count < 10 {
            return "再点亮 \(10 - count) 步 · 解锁\(groundName)"
        } else if count < 25 {
            return "\(groundName)已就位 · 再 \(25 - count) 步解锁\(midName)"
        } else if count < 45 {
            return "\(midName)已点亮 · 再 \(45 - count) 步迎来\(canopyName)"
        } else if count < 65 {
            return "\(canopyName)已停驻 · 再 \(65 - count) 步邂逅\(companionName)"
        } else if count < 85 {
            return "\(companionName)伴你左右 · 再 \(85 - count) 步点亮\(campName)"
        } else if count < leavesPerTree {
            return "森林全生态已齐聚 · \(campName)温暖守护中"
        }
        return nil
    }

    /// 满 100 步纪念卷册起止日期标签
    private var sealedVolumeDateBadge: String? {
        guard currentTreeRecords.count >= leavesPerTree,
              let first = currentTreeRecords.first,
              let last = currentTreeRecords.last else { return nil }
        let f = DateFormatter()
        f.dateFormat = "M/d"
        let s = f.string(from: Date(timeIntervalSince1970: Double(first.timestamp) / 1000.0))
        let e = f.string(from: Date(timeIntervalSince1970: Double(last.timestamp) / 1000.0))
        return "圆满封存 · \(s)-\(e)"
    }

    private var stageTitle: String {
        let count = currentTreeRecords.count
        switch count {
        case 0: return "休眠星种"
        case 1...10: return "初生嫩芽"
        case 11...35: return "抽枝青树"
        case 36...75: return "繁花绿冠"
        case 76..<100: return "森境大树"
        default: return "圆满生命树"
        }
    }

    /// 随真实系统时间自适应柔和天光氛围
    private var ambientTint: (overlay: Color, isNight: Bool, label: String) {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<10:
            return (Color(hex: 0xFFE6A8).opacity(0.10), false, "晨曦")
        case 10..<17:
            return (Color.clear, false, "晴空")
        case 17..<20:
            return (Color(hex: 0xF4A261).opacity(0.16), false, "晚霞")
        default:
            return (Color(hex: 0x1B3242).opacity(0.32), true, "星夜")
        }
    }

    var body: some View {
        let amb = ambientTint
        let selectAction: (ShineRecord) -> Void = { rec in
            SensoryFeedbackService.shared.lightTap()
            withAnimation(.spring(response: 0.30, dampingFraction: 0.78)) {
                selectedRecord = (selectedRecord?.id == rec.id) ? nil : rec
            }
        }

        ZStack {
            // 1. 群落独立手绘水彩背景 + 高阶天光变体 + 昼夜氛围
            GeometryReader { geo in
                Image(currentSpecies.backgroundImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .overlay(currentVariant.atmosphereTint)
                    .overlay(amb.overlay)
            }
            .ignoresSafeArea()

            if amb.isNight || currentVariant != .natural {
                NightFireflyLayer()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            AmbientBiomeParticlesLayer(species: currentSpecies)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            DriftingCloudsAndButterfliesLayer(species: currentSpecies, isNight: amb.isNight)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // 2. 手绘水彩成长树（专属树干 + 群落树冠排布 + 专属生态进化彩蛋）
            GeometryReader { geo in
                let treeWidth = min(geo.size.width * 0.94, 410)
                let treeHeight = min(geo.size.height * 0.62, 520)
                let treeCenterX = geo.size.width * 0.53
                let treeCenterY = geo.size.height * 0.57

                WatercolorGrowthTreeView(
                    records: currentTreeRecords,
                    species: currentSpecies,
                    variant: currentVariant,
                    isMirrored: isMirroredTree,
                    newestLeafIndex: newestLeafIndex,
                    rippleTrigger: rippleTrigger,
                    energyPulseProgress: energyPulseProgress,
                    showEnergyPulse: showEnergyPulse,
                    isNight: amb.isNight,
                    onTapCanopy: {
                        petalBurstId += 1
                    },
                    onSelectRecord: selectAction
                )
                .frame(width: treeWidth, height: treeHeight)
                .position(x: treeCenterX, y: treeCenterY)
            }

            DriftingPetalsOverlay(triggerId: petalBurstId, species: currentSpecies)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // 3. 星芒粒子层
            StarburstParticleLayer(burstId: burstId, isGrand: true)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // 4. 极简悬浮 HUD（物理绝对居中三层排布）
            VStack(spacing: 8) {
                topHudBar(isNight: amb.isNight)
                    .padding(.horizontal, 18)
                    .padding(.top, 8)

                hudSpeciesPill
                    .padding(.horizontal, 18)

                if let sealedBadge = sealedVolumeDateBadge {
                    HStack(spacing: 5) {
                        Image(systemName: "rosette")
                            .font(.system(size: 11, weight: .bold))
                        Text(sealedBadge)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(Color(hex: 0xB45309))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 4)
                    .background(Color(hex: 0xFEF3C7).opacity(0.92))
                    .clipShape(Capsule())
                } else if let ecoHint = ecoMilestoneHint {
                    HStack(spacing: 5) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(currentVariant.badgeColor)
                        Text(ecoHint)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(Color(hex: 0x2F523E))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 4)
                    .background(Color(hex: 0xFAF6ED).opacity(0.84))
                    .overlay(Capsule().stroke(Color.white.opacity(0.75), lineWidth: 0.8))
                    .clipShape(Capsule())
                }

                Spacer()

                if let rec = selectedRecord {
                    selectedLeafBanner(rec)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else if let quote = freeQuoteBanner {
                    Text(quote)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundColor(Color(hex: 0x1D4432))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color(hex: 0xFAF6ED).opacity(0.92))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color(hex: 0xDFD6C3), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: Color.black.opacity(0.08), radius: 10, y: 4)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 12)
                        .transition(.opacity.combined(with: .scale(scale: 0.94)))
                }

                // 底部 0.75s 视触三感合一拟物长震动仪式按钮
                ChargeToShineButton(
                    label: "按住浇灌星光",
                    chargingLabel: "星光汇聚中...",
                    completedLabel: "此刻已发光",
                    allowQuickTapClose: true,
                    accentColor: Color(hex: 0xE5F4E8).opacity(0.94),
                    secondaryAccentColor: Color(hex: 0xCDE7D3).opacity(0.94),
                    borderColor: Color(hex: 0xA4CBAE).opacity(0.85),
                    textColor: Color(hex: 0x1D4432),
                    chargingTextColor: Color(hex: 0x5C3A08),
                    onCharged: { performWatering() },
                    onQuickTap: { performWatering() }
                )
                .frame(width: 218)
                .padding(.bottom, 22)
            }
        }
        .sheet(isPresented: $showSettingsSheet) {
            ShineJarSheet()
        }
        .sheet(isPresented: $showForestGallery) {
            ForestGallerySheet(
                totalRecordsCount: chronologicalRecords.count,
                totalTreesCount: totalTreesCount,
                activeTreeIndex: activeTreeIndex,
                leavesPerTree: leavesPerTree,
                allRecords: chronologicalRecords
            ) { chosenIdx in
                withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                    selectedTreeIndex = chosenIdx
                    selectedRecord = nil
                }
            }
        }
        .onChange(of: appState.shineRecords.count) { newCount in
            if newCount > 0 {
                selectedTreeIndex = nil // 自动回到最新一棵正在成长的树
                let idxInTree = (newCount - 1) % leavesPerTree
                triggerNewLeafCelebration(leafIndex: idxInTree)
            }
        }
    }

    private func topHudBar(isNight: Bool) -> some View {
        let titleColor = isNight ? Color.white : Color(hex: 0x1D4432)
        return ZStack {
            Text("微步成长树")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(titleColor)

            HStack(alignment: .center) {
                hudCloseButton
                Spacer()
                hudRightButtons
            }
        }
        .frame(height: 38)
    }

    private var hudCloseButton: some View {
        Button {
            SensoryFeedbackService.shared.selection()
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: 0x1D4432))
                .frame(width: 38, height: 38)
                .background(Color(hex: 0xFAF6ED).opacity(0.88))
                .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 1))
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.08), radius: 8, y: 3)
        }
        .buttonStyle(ScaleBounceButtonStyle(scale: 0.90))
    }

    private var hudSpeciesPill: some View {
        let countText = "\(currentTreeRecords.count)/\(leavesPerTree)"
        let speciesTitle = currentVariant.prefixTitle.map { "\($0)·\(currentSpecies.displayName)" } ?? currentSpecies.displayName
        let infoText: String = totalTreesCount > 1
            ? "第 \(activeTreeIndex + 1)/\(totalTreesCount) 棵 · \(speciesTitle) · \(countText)"
            : "\(speciesTitle) · \(stageTitle) · \(countText)"

        return HStack(spacing: 6) {
            if totalTreesCount > 1 {
                Button {
                    SensoryFeedbackService.shared.selection()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                        selectedTreeIndex = max(0, activeTreeIndex - 1)
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(activeTreeIndex > 0 ? Color(hex: 0x1D4432) : Color(hex: 0xA8B8AE))
                }
                .disabled(activeTreeIndex == 0)
            }

            Circle()
                .fill(currentVariant.badgeColor)
                .frame(width: 6, height: 6)

            Text(infoText)
                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: 0x3D5E4C))
                .contentTransition(.numericText())

            if totalTreesCount > 1 {
                Button {
                    SensoryFeedbackService.shared.selection()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                        selectedTreeIndex = min(totalTreesCount - 1, activeTreeIndex + 1)
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(activeTreeIndex < totalTreesCount - 1 ? Color(hex: 0x1D4432) : Color(hex: 0xA8B8AE))
                }
                .disabled(activeTreeIndex >= totalTreesCount - 1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(Color(hex: 0xFAF6ED).opacity(0.88))
        .overlay(Capsule().stroke(Color.white.opacity(0.85), lineWidth: 0.9))
        .clipShape(Capsule())
    }

    private var hudRightButtons: some View {
        HStack(spacing: 8) {
            Button {
                SensoryFeedbackService.shared.selection()
                showForestGallery = true
            } label: {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: 0x1D4432))
                    .frame(width: 38, height: 38)
                    .background(Color(hex: 0xFAF6ED).opacity(0.88))
                    .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 1))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.08), radius: 8, y: 3)
            }
            .buttonStyle(ScaleBounceButtonStyle(scale: 0.90))

            Button {
                SensoryFeedbackService.shared.selection()
                showSettingsSheet = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: 0x1D4432))
                    .frame(width: 38, height: 38)
                    .background(Color(hex: 0xFAF6ED).opacity(0.88))
                    .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 1))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.08), radius: 8, y: 3)
            }
            .buttonStyle(ScaleBounceButtonStyle(scale: 0.90))
        }
    }

    private func selectedLeafBanner(_ rec: ShineRecord) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(rec.title)
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundColor(Color(hex: 0x1D4432))
                    .lineLimit(1)
                Text(BotanicalTheme.formatRelativeDate(epochMs: rec.timestamp))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: 0x5B7A69))
            }
            Spacer()
            Button {
                withAnimation(.easeOut(duration: 0.18)) {
                    selectedRecord = nil
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color(hex: 0x9BB3A5))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(hex: 0xFAF6ED).opacity(0.94))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.9), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.09), radius: 10, y: 4)
    }

    private func performWatering() {
        guard !isWatering else { return }
        isWatering = true
        Task {
            let payload = await appState.celebrateFreely()
            await MainActor.run {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                    selectedRecord = nil
                    freeQuoteBanner = payload.quote
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                    isWatering = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) {
                    if freeQuoteBanner == payload.quote {
                        withAnimation(.easeOut(duration: 0.25)) {
                            freeQuoteBanner = nil
                        }
                    }
                }
            }
        }
    }

    private func triggerNewLeafCelebration(leafIndex: Int) {
        newestLeafIndex = leafIndex
        burstId += 1
        petalBurstId += 1
        rippleTrigger += 1
        SensoryFeedbackService.shared.celebrateGrand(
            soundEnabled: appState.soundEnabled,
            soundPack: appState.soundPack
        )

        showEnergyPulse = true
        energyPulseProgress = 0
        withAnimation(.easeOut(duration: 0.60)) {
            energyPulseProgress = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.80) {
            withAnimation(.easeOut(duration: 0.22)) {
                showEnergyPulse = false
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if newestLeafIndex == leafIndex {
                newestLeafIndex = nil
            }
        }
    }
}

// MARK: - 手绘水彩树干 + 水彩叶簇/星花逐片生长核心舞台

private struct WatercolorGrowthTreeView: View {
    let records: [ShineRecord]
    let species: ForestTreeSpecies
    let variant: ForestCosmicVariant
    let isMirrored: Bool
    let newestLeafIndex: Int?
    let rippleTrigger: Int
    let energyPulseProgress: CGFloat
    let showEnergyPulse: Bool
    let isNight: Bool
    let onTapCanopy: () -> Void
    let onSelectRecord: (ShineRecord) -> Void

    @State private var swayPhase: Bool = false
    @State private var tapShakeAngle: Double = 0

    private var visibleCount: Int { min(records.count, 100) }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let canopyDensity = min(1.0, Double(visibleCount) / 85.0)
            let activeSlots = Array(WatercolorLeafSlot.slots(for: species).prefix(visibleCount))

            ZStack {
                // 树根同色系地貌接地柔雾影
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                species.groundShadowPrimary.opacity(0.42),
                                species.groundShadowSecondary.opacity(0.20),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 8,
                            endRadius: w * 0.32
                        )
                    )
                    .frame(width: w * 0.58, height: 34)
                    .position(x: w * 0.50, y: h * 0.942)

                // 树冠背后柔和阳光/高阶变体氛围晕
                if visibleCount > 0 {
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [
                                    species.canopyGlowColor(isNight: isNight).opacity(isNight ? 0.28 : 0.46),
                                    variant.atmosphereTint,
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 16,
                                endRadius: w * 0.52
                            )
                        )
                        .frame(width: w * 1.02, height: h * 0.66)
                        .position(x: w * 0.50, y: h * 0.33)
                }

                // 1. 群落独立手绘水彩树干骨架（底端 4% 柔和羽化融地）
                Image(species.trunkImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: w * 0.94, height: h * 0.94)
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .white, location: 0.0),
                                .init(color: .white, location: 0.94),
                                .init(color: .white.opacity(0.25), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(x: isMirrored ? -1 : 1, y: 1)
                    .position(x: w * 0.50, y: h * 0.50)
                    .opacity(records.isEmpty ? 0.65 : 0.98)

                // 生态彩蛋 1（10 步解锁）：群落专属地面伴侣（蘑菇/松鼠/雪兔/熊猫/海鸥）
                if visibleCount >= 10 {
                    groundEasterEggLayer(w: w, h: h)
                }

                // 生态彩蛋 2（25 步解锁）：暖光树洞或林间萤火灯笼
                if visibleCount >= 25 {
                    midEasterEggLayer(w: w, h: h)
                }

                // 能量流沿树干上升
                if showEnergyPulse {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: 0xFFF3B0), Color(hex: 0xF5B942).opacity(0.45), .clear],
                                center: .center,
                                startRadius: 2,
                                endRadius: 28
                            )
                        )
                        .frame(width: 56, height: 56)
                        .position(
                            x: w * 0.49 + sin(energyPulseProgress * .pi) * 10,
                            y: h * (0.90 - energyPulseProgress * 0.56)
                        )
                }

                // 1.5 水彩树冠底晕层：随叶数增加渐显，让 100 叶时树冠整体饱满充盈
                if visibleCount >= 16 {
                    ZStack {
                        Ellipse()
                            .fill(species.canopyWashPrimary.opacity(0.26 * canopyDensity))
                            .frame(width: w * 0.84, height: h * 0.48)
                            .blur(radius: 18)
                            .position(x: w * 0.50, y: h * 0.32)

                        Ellipse()
                            .fill(species.canopyWashSecondary.opacity(0.22 * canopyDensity))
                            .frame(width: w * 0.66, height: h * 0.36)
                            .blur(radius: 14)
                            .position(x: w * 0.48, y: h * 0.27)
                    }
                    .allowsHitTesting(false)
                }

                // 2. 群落专属形态水彩叶簇逐片生长（1 次微步 = 1 簇手绘水彩叶）
                ForEach(activeSlots) { slot in
                    let isNewest = (newestLeafIndex == slot.id)
                    let matchingRec = slot.id < records.count ? records[slot.id] : nil
                    let mappedNx = isMirrored ? (1.0 - slot.nx) : slot.nx
                    let mappedAngle = isMirrored ? -slot.angle : slot.angle

                    WatercolorLeafNodeView(
                        species: species,
                        size: slot.size,
                        hueShift: slot.hueShift,
                        isStarBlossom: slot.isStarBlossom,
                        isNewest: isNewest,
                        rippleTrigger: isNewest ? rippleTrigger : 0
                    )
                    .rotationEffect(.degrees(mappedAngle + (swayPhase ? 3.6 : -3.6)))
                    .offset(y: swayPhase ? -1.4 : 1.4)
                    .position(x: mappedNx * w, y: slot.ny * h)
                    .onTapGesture {
                        if let rec = matchingRec {
                            onSelectRecord(rec)
                        } else {
                            triggerBreezeShake()
                        }
                    }
                }

                // 生态彩蛋 3（45 步解锁）：枝头蓝鹊 / 樱枝白鸽 / 松枝猫头鹰
                if visibleCount >= 45 {
                    canopyEasterEggLayer(w: w, h: h)
                }

                // 生态彩蛋 4（65 步解锁）：林间打盹红狐狸 / 好奇梅花小鹿 / 海岛石灯
                if visibleCount >= 65 {
                    companionAnimalLayer(w: w, h: h)
                }

                // 生态彩蛋 5（85 步解锁）：树下暖茶木桩与森林小篝火营地
                if visibleCount >= 85 {
                    campEasterEggLayer(w: w, h: h)
                }
            }
            .rotationEffect(.degrees(tapShakeAngle), anchor: .bottom)
            .contentShape(Rectangle())
            .onTapGesture {
                triggerBreezeShake()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.4).repeatForever(autoreverses: true)) {
                swayPhase = true
            }
        }
    }

    @ViewBuilder
    private func groundEasterEggLayer(w: CGFloat, h: CGFloat) -> some View {
        let isAnimal = (species == .autumnMaple || species == .winterPine || species == .bambooGrove || species == .islandPalm)
        let imgWidth: CGFloat = isAnimal ? min(w * 0.28, 114) : min(w * 0.46, 186)
        let posX: CGFloat = isAnimal
            ? w * (isMirrored ? 0.34 : 0.66)
            : w * (isMirrored ? 0.51 : 0.49)
        let posY: CGFloat = isAnimal ? h * 0.908 : h * 0.925

        if isAnimal {
            InteractiveEcoAnimal(
                imageName: species.groundEasterEggImage,
                width: imgWidth,
                isMirrored: isMirrored,
                breathPeriod: 2.8,
                tiltDegrees: 2.6,
                bobAmplitude: 2.0,
                isCrabWalk: false,
                onTapBonus: {
                    SensoryFeedbackService.shared.lightTap()
                }
            )
            .position(x: posX, y: posY)
            .transition(.scale(scale: 0.65, anchor: .bottom).combined(with: .opacity))
        } else {
            Image(species.groundEasterEggImage)
                .resizable()
                .scaledToFit()
                .frame(width: imgWidth)
                .scaleEffect(x: isMirrored ? -1 : 1, y: 1)
                .rotationEffect(.degrees(swayPhase ? 1.4 : -1.4), anchor: .bottom)
                .position(x: posX, y: posY)
                .allowsHitTesting(false)
                .transition(.scale(scale: 0.65, anchor: .bottom).combined(with: .opacity))
        }
    }

    @ViewBuilder
    private func midEasterEggLayer(w: CGFloat, h: CGFloat) -> some View {
        switch species.midEcoStyle {
        case .treeHollow:
            ZStack {
                CandleFlickerGlow(
                    primaryColor: Color(hex: 0xFFD97D),
                    secondaryColor: Color(hex: 0xF4A261),
                    baseOpacity: isNight ? 0.78 : 0.42,
                    size: isNight ? 96 : 72
                )

                Image("IllustTreeHollow")
                    .resizable()
                    .scaledToFit()
                    .frame(width: min(w * 0.15, 62))
                    .scaleEffect(x: isMirrored ? -1 : 1, y: 1)
            }
            .position(x: w * (isMirrored ? 0.515 : 0.485), y: h * 0.67)
            .allowsHitTesting(false)
            .transition(.scale(scale: 0.7).combined(with: .opacity))

        case .stoneLantern:
            ZStack {
                CandleFlickerGlow(
                    primaryColor: Color(hex: 0xFFE38A),
                    secondaryColor: Color(hex: 0xF4A261),
                    baseOpacity: isNight ? 0.88 : 0.52,
                    size: 74
                )
                .offset(y: -12)

                Image("IllustEcoStoneLantern")
                    .resizable()
                    .scaledToFit()
                    .frame(width: min(w * 0.16, 66))
            }
            .position(x: w * (isMirrored ? 0.84 : 0.16), y: h * 0.875)
            .allowsHitTesting(false)
            .transition(.scale(scale: 0.7, anchor: .bottom).combined(with: .opacity))

        case .beachCrab:
            InteractiveEcoAnimal(
                imageName: "IllustEcoCrab",
                width: min(w * 0.23, 94),
                isMirrored: isMirrored,
                breathPeriod: 2.2,
                tiltDegrees: 3.4,
                bobAmplitude: 1.8,
                isCrabWalk: true,
                onTapBonus: {
                    SensoryFeedbackService.shared.lightTap()
                }
            )
            .position(x: w * (isMirrored ? 0.80 : 0.20), y: h * 0.918)
            .transition(.scale(scale: 0.7, anchor: .bottom).combined(with: .opacity))
        }
    }

    private func canopyEasterEggLayer(w: CGFloat, h: CGFloat) -> some View {
        let baseX: CGFloat = (species == .islandPalm) ? 0.66 : 0.74
        let baseY: CGFloat = (species == .islandPalm) ? 0.14 : 0.21
        let posX = w * (isMirrored ? (1.0 - baseX) : baseX)

        return InteractiveEcoAnimal(
            imageName: species.canopyEasterEggImage,
            width: min(w * 0.22, 88),
            isMirrored: isMirrored,
            breathPeriod: 2.4,
            tiltDegrees: 4.0,
            bobAmplitude: 4.5,
            isCrabWalk: false,
            onTapBonus: {
                triggerBreezeShake()
            }
        )
        .position(x: posX, y: h * baseY)
        .transition(.scale(scale: 0.6).combined(with: .opacity))
    }

    private func companionAnimalLayer(w: CGFloat, h: CGFloat) -> some View {
        let isLantern = (species == .islandPalm)
        let imgW: CGFloat = isLantern ? min(w * 0.15, 60) : min(w * 0.22, 90)
        // 按群落分流站位，彻底避开背景小芽精灵、石灯笼与螃蟹
        let rawX: CGFloat = {
            switch species {
            case .ancientOak:
                return 0.63 // 避开左下角背景小新芽精灵，放在树根与右营地之间
            case .weepingSakura, .winterPine, .islandPalm:
                return 0.34 // 避开最左侧 0.16~0.20 的石灯笼或螃蟹
            case .autumnMaple, .bambooGrove:
                return 0.21 // 右侧已有 0.66 松鼠/熊猫，放左草地对称呼应
            }
        }()
        let posX = w * (isMirrored ? (1.0 - rawX) : rawX)
        let posY = h * (isLantern ? 0.865 : (species == .ancientOak ? 0.902 : 0.892))

        return Group {
            if isLantern {
                ZStack {
                    CandleFlickerGlow(
                        primaryColor: Color(hex: 0xFFE38A),
                        secondaryColor: Color(hex: 0xF4A261),
                        baseOpacity: isNight ? 0.88 : 0.52,
                        size: 70
                    )
                    .offset(y: -10)

                    Image(species.companionAnimalImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: imgW)
                }
                .allowsHitTesting(false)
            } else {
                InteractiveEcoAnimal(
                    imageName: species.companionAnimalImage,
                    width: imgW,
                    isMirrored: isMirrored,
                    breathPeriod: 2.6,
                    tiltDegrees: 2.8,
                    bobAmplitude: 2.2,
                    isCrabWalk: false,
                    onTapBonus: {
                        SensoryFeedbackService.shared.lightTap()
                    }
                )
            }
        }
        .position(x: posX, y: posY)
        .transition(.scale(scale: 0.7, anchor: .bottom).combined(with: .opacity))
    }

    private func campEasterEggLayer(w: CGFloat, h: CGFloat) -> some View {
        let posX = w * (isMirrored ? 0.17 : 0.83)
        return ZStack {
            CandleFlickerGlow(
                primaryColor: Color(hex: 0xFFB74D),
                secondaryColor: Color(hex: 0xFF8A65),
                baseOpacity: isNight ? 0.82 : 0.45,
                size: 84
            )
            .offset(x: 8, y: 4)

            Image(species.campEasterEggImage)
                .resizable()
                .scaledToFit()
                .frame(width: min(w * 0.25, 102))
                .scaleEffect(x: isMirrored ? -1 : 1, y: 1)

            CampSmokeAndSparksOverlay(isMirrored: isMirrored)
                .frame(width: 96, height: 86)
                .offset(y: -36)
                .allowsHitTesting(false)
        }
        .position(x: posX, y: h * 0.895)
        .allowsHitTesting(false)
        .transition(.scale(scale: 0.7, anchor: .bottom).combined(with: .opacity))
    }

    private func triggerBreezeShake() {
        SensoryFeedbackService.shared.selection()
        onTapCanopy()
        withAnimation(.spring(response: 0.24, dampingFraction: 0.46)) {
            tapShakeAngle = 1.8
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.spring(response: 0.46, dampingFraction: 0.42)) {
                tapShakeAngle = 0
            }
        }
    }
}

// MARK: - 单簇手绘水彩叶 & 星花果节点（含新叶萌芽弹跳 + 金色光环涟漪 + 树种自适应染色）

private struct WatercolorLeafNodeView: View {
    let species: ForestTreeSpecies
    let size: CGFloat
    let hueShift: Double
    let isStarBlossom: Bool
    let isNewest: Bool
    let rippleTrigger: Int

    @State private var popScale: CGFloat = 1.0
    @State private var ringScale: CGFloat = 0.35
    @State private var ringOpacity: Double = 0

    var body: some View {
        ZStack {
            if ringOpacity > 0.01 {
                Circle()
                    .stroke(species.ringColor, lineWidth: 2.0)
                    .frame(width: size * 0.9, height: size * 0.9)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)
            }

            Image(species.leafImageName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .hueRotation(.degrees(hueShift * 0.35))
                .saturation(species.leafSaturation)

            if isStarBlossom {
                Image("IllustStarBlossom")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.54, height: size * 0.54)
                    .hueRotation(.degrees(species.blossomHueShift))
                    .shadow(color: species.blossomGlow.opacity(0.72), radius: 5)
                    .offset(x: size * 0.12, y: -size * 0.08)
            }
        }
        .scaleEffect(popScale)
        .onAppear {
            if isNewest { playSproutPop() }
        }
        .onChange(of: rippleTrigger) { _ in
            if isNewest { playSproutPop() }
        }
    }

    private func playSproutPop() {
        popScale = 0.08
        ringScale = 0.35
        ringOpacity = 0.95
        withAnimation(.spring(response: 0.46, dampingFraction: 0.48)) {
            popScale = 1.0
        }
        withAnimation(.easeOut(duration: 0.72)) {
            ringScale = 2.0
            ringOpacity = 0.0
        }
    }
}

// MARK: - 微风飘落花瓣特效层

private struct DriftingPetalsOverlay: View {
    let triggerId: Int
    let species: ForestTreeSpecies
    @State private var falling: Bool = false
    @State private var visible: Bool = false

    var body: some View {
        GeometryReader { geo in
            if visible {
                ZStack {
                    ForEach(0..<10, id: \.self) { idx in
                        let startX = geo.size.width * (0.20 + CGFloat(idx) * 0.068)
                        let startY = geo.size.height * (0.24 + CGFloat(idx % 3) * 0.08)
                        Ellipse()
                            .fill(idx % 2 == 0 ? species.petalPrimary : species.petalSecondary)
                            .frame(width: 9.5, height: 5.8)
                            .rotationEffect(.degrees(falling ? Double(idx * 55 + 140) : Double(idx * 25)))
                            .position(
                                x: startX + (falling ? CGFloat((idx % 2 == 0 ? 1 : -1) * 52) : 0),
                                y: startY + (falling ? 210 + CGFloat(idx * 14) : 0)
                            )
                            .opacity(falling ? 0.0 : 0.88)
                    }
                }
            }
        }
        .onChange(of: triggerId) { _ in
            visible = true
            falling = false
            withAnimation(.easeOut(duration: 1.6)) {
                falling = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.65) {
                visible = false
            }
        }
    }
}

// MARK: - 星夜萤火微粒氛围层

private struct NightFireflyLayer: View {
    @State private var pulse: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<10, id: \.self) { i in
                    let x = geo.size.width * CGFloat(0.12 + Double((i * 23) % 76) / 100.0)
                    let y = geo.size.height * CGFloat(0.20 + Double((i * 19) % 58) / 100.0)
                    Circle()
                        .fill(Color(hex: 0xFFE68F))
                        .frame(width: i % 2 == 0 ? 4.5 : 3.2, height: i % 2 == 0 ? 4.5 : 3.2)
                        .shadow(color: Color(hex: 0xFFD257), radius: 5)
                        .position(x: x, y: y + (pulse ? -8 : 8))
                        .opacity(pulse ? (i % 2 == 0 ? 0.85 : 0.35) : (i % 2 == 0 ? 0.30 : 0.80))
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

/// 群落常态自然氛围粒子（慢速飘雪 / 樱瓣 / 秋枫 / 春叶微光，30fps 轻量 Canvas 绘制）
private struct AmbientBiomeParticlesLayer: View {
    let species: ForestTreeSpecies

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let count = 9
                for i in 0..<count {
                    let seed = Double(i) * 1.73 + 0.5
                    let speed = 0.032 + Double(i % 4) * 0.008
                    let progress = (t * speed + seed * 0.19).truncatingRemainder(dividingBy: 1.0)
                    let baseX = size.width * CGFloat((Double(i) + 0.5) / Double(count))
                    let sway = CGFloat(sin(t * 1.1 + seed * 2.4) * 22.0)
                    let x = baseX + sway
                    let y = CGFloat(progress) * (size.height + 40) - 20
                    let color = (i % 2 == 0) ? species.petalPrimary : species.petalSecondary

                    var sub = ctx
                    sub.translateBy(x: x, y: y)
                    sub.rotate(by: .radians(t * 0.7 + seed))
                    if species == .winterPine {
                        let r = CGFloat(2.4 + Double(i % 3) * 0.9)
                        sub.fill(Path(ellipseIn: CGRect(x: -r, y: -r, width: r * 2, height: r * 2)), with: .color(color.opacity(0.65)))
                    } else {
                        let w = CGFloat(6.5 + Double(i % 3) * 2.2)
                        let h = CGFloat(4.2 + Double(i % 2) * 1.5)
                        sub.fill(Path(ellipseIn: CGRect(x: -w / 2, y: -h / 2, width: w, height: h)), with: .color(color.opacity(0.58)))
                    }
                }
            }
        }
    }
}

// MARK: - 吉卜力动画片式双关键帧角色 + 飘云与扇翅飞舞蝴蝶（零畸变、自适应 120fps）

private struct InteractiveEcoAnimal: View {
    let imageName: String
    let width: CGFloat
    let isMirrored: Bool
    let breathPeriod: Double
    let tiltDegrees: Double
    let bobAmplitude: CGFloat
    let isCrabWalk: Bool
    let onTapBonus: () -> Void

    @State private var isTappedAction: Bool = false
    @State private var heartProgress: CGFloat = 0
    @State private var showHeart: Bool = false

    private var frame2Name: String { "\(imageName)Frame2" }
    private var hasFrame2: Bool { UIImage(named: frame2Name) != nil }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let cycle = max(2.2, breathPeriod)
            let localT = t.truncatingRemainder(dividingBy: cycle)
            // 自然动画片节拍：大部分时间保持 Frame 1，周期内眨眼/动作一次（偶有轻快双连眨），持续 0.34s
            let autoFrame2 = (localT > (cycle - 0.42) && localT < (cycle - 0.08))
                || (localT > (cycle - 0.78) && localT < (cycle - 0.58) && Int(t / cycle) % 3 == 0)
            let showFrame2 = hasFrame2 && (isTappedAction || autoFrame2)

            // 仅海滩螃蟹保留极轻微的横向沙地踱步（不拉伸不变形）
            let walkX: CGFloat = isCrabWalk ? CGFloat(sin(t * 1.1) * 5.0) : 0

            ZStack(alignment: .top) {
                ZStack {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: width)
                        .opacity(showFrame2 ? 0 : 1)

                    if hasFrame2 {
                        Image(frame2Name)
                            .resizable()
                            .scaledToFit()
                            .frame(width: width)
                            .opacity(showFrame2 ? 1 : 0)
                    }
                }
                .scaleEffect(x: isMirrored ? -1.0 : 1.0, y: 1.0)
                .offset(x: walkX)

                if showHeart {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: 0xF27D72))
                        .shadow(color: .white.opacity(0.85), radius: 3)
                        .offset(x: walkX, y: -8 - heartProgress * 26)
                        .scaleEffect(0.75 + heartProgress * 0.35)
                        .opacity(Double(1.0 - heartProgress))
                        .allowsHitTesting(false)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            triggerAnimalAction()
        }
    }

    private func triggerAnimalAction() {
        onTapBonus()
        isTappedAction = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            isTappedAction = false
        }

        heartProgress = 0
        showHeart = true
        withAnimation(.easeOut(duration: 0.85)) {
            heartProgress = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.88) {
            showHeart = false
        }
    }
}

/// 天空缓缓飘过的水彩软云 + 树间翩翩扇翅飞舞的小蝴蝶（营造吉卜力动画片大场景氛围）
private struct DriftingCloudsAndButterfliesLayer: View {
    let species: ForestTreeSpecies
    let isNight: Bool

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                // 1. 天空缓缓飘过的 2 朵极淡柔和云朵
                let cloudAlpha = isNight ? 0.08 : 0.24
                for i in 0..<2 {
                    let speed = 0.008 + Double(i) * 0.004
                    let prog = (t * speed + Double(i) * 0.48).truncatingRemainder(dividingBy: 1.0)
                    let cx = (prog * (size.width + 180)) - 90
                    let cy = size.height * (0.16 + CGFloat(i) * 0.09)
                    let w: CGFloat = 110 + CGFloat(i) * 36
                    let h: CGFloat = 28 + CGFloat(i) * 8

                    ctx.fill(
                        Path(ellipseIn: CGRect(x: cx - w * 0.5, y: cy - h * 0.5, width: w, height: h)),
                        with: .color(Color.white.opacity(cloudAlpha))
                    )
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: cx - w * 0.26, y: cy - h * 0.85, width: w * 0.52, height: h * 0.95)),
                        with: .color(Color.white.opacity(cloudAlpha * 0.85))
                    )
                }

                // 2. 树冠与花丛间翩翩飞舞的 2 只扇翅小蝴蝶（冬雪松夜空跳过蝴蝶）
                if species != .winterPine {
                    let butterflyColors: [Color] = [
                        Color(hex: 0xFAD2E1),
                        Color(hex: 0xFFE5A3)
                    ]
                    for b in 0..<2 {
                        let speed = 0.22 + Double(b) * 0.07
                        let phase = t * speed + Double(b) * 2.1
                        let centerX: CGFloat = size.width * (b == 0 ? 0.34 : 0.68)
                        let centerY: CGFloat = size.height * (b == 0 ? 0.52 : 0.62)
                        let dx1: Double = sin(phase) * 58.0
                        let dx2: Double = cos(phase * 1.7) * 18.0
                        let dy1: Double = cos(phase * 1.3) * 34.0
                        let dy2: Double = sin(phase * 2.3) * 12.0
                        let bx: CGFloat = centerX + CGFloat(dx1 + dx2)
                        let by: CGFloat = centerY + CGFloat(dy1 + dy2)

                        // 翅膀高频扇合（0.25 ~ 1.0）
                        let flapPhase: Double = abs(sin(t * (9.5 + Double(b) * 1.5)))
                        let flap: CGFloat = CGFloat(0.28 + 0.72 * flapPhase)
                        let headingAngle: Double = atan2(cos(phase * 1.3), cos(phase)) * 0.35

                        var sub = ctx
                        sub.translateBy(x: bx, y: by)
                        sub.rotate(by: .radians(headingAngle))

                        let wingColor = butterflyColors[b].opacity(isNight ? 0.72 : 0.88)
                        let wingStroke = Color(hex: 0x8D6E63).opacity(0.45)

                        // 左翅
                        let leftWing = Path(ellipseIn: CGRect(x: -7.5 * flap, y: -5.5, width: 7.5 * flap, height: 10.5))
                        sub.fill(leftWing, with: .color(wingColor))
                        sub.stroke(leftWing, with: .color(wingStroke), lineWidth: 0.7)

                        // 右翅
                        let rightWing = Path(ellipseIn: CGRect(x: 0, y: -5.5, width: 7.5 * flap, height: 10.5))
                        sub.fill(rightWing, with: .color(wingColor))
                        sub.stroke(rightWing, with: .color(wingStroke), lineWidth: 0.7)

                        // 细小身体
                        sub.fill(
                            Path(roundedRect: CGRect(x: -0.9, y: -4.0, width: 1.8, height: 8.0), cornerSize: CGSize(width: 0.9, height: 0.9)),
                            with: .color(Color(hex: 0x5D4037).opacity(0.75))
                        )
                    }
                }
            }
        }
    }
}

/// 石灯笼 / 树洞 / 篝火双频摇曳暖光
private struct CandleFlickerGlow: View {
    let primaryColor: Color
    let secondaryColor: Color
    let baseOpacity: Double
    let size: CGFloat

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let flicker = sin(t * 4.2) * 0.5 + sin(t * 7.6 + 1.1) * 0.5
            let scale = 0.94 + CGFloat(flicker) * 0.08
            let opacity = max(0.25, min(1.0, baseOpacity + flicker * 0.14))

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            primaryColor.opacity(opacity),
                            secondaryColor.opacity(opacity * 0.36),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 3,
                        endRadius: size * 0.5
                    )
                )
                .frame(width: size, height: size)
                .scaleEffect(scale)
        }
    }
}

/// 暖茶篝火营地袅袅上升白烟与微弱火星光点
private struct CampSmokeAndSparksOverlay: View {
    let isMirrored: Bool

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let dir: CGFloat = isMirrored ? -1.0 : 1.0

                // 3 缕柔和白烟（热茶与篝火）
                for i in 0..<3 {
                    let phase = (t * 0.38 + Double(i) * 0.33).truncatingRemainder(dividingBy: 1.0)
                    let baseX = size.width * (i == 0 ? 0.36 : 0.62)
                    let x = (isMirrored ? size.width - baseX : baseX) + CGFloat(sin(phase * 2.0 * .pi + Double(i)) * 4.5) * dir
                    let y = size.height * (0.85 - CGFloat(phase) * 0.72)
                    let r = CGFloat(4.5 + phase * 7.5)
                    let alpha = sin(phase * .pi) * 0.34
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: x - r, y: y - r * 0.72, width: r * 2, height: r * 1.44)),
                        with: .color(Color.white.opacity(alpha))
                    )
                }

                // 3 颗上升火星光点
                for i in 0..<3 {
                    let phase = (t * 0.62 + Double(i) * 0.31 + 0.15).truncatingRemainder(dividingBy: 1.0)
                    let rawX = size.width * (0.58 + CGFloat(i) * 0.05)
                    let x = (isMirrored ? size.width - rawX : rawX) + CGFloat(cos(phase * 3.0 * .pi + Double(i)) * 5.0)
                    let y = size.height * (0.88 - CGFloat(phase) * 0.78)
                    let r = CGFloat(1.8 * (1.0 - phase * 0.5))
                    let alpha = sin(phase * .pi) * 0.85
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                        with: .color(Color(hex: 0xFFD166).opacity(alpha))
                    )
                }
            }
        }
    }
}
