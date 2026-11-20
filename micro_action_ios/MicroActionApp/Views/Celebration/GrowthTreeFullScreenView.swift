import SwiftUI

/// 全屏沉浸式「微步成长树 2.0」独立页面
/// 同画风手绘水彩树干 + 水彩叶簇/星花逐片生长 + 每 100 步成林切换 + CoreHaptics 0.6s 长震动浇灌 + 昼夜自适应天光
struct GrowthTreeFullScreenView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var showSettingsSheet: Bool = false
    @State private var selectedTreeIndex: Int? = nil // nil 表示当前正在成长的最新一棵树
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

    private var currentTreeRecords: [ShineRecord] {
        let start = activeTreeIndex * leavesPerTree
        let end = min(start + leavesPerTree, chronologicalRecords.count)
        guard start < end else { return [] }
        return Array(chronologicalRecords[start..<end])
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

        ZStack {
            // 1. 宫崎骏晨曦草坡背景画卷 + 昼夜自适应柔和天光
            GeometryReader { geo in
                Image("IllustGrowthTreeBg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .overlay(amb.overlay)
            }
            .ignoresSafeArea()

            // 夜晚模式增加静谧闪烁暖金萤火微粒
            if amb.isNight {
                NightFireflyLayer()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // 2. 中央手绘水彩成长树（树根自然贴合草坡隆起处）
            GeometryReader { geo in
                let treeWidth = min(geo.size.width * 0.90, 390)
                let treeHeight = min(geo.size.height * 0.56, 470)
                let treeCenterY = geo.size.height * 0.525

                WatercolorGrowthTreeView(
                    records: currentTreeRecords,
                    newestLeafIndex: newestLeafIndex,
                    rippleTrigger: rippleTrigger,
                    energyPulseProgress: energyPulseProgress,
                    showEnergyPulse: showEnergyPulse,
                    isNight: amb.isNight,
                    onTapCanopy: {
                        petalBurstId += 1
                    },
                    onSelectRecord: { rec in
                        SensoryFeedbackService.shared.lightTap()
                        withAnimation(.spring(response: 0.30, dampingFraction: 0.78)) {
                            selectedRecord = (selectedRecord?.id == rec.id) ? nil : rec
                        }
                    }
                )
                .frame(width: treeWidth, height: treeHeight)
                .position(x: geo.size.width / 2, y: treeCenterY)
            }

            // 3. 微风花瓣飘落层 & 星芒粒子层
            DriftingPetalsOverlay(triggerId: petalBurstId)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            StarburstParticleLayer(burstId: burstId, isGrand: true)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // 4. 极简悬浮 HUD
            VStack(spacing: 0) {
                topHudBar(isNight: amb.isNight)
                    .padding(.horizontal, 18)
                    .padding(.top, 10)

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

                // 底部 0.6s 连续长震动浇灌按钮（按住蓄力 / 轻点皆可）
                ChargeToShineButton(
                    label: "按住浇灌星光",
                    chargingLabel: "星光汇聚中...",
                    completedLabel: "新叶已萌芽",
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
                            ? "第 \(activeTreeIndex + 1)/\(totalTreesCount) 棵 · \(stageTitle) · \(currentTreeRecords.count)/\(leavesPerTree)"
                            : "\(stageTitle) · \(currentTreeRecords.count)/\(leavesPerTree) 叶"
                    )
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

    /// 100 个精准贴合 IllustTreeTrunk 圆拱形枝桠的黄金角水彩叶簇锚点
    private static let allSlots: [WatercolorLeafSlot] = {
        var slots: [WatercolorLeafSlot] = []
        // 前 12 片优先落在主枝干内侧与顶梢，数量少时已极具水彩画感
        let earlyPts: [(CGFloat, CGFloat, Double, CGFloat)] = [
            (0.49, 0.42, -12, 46), (0.37, 0.40, -38, 44), (0.62, 0.39, 32, 46),
            (0.28, 0.34, -52, 44), (0.72, 0.33, 46, 44), (0.50, 0.28, 6, 48),
            (0.40, 0.26, -24, 46), (0.61, 0.25, 22, 46), (0.21, 0.42, -64, 42),
            (0.79, 0.41, 58, 42), (0.48, 0.16, -4, 46), (0.33, 0.19, -32, 44)
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
                // 黄金角螺旋均匀填充树冠圆拱区域（中心 (0.50, 0.33)，横半径 0.40，纵半径 0.25）
                let k = Double(i - earlyPts.count + 1)
                let golden = k * 2.3999632297
                let r = sqrt(k / 88.0)
                let jx = sin(k * 6.7) * 0.025
                let jy = cos(k * 4.3) * 0.020
                nx = min(0.90, max(0.10, 0.50 + CGFloat(cos(golden) * 0.40 * r + jx)))
                ny = min(0.56, max(0.08, 0.33 + CGFloat(sin(golden) * 0.24 * r + jy)))
                angle = cos(golden) * 48.0 + sin(k * 3.1) * 18.0
                size = CGFloat(38 + (i * 13) % 16)
            }
            let hue = Double(((i * 19) % 15) - 7) * 1.4
            let isStar = (i > 0 && (i + 1) % 5 == 0)
            slots.append(WatercolorLeafSlot(id: i, nx: nx, ny: ny, angle: angle, size: size, hueShift: hue, isStarBlossom: isStar))
        }
        return slots
    }()

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // 树根草影柔和贴地过渡（彻底融入背景草坡）
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: 0x3D5E3A).opacity(0.28), Color.clear],
                            center: .center,
                            startRadius: 6,
                            endRadius: w * 0.24
                        )
                    )
                    .frame(width: w * 0.46, height: 26)
                    .position(x: w * 0.50, y: h * 0.945)

                // 树冠背后柔和阳光氛围晕
                if visibleCount > 0 {
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [
                                    (isNight ? Color(hex: 0x8DE4AF) : Color(hex: 0xEEF9D6)).opacity(isNight ? 0.24 : 0.50),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 12,
                                endRadius: w * 0.48
                            )
                        )
                        .frame(width: w * 0.92, height: h * 0.58)
                        .position(x: w * 0.50, y: h * 0.34)
                }

                // 1. 同画风手绘水彩树干与舒展枝桠（零镂空缺口、零硬边）
                Image("IllustTreeTrunk")
                    .resizable()
                    .scaledToFit()
                    .frame(width: w * 0.94, height: h * 0.94)
                    .position(x: w * 0.50, y: h * 0.50)
                    .opacity(records.isEmpty ? 0.55 : 0.98)

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
                            x: w * 0.48 + sin(energyPulseProgress * .pi) * 10,
                            y: h * (0.90 - energyPulseProgress * 0.56)
                        )
                }

                // 2. 手绘水彩叶簇逐片生长（1 次微步 = 1 簇手绘水彩叶）
                let activeSlots = Array(Self.allSlots.prefix(visibleCount))
                ForEach(activeSlots) { slot in
                    let isNewest = (newestLeafIndex == slot.id)
                    let matchingRec = slot.id < records.count ? records[slot.id] : nil

                    WatercolorLeafNodeView(
                        size: slot.size,
                        hueShift: slot.hueShift,
                        isStarBlossom: slot.isStarBlossom,
                        isNewest: isNewest,
                        rippleTrigger: isNewest ? rippleTrigger : 0
                    )
                    .rotationEffect(.degrees(slot.angle + (swayPhase ? 2.4 : -2.4)))
                    .position(x: slot.nx * w, y: slot.ny * h)
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

// MARK: - 单簇手绘水彩叶 & 星花果节点（含新叶萌芽弹跳 + 金色光环涟漪）

private struct WatercolorLeafNodeView: View {
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
                    .stroke(Color(hex: 0xFFD966), lineWidth: 2.0)
                    .frame(width: size * 0.9, height: size * 0.9)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)
            }

            Image("IllustLeafCluster")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .hueRotation(.degrees(hueShift))

            if isStarBlossom {
                Image("IllustStarBlossom")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.56, height: size * 0.56)
                    .shadow(color: Color(hex: 0xFFD15C).opacity(0.65), radius: 5)
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

// MARK: - 微风飘落樱花瓣特效层

private struct DriftingPetalsOverlay: View {
    let triggerId: Int
    @State private var falling: Bool = false
    @State private var visible: Bool = false

    var body: some View {
        GeometryReader { geo in
            if visible {
                ZStack {
                    ForEach(0..<8, id: \.self) { idx in
                        let startX = geo.size.width * (0.22 + CGFloat(idx) * 0.08)
                        let startY = geo.size.height * (0.28 + CGFloat(idx % 3) * 0.07)
                        Ellipse()
                            .fill(idx % 2 == 0 ? Color(hex: 0xF7C6CF) : Color(hex: 0xB8E0B6))
                            .frame(width: 9, height: 5.5)
                            .rotationEffect(.degrees(falling ? Double(idx * 55 + 140) : Double(idx * 25)))
                            .position(
                                x: startX + (falling ? CGFloat((idx % 2 == 0 ? 1 : -1) * 48) : 0),
                                y: startY + (falling ? 190 + CGFloat(idx * 14) : 0)
                            )
                            .opacity(falling ? 0.0 : 0.85)
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
