import SwiftUI

/// 森林多树种轮换定义（每满 100 步换一种截然不同的水彩树种与枝桠走向）
private enum ForestTreeSpecies: Int, CaseIterable {
    case springSprout = 0   // 第 1 棵：春日翠绿新芽树
    case sakuraBlossom = 1  // 第 2 棵：樱花暖粉花树
    case autumnGinkgo = 2   // 第 3 棵：秋日鎏金银杏树
    case starryBluebell = 3 // 第 4 棵：星夜蓝铃梦幻树

    static func forIndex(_ index: Int) -> ForestTreeSpecies {
        let safeIdx = max(0, index) % allCases.count
        return ForestTreeSpecies(rawValue: safeIdx) ?? .springSprout
    }

    var displayName: String {
        switch self {
        case .springSprout: return "春日新芽树"
        case .sakuraBlossom: return "樱花暖粉树"
        case .autumnGinkgo: return "鎏金银杏树"
        case .starryBluebell: return "星夜蓝铃树"
        }
    }

    /// 奇数棵镜像树干与枝桠走向，让连续两棵树形态也不重复
    var mirrorTrunk: Bool {
        rawValue % 2 == 1
    }

    var trunkHue: Double {
        switch self {
        case .springSprout: return 0
        case .sakuraBlossom: return -14
        case .autumnGinkgo: return 10
        case .starryBluebell: return 165
        }
    }

    var trunkSaturation: Double {
        switch self {
        case .springSprout: return 1.0
        case .sakuraBlossom: return 0.78
        case .autumnGinkgo: return 1.08
        case .starryBluebell: return 0.52
        }
    }

    var trunkBrightness: Double {
        switch self {
        case .springSprout: return 0
        case .sakuraBlossom: return -0.04
        case .autumnGinkgo: return -0.02
        case .starryBluebell: return 0.04
        }
    }

    var leafHueBase: Double {
        switch self {
        case .springSprout: return 0
        case .sakuraBlossom: return 158
        case .autumnGinkgo: return -74
        case .starryBluebell: return 106
        }
    }

    var leafSaturation: Double {
        switch self {
        case .springSprout: return 1.06
        case .sakuraBlossom: return 0.88
        case .autumnGinkgo: return 1.12
        case .starryBluebell: return 0.94
        }
    }

    var leafBrightness: Double {
        switch self {
        case .springSprout: return 0
        case .sakuraBlossom: return 0.08
        case .autumnGinkgo: return 0.05
        case .starryBluebell: return 0.04
        }
    }

    var leafMultiply: Color {
        switch self {
        case .springSprout: return .white
        case .sakuraBlossom: return Color(hex: 0xFFE6EE)
        case .autumnGinkgo: return Color(hex: 0xFFF2CC)
        case .starryBluebell: return Color(hex: 0xE6F1FF)
        }
    }

    var blossomHueShift: Double {
        switch self {
        case .springSprout: return 0
        case .sakuraBlossom: return -38
        case .autumnGinkgo: return -12
        case .starryBluebell: return 165
        }
    }

    var blossomGlow: Color {
        switch self {
        case .springSprout: return Color(hex: 0xFFD15C)
        case .sakuraBlossom: return Color(hex: 0xFF9EB5)
        case .autumnGinkgo: return Color(hex: 0xFFB84D)
        case .starryBluebell: return Color(hex: 0x99C7FF)
        }
    }

    var ringColor: Color {
        switch self {
        case .springSprout: return Color(hex: 0xFFD966)
        case .sakuraBlossom: return Color(hex: 0xFFA6BE)
        case .autumnGinkgo: return Color(hex: 0xFFC857)
        case .starryBluebell: return Color(hex: 0x9CC8FF)
        }
    }

    var canopyWashPrimary: Color {
        switch self {
        case .springSprout: return Color(hex: 0x7BC47F)
        case .sakuraBlossom: return Color(hex: 0xF5B5C8)
        case .autumnGinkgo: return Color(hex: 0xF2B949)
        case .starryBluebell: return Color(hex: 0x89B5EC)
        }
    }

    var canopyWashSecondary: Color {
        switch self {
        case .springSprout: return Color(hex: 0xA8DC8C)
        case .sakuraBlossom: return Color(hex: 0xFAD7E2)
        case .autumnGinkgo: return Color(hex: 0xF7D774)
        case .starryBluebell: return Color(hex: 0xB3C7F7)
        }
    }

