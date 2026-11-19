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
            LazyVStack(spacing: 12) {
                if appState.activeHabits.isEmpty {
                    emptyStateView
                } else {
                    HStack(alignment: .center, spacing: 8) {
                        Text("微习惯")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(BotanicalTheme.textPrimary)

                        Text("\(appState.activeHabits.count)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(BotanicalTheme.secondaryDark)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3)
                            .background(BotanicalTheme.secondary.opacity(0.12))
                            .clipShape(Capsule())

                        Spacer()
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 4)

                    ForEach(appState.activeHabits) { habit in
                        HabitCardView(
                            habit: habit,
                            isExpanded: expandedHabitId == habit.id,
                            onTap: {
                                SensoryFeedbackService.shared.selection()
                                withAnimation(.spring(response: 0.30, dampingFraction: 0.84)) {
                                    expandedHabitId = expandedHabitId == habit.id ? nil : habit.id
                                }
                            },
                            onEdit: { editingHabit = habit }
                        )
                    }
                }

                if !appState.stoppedHabits.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("已停用")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(BotanicalTheme.textPrimary)
                            .padding(.top, 18)

                        ForEach(appState.stoppedHabits) { habit in
                            HabitCardView(
                                habit: habit,
                                isExpanded: expandedHabitId == habit.id,
                                onTap: {
                                    SensoryFeedbackService.shared.selection()
                                    withAnimation(.spring(response: 0.30, dampingFraction: 0.84)) {
                                        expandedHabitId = expandedHabitId == habit.id ? nil : habit.id
                                    }
                                },
                                onEdit: { editingHabit = habit }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 130)
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
