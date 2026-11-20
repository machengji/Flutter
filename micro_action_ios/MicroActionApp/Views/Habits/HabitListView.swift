import SwiftUI

/// 微习惯列表视图（Tiimo 风格治愈系空状态引导 + 轻呼吸列表页头 + 已停用分区）
struct HabitListView: View {
    var onQuickAdd: () -> Void = {}
    var onOpenShineJar: () -> Void = {}

    @EnvironmentObject private var appState: AppState

    @State private var expandedHabitId: String? = nil
    @State private var editingHabit: HabitItem? = nil

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 7) {
                    if !appState.activeHabits.isEmpty {
                        let checkedTodayCount = appState.activeHabits.filter { $0.todayCheckCount() > 0 }.count
                        HabitHeaderHeroCard(
                            checkedTodayCount: checkedTodayCount,
                            totalActiveCount: appState.activeHabits.count,
                            coreCount: appState.coreHabits.count
                        )
                        .padding(.bottom, 3)
                    }

                    if appState.activeHabits.isEmpty {
                        emptyStateView
                    } else {
                        if !appState.coreHabits.isEmpty {
                            coreHabitsHeader(count: appState.coreHabits.count)
                                .padding(.horizontal, 2)

                            ForEach(appState.coreHabits) { habit in
                                habitRowCard(habit, allowSwipeCore: true)
                                    .id(habit.id)
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
                                .padding(.horizontal, 2)
                            }

                            ForEach(appState.normalActiveHabits) { habit in
                                habitRowCard(habit, allowSwipeCore: true)
                                    .id(habit.id)
                            }
                        }
                    }

                    if !appState.stoppedHabits.isEmpty {
                        Text("已停用")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(BotanicalTheme.textSecondary)
                            .padding(.top, 10)
                            .padding(.horizontal, 2)

                        ForEach(appState.stoppedHabits) { habit in
                            habitRowCard(habit, allowSwipeCore: false)
                                .id(habit.id)
                        }
                    }

                    Color.clear
                        .frame(height: 112)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }
            .onAppear {
                consumePendingLocateHabit(proxy: scrollProxy)
            }
            .onChange(of: appState.pendingLocateHabitId) { _ in
                consumePendingLocateHabit(proxy: scrollProxy)
            }
        }
        .sheet(item: $editingHabit) { habit in
            AddHabitSheet(editingHabit: habit)
        }
    }

    private func consumePendingLocateHabit(proxy: ScrollViewProxy) {
        guard let targetId = appState.pendingLocateHabitId else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.90)) {
                expandedHabitId = targetId
                proxy.scrollTo(targetId, anchor: .center)
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
        SwipeActionCardWrapper(
            enabled: allowSwipeCore,
            actionTitle: habit.isCoreHabit ? "取消核心" : "核心习惯",
            actionIcon: habit.isCoreHabit ? "flame.slash" : "flame.fill",
            actionTint: habit.isCoreHabit ? BotanicalTheme.textSecondary : Color(hex: 0xD96B27),
            onTriggerAction: {
                withAnimation(.spring(response: 0.30, dampingFraction: 0.90)) {
                    appState.toggleCoreHabit(id: habit.id)
                }
            }
        ) {
            HabitCardView(
                habit: habit,
                isExpanded: expandedHabitId == habit.id,
                onTap: {
                    SensoryFeedbackService.shared.selection()
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.90)) {
                        expandedHabitId = expandedHabitId == habit.id ? nil : habit.id
                    }
                },
                onEdit: { editingHabit = habit }
            )
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

    private var progressRatio: CGFloat {
        guard totalActiveCount > 0 else { return 0 }
        return min(1.0, CGFloat(checkedTodayCount) / CGFloat(totalActiveCount))
    }

    private var percentInt: Int {
        Int((progressRatio * 100).rounded())
    }

    var body: some View {
        EditorialHeaderBannerShell(
            backgroundImageName: "IllustHeaderHabit",
            borderColor: Color.white.opacity(0.92),
            shadowColor: Color(hex: 0x2D9D78).opacity(0.08),
            leftContent: { entered in
                HStack(spacing: 12) {
                    // 专属：44pt 冰川青碧环形进度仪表盘
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.72), lineWidth: 4.5)
                        Circle()
                            .trim(from: 0, to: entered ? progressRatio : 0)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: 0x10B981), Color(hex: 0x059669)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.65, dampingFraction: 0.80).delay(0.10), value: entered)

                        Text("\(percentInt)%")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(hex: 0x134E4A))
                    }
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.55), in: Circle())
                    .scaleEffect(entered ? 1.0 : 0.78)
                    .opacity(entered ? 1.0 : 0.0)
                    .animation(.spring(response: 0.44, dampingFraction: 0.76).delay(0.04), value: entered)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(headlineText)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: 0x134E4A))
                            .lineLimit(1)

                        Text(Self.habitQuotes[quoteIndex % Self.habitQuotes.count])
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: 0x3D6E60))
                            .lineLimit(1)
                            .id(quoteIndex)
                            .transition(.opacity)

                        HStack(spacing: 6) {
                            Text("已完成 \(checkedTodayCount)/\(totalActiveCount)")
                                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: 0x047857))
                            if coreCount > 0 {
                                Text("·")
                                    .foregroundColor(Color(hex: 0x6B8E82))
                                Text("核心 \(coreCount) 项")
                                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: 0xB8531E))
                            }
                        }
                    }
                    .opacity(entered ? 1.0 : 0.0)
                    .offset(x: entered ? 0 : -6)
                    .animation(.spring(response: 0.42, dampingFraction: 0.82).delay(0.10), value: entered)
                }
            },
            artwork: { pulseTick, entered in
                HabitRippleSproutArtwork(pulseTick: pulseTick, entered: entered)
            },
            onTapBanner: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    quoteIndex += 1
                }
            }
        )
    }
}
