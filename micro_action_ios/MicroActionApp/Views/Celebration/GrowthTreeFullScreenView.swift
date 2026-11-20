import SwiftUI

/// 全屏沉浸式「微步成长树」独立页面
/// 宫崎骏晨曦草地森林背景画卷 + SwiftUI 有机贝塞尔枝干 + 逐叶萌芽生长引擎（1 次微步 = 1 片真实新叶）
struct GrowthTreeFullScreenView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var showSettingsSheet: Bool = false
    @State private var burstId: Int = 0
    @State private var newestLeafIndex: Int? = nil
    @State private var rippleTrigger: Int = 0
    @State private var energyPulseProgress: CGFloat = 0
    @State private var showEnergyPulse: Bool = false
    @State private var selectedRecord: ShineRecord? = nil
    @State private var freeQuoteBanner: String? = nil
    @State private var isWatering: Bool = false

    private var totalCount: Int {
        appState.shineRecords.count
    }

    private var stageInfo: (level: Int, name: String, subtitle: String) {
        switch totalCount {
        case 0:
            return (0, "休眠星种", "完成 1 步即破土发芽")
        case 1...5:
            return (1, "初生嫩芽", "共 \(totalCount) 片新叶")
        case 6...20:
            return (2, "舒展幼苗", "共 \(totalCount) 片新叶")
        case 21...50:
            return (3, "青翠小树", "共 \(totalCount) 片叶 · 星花初绽")
        default:
            return (4, "森境大树", "共 \(totalCount) 片叶 · 繁星满枝")
        }
    }

    var body: some View {
        ZStack {
            // 1. 宫崎骏晨曦草地背景画卷（左下角坐着仰望微笑的小新芽精灵）
            GeometryReader { geo in
                Image("IllustGrowthTreeBg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .ignoresSafeArea()

            // 2. 中央有机贝塞尔成长树（从草坡正中生长而出，随微步记录一片片长出新叶）
            GeometryReader { geo in
                let treeWidth = min(geo.size.width * 0.92, 400)
                let treeHeight = geo.size.height * 0.56
                // 树根精准落在草坡隆起处（约屏幕高度 78% 位置）
                let treeCenterY = geo.size.height * 0.50

                OrganicGrowthTreeView(
                    records: appState.shineRecords,
                    newestLeafIndex: newestLeafIndex,
                    rippleTrigger: rippleTrigger,
                    energyPulseProgress: energyPulseProgress,
                    showEnergyPulse: showEnergyPulse,
                    onSelectRecord: { rec in
                        SensoryFeedbackService.shared.lightTap()
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                            selectedRecord = (selectedRecord?.id == rec.id) ? nil : rec
                        }
                    }
                )
                .frame(width: treeWidth, height: treeHeight)
                .position(x: geo.size.width / 2, y: treeCenterY)
            }

            // 3. 星芒粒子层
            StarburstParticleLayer(burstId: burstId, isGrand: true)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // 4. 极简悬浮 HUD（顶部返回/阶段/设置 + 底部足迹气泡/浇灌按钮）
            VStack(spacing: 0) {
                topHudBar
                    .padding(.horizontal, 18)
                    .padding(.top, 10)

                Spacer()

                // 轻点叶子/星果后显示的微步足迹胶囊，或浇灌鼓励气泡
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
                        .background(Color(hex: 0xFAF6ED).opacity(0.90))
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

                bottomActionBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 22)
            }
        }
        .sheet(isPresented: $showSettingsSheet) {
            ShineJarSheet()
        }
        .onChange(of: appState.shineRecords.count) { newCount in
            if newCount > 0 {
                triggerNewLeafCelebration(forTotalCount: newCount)
            }
        }
    }

    private var topHudBar: some View {
        HStack(alignment: .center) {
            Button {
                SensoryFeedbackService.shared.selection()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: 0x1D4432))
                    .frame(width: 38, height: 38)
                    .background(Color(hex: 0xFAF6ED).opacity(0.84))
                    .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.08), radius: 8, y: 3)
            }
            .buttonStyle(ScaleBounceButtonStyle(scale: 0.90))

            Spacer()

            VStack(spacing: 3) {
                Text("微步成长树")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(hex: 0x1D4432))

                HStack(spacing: 5) {
                    Circle()
                        .fill(Color(hex: 0xE07A38))
                        .frame(width: 6, height: 6)
                    Text("\(stageInfo.name) · \(stageInfo.subtitle)")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(Color(hex: 0x3D5E4C))
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 4)
                .background(Color(hex: 0xFAF6ED).opacity(0.84))
                .overlay(Capsule().stroke(Color.white.opacity(0.8), lineWidth: 0.9))
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
                    .background(Color(hex: 0xFAF6ED).opacity(0.84))
                    .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.08), radius: 8, y: 3)
            }
            .buttonStyle(ScaleBounceButtonStyle(scale: 0.90))
        }
    }

    private func selectedLeafBanner(_ rec: ShineRecord) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 13))
                .foregroundColor(BotanicalTheme.primary)
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
        .background(Color(hex: 0xFAF6ED).opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.85), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.09), radius: 10, y: 4)
    }

    private var bottomActionBar: some View {
        Button {
            guard !isWatering else { return }
            isWatering = true
            Task {
                let payload = await appState.celebrateFreely()
                await MainActor.run {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                        selectedRecord = nil
                        freeQuoteBanner = payload.quote
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14.5, weight: .bold))
                Text("浇灌星光 · 长出新叶")
                    .font(.system(size: 14.5, weight: .bold))
            }
            .foregroundColor(Color(hex: 0x1D4432))
            .padding(.horizontal, 24)
            .frame(height: 46)
            .background(
                LinearGradient(
                    colors: [Color(hex: 0xF5FBE9).opacity(0.94), Color(hex: 0xDCF0DF).opacity(0.92)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Capsule()
                    .stroke(Color(hex: 0xA8CEB2).opacity(0.85), lineWidth: 1.1)
            )
            .clipShape(Capsule())
            .shadow(color: Color(hex: 0x2F5E45).opacity(0.16), radius: 12, y: 5)
        }
        .buttonStyle(ScaleBounceButtonStyle(scale: 0.94))
    }

    private func triggerNewLeafCelebration(forTotalCount count: Int) {
        let idx = min(max(0, count - 1), 119)
        newestLeafIndex = idx
        burstId += 1
        rippleTrigger += 1
        SensoryFeedbackService.shared.celebrateGrand(
            soundEnabled: appState.soundEnabled,
            soundPack: appState.soundPack
        )

        showEnergyPulse = true
        energyPulseProgress = 0
        withAnimation(.easeOut(duration: 0.65)) {
            energyPulseProgress = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            withAnimation(.easeOut(duration: 0.25)) {
                showEnergyPulse = false
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            if newestLeafIndex == idx {
                newestLeafIndex = nil
            }
        }
    }
}

// MARK: - 程序化有机贝塞尔生长树（支持逐叶萌芽 + 新叶弹跳 + 点击星叶查足迹）

private struct OrganicGrowthTreeView: View {
    let records: [ShineRecord]
    let newestLeafIndex: Int?
    let rippleTrigger: Int
    let energyPulseProgress: CGFloat
    let showEnergyPulse: Bool
    let onSelectRecord: (ShineRecord) -> Void

    @State private var swayPhase: Bool = false
    @State private var tapShakeAngle: Double = 0

    private var totalCount: Int { records.count }

    private var stageLevel: Int {
        switch totalCount {
        case 0: return 0
        case 1...5: return 1
        case 6...20: return 2
        case 21...50: return 3
        default: return 4
        }
    }

    /// 最多在树冠呈现 120 片叶位（按时间从早到晚对应记录，超过 120 保留最新 120 片叶子的足迹关联）
    private var visibleCount: Int {
        min(totalCount, 120)
    }

    private struct LeafNode: Identifiable {
        let id: Int
        let nx: CGFloat
        let ny: CGFloat
        let angle: Double
        let scale: CGFloat
        let colorHex: UInt32
        let isStarFruit: Bool
    }

    /// 确定性有机叶位生成（由内向外、由下到上，随着步数增加自然撑起饱满树冠）
    private static let allLeafNodes: [LeafNode] = {
        let palette: [UInt32] = [0x6BBF7B, 0x86CE8E, 0x4EA367, 0x9FD99B, 0x57AE70, 0xB3DF8C]
        // 核心枝梢优先锚点（前 15 片叶精准落在主枝与次枝梢头，数量少时也优雅！）
        let earlyAnchors: [(CGFloat, CGFloat, Double)] = [
            (0.50, 0.52, -18), (0.43, 0.49, -45), (0.57, 0.48, 32),
            (0.36, 0.44, -55), (0.64, 0.42, 48), (0.50, 0.39, 10),
            (0.30, 0.39, -62), (0.71, 0.37, 58), (0.42, 0.34, -28),
            (0.58, 0.33, 25), (0.25, 0.45, -72), (0.76, 0.44, 68),
            (0.49, 0.27, -5),  (0.35, 0.29, -38), (0.65, 0.28, 36)
        ]

        var nodes: [LeafNode] = []
        for i in 0..<120 {
            let nx: CGFloat
            let ny: CGFloat
            let angle: Double
            if i < earlyAnchors.count {
                nx = earlyAnchors[i].0
                ny = earlyAnchors[i].1
                angle = earlyAnchors[i].2
            } else {
                // 黄金角螺旋向外层均匀铺展树冠
                let k = Double(i - earlyAnchors.count + 1)
                let goldenAngle = k * 2.3999632297
                let normR = sqrt(k / 105.0)
                let rx = 0.34 * normR
                let ry = 0.22 * normR
                let jitterX = sin(k * 7.3) * 0.025
                let jitterY = cos(k * 5.1) * 0.020
                nx = min(0.88, max(0.12, 0.50 + CGFloat(cos(goldenAngle) * rx + jitterX)))
                ny = min(0.56, max(0.14, 0.36 + CGFloat(sin(goldenAngle) * ry + jitterY)))
                angle = (cos(goldenAngle) * 65.0) + sin(k * 3.7) * 20.0
            }
            let isStar = (i > 0 && (i + 1) % 5 == 0)
            let scale = CGFloat(0.84 + Double((i * 17) % 10) * 0.036)
            let color = palette[i % palette.count]
            nodes.append(LeafNode(id: i, nx: nx, ny: ny, angle: angle, scale: scale, colorHex: color, isStarFruit: isStar))
        }
        return nodes
    }()

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // 树冠背后的柔光氛围晕
                if totalCount > 0 {
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: 0xE6F7CC).opacity(0.55), Color.clear],
                                center: .center,
                                startRadius: 15,
                                endRadius: w * 0.44
                            )
                        )
                        .frame(width: w * 0.85, height: h * 0.52)
                        .position(x: w * 0.50, y: h * 0.37)
                }

                // 1. 有机渐细贝塞尔树干与多级枝干
                OrganicTreeTrunkShape(stage: stageLevel)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0x9C7154), Color(hex: 0x79533B), Color(hex: 0x5E3E2B)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(hex: 0x4A301E).opacity(0.18), radius: 8, y: 4)

                // 能量脉冲沿树干上升
                if showEnergyPulse {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: 0xFFF2AE), Color(hex: 0xF5B942).opacity(0.4), .clear],
                                center: .center,
                                startRadius: 2,
                                endRadius: 26
                            )
                        )
                        .frame(width: 52, height: 52)
                        .position(
                            x: w * 0.50 + sin(energyPulseProgress * .pi) * 8,
                            y: h * (0.94 - energyPulseProgress * 0.56)
                        )
                }

                // 2. 逐片生长的叶子与星花果实（倒序让新叶也在外层清晰可见）
                let activeNodes = Array(Self.allLeafNodes.prefix(visibleCount))
                let reversedRecords = Array(records.reversed())

                ForEach(activeNodes) { node in
                    let isNewest = (newestLeafIndex == node.id)
                    let matchingRecord = node.id < reversedRecords.count ? reversedRecords[node.id] : nil

                    LeafNodeView(
                        color: Color(hex: node.colorHex),
                        isStarFruit: node.isStarFruit,
                        isNewest: isNewest,
                        rippleTrigger: isNewest ? rippleTrigger : 0
                    )
                    .scaleEffect(node.scale)
                    .rotationEffect(.degrees(node.angle + (swayPhase ? 2.2 : -2.2)))
                    .position(x: node.nx * w, y: node.ny * h)
                    .onTapGesture {
                        if let rec = matchingRecord {
                            onSelectRecord(rec)
                        } else {
                            triggerBreezeShake()
                        }
                    }
                }

                // 0 步时地面的一颗小星种
                if totalCount == 0 {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: 0xFFE58F), Color(hex: 0x8ED09A)],
                                center: .center,
                                startRadius: 2,
                                endRadius: 12
                            )
                        )
                        .frame(width: 20, height: 20)
                        .position(x: w * 0.50, y: h * 0.92)
                }
            }
            .rotationEffect(.degrees(tapShakeAngle), anchor: .bottom)
            .contentShape(Rectangle())
            .onTapGesture {
                triggerBreezeShake()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                swayPhase = true
            }
        }
    }

    private func triggerBreezeShake() {
        SensoryFeedbackService.shared.selection()
        withAnimation(.spring(response: 0.22, dampingFraction: 0.45)) {
            tapShakeAngle = 2.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.42)) {
                tapShakeAngle = 0
            }
        }
    }
}

