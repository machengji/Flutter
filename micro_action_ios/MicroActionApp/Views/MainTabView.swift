import SwiftUI

/// 原生 SwiftUI 主界面（Tiimo 梦幻薰衣草柔雾美学：居中获取 PRO 悬浮胶囊 + 右侧星籽罐落点 + 底部双段式悬浮 Dock + 左侧滑出抽屉 + 星籽入罐轨迹）
struct MainTabView: View {
    enum ActiveTab: String, CaseIterable {
        case plans = "愿望"
        case habits = "习惯"
        case anchors = "锚点"
        case insights = "洞察"

        var iconName: String {
            switch self {
            case .plans: return "checkmark.square"
            case .habits: return "circle.dashed"
            case .anchors: return "calendar"
            case .insights: return "chart.bar"
            }
        }

        var activeIconName: String {
            switch self {
            case .plans: return "checkmark.square.fill"
            case .habits: return "circle.dashed.inset.filled"
            case .anchors: return "calendar.badge.clock"
            case .insights: return "chart.bar.fill"
            }
        }

        var quickAddMode: QuickAddFloatingBar.Mode {
            switch self {
            case .habits: return .habit
            case .anchors: return .anchor
            case .plans, .insights: return .plan
            }
        }
    }

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var proStore: ProStoreService

    @State private var currentTab: ActiveTab = .plans
    @State private var showSideDrawer: Bool = false
    @State private var activeMenuDestination: SideMenuDestination? = nil
    @State private var showShineJar: Bool = false
    @State private var showQuickAdd: Bool = false

    // 发光庆祝与成长树动效状态
    @Namespace private var morphNamespace
    @State private var chromeAppeared: Bool = false
    @State private var particleBurstId: Int = 0
    @State private var seedFlightId: Int = 0
    @State private var seedFlightStart: CGPoint = CGPoint(x: 195, y: 420)
    @State private var jarTargetPoint: CGPoint = CGPoint(x: 315, y: 62)
    @State private var jarPulse: Bool = false

