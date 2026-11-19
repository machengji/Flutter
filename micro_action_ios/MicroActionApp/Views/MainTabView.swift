import SwiftUI

/// 原生 SwiftUI 主界面（完全复刻并升华原版 HomePage：森系晨雾三光球背景 + 顶部星籽罐脉冲胶囊 + 液态玻璃底栏 + 左侧滑出抽屉 + 星籽入罐轨迹 + 粒子绽放）
struct MainTabView: View {
    enum ActiveTab: String, CaseIterable {
        case plans = "计划"
        case habits = "习惯"
        case anchors = "锚点"

        var iconName: String {
            switch self {
            case .plans: return "checklist"
            case .habits: return "wind"
            case .anchors: return "clock.badge.checkmark"
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
    @State private var jarTargetPoint: CGPoint = CGPoint(x: 185, y: 62)
    @State private var jarPulse: Bool = false

    var body: some View {
        GeometryReader { rootGeo in
            ZStack {
                // 1. 原版森系晨雾与自然光影背景
                ImmersiveBackgroundView()

                // 2. 顶部栏 + 主列表内容
                VStack(spacing: 0) {
                    topHeaderBar
                        .padding(.horizontal, 24)
                        .padding(.top, 14)
                        .padding(.bottom, 8)

                    Group {
                        switch currentTab {
                        case .plans:
                            PlanListView()
                        case .habits:
                            HabitListView()
                        case .anchors:
                            AnchorListView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
                }

                // 3. 底部液态玻璃悬浮导航条 + 森绿光晕新建按钮
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

                // 6. 左侧滑出森系抽屉（显式传入安全区边距，防止被灵动岛或底部横条遮挡）
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
        HStack(spacing: 12) {
            // 原版纯白圆形柔和阴影菜单按钮
            Button {
                SensoryFeedbackService.shared.lightTap()
                withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                    showSideDrawer = true
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(BotanicalTheme.textPrimary)
                    .frame(width: 42, height: 42)
                    .background(BotanicalTheme.surface.opacity(0.94))
                    .clipShape(Circle())
                    .shadow(color: BotanicalTheme.shadowLight, radius: 12, y: 4)
            }
            .buttonStyle(ScaleBounceButtonStyle(scale: 0.92))

            Text("微行动")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(BotanicalTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            // 发光星籽罐入口胶囊（承接星籽落点与脉冲发光动效）
            let hasToday = appState.todayShineCount > 0
            Button {
                SensoryFeedbackService.shared.selection()
                showShineJar = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(hasToday || jarPulse ? Color(hex: 0xC9973B) : BotanicalTheme.textHint)

                    Text(
                        hasToday
                            ? "今日发光 \(appState.todayShineCount) 次"
                            : "发光罐 \(appState.shineRecords.count)"
                    )
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(BotanicalTheme.primaryDark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(BotanicalTheme.surface.opacity(0.94))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            jarPulse
                                ? Color(hex: 0xE2B862).opacity(0.80)
                                : BotanicalTheme.primary.opacity(0.18),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: jarPulse
                        ? Color(hex: 0xE9C46A).opacity(0.42)
                        : BotanicalTheme.shadowLight,
                    radius: jarPulse ? 12 : 10,
                    y: jarPulse ? 0 : 4
                )
                .scaleEffect(jarPulse ? 1.12 : 1.0)
                .animation(.spring(response: 0.24, dampingFraction: 0.62), value: jarPulse)
            }
            .buttonStyle(.plain)
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

            Spacer(minLength: 4)

            // Pro 尊享入口圆钮
            Button {
                SensoryFeedbackService.shared.selection()
                appState.showProPaywall = true
            } label: {
                Image(systemName: proStore.isPro ? "crown.fill" : "crown")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(proStore.isPro ? Color(hex: 0xC9973B) : BotanicalTheme.textSecondary)
                    .frame(width: 38, height: 38)
                    .background(proStore.isPro ? Color(hex: 0xFEF3C7) : BotanicalTheme.surface.opacity(0.94))
                    .clipShape(Circle())
                    .shadow(color: BotanicalTheme.shadowLight, radius: 10, y: 4)
            }
            .buttonStyle(ScaleBounceButtonStyle(scale: 0.92))
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