// MARK: - 单片水彩质感叶子 + 新叶“噗”地萌芽弹跳特效

private struct LeafNodeView: View {
    let color: Color
    let isStarFruit: Bool
    let isNewest: Bool
    let rippleTrigger: Int

    @State private var popScale: CGFloat = 1.0
    @State private var ringScale: CGFloat = 0.4
    @State private var ringOpacity: Double = 0

    var body: some View {
        ZStack {
            if ringOpacity > 0.01 {
                Circle()
                    .stroke(Color(hex: 0xFFD966), lineWidth: 2.0)
                    .frame(width: 34, height: 34)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)
            }

            // 精致双侧水彩叶片
            ZStack {
                BotanicalLeafShape()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.95), color.opacity(0.72)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 17, height: 25)
                    .shadow(color: color.opacity(0.25), radius: 2.5, y: 1.5)

                // 中央细叶脉高光
                Path { p in
                    p.move(to: CGPoint(x: 8.5, y: 23))
                    p.addLine(to: CGPoint(x: 8.5, y: 5))
                }
                .stroke(Color.white.opacity(0.45), lineWidth: 0.9)
                .frame(width: 17, height: 25)
            }

            // 每逢 5 的倍数步数，叶间结出一颗发光小星果
            if isStarFruit {
                Image(systemName: "star.fill")
                    .font(.system(size: 10.5))
                    .foregroundColor(Color(hex: 0xFFD452))
                    .shadow(color: Color(hex: 0xFFB830).opacity(0.8), radius: 4)
                    .offset(x: 5, y: -5)
            }
        }
        .scaleEffect(popScale)
        .onAppear {
            if isNewest {
                playSproutPop()
            }
        }
        .onChange(of: rippleTrigger) { _ in
            if isNewest {
                playSproutPop()
            }
        }
    }

    private func playSproutPop() {
        popScale = 0.08
        ringScale = 0.3
        ringOpacity = 0.95
        withAnimation(.spring(response: 0.45, dampingFraction: 0.46)) {
            popScale = 1.0
        }
        withAnimation(.easeOut(duration: 0.72)) {
            ringScale = 2.0
            ringOpacity = 0.0
        }
    }
}

