import SwiftUI

/// 全周期 AI 成长洞察与多维可视化图表页（报告状态与缓存由 AppState 托管持久化，切换页面绝不丢失）
struct AnalyticsTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                // 页面大标题
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("成长洞察")
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundColor(BotanicalTheme.textPrimary)
                        Text("图表化看见微步积累与主要矛盾推进")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(BotanicalTheme.textSecondary)
                    }
                    Spacer()
                }
                .padding(.top, 4)

                // 核心 4 指标速览
                HStack(spacing: 10) {
                    statTile(value: "\(appState.todayShineCount)", label: "今日微步", tint: BotanicalTheme.primaryDark)
                    statTile(value: "\(appState.mainContradictionPlans.count)", label: "主要矛盾", tint: Color(hex: 0xD96B27))
                    statTile(value: "\(appState.completedPlans.count)", label: "已达成", tint: BotanicalTheme.primary)
                    statTile(value: "\(appState.activeHabits.count)", label: "微习惯", tint: BotanicalTheme.secondary)
                }

                // 本地即时图表 1：近 7 日微步趋势柱状图
                WeeklyShineChartCard(records: appState.shineRecords)

                // 本地即时图表 2：愿望推进结构环形图
                WishStructureDonutCard(
                    mainCount: appState.mainContradictionPlans.count,
                    normalCount: appState.normalOngoingPlans.count,
                    doneCount: appState.completedPlans.count
                )

                // AI 成长洞察核心区（状态持久化在 AppState，切 Tab / 重启均保留）
                if appState.isAnalyzingOverview {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(BotanicalTheme.primary)
                            .scaleEffect(1.1)
                        Text("AI 正在生成六维雷达与行动建议...")
                            .font(.system(size: 13.5, weight: .medium))
                            .foregroundColor(BotanicalTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 36)
                    .liquidGlassCard(cornerRadius: 24, tint: BotanicalTheme.primaryLight, interactive: false, shadowRadius: 10)
                } else if let err = appState.analyticsErrorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(BotanicalTheme.danger)
                        Text(err)
                            .font(.system(size: 13.5))
                            .foregroundColor(BotanicalTheme.textPrimary)
                            .multilineTextAlignment(.center)
                        Button("重新分析") {
                            SensoryFeedbackService.shared.lightTap()
                            appState.runOverviewAnalysis()
                        }
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 9)
                        .background(BotanicalTheme.primaryGradient)
                        .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .liquidGlassCard(cornerRadius: 24, tint: BotanicalTheme.danger, interactive: false, shadowRadius: 10)
                } else if let report = appState.cachedAnalyticsReport {
                    // 1. 一句话核心诊断 + 刷新按钮
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("AI 核心诊断", systemImage: "sparkles")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(BotanicalTheme.primaryDark)
                            Spacer()
                            if let ts = appState.cachedAnalyticsTimestamp {
                                Text(formatSyncTime(ts))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(BotanicalTheme.textHint)
                            }
                            Button {
                                SensoryFeedbackService.shared.lightTap()
                                appState.runOverviewAnalysis()
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12.5, weight: .semibold))
                                    .foregroundColor(BotanicalTheme.primary)
                                    .frame(width: 28, height: 28)
                                    .background(BotanicalTheme.primary.opacity(0.10))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }

                        Text(report.summary)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(BotanicalTheme.textPrimary.opacity(0.92))
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .liquidGlassCard(cornerRadius: 22, tint: BotanicalTheme.primaryLight, interactive: false, shadowRadius: 10)

                    // 2. 生命六维度雷达图（图形化直觉展示）
                    LifeDimensionsRadarCard(dimensions: report.lifeDimensions)

                    // 3. 微习惯坚持度横向柱状图
                    if !report.habitRank.isEmpty {
                        HabitRankBarChartCard(items: Array(report.habitRank.prefix(5)))
                    }

                    // 4. 精炼诊断要点（亮点 & 卡点）
                    let hasHighlights = !(report.highlights ?? []).isEmpty
                    let hasBottlenecks = !(report.bottlenecks ?? []).isEmpty
                    if hasHighlights || hasBottlenecks {
                        VStack(alignment: .leading, spacing: 12) {
                            if let highlights = report.highlights, !highlights.isEmpty {
                                compactTagSection(
                                    title: "正向趋势",
                                    icon: "checkmark.seal.fill",
                                    tint: BotanicalTheme.primary,
                                    items: highlights
                                )
                            }
                            if hasHighlights && hasBottlenecks {
                                Divider().opacity(0.45)
                            }
                            if let bottlenecks = report.bottlenecks, !bottlenecks.isEmpty {
                                compactTagSection(
                                    title: "当前卡点",
                                    icon: "exclamationmark.circle.fill",
                                    tint: Color(hex: 0xD96B27),
                                    items: bottlenecks
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .liquidGlassCard(cornerRadius: 22, tint: BotanicalTheme.primaryLight, interactive: false, shadowRadius: 10)
                    }

                    // 5. 下周行动清单（3 条极简可执行指令）
                    if let suggestions = report.actionSuggestions, !suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("下周行动建议", systemImage: "arrow.up.right.circle.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(BotanicalTheme.primaryDark)
                            ForEach(Array(suggestions.enumerated()), id: \.offset) { idx, item in
                                HStack(alignment: .center, spacing: 10) {
                                    Text("\(idx + 1)")
                                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                                        .foregroundColor(.white)
                                        .frame(width: 21, height: 21)
                                        .background(BotanicalTheme.primaryGradient)
                                        .clipShape(Circle())
                                    Text(item)
                                        .font(.system(size: 13.5, weight: .medium))
                                        .foregroundColor(BotanicalTheme.textPrimary.opacity(0.92))
                                        .lineSpacing(3)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .liquidGlassCard(cornerRadius: 22, tint: BotanicalTheme.primaryLight, interactive: false, shadowRadius: 10)
                    }
                } else {
                    VStack(spacing: 14) {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(BotanicalTheme.primary)
                                .frame(width: 46, height: 46)
                                .background(BotanicalTheme.primarySoft.opacity(0.8))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 3) {
                                Text("AI 六维雷达与行动建议")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(BotanicalTheme.textPrimary)
                                Text("结合主要矛盾与习惯数据，生成精炼图表诊断")
                                    .font(.system(size: 12.5))
                                    .foregroundColor(BotanicalTheme.textSecondary)
                            }
                            Spacer()
                        }

                        Button {
                            SensoryFeedbackService.shared.lightTap()
                            appState.runOverviewAnalysis()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                Text("生成 AI 诊断图表")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(BotanicalTheme.primaryGradient)
                            .clipShape(Capsule())
                            .shadow(color: BotanicalTheme.primary.opacity(0.24), radius: 10, y: 4)
                        }
                        .buttonStyle(ScaleBounceButtonStyle(scale: 0.97))
                    }
                    .padding(18)
                    .liquidGlassCard(cornerRadius: 24, tint: BotanicalTheme.primaryLight, interactive: false, shadowRadius: 10)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 130)
        }
    }

    private func statTile(value: String, label: String, tint: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 21, weight: .heavy, design: .rounded))
                .foregroundColor(tint)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(BotanicalTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .liquidGlassCard(cornerRadius: 18, tint: tint, interactive: false, shadowRadius: 8)
    }

    private func compactTagSection(title: String, icon: String, tint: Color, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(title, systemImage: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(tint == BotanicalTheme.primary ? BotanicalTheme.primaryDark : tint)
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(tint)
                        .frame(width: 5.5, height: 5.5)
                        .padding(.top, 6)
                    Text(item)
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(BotanicalTheme.textPrimary.opacity(0.9))
                }
            }
        }
    }

    private func formatSyncTime(_ ms: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(ms) / 1000.0)
        let f = DateFormatter()
        f.dateFormat = Calendar.current.isDateInToday(date) ? "HH:mm 更新" : "MM-dd HH:mm"
        return f.string(from: date)
    }
}

