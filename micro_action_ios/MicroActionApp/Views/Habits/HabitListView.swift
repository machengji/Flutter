import SwiftUI

/// 微习惯列表视图（Tiimo 风格治愈系空状态引导 + 轻呼吸列表页头 + 已停用分区）
struct HabitListView: View {
    var onQuickAdd: () -> Void = {}
    var onOpenShineJar: () -> Void = {}

    @EnvironmentObject private var appState: AppState

    @State private var expandedHabitId: String? = nil
    @State private var editingHabit: HabitItem? = nil

    var body: some View {
        List {
            if appState.activeHabits.isEmpty {
                emptyStateView
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            } else {
                if !appState.coreHabits.isEmpty {
                    coreHabitsHeader(count: appState.coreHabits.count)
                        .listRowInsets(EdgeInsets(top: 4, leading: 18, bottom: 2, trailing: 18))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)

                    ForEach(appState.coreHabits) { habit in
                        habitRowCard(habit, allowSwipeCore: true)
                    }
                }

                if !appState.normalActiveHabits.isEmpty {
                    if !appState.coreHabits.isEmpty {
                        HStack(spacing: 6) {
                            Text("其他习惯")
                                .font(.system(size: 13.5, weight: .semibold))
                                .foregroundColor(BotanicalTheme.textSecondary)
                            Text("\(appState.normalActiveHabits.count)")
                                .font(.system(size: 10.5, weight: .bold))
                                .foregroundColor(BotanicalTheme.textSecondary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(BotanicalTheme.surfaceMuted)
                                .clipShape(Capsule())
                            Spacer()
                        }
                        .padding(.top, 10)
                        .listRowInsets(EdgeInsets(top: 4, leading: 18, bottom: 2, trailing: 18))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }

                    ForEach(appState.normalActiveHabits) { habit in
                        habitRowCard(habit, allowSwipeCore: true)
                    }
                }
            }

            if !appState.stoppedHabits.isEmpty {
                Text("已停用")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(BotanicalTheme.textSecondary)
                    .padding(.top, 10)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 2, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                ForEach(appState.stoppedHabits) { habit in
                    habitRowCard(habit, allowSwipeCore: false)
                }
            }

            Color.clear
                .frame(height: 112)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .sheet(item: $editingHabit) { habit in
            AddHabitSheet(editingHabit: habit)
        }
    }

    private func coreHabitsHeader(count: Int) -> some View {
        HStack(alignment: .center, spacing: 7) {
            Image(systemName: "flame.fill")
                .font(.system(size: 13.5, weight: .bold))
                .foregroundColor(Color(hex: 0xD96B27))

            Text("核心习惯 · 优先坚持")
                .font(.system(size: 14.5, weight: .bold))
                .foregroundColor(Color(hex: 0x9C4415))

            Text("\(count)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: 0xB8531E))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color(hex: 0xFCEAD7))
                .clipShape(Capsule())

            Spacer()
        }
        .padding(.top, 4)
        .padding(.bottom, 2)
    }

    @ViewBuilder
    private func habitRowCard(_ habit: HabitItem, allowSwipeCore: Bool) -> some View {
        let card = HabitCardView(
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
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)

        if allowSwipeCore {
            card.swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button {
                    SensoryFeedbackService.shared.lightTap()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                        appState.toggleCoreHabit(id: habit.id)
                    }
                } label: {
                    Label(
                        habit.isCoreHabit ? "取消核心" : "核心习惯",
                        systemImage: habit.isCoreHabit ? "flame.slash" : "flame.fill"
                    )
                }
                .tint(habit.isCoreHabit ? BotanicalTheme.textSecondary : Color(hex: 0xD96B27))
            }
        } else {
            card
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
