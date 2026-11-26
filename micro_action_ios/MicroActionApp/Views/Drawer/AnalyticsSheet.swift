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
    @EnvironmentObject private var proStore: ProStoreService
    @State private var selectedSegment: Segment = .overview
    @State private var trendWindowDays: Int = 7
    @State private var exportToast: String? = nil
    @State private var isExporting: Bool = false
    @State private var showMindMap: Bool = false
    @State private var showProPaywall: Bool = false
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

                // 1.5 AI 全景思维导图入口卡片（点击沉浸打开可缩放拖拽无限画布）
                Button {
                    SensoryFeedbackService.shared.lightTap()
                    if !proStore.isPro {
                        showProPaywall = true
                    } else {
                        showMindMap = true
                    }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(BotanicalTheme.primaryGradient)
                                .frame(width: 44, height: 44)
                            Image(systemName: "point.3.connected.trianglepath.dotted")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text("AI 全景思维导图")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(BotanicalTheme.textPrimary)
                                if !proStore.isPro {
                                    Text("PRO")
                                        .font(.system(size: 9.5, weight: .heavy))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(BotanicalTheme.accentWarm)
                                        .clipShape(Capsule())
                                }
                                Text("全量聚类")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(BotanicalTheme.primaryDark)
                                    .padding(.horizontal, 6.5)
                                    .padding(.vertical, 2)
                                    .background(BotanicalTheme.primarySoft)
                                    .clipShape(Capsule())
                            }
                            Text(
                                appState.cachedMindMap != nil
                                    ? "已收录 \(appState.cachedMindMap!.root.totalLeafCount) 项记录 · 点击打开缩放导图"
                                    : "用 AI 把全部愿望、习惯与时间锚点画成一张全景导图"
                            )
                            .font(.system(size: 11.5))
                            .foregroundColor(BotanicalTheme.textSecondary)
                            .lineLimit(1)
                        }

                        Spacer(minLength: 4)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(BotanicalTheme.textHint)
                    }
                    .padding(14)
                    .background(BotanicalTheme.surface.opacity(0.94))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(BotanicalTheme.primary.opacity(0.16), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: Color.black.opacity(0.04), radius: 10, y: 4)
                }
                .buttonStyle(ScaleBounceButtonStyle(scale: 0.97))

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
        .fullScreenCover(isPresented: $showMindMap) {
            AiMindMapFullScreenView()
        }
        .sheet(isPresented: $showProPaywall) {
            ProPaywallSheet()
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

    @State private var showBreakdown: Bool = false
    @State private var animateRings: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 16) {
                // 左侧莫兰迪双层进度环（外环综合节奏分，内环近7日活跃度；轻点双环或卡片空白处看四维构成）
                ZStack {
                    Circle()
                        .stroke(Color(hex: 0xE2EAE4), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: animateRings ? CGFloat(max(0.03, Double(data.vitalityScore) / 100.0)) : 0)
                        .stroke(
                            LinearGradient(colors: [Color(hex: 0x56A573), Color(hex: 0x2F6E4A)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    Circle()
                        .stroke(Color(hex: 0xF1E8D8), lineWidth: 7)
                        .padding(13)
                    Circle()
                        .trim(from: 0, to: animateRings ? CGFloat(max(0.04, Double(data.activeDays7) / 7.0)) : 0)
                        .stroke(
                            LinearGradient(colors: [Color(hex: 0xE8B95B), Color(hex: 0xD97736)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 7, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .padding(13)

                    VStack(spacing: 1) {
                        Text("\(animateRings ? data.vitalityScore : 0)")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(hex: 0x1B3F2E))
                            .contentTransition(.numericText())
                        HStack(spacing: 2) {
                            Text("节奏分")
                                .font(.system(size: 9.5, weight: .semibold))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 7.5, weight: .bold))
                                .rotationEffect(.degrees(showBreakdown ? 180 : 0))
                        }
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
                        let todayText = data.todayDeltaScore > 0
                            ? "今日 +\(data.todayDeltaScore)"
                            : (data.todayDeltaScore < 0 ? "今日 \(data.todayDeltaScore)" : "今日待起步")
                        let todayPositive = data.todayDeltaScore >= 0
                        miniBadge(
                            text: todayText,
                            tint: todayPositive ? Color(hex: 0x1D4432) : Color(hex: 0xB8531E),
                            bg: todayPositive ? Color(hex: 0xEBF5EE) : Color(hex: 0xFCEAD7)
                        )
                    }

                    Text(data.summaryLine)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(Color(hex: 0x4A6B5A))
                        .lineLimit(2)
                        .lineSpacing(3)
                }
            }

            // 今日分时节奏变化轨迹（08:30 -> 12:00 -> 18:00 -> 此刻，直观呈现未动下滑与行动回升）
            HStack(spacing: 6) {
                Text("今日轨迹")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(Color(hex: 0x5E7A6B))

                ForEach(data.intradayPoints) { pt in
                    HStack(spacing: 3) {
                        Text(pt.label)
                            .font(.system(size: 10, weight: pt.isCurrent ? .bold : .medium))
                            .foregroundColor(pt.isCurrent ? Color(hex: 0x1B3F2E) : Color(hex: 0x6E8578))
                        Text(pt.score.map { "\($0)" } ?? "--")
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundColor(
                                pt.score == nil
                                    ? Color(hex: 0x9BB0A3)
                                    : (pt.isCurrent
                                        ? (data.todayDeltaScore < 0 ? Color(hex: 0xB8531E) : Color(hex: 0x2F6E4A))
                                        : Color(hex: 0x4A6B5A))
                            )
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(pt.isCurrent ? Color(hex: 0xE4F1E8) : Color.white.opacity(0.65))
                    .overlay(
                        Capsule()
                            .stroke(pt.isCurrent ? Color(hex: 0x56A573).opacity(0.45) : Color(hex: 0xDCE6DF), lineWidth: 0.7)
                    )
                    .clipShape(Capsule())
                }
            }

            if showBreakdown {
                VStack(alignment: .leading, spacing: 9) {
                    Divider().opacity(0.45)

                    ForEach(data.rhythmDimensions) { dim in
                        VStack(spacing: 4) {
                            HStack {
                                Text(dim.title)
                                    .font(.system(size: 11.5, weight: .semibold))
                                    .foregroundColor(Color(hex: 0x355745))
                                Spacer()
                                Text("\(dim.score) / \(dim.maxScore)")
                                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                    .foregroundColor(dim.tint)
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.black.opacity(0.06))
                                    Capsule()
                                        .fill(dim.tint)
                                        .frame(width: max(6, geo.size.width * CGFloat(dim.score) / CGFloat(max(1, dim.maxScore))))
                                }
                            }
                            .frame(height: 6)
                        }
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "bolt.heart.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: 0xD97736))
                        Text(data.nextBoostHint)
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(Color(hex: 0x7A4B18))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: 0xFEF3C7).opacity(0.65))
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(18)
        .contentShape(Rectangle())
        .onTapGesture {
            SensoryFeedbackService.shared.lightTap()
            withAnimation(.spring(response: 0.36, dampingFraction: 0.80)) {
                showBreakdown.toggle()
            }
        }
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
        .onAppear {
            withAnimation(.spring(response: 0.78, dampingFraction: 0.86)) {
                animateRings = true
            }
        }
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

    struct RhythmDimension: Identifiable {
        let id: String
        let title: String
        let score: Int
        let maxScore: Int
        let tint: Color
    }

    struct IntradayPoint: Identifiable {
        let id: String
        let label: String
        let score: Int?
        let isCurrent: Bool
    }

    let vitalityScore: Int
    let todayDeltaScore: Int
    let activeDays7: Int
    let wishCompletionRate: Double
    let streakDays: Int
    let phaseTitle: String
    let weekDeltaText: String
    let weekDeltaPositive: Bool
    let summaryLine: String
    let nextBoostHint: String
    let rhythmDimensions: [RhythmDimension]
    let intradayPoints: [IntradayPoint]
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

        // 温和正反馈四维模型 + 日内微降(0~5分) + 多日未用明显衰减（满分 100）
        let todayStartMs = Int64(todayStart.timeIntervalSince1970 * 1000)
        let yesterdayStart = cal.date(byAdding: .day, value: -1, to: todayStart) ?? todayStart
        let yesterdayStartMs = Int64(yesterdayStart.timeIntervalSince1970 * 1000)
        let yesterdaySteps = records.filter { $0.timestamp >= yesterdayStartMs && $0.timestamp < todayStartMs }.count

        // 距离上次点亮微步已经过去了多少天（0=今天刚做，1=昨天刚做，>=2 表示好几天没打开）
        let lastActionDay = records.map { cal.startOfDay(for: Date(timeIntervalSince1970: TimeInterval($0.timestamp) / 1000.0)) }.max()
        let daysSinceLastAction: Int = {
            guard let lastDay = lastActionDay else { return 0 }
            return max(0, cal.dateComponents([.day], from: lastDay, to: todayStart).day ?? 0)
        }()

        // 统一计算指定时刻（今日内）的四维节奏分，既用于此刻实时分，也用于回算早/午/晚分时轨迹
        func evaluateScore(at targetDate: Date) -> (total: Int, todayScore: Int, activeScore: Int, streakScore: Int, wishScore: Int, todaySteps: Int, decay: Int) {
            let targetMs = Int64(targetDate.timeIntervalSince1970 * 1000)
            let stepsUpToT = records.filter { $0.timestamp >= todayStartMs && $0.timestamp <= targetMs }.count
            let checkedHabitsUpToT = activeHabits.filter { habit in
                habit.completionHistory.contains { $0 >= todayStartMs && $0 <= targetMs }
            }.count
            let habitRateUpToT = activeHabits.isEmpty ? 0.0 : Double(checkedHabitsUpToT) / Double(activeHabits.count)

            // 1. 今日行动与余温（25 分：今日启动即得 10+ 分，3步+习惯可拿满；未动时若昨日有行动保留 8 分余温）
            let sToday: Int
            if stepsUpToT > 0 || checkedHabitsUpToT > 0 {
                let stepPart = min(6.0, Double(stepsUpToT) * 2.0)
                let habitPart = habitRateUpToT * 9.0
                sToday = min(25, 10 + Int(round(stepPart + habitPart)))
            } else if yesterdaySteps > 0 {
                sToday = 8
            } else {
                sToday = 0
            }

            // 2. 近 7 日节拍活跃（35 分：单日 >=2 步计 1.0 天，1 步计 0.85 天）
            var activeQualityDays = 0.0
            for offset in 0..<7 {
                let dStart = cal.date(byAdding: .day, value: -offset, to: todayStart) ?? todayStart
                let dEnd = cal.date(byAdding: .day, value: 1, to: dStart) ?? dStart
                let dStartMs = Int64(dStart.timeIntervalSince1970 * 1000)
                let dEndMs = Int64(min(dEnd.timeIntervalSince1970, targetDate.timeIntervalSince1970) * 1000)
                guard dEndMs > dStartMs else { continue }
                let cnt = records.filter { $0.timestamp >= dStartMs && $0.timestamp < dEndMs }.count
                if cnt >= 2 {
                    activeQualityDays += 1.0
                } else if cnt >= 1 {
                    activeQualityDays += 0.85
                }
            }
            let sActive = min(35, Int(round(activeQualityDays / 7.0 * 35.0)))

            // 3. 愿望推进力（20 分：近 7 天完成占 12 分 + 历史完成率沉淀占 8 分）
            let recentCompletedWishes = plans.filter { p in
                guard p.status == .completed, let ct = p.completeTime else { return false }
                return ct >= sevenDaysAgoMs && ct <= targetMs
            }.count
            let recentWishPart = min(12.0, Double(recentCompletedWishes) * 4.0)
            let historyWishPart = wishRate * 8.0
            let sWish = min(20, Int(round(recentWishPart + historyWishPart)))

            // 4. 连续连击惯性（20 分：连续 21 天拿满）
            let effectiveStreak = (stepsUpToT > 0 || streak > 0) ? streak : 0
            let sStreak = min(20, Int(round(sqrt(Double(effectiveStreak) / 21.0) * 20.0)))

            // 5. 衰减机制：日内未动仅温和微降 0~5 分；只有连续 >=2 天没打开才逐步明显下降（每天 -7 分，封顶 35 分）
            let h = Double(cal.component(.hour, from: targetDate))
            let m = Double(cal.component(.minute, from: targetDate))
            let awakeProgress = max(0.0, min(1.0, ((h + m / 60.0) - 8.5) / 14.0))
            let hasActedToday = (stepsUpToT > 0 || checkedHabitsUpToT > 0)
            let todayMildDecay = hasActedToday ? 0 : Int(round(awakeProgress * 5.0))
            let dormantDays = hasActedToday ? 0 : max(0, daysSinceLastAction - 1)
            let dormantDecay = min(35, dormantDays * 7)
            let decay = todayMildDecay + dormantDecay

            let total = max(0, min(100, sToday + sActive + sWish + sStreak - decay))
            return (total, sToday, sActive, sStreak, sWish, stepsUpToT, decay)
        }

        let currentEval = evaluateScore(at: now)
        let morningDate = cal.date(bySettingHour: 8, minute: 30, second: 0, of: todayStart) ?? todayStart
        let morningBaseline = evaluateScore(at: morningDate).total
        let todayDeltaScore = currentEval.total - morningBaseline

        let vitality = currentEval.total
        let activeScore = currentEval.activeScore
        let todayScore = currentEval.todayScore
        let streakScore = currentEval.streakScore
        let wishScore = currentEval.wishScore
        let todaySteps = currentEval.todaySteps

        // 今日 4 个时段分时节奏轨迹（08:30 · 12:00 · 18:00 · 此刻）
        let noonDate = cal.date(bySettingHour: 12, minute: 0, second: 0, of: todayStart) ?? todayStart
        let eveningDate = cal.date(bySettingHour: 18, minute: 0, second: 0, of: todayStart) ?? todayStart
        let intradayPoints: [LocalAnalyticsSnapshot.IntradayPoint] = [
            .init(id: "08", label: "08:30", score: now >= morningDate ? morningBaseline : nil, isCurrent: false),
            .init(id: "12", label: "12:00", score: now >= noonDate ? evaluateScore(at: noonDate).total : nil, isCurrent: false),
            .init(id: "18", label: "18:00", score: now >= eveningDate ? evaluateScore(at: eveningDate).total : nil, isCurrent: false),
            .init(id: "now", label: "此刻", score: vitality, isCurrent: true)
        ]

        let dimensions: [LocalAnalyticsSnapshot.RhythmDimension] = [
            .init(id: "active", title: "7日节拍活跃", score: activeScore, maxScore: 35, tint: Color(hex: 0x2F6E4A)),
            .init(id: "today", title: "今日行动动能", score: todayScore, maxScore: 25, tint: Color(hex: 0x56A573)),
            .init(id: "wish", title: "愿望推进力", score: wishScore, maxScore: 20, tint: Color(hex: 0xD97736)),
            .init(id: "streak", title: "21日连击惯性", score: streakScore, maxScore: 20, tint: Color(hex: 0xE5A93B))
        ]

        let phaseTitle: String
        switch vitality {
        case 85...100: phaseTitle = "心流巅峰态"
        case 70..<85: phaseTitle = "火力全开期"
        case 55..<70: phaseTitle = "顺风滑行期"
        case 38..<55: phaseTitle = "稳步蓄能期"
        case 18..<38: phaseTitle = "破晓起步期"
        default: phaseTitle = "静待微光中"
        }

        let nextBoostHint: String
        if todaySteps == 0 && daysSinceLastAction >= 2 {
            nextBoostHint = "已隔 \(daysSinceLastAction) 天未打卡，今天完成 1 件小事即可快速回升！"
        } else if todaySteps == 0 {
            nextBoostHint = "今天完成 1 件 2 分钟小事，节奏分预计立涨 +\(max(6, 14 - todayScore)) 分"
        } else if vitality >= 85 {
            nextBoostHint = "四维能量饱满，继续享受这种轻盈掌控感吧！"
        } else if todayScore < 20 {
            nextBoostHint = "再完成 1 次微步或打卡习惯，今日分可继续上涨 +\(min(6, 25 - todayScore)) 分"
        } else if wishScore < 14 && !ongoingPlans.isEmpty {
            nextBoostHint = "近 7 日推进或完成 1 个愿望/子步骤，可直接加 +4 分推进力"
        } else {
            nextBoostHint = "保持每日小步节奏，连击惯性与活跃度会稳步推高"
        }

        let summaryLine: String
        if records.isEmpty {
            summaryLine = "完成第一件 2 分钟小事，即可自动点亮 12 周热力图与四维节奏分。"
        } else if todaySteps == 0 && daysSinceLastAction >= 2 {
            summaryLine = "已间隔 \(daysSinceLastAction) 天未记录，节奏分有所回落，点亮 1 步立即唤醒。"
        } else if !mainPlans.isEmpty {
            summaryLine = "近 7 日活跃 \(activeDays7)/7 天，优先攻克「\(mainPlans.first?.name ?? "")」等 \(mainPlans.count) 项焦点。"
        } else {
            summaryLine = "本周累计点亮 \(thisWeekCount) 步微光，活跃 \(activeDays7) 天，状态正稳步升温。"
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
            todayDeltaScore: todayDeltaScore,
            activeDays7: activeDays7,
            wishCompletionRate: wishRate,
            streakDays: streak,
            phaseTitle: phaseTitle,
            weekDeltaText: weekDeltaText,
            weekDeltaPositive: weekDeltaPositive,
            summaryLine: summaryLine,
            nextBoostHint: nextBoostHint,
            rhythmDimensions: dimensions,
            intradayPoints: intradayPoints,
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
