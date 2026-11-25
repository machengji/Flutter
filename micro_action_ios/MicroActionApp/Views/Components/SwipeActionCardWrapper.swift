import SwiftUI

/// 专为 ScrollView + LazyVStack 打造的防误触左滑操作容器
/// - 严格方向锁：仅当明确向左滑（dx < -18）且横向位移超过垂直位移 2.4 倍时才介入
/// - 彻底禁止未展开时的向右拖动，自然上下滚动列表 0 误触
struct SwipeActionCardWrapper<Content: View>: View {
    let enabled: Bool
    let actionTitle: String
    let actionIcon: String
    let actionTint: Color
    let onTriggerAction: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var offsetX: CGFloat = 0
    @State private var isOpen: Bool = false
    @State private var lockedAxis: Axis? = nil

    private let revealWidth: CGFloat = 92
    private let fullSwipeThreshold: CGFloat = 156

    var body: some View {
        if !enabled {
            content()
        } else {
            ZStack(alignment: .trailing) {
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
                        DragGesture(minimumDistance: 22, coordinateSpace: .local)
                            .onChanged { value in
                                let dx = value.translation.width
                                let dy = value.translation.height

                                // 首帧方向锁定：一旦判定为垂直滚动，整个手势周期彻底放行
                                if lockedAxis == nil {
                                    if abs(dy) > 8 && abs(dy) >= abs(dx) * 0.60 {
                                        lockedAxis = .vertical
                                        return
                                    }
                                    if isOpen {
                                        if abs(dx) > 16 && abs(dx) > abs(dy) * 1.8 {
                                            lockedAxis = .horizontal
                                        } else {
                                            return
                                        }
                                    } else {
                                        // 未展开时：严禁向右滑动触发，仅允许明确向左滑
                                        if dx < -22 && abs(dx) > abs(dy) * 2.4 {
                                            lockedAxis = .horizontal
                                        } else {
                                            return
                                        }
                                    }
                                }

                                guard lockedAxis == .horizontal else { return }

                                let base: CGFloat = isOpen ? -revealWidth : 0
                                let raw = base + dx
                                // 彻底禁止向右拉出（最小值限制在 0，不往右晃动）
                                offsetX = min(0, max(raw, -(fullSwipeThreshold + 20)))
                            }
                            .onEnded { _ in
                                defer { lockedAxis = nil }
                                guard lockedAxis == .horizontal else { return }

                                if -offsetX >= fullSwipeThreshold {
                                    closeAndRun()
                                } else if -offsetX >= revealWidth * 0.58 {
                                    withAnimation(.spring(response: 0.26, dampingFraction: 0.88)) {
                                        offsetX = -revealWidth
                                        isOpen = true
                                    }
                                } else {
                                    withAnimation(.spring(response: 0.26, dampingFraction: 0.88)) {
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
        withAnimation(.spring(response: 0.26, dampingFraction: 0.88)) {
            offsetX = 0
            isOpen = false
        }
        onTriggerAction()
    }
}
