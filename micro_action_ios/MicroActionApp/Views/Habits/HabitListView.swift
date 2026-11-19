import SwiftUI

/// 微习惯列表视图（Tiimo 风格治愈系空状态引导 + 轻呼吸列表页头 + 已停用分区）
struct HabitListView: View {
    var onQuickAdd: () -> Void = {}
    var onOpenShineJar: () -> Void = {}

    @EnvironmentObject private var appState: AppState

    @State private var expandedHabitId: String? = nil
    @State private var editingHabit: HabitItem? = nil

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 8) {
                if appState.activeHabits.isEmpty {
                    emptyStateView
                } else {
                    ForEach(appState.activeHabits) { habit in
                        HabitCardView(
                            habit: habit,
                            isExpanded: expandedHabitId == habit.id,
                            onTap: {
                                SensoryFeedbackService.shared.selection()
                                withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                                    expandedHabitId = expandedHabitId == habit.id ? nil : habit.id
                                }
                            },
                            onEdit: { editingHabit = habit }
                        )
                    }
                }

                if !appState.stoppedHabits.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("已停用")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(BotanicalTheme.textSecondary)
                            .padding(.top, 10)

                        ForEach(appState.stoppedHabits) { habit in
                            HabitCardView(
                                habit: habit,
                                isExpanded: expandedHabitId == habit.id,
                                onTap: {
                                    SensoryFeedbackService.shared.selection()
                                    withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                                        expandedHabitId = expandedHabitId == habit.id ? nil : habit.id
                                    }
                                },
                                onEdit: { editingHabit = habit }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 120)
        }
        .sheet(item: $editingHabit) { habit in
            AddHabitSheet(editingHabit: habit)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 28)

            StarSproutIllustrationBadge(imageName: "IllustEmptyHabit", size: 204)
                .padding(.bottom, 8)

            Text("从一个微小动作开始\n让好习惯自然生长")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(BotanicalTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.bottom, 36)

            VStack(alignment: .leading, spacing: 11) {
                TiimoQuickActionPill(
                    icon: "plus.circle.fill",
                    iconColor: BotanicalTheme.secondary,
                    title: "创建我的第一个微习惯"
                ) {
                    onQuickAdd()
                }

                TiimoQuickActionPill(
                    icon: "leaf.fill",
                    iconColor: BotanicalTheme.primary,
                    title: "先去成长树夸夸今天的自己"
                ) {
                    onOpenShineJar()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 18)

            TiimoSoftBannerCard(
                title: "每次打卡都是一次蜕变",
                subtitle: "完成后自动浇灌成长树与专属夸夸",
                buttonLabel: "去新建"
            ) {
                onQuickAdd()
            }
        }
        .frame(maxWidth: .infinity)
    }
}
