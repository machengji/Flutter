import SwiftUI

/// 计划列表视图（进行中计划自动按子任务叶节点前置提升 + 已完成折叠列表）
struct PlanListView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var proStore: ProStoreService

    @State private var expandedPlanId: String? = nil
    @State private var showCompleted: Bool = false
    @State private var editingPlan: PlanItem? = nil
    @State private var detailPlan: PlanItem? = nil
    @State private var toastText: String? = nil

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if let toast = toastText {
                    Text(toast)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(BotanicalTheme.primaryDark)
                        .clipShape(Capsule())
                }

                if appState.ongoingPlans.isEmpty {
                    emptyStateCard
                } else {
                    ForEach(appState.ongoingPlans) { plan in
                        PlanCardView(
                            plan: plan,
                            isExpanded: expandedPlanId == plan.id,
                            onTap: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                    expandedPlanId = expandedPlanId == plan.id ? nil : plan.id
                                }
                            },
                            onEdit: { editingPlan = plan },
                            onDetail: { detailPlan = plan },
                            onFeedback: { msg in showToast(msg) }
                        )
                    }
                }

                if !appState.completedPlans.isEmpty {
                    VStack(spacing: 10) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.22)) {
                                showCompleted.toggle()
                            }
                        } label: {
                            HStack {
                                Text("已完成 (\(appState.completedPlans.count))")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(BotanicalTheme.textSecondary)
                                Spacer()
                                Image(systemName: showCompleted ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(BotanicalTheme.textHint)
                            }
                            .padding(.horizontal, 6)
                            .padding(.top, 10)
                        }

                        if showCompleted {
                            ForEach(appState.completedPlans) { plan in
                                PlanCardView(
                                    plan: plan,
                                    isExpanded: expandedPlanId == plan.id,
                                    onTap: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                            expandedPlanId = expandedPlanId == plan.id ? nil : plan.id
                                        }
                                    },
                                    onEdit: { editingPlan = plan },
                                    onDetail: { detailPlan = plan },
                                    onFeedback: { msg in showToast(msg) }
                                )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
        .sheet(item: $editingPlan) { plan in
            AddPlanSheet(editingPlan: plan)
        }
        .sheet(item: $detailPlan) { plan in
            PlanDetailSheet(plan: plan)
        }
    }

    private var emptyStateCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 32))
                .foregroundColor(BotanicalTheme.secondary)
            Text("还没有进行中的微行动计划")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(BotanicalTheme.textPrimary)
            Text("点击右下角 + 添加一个 2 分钟就能动手的小目标")
                .font(.system(size: 13))
                .foregroundColor(BotanicalTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .background(BotanicalTheme.surface.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(BotanicalTheme.border, lineWidth: 1))
    }

    private func showToast(_ msg: String) {
        toastText = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            if toastText == msg { toastText = nil }
        }
    }
}
