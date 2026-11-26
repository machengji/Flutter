import SwiftUI

/// 列表卡片零冲突快捷操作容器（彻底移除 ScrollView 内部 DragGesture，改用原生 .contextMenu，确保 Xcode 26 下首次与久置后 100% 丝滑滚动）
struct SwipeActionCardWrapper<Content: View>: View {
    let enabled: Bool
    let actionTitle: String
    let actionIcon: String
    let actionTint: Color
    let onTriggerAction: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        if !enabled {
            content()
        } else {
            content()
                .contextMenu {
                    Button {
                        SensoryFeedbackService.shared.lightTap()
                        onTriggerAction()
                    } label: {
                        Label(actionTitle, systemImage: actionIcon)
                    }
                }
        }
    }
}
