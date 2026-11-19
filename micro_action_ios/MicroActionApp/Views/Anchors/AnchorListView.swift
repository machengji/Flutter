import SwiftUI

/// 福格时间锚点列表视图（Tiimo 风格治愈系空状态引导 + 轻呼吸列表页头 + 快捷编辑删除）
struct AnchorListView: View {
    var onQuickAdd: () -> Void = {}
    var onOpenShineJar: () -> Void = {}

    @EnvironmentObject private var appState: AppState

    @State private var selectedAnchorId: String? = nil
    @State private var editingAnchor: AnchorItem? = nil
    @State private var deletingAnchor: AnchorItem? = nil

    private var selectedAnchor: AnchorItem? {
        appState.anchors.first(where: { $0.id == selectedAnchorId })
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                if appState.anchors.isEmpty {
                    emptyStateView
                } else {
                    HStack(alignment: .center, spacing: 8) {
                        Text("时间锚点")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(BotanicalTheme.textPrimary)

                        Text("\(appState.anchors.count)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(BotanicalTheme.anchorAccent)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3)
                            .background(BotanicalTheme.anchorAccent.opacity(0.12))
                            .clipShape(Capsule())

                        Spacer()
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 2)

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
            .padding(.horizontal, 20)
            .padding(.top, 10)
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
        VStack(spacing: 0) {
            Spacer(minLength: 28)

            StarSproutIllustrationBadge(imageName: "IllustEmptyAnchor", size: 146)
                .padding(.bottom, 18)

            Text("绑定每天必做的时刻\n轻轻一推就开始行动")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(BotanicalTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.bottom, 36)

            VStack(alignment: .leading, spacing: 11) {
                TiimoQuickActionPill(
                    icon: "bell.badge.fill",
                    iconColor: BotanicalTheme.anchorAccent,
                    title: "添加第一个日常时间锚点"
                ) {
                    onQuickAdd()
                }

                TiimoQuickActionPill(
                    icon: "leaf.fill",
                    iconColor: BotanicalTheme.primary,
                    title: "打开微步成长树看看收获"
                ) {
                    onOpenShineJar()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 18)

            TiimoSoftBannerCard(
                title: "福格行为模型时间锚点",
                subtitle: "例如：起床后、午饭前，自然触发微行动",
                buttonLabel: "去添加"
            ) {
                onQuickAdd()
            }
        }
        .frame(maxWidth: .infinity)
    }
}
