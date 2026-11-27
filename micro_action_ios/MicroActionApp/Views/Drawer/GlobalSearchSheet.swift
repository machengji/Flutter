import SwiftUI

/// 全局搜索浮层：从侧滑抽屉进入，支持按全部 / 愿望 / 习惯 / 锚点 / 发光记录检索与点击直达定位
struct GlobalSearchSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    enum SearchScope: String, CaseIterable, Identifiable {
        case all = "全部"
        case plans = "愿望"
        case habits = "习惯"
        case anchors = "锚点"
        case shines = "发光记录"

        var id: String { rawValue }
    }

    @State private var query: String = ""
    @State private var scope: SearchScope = .all
    @FocusState private var isSearchFocused: Bool

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var matchedPlans: [PlanItem] {
        guard scope == .all || scope == .plans else { return [] }
        let q = trimmedQuery.lowercased()
        guard !q.isEmpty else { return [] }
        return appState.plans.filter { plan in
            plan.name.lowercased().contains(q)
        }
    }

    private var matchedHabits: [HabitItem] {
        guard scope == .all || scope == .habits else { return [] }
        let q = trimmedQuery.lowercased()
        guard !q.isEmpty else { return [] }
        return appState.habits.filter { habit in
            habit.name.lowercased().contains(q)
                || (habit.starterStep?.lowercased().contains(q) ?? false)
        }
    }

    private var matchedAnchors: [AnchorItem] {
        guard scope == .all || scope == .anchors else { return [] }
        let q = trimmedQuery.lowercased()
        guard !q.isEmpty else { return [] }
        return appState.anchors.filter { anchor in
            anchor.name.lowercased().contains(q)
                || anchor.triggerTime.lowercased().contains(q)
                || anchor.repeatCycle.displayName.lowercased().contains(q)
        }
    }

    private var matchedShines: [ShineRecord] {
        guard scope == .all || scope == .shines else { return [] }
        let q = trimmedQuery.lowercased()
        guard !q.isEmpty else { return Array(appState.shineRecords.prefix(12)) }
        return appState.shineRecords.filter { record in
            record.title.lowercased().contains(q)
                || formatTime(record.timestamp).lowercased().contains(q)
        }
    }

    private var totalMatchesCount: Int {
        matchedPlans.count + matchedHabits.count + matchedAnchors.count + matchedShines.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BotanicalTheme.pageGradient.ignoresSafeArea()

                VStack(spacing: 12) {
                    searchBarSection
                    scopeFilterStrip

                    ScrollView(showsIndicators: false) {
                        if trimmedQuery.isEmpty {
                            emptyQueryOverview
                        } else if totalMatchesCount == 0 {
                            emptyResultState
                        } else {
                            searchResultsContent
                        }
                    }
                }
                .padding(.top, 8)
            }
            .navigationTitle("全局搜索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        SensoryFeedbackService.shared.lightTap()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(BotanicalTheme.primaryDark)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                    isSearchFocused = true
                }
            }
        }
    }

    // MARK: - 搜索输入栏

    private var searchBarSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(BotanicalTheme.primaryDark)

            TextField("搜索愿望、习惯、锚点或发光记录...", text: $query)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(BotanicalTheme.textPrimary)
                .focused($isSearchFocused)
                .submitLabel(.search)

            if !query.isEmpty {
                Button {
                    SensoryFeedbackService.shared.selection()
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(BotanicalTheme.textSecondary.opacity(0.65))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .liquidGlassCard(cornerRadius: 16, tint: BotanicalTheme.primaryLight, interactive: true, shadowRadius: 8)
        .padding(.horizontal, 16)
    }

    // MARK: - 分类筛选胶囊

    private var scopeFilterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SearchScope.allCases) { item in
                    let isSelected = scope == item
                    Button {
                        SensoryFeedbackService.shared.selection()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            scope = item
                        }
                    } label: {
                        Text(item.rawValue)
                            .font(.system(size: 12.5, weight: isSelected ? .bold : .medium, design: .rounded))
                            .foregroundColor(isSelected ? .white : BotanicalTheme.textSecondary)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(isSelected ? BotanicalTheme.primary : Color.white.opacity(0.72))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? Color.clear : BotanicalTheme.border.opacity(0.55), lineWidth: 0.8)
                            )
                    }
                    .buttonStyle(ScaleBounceButtonStyle(scale: 0.96))
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - 未输入时的概览与最近发光

    private var emptyQueryOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                statTile(title: "愿望清单", count: appState.plans.count, icon: "target", color: BotanicalTheme.primaryDark) {
                    scope = .plans
                }
                statTile(title: "微习惯", count: appState.habits.count, icon: "leaf.fill", color: BotanicalTheme.primary) {
                    scope = .habits
                }
                statTile(title: "每日锚点", count: appState.anchors.count, icon: "bell.badge.fill", color: BotanicalTheme.goldDark) {
                    scope = .anchors
                }
                statTile(title: "发光记录", count: appState.shineRecords.count, icon: "sun.max.fill", color: BotanicalTheme.gold) {
                    scope = .shines
                }
            }

            if !appState.shineRecords.isEmpty && (scope == .all || scope == .shines) {
                sectionHeader("最近发光记录", count: min(12, appState.shineRecords.count))
                VStack(spacing: 10) {
                    ForEach(Array(appState.shineRecords.prefix(12))) { record in
                        shineRow(record)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 28)
    }

    private func statTile(title: String, count: Int, icon: String, color: Color, onTap: @escaping () -> Void) -> some View {
        Button {
            SensoryFeedbackService.shared.selection()
            onTap()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 34, height: 34)
                    .background(color.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(BotanicalTheme.textSecondary)
                    Text("\(count) 项")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(BotanicalTheme.textPrimary)
                }
                Spacer()
            }
            .padding(12)
            .liquidGlassCard(cornerRadius: 16, tint: BotanicalTheme.primaryLight, interactive: true, shadowRadius: 6)
        }
        .buttonStyle(ScaleBounceButtonStyle(scale: 0.97))
    }

    // MARK: - 搜索结果列表

    private var searchResultsContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !matchedPlans.isEmpty {
                sectionHeader("愿望", count: matchedPlans.count)
                VStack(spacing: 10) {
                    ForEach(matchedPlans) { plan in
                        planRow(plan)
                    }
                }
            }

            if !matchedHabits.isEmpty {
                sectionHeader("微习惯", count: matchedHabits.count)
                VStack(spacing: 10) {
                    ForEach(matchedHabits) { habit in
                        habitRow(habit)
                    }
                }
            }

            if !matchedAnchors.isEmpty {
                sectionHeader("每日锚点", count: matchedAnchors.count)
                VStack(spacing: 10) {
                    ForEach(matchedAnchors) { anchor in
                        anchorRow(anchor)
                    }
                }
            }

            if !matchedShines.isEmpty {
                sectionHeader("发光记录", count: matchedShines.count)
                VStack(spacing: 10) {
                    ForEach(matchedShines) { record in
                        shineRow(record)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 28)
    }

    private var emptyResultState: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(BotanicalTheme.primary.opacity(0.65))
                .padding(.top, 48)
            Text("没有找到与「\(trimmedQuery)」相关的内容")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(BotanicalTheme.textPrimary)
            Text("试试换个关键词，或切换上方分类胶囊")
                .font(.system(size: 12.5))
                .foregroundColor(BotanicalTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(BotanicalTheme.primaryDark)
            Spacer()
            Text("\(count)")
                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                .foregroundColor(BotanicalTheme.textSecondary)
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }

    // MARK: - 各类结果行（点击直达）

    private func planRow(_ plan: PlanItem) -> some View {
        let statusLabel: String = {
            switch plan.status {
            case .ongoing: return plan.isMainContradiction ? "重点进行中" : "进行中"
            case .completed: return "已完成"
            case .archived: return "已归档"
            }
        }()
        return resultCard(
            icon: "target",
            iconColor: BotanicalTheme.primaryDark,
            title: plan.name,
            subtitle: "愿望 · \(statusLabel)",
            actionText: "前往定位"
        ) {
            SensoryFeedbackService.shared.lightTap()
            appState.pendingLocatePlanId = plan.id
            dismiss()
        }
    }

    private func habitRow(_ habit: HabitItem) -> some View {
        let sub = habit.starterStep.flatMap { $0.isEmpty ? nil : "微步：\($0)" }
            ?? "坚持 \(habit.totalDays) 天 · \(habit.status == .active ? "养成中" : "已停用")"
        return resultCard(
            icon: "leaf.fill",
            iconColor: BotanicalTheme.primary,
            title: habit.name,
            subtitle: "习惯 · \(sub)",
            actionText: "前往定位"
        ) {
            SensoryFeedbackService.shared.lightTap()
            appState.pendingLocateHabitId = habit.id
            dismiss()
        }
    }

    private func anchorRow(_ anchor: AnchorItem) -> some View {
        return resultCard(
            icon: "bell.badge.fill",
            iconColor: BotanicalTheme.goldDark,
            title: anchor.name,
            subtitle: "锚点 · \(anchor.triggerTime) · \(anchor.repeatCycle.displayName)",
            actionText: "打开详情"
        ) {
            SensoryFeedbackService.shared.lightTap()
            appState.pendingOpenedAnchorId = anchor.id
            dismiss()
        }
    }

    private func shineRow(_ record: ShineRecord) -> some View {
        return resultCard(
            icon: "sun.max.fill",
            iconColor: BotanicalTheme.gold,
            title: record.title,
            subtitle: "发光记录 · \(formatTime(record.timestamp))",
            actionText: "重温卡片"
        ) {
            SensoryFeedbackService.shared.lightTap()
            dismiss()
            Task { @MainActor in
                let quote = await appState.quoteService.takeRainbowQuote(
                    preferOnline: appState.quoteSourceMode == .onlineFirst
                )
                let joke = await appState.quoteService.takeColdJokeQuote(
                    preferOnline: appState.quoteSourceMode == .onlineFirst
                )
                appState.activeCelebration = CelebrationPayload(
                    id: Int.random(in: 1000...999999),
                    actionTitle: record.title,
                    quote: quote,
                    jokeQuote: joke,
                    aiQuote: nil,
                    fortuneSlip: CelebrationLibrary.fortuneSlips.randomElement(),
                    isGrand: record.isGrand,
                    milestoneTag: nil
                )
            }
        }
    }

    private func resultCard(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        actionText: String,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 36, height: 36)
                    .background(iconColor.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundColor(BotanicalTheme.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(subtitle)
                        .font(.system(size: 11.5))
                        .foregroundColor(BotanicalTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(actionText)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(BotanicalTheme.primaryDark)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(BotanicalTheme.primaryLight.opacity(0.45))
                    .clipShape(Capsule())
            }
            .padding(12)
            .liquidGlassCard(cornerRadius: 16, tint: BotanicalTheme.primaryLight, interactive: true, shadowRadius: 6)
        }
        .buttonStyle(ScaleBounceButtonStyle(scale: 0.98))
    }

    private func formatTime(_ tsMs: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(tsMs) / 1000.0)
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 HH:mm"
        return f.string(from: date)
    }
}
