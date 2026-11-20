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
            if !appState.activeHabits.isEmpty {
                let checkedTodayCount = appState.activeHabits.filter { $0.todayCheckCount() > 0 }.count
                HabitHeaderHeroCard(
                    checkedTodayCount: checkedTodayCount,
                    totalActiveCount: appState.activeHabits.count,
                    coreCount: appState.coreHabits.count
                )
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 5, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

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
                        .padding(.top, 8)
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
        .onAppear {
            consumePendingLocateHabit()
        }
        .onChange(of: appState.pendingLocateHabitId) { _ in
            consumePendingLocateHabit()
        }
    }

    private func consumePendingLocateHabit() {
        guard let targetId = appState.pendingLocateHabitId else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                expandedHabitId = targetId
            }
            appState.pendingLocateHabitId = nil
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
        .padding(.top, 2)
        .padding(.bottom, 1)
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
        .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
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

/// 习惯页顶部莫兰迪水滴涟漪横幅（102pt 超薄高定插画 + 每次切页弹性入场 + 轻点切关怀短语）
private struct HabitHeaderHeroCard: View {
    let checkedTodayCount: Int
    let totalActiveCount: Int
    let coreCount: Int

    @State private var appeared: Bool = false
    @State private var tapBounce: Bool = false
    @State private var quoteIndex: Int = 0

    private static let habitQuotes: [String] = [
        "哪怕只做 1 分钟，也是在滋养今天的自己",
        "不求完美打卡，保持轻盈的节奏就够了",
        "每一次轻点，都在悄悄重塑你的日常",
        "微习惯像滴水成溪，慢慢来反而最快"
    ]

    private var headlineText: String {
        if totalActiveCount > 0 && checkedTodayCount >= totalActiveCount {
            return "今日微习惯已全部点亮"
        } else if checkedTodayCount > 0 {
            return "今天已滋养 \(checkedTodayCount) 个好习惯"
        } else {
            return "选一个最轻松的习惯开始吧"
        }
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Image("IllustHeaderHabit")
                .resizable()
                .scaledToFill()
                .frame(height: 102)
                .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(headlineText)
                    .font(.system(size: 14.5, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: 0x1A4236))
                    .lineLimit(1)

                Text(Self.habitQuotes[quoteIndex % Self.habitQuotes.count])
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(Color(hex: 0x456D60))
                    .lineLimit(1)
                    .id(quoteIndex)
                    .transition(.opacity)

                HStack(spacing: 6) {
                    miniPill(
                        icon: "checkmark.circle.fill",
                        text: "今日 \(checkedTodayCount)/\(totalActiveCount)",
                        tint: BotanicalTheme.primaryDark,
                        bg: Color.white.opacity(0.88)
                    )

                    if coreCount > 0 {
                        miniPill(
                            icon: "flame.fill",
                            text: "核心 \(coreCount)",
                            tint: Color(hex: 0xB8531E),
                            bg: Color(hex: 0xFCEAD7).opacity(0.95)
                        )
                    }
                }
                .padding(.top, 2)
            }
            .padding(.leading, 16)
            .padding(.trailing, 118)
            .opacity(appeared ? 1.0 : 0.0)
            .offset(y: appeared ? 0 : 6)
        }
        .frame(height: 102)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.92), lineWidth: 1.1)
        )
        .shadow(color: BotanicalTheme.primaryDark.opacity(0.06), radius: 7, y: 3)
        .scaleEffect(appeared ? (tapBounce ? 0.975 : 1.0) : 0.94)
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            guard !appeared else { return }
            withAnimation(.spring(response: 0.46, dampingFraction: 0.76)) {
                appeared = true
            }
        }
        .onTapGesture {
            SensoryFeedbackService.shared.selection()
            withAnimation(.spring(response: 0.24, dampingFraction: 0.65)) {
                tapBounce = true
                quoteIndex += 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                withAnimation(.spring(response: 0.30, dampingFraction: 0.70)) {
                    tapBounce = false
                }
            }
        }
    }

    private func miniPill(icon: String, text: String, tint: Color, bg: Color) -> some View {
        HStack(spacing: 3.5) {
            Image(systemName: icon)
                .font(.system(size: 9.5, weight: .bold))
            Text(text)
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
        }
        .foregroundColor(tint)
        .padding(.horizontal, 8.5)
        .padding(.vertical, 3)
        .background(bg)
        .clipShape(Capsule())
    }
}
