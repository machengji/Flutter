import SwiftUI

/// 原生 SwiftUI 主界面（Tiimo 梦幻薰衣草柔雾美学：居中获取 PRO 悬浮胶囊 + 右侧星籽罐落点 + 底部双段式悬浮 Dock + 左侧滑出抽屉 + 星籽入罐轨迹）
struct MainTabView: View {
    enum ActiveTab: String, CaseIterable {
        case plans = "计划"
        case habits = "习惯"
        case anchors = "锚点"

        var iconName: String {
            switch self {
            case .plans: return "checkmark.square"
            case .habits: return "circle.dashed"
            case .anchors: return "calendar"
            }
        }

        var activeIconName: String {
            switch self {
            case .plans: return "checkmark.square.fill"
            case .habits: return "circle.dashed.inset.filled"
            case .anchors: return "calendar.badge.clock"
            }
        }
    }

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var proStore: ProStoreService

    @State private var currentTab: ActiveTab = .plans
    @State private var showSideDrawer: Bool = false
    @State private var activeMenuDestination: SideMenuDestination? = nil
    @State private var showShineJar: Bool = false
    @State private var showAddModal: Bool = false

    // 发光庆祝与星籽入罐动效状态
    @State private var particleBurstId: Int = 0
    @State private var seedFlightId: Int = 0
    @State private var seedFlightStart: CGPoint = CGPoint(x: 195, y: 420)
    @State private var jarTargetPoint: CGPoint = CGPoint(x: 315, y: 62)
    @State private var jarPulse: Bool = false

