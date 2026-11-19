import SwiftUI

/// 微习惯列表视图（完整复刻原版：进行中 + 已停用分区、点击卡片展开操作托盘、森系空状态）
struct HabitListView: View {
    @EnvironmentObject private var appState: AppState

    @State private var expandedHabitId: String? = nil
    @State private var editingHabit: HabitItem? = nil

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                if appState.activeHabits.isEmpty {
                    emptyStateView
                } else {
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
                    VStack(alignment: .leading, spacing: 14) {
                        Text("已停用")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(BotanicalTheme.textPrimary)
                            .padding(.top, 20)

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
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 130)
        }
        .sheet(item: $editingHabit) { habit in
            AddHabitSheet(editingHabit: habit)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(BotanicalTheme.primary.opacity(0.10))
                    .frame(width: 80, height: 80)
                Image(systemName: "wind")
                    .font(.system(size: 36))
                    .foregroundColor(BotanicalTheme.primary)
            }
            .padding(.bottom, 8)

            Text("开始你的第一个习惯")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(BotanicalTheme.textPrimary)

            Text("点击下方按钮添加新习惯")
                .font(.system(size: 13))
                .foregroundColor(BotanicalTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 96)
    }
}