// MARK: - 图表 1：近 7 日微步趋势柱状图

private struct WeeklyShineChartCard: View {
    let records: [ShineRecord]

    private struct DayPoint: Identifiable {
        let id: Int
        let label: String
        let count: Int
        let isToday: Bool
    }

    private var points: [DayPoint] {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "zh_CN")

        return (0..<7).map { offset -> DayPoint in
            let dayOffset = offset - 6
            let dayDate = cal.date(byAdding: .day, value: dayOffset, to: todayStart) ?? todayStart
            let nextDate = cal.date(byAdding: .day, value: 1, to: dayDate) ?? dayDate
            let startMs = Int64(dayDate.timeIntervalSince1970 * 1000)
            let endMs = Int64(nextDate.timeIntervalSince1970 * 1000)
            let cnt = records.filter { $0.timestamp >= startMs && $0.timestamp < endMs }.count
            let shortLabel = dayOffset == 0 ? "今天" : formatter.string(from: dayDate).replacingOccurrences(of: "周", with: "")
            return DayPoint(id: offset, label: shortLabel, count: cnt, isToday: dayOffset == 0)
        }
    }

    var body: some View {
        let data = points
        let maxCount = max(data.map(\.count).max() ?? 1, 1)
        let weekTotal = data.reduce(0) { $0 + $1.count }

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("近 7 日微步趋势", systemImage: "chart.bar.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(BotanicalTheme.textPrimary)
                Spacer()
                Text("本周 \(weekTotal) 步")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(BotanicalTheme.primaryDark)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(BotanicalTheme.primarySoft)
                    .clipShape(Capsule())
            }

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(data) { pt in
                    VStack(spacing: 5) {
                        Text("\(pt.count)")
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundColor(pt.isToday ? Color(hex: 0xB8531E) : BotanicalTheme.textSecondary)
                            .opacity(pt.count > 0 || pt.isToday ? 1 : 0.4)

                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(
                                pt.isToday
                                    ? LinearGradient(colors: [Color(hex: 0xF3B65B), Color(hex: 0xE07A38)], startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(colors: [BotanicalTheme.primary, BotanicalTheme.primary.opacity(0.65)], startPoint: .top, endPoint: .bottom)
                            )
                            .frame(height: max(6, CGFloat(pt.count) / CGFloat(maxCount) * 76))
                            .frame(maxWidth: .infinity)

                        Text(pt.label)
                            .font(.system(size: 11, weight: pt.isToday ? .bold : .medium))
                            .foregroundColor(pt.isToday ? BotanicalTheme.textPrimary : BotanicalTheme.textSecondary)
                    }
                }
            }
            .frame(height: 118, alignment: .bottom)
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 22, tint: BotanicalTheme.primaryLight, interactive: false, shadowRadius: 10)
    }
}

