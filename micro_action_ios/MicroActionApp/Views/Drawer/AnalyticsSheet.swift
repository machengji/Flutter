import SwiftUI
import UIKit

/// 成长洞察 2.0：顶部莫兰迪双环节奏大卡（支持导出本周复盘海报）+ 三段式聚焦视图（总览 / 愿望 / 习惯）+ 跨 Tab 跳转闭环
struct AnalyticsTabView: View {
    enum Segment: String, CaseIterable, Identifiable {
        case overview = "总览"
        case wishes = "愿望"
        case habits = "习惯"
        var id: String { rawValue }
    }

    @EnvironmentObject private var appState: AppState
    @State private var selectedSegment: Segment = .overview
    @State private var trendWindowDays: Int = 7
    @State private var exportToast: String? = nil
    @State private var isExporting: Bool = false
    @Namespace private var segmentNS

    private var snapshot: LocalAnalyticsSnapshot {
        LocalAnalyticsEngine.analyze(
            plans: appState.plans,
            habits: appState.habits,
            anchors: appState.anchors,
            records: appState.shineRecords
        )
    }

    var body: some View {
        let data = snapshot

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                if let toast = exportToast {
                    Text(toast)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(BotanicalTheme.primaryDark)
                        .clipShape(Capsule())
                        .frame(maxWidth: .infinity)
                        .transition(.opacity)
                }

                // 1. 顶部莫兰迪双环节奏大卡 + 一键导出本周复盘海报
                MorandiHeroRhythmCard(
                    data: data,
                    todayCount: appState.todayShineCount,
                    isExporting: isExporting,
                    onExportPoster: {
                        exportWeeklyPoster(data: data)
                    }
                )

                // 2. 三段式切换胶囊（总览 / 愿望 / 习惯）
                HStack(spacing: 4) {
                    ForEach(Segment.allCases) { seg in
                        let isSelected = selectedSegment == seg
                        Button {
                            SensoryFeedbackService.shared.selection()
                            withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                                selectedSegment = seg
                            }
                        } label: {
                            Text(seg.rawValue)
                                .font(.system(size: 13.5, weight: isSelected ? .bold : .semibold))
                                .foregroundColor(isSelected ? .white : BotanicalTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background {
                                    if isSelected {
                                        Capsule()
                                            .fill(BotanicalTheme.primaryGradient)
                                            .matchedGeometryEffect(id: "insightSeg", in: segmentNS)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .background(Color.white.opacity(0.86))
                .overlay(Capsule().stroke(BotanicalTheme.border, lineWidth: 0.9))
                .clipShape(Capsule())

                // 3. 分段专属硬核可视化（每个分段仅呈现 2 个高密度精选图表）
                switch selectedSegment {
                case .overview:
                    TwelveWeekHeatmapCard(records: appState.shineRecords)
                    InteractiveTrendBarChartCard(records: appState.shineRecords, days: $trendWindowDays)

                case .wishes:
                    WishStructureDonutCard(
                        mainCount: appState.mainContradictionPlans.count,
                        normalCount: appState.normalOngoingPlans.count,
                        doneCount: appState.completedPlans.count,
                        mainSubRate: data.mainContradictionSubRate
                    )
                    StaleWishAgeRankCard(items: data.staleWishes) { planId in
                        SensoryFeedbackService.shared.lightTap()
                        appState.pendingLocatePlanId = planId
                    }

                case .habits:
                    HabitWeeklyMatrixCard(habits: appState.activeHabits) { habitId in
                        SensoryFeedbackService.shared.lightTap()
                        appState.pendingLocateHabitId = habitId
                    }
                    if !data.habitRanks.isEmpty {
                        HabitRankBarChartCard(items: Array(data.habitRanks.prefix(6)))
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 130)
        }
    }

    @MainActor
    private func exportWeeklyPoster(data: LocalAnalyticsSnapshot) {
        guard !isExporting else { return }
        isExporting = true
        SensoryFeedbackService.shared.lightTap()

        let posterView = WeeklyReviewExportPoster(
            data: data,
            todayCount: appState.todayShineCount,
            records: appState.shineRecords
        )
        let renderer = ImageRenderer(content: posterView)
        renderer.scale = 3.0
        if let uiImage = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            showToast("本周成长复盘海报已保存至系统相册")
        } else {
            showToast("生成海报失败，请稍后重试")
        }
        isExporting = false
    }

    private func showToast(_ msg: String) {
        withAnimation(.easeOut(duration: 0.2)) { exportToast = msg }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if exportToast == msg {
                withAnimation(.easeIn(duration: 0.2)) { exportToast = nil }
            }
        }
    }
}

// MARK: - 顶部莫兰迪双环节奏大卡

private struct MorandiHeroRhythmCard: View {
    let data: LocalAnalyticsSnapshot
    let todayCount: Int
    let isExporting: Bool
    let onExportPoster: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 16) {
                // 左侧莫兰迪双层进度环（外环近7日活跃率，内环愿望达成率）
                ZStack {
                    Circle()
                        .stroke(Color(hex: 0xE2EAE4), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: CGFloat(data.activeDays7) / 7.0)
                        .stroke(
                            LinearGradient(colors: [Color(hex: 0x56A573), Color(hex: 0x2F6E4A)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    Circle()
                        .stroke(Color(hex: 0xF1E8D8), lineWidth: 7)
                        .padding(13)
                    Circle()
                        .trim(from: 0, to: CGFloat(max(0.04, data.wishCompletionRate)))
                        .stroke(
                            LinearGradient(colors: [Color(hex: 0xE8B95B), Color(hex: 0xD97736)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 7, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .padding(13)

                    VStack(spacing: 0) {
                        Text("\(data.vitalityScore)")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(hex: 0x1B3F2E))
                        Text("节奏分")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(Color(hex: 0x5E7A6B))
                    }
                }
                .frame(width: 96, height: 96)

                // 右侧阶段标题、关键指标与一句话诊断
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(data.phaseTitle)
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(hex: 0x1B3F2E))
                        Spacer()
                        Button(action: onExportPoster) {
                            HStack(spacing: 3) {
                                if isExporting {
                                    ProgressView().scaleEffect(0.65).tint(BotanicalTheme.primaryDark)
                                } else {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 11.5, weight: .bold))
                                }
                                Text("周报")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(Color(hex: 0x1D4432))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.85))
                            .overlay(Capsule().stroke(Color(hex: 0xD8E3DA), lineWidth: 0.9))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(ScaleBounceButtonStyle(scale: 0.93))
                        .disabled(isExporting)
                    }

                    HStack(spacing: 6) {
                        miniBadge(text: "连续 \(data.streakDays) 天", tint: Color(hex: 0x1D4432), bg: Color(hex: 0xDFF0E4))
                        miniBadge(
                            text: data.weekDeltaText,
                            tint: data.weekDeltaPositive ? Color(hex: 0x1D4432) : Color(hex: 0xB8531E),
                            bg: data.weekDeltaPositive ? Color(hex: 0xEBF5EE) : Color(hex: 0xFCEAD7)
                        )
                    }

                    Text(data.summaryLine)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(Color(hex: 0x4A6B5A))
                        .lineLimit(2)
                        .lineSpacing(3)
                }
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color(hex: 0xFAF8F3), Color(hex: 0xEDF6F0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.95), lineWidth: 1.2)
        )
        .shadow(color: BotanicalTheme.primaryDark.opacity(0.06), radius: 10, y: 4)
    }