    var body: some View {
        GeometryReader { rootGeo in
            ZStack {
                // 1. 顶部悬浮栏 + 主列表内容（忽略键盘挤压，确保打开快录条时背后界面纹丝不动零闪烁）
                VStack(spacing: 0) {
                    topHeaderBar
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .padding(.bottom, 8)
                        .offset(y: chromeAppeared ? 0 : -14)
                        .opacity(chromeAppeared ? 1.0 : 0.0)

                    Group {
                        switch currentTab {
                        case .plans:
                            PlanListView(
                                onQuickAdd: { openQuickAdd() },
                                onOpenShineJar: { showShineJar = true },
                                onSwitchTab: { tab in
                                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                        currentTab = tab
                                    }
                                }
                            )
                        case .habits:
                            HabitListView(
                                onQuickAdd: { openQuickAdd() },
                                onOpenShineJar: { showShineJar = true }
                            )
                        case .anchors:
                            AnchorListView(
                                onQuickAdd: { openQuickAdd() },
                                onOpenShineJar: { showShineJar = true }
                            )
                        case .insights:
                            AnalyticsTabView()
                        }
                    }
                    .id(currentTab)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity.combined(with: .offset(y: 8)))
                    .animation(.spring(response: 0.30, dampingFraction: 0.84), value: currentTab)
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)

                // 3. 底部 iOS 26 液态玻璃双段式悬浮 Dock（用 opacity 隐去避免与键盘位移动画打架）
                VStack {
                    Spacer()
                    LiquidGlassTabBar(
                        currentTab: $currentTab,
                        onSelectTab: { tab in
                            SensoryFeedbackService.shared.selection()
                            withAnimation(.spring(response: 0.34, dampingFraction: 0.80)) {
                                currentTab = tab
                            }
                        },
                        onTapAdd: {
                            openQuickAdd()
                        }
                    )
                    .offset(y: chromeAppeared ? 0 : 24)
                    .opacity(chromeAppeared && !showQuickAdd ? 1.0 : 0.0)
                    .allowsHitTesting(!showQuickAdd)
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)

                // 4. 现代液态玻璃紧贴键盘悬浮快捷录入条（默认新愿望，从右下角弹簧弹出）
                if showQuickAdd {
                    QuickAddFloatingBar(
                        isPresented: $showQuickAdd,
                        initialMode: .plan
                    )
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.84, anchor: .bottomTrailing).combined(with: .opacity),
                            removal: .scale(scale: 0.90, anchor: .bottomTrailing).combined(with: .opacity)
                        )
                    )
                    .zIndex(450)
                }

                // 5. 无阻断全屏星光粒子绽放层
                StarburstParticleLayer(burstId: particleBurstId, isGrand: true)
                    .ignoresSafeArea()

                // 6. 成长能量飞入顶部「微步成长树」胶囊动效层
                FlyingStarSeedOverlay(
                    flightId: seedFlightId,
                    startPoint: seedFlightStart,
                    targetPoint: jarTargetPoint
                ) {
                    triggerJarPulse()
                }

                // 7. 左侧滑出液态玻璃圆角抽屉
                SideDrawerOverlay(
                    isPresented: $showSideDrawer,
                    topInset: rootGeo.safeAreaInsets.top,
                    bottomInset: rootGeo.safeAreaInsets.bottom
                ) { destination in
                    if destination == .analytics {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.80)) {
                            currentTab = .insights
                        }
                    } else {
                        activeMenuDestination = destination
                    }
                }
                .zIndex(500)

                // 8. 顶层全局高光庆祝海报
                if let payload = appState.activeCelebration {
                    CelebrationPosterView(
                        payload: payload,
                        onDismiss: {
                            appState.activeCelebration = nil
                            launchSeedFlight(in: rootGeo.size)
                        },
                        onChargedDismiss: {
                            appState.activeCelebration = nil
                            particleBurstId += 1
                            launchSeedFlight(in: rootGeo.size)
                        }
                    )
                    .zIndex(999)
                }
            }
            .coordinateSpace(name: "MainRootSpace")
            .onAppear {
                if appState.pendingOpenedAnchorId != nil {
                    currentTab = .anchors
                }
                withAnimation(.spring(response: 0.62, dampingFraction: 0.84).delay(0.75)) {
                    chromeAppeared = true
                }
            }
            .onChange(of: appState.pendingOpenedAnchorId) { newId in
                if newId != nil {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                        currentTab = .anchors
                    }
                }
            }
            .onChange(of: appState.pendingLocatePlanId) { newId in
                if newId != nil {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                        currentTab = .plans
                    }
                }
            }
            .onChange(of: appState.pendingLocateHabitId) { newId in
                if newId != nil {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                        currentTab = .habits
                    }
                }
            }
            .onChange(of: appState.activeCelebration?.id) { newId in
                if newId != nil {
                    particleBurstId += 1
                }
            }
        }
        .background {
            ImmersiveBackgroundView()
        }
        .sheet(item: $activeMenuDestination) { dest in
            Group {
                switch dest {
                case .settings: SettingsSheet()
                case .analytics: AnalyticsSheet()
                case .archive: ArchiveSheet()
                case .help: HelpSheet()
                case .legal: LegalSheet()
                }
            }
            .liquidGlassSheet(detents: [.large], cornerRadius: 34)
        }
        .fullScreenCover(isPresented: $showShineJar) {
            GrowthTreeFullScreenView()
        }
        .sheet(isPresented: $appState.showProPaywall) {
            ProPaywallSheet()
                .liquidGlassSheet(detents: [.large], cornerRadius: 34)
                .liquidZoomTransition(sourceID: "proPill", in: morphNamespace)
        }
        .sheet(item: Binding<AnchorItem?>(
            get: {
                guard let id = appState.pendingOpenedAnchorId else { return nil }
                return appState.anchors.first(where: { $0.id == id })
            },
            set: { item in
                if item == nil {
                    appState.pendingOpenedAnchorId = nil
                }
            }
        )) { anchor in
            AnchorDetailSheet(anchorId: anchor.id)
                .liquidGlassSheet(detents: [.large], cornerRadius: 34)
        }
    }

    private func openQuickAdd() {
        SensoryFeedbackService.shared.lightTap()
        withAnimation(.spring(response: 0.34, dampingFraction: 0.80)) {
            showQuickAdd = true
        }
    }

    private var headerDateText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 · E"
        return f.string(from: Date())
    }

    private var topHeaderBar: some View {
        ZStack {
            // 居中层：物理绝对居中（不受左右按钮宽度差异影响）
            if !proStore.isPro {
                Button {
                    SensoryFeedbackService.shared.selection()
                    appState.showProPaywall = true
                } label: {
                    HStack(spacing: 5) {
                        Text("获取 PRO")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(BotanicalTheme.textPrimary)
                            .lineLimit(1)

                        Image(systemName: "sparkle")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundColor(BotanicalTheme.primary)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 42)
                    .liquidGlassCapsule(
                        tint: BotanicalTheme.primaryLight,
                        interactive: true,
                        shadowRadius: 14
                    )
                }
                .buttonStyle(ScaleBounceButtonStyle(scale: 0.94))
                .liquidZoomSource(id: "proPill", in: morphNamespace)
            } else {
                // Things 3 / Tiimo 杂志极简风：正中轴纯文字日期，干净呼吸感十足
                VStack(spacing: 1) {
                    Text(headerDateText)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(BotanicalTheme.textPrimary.opacity(0.88))
                    Text("微步成林")
                        .font(.system(size: 10.5, weight: .semibold))
                        .tracking(1.2)
                        .foregroundColor(BotanicalTheme.primaryDark.opacity(0.65))
                }
            }

            // 左右双翼层
            HStack(spacing: 8) {
                // 左侧：极简双横线菜单按钮
                Button {
                    SensoryFeedbackService.shared.lightTap()
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                        showSideDrawer = true
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        Capsule()
                            .fill(BotanicalTheme.textPrimary)
                            .frame(width: 17, height: 1.8)
                        Capsule()
                            .fill(BotanicalTheme.textPrimary)
                            .frame(width: 11, height: 1.8)
                    }
                    .frame(width: 44, height: 44)
                    .liquidGlassCircle(
                        tint: BotanicalTheme.primaryLight,
                        interactive: true,
                        shadowRadius: 12
                    )
                }
                .buttonStyle(ScaleBounceButtonStyle(scale: 0.92))
                .accessibilityLabel("打开侧边菜单")

                Spacer()

                // 右侧：液态玻璃微步成长树胶囊入口（保留落点追踪与浇灌脉冲动效）
                let hasToday = appState.todayShineCount > 0
            Button {
                SensoryFeedbackService.shared.selection()
                showShineJar = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(jarPulse ? BotanicalTheme.gold : BotanicalTheme.primary)

                    Text(
                        hasToday
                            ? "今日 +\(appState.todayShineCount)"
                            : "成长树 \(appState.shineRecords.count)"
                    )
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundColor(BotanicalTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .liquidGlassCapsule(
                    tint: jarPulse ? BotanicalTheme.gold : BotanicalTheme.primaryLight,
                    interactive: true,
                    shadowRadius: jarPulse ? 16 : 12
                )
                .overlay(
                    Capsule()
                        .stroke(
                            jarPulse ? BotanicalTheme.gold.opacity(0.85) : Color.clear,
                            lineWidth: 1.4
                        )
                )
                .scaleEffect(jarPulse ? 1.12 : 1.0)
                .animation(.spring(response: 0.24, dampingFraction: 0.62), value: jarPulse)
            }
            .contentShape(Capsule())
            .buttonStyle(ScaleBounceButtonStyle(scale: 0.94))
            .accessibilityLabel("打开微步成长树")
            .liquidZoomSource(id: "treePill", in: morphNamespace)
            .background(
                GeometryReader { jarGeo in
                    Color.clear
                        .onAppear {
                            let frame = jarGeo.frame(in: .named("MainRootSpace"))
                            jarTargetPoint = CGPoint(x: frame.midX, y: frame.midY)
                        }
                        .onChange(of: jarGeo.frame(in: .named("MainRootSpace"))) { newFrame in
                            jarTargetPoint = CGPoint(x: newFrame.midX, y: newFrame.midY)
                        }
                }
            )
            }
        }
    }

    private func launchSeedFlight(in size: CGSize) {
        seedFlightStart = CGPoint(x: size.width * 0.5, y: size.height * 0.54)
        seedFlightId += 1
    }

    private func triggerJarPulse() {
        SensoryFeedbackService.shared.lightTap()
        jarPulse = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            jarPulse = false
        }
    }
}
