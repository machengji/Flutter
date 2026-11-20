import SwiftUI

/// 专为 ScrollView + LazyVStack 打造的丝滑左滑操作容器
/// - 智能角度锁：仅当横向位移明显大于垂直位移时才响应左滑，绝不干扰上下滚动
/// - 支持轻滑悬停点击或深拉直接触发，松手弹性回弹
struct SwipeActionCardWrapper<Content: View>: View {
    let enabled: Bool
    let actionTitle: String
    let actionIcon: String
    let actionTint: Color
    let onTriggerAction: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var offsetX: CGFloat = 0
    @State private var isOpen: Bool = false

    private let revealWidth: CGFloat = 92
    private let fullSwipeThreshold: CGFloat = 148

    var body: some View {
        if !enabled {
            content()
        } else {
            ZStack(alignment: .trailing) {
                // 底层左滑操作按钮（仅在拉出时渐显，零平时多余渲染）
                if offsetX < -4 {
                    Button {
                        closeAndRun()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: actionIcon)
                                .font(.system(size: 16, weight: .bold))
                            Text(actionTitle)
                                .font(.system(size: 11, weight: .bold))
                                .lineLimit(1)
                        }
                        .foregroundColor(.white)
                        .frame(width: max(68, min(-offsetX - 8, 120)))
                        .frame(maxHeight: .infinity)
                        .background(actionTint)
                        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 2)
                    .transition(.opacity)
                }

                content()
                    .offset(x: offsetX)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 16, coordinateSpace: .local)
                            .onChanged { value in
                                let dx = value.translation.width
                                let dy = value.translation.height
                                // 角度锁：垂直滑动不拦截，保证列表滚动 120Hz 丝滑
                                guard abs(dx) > abs(dy) * 1.25 || isOpen else { return }

                                let base: CGFloat = isOpen ? -revealWidth : 0
                                let raw = base + dx
                                if raw > 0 {
                                    offsetX = raw * 0.18
                                } else {
                                    offsetX = max(raw, -(fullSwipeThreshold + 24))
                                }
                            }
                            .onEnded { value in
                                let dx = value.translation.width
                                let dy = value.translation.height
                                guard abs(dx) > abs(dy) * 1.25 || isOpen else { return }

                                if -offsetX >= fullSwipeThreshold {
                                    closeAndRun()
                                } else if -offsetX >= revealWidth * 0.55 {
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                                        offsetX = -revealWidth
                                        isOpen = true
                                    }
                                } else {
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                                        offsetX = 0
                                        isOpen = false
                                    }
                                }
                            }
                    )
            }
        }
    }

    private func closeAndRun() {
        SensoryFeedbackService.shared.lightTap()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
            offsetX = 0
            isOpen = false
        }
        onTriggerAction()
    }
}