    private func miniBadge(text: String, tint: Color, bg: Color) -> some View {
        Text(text)
            .font(.system(size: 10.5, weight: .bold, design: .rounded))
            .foregroundColor(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(bg)
            .clipShape(Capsule())
    }
}

// MARK: - 总览图表 1：GitHub 风格近 12 周发光热力图（支持点选格子看当日步数）

private struct TwelveWeekHeatmapCard: View {
    let records: [ShineRecord]
    @State private var selectedCell: HeatCell? = nil

    private struct HeatCell: Identifiable, Equatable {
        let id: Int
        let date: Date
        let count: Int
        let isFuture: Bool
    }

    private var gridData: (weeks: [[HeatCell]], total84: Int, activeDays: Int) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today) // 1=Sun, 2=Mon...
        let daysFromMonday = (weekday + 5) % 7
        let currentWeekMonday = cal.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
        let startMonday = cal.date(byAdding: .day, value: -11 * 7, to: currentWeekMonday) ?? today

        var dayCounts: [Date: Int] = [:]
        for r in records {
            let d = cal.startOfDay(for: Date(timeIntervalSince1970: TimeInterval(r.timestamp) / 1000.0))
            dayCounts[d, default: 0] += 1
        }

        var weeks: [[HeatCell]] = []
        var total = 0
        var active = 0
        var idx = 0
        for w in 0..<12 {
            var col: [HeatCell] = []
            for d in 0..<7 {
                let date = cal.date(byAdding: .day, value: w * 7 + d, to: startMonday) ?? today
                let isFuture = date > today
                let cnt = isFuture ? 0 : (dayCounts[date] ?? 0)
                if !isFuture {
                    total += cnt
                    if cnt > 0 { active += 1 }
                }
                col.append(HeatCell(id: idx, date: date, count: cnt, isFuture: isFuture))
                idx += 1
            }
            weeks.append(col)
        }
        return (weeks, total, active)
    }

    var body: some View {
        let res = gridData
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("近 12 周发光热力", systemImage: "square.grid.3x3.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(BotanicalTheme.textPrimary)
                Spacer()
                if let cell = selectedCell {
                    Text("\(formatShortDate(cell.date)) · \(cell.count) 步")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: 0xB8531E))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(Color(hex: 0xFCEAD7))
                        .clipShape(Capsule())
                } else {
                    Text("活跃 \(res.activeDays) 天 · \(res.total84) 步")
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .foregroundColor(BotanicalTheme.textSecondary)
                }
            }

            HStack(spacing: 4) {
                ForEach(Array(res.weeks.enumerated()), id: \.offset) { _, week in
                    VStack(spacing: 4) {
                        ForEach(week) { cell in
                            let isSelected = selectedCell?.id == cell.id
                            RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                                .fill(cellColor(for: cell))
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                                        .stroke(isSelected ? Color(hex: 0xD96B27) : Color.clear, lineWidth: 1.5)
                                )
                                .onTapGesture {
                                    guard !cell.isFuture else { return }
                                    SensoryFeedbackService.shared.selection()
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        selectedCell = (selectedCell?.id == cell.id) ? nil : cell
                                    }
                                }
                        }
                    }
                }
            }

            HStack(spacing: 4) {
                Text("轻点格子查看当日步数")
                    .font(.system(size: 10.5))
                    .foregroundColor(BotanicalTheme.textHint)
                Spacer()
                Text("少")
                    .font(.system(size: 10))
                    .foregroundColor(BotanicalTheme.textHint)
                ForEach([0, 1, 2, 4, 6], id: \.self) { lv in
                    RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                        .fill(levelColor(lv))
                        .frame(width: 10, height: 10)
                }
                Text("多")
                    .font(.system(size: 10))
                    .foregroundColor(BotanicalTheme.textHint)
            }
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 22, tint: BotanicalTheme.primaryLight, interactive: false, shadowRadius: 8)
    }

    private func cellColor(for cell: HeatCell) -> Color {
        if cell.isFuture { return Color.clear }
        return levelColor(cell.count)
    }

    private func levelColor(_ count: Int) -> Color {
        switch count {
        case 0: return Color(hex: 0xEDF2EE)
        case 1: return Color(hex: 0xC6E5CE)
        case 2...3: return Color(hex: 0x88CC9B)
        case 4...5: return Color(hex: 0x4BA368)
        default: return Color(hex: 0x246941)
        }
    }

    private func formatShortDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "M月d日"
        return f.string(from: d)
    }
}

