import SwiftUI

/// 原版液态玻璃底部悬浮导航条 + 森绿光晕新建按钮（Liquid Glass Bar & Glow FAB）
struct LiquidGlassTabBar: View {
    @Binding var currentTab: MainTabView.ActiveTab
    let onSelectTab: (MainTabView.ActiveTab) -> Void
    let onTapAdd: () -> Void

    @Namespace private var pillNamespace

    private let inactiveColor = Color(hex: 0x3F5A4B)

    var body: some View {
        HStack(spacing: 14) {
            liquidGlassSwitcher
            Spacer(minLength: 0)
            glowAddButton
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 14)
    }

    /// 液态玻璃容器（磨砂底 + 青碧色散光泽 + 左上角镜面高光 + 渐变高光描边 + 丝滑滑块胶囊）
    private var liquidGlassSwitcher: some View {
        HStack(spacing: 2) {
            ForEach(MainTabView.ActiveTab.allCases, id: \.self) { tab in
                let isActive = currentTab == tab
                Button {
                    onSelectTab(tab)
                } label: {
                    ZStack {
                        if isActive {
                            Capsule()
                                .fill(BotanicalTheme.activePillGradient)
                                .overlay(
                                    // 顶部液态玻璃弧形高光
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.36),
                                            Color.white.opacity(0.08),
                                            .clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .center
                                    )
                                    .clipShape(Capsule())
                                )
                                .shadow(
                                    color: BotanicalTheme.primary.opacity(0.24),
                                    radius: 10,
                                    y: 3
                                )
                                .matchedGeometryEffect(id: "ActiveTabPill", in: pillNamespace)
                        }

                        HStack(spacing: 5) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 15, weight: .semibold))
                            Text(tab.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .foregroundColor(isActive ? .white : inactiveColor)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 10)
                    }
                }
                .buttonStyle(ScaleBounceButtonStyle(scale: 0.93))
            }
        }
        .padding(5)
        .background(
            ZStack {
                Capsule()
                    .fill(.ultraThinMaterial)

                Capsule()
                    .fill(Color.white.opacity(0.58))

                // 柔和色散光泽
                Capsule()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.45), location: 0.0),
                                .init(color: BotanicalTheme.primary.opacity(0.06), location: 0.40),
                                .init(color: BotanicalTheme.secondary.opacity(0.05), location: 0.65),
                                .init(color: Color.white.opacity(0.35), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // 左上角镜面高光
                Capsule()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.62), .clear],
                            center: UnitPoint(x: 0.12, y: 0.08),
                            startRadius: 0,
                            endRadius: 90
                        )
                    )
            }
        )
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.95), location: 0.0),
                            .init(color: Color.white.opacity(0.42), location: 0.30),
                            .init(color: BotanicalTheme.primary.opacity(0.18), location: 0.75),
                            .init(color: Color.white.opacity(0.75), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        )
        .shadow(color: BotanicalTheme.primaryDark.opacity(0.09), radius: 22, y: 10)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
    }

    /// 右下角森绿柔和光晕新建按钮（复刻原版 _GlowAddButton）
    private var glowAddButton: some View {
        Button {
            SensoryFeedbackService.shared.lightTap()
            onTapAdd()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 58, height: 58)
                .background(BotanicalTheme.primaryGradient)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.38), lineWidth: 1)
                )
                .shadow(color: BotanicalTheme.primaryLight.opacity(0.44), radius: 18, y: 0)
                .shadow(color: BotanicalTheme.primaryDark.opacity(0.22), radius: 10, y: 5)
        }
        .buttonStyle(ScaleBounceButtonStyle(scale: 0.91))
    }
}
