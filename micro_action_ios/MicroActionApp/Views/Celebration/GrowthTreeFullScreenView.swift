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

            // 4. 极简悬浮 HUD
            VStack(spacing: 0) {
                topHudBar(isNight: amb.isNight)
                    .padding(.horizontal, 18)
                    .padding(.top, 10)

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
                    .padding(.top, 8)
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
                    .padding(.top, 8)
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
        return HStack(alignment: .center) {
            hudCloseButton
            Spacer()
            hudCenterTitle(titleColor: titleColor)
            Spacer()
            hudRightButtons
        }
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

    private func hudCenterTitle(titleColor: Color) -> some View {
        let countText = "\(currentTreeRecords.count)/\(leavesPerTree)"
        let speciesTitle = currentVariant.prefixTitle.map { "\($0)·\(currentSpecies.displayName)" } ?? currentSpecies.displayName
        let infoText: String = totalTreesCount > 1
            ? "第 \(activeTreeIndex + 1)/\(totalTreesCount) 棵 · \(speciesTitle) · \(countText)"
            : "\(speciesTitle) · \(stageTitle) · \(countText)"

        return VStack(spacing: 4) {
            Text("微步成长树")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(titleColor)

            HStack(spacing: 6) {
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
            .padding(.vertical, 4.5)
            .background(Color(hex: 0xFAF6ED).opacity(0.88))
            .overlay(Capsule().stroke(Color.white.opacity(0.85), lineWidth: 0.9))
            .clipShape(Capsule())
        }
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
                    .rotationEffect(.degrees(mappedAngle + (swayPhase ? 2.4 : -2.4)))
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

        Image(species.groundEasterEggImage)
            .resizable()
            .scaledToFit()
            .frame(width: imgWidth)
            .scaleEffect(x: isMirrored ? -1 : 1, y: 1)
            .position(x: posX, y: posY)
            .allowsHitTesting(false)
            .transition(.scale(scale: 0.65, anchor: .bottom).combined(with: .opacity))
    }

    @ViewBuilder
    private func midEasterEggLayer(w: CGFloat, h: CGFloat) -> some View {
        switch species.midEcoStyle {
        case .treeHollow:
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: 0xFFD97D).opacity(isNight ? 0.72 : 0.36),
                                Color(hex: 0xF4A261).opacity(isNight ? 0.28 : 0.12),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 4,
                            endRadius: isNight ? 46 : 34
                        )
                    )
                    .frame(width: isNight ? 92 : 68, height: isNight ? 92 : 68)

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
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: 0xFFE38A).opacity(isNight ? 0.85 : 0.44),
                                Color(hex: 0xF4A261).opacity(0.18),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 2,
                            endRadius: 34
                        )
                    )
                    .frame(width: 68, height: 68)
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
            Image("IllustEcoCrab")
                .resizable()
                .scaledToFit()
                .frame(width: min(w * 0.23, 94))
                .scaleEffect(x: isMirrored ? -1 : 1, y: 1)
                .position(x: w * (isMirrored ? 0.80 : 0.20), y: h * 0.918)
                .allowsHitTesting(false)
                .transition(.scale(scale: 0.7, anchor: .bottom).combined(with: .opacity))
        }
    }

    private func canopyEasterEggLayer(w: CGFloat, h: CGFloat) -> some View {
        let baseX: CGFloat = (species == .islandPalm) ? 0.66 : 0.74
        let baseY: CGFloat = (species == .islandPalm) ? 0.14 : 0.21
        let posX = w * (isMirrored ? (1.0 - baseX) : baseX)

        return Image(species.canopyEasterEggImage)
            .resizable()
            .scaledToFit()
            .frame(width: min(w * 0.22, 88))
            .scaleEffect(x: isMirrored ? -1 : 1, y: 1)
            .rotationEffect(.degrees(swayPhase ? 1.8 : -1.8))
            .offset(y: swayPhase ? -3.5 : 3.5)
            .position(x: posX, y: h * baseY)
            .onTapGesture {
                triggerBreezeShake()
            }
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

        return Image(species.companionAnimalImage)
            .resizable()
            .scaledToFit()
            .frame(width: imgW)
            .scaleEffect(x: isMirrored ? -1 : 1, y: 1)
            .position(x: posX, y: posY)
            .allowsHitTesting(false)
            .transition(.scale(scale: 0.7, anchor: .bottom).combined(with: .opacity))
    }

    private func campEasterEggLayer(w: CGFloat, h: CGFloat) -> some View {
        let posX = w * (isMirrored ? 0.17 : 0.83)
        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: 0xFFB74D).opacity(isNight ? 0.75 : 0.36),
                            Color(hex: 0xFF8A65).opacity(0.14),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 4,
                        endRadius: 38
                    )
                )
                .frame(width: 76, height: 76)
                .scaleEffect(swayPhase ? 1.08 : 0.94)
                .offset(x: 8, y: 4)

            Image(species.campEasterEggImage)
                .resizable()
                .scaledToFit()
                .frame(width: min(w * 0.25, 102))
                .scaleEffect(x: isMirrored ? -1 : 1, y: 1)
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