// MARK: - 总览图表 2：可点选趋势柱状图（点柱子直接看当天具体完成的事项）

private struct InteractiveTrendBarChartCard: View {
    let records: [ShineRecord]
    @Binding var days: Int
    @State private var selectedOffset: Int? = nil

    private struct DayPoint: Identifiable {
        let id: Int
        let date: Date
        let label: String
        let dayRecords: [ShineRecord]
        let isToday: Bool
        var count: Int { dayRecords.count }
    }

    private var points: [DayPoint] {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = days <= 7 ? "E" : "d"
        formatter.locale = Locale(identifier: "zh_CN")

        return (0..<days).map { offset -> DayPoint in
            let dayOffset = offset - (days - 1)
            let dayDate = cal.date(byAdding: .day, value: dayOffset, to: todayStart) ?? todayStart
            let nextDate = cal.date(byAdding: .day, value: 1, to: dayDate) ?? dayDate
            let startMs = Int64(dayDate.timeIntervalSince1970 * 1000)
            let endMs = Int64(nextDate.timeIntervalSince1970 * 1000)
            let matched = records.filter { $0.timestamp >= startMs && $0.timestamp < endMs }
            let shortLabel: String
            if days <= 7 {
                shortLabel = dayOffset == 0 ? "今天" : formatter.string(from: dayDate).replacingOccurrences(of: "周", with: "")
            } else {
                shortLabel = (offset % 6 == 0 || dayOffset == 0) ? (dayOffset == 0 ? "今" : formatter.string(from: dayDate)) : ""
            }
            return DayPoint(id: offset, date: dayDate, label: shortLabel, dayRecords: matched, isToday: dayOffset == 0)
        }
    }