    var body: some View {
        GeometryReader { rootGeo in
            ZStack {
                // 1. Tiimo 风格梦幻薰衣草柔雾背景
                ImmersiveBackgroundView()

                // 2. 顶部悬浮栏 + 主列表内容
                VStack(spacing: 0) {
                    topHeaderBar
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .padding(.bottom, 8)

                    Group {
                        switch currentTab {
                        case .plans:
                            PlanListView(
                                onQuickAdd: { showAddModal = true },
                                onOpenShineJar: { showShineJar = true },
                                onSwitchTab: { tab in
                                    withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                                        currentTab = tab
                                    }
                                }
                            )
                        case .habits:
                            HabitListView(
                                onQuickAdd: { showAddModal = true },
                                onOpenShineJar: { showShineJar = true }
                            )
                        case .anchors:
                            AnchorListView(
                                onQuickAdd: { showAddModal = true },
                                onOpenShineJar: { showShineJar = true }
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
                }

                // 3. 底部 Tiimo 双段式悬浮胶囊导航栏
                VStack {
                    Spacer()
                    LiquidGlassTabBar(
                        currentTab: $currentTab,
                        onSelectTab: { tab in
                            SensoryFeedbackService.shared.selection()
                            withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                                currentTab = tab
                            }
                        },
                        onTapAnalytics: {
                            activeMenuDestination = .analytics
                        },
                        onTapAdd: {
                            showAddModal = true
                        }
                    )
                }

                // 4. 无阻断全屏星光粒子绽放层
                StarburstParticleLayer(burstId: particleBurstId, isGrand: true)
                    .ignoresSafeArea()

                // 5. 星籽弧线飞入顶部「发光星籽罐」胶囊动效层（与 MainRootSpace 同处安全区坐标系，落点精准对齐胶囊中心）
                FlyingStarSeedOverlay(
                    flightId: seedFlightId,
                    startPoint: seedFlightStart,
                    targetPoint: jarTargetPoint
                ) {
                    triggerJarPulse()
                }

                // 6. 左侧滑出圆角抽屉（显式传入安全区边距，防止被灵动岛或底部横条遮挡）
                SideDrawerOverlay(
                    isPresented: $showSideDrawer,
                    topInset: rootGeo.safeAreaInsets.top,
                    bottomInset: rootGeo.safeAreaInsets.bottom
                ) { destination in
                    activeMenuDestination = destination
                }
                .zIndex(500)

                // 7. 顶层全局高光庆祝海报（关闭时触发星籽飞入星籽罐动效，蓄力满关闭额外绽放一次星光）
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
            .onChange(of: appState.activeCelebration?.id) { newId in
                if newId != nil {
                    particleBurstId += 1
                }
            }
        }
        .sheet(item: $activeMenuDestination) { dest in
            switch dest {
            case .settings: SettingsSheet()
            case .analytics: AnalyticsSheet()
            case .archive: ArchiveSheet()
            case .help: HelpSheet()
            case .legal: LegalSheet()
            }
        }
        .sheet(isPresented: $showShineJar) {
            ShineJarSheet()
        }
        .sheet(isPresented: $appState.showProPaywall) {
            ProPaywallSheet()
        }
        .sheet(isPresented: $showAddModal) {
            switch currentTab {
            case .plans:
                AddPlanSheet()
            case .habits:
                AddHabitSheet()
            case .anchors:
                AddAnchorSheet()
            }
        }
    }

    private var topHeaderBar: some View {
        HStack(spacing: 8) {
            // 左侧：Tiimo 截图同款圆形白底极简双横线菜单按钮
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
                .background(
                    ZStack {
                        Circle().fill(.ultraThinMaterial)
                        Circle().fill(Color.white.opacity(0.82))
                    }
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.92), lineWidth: 1)
                )
                .shadow(color: BotanicalTheme.shadowLight, radius: 12, y: 4)
            }
            .buttonStyle(ScaleBounceButtonStyle(scale: 0.92))
            .accessibilityLabel("打开侧边菜单")

            Spacer(minLength: 4)

            // 居中：Tiimo 截图同款「获取 PRO ✨」悬浮磨砂药丸按钮（HStack 弹性居中，窄屏/大字号下绝不与两侧重叠）
            Button {
                SensoryFeedbackService.shared.selection()
                appState.showProPaywall = true
            } label: {
                HStack(spacing: 5) {
                    Text(proStore.isPro ? "微行动 PRO" : "获取 PRO")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(BotanicalTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Image(systemName: "sparkle")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(BotanicalTheme.primary)
                }
                .padding(.horizontal, 16)
                .frame(height: 42)
                .background(
                    ZStack {
                        Capsule().fill(.ultraThinMaterial)
                        Capsule().fill(Color.white.opacity(0.78))
                    }
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.95), lineWidth: 1.1)
                )
                .shadow(color: BotanicalTheme.shadowLight, radius: 14, y: 4)
            }
            .buttonStyle(ScaleBounceButtonStyle(scale: 0.94))
            .layoutPriority(1)

            Spacer(minLength: 4)

            // 右侧：发光星籽罐胶囊入口（明确区分「今日」与「星籽」累计语义，保留星籽落点追踪与脉冲动效）
            let hasToday = appState.todayShineCount > 0
            Button {
                SensoryFeedbackService.shared.selection()
                showShineJar = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(hasToday || jarPulse ? BotanicalTheme.gold : BotanicalTheme.primary)

                    Text(
                        hasToday
                            ? "今日 \(appState.todayShineCount)"
                            : "星籽 \(appState.shineRecords.count)"
                    )
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundColor(BotanicalTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(
                    ZStack {
                        Capsule().fill(.ultraThinMaterial)
                        Capsule().fill(Color.white.opacity(0.82))
                    }
                )
                .overlay(
                    Capsule()
                        .stroke(
                            jarPulse
                                ? BotanicalTheme.gold.opacity(0.85)
                                : Color.white.opacity(0.92),
                            lineWidth: 1.1
                        )
                )
                .shadow(
                    color: jarPulse
                        ? BotanicalTheme.gold.opacity(0.45)
                        : BotanicalTheme.shadowLight,
                    radius: jarPulse ? 14 : 12,
                    y: jarPulse ? 0 : 4
                )
                .scaleEffect(jarPulse ? 1.12 : 1.0)
                .animation(.spring(response: 0.24, dampingFraction: 0.62), value: jarPulse)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("打开发光星籽罐")
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
