import WidgetKit
import SwiftUI

struct ShineJarEntry: TimelineEntry {
    let date: Date
    let snapshot: ShineWidgetSnapshot
}

struct ShineJarProvider: TimelineProvider {
    func placeholder(in context: Context) -> ShineJarEntry {
        ShineJarEntry(
            date: Date(),
            snapshot: ShineWidgetSnapshot(
                todayShineCount: 5,
                totalShineCount: 42,
                themeId: CelebrationThemeSkin.emerald.rawValue,
                latestActionTitle: "整理桌面 3 分钟",
                seedColorSeeds: [0, 1, 2, 3, 4],
                updatedAtMs: 0,
                pendingPlans: [
                    WidgetPlanSummary(id: "p1", title: "读 5 页书", pendingSubCount: 2),
                    WidgetPlanSummary(id: "p2", title: "出门散步 10 分钟", pendingSubCount: 0),
                    WidgetPlanSummary(id: "p3", title: "整理今晚清单", pendingSubCount: 0)
                ],
                pendingHabits: [
                    WidgetHabitSummary(id: "h1", title: "喝一杯温水", todayCount: 0, isCore: true),
                    WidgetHabitSummary(id: "h2", title: "深呼吸 3 次", todayCount: 1, isCore: false)
                ],
                totalPendingPlans: 3,
                todayHabitsDone: 1,
                totalHabitsCount: 2,
                treeSpeciesIndex: 0
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ShineJarEntry) -> Void) {
        let loaded = SharedWidgetStore.load()
        if context.isPreview && loaded.updatedAtMs == 0 && loaded.pendingPlans.isEmpty && loaded.pendingHabits.isEmpty {
            completion(placeholder(in: context))
        } else {
            completion(ShineJarEntry(date: Date(), snapshot: loaded))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShineJarEntry>) -> Void) {
        let now = Date()
        let entry = ShineJarEntry(date: now, snapshot: SharedWidgetStore.load())
        let thirtyMin = Calendar.current.date(byAdding: .minute, value: 30, to: now) ?? now.addingTimeInterval(1800)
        let tomorrowStart = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now).addingTimeInterval(5)
        let nextRefresh = min(thirtyMin, tomorrowStart)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

private struct WidgetPalette {
    let isDark: Bool

    var bg: Color {
        isDark ? Color(red: 0.086, green: 0.188, blue: 0.141) : Color(red: 0.980, green: 0.965, blue: 0.925)
    }
    var cardBg: Color {
        isDark ? Color(red: 0.125, green: 0.258, blue: 0.196).opacity(0.92) : Color.white.opacity(0.84)
    }
    var cardBorder: Color {
        isDark ? Color(red: 0.960, green: 0.812, blue: 0.463).opacity(0.22) : Color(red: 0.220, green: 0.369, blue: 0.278).opacity(0.12)
    }
    var inkPrimary: Color {
        isDark ? Color(red: 0.969, green: 0.949, blue: 0.906) : Color(red: 0.114, green: 0.259, blue: 0.192)
    }
    var inkSecondary: Color {
        isDark ? Color(red: 0.722, green: 0.816, blue: 0.761) : Color(red: 0.333, green: 0.447, blue: 0.384)
    }
    var accentGreen: Color {
        isDark ? Color(red: 0.486, green: 0.808, blue: 0.592) : Color(red: 0.176, green: 0.416, blue: 0.310)
    }
    var accentGold: Color {
        isDark ? Color(red: 0.961, green: 0.812, blue: 0.463) : Color(red: 0.839, green: 0.596, blue: 0.157)
    }
    var accentCoral: Color {
        isDark ? Color(red: 0.949, green: 0.620, blue: 0.482) : Color(red: 0.851, green: 0.467, blue: 0.341)
    }
    var trackBg: Color {
        isDark ? Color.white.opacity(0.12) : Color(red: 0.176, green: 0.416, blue: 0.310).opacity(0.12)
    }
}

struct ShineJarWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme
    var entry: ShineJarProvider.Entry

    private var palette: WidgetPalette {
        WidgetPalette(isDark: colorScheme == .dark)
    }

    private var snap: ShineWidgetSnapshot { entry.snapshot }

    private var isSnapshotFromToday: Bool {
        guard snap.updatedAtMs > 0 else { return false }
        let updatedDate = Date(timeIntervalSince1970: Double(snap.updatedAtMs) / 1000.0)
        return Calendar.current.isDateInToday(updatedDate)
    }

    private var effectiveTodayShineCount: Int {
        isSnapshotFromToday ? snap.todayShineCount : 0
    }

    private var effectiveTodayHabitsDone: Int {
        isSnapshotFromToday ? snap.todayHabitsDone : 0
    }

    private var isSandboxBlocked: Bool {
        !SharedWidgetStore.isAppGroupAvailable && snap.updatedAtMs == 0
    }

    private var currentTreeLeafCount: Int {
        guard snap.totalShineCount > 0 else { return 0 }
        let mod = snap.totalShineCount % 100
        return mod == 0 ? 100 : mod
    }

    private var treeSpeciesName: String {
        switch snap.treeSpeciesIndex % 4 {
        case 1: return "樱花暖粉树"
        case 2: return "鎏金银杏树"
        case 3: return "星夜蓝铃树"
        default: return "春日新芽树"
        }
    }

    private var stageName: String {
        switch currentTreeLeafCount {
        case 0: return "休眠星种"
        case 1...10: return "初生嫩芽"
        case 11...35: return "抽枝青树"
        case 36...75: return "繁花绿冠"
        case 76..<100: return "森境大树"
        default: return "圆满生命树"
        }
    }

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 1) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("\(effectiveTodayShineCount)")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                }
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                    Text("今日微步 +\(effectiveTodayShineCount)")
                        .font(.system(size: 13, weight: .bold))
                }
                Text("\(treeSpeciesName) · \(currentTreeLeafCount)/100 叶")
                    .font(.system(size: 11))
                    .opacity(0.85)
            }
        case .systemLarge:
            largeWidgetView
        case .systemMedium:
            mediumWidgetView
        default:
            smallWidgetView
        }
    }

    // MARK: - 小号小组件 (2x2)

    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(palette.accentGreen)
                Text(treeSpeciesName)
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(palette.inkPrimary)
                    .lineLimit(1)
                Spacer()
                Text("\(currentTreeLeafCount)/100")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(palette.accentGold)
            }

            Spacer(minLength: 2)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(effectiveTodayShineCount)")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(palette.inkPrimary)
                Text("今日微步")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(palette.inkSecondary)
            }

            // 成长树叶进度条
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(palette.trackBg)
                    Capsule()
                        .fill(LinearGradient(colors: [palette.accentGreen, palette.accentGold], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(6, g.size.width * CGFloat(currentTreeLeafCount) / 100.0))
                }
            }
            .frame(height: 5)

            Spacer(minLength: 2)

            if let topPlan = snap.pendingPlans.first,
               let url = planCompleteURL(id: topPlan.id) {
                Link(destination: url) {
                    HStack(spacing: 5) {
                        Circle()
                            .stroke(palette.accentGreen, lineWidth: 1.5)
                            .frame(width: 12, height: 12)
                        Text(topPlan.title)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(palette.inkPrimary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(palette.cardBg)
                    .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(palette.cardBorder, lineWidth: 0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
            } else if let topHabit = snap.pendingHabits.first,
                      let url = habitCompleteURL(id: topHabit.id) {
                Link(destination: url) {
                    HStack(spacing: 5) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(palette.accentGold)
                        Text(topHabit.title)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(palette.inkPrimary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(palette.cardBg)
                    .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(palette.cardBorder, lineWidth: 0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
            } else {
                Text("\(stageName) · 累计 \(snap.totalShineCount) 步")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(palette.inkSecondary)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .widgetBackground(palette.bg)
    }

    // MARK: - 中号小组件 (4x2)

    private var mediumWidgetView: some View {
        HStack(spacing: 12) {
            // 左侧：成长树与今日统计看板
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(palette.accentGreen)
                    Text("微步成长")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(palette.inkPrimary)
                }

                Spacer(minLength: 2)

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(effectiveTodayShineCount)")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(palette.inkPrimary)
                    Text("步")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(palette.inkSecondary)
                }

                Text("\(treeSpeciesName)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(palette.accentGold)
                    .lineLimit(1)

                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(palette.trackBg)
                        Capsule()
                            .fill(LinearGradient(colors: [palette.accentGreen, palette.accentGold], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(6, g.size.width * CGFloat(currentTreeLeafCount) / 100.0))
                    }
                }
                .frame(height: 5)

                Text("习惯 \(effectiveTodayHabitsDone)/\(max(1, snap.totalHabitsCount)) · 树 \(currentTreeLeafCount)/100")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(palette.inkSecondary)
                    .lineLimit(1)
            }
            .frame(width: 114, alignment: .leading)

            // 右侧：待办愿望与习惯快速打卡（点击直接进 App 庆祝）
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("点一下即刻完成")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(palette.inkSecondary)
                    Spacer()
                    if snap.totalPendingPlans > 0 {
                        Text("待办 \(snap.totalPendingPlans)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(palette.accentGreen)
                    }
                }

                let quickItems = buildMixedQuickItems(limit: 3)
                if quickItems.isEmpty {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: isSandboxBlocked ? "exclamationmark.triangle.fill" : "sun.max.fill")
                            .foregroundColor(isSandboxBlocked ? palette.accentCoral : palette.accentGold)
                        Text(isSandboxBlocked
                             ? "当前安装签名未启用 App Group，无法跨进程读取主 App 数据"
                             : "今天清单很轻盈，随时点进微步加一小步吧")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(palette.inkSecondary)
                            .lineLimit(3)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(palette.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    Spacer()
                } else {
                    ForEach(quickItems) { item in
                        widgetActionRow(item: item, compact: true)
                    }
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .widgetBackground(palette.bg)
    }

    // MARK: - 大号小组件 (4x4)

    private var largeWidgetView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 顶部总览栏
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(palette.accentGreen)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(treeSpeciesName) · \(stageName)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(palette.inkPrimary)
                        Text("本棵进度 \(currentTreeLeafCount)/100 叶 · 累计 \(snap.totalShineCount) 步")
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundColor(palette.inkSecondary)
                    }
                }
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("+\(effectiveTodayShineCount)")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(palette.accentGold)
                    Text("今日")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundColor(palette.inkSecondary)
                }
            }

            // 待办愿望区
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("微步愿望清单")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(palette.inkSecondary)
                    Spacer()
                    Text("点击直接完成并庆祝")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(palette.accentGreen)
                }

                if snap.pendingPlans.isEmpty {
                    Text("愿望清单都清空啦，太棒了！")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(palette.inkSecondary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(palette.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else {
                    ForEach(snap.pendingPlans.prefix(4)) { plan in
                        if let url = planCompleteURL(id: plan.id) {
                            widgetActionRow(
                                item: QuickWidgetItem(
                                    id: "plan-\(plan.id)",
                                    title: plan.title,
                                    badge: plan.pendingSubCount > 0 ? "含\(plan.pendingSubCount)步" : nil,
                                    isHabit: false,
                                    isDoneToday: false,
                                    url: url
                                ),
                                compact: false
                            )
                        }
                    }
                }
            }

            // 每日微习惯区
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("每日微习惯")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(palette.inkSecondary)
                    Spacer()
                    Text("今日已打卡 \(effectiveTodayHabitsDone)/\(snap.totalHabitsCount)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(palette.accentGold)
                }

                if snap.pendingHabits.isEmpty {
                    Text("打开微步添加一个轻盈微习惯吧")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(palette.inkSecondary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(palette.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else {
                    ForEach(snap.pendingHabits.prefix(3)) { habit in
                        if let url = habitCompleteURL(id: habit.id) {
                            widgetActionRow(
                                item: QuickWidgetItem(
                                    id: "habit-\(habit.id)",
                                    title: habit.title,
                                    badge: habit.todayCount > 0 ? "今日×\(habit.todayCount)" : (habit.isCore ? "核心" : "打卡"),
                                    isHabit: true,
                                    isDoneToday: habit.todayCount > 0,
                                    url: url
                                ),
                                compact: false
                            )
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .widgetBackground(palette.bg)
    }

    // MARK: - 子组件与深链构造

    private struct QuickWidgetItem: Identifiable {
        let id: String
        let title: String
        let badge: String?
        let isHabit: Bool
        let isDoneToday: Bool
        let url: URL
    }

    private func buildMixedQuickItems(limit: Int) -> [QuickWidgetItem] {
        var result: [QuickWidgetItem] = []
        for plan in snap.pendingPlans.prefix(2) {
            if let url = planCompleteURL(id: plan.id) {
                result.append(QuickWidgetItem(
                    id: "p-\(plan.id)",
                    title: plan.title,
                    badge: plan.pendingSubCount > 0 ? "\(plan.pendingSubCount)步" : nil,
                    isHabit: false,
                    isDoneToday: false,
                    url: url
                ))
            }
        }
        for habit in snap.pendingHabits where result.count < limit {
            if let url = habitCompleteURL(id: habit.id) {
                result.append(QuickWidgetItem(
                    id: "h-\(habit.id)",
                    title: habit.title,
                    badge: habit.todayCount > 0 ? "×\(habit.todayCount)" : "习惯",
                    isHabit: true,
                    isDoneToday: habit.todayCount > 0,
                    url: url
                ))
            }
        }
        for plan in snap.pendingPlans.dropFirst(2) where result.count < limit {
            if let url = planCompleteURL(id: plan.id) {
                result.append(QuickWidgetItem(
                    id: "p-\(plan.id)",
                    title: plan.title,
                    badge: plan.pendingSubCount > 0 ? "\(plan.pendingSubCount)步" : nil,
                    isHabit: false,
                    isDoneToday: false,
                    url: url
                ))
            }
        }
        return Array(result.prefix(limit))
    }

    @ViewBuilder
    private func widgetActionRow(item: QuickWidgetItem, compact: Bool) -> some View {
        Link(destination: item.url) {
            HStack(spacing: 8) {
                ZStack {
                    if item.isDoneToday {
                        Circle()
                            .fill(palette.accentGreen)
                            .frame(width: 15, height: 15)
                        Image(systemName: "checkmark")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .stroke(item.isHabit ? palette.accentGold : palette.accentGreen, lineWidth: 1.6)
                            .frame(width: 15, height: 15)
                    }
                }

                Text(item.title)
                    .font(.system(size: compact ? 12 : 12.5, weight: .semibold))
                    .foregroundColor(palette.inkPrimary)
                    .lineLimit(1)

                Spacer(minLength: 4)

                if let badge = item.badge {
                    Text(badge)
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(item.isHabit ? palette.accentGold : palette.accentGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background((item.isHabit ? palette.accentGold : palette.accentGreen).opacity(0.14))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, compact ? 6.5 : 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.cardBg)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(palette.cardBorder, lineWidth: 0.8)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func planCompleteURL(id: String) -> URL? {
        var c = URLComponents()
        c.scheme = "microaction"
        c.host = "complete-plan"
        c.queryItems = [URLQueryItem(name: "id", value: id)]
        return c.url
    }

    private func habitCompleteURL(id: String) -> URL? {
        var c = URLComponents()
        c.scheme = "microaction"
        c.host = "complete-habit"
        c.queryItems = [URLQueryItem(name: "id", value: id)]
        return c.url
    }
}

private extension View {
    @ViewBuilder
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self.containerBackground(color, for: .widget)
        } else {
            self.background(color)
        }
    }
}

struct ShineJarWidget: Widget {
    let kind: String = "ShineJarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShineJarProvider()) { entry in
            ShineJarWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("微步今日看板")
        .description("在桌面随时查看今日微步、成长树进度与待办愿望，轻点即可直达庆祝。")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}
