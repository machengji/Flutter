import SwiftUI

/// 单条计划卡片（完整复刻原版 PlanCard 森系新芽视觉与内嵌浅苔绿操作托盘）
struct PlanCardView: View {
    let plan: PlanItem
    let isExpanded: Bool
    let onTap: () -> Void
    let onTapSubPlan: (String) -> Void
    let onEdit: () -> Void
    let onDetail: () -> Void
    let onRequestReminder: () -> Void
    let onFeedback: (String) -> Void

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var proStore: ProStoreService

    @State private var subDraft: String = ""
    @State private var isAiBreaking: Bool = false
    @State private var aiSuggestions: [String] = []
    @State private var selectedSuggestionIndices: Set<Int> = []
    @State private var showDeleteConfirm: Bool = false

    private var isCompleted: Bool { plan.status == .completed }
    private var isArchived: Bool { plan.status == .archived }
    private var parent: PlanItem? { appState.parentPlan(of: plan) }
    private var subProgress: (completed: Int, total: Int) { appState.subProgress(of: plan.id) }
    private var directSubs: [PlanItem] { appState.directSubPlans(of: plan.id) }
    private var hasSubProgress: Bool { subProgress.total > 0 }
    private var allSubsDone: Bool { hasSubProgress && subProgress.completed >= subProgress.total }
    private var hasDraft: Bool { !subDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 主体行
            HStack(alignment: .center, spacing: 12) {
                // 44x44 森系新芽打卡框
                Button {
                    SensoryFeedbackService.shared.lightTap()
                    Task {
                        await appState.togglePlanStatus(id: plan.id, isPro: proStore.isPro)
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(checkBoxFill)
                            .frame(width: 44, height: 44)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(checkBoxBorder, lineWidth: 1.6)
                            )

                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 19, weight: .bold))
                                .foregroundColor(.white)
                        } else if isArchived {
                            Image(systemName: "archivebox")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(BotanicalTheme.textHint)
                        } else {
                            Image(systemName: "sparkle")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(BotanicalTheme.primary.opacity(0.45))
                        }
                    }
                }
                .buttonStyle(ScaleBounceButtonStyle(scale: 0.90))

                // 标题与元信息
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .center, spacing: 6) {
                        if plan.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(BotanicalTheme.accentWarm)
                        }

                        Text(plan.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isCompleted || isArchived ? BotanicalTheme.textSecondary : BotanicalTheme.textPrimary)
                            .strikethrough(isCompleted, color: BotanicalTheme.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: 4)

                        if hasSubProgress {
                            Text("\(subProgress.completed)/\(subProgress.total)")
                                .font(.system(size: 10.5, weight: .semibold))
                                .foregroundColor(allSubsDone ? BotanicalTheme.primaryDark : BotanicalTheme.textSecondary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2.5)
                                .background(allSubsDone ? BotanicalTheme.primary.opacity(0.14) : BotanicalTheme.surfaceMuted)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(
                                            allSubsDone
                                                ? BotanicalTheme.primary.opacity(0.30)
                                                : BotanicalTheme.textHint.opacity(0.22),
                                            lineWidth: 0.8
                                        )
                                )
                        }
                    }

                    // 相对日期 + 多级拆解彩色圆点链 + 父目标标签
                    HStack(spacing: 6) {
                        Text(
                            isCompleted
                                ? "完成于 \(BotanicalTheme.formatRelativeDate(epochMs: plan.completeTime ?? 0))"
                                : BotanicalTheme.formatRelativeDate(epochMs: plan.createTime)
                        )
                        .font(.system(size: 13))
                        .foregroundColor(BotanicalTheme.textSecondary)

                        if plan.groupColorIndex >= 0 && plan.decompositionLevel > 0 {
                            let dotCount = min(max(plan.decompositionLevel, 1), 5)
                            let baseColor = BotanicalTheme.groupColor(for: plan.groupColorIndex)
                            HStack(spacing: 4) {
                                ForEach(0..<dotCount, id: \.self) { idx in
                                    Circle()
                                        .fill(baseColor.opacity(max(0.35, 0.88 - Double(idx) * 0.1)))
                                        .frame(width: 6.5, height: 6.5)
                                }
                            }
                            .padding(.leading, 2)
                        }

                        if let parent {
                            Text(parent.name)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(BotanicalTheme.primaryDark.opacity(0.88))
                                .lineLimit(1)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1.5)
                                .background(BotanicalTheme.primary.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }

                        if plan.reminderIdentifier != nil {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 10.5))
                                .foregroundColor(BotanicalTheme.secondary)
                        }
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(BotanicalTheme.textHint)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .animation(.easeOut(duration: 0.2), value: isExpanded)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)

            // 无框一体式扩展区（轻柔发丝线分隔，融入同一张液态玻璃卡片，告别隔离边框）
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Rectangle()
                        .fill(BotanicalTheme.primary.opacity(0.08))
                        .frame(height: 0.6)

                    // 直接子任务列表
                    if !directSubs.isEmpty {
                        VStack(spacing: 5) {
                            ForEach(directSubs) { sub in
                                subPlanRow(sub)
                            }
                        }
                    }

                    // 行内添加子任务 + AI 一键拆微步骤
                    if !isCompleted {
                        inlineSubPlanInput
                    }

                    // AI 拆解结果预览与自由勾选确认区
                    if !aiSuggestions.isEmpty {
                        aiSuggestionPickerSection
                    }

                    // 自适应等宽快捷操作按钮栏
                    HStack(spacing: 6) {
                        squareActionButton(
                            icon: "sparkles.rectangle.stack",
                            color: BotanicalTheme.primary
                        ) {
                            onDetail()
                        }
                        if !isCompleted {
                            squareActionButton(
                                icon: "bell.badge",
                                color: BotanicalTheme.secondary
                            ) {
                                onRequestReminder()
                            }
                        }
                        squareActionButton(
                            icon: "pencil",
                            color: BotanicalTheme.textSecondary
                        ) {
                            onEdit()
                        }
                        squareActionButton(
                            icon: plan.isPinned ? "pin.slash" : "pin",
                            color: BotanicalTheme.accentWarm,
                            isHighlighted: plan.isPinned
                        ) {
                            appState.togglePinPlan(id: plan.id)
                        }
                        squareActionButton(
                            icon: "archivebox",
                            color: isArchived ? BotanicalTheme.primary : BotanicalTheme.textSecondary,
                            isHighlighted: isArchived
                        ) {
                            if isArchived {
                                appState.restoreArchivedPlan(id: plan.id)
                            } else {
                                appState.archivePlan(id: plan.id)
                            }
                        }
                        squareActionButton(
                            icon: isCompleted ? "arrow.counterclockwise" : "checkmark",
                            color: BotanicalTheme.primaryDark
                        ) {
                            Task {
                                await appState.togglePlanStatus(id: plan.id, isPro: proStore.isPro)
                            }
                        }
                        squareActionButton(
                            icon: "trash",
                            color: BotanicalTheme.danger,
                            isDanger: true
                        ) {
                            showDeleteConfirm = true
                        }
                    }
                    .padding(.top, 2)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }
        }
        .clipped()
        .liquidGlassCard(
            cornerRadius: 19,
            tint: BotanicalTheme.primaryLight,
            interactive: false,
            shadowRadius: 10
        )
        .alert("确认删除计划？", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                appState.deletePlan(id: plan.id)
            }
        } message: {
            Text(hasSubProgress
                 ? "删除「\(plan.name)」将同时移除其关联的 \(subProgress.total) 个子步骤，此操作不可撤销。"
                 : "确定要删除「\(plan.name)」吗？此操作不可撤销。")
        }
    }

    private var checkBoxFill: AnyShapeStyle {
        if isCompleted {
            return AnyShapeStyle(BotanicalTheme.primaryGradient)
        } else if isArchived {
            return AnyShapeStyle(BotanicalTheme.surfaceMuted)
        } else {
            return AnyShapeStyle(BotanicalTheme.primary.opacity(0.05))
        }
    }

    private var checkBoxBorder: Color {
        if isCompleted { return BotanicalTheme.primary }
        if isArchived { return BotanicalTheme.textSecondary.opacity(0.25) }
        return BotanicalTheme.primary.opacity(0.24)
    }

    private func subPlanRow(_ sub: PlanItem) -> some View {
        let subDone = sub.status == .completed
        return HStack(spacing: 9) {
            Button {
                SensoryFeedbackService.shared.lightTap()
                Task {
                    await appState.togglePlanStatus(id: sub.id, isPro: proStore.isPro)
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(subDone ? AnyShapeStyle(BotanicalTheme.primaryGradient) : AnyShapeStyle(BotanicalTheme.primary.opacity(0.05)))
                        .frame(width: 20, height: 20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(subDone ? BotanicalTheme.primary : BotanicalTheme.primary.opacity(0.32), lineWidth: 1.3)
                        )
                    if subDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            Text(sub.name)
                .font(.system(size: 13.5))
                .foregroundColor(subDone ? BotanicalTheme.textHint : BotanicalTheme.textPrimary)
                .strikethrough(subDone, color: BotanicalTheme.textHint)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    SensoryFeedbackService.shared.selection()
                    onTapSubPlan(sub.id)
                }

            Button {
                SensoryFeedbackService.shared.lightTap()
                appState.deletePlan(id: sub.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(BotanicalTheme.textHint)
                    .padding(4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(BotanicalTheme.primary.opacity(0.10), lineWidth: 0.8)
        )
    }

    private var inlineSubPlanInput: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(BotanicalTheme.primary.opacity(0.78))

            TextField("添加子任务", text: $subDraft)
                .font(.system(size: 13.5))
                .foregroundColor(BotanicalTheme.textPrimary)
                .submitLabel(.done)
                .onSubmit { submitSubDraft() }

            if hasDraft {
                Button {
                    submitSubDraft()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(BotanicalTheme.primary)
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleBounceButtonStyle(scale: 0.90))
            } else {
                Button {
                    triggerAiBreakdown()
                } label: {
                    HStack(spacing: 4) {
                        if isAiBreaking {
                            ProgressView()
                                .tint(BotanicalTheme.primary)
                                .scaleEffect(0.65)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(BotanicalTheme.primary)
                        }
                        Text(isAiBreaking ? "拆解中..." : "AI拆微步骤")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(BotanicalTheme.primaryDark)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(BotanicalTheme.primary.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(ScaleBounceButtonStyle(scale: 0.94))
                .disabled(isAiBreaking)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 38)
        .background(Color.white.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(BotanicalTheme.primary.opacity(0.18), lineWidth: 0.9)
        )
    }

    private func squareActionButton(
        icon: String,
        color: Color,
        isDanger: Bool = false,
        isHighlighted: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        let effectiveColor = isDanger ? BotanicalTheme.danger : color
        return Button {
            SensoryFeedbackService.shared.selection()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(effectiveColor)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    isHighlighted
                        ? effectiveColor.opacity(0.14)
                        : (isDanger ? effectiveColor.opacity(0.08) : Color.white.opacity(0.76))
                )
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(effectiveColor.opacity(isHighlighted ? 0.25 : 0.12), lineWidth: 0.9)
                )
        }
        .buttonStyle(ScaleBounceButtonStyle(scale: 0.90))
    }

    private func submitSubDraft() {
        let trimmed = subDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        SensoryFeedbackService.shared.selection()
        appState.addSubPlan(parentId: plan.id, name: trimmed)
        subDraft = ""
    }

    private var aiSuggestionPickerSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("选择要添加的微步骤")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(BotanicalTheme.primaryDark)
                Spacer()
                Button("取消") {
                    SensoryFeedbackService.shared.selection()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                        aiSuggestions = []
                        selectedSuggestionIndices = []
                    }
                }
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundColor(BotanicalTheme.textSecondary)
            }

            ForEach(Array(aiSuggestions.enumerated()), id: \.offset) { idx, step in
                let isSelected = selectedSuggestionIndices.contains(idx)
                Button {
                    SensoryFeedbackService.shared.selection()
                    if isSelected {
                        selectedSuggestionIndices.remove(idx)
                    } else {
                        selectedSuggestionIndices.insert(idx)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(isSelected ? BotanicalTheme.primary : BotanicalTheme.textHint)

                        Text(step)
                            .font(.system(size: 13))
                            .foregroundColor(BotanicalTheme.textPrimary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(isSelected ? BotanicalTheme.primarySoft.opacity(0.65) : Color.white.opacity(0.60))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Button {
                confirmSelectedSuggestions()
            } label: {
                Text("添加选中的 \(selectedSuggestionIndices.count) 个微步骤")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(
                        selectedSuggestionIndices.isEmpty
                            ? AnyShapeStyle(BotanicalTheme.textHint.opacity(0.45))
                            : AnyShapeStyle(BotanicalTheme.primaryGradient)
                    )
                    .clipShape(Capsule())
            }
            .buttonStyle(ScaleBounceButtonStyle(scale: 0.97))
            .disabled(selectedSuggestionIndices.isEmpty)
        }
        .padding(10)
        .background(BotanicalTheme.primarySoft.opacity(0.32))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
    }

    private func confirmSelectedSuggestions() {
        let picked = aiSuggestions.enumerated()
            .filter { selectedSuggestionIndices.contains($0.offset) }
            .map(\.element)
        guard !picked.isEmpty else { return }
        SensoryFeedbackService.shared.lightTap()
        for step in picked {
            appState.addSubPlan(parentId: plan.id, name: step)
        }
        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
            aiSuggestions = []
            selectedSuggestionIndices = []
        }
        onFeedback("已添加 \(picked.count) 个精选微步骤并置顶到首页")
    }

    private func triggerAiBreakdown() {
        if !proStore.isPro {
            appState.showProPaywall = true
            return
        }
        isAiBreaking = true
        Task {
            do {
                let steps = try await appState.previewAiBreakdownSteps(planId: plan.id)
                await MainActor.run {
                    isAiBreaking = false
                    SensoryFeedbackService.shared.lightTap()
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                        aiSuggestions = steps
                        selectedSuggestionIndices = Set(steps.indices)
                    }
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