private struct BotanicalLeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.move(to: CGPoint(x: w * 0.5, y: h))
        p.addQuadCurve(to: CGPoint(x: w * 0.5, y: 0), control: CGPoint(x: w * 1.15, y: h * 0.48))
        p.addQuadCurve(to: CGPoint(x: w * 0.5, y: h), control: CGPoint(x: -w * 0.15, y: h * 0.48))
        return p
    }
}

// MARK: - 有机渐细贝塞尔树干与分枝轮廓（彻底告别直线硬棒）

private struct OrganicTreeTrunkShape: Shape {
    let stage: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard stage > 0 else { return path }
        let w = rect.width
        let h = rect.height

        // 根据成长阶段调整树干粗细与高度比例
        let baseHalfW: CGFloat = stage == 1 ? 6 : (stage == 2 ? 10 : (stage == 3 ? 14 : 18))
        let topY: CGFloat = stage == 1 ? 0.62 : (stage == 2 ? 0.46 : 0.38)

        // 主干有机轮廓（左侧上行，右侧下行，根部向草坡自然抓地）
        path.move(to: CGPoint(x: w * 0.50 - baseHalfW * 1.65, y: h * 0.96))
        path.addCurve(
            to: CGPoint(x: w * 0.50 - baseHalfW * 0.28, y: h * topY),
            control1: CGPoint(x: w * 0.50 - baseHalfW * 0.85, y: h * 0.84),
            control2: CGPoint(x: w * 0.47, y: h * 0.64)
        )
        path.addLine(to: CGPoint(x: w * 0.50 + baseHalfW * 0.28, y: h * topY))
        path.addCurve(
            to: CGPoint(x: w * 0.50 + baseHalfW * 1.75, y: h * 0.96),
            control1: CGPoint(x: w * 0.53, y: h * 0.64),
            control2: CGPoint(x: w * 0.50 + baseHalfW * 0.88, y: h * 0.84)
        )
        path.closeSubpath()

