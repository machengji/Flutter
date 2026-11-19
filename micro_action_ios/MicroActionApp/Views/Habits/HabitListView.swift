import SwiftUI

/// 微习惯列表视图（支持一键打卡触发全屏庆祝、编辑与删除）
struct HabitListView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var proStore: ProStoreService

    @State private var editingHabit: HabitItem? = nil

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if appState.activeHabits.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 32))
                            .foregroundColor(BotanicalTheme.secondary)
                        Text("还没有建立微习惯")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(BotanicalTheme.textPrimary)
                        Text("从“喝一口温水”或“读一页书”开始养成发光习惯")
                            .font(.system(size: 13))
                            .foregroundColor(BotanicalTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 44)
                    .background(BotanicalTheme.surface.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(BotanicalTheme.border, lineWidth: 1))
                } else {
                    ForEach(appState.activeHabits) { habit in
                        let todayCount = habit.todayCheckCount()
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(todayCount > 0 ? BotanicalTheme.primarySoft : BotanicalTheme.surfaceMuted)
                                    .frame(width: 40, height: 40)
                                Image(systemName: "wind")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(BotanicalTheme.primary)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(habit.name)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(BotanicalTheme.textPrimary)
                                Text(todayCount > 0
                                     ? "今日已打卡 \(todayCount) 次 · 累计 \(habit.totalDays) 次"
                                     : "今日待打卡 · 累计 \(habit.totalDays) 次")
                                    .font(.system(size: 12))
                                    .foregroundColor(BotanicalTheme.textSecondary)
                            }

                            Spacer()

                            Button {
                                SensoryFeedbackService.shared.lightTap()
                                Task {
                                    await appState.checkHabit(id: habit.id, isPro: proStore.isPro)
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                    Text(todayCount > 0 ? "已打卡(\(todayCount))" : "打卡")
                                        .font(.system(size: 13, weight: .bold))
                                }
                                .foregroundColor(todayCount > 0 ? BotanicalTheme.primaryDark : .white)
                                .padding(.horizontal, 14)
                                .frame(height: 36)
                                .background(todayCount > 0 ? BotanicalTheme.primarySoft : BotanicalTheme.primary)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(14)
                        .background(BotanicalTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(BotanicalTheme.border, lineWidth: 1))
                        .contextMenu {
                            Button {
                                editingHabit = habit
                            } label: {
                                Label("编辑名称", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                appState.deleteHabit(id: habit.id)
                            } label: {
                                Label("删除习惯", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
        .sheet(item: $editingHabit) { habit in
            AddHabitSheet(editingHabit: habit)
        }
    }
}
