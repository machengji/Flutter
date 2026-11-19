import SwiftUI

/// 福格时间锚点列表视图（复刻原版 24pt 边距、暖阳松果锚点卡片、快捷编辑删除与森系空状态）
struct AnchorListView: View {
    @EnvironmentObject private var appState: AppState

    @State private var selectedAnchorId: String? = nil
    @State private var editingAnchor: AnchorItem? = nil
    @State private var deletingAnchor: AnchorItem? = nil

    private var selectedAnchor: AnchorItem? {
        appState.anchors.first(where: { $0.id == selectedAnchorId })
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                if appState.anchors.isEmpty {
                    emptyStateView
                } else {
                    ForEach(appState.anchors) { anchor in
                        AnchorCardView(
                            anchor: anchor,
                            onTap: {
                                SensoryFeedbackService.shared.selection()
                                selectedAnchorId = anchor.id
                            },
                            onEdit: {
                                editingAnchor = anchor
                            },
                            onDelete: {
                                deletingAnchor = anchor
                            },
                            onToggleReminder: {
                                appState.toggleAnchorReminder(id: anchor.id)
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 130)
        }
        .sheet(isPresented: Binding(
            get: { selectedAnchor != nil },
            set: { if !$0 { selectedAnchorId = nil } }
        )) {
            if let anchor = selectedAnchor {
                AnchorDetailSheet(anchorId: anchor.id)
            }
        }
        .sheet(item: $editingAnchor) { anchor in
            AddAnchorSheet(editingAnchor: anchor)
        }
        .alert("确认删除时间锚点？", isPresented: Binding(
            get: { deletingAnchor != nil },
            set: { if !$0 { deletingAnchor = nil } }
        )) {
            Button("取消", role: .cancel) { deletingAnchor = nil }
            Button("删除", role: .destructive) {
                if let target = deletingAnchor {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        appState.deleteAnchor(id: target.id)
                    }
                    deletingAnchor = nil
                }
            }
        } message: {
            Text("确定要删除「\(deletingAnchor?.name ?? "")」时间锚点及定时提醒吗？关联的计划与习惯不会被删除。")
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(BotanicalTheme.primary.opacity(0.10))
                    .frame(width: 80, height: 80)
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 36))
                    .foregroundColor(BotanicalTheme.primary)
            }
            .padding(.bottom, 8)

            Text("添加你的第一个锚点")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(BotanicalTheme.textPrimary)

            Text("锚点是生活中一定会发生的事情\n(例如: 起床后, 吃饭前)")
                .font(.system(size: 13))
                .foregroundColor(BotanicalTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 96)
    }
}
