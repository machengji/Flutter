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
    @State private var mascotTilt: Double = 0
    @State private var plusRotation: Double = 0
    @State private var plusScale: CGFloat = 1.0

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
        .onChange(of: replayToken) { _ in
            playAddButtonWakeAnimation()
        }
    }

    /// 左侧液态玻璃 4 图标长胶囊（保持绝对沉稳零抖动）
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
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .frame(height: 60)
        .liquidGlassCapsule(tint: BotanicalTheme.primaryLight, interactive: true, shadowRadius: 20)
    }

    /// 右下角独立悬浮 iOS 液态玻璃森系精灵新建按钮
    private var mascotAddOrbButton: some View {
        Button {
            SensoryFeedbackService.shared.lightTap()
            onTapAdd()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 60, height: 60)
                    .liquidGlassCircle(tint: BotanicalTheme.primaryLight, interactive: true, shadowRadius: 18)

                TiimoMascotOrbView(style: .dockAvatar)
                    .frame(width: 46, height: 46)
                    .clipShape(Circle())
                    .rotationEffect(.degrees(mascotTilt))

                // 右下角精致翡翠绿加号微章
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
                    .rotationEffect(.degrees(plusRotation))
                    .scaleEffect(plusScale)
                    .offset(x: 20, y: 20)
            }
        }
        .buttonStyle(ScaleBounceButtonStyle(scale: 0.90))
        .accessibilityLabel("新建微行动")
    }

    /// 仅针对右下角精灵「+」添加按钮的冷/热启动俏皮唤醒动画：轻跃 + 小芽精灵歪头打招呼 + 加号微旋绽放
    private func playAddButtonWakeAnimation() {
        orbOffsetY = 10
        orbScale = 0.88
        plusScale = 0.70
        plusRotation = -90

        withAnimation(.spring(response: 0.42, dampingFraction: 0.62)) {
            orbOffsetY = 0
            orbScale = 1.0
        }
        withAnimation(.spring(response: 0.26, dampingFraction: 0.50)) {
            mascotTilt = -10
        }
        withAnimation(.spring(response: 0.38, dampingFraction: 0.60).delay(0.06)) {
            plusRotation = 0
            plusScale = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.54)) {
                mascotTilt = 6
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.70)) {
                mascotTilt = 0
            }
        }
    }
}