    var body: some View {
        let data = points
        let maxCount = max(data.map(\.count).max() ?? 1, 1)
        let activeIdx = selectedOffset ?? (data.count - 1)
        let safePoint = (activeIdx >= 0 && activeIdx < data.count) ? data[activeIdx] : nil

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("微步趋势明细", systemImage: "chart.bar.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(BotanicalTheme.textPrimary)
                Spacer()
                HStack(spacing: 4) {
                    windowChip(title: "7天", value: 7)
                    windowChip(title: "30天", value: 30)
                }
                .padding(3)
                .background(BotanicalTheme.surfaceMuted)
                .clipShape(Capsule())
            }

            HStack(alignment: .bottom, spacing: days <= 7 ? 10 : 3) {
                ForEach(data) { pt in
                    let isSelected = (safePoint?.id == pt.id)
                    VStack(spacing: 4) {
                        if days <= 7 {
                            Text("\(pt.count)")
                                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                .foregroundColor(isSelected ? Color(hex: 0xB8531E) : BotanicalTheme.textSecondary)
                                .opacity(pt.count > 0 || isSelected ? 1 : 0.4)
                        }

                        RoundedRectangle(cornerRadius: days <= 7 ? 6 : 2.5, style: .continuous)
                            .fill(
                                isSelected
                                    ? LinearGradient(colors: [Color(hex: 0xF3B65B), Color(hex: 0xE07A38)], startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(colors: [BotanicalTheme.primary.opacity(0.82), BotanicalTheme.primary.opacity(0.45)], startPoint: .top, endPoint: .bottom)
                            )
                            .frame(height: max(6, CGFloat(pt.count) / CGFloat(maxCount) * 74))
                            .frame(maxWidth: .infinity)

                        if !pt.label.isEmpty || days <= 7 {
                            Text(pt.label)
                                .font(.system(size: days <= 7 ? 11 : 9.5, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? BotanicalTheme.textPrimary : BotanicalTheme.textSecondary)
                                .lineLimit(1)
                        } else {
                            Color.clear.frame(height: 12)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        SensoryFeedbackService.shared.selection()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            selectedOffset = pt.id
                        }
                    }
                }
            }
            .frame(height: 114, alignment: .bottom)

            // 选中日期的具体完成事项列表
            if let pt = safePoint {
                VStack(alignment: .leading, spacing: 6) {
                    Divider().opacity(0.45)
                    HStack {
                        Text(formatDayHeader(pt.date, isToday: pt.isToday))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(BotanicalTheme.primaryDark)
                        Spacer()
                        Text("共 \(pt.count) 项")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(BotanicalTheme.textSecondary)
                    }

                    if pt.dayRecords.isEmpty {
                        Text("这一天暂无微步记录")
                            .font(.system(size: 12))
                            .foregroundColor(BotanicalTheme.textHint)
                            .padding(.vertical, 2)
                    } else {
                        ForEach(pt.dayRecords.prefix(5)) { rec in
                            HStack(spacing: 7) {
                                Circle()
                                    .fill(BotanicalTheme.primary)
                                    .frame(width: 5, height: 5)
                                Text(rec.title)
                                    .font(.system(size: 12.5, weight: .medium))
                                    .foregroundColor(BotanicalTheme.textPrimary)
                                    .lineLimit(1)
                                Spacer()
                                Text(formatTime(rec.timestamp))
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundColor(BotanicalTheme.textHint)
                            }
                        }
                        if pt.dayRecords.count > 5 {
                            Text("还有 \(pt.dayRecords.count - 5) 条记录...")
                                .font(.system(size: 11))
                                .foregroundColor(BotanicalTheme.textHint)
                        }
                    }
                }
            }
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 22, tint: BotanicalTheme.primaryLight, interactive: false, shadowRadius: 8)
    }

    private func windowChip(title: String, value: Int) -> some View {
        let selected = days == value
        return Button {
            SensoryFeedbackService.shared.selection()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                days = value
                selectedOffset = value - 1
            }
        } label: {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(selected ? .white : BotanicalTheme.textSecondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(selected ? BotanicalTheme.primary : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func formatDayHeader(_ date: Date, isToday: Bool) -> String {
        let f = DateFormatter()
        f.dateFormat = "M月d日"
        return isToday ? "今天（\(f.string(from: date))）完成的微步" : "\(f.string(from: date)) 完成的微步"
    }

    private func formatTime(_ ms: Int64) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: Date(timeIntervalSince1970: TimeInterval(ms) / 1000.0))
    }
}

// MARK: - 愿望图表 1：愿望结构与推进环形图

private struct WishStructureDonutCard: View {
    let mainCount: Int
    let normalCount: Int
    let doneCount: Int
    let mainSubRate: Int?

    var body: some View {
        let total = max(mainCount + normalCount + doneCount, 1)
        let completionRate = Int(round(Double(doneCount) / Double(total) * 100.0))
        let mainEnd = Double(mainCount) / Double(total)
        let normalEnd = mainEnd + Double(normalCount) / Double(total)

        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(BotanicalTheme.surfaceMuted, lineWidth: 13)

                if mainCount > 0 {
                    Circle()
                        .trim(from: 0, to: mainEnd)
                        .stroke(Color(hex: 0xE07A38), style: StrokeStyle(lineWidth: 13, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                if normalCount > 0 {
                    Circle()
                        .trim(from: mainEnd, to: normalEnd)
                        .stroke(BotanicalTheme.primaryLight, style: StrokeStyle(lineWidth: 13, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                if doneCount > 0 {
                    Circle()
                        .trim(from: normalEnd, to: 1.0)
                        .stroke(BotanicalTheme.primaryDark, style: StrokeStyle(lineWidth: 13, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }

                VStack(spacing: 1) {
                    Text("\(completionRate)%")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(BotanicalTheme.primaryDark)
                    Text("达成率")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(BotanicalTheme.textSecondary)
                }
            }
            .frame(width: 92, height: 92)

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text("愿望结构分布")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(BotanicalTheme.textPrimary)
                    Spacer()
                    if let subRate = mainSubRate {
                        Text("矛盾步骤 \(subRate)%")
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundColor(Color(hex: 0xB8531E))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(Color(hex: 0xFCEAD7))
                            .clipShape(Capsule())
                    }
                }

                legendRow(color: Color(hex: 0xE07A38), title: "主要矛盾", value: mainCount)
                legendRow(color: BotanicalTheme.primaryLight, title: "进行中愿望", value: normalCount)
                legendRow(color: BotanicalTheme.primaryDark, title: "已达成愿望", value: doneCount)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 22, tint: BotanicalTheme.primaryLight, interactive: false, shadowRadius: 8)
    }

    private func legendRow(color: Color, title: String, value: Int) -> some View {
        HStack(spacing: 7) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundColor(BotanicalTheme.textSecondary)
            Spacer()
            Text("\(value)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(BotanicalTheme.textPrimary)
        }
    }
}

// MARK: - 愿望图表 2：拖延天龄榜（点击直接跳回愿望页并展开定位）

private struct StaleWishAgeRankCard: View {
    let items: [LocalAnalyticsSnapshot.StaleWishEntry]
    let onLocate: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Label("愿望拖延天龄榜", systemImage: "hourglass.bottomhalf.filled")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(BotanicalTheme.textPrimary)
                Spacer()
                Text("轻点直达定位")
                    .font(.system(size: 11))
                    .foregroundColor(BotanicalTheme.textHint)
            }

            if items.isEmpty {
                Text("太棒了！目前没有搁置中的待办愿望")
                    .font(.system(size: 13))
                    .foregroundColor(BotanicalTheme.textSecondary)
                    .padding(.vertical, 8)
            } else {
                let maxDays = max(items.map(\.ageDays).max() ?? 1, 1)
                ForEach(items) { item in
                    Button {
                        onLocate(item.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack(spacing: 6) {
                                if item.isMain {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 10.5))
                                        .foregroundColor(Color(hex: 0xD96B27))
                                }
                                Text(item.name)
                                    .font(.system(size: 13.5, weight: .semibold))
                                    .foregroundColor(BotanicalTheme.textPrimary)
                                    .lineLimit(1)
                                Spacer()
                                Text(item.ageDays == 0 ? "今天新建" : "已搁置 \(item.ageDays) 天")
                                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                    .foregroundColor(item.ageDays >= 7 ? Color(hex: 0xB8531E) : BotanicalTheme.textSecondary)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10.5, weight: .semibold))
                                    .foregroundColor(BotanicalTheme.textHint)
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(BotanicalTheme.surfaceMuted)
                                    Capsule()
                                        .fill(
                                            item.ageDays >= 7
                                                ? LinearGradient(colors: [Color(hex: 0xF3B65B), Color(hex: 0xD96B27)], startPoint: .leading, endPoint: .trailing)
                                                : BotanicalTheme.primaryGradient
                                        )
                                        .frame(width: max(12, geo.size.width * CGFloat(max(1, item.ageDays)) / CGFloat(maxDays)))
                                }
                            }
                            .frame(height: 6.5)
                        }
                        .padding(.vertical, 3)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 22, tint: Color(hex: 0xD96B27), interactive: false, shadowRadius: 8)
    }
}

// MARK: - 习惯图表 1：本周 7 天打卡矩阵（点击直接跳回习惯页并展开定位）

private struct HabitWeeklyMatrixCard: View {
    let habits: [HabitItem]
    let onLocate: (String) -> Void

    private var last7Days: [(date: Date, label: String, isToday: Bool)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "E"
        return (0..<7).map { i in
            let offset = i - 6
            let d = cal.date(byAdding: .day, value: offset, to: today) ?? today
            let lbl = offset == 0 ? "今" : f.string(from: d).replacingOccurrences(of: "周", with: "")
            return (d, lbl, offset == 0)
        }
    }

    var body: some View {
        let days = last7Days
        let cal = Calendar.current

        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Label("近 7 天习惯打卡矩阵", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(BotanicalTheme.textPrimary)
                Spacer()
                Text("轻点跳转定位")
                    .font(.system(size: 11))
                    .foregroundColor(BotanicalTheme.textHint)
            }

            if habits.isEmpty {
                Text("暂无进行中的微习惯")
                    .font(.system(size: 13))
                    .foregroundColor(BotanicalTheme.textSecondary)
                    .padding(.vertical, 8)
            } else {
                // 列头星期
                HStack(spacing: 6) {
                    Text("习惯")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(BotanicalTheme.textHint)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(Array(days.enumerated()), id: \.offset) { _, d in
                        Text(d.label)
                            .font(.system(size: 10.5, weight: d.isToday ? .bold : .medium))
                            .foregroundColor(d.isToday ? Color(hex: 0xB8531E) : BotanicalTheme.textHint)
                            .frame(width: 20)
                    }
                }

                ForEach(habits.prefix(8)) { habit in
                    let doneDays = Set(habit.completionHistory.map { cal.startOfDay(for: Date(timeIntervalSince1970: TimeInterval($0) / 1000.0)) })
                    Button {
                        onLocate(habit.id)
                    } label: {
                        HStack(spacing: 6) {
                            HStack(spacing: 4) {
                                if habit.isCoreHabit {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(Color(hex: 0xD96B27))
                                }
                                Text(habit.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(BotanicalTheme.textPrimary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            ForEach(Array(days.enumerated()), id: \.offset) { _, d in
                                let checked = doneDays.contains(d.date)
                                Circle()
                                    .fill(checked ? BotanicalTheme.primary : Color(hex: 0xE9EFEA))
                                    .frame(width: 14, height: 14)
                                    .overlay(
                                        Circle()
                                            .stroke(d.isToday && !checked ? Color(hex: 0xE07A38).opacity(0.65) : Color.clear, lineWidth: 1.2)
                                    )
                                    .frame(width: 20)
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 22, tint: BotanicalTheme.primaryLight, interactive: false, shadowRadius: 8)
    }
}

// MARK: - 习惯图表 2：微习惯累计坚持排行

private struct HabitRankBarChartCard: View {
    let items: [LocalAnalyticsSnapshot.HabitRankEntry]

    var body: some View {
        let maxCount = max(items.map(\.count).max() ?? 1, 1)
        VStack(alignment: .leading, spacing: 11) {
            Label("微习惯累计坚持排行", systemImage: "flame.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(BotanicalTheme.textPrimary)

            ForEach(Array(items.enumerated()), id: \.element.id) { idx, habit in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        if habit.isCore {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10.5))
                                .foregroundColor(Color(hex: 0xD96B27))
                        }
                        Text(habit.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(BotanicalTheme.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Text("\(habit.count) 次")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(idx == 0 ? Color(hex: 0xB8531E) : BotanicalTheme.primaryDark)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(BotanicalTheme.surfaceMuted)
                            Capsule()
                                .fill(
                                    idx == 0
                                        ? LinearGradient(colors: [Color(hex: 0xF3B65B), Color(hex: 0xE07A38)], startPoint: .leading, endPoint: .trailing)
                                        : BotanicalTheme.primaryGradient
                                )
                                .frame(width: max(10, geo.size.width * CGFloat(habit.count) / CGFloat(maxCount)))
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 22, tint: BotanicalTheme.warning, interactive: false, shadowRadius: 8)
    }
}

// MARK: - 莫兰迪本周成长复盘导出海报（3x 高清保存相册）

private struct WeeklyReviewExportPoster: View {
    let data: LocalAnalyticsSnapshot
    let todayCount: Int
    let records: [ShineRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("微步 · 本周成长复盘")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(hex: 0x1B3F2E))
                    Text(dateRangeLabel)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: 0x5E7A6B))
                }
                Spacer()
                Text("\(data.vitalityScore) 分")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(hex: 0x2F6E4A))
            }

            HStack(spacing: 10) {
                posterStat("本周活跃", "\(data.activeDays7)/7 天")
                posterStat("连续发光", "\(data.streakDays) 天")
                posterStat("本周对比", data.weekDeltaText)
            }

            Text(data.summaryLine)
                .font(.system(size: 13.5, weight: .medium))
                .foregroundColor(Color(hex: 0x3A5949))
                .lineSpacing(4)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            HStack {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 11))
                    .foregroundColor(BotanicalTheme.primary)
                Text("微小的每一步，都在悄悄长成森林")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(Color(hex: 0x5E7A6B))
                Spacer()
            }
        }
        .padding(24)
        .frame(width: 360)
        .background(
            LinearGradient(
                colors: [Color(hex: 0xFAF8F3), Color(hex: 0xEBF5EE)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var dateRangeLabel: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd"
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -6, to: end) ?? end
        return "\(f.string(from: start)) - \(f.string(from: end))"
    }

    private func posterStat(_ title: String, _ val: String) -> some View {
        VStack(spacing: 4) {
            Text(val)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(Color(hex: 0x1B3F2E))
            Text(title)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundColor(Color(hex: 0x5E7A6B))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - 100% 本地行为数据分析引擎

private struct LocalAnalyticsSnapshot {
    struct HabitRankEntry: Identifiable {
        let id: String
        let name: String
        let count: Int
        let isCore: Bool
    }

    struct StaleWishEntry: Identifiable {
        let id: String
        let name: String
        let ageDays: Int
        let isMain: Bool
    }

    let vitalityScore: Int
    let activeDays7: Int
    let wishCompletionRate: Double
    let streakDays: Int
    let phaseTitle: String
    let weekDeltaText: String
    let weekDeltaPositive: Bool
    let summaryLine: String
    let mainContradictionSubRate: Int?
    let staleWishes: [StaleWishEntry]
    let habitRanks: [HabitRankEntry]
}

private enum LocalAnalyticsEngine {
    static func analyze(
        plans: [PlanItem],
        habits: [HabitItem],
        anchors: [AnchorItem],
        records: [ShineRecord]
    ) -> LocalAnalyticsSnapshot {
        let cal = Calendar.current
        let now = Date()
        let todayStart = cal.startOfDay(for: now)
        let nowMs = Int64(now.timeIntervalSince1970 * 1000)

        let daySet = Set(records.map { cal.startOfDay(for: Date(timeIntervalSince1970: TimeInterval($0.timestamp) / 1000.0)) })
        var streak = 0
        var checkDate = todayStart
        if !daySet.contains(todayStart), let yesterday = cal.date(byAdding: .day, value: -1, to: todayStart) {
            checkDate = yesterday
        }
        while daySet.contains(checkDate) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }

        let sevenDaysAgoMs = Int64((cal.date(byAdding: .day, value: -6, to: todayStart) ?? todayStart).timeIntervalSince1970 * 1000)
        let fourteenDaysAgoMs = Int64((cal.date(byAdding: .day, value: -13, to: todayStart) ?? todayStart).timeIntervalSince1970 * 1000)
        let thisWeekCount = records.filter { $0.timestamp >= sevenDaysAgoMs }.count
        let lastWeekCount = records.filter { $0.timestamp >= fourteenDaysAgoMs && $0.timestamp < sevenDaysAgoMs }.count

        let weekDeltaText: String
        let weekDeltaPositive: Bool
        if lastWeekCount == 0 {
            weekDeltaText = thisWeekCount > 0 ? "本周 +\(thisWeekCount) 步" : "待起步"
            weekDeltaPositive = true
        } else {
            let pct = Int(round(Double(thisWeekCount - lastWeekCount) / Double(lastWeekCount) * 100.0))
            weekDeltaPositive = pct >= 0
            weekDeltaText = pct >= 0 ? "较上周 +\(pct)%" : "较上周 \(pct)%"
        }

        let ongoingPlans = plans.filter { $0.status == .ongoing }
        let completedPlans = plans.filter { $0.status == .completed }
        let mainPlans = ongoingPlans.filter { $0.isMainContradiction }
        let totalWishes = max(ongoingPlans.count + completedPlans.count, 1)
        let wishRate = Double(completedPlans.count) / Double(totalWishes)

        let mainIds = Set(mainPlans.map(\.id))
        let mainChildren = plans.filter { p in
            guard let pid = p.parentId else { return false }
            return mainIds.contains(pid) && p.status != .archived
        }
        let mainSubRate: Int? = mainChildren.isEmpty
            ? nil
            : Int(round(Double(mainChildren.filter { $0.status == .completed }.count) / Double(mainChildren.count) * 100.0))

        let activeHabits = habits.filter { $0.status == .active }
        let checkedTodayHabits = activeHabits.filter { $0.todayCheckCount() > 0 }.count
        let habitRate = activeHabits.isEmpty ? 0.0 : Double(checkedTodayHabits) / Double(activeHabits.count)

        let activeDays7 = (0..<7).filter { offset in
            let d = cal.date(byAdding: .day, value: -offset, to: todayStart) ?? todayStart
            return daySet.contains(d)
        }.count

        let vitality = min(
            100,
            max(
                records.isEmpty && completedPlans.isEmpty ? 15 : 28,
                Int(round(Double(activeDays7) / 7.0 * 42.0 + wishRate * 28.0 + habitRate * 20.0 + (mainPlans.isEmpty ? 0 : 10.0)))
            )
        )

        let phaseTitle: String
        switch vitality {
        case 80...100: phaseTitle = "高光复利期"
        case 55..<80: phaseTitle = "稳步推进期"
        case 35..<55: phaseTitle = "蓄力萌芽期"
        default: phaseTitle = "轻盈起步期"
        }

        let summaryLine: String
        if records.isEmpty {
            summaryLine = "完成第一件 2 分钟小事，即可自动点亮 12 周热力图与成长曲线。"
        } else if !mainPlans.isEmpty {
            summaryLine = "近 7 日活跃 \(activeDays7)/7 天，当前优先攻克「\(mainPlans.first?.name ?? "")」等 \(mainPlans.count) 项主要矛盾。"
        } else {
            summaryLine = "本周累计点亮 \(thisWeekCount) 步微光，活跃 \(activeDays7) 天，节奏稳健。"
        }

        // 拖延天龄榜（按创建时间从最早到最近排序 Top 6）
        let staleWishes: [LocalAnalyticsSnapshot.StaleWishEntry] = ongoingPlans
            .sorted { $0.createTime < $1.createTime }
            .prefix(6)
            .map { p in
                let age = max(0, Int((nowMs - p.createTime) / 86_400_000))
                return LocalAnalyticsSnapshot.StaleWishEntry(id: p.id, name: p.name, ageDays: age, isMain: p.isMainContradiction)
            }

        let habitRanks = activeHabits
            .sorted { a, b in
                if a.totalDays != b.totalDays { return a.totalDays > b.totalDays }
                return a.isCoreHabit && !b.isCoreHabit
            }
            .map { LocalAnalyticsSnapshot.HabitRankEntry(id: $0.id, name: $0.name, count: $0.totalDays, isCore: $0.isCoreHabit) }

        return LocalAnalyticsSnapshot(
            vitalityScore: vitality,
            activeDays7: activeDays7,
            wishCompletionRate: wishRate,
            streakDays: streak,
            phaseTitle: phaseTitle,
            weekDeltaText: weekDeltaText,
            weekDeltaPositive: weekDeltaPositive,
            summaryLine: summaryLine,
            mainContradictionSubRate: mainSubRate,
            staleWishes: staleWishes,
            habitRanks: habitRanks
        )
    }
}

/// 兼容旧 Sheet 路由的薄包装层
struct AnalyticsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            AnalyticsTabView()
                .liquidSheetCanvasBackground()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("完成") { dismiss() }
                            .foregroundColor(BotanicalTheme.primary)
                    }
                }
        }
    }
}
