import SwiftUI

/// 原生 SwiftUI 主界面（森系顶部标题栏 + 今日发光星籽罐胶囊 + 计划/习惯/锚点悬浮切换栏 + 顶层庆祝海报）
struct MainTabView: View {
    enum ActiveTab: String, CaseIterable {
        case plans = "计划"
        case habits = "习惯"
        case anchors = "锚点"

        var iconName: String {
            switch self {
            case .plans: return "checklist"
            case .habits: return "leaf.fill"
            case .anchors: return "clock.badge.checkmark"
            }
        }
    }

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var proStore: ProStoreService

    @State private var currentTab: ActiveTab = .plans
    @State private var showSideMenu: Bool = false
    @State private var showShineJar: Bool = false
    @State private var showAddModal: Bool = false

    var body: some View {
        ZStack {
            BotanicalTheme.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                topHeaderBar
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
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
            }

            // 底部悬浮导航条 + 发光新建按钮
            VStack {
                Spacer()
                HStack(spacing: 14) {
                    floatingTabBar
                    floatingAddButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
            }

            // 顶层全局高光庆祝海报（确保在主页点击完成时直出最顶层）
            if let payload = appState.activeCelebration {
                CelebrationPosterView(payload: payload) {
                    appState.activeCelebration = nil
                }
                .zIndex(999)
            }
        }
        .sheet(isPresented: $showSideMenu) {
            SideMenuSheet()
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
            Button {
                SensoryFeedbackService.shared.selection()
                showSideMenu = true
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(BotanicalTheme.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(BotanicalTheme.surface.opacity(0.9))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(BotanicalTheme.border, lineWidth: 1))
            }

            Text("微行动")
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(BotanicalTheme.textPrimary)

            Button {
                SensoryFeedbackService.shared.selection()
                showShineJar = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: 0xD97706))
                    Text("今日发光 \(appState.todayShineCount) 次")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(BotanicalTheme.primaryDark)
                }
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(BotanicalTheme.surface.opacity(0.92))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(BotanicalTheme.primary.opacity(0.22), lineWidth: 1))
            }

            Spacer()

            Button {
                SensoryFeedbackService.shared.selection()
                appState.showProPaywall = true
            } label: {
                Image(systemName: proStore.isPro ? "crown.fill" : "crown")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(proStore.isPro ? Color(hex: 0xD97706) : BotanicalTheme.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(proStore.isPro ? Color(hex: 0xFEF3C7) : BotanicalTheme.surface.opacity(0.9))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(BotanicalTheme.border, lineWidth: 1))
            }
        }
    }

    private var floatingTabBar: some View {
        HStack(spacing: 6) {
            ForEach(ActiveTab.allCases, id: \.self) { tab in
                let isSelected = currentTab == tab
                Button {
                    SensoryFeedbackService.shared.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        currentTab = tab
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 14, weight: .bold))
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(isSelected ? .white : BotanicalTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(isSelected ? BotanicalTheme.primary : Color.clear)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(5)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.7), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.08), radius: 14, y: 6)
    }

    private var floatingAddButton: some View {
        Button {
            SensoryFeedbackService.shared.lightTap()
            showAddModal = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 54, height: 54)
                .background(BotanicalTheme.primaryGradient)
                .clipShape(Circle())
                .shadow(color: BotanicalTheme.primary.opacity(0.36), radius: 12, y: 6)
        }
    }
}
