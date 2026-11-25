import SwiftUI

/// Tiimo 风格双段式悬浮底部导航栏（左侧白底玻璃 4 图标长胶囊沉稳不动 + 右侧悬浮柔光精灵新建按钮冷/热启动俏皮歪头动效）
struct LiquidGlassTabBar: View {
    @Binding var currentTab: MainTabView.ActiveTab
    var replayToken: Int = 0
    let onSelectTab: (MainTabView.ActiveTab) -> Void
    let onTapAdd: () -> Void

    @Namespace private var pillNamespace

    @State private var orbOffsetY: CGFloat = 0
    @State private var orbScale: CGFloat = 1.0
    @State private var isAuraBreathing: Bool = false
    @State private var isDraggingDock: Bool = false
    @State private var dockWidth: CGFloat = 260

    private let inactiveColor = Color(hex: 0x6D6A7E)

    var body: some View {
        HStack(spacing: 12) {
            floatingIconDock

            mascotAddOrbButton
                .scaleEffect(orbScale)
                .offset(y: orbOffsetY)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                isAuraBreathing = true
            }
        }
        .onChange(of: replayToken) { _ in
            playAddButtonWakeAnimation()
        }
    }

    /// 左侧液态玻璃 4 图标长胶囊（支持 iOS 26 原生 Liquid Glass 凸起水滴透镜 + 横向滑动跟随）
    @ViewBuilder
    private var floatingIconDock: some View {
        let tabs = MainTabView.ActiveTab.allCases
        let dockRow = HStack(spacing: 4) {
            ForEach(tabs, id: \.self) { tab in
                let isActive = currentTab == tab
                Button {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.74)) {
                        onSelectTab(tab)
                    }
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
                            activeTabLens
                        }
                    }
                }
                .buttonStyle(ScaleBounceButtonStyle(scale: 0.94))
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .frame(height: 60)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { dockWidth = max(1, geo.size.width) }
                    .onChange(of: geo.size.width) { newW in
                        dockWidth = max(1, newW)
                    }
            }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 8, coordinateSpace: .local)
                .onChanged { value in
                    if !isDraggingDock {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.76)) {
                            isDraggingDock = true
                        }
                    }
                    let cellW = max(1, dockWidth / CGFloat(max(1, tabs.count)))
                    let idx = min(tabs.count - 1, max(0, Int(value.location.x / cellW)))
                    let targetTab = tabs[idx]
                    if targetTab != currentTab {
                        SensoryFeedbackService.shared.selection()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.74)) {
                            onSelectTab(targetTab)
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.72)) {
                        isDraggingDock = false
                    }
                }
        )

        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 8) {
                dockRow
                    .glassEffect(.regular.tint(BotanicalTheme.primaryLight.opacity(0.08)).interactive(), in: .capsule)
            }
        } else {
            dockRow
                .liquidGlassCapsule(tint: BotanicalTheme.primaryLight, interactive: true, shadowRadius: 20)
        }
        #else
        dockRow
            .liquidGlassCapsule(tint: BotanicalTheme.primaryLight, interactive: true, shadowRadius: 20)
        #endif
    }

    /// 选中态液态水滴透镜胶囊（iOS 26 使用原生 .glassEffectID + 凸起折射；低版本使用光学棱镜高光胶囊）
    @ViewBuilder
    private var activeTabLens: some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(BotanicalTheme.primarySoft.opacity(0.32))
                .frame(height: 54)
                .glassEffect(.regular.tint(BotanicalTheme.primaryLight.opacity(0.16)).interactive(), in: .capsule)
                .glassEffectID("ActiveTabLens", in: pillNamespace)
                .scaleEffect(x: isDraggingDock ? 1.09 : 1.04, y: isDraggingDock ? 1.07 : 1.05)
        } else {
            fallbackPrismLens
        }
        #else
        fallbackPrismLens
        #endif
    }

    /// iOS 16–25 兼容的高透光学棱镜水滴胶囊（模拟边缘色散折射高光）
    private var fallbackPrismLens: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.86),
                        BotanicalTheme.primarySoft.opacity(0.55)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: Color(hex: 0xA8E6CF).opacity(0.75), location: 0.0),
                                .init(color: Color.white.opacity(0.95), location: 0.35),
                                .init(color: Color(hex: 0xFFD3B6).opacity(0.65), location: 0.72),
                                .init(color: Color(hex: 0xBDE0FE).opacity(0.70), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.3
                    )
            )
            .shadow(color: BotanicalTheme.primaryDark.opacity(0.10), radius: 8, y: 2)
            .frame(height: 54)
            .scaleEffect(x: isDraggingDock ? 1.09 : 1.04, y: isDraggingDock ? 1.07 : 1.05)
            .matchedGeometryEffect(id: "ActiveTabPill", in: pillNamespace)
    }

    /// 右下角独立悬浮 iOS 液态玻璃极简呼吸新建球
    private var mascotAddOrbButton: some View {
        Button {
            SensoryFeedbackService.shared.lightTap()
            onTapAdd()
        } label: {
            ZStack {
                // 极柔和慢呼吸森光微晕
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                BotanicalTheme.primaryLight.opacity(isAuraBreathing ? 0.34 : 0.14),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 16,
                            endRadius: 36
                        )
                    )
                    .frame(width: 68, height: 68)
                    .scaleEffect(isAuraBreathing ? 1.06 : 0.96)
                    .allowsHitTesting(false)

                Circle()
                    .fill(Color.clear)
                    .frame(width: 58, height: 58)
                    .liquidGlassCircle(tint: BotanicalTheme.primaryLight, interactive: true, shadowRadius: 16)

                TiimoMascotOrbView(style: .dockAvatar)
                    .frame(width: 44, height: 44)
                    .opacity(0.95)

                // 右下角精巧翡翠加号微章
                Image(systemName: "plus")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 19, height: 19)
                    .background(BotanicalTheme.primaryGradient)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 1.6)
                    )
                    .offset(x: 19, y: 19)
            }
        }
        .buttonStyle(ScaleBounceButtonStyle(scale: 0.92))
        .accessibilityLabel("新建微行动")
    }

    /// 丝滑单次物理弹簧唤醒动效（克制优雅，无机械多段摇头）
    private func playAddButtonWakeAnimation() {
        orbOffsetY = 8
        orbScale = 0.92
        withAnimation(.spring(response: 0.46, dampingFraction: 0.80)) {
            orbOffsetY = 0
            orbScale = 1.0
        }
    }
}