// MARK: - 图表 2：愿望推进结构环形图

private struct WishStructureDonutCard: View {
    let mainCount: Int
    let normalCount: Int
    let doneCount: Int

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

            VStack(alignment: .leading, spacing: 8) {
                Text("愿望结构分布")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(BotanicalTheme.textPrimary)

                legendRow(color: Color(hex: 0xE07A38), title: "主要矛盾", value: mainCount)
                legendRow(color: BotanicalTheme.primaryLight, title: "进行中愿望", value: normalCount)
                legendRow(color: BotanicalTheme.primaryDark, title: "已达成愿望", value: doneCount)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 22, tint: BotanicalTheme.primaryLight, interactive: false, shadowRadius: 10)
    }

    private func legendRow(color: Color, title: String, value: Int) -> some View {
        HStack(spacing: 7) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
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

// MARK: - 图表 3：生命六维度雷达图

private struct LifeDimensionsRadarCard: View {
    let dimensions: AiAnalyticsReport.LifeDimensions

    private var entries: [(label: String, score: Int)] {
        [
            ("健康", max(0, min(10, dimensions.health))),
            ("家庭", max(0, min(10, dimensions.family))),
            ("事业", max(0, min(10, dimensions.career))),
            ("学习", max(0, min(10, dimensions.learning))),
            ("休闲", max(0, min(10, dimensions.leisure))),
            ("财富", max(0, min(10, dimensions.wealth)))
        ]
    }

    var body: some View {
        let items = entries
        VStack(alignment: .leading, spacing: 10) {
            Label("生命六维雷达图", systemImage: "hexagon.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(BotanicalTheme.textPrimary)

            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let radius = size * 0.34

                ZStack {
                    // 三层六边形参考网
                    ForEach([0.33, 0.66, 1.0], id: \.self) { ratio in
                        hexagonPath(center: center, radius: radius * ratio)
                            .stroke(BotanicalTheme.primary.opacity(0.15), lineWidth: 1)
                    }

                    // 6 条轴线
                    ForEach(0..<6, id: \.self) { idx in
                        Path { p in
                            p.move(to: center)
                            p.addLine(to: vertexPoint(center: center, radius: radius, index: idx))
                        }
                        .stroke(BotanicalTheme.primary.opacity(0.12), lineWidth: 0.8)
                    }

                    // 数据多边形面积 + 描边
                    let dataPath = radarDataPath(center: center, radius: radius, scores: items.map(\.score))
                    dataPath
                        .fill(
                            RadialGradient(
                                colors: [BotanicalTheme.primary.opacity(0.38), BotanicalTheme.primaryLight.opacity(0.22)],
                                center: .center,
                                startRadius: 5,
                                endRadius: radius
                            )
                        )
                    dataPath
                        .stroke(BotanicalTheme.primaryDark, style: StrokeStyle(lineWidth: 2, lineJoin: .round))

                    // 顶点圆点 + 标签
                    ForEach(0..<6, id: \.self) { idx in
                        let pt = vertexPoint(center: center, radius: radius * CGFloat(items[idx].score) / 10.0, index: idx)
                        Circle()
                            .fill(BotanicalTheme.primaryDark)
                            .frame(width: 6.5, height: 6.5)
                            .position(pt)

                        let labelPt = vertexPoint(center: center, radius: radius + 24, index: idx)
                        Text("\(items[idx].label) \(items[idx].score)")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(BotanicalTheme.textPrimary)
                            .position(labelPt)
                    }
                }
            }
            .frame(height: 226)
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 22, tint: BotanicalTheme.primaryLight, interactive: false, shadowRadius: 10)
    }

    private func vertexPoint(center: CGPoint, radius: CGFloat, index: Int) -> CGPoint {
        let angle = -CGFloat.pi / 2.0 + CGFloat(index) * (.pi / 3.0)
        return CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
    }

    private func hexagonPath(center: CGPoint, radius: CGFloat) -> Path {
        Path { p in
            for idx in 0..<6 {
                let pt = vertexPoint(center: center, radius: radius, index: idx)
                if idx == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()
        }
    }

    private func radarDataPath(center: CGPoint, radius: CGFloat, scores: [Int]) -> Path {
        Path { p in
            for idx in 0..<6 {
                let ratio = CGFloat(max(1, scores[idx])) / 10.0
                let pt = vertexPoint(center: center, radius: radius * ratio, index: idx)
                if idx == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()
        }
    }
}

// MARK: - 图表 4：微习惯坚持度横向柱状图

private struct HabitRankBarChartCard: View {
    let items: [AiAnalyticsReport.HabitRank]

    var body: some View {
        let maxCount = max(items.map(\.count).max() ?? 1, 1)
        VStack(alignment: .leading, spacing: 11) {
            Label("微习惯坚持度排行", systemImage: "flame.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(BotanicalTheme.textPrimary)

            ForEach(Array(items.enumerated()), id: \.element.id) { idx, habit in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
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
        .liquidGlassCard(cornerRadius: 22, tint: BotanicalTheme.warning, interactive: false, shadowRadius: 10)
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
