import SwiftUI

/// 全周期 AI 成长洞察与生命六维度评估（原生嵌入主界面第 4 Tab，零弹窗压迫感）
struct AnalyticsTabView: View {
    @EnvironmentObject private var appState: AppState

    @State private var isLoading: Bool = false
    @State private var report: AiAnalyticsReport? = nil
    @State private var errorMessage: String? = nil

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // 页面大标题
                VStack(alignment: .leading, spacing: 4) {
                    Text("成长洞察")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundColor(BotanicalTheme.textPrimary)
                    Text("看见每一次微步积累的长期复利")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(BotanicalTheme.textSecondary)
                }
                .padding(.top, 4)

                // 基础数据概览卡（液态玻璃三联卡）
                HStack(spacing: 12) {
                    statTile(value: "\(appState.todayShineCount)", label: "今日微步")
                    statTile(value: "\(appState.shineRecords.count)", label: "累计成长")
                    statTile(value: "\(appState.completedPlans.count)", label: "达成计划")
                }

                // AI 成长洞察核心区
                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(BotanicalTheme.primary)
                            .scaleEffect(1.1)
                        Text("AI 正在梳理你的微步行动轨迹...")
                            .font(.system(size: 13.5, weight: .medium))
                            .foregroundColor(BotanicalTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 44)
                    .liquidGlassCard(cornerRadius: 24, tint: BotanicalTheme.primaryLight, interactive: false, shadowRadius: 12)
                } else if let err = errorMessage {
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
                            runAnalysis()
                        }
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 9)
                        .background(BotanicalTheme.primaryGradient)
                        .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(22)
                    .liquidGlassCard(cornerRadius: 24, tint: BotanicalTheme.danger, interactive: false, shadowRadius: 10)
                } else if let r = report {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("AI 成长洞察", systemImage: "sparkles")
                                .font(.system(size: 15.5, weight: .bold))
                                .foregroundColor(BotanicalTheme.primaryDark)
                            Spacer()
                            Button {
                                SensoryFeedbackService.shared.lightTap()
                                runAnalysis()
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(BotanicalTheme.primary)
                                    .frame(width: 30, height: 30)
                                    .background(BotanicalTheme.primary.opacity(0.10))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }

                        Text(r.summary)
                            .font(.system(size: 14.5))
                            .foregroundColor(BotanicalTheme.textPrimary.opacity(0.88))
                            .lineSpacing(5)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .liquidGlassCard(cornerRadius: 24, tint: BotanicalTheme.primaryLight, interactive: false, shadowRadius: 12)

                    if let highlights = r.highlights, !highlights.isEmpty {
                        insightListCard(
                            title: "核心亮点与正向趋势",
                            icon: "checkmark.seal.fill",
                            tint: BotanicalTheme.primary,
                            items: highlights
                        )
                    }

                    if let bottlenecks = r.bottlenecks, !bottlenecks.isEmpty {
                        insightListCard(
                            title: "瓶颈与潜在失衡点",
                            icon: "exclamationmark.circle.fill",
                            tint: BotanicalTheme.warning,
                            items: bottlenecks
                        )
                    }

                    if let suggestions = r.actionSuggestions, !suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 11) {
                            Label("下周可执行微行动建议", systemImage: "arrow.up.right.circle.fill")
                                .font(.system(size: 15.5, weight: .bold))
                                .foregroundColor(BotanicalTheme.primaryDark)
                            ForEach(Array(suggestions.enumerated()), id: \.offset) { idx, item in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("\(idx + 1)")
                                        .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                                        .foregroundColor(.white)
                                        .frame(width: 22, height: 22)
                                        .background(BotanicalTheme.primaryGradient)
                                        .clipShape(Circle())
                                    Text(item)
                                        .font(.system(size: 13.5))
                                        .foregroundColor(BotanicalTheme.textPrimary.opacity(0.9))
                                        .lineSpacing(4)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .liquidGlassCard(cornerRadius: 24, tint: BotanicalTheme.primaryLight, interactive: false, shadowRadius: 12)
                    }

                    if !r.habitRank.isEmpty {
                        VStack(alignment: .leading, spacing: 11) {
                            Label("微习惯坚持度排行", systemImage: "flame.fill")
                                .font(.system(size: 15.5, weight: .bold))
                                .foregroundColor(BotanicalTheme.textPrimary)
                            ForEach(Array(r.habitRank.prefix(5).enumerated()), id: \.element.id) { idx, habit in
                                HStack {
                                    Text("TOP \(idx + 1)")
                                        .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                                        .foregroundColor(idx == 0 ? BotanicalTheme.warning : BotanicalTheme.primaryDark)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background((idx == 0 ? BotanicalTheme.warning : BotanicalTheme.primary).opacity(0.14))
                                        .clipShape(Capsule())
                                    Text(habit.name)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(BotanicalTheme.textPrimary)
                                    Spacer()
                                    Text("\(habit.count) 次")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(BotanicalTheme.primaryDark)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .liquidGlassCard(cornerRadius: 24, tint: BotanicalTheme.warning, interactive: false, shadowRadius: 12)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("生命六维度评估")
                            .font(.system(size: 15.5, weight: .bold))
                            .foregroundColor(BotanicalTheme.textPrimary)
                        dimensionBar("健康", score: r.lifeDimensions.health)
                        dimensionBar("家庭", score: r.lifeDimensions.family)
                        dimensionBar("事业", score: r.lifeDimensions.career)
                        dimensionBar("学习", score: r.lifeDimensions.learning)
                        dimensionBar("休闲", score: r.lifeDimensions.leisure)
                        dimensionBar("财富", score: r.lifeDimensions.wealth)
                    }
                    .padding(18)
                    .liquidGlassCard(cornerRadius: 24, tint: BotanicalTheme.primaryLight, interactive: false, shadowRadius: 12)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(BotanicalTheme.primary)
                            .frame(width: 58, height: 58)
                            .background(BotanicalTheme.primarySoft.opacity(0.8))
                            .clipShape(Circle())

                        VStack(spacing: 6) {
                            Text("一键生成 AI 成长洞察")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(BotanicalTheme.textPrimary)
                            Text("结合你的计划、微习惯与成长树足迹，生成专属总结与生命六维度平衡建议")
                                .font(.system(size: 13))
                                .foregroundColor(BotanicalTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                        }

                        Button {
                            SensoryFeedbackService.shared.lightTap()
                            runAnalysis()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                Text("生成 AI 成长洞察报告")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(BotanicalTheme.primaryGradient)
                            .clipShape(Capsule())
                            .shadow(color: BotanicalTheme.primary.opacity(0.26), radius: 12, y: 5)
                        }
                        .buttonStyle(ScaleBounceButtonStyle(scale: 0.97))
                    }
                    .padding(22)
                    .liquidGlassCard(cornerRadius: 26, tint: BotanicalTheme.primaryLight, interactive: false, shadowRadius: 12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 130)
        }
    }

    private func statTile(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 23, weight: .heavy, design: .rounded))
                .foregroundColor(BotanicalTheme.primaryDark)
            Text(label)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundColor(BotanicalTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .liquidGlassCard(cornerRadius: 20, tint: BotanicalTheme.primaryLight, interactive: false, shadowRadius: 10)
    }

    private func dimensionBar(_ name: String, score: Int) -> some View {
        let clamped = max(0, min(10, score))
        return HStack(spacing: 10) {
            Text(name)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundColor(BotanicalTheme.textPrimary)
                .frame(width: 36, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(BotanicalTheme.primary.opacity(0.10))
                    Capsule()
                        .fill(BotanicalTheme.primaryGradient)
                        .frame(width: geo.size.width * CGFloat(clamped) / 10.0)
                }
            }
            .frame(height: 8.5)
            Text("\(clamped)/10")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(BotanicalTheme.primaryDark)
                .frame(width: 38, alignment: .trailing)
        }
    }

    private func insightListCard(title: String, icon: String, tint: Color, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Label(title, systemImage: icon)
                .font(.system(size: 15.5, weight: .bold))
                .foregroundColor(tint == BotanicalTheme.primary ? BotanicalTheme.primaryDark : tint)
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 9) {
                    Circle()
                        .fill(tint)
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    Text(item)
                        .font(.system(size: 13.5))
                        .foregroundColor(BotanicalTheme.textPrimary.opacity(0.9))
                        .lineSpacing(4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .liquidGlassCard(cornerRadius: 24, tint: tint, interactive: false, shadowRadius: 12)
    }

    private func runAnalysis() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let res = try await appState.analyzeOverview()
                await MainActor.run {
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
                        report = res
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.22)) {
                        errorMessage = error.localizedDescription
                        isLoading = false
                    }
                }
            }
        }
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
