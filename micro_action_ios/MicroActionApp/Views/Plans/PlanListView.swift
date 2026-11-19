import SwiftUI

/// 计划列表视图（Tiimo 风格治愈系空状态引导 + 轻呼吸卡片列表 + 已完成折叠区 + iOS 提醒事项面板）
struct PlanListView: View {
    var onQuickAdd: () -> Void = {}
    var onOpenShineJar: () -> Void = {}
    var onSwitchTab: (MainTabView.ActiveTab) -> Void = { _ in }

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var proStore: ProStoreService

    @State private var expandedPlanId: String? = nil
    @State private var showCompleted: Bool = true
    @State private var editingPlan: PlanItem? = nil
    @State private var detailPlan: PlanItem? = nil
    @State private var reminderTargetPlan: PlanItem? = nil
    @State private var toastText: String? = nil

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                if let toast = toastText {
                    Text(toast)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(BotanicalTheme.primaryDark)
                        .clipShape(Capsule())
                        .shadow(color: BotanicalTheme.primary.opacity(0.24), radius: 10, y: 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if appState.ongoingPlans.isEmpty {
                    emptyStateView
                } else {
                    sectionHeader(title: "微行动计划", count: appState.ongoingPlans.count)

                    ForEach(appState.ongoingPlans) { plan in
                        PlanCardView(
                            plan: plan,
                            isExpanded: expandedPlanId == plan.id,
                            onTap: {
                                SensoryFeedbackService.shared.selection()
                                withAnimation(.spring(response: 0.30, dampingFraction: 0.84)) {
                                    expandedPlanId = expandedPlanId == plan.id ? nil : plan.id
                                }
                            },
                            onTapSubPlan: { subId in
                                withAnimation(.spring(response: 0.30, dampingFraction: 0.84)) {
                                    expandedPlanId = subId
                                }
                            },
                            onEdit: { editingPlan = plan },
                            onDetail: { detailPlan = plan },
                            onRequestReminder: {
                                if !proStore.isPro {
                                    appState.showProPaywall = true
                                } else {
                                    reminderTargetPlan = plan
                                }
                            },
                            onFeedback: { msg in showToast(msg) }
                        )
                    }
                }

                if !appState.completedPlans.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            SensoryFeedbackService.shared.selection()
                            withAnimation(.easeInOut(duration: 0.24)) {
                                showCompleted.toggle()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text("已完成")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(BotanicalTheme.textPrimary)

                                Text("\(appState.completedPlans.count)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(BotanicalTheme.primaryDark)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 3.5)
                                    .background(BotanicalTheme.primarySoft)
                                    .clipShape(Capsule())

                                Spacer()

                                Image(systemName: showCompleted ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(BotanicalTheme.textHint)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 18)

                        if showCompleted {
                            ForEach(appState.completedPlans) { plan in
                                PlanCardView(
                                    plan: plan,
                                    isExpanded: expandedPlanId == plan.id,
                                    onTap: {
                                        SensoryFeedbackService.shared.selection()
                                        withAnimation(.spring(response: 0.30, dampingFraction: 0.84)) {
                                            expandedPlanId = expandedPlanId == plan.id ? nil : plan.id
                                        }
                                    },
                                    onTapSubPlan: { subId in
                                        withAnimation(.spring(response: 0.30, dampingFraction: 0.84)) {
                                            expandedPlanId = subId
                                        }
                                    },
                                    onEdit: { editingPlan = plan },
                                    onDetail: { detailPlan = plan },
                                    onRequestReminder: {},
                                    onFeedback: { msg in showToast(msg) }
                                )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 130)
        }
        .sheet(item: $editingPlan) { plan in
            AddPlanSheet(editingPlan: plan)
        }
        .sheet(item: $detailPlan) { plan in
            PlanDetailSheet(plan: plan)
        }
        .sheet(item: $reminderTargetPlan) { plan in
            PlanReminderOptionSheet(plan: plan) { message in
                expandedPlanId = nil
                showToast(message)
            }
        }
    }

    private func sectionHeader(title: String, count: Int) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(BotanicalTheme.textPrimary)

            Text("\(count)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(BotanicalTheme.primaryDark)
                .padding(.horizontal, 9)
                .padding(.vertical, 3)
                .background(BotanicalTheme.primarySoft)
                .clipShape(Capsule())

            Spacer()
        }
        .padding(.top, 4)
        .padding(.bottom, 4)
    }

    private var emptyStateView: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 28)

            StarSproutIllustrationBadge(imageName: "IllustEmptyPlan", size: 204)
                .padding(.bottom, 8)

            Text("写下今天的一件小事\n让第一个微行动悄悄发芽")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(BotanicalTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.bottom, 36)

            VStack(alignment: .leading, spacing: 11) {
                TiimoQuickActionPill(
                    icon: "sparkles",
                    iconColor: BotanicalTheme.primary,
                    title: "写下今天的一个微行动"
                ) {
                    onQuickAdd()
                }

                TiimoQuickActionPill(
                    icon: "checkmark.square.fill",
                    iconColor: BotanicalTheme.success,
                    title: "养成一个 2 分钟微习惯"
                ) {
                    onSwitchTab(.habits)
                }

                TiimoQuickActionPill(
                    icon: "calendar",
                    iconColor: BotanicalTheme.anchorAccent,
                    title: "设置每日时间锚点提醒"
                ) {
                    onSwitchTab(.anchors)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 18)

            TiimoSoftBannerCard(
                title: "随时为自己鼓掌",
                subtitle: "去微步成长树浇灌今日份成长",
                buttonLabel: "去看看"
            ) {
                onOpenShineJar()
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func showToast(_ msg: String) {
        withAnimation(.easeOut(duration: 0.2)) {
            toastText = msg
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            if toastText == msg {
                withAnimation(.easeIn(duration: 0.2)) {
                    toastText = nil
                }
            }
        }
    }
}

/// 原版风格：加入 iOS 系统提醒事项底部选项面板（直接加入 / 设置提醒时间后加入）
private struct PlanReminderOptionSheet: View {
    let plan: PlanItem
    let onComplete: (String) -> Void

    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var showTimePicker: Bool = false
    @State private var chosenTime: Date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var isSubmitting: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(BotanicalTheme.info)
                    .frame(width: 42, height: 42)
                    .background(BotanicalTheme.info.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("加入 iOS 提醒事项")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(BotanicalTheme.textPrimary)
                    Text("自动归入专属「微行动」提醒列表")
                        .font(.system(size: 12.5))
                        .foregroundColor(BotanicalTheme.textSecondary)
                }
                Spacer()
            }

            Button {
                submitReminder(dueDate: nil)
            } label: {
                optionCard(
                    icon: "checkmark.circle.fill",
                    iconColor: BotanicalTheme.primaryDark,
                    borderColor: BotanicalTheme.primary.opacity(0.18),
                    title: "直接加入「微行动」提醒列表",
                    subtitle: "不设特定闹钟，随时在系统提醒事项中查看勾选"
                )
            }
            .buttonStyle(ScaleBounceButtonStyle(scale: 0.98))
            .disabled(isSubmitting)

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    showTimePicker.toggle()
                }
            } label: {
                optionCard(
                    icon: "clock.badge.checkmark",
                    iconColor: BotanicalTheme.info,
                    borderColor: BotanicalTheme.info.opacity(0.20),
                    title: "设置提醒时间后加入",
                    subtitle: "到点触发 iOS 系统级提醒事项推送"
                )
            }
            .buttonStyle(ScaleBounceButtonStyle(scale: 0.98))
            .disabled(isSubmitting)