    func canopyGlowColor(isNight: Bool) -> Color {
        switch self {
        case .springSprout: return isNight ? Color(hex: 0x8DE4AF) : Color(hex: 0xEEF9D6)
        case .sakuraBlossom: return isNight ? Color(hex: 0xF4B2C9) : Color(hex: 0xFFE6EE)
        case .autumnGinkgo: return isNight ? Color(hex: 0xF5C26B) : Color(hex: 0xFFF2C9)
        case .starryBluebell: return isNight ? Color(hex: 0x9EC5FF) : Color(hex: 0xE2EEFF)
        }
    }

    var petalPrimary: Color {
        switch self {
        case .springSprout: return Color(hex: 0xF7C6CF)
        case .sakuraBlossom: return Color(hex: 0xF7A8BD)
        case .autumnGinkgo: return Color(hex: 0xF5C249)
        case .starryBluebell: return Color(hex: 0x99BFFF)
        }
    }

    var petalSecondary: Color {
        switch self {
        case .springSprout: return Color(hex: 0xB8E0B6)
        case .sakuraBlossom: return Color(hex: 0xFFF1F5)
        case .autumnGinkgo: return Color(hex: 0xF29A4B)
        case .starryBluebell: return Color(hex: 0xE5EEFF)
        }
    }
}

