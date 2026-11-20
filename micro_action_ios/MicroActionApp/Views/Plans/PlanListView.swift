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
        List {
            if let toast = toastText {
                Text(toast)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(BotanicalTheme.primaryDark)
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            if !appState.ongoingPlans.isEmpty {
                HeaderHeroBannerCard(
                    todayShineCount: appState.todayShineCount,
                    mainContradictionCount: appState.mainContradictionPlans.count,
                    ongoingCount: appState.ongoingPlans.count
                )
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 6, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            if appState.ongoingPlans.isEmpty {
                emptyStateView
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            } else {
                if !appState.mainContradictionPlans.isEmpty {
                    mainContradictionHeader(count: appState.mainContradictionPlans.count)
                        .listRowInsets(EdgeInsets(top: 4, leading: 18, bottom: 2, trailing: 18))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)

                    ForEach(appState.mainContradictionPlans) { plan in
                        planRowCard(plan, allowSwipeContradiction: true)
                    }
                }

                if !appState.normalOngoingPlans.isEmpty {
                    if !appState.mainContradictionPlans.isEmpty {
                        HStack(spacing: 6) {
                            Text("其他愿望")
                                .font(.system(size: 13.5, weight: .semibold))
                                .foregroundColor(BotanicalTheme.textSecondary)
                            Text("\(appState.normalOngoingPlans.count)")
                                .font(.system(size: 10.5, weight: .bold))
                                .foregroundColor(BotanicalTheme.textSecondary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(BotanicalTheme.surfaceMuted)
                                .clipShape(Capsule())
                            Spacer()
                        }
                        .padding(.top, 10)
                        .listRowInsets(EdgeInsets(top: 4, leading: 18, bottom: 2, trailing: 18))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }

                    ForEach(appState.normalOngoingPlans) { plan in
                        planRowCard(plan, allowSwipeContradiction: true)
                    }
                }
            }

            if !appState.completedPlans.isEmpty {
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
                    .padding(.top, 14)
                    .padding(.bottom, 2)
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

                if showCompleted {
                    ForEach(appState.completedPlans) { plan in
                        planRowCard(plan, allowSwipeContradiction: false)
                    }
                }
            }

            Color.clear
                .frame(height: 112)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
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
        .onAppear {
            consumePendingLocatePlan()
        }
        .onChange(of: appState.pendingLocatePlanId) { _ in
            consumePendingLocatePlan()
        }
    }

    private func consumePendingLocatePlan() {
        guard let targetId = appState.pendingLocatePlanId else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                expandedPlanId = targetId
            }
            appState.pendingLocatePlanId = nil
        }
    }

    private func mainContradictionHeader(count: Int) -> some View {
        HStack(alignment: .center, spacing: 7) {
            Image(systemName: "flame.fill")
                .font(.system(size: 13.5, weight: .bold))
                .foregroundColor(Color(hex: 0xD96B27))

            Text("主要矛盾 · 优先解决")
                .font(.system(size: 14.5, weight: .bold))
                .foregroundColor(Color(hex: 0x9C4415))

            Text("\(count)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: 0xB8531E))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color(hex: 0xFCEAD7))
                .clipShape(Capsule())

            Spacer()
        }
        .padding(.top, 4)
        .padding(.bottom, 2)
    }

    @ViewBuilder
    private func planRowCard(_ plan: PlanItem, allowSwipeContradiction: Bool) -> some View {
        let card = PlanCardView(
            plan: plan,
            isExpanded: expandedPlanId == plan.id,
            onTap: {
                SensoryFeedbackService.shared.selection()
                withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
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
                if !allowSwipeContradiction { return }
                if !proStore.isPro {
                    appState.showProPaywall = true
                } else {
                    reminderTargetPlan = plan
                }
            },
            onFeedback: { msg in showToast(msg) }
        )
        .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)

        if allowSwipeContradiction {
            card.swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button {
                    SensoryFeedbackService.shared.lightTap()
                    let nextState = !plan.isMainContradiction
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                        appState.toggleMainContradiction(id: plan.id)
                    }
                    showToast(nextState ? "已设为主要矛盾，优先解决" : "已移出主要矛盾")
                } label: {
                    Label(
                        plan.isMainContradiction ? "取消主要矛盾" : "主要矛盾",
                        systemImage: plan.isMainContradiction ? "flame.slash" : "flame.fill"
                    )
                }
                .tint(plan.isMainContradiction ? BotanicalTheme.textSecondary : Color(hex: 0xD96B27))
            }
        } else {
            card
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

            Text("写下今天的一个愿望\n让每一个向往悄悄发芽")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(BotanicalTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.bottom, 36)

            VStack(alignment: .leading, spacing: 11) {
                TiimoQuickActionPill(
                    icon: "sparkles",
                    iconColor: BotanicalTheme.primary,
                    title: "写下今天的一个愿望"
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

/// 顶部晨光精灵水彩关怀横幅（每次打开自动播放入场动画，展示时段关怀语言与关键数据）
private struct HeaderHeroBannerCard: View {
    let todayShineCount: Int
    let mainContradictionCount: Int
    let ongoingCount: Int

    @State private var appeared: Bool = false
    @State private var tapBounce: Bool = false
    @State private var quoteIndex: Int = 0

    private static let gentleQuotes: [String] = [
        "不用一次做完，先迈出 2 分钟就够了",
        "微小的每一步，都在悄悄长成森林",
        "先解决眼前的关键一步，节奏就稳了",
        "允许自己慢慢来，今天也有好好发光"
    ]

    private var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return "早安，今天也从一件小事发芽"
        case 11..<14: return "午安，慢下来喝口水也是微步"
        case 14..<18: return "下午好，哪怕推进一点也很棒"
        case 18..<23:
            return todayShineCount > 0 ? "晚上好，今日已点亮 \(todayShineCount) 步微光" : "晚上好，做一件轻松的小事再休息"
        default: return "夜深了，把未完的事温柔交给明天"
        }
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Image("IllustHeaderHero")
                .resizable()
                .scaledToFill()
                .frame(height: 102)
                .clipped()

            // 左侧文字与关键数据层
            VStack(alignment: .leading, spacing: 4) {
                Text(timeGreeting)
                    .font(.system(size: 14.5, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: 0x1B3F2E))
                    .lineLimit(1)

                Text(quoteIndex == 0 ? Self.gentleQuotes[0] : Self.gentleQuotes[quoteIndex % Self.gentleQuotes.count])
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(Color(hex: 0x4A6B5A))
                    .lineLimit(1)
                    .id(quoteIndex)
                    .transition(.opacity)

                HStack(spacing: 6) {
                    miniStatPill(
                        icon: "sparkles",
                        text: "今日 +\(todayShineCount)",
                        tint: BotanicalTheme.primaryDark,
                        bg: Color.white.opacity(0.88)
                    )

                    if mainContradictionCount > 0 {
                        miniStatPill(
                            icon: "flame.fill",
                            text: "主要矛盾 \(mainContradictionCount)",
                            tint: Color(hex: 0xB8531E),
                            bg: Color(hex: 0xFCEAD7).opacity(0.95)
                        )
                    } else {
                        miniStatPill(
                            icon: "leaf.fill",
                            text: "待办 \(ongoingCount)",
                            tint: Color(hex: 0x2F5E45),
                            bg: Color.white.opacity(0.88)
                        )
                    }
                }
                .padding(.top, 2)
            }
            .padding(.leading, 16)
            .padding(.trailing, 118)
            .opacity(appeared ? 1.0 : 0.0)
            .offset(y: appeared ? 0 : 6)
        }
        .frame(height: 102)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.92), lineWidth: 1.1)
        )
        .shadow(color: BotanicalTheme.primaryDark.opacity(0.06), radius: 7, y: 3)
        .scaleEffect(appeared ? (tapBounce ? 0.975 : 1.0) : 0.94)
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            guard !appeared else { return }
            withAnimation(.spring(response: 0.46, dampingFraction: 0.76)) {
                appeared = true
            }
        }
        .onTapGesture {
            SensoryFeedbackService.shared.selection()
            withAnimation(.spring(response: 0.24, dampingFraction: 0.65)) {
                tapBounce = true
                quoteIndex += 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                withAnimation(.spring(response: 0.30, dampingFraction: 0.70)) {
                    tapBounce = false
                }
            }
        }
    }

    private func miniStatPill(icon: String, text: String, tint: Color, bg: Color) -> some View {
        HStack(spacing: 3.5) {
            Image(systemName: icon)
                .font(.system(size: 9.5, weight: .bold))
            Text(text)
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
        }
        .foregroundColor(tint)
        .padding(.horizontal, 8.5)
        .padding(.vertical, 3)
        .background(bg)
        .clipShape(Capsule())
    }
}