            if showTimePicker {
                VStack(spacing: 12) {
                    DatePicker("选择提醒时间", selection: $chosenTime, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .tint(BotanicalTheme.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(BotanicalTheme.surfaceMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Button {
                        submitReminder(dueDate: chosenTime)
                    } label: {
                        Text(isSubmitting ? "正在写入..." : "确认时间并加入提醒事项")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(BotanicalTheme.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(isSubmitting)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 20)
        .background(Color.white.ignoresSafeArea())
        .presentationDetents([showTimePicker ? .medium : .height(300)])
        .presentationDragIndicator(.visible)
    }

    private func optionCard(
        icon: String,
        iconColor: Color,
        borderColor: Color,
        title: String,
        subtitle: String
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(BotanicalTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(BotanicalTheme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(BotanicalTheme.textHint)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(BotanicalTheme.surfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private func submitReminder(dueDate: Date?) {
        isSubmitting = true
        SensoryFeedbackService.shared.lightTap()
        Task {
            let ok = await appState.pushPlanToAppleReminders(planId: plan.id, dueDate: dueDate)
            await MainActor.run {
                isSubmitting = false
                dismiss()
                onComplete(ok ? "已将「\(plan.name)」加入 iOS 提醒事项『微行动』列表" : "写入提醒事项失败，请检查系统权限")
            }
        }
    }
}
