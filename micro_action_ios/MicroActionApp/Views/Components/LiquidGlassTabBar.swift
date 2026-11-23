import SwiftUI

/// Tiimo 风格双段式悬浮底部导航栏（左侧白底玻璃 4 图标长胶囊 + 右侧独立悬浮柔光精灵新建按钮，支持冷/热启动交错弹性动效）
struct LiquidGlassTabBar: View {
    @Binding var currentTab: MainTabView.ActiveTab
    var replayToken: Int = 0
    let onSelectTab: (MainTabView.ActiveTab) -> Void
    let onTapAdd: () -> Void

    @Namespace private var pillNamespace

    @State private var dockOffsetY: CGFloat = 0
    @State private var dockScale: CGFloat = 1.0
    @State private var activeWaveIndex: Int = -1
    @State private var orbOffsetY: CGFloat = 0
    @State private var orbScale: CGFloat = 1.0
    @State private var mascotTilt: Double = 0
    @State private var plusRotation: Double = 0
    @State private var plusScale: CGFloat = 1.0

    private let inactiveColor = Color(hex: 0x6D6A7E)

    var body: some View {
        HStack(spacing: 12) {
            floatingIconDock
                .scaleEffect(dockScale)
                .offset(y: dockOffsetY)

            mascotAddOrbButton
                .scaleEffect(orbScale)
                .offset(y: orbOffsetY)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .onChange(of: replayToken) { _ in
            playWakeChoreography()
        }
    }

    /// 左侧液态玻璃 4 图标长胶囊（愿望 / 习惯 / 锚点 / 洞察，固定 60pt 与右侧精灵圆球等高对齐）
    private var floatingIconDock: some View {
        let tabs = MainTabView.ActiveTab.allCases
        return HStack(spacing: 4) {
            ForEach(Array(tabs.enumerated()), id: \.element) { idx, tab in
                let isActive = currentTab == tab
                let isWaveBouncing = (activeWaveIndex == idx)

                Button {
                    onSelectTab(tab)
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: isActive ? tab.activeIconName : tab.iconName)
                            .font(.system(size: 19, weight: isActive ? .semibold : .regular))
                            .foregroundColor(isActive ? BotanicalTheme.primary : inactiveColor)
                            .scaleEffect(isWaveBouncing ? 1.18 : 1.0)
                            .offset(y: isWaveBouncing ? -3.5 : 0)

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

    /// 冷/热启动底部 Dock 交错弹性唤醒编排：长胶囊浮起 -> 4 图标波浪轻跃 -> 精灵球 Q 弹歪头 -> 翡翠加号微旋绽放
    private func playWakeChoreography() {
        // 1. 瞬时微沉起势（不闪烁、不消失，保持视觉连贯）
        dockOffsetY = 14
        dockScale = 0.95
        orbOffsetY = 18
        orbScale = 0.84
        plusScale = 0.65
        plusRotation = -90

        // 2. 左侧长胶囊弹性浮起
        withAnimation(.spring(response: 0.44, dampingFraction: 0.72)) {
            dockOffsetY = 0
            dockScale = 1.0
        }

        // 3. 4 个 Tab 图标依次波浪轻跃
        for idx in 0..<MainTabView.ActiveTab.allCases.count {
            let delay = 0.06 + Double(idx) * 0.055
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.24, dampingFraction: 0.56)) {
                    activeWaveIndex = idx
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                activeWaveIndex = -1
            }
        }

        // 4. 右侧精灵新建圆球稍晚 0.07s Q 弹跃起 + 俏皮歪头 + 加号徽章旋转绽放
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.60)) {
                orbOffsetY = 0
                orbScale = 1.0
            }
            withAnimation(.spring(response: 0.26, dampingFraction: 0.48)) {
                mascotTilt = -10
            }
            withAnimation(.spring(response: 0.40, dampingFraction: 0.58).delay(0.08)) {
                plusRotation = 0
                plusScale = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.52)) {
                    mascotTilt = 6
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.68)) {
                    mascotTilt = 0
                }
            }
        }
    }
}
