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
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 7) {
                if !appState.anchors.isEmpty {
                    AnchorHeaderHeroCard(anchors: appState.anchors)
                        .padding(.bottom, 3)
                }

                if appState.anchors.isEmpty {
                    emptyStateView
                } else {
                    ForEach(appState.anchors) { anchor in
                        SwipeActionCardWrapper(
                            enabled: true,
                            actionTitle: "删除锚点",
                            actionIcon: "trash.fill",
                            actionTint: BotanicalTheme.danger,
                            onTriggerAction: {
                                deletingAnchor = anchor
                            }
                        ) {
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

                Color.clear
                    .frame(height: 112)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
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
            Text("确定要删除「\(deletingAnchor?.name ?? "")」时间锚点及定时提醒吗？关联的愿望与习惯不会被删除。")
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 28)

            StarSproutIllustrationBadge(imageName: "IllustEmptyAnchor", size: 204)
                .padding(.bottom, 8)

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

/// 锚点页顶部暖杏弯月星轨横幅（专属「下一生活节拍」时间预告结构 + 沿星轨公转微光动效）
private struct AnchorHeaderHeroCard: View {
    let anchors: [AnchorItem]

    @State private var quoteIndex: Int = 0

    private static let anchorQuotes: [String] = [
        "把行动系在日常节拍上，到点自然顺手完成",
        "不靠意志力硬扛，用生活锚点轻轻推自己一把",
        "起床、午休、睡前，都是最温柔的触发信号"
    ]

    private var enabledAnchors: [AnchorItem] {
        anchors.filter { $0.reminderEnabled }.sorted { $0.triggerTime < $1.triggerTime }
    }

    private func nextUpcomingAnchor(at now: Date) -> AnchorItem? {
        enabledAnchors
            .compactMap { anchor -> (AnchorItem, Date)? in
                guard let fire = anchor.nextFireDate(after: now) else { return nil }
                return (anchor, fire)
            }
            .min(by: { $0.1 < $1.1 })?.0 ?? enabledAnchors.first
    }

    private var linkedTotal: Int {
        anchors.reduce(0) { $0 + $1.planIds.count + $1.habitIds.count }
    }

    var body: some View {
        EditorialHeaderBannerShell(
            backgroundImageName: "IllustHeaderAnchor",
            borderColor: Color.white.opacity(0.92),
            shadowColor: Color(hex: 0xD97706).opacity(0.08),
            leftContent: { entered in
                TimelineView(.periodic(from: .now, by: 30)) { context in
                    VStack(alignment: .leading, spacing: 4) {
                        if let next = nextUpcomingAnchor(at: context.date) {
                            HStack(alignment: .firstTextBaseline, spacing: 7) {
                                Text(next.triggerTime)
                                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                                    .foregroundColor(Color(hex: 0xB45309))
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 2)
                                    .background(Color.white.opacity(0.88))
                                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                                Text("下一节拍")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(hex: 0x7A5B3E))
                            }
                            .opacity(entered ? 1.0 : 0.0)
                            .offset(x: entered ? 0 : -8)
                            .animation(.spring(response: 0.40, dampingFraction: 0.80).delay(0.04), value: entered)

                            Text(next.name)
                                .font(.system(size: 14.5, weight: .bold))
                                .foregroundColor(Color(hex: 0x4A2E14))
                                .lineLimit(1)
                                .opacity(entered ? 1.0 : 0.0)
                                .offset(x: entered ? 0 : -6)
                                .animation(.spring(response: 0.40, dampingFraction: 0.82).delay(0.10), value: entered)
                        } else {
                        Text("已建立 \(anchors.count) 个生活锚点")
                            .font(.system(size: 14.5, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: 0x4A2E14))
                            .lineLimit(1)

                        Text(Self.anchorQuotes[quoteIndex % Self.anchorQuotes.count])
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(Color(hex: 0x7A5B3E))
                            .lineLimit(1)
                    }

                    HStack(spacing: 8) {
                        Label("已开启 \(enabledAnchors.count)/\(anchors.count)", systemImage: "bell.badge.fill")
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: 0xB45309))
                        Text("·")
                            .foregroundColor(Color(hex: 0x9C7E62))
                        Text("串联 \(linkedTotal) 项行动")
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundColor(BotanicalTheme.primaryDark)
                    }
                    .padding(.top, 1)
                    .opacity(entered ? 1.0 : 0.0)
                    .offset(y: entered ? 0 : 6)
                    .animation(.spring(response: 0.42, dampingFraction: 0.80).delay(0.15), value: entered)
                    }
                }
            },
            artwork: { pulseTick, entered in
                AnchorOrbitClockArtwork(pulseTick: pulseTick, entered: entered)
            },
            onTapBanner: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    quoteIndex += 1
                }
            }
        )
    }
}
