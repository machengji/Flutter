import SwiftUI

/// Tiimo 风格双段式悬浮底部导航栏（左侧白底玻璃 4 图标长胶囊 + 右侧独立悬浮柔光精灵新建按钮）
struct LiquidGlassTabBar: View {
    @Binding var currentTab: MainTabView.ActiveTab
    let onSelectTab: (MainTabView.ActiveTab) -> Void
    let onTapAnalytics: () -> Void
    let onTapAdd: () -> Void

    @Namespace private var pillNamespace

    private let inactiveColor = Color(hex: 0x6D6A7E)

    var body: some View {
        HStack(spacing: 12) {
            floatingIconDock
            mascotAddOrbButton
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    /// 左侧白底磨砂 4 图标长胶囊（计划 / 习惯 / 锚点 / 洞察，固定 60pt 与右侧精灵圆球等高对齐）
    private var floatingIconDock: some View {
        HStack(spacing: 4) {
            ForEach(MainTabView.ActiveTab.allCases, id: \.self) { tab in
                let isActive = currentTab == tab
                Button {
                    onSelectTab(tab)
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: isActive ? tab.activeIconName : tab.iconName)
                            .font(.system(size: 19, weight: isActive ? .semibold : .regular))
                            .foregroundColor(isActive ? BotanicalTheme.primary : inactiveColor)

                        Text(tab.rawValue)
                            .font(.system(size: 9.5, weight: isActive ? .bold : .medium))
                            .foregroundColor(isActive ? BotanicalTheme.primaryDark : inactiveColor.opacity(0.85))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        if isActive {
                            Capsule()
                                .fill(BotanicalTheme.primarySoft)
                                .overlay(
                                    Capsule()
                                        .stroke(BotanicalTheme.primary.opacity(0.20), lineWidth: 0.9)
                                )
                                .matchedGeometryEffect(id: "ActiveTabPill", in: pillNamespace)
                        }
                    }
                }
                .buttonStyle(ScaleBounceButtonStyle(scale: 0.93))
            }

            // 第 4 枚图标：数据洞察（呼应 Tiimo 底部柱状图图标，点击直达数据分析页）
            Button {
                SensoryFeedbackService.shared.selection()
                onTapAnalytics()
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 19, weight: .regular))
                        .foregroundColor(inactiveColor)

                    Text("洞察")
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundColor(inactiveColor.opacity(0.85))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(ScaleBounceButtonStyle(scale: 0.93))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .frame(height: 60)
        .background(
            ZStack {
                Capsule()
                    .fill(.ultraThinMaterial)
                Capsule()
                    .fill(Color.white.opacity(0.82))
            }
        )
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            BotanicalTheme.border.opacity(0.85)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: BotanicalTheme.shadowMedium, radius: 20, y: 8)
        .shadow(color: Color.black.opacity(0.03), radius: 6, y: 2)
    }

    /// 右下角 Tiimo 同款独立悬浮圆形柔光精灵按钮（轻点快速新建当前 Tab 微行动）
    private var mascotAddOrbButton: some View {
        Button {
            SensoryFeedbackService.shared.lightTap()
            onTapAdd()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.96))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(BotanicalTheme.border.opacity(0.90), lineWidth: 1)
                    )
                    .shadow(color: BotanicalTheme.shadowMedium, radius: 18, y: 8)

                TiimoMascotOrbView(style: .dockAvatar)
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())

                // 右下角精致加号微章，清晰传达新建意图
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(BotanicalTheme.primaryGradient)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 1.8)
                    )
                    .offset(x: 20, y: 20)
            }
        }
        .buttonStyle(ScaleBounceButtonStyle(scale: 0.90))
        .accessibilityLabel("新建微行动")
    }
}