        // 阶段 >= 1：左主枝 & 右主枝
        addTaperedBranch(
            to: &path,
            start: CGPoint(x: w * 0.49, y: h * 0.64),
            end: CGPoint(x: w * 0.30, y: h * 0.40),
            ctrl1: CGPoint(x: w * 0.40, y: h * 0.56),
            ctrl2: CGPoint(x: w * 0.34, y: h * 0.47),
            startWidth: baseHalfW * 0.68,
            endWidth: 2.2
        )

        addTaperedBranch(
            to: &path,
            start: CGPoint(x: w * 0.51, y: h * 0.60),
            end: CGPoint(x: w * 0.70, y: h * 0.37),
            ctrl1: CGPoint(x: w * 0.60, y: h * 0.53),
            ctrl2: CGPoint(x: w * 0.66, y: h * 0.44),
            startWidth: baseHalfW * 0.64,
            endWidth: 2.2
        )

        // 阶段 >= 2：中上冠分枝与外延小枝
        if stage >= 2 {
            addTaperedBranch(
                to: &path,
                start: CGPoint(x: w * 0.50, y: h * 0.48),
                end: CGPoint(x: w * 0.41, y: h * 0.27),
                ctrl1: CGPoint(x: w * 0.47, y: h * 0.39),
                ctrl2: CGPoint(x: w * 0.43, y: h * 0.32),
                startWidth: baseHalfW * 0.42,
                endWidth: 1.8
            )
            addTaperedBranch(
                to: &path,
                start: CGPoint(x: w * 0.50, y: h * 0.46),
                end: CGPoint(x: w * 0.60, y: h * 0.26),
                ctrl1: CGPoint(x: w * 0.53, y: h * 0.38),
                ctrl2: CGPoint(x: w * 0.57, y: h * 0.31),
                startWidth: baseHalfW * 0.40,
                endWidth: 1.8
            )
        }