/// 全屏沉浸式「微步成长树 2.0」独立页面
/// 同画风手绘水彩树干 + 水彩叶簇/星花逐片生长 + 每 100 步成林切换 + CoreHaptics 0.6s 长震动浇灌 + 昼夜自适应天光
struct GrowthTreeFullScreenView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var showSettingsSheet: Bool = false
    @State private var selectedTreeIndex: Int? = nil // nil 表示当前正在成长的最新一卷
    @State private var overrideScene: ShineWorldScene? = nil // 允许随时自由切换 4 大治愈世界预览
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

    private var currentScene: ShineWorldScene {
        overrideScene ?? (ShineWorldScene(rawValue: activeTreeIndex % ShineWorldScene.allCases.count) ?? .growthTree)
    }

    private var currentSeasonPalette: ShineSeasonPalette {
        ShineSeasonPalette.forVolume(activeTreeIndex)
    }

    private var currentTreeRecords: [ShineRecord] {
        let start = activeTreeIndex * leavesPerTree
        let end = min(start + leavesPerTree, chronologicalRecords.count)
        guard start < end else { return [] }
        return Array(chronologicalRecords[start..<end])
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
            // 1 & 2. 4 大微步治愈世界主舞台（× 4 季色盘 = 16 种不重样画卷）
            switch currentScene {
            case .growthTree:
                GeometryReader { geo in
                    Image("IllustGrowthTreeBg")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .overlay(amb.overlay)
                }
                .ignoresSafeArea()

                if amb.isNight {
                    NightFireflyLayer()
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }

                GeometryReader { geo in
                    let treeWidth = min(geo.size.width * 0.94, 410)
                    let treeHeight = min(geo.size.height * 0.62, 520)
                    let treeCenterX = geo.size.width * 0.53
                    let treeCenterY = geo.size.height * 0.57

                    WatercolorGrowthTreeView(
                        records: currentTreeRecords,
                        species: currentSpecies,
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

            case .starryLanternSea:
                StarryLanternSeaSceneView(
                    records: currentTreeRecords,
                    palette: currentSeasonPalette,
                    newestIndex: newestLeafIndex,
                    onSelectRecord: selectAction
                )
                .ignoresSafeArea()

            case .crystalTerrarium:
                CrystalTerrariumSceneView(
                    records: currentTreeRecords,
                    palette: currentSeasonPalette,
                    newestIndex: newestLeafIndex,
                    onSelectRecord: selectAction
                )
                .ignoresSafeArea()

            case .auroraConstellation:
                AuroraConstellationSceneView(
                    records: currentTreeRecords,
                    palette: currentSeasonPalette,
                    newestIndex: newestLeafIndex,
                    onSelectRecord: selectAction
                )
                .ignoresSafeArea()
            }

            // 3. 星芒粒子层
            StarburstParticleLayer(burstId: burstId, isGrand: true)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // 4. 极简悬浮 HUD
            VStack(spacing: 0) {
                topHudBar(isNight: amb.isNight || currentScene.isDarkCanvas)
                    .padding(.horizontal, 18)
                    .padding(.top, 10)

                // 4 大治愈世界自由切换微胶囊条
                worldSceneSwitcherBar
                    .padding(.top, 10)
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
                    .padding(.top, 7)
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

                // 底部 0.6s 拟物棘轮长震动仪式按钮（文案随当前治愈世界自适应）
                ChargeToShineButton(
                    label: currentScene.waterActionLabel,
                    chargingLabel: "星光汇聚中...",
                    completedLabel: "此刻已发光",
                    allowQuickTapClose: true,
                    accentColor: currentScene.isDarkCanvas ? Color(hex: 0xF5E3B8).opacity(0.94) : Color(hex: 0xE5F4E8).opacity(0.94),
                    secondaryAccentColor: currentScene.isDarkCanvas ? Color(hex: 0xE8C882).opacity(0.94) : Color(hex: 0xCDE7D3).opacity(0.94),
                    borderColor: currentScene.isDarkCanvas ? Color(hex: 0xFFF3D4).opacity(0.85) : Color(hex: 0xA4CBAE).opacity(0.85),
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

            Spacer()

            VStack(spacing: 4) {
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
                        .fill(Color(hex: 0xE07A38))
                        .frame(width: 6, height: 6)

                    Text(
                        totalTreesCount > 1
                            ? "第 \(activeTreeIndex + 1)/\(totalTreesCount) 卷 · \(currentSeasonPalette.seasonTitle)\(currentScene.shortName) · \(currentTreeRecords.count)/\(leavesPerTree)"
                            : "\(currentSeasonPalette.seasonTitle)\(currentScene.shortName) · \(currentTreeRecords.count)/\(leavesPerTree)"
                    )
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: 0x3D5E4C))
                    .contentTransition(.numericText())

                    if totalTreesCount > 1 {
                        Button {
                            SensoryFeedbackService.shared.selection()
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                                selectedTreeIndex = min(totalTreesCount - 1, activeTreeIndex + 1)
                                overrideScene = nil
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

            Spacer()

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

    private var worldSceneSwitcherBar: some View {
        HStack(spacing: 6) {
            ForEach(ShineWorldScene.allCases) { scene in
                let isSelected = (currentScene == scene)
                Button {
                    SensoryFeedbackService.shared.selection()
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                        overrideScene = scene
                        selectedRecord = nil
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: scene.iconName)
                            .font(.system(size: 10, weight: .bold))
                        Text(scene.shortName)
                            .font(.system(size: 11, weight: isSelected ? .bold : .semibold))
                    }
                    .foregroundColor(
                        isSelected
                            ? (currentScene.isDarkCanvas ? Color(hex: 0x1A2E25) : .white)
                            : (currentScene.isDarkCanvas ? Color.white.opacity(0.82) : Color(hex: 0x3D5E4C))
                    )
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5.5)
                    .background(
                        Capsule()
                            .fill(
                                isSelected
                                    ? (currentScene.isDarkCanvas ? Color(hex: 0xF5E3B8) : Color(hex: 0x2D6A4F))
                                    : (currentScene.isDarkCanvas ? Color.white.opacity(0.14) : Color(hex: 0xFAF6ED).opacity(0.82))
                            )
                    )
                }
                .buttonStyle(ScaleBounceButtonStyle(scale: 0.94))
            }
        }
    }

    private func selectedLeafBanner(_ rec: ShineRecord) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: 0xD96B27))
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

    private struct WatercolorLeafSlot: Identifiable {
        let id: Int
        let nx: CGFloat
        let ny: CGFloat
        let angle: Double
        let size: CGFloat
        let hueShift: Double
        let isStarBlossom: Bool
    }

    /// 100 个精准贴合 IllustTreeTrunk 全幅枝桠的水彩叶簇锚点（100 叶时饱满覆满整棵树冠）
    private static let allSlots: [WatercolorLeafSlot] = {
        var slots: [WatercolorLeafSlot] = []
        // 前 12 片落在主枝梢与中心冠层，初生期即有层次感
        let earlyPts: [(CGFloat, CGFloat, Double, CGFloat)] = [
            (0.49, 0.42, -12, 60), (0.35, 0.39, -38, 58), (0.64, 0.38, 32, 60),
            (0.24, 0.33, -52, 58), (0.76, 0.32, 46, 58), (0.50, 0.25, 6, 62),
            (0.38, 0.23, -24, 60), (0.62, 0.22, 22, 60), (0.16, 0.42, -64, 56),
            (0.84, 0.41, 58, 56), (0.49, 0.12, -4, 60), (0.31, 0.16, -32, 58)
        ]

        for i in 0..<100 {
            let nx: CGFloat
            let ny: CGFloat
            let angle: Double
            let size: CGFloat
            if i < earlyPts.count {
                nx = earlyPts[i].0
                ny = earlyPts[i].1
                angle = earlyPts[i].2
                size = earlyPts[i].3
            } else {
                // 黄金角螺旋覆盖完整圆拱形树冠（中心 (0.50, 0.33)，横半径 0.45，纵半径 0.28）
                let k = Double(i - earlyPts.count + 1)
                let golden = k * 2.3999632297
                let r = sqrt(k / 88.0)
                let jx = sin(k * 6.7) * 0.028
                let jy = cos(k * 4.3) * 0.024
                nx = min(0.95, max(0.05, 0.50 + CGFloat(cos(golden) * 0.45 * r + jx)))
                ny = min(0.62, max(0.04, 0.33 + CGFloat(sin(golden) * 0.28 * r + jy)))
                angle = cos(golden) * 52.0 + sin(k * 3.1) * 18.0
                // 内圈饱满（64~76pt），外缘轻盈灵动（54~66pt）
                size = CGFloat((r < 0.72 ? 62 : 54) + (i * 13) % 15)
            }
            let hue = Double(((i * 19) % 15) - 7) * 1.6
            let isStar = (i > 0 && (i + 1) % 5 == 0)
            slots.append(WatercolorLeafSlot(id: i, nx: nx, ny: ny, angle: angle, size: size, hueShift: hue, isStarBlossom: isStar))
        }
        return slots
    }()

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let canopyDensity = min(1.0, Double(visibleCount) / 85.0)

            ZStack {
                // 树根深层接地草影 + 草丘承托（将树根自然埋入草坡）
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: 0x355833).opacity(0.44),
                                Color(hex: 0x5A8247).opacity(0.24),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 8,
                            endRadius: w * 0.30
                        )
                    )
                    .frame(width: w * 0.58, height: 34)
                    .position(x: w * 0.50, y: h * 0.945)

                // 树冠背后柔和阳光/树种氛围晕
                if visibleCount > 0 {
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [
                                    species.canopyGlowColor(isNight: isNight).opacity(isNight ? 0.28 : 0.48),
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

                // 1. 同画风手绘水彩树干与舒展枝桠（按树种切换色温与左右镜像枝桠走向）
                Image("IllustTreeTrunk")
                    .resizable()
                    .scaledToFit()
                    .frame(width: w * 0.96, height: h * 0.96)
                    .scaleEffect(x: species.mirrorTrunk ? -1 : 1, y: 1)
                    .hueRotation(.degrees(species.trunkHue))
                    .saturation(species.trunkSaturation)
                    .brightness(species.trunkBrightness)
                    .position(x: w * 0.50, y: h * 0.50)
                    .opacity(records.isEmpty ? 0.58 : 0.98)

                // 树根处柔和草坡微融层（柔和衔接根部与草坡，避免浮在草面）
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: 0x7BA156).opacity(0.32),
                                Color(hex: 0x5D8440).opacity(0.0)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: w * 0.42, height: 22)
                    .blur(radius: 3)
                    .position(x: w * 0.50, y: h * 0.955)
                    .allowsHitTesting(false)

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

                // 1.5 水彩树冠底晕层：随叶数增加渐显，让 100 叶时树冠整体饱满充盈、零稀疏缝隙
                if visibleCount >= 16 {
                    ZStack {
                        Ellipse()
                            .fill(species.canopyWashPrimary.opacity(0.28 * canopyDensity))
                            .frame(width: w * 0.86, height: h * 0.50)
                            .blur(radius: 18)
                            .position(x: w * 0.50, y: h * 0.33)

                        Ellipse()
                            .fill(species.canopyWashSecondary.opacity(0.24 * canopyDensity))
                            .frame(width: w * 0.68, height: h * 0.38)
                            .blur(radius: 14)
                            .position(x: w * 0.48, y: h * 0.28)
                    }
                    .allowsHitTesting(false)
                }

                // 2. 手绘水彩叶簇逐片生长（1 次微步 = 1 簇手绘水彩叶）
                let activeSlots = Array(Self.allSlots.prefix(visibleCount))
                ForEach(activeSlots) { slot in
                    let isNewest = (newestLeafIndex == slot.id)
                    let matchingRec = slot.id < records.count ? records[slot.id] : nil
                    let mappedNx = species.mirrorTrunk ? (1.0 - slot.nx) : slot.nx
                    let mappedAngle = species.mirrorTrunk ? -slot.angle : slot.angle

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

            Image("IllustLeafCluster")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .hueRotation(.degrees(species.leafHueBase + hueShift))
                .saturation(species.leafSaturation)
                .brightness(species.leafBrightness)
                .colorMultiply(species.leafMultiply)

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
