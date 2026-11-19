import SwiftUI

/// DeepSeek 全周期成长洞察与生命六维度评估视图
struct AnalyticsSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var isLoading: Bool = false
    @State private var report: AiAnalyticsReport? = nil
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 基础数据概览卡
                    HStack(spacing: 12) {
                        statTile(value: "\(appState.todayShineCount)", label: "今日发光")
                        statTile(value: "\(appState.shineRecords.count)", label: "累计星籽")
                        statTile(value: "\(appState.completedPlans.count)", label: "达成计划")
                    }

                    if isLoading {
                        VStack(spacing: 12) {
                            ProgressView().tint(BotanicalTheme.primary)
                            Text("AI 正在分析你的行动轨迹...")
                                .font(.system(size: 13))
                                .foregroundColor(BotanicalTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if let err = errorMessage {
                        VStack(spacing: 10) {
                            Text(err)
                                .font(.system(size: 13))
                                .foregroundColor(BotanicalTheme.danger)
                                .multilineTextAlignment(.center)
                            Button("重新分析") { runAnalysis() }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(BotanicalTheme.primary)
                                .clipShape(Capsule())
                        }
                        .padding(20)
                    } else if let r = report {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("AI 成长洞察")
                                .font(.system(size: 15, weight: .bold))
                            Text(r.summary)
                                .font(.system(size: 14))
                                .foregroundColor(BotanicalTheme.textSecondary)
                                .lineSpacing(4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(BotanicalTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 18))

                        VStack(alignment: .leading, spacing: 10) {
                            Text("生命六维度评估")
                                .font(.system(size: 15, weight: .bold))
                            dimensionBar("健康", score: r.lifeDimensions.health)
                            dimensionBar("家庭", score: r.lifeDimensions.family)
                            dimensionBar("事业", score: r.lifeDimensions.career)
                            dimensionBar("学习", score: r.lifeDimensions.learning)
                            dimensionBar("休闲", score: r.lifeDimensions.leisure)
                            dimensionBar("财富", score: r.lifeDimensions.wealth)
                        }
                        .padding(16)
                        .background(BotanicalTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    } else {
                        Button {
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
                        }
                    }
                }
                .padding(20)
            }
            .background(BotanicalTheme.backgroundTop.ignoresSafeArea())
            .navigationTitle("AI 数据分析")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(BotanicalTheme.primary)
                }
            }
        }
    }

    private func statTile(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(BotanicalTheme.primaryDark)
            Text(label)
                .font(.system(size: 11.5))
                .foregroundColor(BotanicalTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(BotanicalTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(BotanicalTheme.border, lineWidth: 1))
    }

    private func dimensionBar(_ name: String, score: Int) -> some View {
        let clamped = max(0, min(10, score))
        return HStack(spacing: 10) {
            Text(name)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 36, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(BotanicalTheme.surfaceMuted)
                    Capsule()
                        .fill(BotanicalTheme.primary)
                        .frame(width: geo.size.width * CGFloat(clamped) / 10.0)
                }
            }
            .frame(height: 8)
            Text("\(clamped)/10")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(BotanicalTheme.primaryDark)
                .frame(width: 36, alignment: .trailing)
        }
    }

    private func runAnalysis() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let res = try await appState.analyzeOverview()
                await MainActor.run {
                    report = res
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
