import SwiftUI

/// 单任务 DeepSeek AI 深度剖析视图（难度评估、阻力卡点、微步骤一键添加、推荐时间锚点）
struct PlanDetailSheet: View {
    let plan: PlanItem

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var proStore: ProStoreService
    @Environment(\.dismiss) private var dismiss

    @State private var isLoading: Bool = false
    @State private var diagnosis: SinglePlanDiagnosis? = nil
    @State private var errorMessage: String? = nil
    @State private var addedSteps: Set<String> = []
    @State private var showApiConfigAlert: Bool = false
    @State private var showSettingsSheet: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("目标事项")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(BotanicalTheme.textSecondary)
                        Text(plan.name)
                            .font(.system(size: 19, weight: .heavy))
                            .foregroundColor(BotanicalTheme.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(BotanicalTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    if isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(BotanicalTheme.primary)
                            Text("AI 行动教练正在拆解阻力...")
                                .font(.system(size: 13))
                                .foregroundColor(BotanicalTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if let err = errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(BotanicalTheme.danger)
                            Text(err)
                                .font(.system(size: 13))
                                .foregroundColor(BotanicalTheme.textSecondary)
                                .multilineTextAlignment(.center)
                            Button("重新剖析") { loadDiagnosis() }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(BotanicalTheme.primary)
                                .clipShape(Capsule())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    } else if let d = diagnosis {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("启动阻力评估")
                                    .font(.system(size: 14, weight: .bold))
                                Spacer()
                                Text("\(d.difficultyScore) / 10")
                                    .font(.system(size: 15, weight: .heavy))
                                    .foregroundColor(BotanicalTheme.accentWarm)
                            }
                            Text(d.difficultyReason)
                                .font(.system(size: 13.5))
                                .foregroundColor(BotanicalTheme.textSecondary)

                            Divider()

                            Text("可能卡点：\(d.likelyBlocker)")
                                .font(.system(size: 13.5, weight: .medium))
                                .foregroundColor(BotanicalTheme.textPrimary)

                            Text("推荐绑定锚点：\(d.suggestedAnchor)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(BotanicalTheme.primaryDark)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(BotanicalTheme.primarySoft.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(16)
                        .background(BotanicalTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                        VStack(alignment: .leading, spacing: 10) {
                            Text("推荐 2 分钟微步骤（点击添加为子任务）")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(BotanicalTheme.textPrimary)

                            ForEach(d.microSteps, id: \.self) { step in
                                let added = addedSteps.contains(step)
                                HStack {
                                    Text(step)
                                        .font(.system(size: 14))
                                        .foregroundColor(BotanicalTheme.textPrimary)
                                    Spacer()
                                    Button {
                                        guard !added else { return }
                                        appState.addSubPlan(parentId: plan.id, name: step)
                                        addedSteps.insert(step)
                                        SensoryFeedbackService.shared.lightTap()
                                    } label: {
                                        Text(added ? "已添加" : "+ 添加")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(added ? BotanicalTheme.textHint : .white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(added ? BotanicalTheme.surfaceMuted : BotanicalTheme.primary)
                                            .clipShape(Capsule())
                                    }
                                    .disabled(added)
                                }
                                .padding(12)
                                .background(BotanicalTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(BotanicalTheme.backgroundTop.ignoresSafeArea())
            .navigationTitle("AI 深度剖析")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(BotanicalTheme.primary)
                }
            }
            .onAppear { loadDiagnosis() }
            .alert("尚未配置 AI 接口", isPresented: $showApiConfigAlert) {
                Button("去配置 API") {
                    showSettingsSheet = true
                }
                Button("稍后再说", role: .cancel) {}
            } message: {
                Text("AI 深度剖析需要配置个人 API Key，请前往「设置 → 自定义 AI 接口」填写后再使用。")
            }
            .sheet(isPresented: $showSettingsSheet) {
                SettingsSheet()
                    .liquidGlassSheet(detents: [.large], cornerRadius: 34)
            }
        }
    }

    private func loadDiagnosis() {
        guard appState.isAiApiConfigured else {
            isLoading = false
            errorMessage = "尚未配置 AI 接口，请前往「设置 → 自定义 AI 接口」填入 API Key"
            showApiConfigAlert = true
            return
        }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let res = try await appState.analyzeSinglePlan(planId: plan.id)
                await MainActor.run {
                    diagnosis = res
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
