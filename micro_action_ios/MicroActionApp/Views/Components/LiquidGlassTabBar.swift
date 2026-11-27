import SwiftUI

/// Tiimo 风格双段式悬浮底部导航栏（左侧白底玻璃 4 图标长胶囊沉稳不动 + 右侧悬浮柔光精灵新建按钮冷/热启动俏皮歪头动效）
struct LiquidGlassTabBar: View {
    @Binding var currentTab: MainTabView.ActiveTab
    var replayToken: Int = 0
    let onSelectTab: (MainTabView.ActiveTab) -> Void
    let onTapAdd: () -> Void

    @Namespace private var pillNamespace

    @State private var isDraggingDock: Bool = false
    @State private var dragLocationX: CGFloat? = nil
    @State private var dragStretch: CGFloat = 1.0
    @State private var dockWidth: CGFloat = 280

    private let inactiveColor = Color(hex: 0x5E6470)
    private let dockHeight: CGFloat = 56
    private let dockInnerPad: CGFloat = 4

    var body: some View {
        HStack(spacing: 10) {
            floatingIconDock

            mascotAddOrbButton
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    /// 左侧液态玻璃 4 图标长胶囊（严格内嵌横向扁胶囊 + 连续跟手流体滑动 + 水滴弹性形变）
    @ViewBuilder
    private var floatingIconDock: some View {
        let tabs = MainTabView.ActiveTab.allCases
        let activeIdx = tabs.firstIndex(of: currentTab) ?? 0
        let innerWidth = max(1, dockWidth - dockInnerPad * 2)
        let cellWidth = innerWidth / CGFloat(max(1, tabs.count))
        let pillHeight = dockHeight - dockInnerPad * 2 // 48pt，严丝合缝内嵌于 56pt 外框内
        let minCenterX = dockInnerPad + cellWidth * 0.5
        let maxCenterX = dockWidth - dockInnerPad - cellWidth * 0.5
        let targetCenterX = dockInnerPad + (CGFloat(activeIdx) + 0.5) * cellWidth
        let pillCenterX: CGFloat = {
            if let dragX = dragLocationX {
                return min(maxCenterX, max(minCenterX, dragX))
            }
            return targetCenterX
        }()

        let dockRow = ZStack(alignment: .leading) {
            // 连续流体滑块（唯一内嵌玻璃扁胶囊，点击/拖动时连续实时滑动，绝不溢出外框）
            activeTabLens(width: cellWidth, height: pillHeight)
                .position(x: pillCenterX, y: dockHeight * 0.5)
                .allowsHitTesting(false)

            HStack(spacing: 0) {
                ForEach(tabs, id: \.self) { tab in
                    let isActive = currentTab == tab
                    Button {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.76)) {
                            onSelectTab(tab)
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: isActive ? tab.activeIconName : tab.iconName)
                                .font(.system(size: 18, weight: isActive ? .semibold : .regular))
                                .foregroundColor(isActive ? BotanicalTheme.primaryDark : inactiveColor)

                            Text(tab.rawValue)
                                .font(.system(size: 9.5, weight: isActive ? .bold : .medium))
                                .foregroundColor(isActive ? BotanicalTheme.primaryDark : inactiveColor.opacity(0.88))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(ScaleBounceButtonStyle(scale: 0.94))
                }
            }
            .padding(.horizontal, dockInnerPad)
        }
        .frame(height: dockHeight)
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
            DragGesture(minimumDistance: 6, coordinateSpace: .local)
                .onChanged { value in
                    if !isDraggingDock {
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.78)) {
                            isDraggingDock = true
                        }
                    }
                    dragLocationX = value.location.x
                    let speed = min(1.0, abs(value.velocity.width) / 900.0)
                    dragStretch = 1.0 + 0.04 + speed * 0.08

                    let clampedX = min(innerWidth - 1, max(0, value.location.x - dockInnerPad))
                    let idx = min(tabs.count - 1, max(0, Int(clampedX / max(1, cellWidth))))
                    let targetTab = tabs[idx]
                    if targetTab != currentTab {
                        SensoryFeedbackService.shared.mechanicalDialTick()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                            onSelectTab(targetTab)
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.72)) {
                        dragLocationX = nil
                        isDraggingDock = false
                        dragStretch = 1.0
                    }
                }
        )

        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 6) {
                dockRow
                    .glassEffect(.regular.interactive(), in: .capsule)
            }
        } else {
            dockRow
                .liquidGlassCapsule(tint: .white, interactive: true, shadowRadius: 18)
        }
        #else
        dockRow
            .liquidGlassCapsule(tint: .white, interactive: true, shadowRadius: 18)
        #endif
    }

    /// 选中态内嵌液态玻璃扁胶囊（外层已启用原生 .glassEffect，内层采用零开销纯白镜面高光胶囊避免双层实时采样掉帧）
    @ViewBuilder
    private func activeTabLens(width: CGFloat, height: CGFloat) -> some View {
        let scaleX = isDraggingDock ? dragStretch : 1.0
        let scaleY = isDraggingDock ? max(0.92, 1.0 - (dragStretch - 1.0) * 0.35) : 1.0

        fallbackLiquidPill(width: width, height: height, scaleX: scaleX, scaleY: scaleY)
    }

    /// iOS 16–25 纯净无彩虹边框的通透水滴玻璃扁胶囊（1:1 模拟 iOS 26 原生选中态）
    private func fallbackLiquidPill(width: CGFloat, height: CGFloat, scaleX: CGFloat, scaleY: CGFloat) -> some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(isDraggingDock ? 0.94 : 0.88),
                        Color.white.opacity(isDraggingDock ? 0.62 : 0.56)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.96),
                                Color.white.opacity(0.28)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.75
                    )
            )
            .shadow(color: Color.black.opacity(isDraggingDock ? 0.11 : 0.07), radius: isDraggingDock ? 8 : 5, y: 2)
            .frame(width: width, height: height)
            .scaleEffect(x: scaleX, y: scaleY)
    }

    /// 右下角独立悬浮 iOS 26 液态玻璃小芽宠物新建球（纯净锐利玻璃底 + 可爱小芽宠物 + 右下角小加号，无糊边无循环晃动）
    @ViewBuilder
    private var mascotAddOrbButton: some View {
        let orbContent = ZStack {
            Circle()
                .fill(Color.clear)
                .frame(width: 56, height: 56)
                .liquidGlassCircle(tint: BotanicalTheme.primaryLight, interactive: true, shadowRadius: 14)

            TiimoMascotOrbView(style: .dockAvatar)
                .frame(width: 44, height: 44)

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
        .frame(width: 56, height: 56)

        Button {
            SensoryFeedbackService.shared.lightTap()
            onTapAdd()
        } label: {
            orbContent
        }
        .buttonStyle(ScaleBounceButtonStyle(scale: 0.90))
        .accessibilityLabel("新建微行动")
    }
}
