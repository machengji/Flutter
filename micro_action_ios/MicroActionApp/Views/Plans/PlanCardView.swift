import SwiftUI

/// 单条计划卡片（支持勾选完成触发庆祝、归属父目标彩色胶囊、展开区行内连续添加子任务 + AI一键拆微步骤 + 快捷操作）
struct PlanCardView: View {
    let plan: PlanItem
    let isExpanded: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDetail: () -> Void
    let onFeedback: (String) -> Void

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var proStore: ProStoreService

    @State private var subDraft: String = ""
    @State private var isAiBreaking: Bool = false

    private var isCompleted: Bool { plan.status == .completed }
    private var parent: PlanItem? { appState.parentPlan(of: plan) }
    private var subProgress: (completed: Int, total: Int) { appState.subProgress(of: plan.id) }
    private var directSubs: [PlanItem] { appState.directSubPlans(of: plan.id) }
    private var groupColor: Color { BotanicalTheme.groupColor(for: plan.groupColorIndex) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 主体行
            HStack(alignment: .center, spacing: 12) {
                Button {
                    SensoryFeedbackService.shared.lightTap()
                    Task {
                        await appState.togglePlanStatus(id: plan.id, isPro: proStore.isPro)
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isCompleted ? BotanicalTheme.primary : BotanicalTheme.surfaceMuted)
                            .frame(width: 36, height: 36)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isCompleted ? BotanicalTheme.primary : BotanicalTheme.border, lineWidth: 1.2)
                            )
                        Image(systemName: isCompleted ? "checkmark" : "leaf")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(isCompleted ? .white : BotanicalTheme.primary)
                    }
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if plan.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 10))
                                .foregroundColor(BotanicalTheme.accentWarm)
                        }
                        Text(plan.name)
                            .font(.system(size: 15.5, weight: .semibold))
                            .foregroundColor(isCompleted ? BotanicalTheme.textHint : BotanicalTheme.textPrimary)
                            .strikethrough(isCompleted, color: BotanicalTheme.textHint)
                            .lineLimit(2)
                    }

                    HStack(spacing: 6) {
                        if let parent {
                            Text(parent.name)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(groupColor)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(groupColor.opacity(0.12))
                                .clipShape(Capsule())
                                .lineLimit(1)
                        }
                        if subProgress.total > 0 {
                            Text("子步骤 \(subProgress.completed)/\(subProgress.total)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(BotanicalTheme.textSecondary)
                        }
                        if plan.reminderIdentifier != nil {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 10))
                                .foregroundColor(BotanicalTheme.secondary)
                        }
                    }
                }

                Spacer()

                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(BotanicalTheme.textHint)
            }
            .padding(14)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)

            // 展开区：子任务列表 + 行内添加/AI拆微步骤 + 底部操作按钮
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Divider().background(BotanicalTheme.border.opacity(0.6))

                    if !directSubs.isEmpty {
                        VStack(spacing: 6) {
                            ForEach(directSubs) { sub in
                                HStack(spacing: 8) {
                                    Button {
                                        Task {
                                            await appState.togglePlanStatus(id: sub.id, isPro: proStore.isPro)
                                        }
                                    } label: {
                                        Image(systemName: sub.status == .completed ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 16))
                                            .foregroundColor(sub.status == .completed ? BotanicalTheme.primary : BotanicalTheme.textHint)
                                    }
                                    .buttonStyle(.plain)

                                    Text(sub.name)
                                        .font(.system(size: 13.5))
                                        .foregroundColor(sub.status == .completed ? BotanicalTheme.textHint : BotanicalTheme.textPrimary)
                                        .strikethrough(sub.status == .completed)
                                        .lineLimit(1)

                                    Spacer()

                                    Button {
                                        appState.deletePlan(id: sub.id)
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 11))
                                            .foregroundColor(BotanicalTheme.textHint)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 3)
                            }
                        }
                    }

                    // 行内添加子任务 + AI 一键拆微步骤按钮
                    if !isCompleted {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(BotanicalTheme.primary)

                            TextField("添加微步骤子任务", text: $subDraft)
                                .font(.system(size: 13.5))
                                .submitLabel(.done)
                                .onSubmit { submitSubDraft() }

                            if !subDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Button {
                                    submitSubDraft()
                                } label: {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(BotanicalTheme.primary)
                                }
                            } else {
                                Button {
                                    triggerAiBreakdown()
                                } label: {
                                    HStack(spacing: 4) {
                                        if isAiBreaking {
                                            ProgressView().scaleEffect(0.65)
                                        } else {
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 11, weight: .bold))
                                        }
                                        Text(isAiBreaking ? "拆解中..." : "AI拆微步骤")
                                            .font(.system(size: 11, weight: .bold))
                                    }
                                    .foregroundColor(BotanicalTheme.primaryDark)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 5)
                                    .background(BotanicalTheme.primarySoft.opacity(0.85))
                                    .clipShape(Capsule())
                                }
                                .disabled(isAiBreaking)
                            }
                        }
                        .padding(.horizontal, 10)
                        .frame(height: 38)
                        .background(BotanicalTheme.surfaceMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 11).stroke(BotanicalTheme.border, lineWidth: 1))
                    }

                    // 快捷操作栏
                    HStack {
                        quickAction(icon: "sparkles.rectangle.stack", label: "剖析", color: BotanicalTheme.primary, action: onDetail)
                        if !isCompleted {
                            quickAction(icon: "bell.badge", label: "提醒", color: BotanicalTheme.secondary) {
                                if !proStore.isPro {
                                    appState.showProPaywall = true
                                } else {
                                    Task {
                                        let ok = await appState.pushPlanToAppleReminders(planId: plan.id)
                                        onFeedback(ok ? "已加入 iOS 提醒事项「微行动」列表" : "请先允许系统提醒事项权限")
                                    }
                                }
                            }
                        }
                        quickAction(icon: plan.isPinned ? "pin.slash" : "pin", label: plan.isPinned ? "取消置顶" : "置顶", color: BotanicalTheme.accentWarm) {
                            appState.togglePinPlan(id: plan.id)
                        }
                        quickAction(icon: "pencil", label: "编辑", color: BotanicalTheme.textSecondary, action: onEdit)
                        quickAction(icon: "archivebox", label: "归档", color: BotanicalTheme.textSecondary) {
                            appState.archivePlan(id: plan.id)
                        }
                        quickAction(icon: "trash", label: "删除", color: BotanicalTheme.danger) {
                            appState.deletePlan(id: plan.id)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .background(BotanicalTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isExpanded ? BotanicalTheme.primary.opacity(0.35) : BotanicalTheme.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 8, y: 3)
    }

    private func quickAction(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            SensoryFeedbackService.shared.selection()
            action()
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private func submitSubDraft() {
        let trimmed = subDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        SensoryFeedbackService.shared.selection()
        appState.addSubPlan(parentId: plan.id, name: trimmed)
        subDraft = ""
    }

    private func triggerAiBreakdown() {
        if !proStore.isPro {
            appState.showProPaywall = true
            return
        }
        isAiBreaking = true
        Task {
            do {
                let created = try await appState.aiBreakdownPlan(parentId: plan.id)
                await MainActor.run {
                    isAiBreaking = false
                    onFeedback("AI 已拆解出 \(created.count) 个微步骤并置顶到首页")
                }
            } catch {
                await MainActor.run {
                    isAiBreaking = false
                    onFeedback("AI 拆解失败：\(error.localizedDescription)")
                }
            }
        }
    }
}