        // 阶段 >= 3：左右二级繁茂侧枝
        if stage >= 3 {
            addTaperedBranch(
                to: &path,
                start: CGPoint(x: w * 0.39, y: h * 0.50),
                end: CGPoint(x: w * 0.22, y: h * 0.45),
                ctrl1: CGPoint(x: w * 0.32, y: h * 0.48),
                ctrl2: CGPoint(x: w * 0.27, y: h * 0.46),
                startWidth: baseHalfW * 0.34,
                endWidth: 1.5
            )
            addTaperedBranch(
                to: &path,
                start: CGPoint(x: w * 0.61, y: h * 0.47),
                end: CGPoint(x: w * 0.78, y: h * 0.42),
                ctrl1: CGPoint(x: w * 0.68, y: h * 0.45),
                ctrl2: CGPoint(x: w * 0.73, y: h * 0.43),
                startWidth: baseHalfW * 0.34,
                endWidth: 1.5
            )
        }

        return path
    }

    private func addTaperedBranch(
        to path: inout Path,
        start: CGPoint,
        end: CGPoint,
        ctrl1: CGPoint,
        ctrl2: CGPoint,
        startWidth: CGFloat,
        endWidth: CGFloat
    ) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let len = max(hypot(dx, dy), 1)
        let nx = -dy / len
        let ny = dx / len

        let s1 = CGPoint(x: start.x + nx * startWidth * 0.5, y: start.y + ny * startWidth * 0.5)
        let s2 = CGPoint(x: start.x - nx * startWidth * 0.5, y: start.y - ny * startWidth * 0.5)
        let e1 = CGPoint(x: end.x + nx * endWidth * 0.5, y: end.y + ny * endWidth * 0.5)
        let e2 = CGPoint(x: end.x - nx * endWidth * 0.5, y: end.y - ny * endWidth * 0.5)

        let midW = (startWidth + endWidth) * 0.25
        path.move(to: s1)
        path.addCurve(
            to: e1,
            control1: CGPoint(x: ctrl1.x + nx * midW, y: ctrl1.y + ny * midW),
            control2: CGPoint(x: ctrl2.x + nx * endWidth, y: ctrl2.y + ny * endWidth)
        )
        path.addLine(to: e2)
        path.addCurve(
            to: s2,
            control1: CGPoint(x: ctrl2.x - nx * endWidth, y: ctrl2.y - ny * endWidth),
            control2: CGPoint(x: ctrl1.x - nx * midW, y: ctrl1.y - ny * midW)
        )
        path.closeSubpath()
    }
}
