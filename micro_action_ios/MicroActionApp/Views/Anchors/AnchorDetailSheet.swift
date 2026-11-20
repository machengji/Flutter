import SwiftUI

/// 时间锚点详情抽屉（支持关联愿望/习惯及一键打卡；内建顶层庆祝海报层，彻底确保打卡弹窗绝不被抽屉遮挡！）
struct AnchorDetailSheet: View {
    let anchorId: String

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var proStore: ProStoreService
    @Environment(\.dismiss) private var dismiss

    @State private var showPlanPicker: Bool = false
    @State private var showHabitPicker: Bool = false

    private var anchor: AnchorItem? {
        appState.anchors.first(where: { $0.id == anchorId })
    }

    var body: some View {
        ZStack {
            NavigationStack {
                if let anchor {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // 顶部时间与锚点信息
                            HStack(spacing: 14) {
                                Text(anchor.triggerTime)
                                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                                    .foregroundColor(Color(hex: 0xB45309))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Color(hex: 0xFEF3C7))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(anchor.name)
                                        .font(.system(size: 20, weight: .heavy))
                                        .foregroundColor(BotanicalTheme.textPrimary)
                                    Text("重复周期：\(anchor.repeatCycle.rawValue)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color(hex: 0xB45309))
                                }

                                Spacer()

                                Button(role: .destructive) {
                                    appState.deleteAnchor(id: anchor.id)
                                    dismiss()
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(BotanicalTheme.danger)
                                        .padding(10)
                                        .background(BotanicalTheme.danger.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }

                            let boundPlans = appState.ongoingPlans.filter { anchor.planIds.contains($0.id) }
                            let boundUncheckedHabits = appState.activeHabits.filter { anchor.habitIds.contains($0.id) && $0.todayCheckCount() == 0 }
                            let pendingTotal = boundPlans.count + boundUncheckedHabits.count

                            if pendingTotal > 0 {
                                Button {
                                    SensoryFeedbackService.shared.lightTap()
                                    Task {
                                        await appState.completeAllForAnchor(anchorId: anchor.id, isPro: proStore.isPro)
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 16, weight: .bold))
                                        Text("一键完成本锚点全部事项 (\(pendingTotal) 项)")
                                            .font(.system(size: 14.5, weight: .bold))
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

                            // 关联愿望区块
                            sectionHeader(title: "关联愿望") {
                                showPlanPicker = true
                            }

                            if boundPlans.isEmpty {
                                Text("暂无关联愿望")
                                    .font(.system(size: 13))
                                    .foregroundColor(BotanicalTheme.textHint)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                            } else {
                                ForEach(boundPlans) { plan in
                                    HStack(spacing: 10) {
                                        Text(plan.name)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(BotanicalTheme.textPrimary)
                                        Spacer()
                                        Button("完成") {
                                            Task {
                                                await appState.togglePlanStatus(id: plan.id, isPro: proStore.isPro)
                                            }
                                        }
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(BotanicalTheme.primary)
                                        .clipShape(Capsule())

                                        Button {
                                            appState.unbindPlanFromAnchor(anchorId: anchor.id, planId: plan.id)
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(BotanicalTheme.danger)
                                                .padding(8)
                                                .background(BotanicalTheme.danger.opacity(0.1))
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                    }
                                    .padding(14)
                                    .background(BotanicalTheme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(BotanicalTheme.border, lineWidth: 1))
                                }
                            }

                            // 关联习惯区块
                            sectionHeader(title: "关联习惯") {
                                showHabitPicker = true
                            }

                            let boundHabits = appState.activeHabits.filter { anchor.habitIds.contains($0.id) }
                            if boundHabits.isEmpty {
                                Text("暂无关联习惯")
                                    .font(.system(size: 13))
                                    .foregroundColor(BotanicalTheme.textHint)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                            } else {
                                ForEach(boundHabits) { habit in
                                    let todayCount = habit.todayCheckCount()
                                    HStack(spacing: 10) {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(habit.name)
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(BotanicalTheme.textPrimary)
                                            Text(todayCount > 0
                                                 ? "今日已打卡 \(todayCount) 次 · 累计 \(habit.totalDays) 次"
                                                 : "今日待打卡 · 累计 \(habit.totalDays) 次")
                                                .font(.system(size: 12))
                                                .foregroundColor(BotanicalTheme.textSecondary)
                                        }
                                        Spacer()
                                        Button {
                                            Task {
                                                await appState.checkHabit(id: habit.id, isPro: proStore.isPro)
                                            }
                                        } label: {
                                            Text(todayCount > 0 ? "已打卡(\(todayCount))" : "打卡")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(todayCount > 0 ? BotanicalTheme.primaryDark : .white)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(todayCount > 0 ? BotanicalTheme.primarySoft : BotanicalTheme.primary)
                                                .clipShape(Capsule())
                                        }

                                        Button {
                                            appState.unbindHabitFromAnchor(anchorId: anchor.id, habitId: habit.id)
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(BotanicalTheme.danger)
                                                .padding(8)
                                                .background(BotanicalTheme.danger.opacity(0.1))
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                    }
                                    .padding(14)
                                    .background(BotanicalTheme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(BotanicalTheme.border, lineWidth: 1))
                                }
                            }
                        }
                        .padding(20)
                    }
                    .background(BotanicalTheme.backgroundTop.ignoresSafeArea())
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("完成") { dismiss() }
                                .foregroundColor(BotanicalTheme.primary)
                        }
                    }
                    .sheet(isPresented: $showPlanPicker) {
                        AnchorPlanBindSheet(anchorId: anchor.id)
                            .presentationDetents([.medium, .large])
                            .presentationDragIndicator(.visible)
                    }
                    .sheet(isPresented: $showHabitPicker) {
                        AnchorHabitBindSheet(anchorId: anchor.id)
                            .presentationDetents([.medium, .large])
                            .presentationDragIndicator(.visible)
                    }
                }
            }

            // 在 Sheet 顶层直接承载庆祝海报，确保在锚点弹窗内打卡时 100% 浮现于最前方不被遮挡！
            if let payload = appState.activeCelebration {
                CelebrationPosterView(payload: payload) {
                    appState.activeCelebration = nil
                }
                .zIndex(999)
            }
        }
    }

    private func sectionHeader(title: String, onAdd: @escaping () -> Void) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(BotanicalTheme.primary)
                .frame(width: 4, height: 16)
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(BotanicalTheme.textPrimary)
            Spacer()
            Button(action: onAdd) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("关联管理")
                        .font(.system(size: 12.5, weight: .bold))
                }
                .foregroundColor(BotanicalTheme.primaryDark)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(BotanicalTheme.primarySoft.opacity(0.75))
                .clipShape(Capsule())
            }
            .buttonStyle(ScaleBounceButtonStyle(scale: 0.94))
        }
    }
}

/// 现代 Liquid Glass 风格「关联微行动愿望」多选弹窗
private struct AnchorPlanBindSheet: View {
    let anchorId: String
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private var anchor: AnchorItem? {
        appState.anchors.first(where: { $0.id == anchorId })
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    if appState.ongoingPlans.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "tray")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(BotanicalTheme.textHint)
                            Text("暂无进行中的微行动愿望")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(BotanicalTheme.textSecondary)
                            Text("先去“愿望”页新建一个微行动愿望，再回来绑定时间锚点吧")
                                .font(.system(size: 12.5))
                                .foregroundColor(BotanicalTheme.textHint)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 44)
                        .padding(.horizontal, 20)
                        .liquidGlassCard(cornerRadius: 20, tint: BotanicalTheme.primaryLight, interactive: false, shadowRadius: 10)
                    } else {
                        let boundCount = appState.ongoingPlans.filter { anchor?.planIds.contains($0.id) == true }.count
                        HStack {
                            Text("轻点卡片即可即时绑定或取消")
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundColor(BotanicalTheme.textSecondary)
                            Spacer()
                            Text("已关联 \(boundCount) 项")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(BotanicalTheme.primaryDark)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(BotanicalTheme.primarySoft.opacity(0.75))
                                .clipShape(Capsule())
                        }
                        .padding(.bottom, 4)

                        ForEach(appState.ongoingPlans) { plan in
                            let isBound = anchor?.planIds.contains(plan.id) == true
                            Button {
                                SensoryFeedbackService.shared.selection()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    if isBound {
                                        appState.unbindPlanFromAnchor(anchorId: anchorId, planId: plan.id)
                                    } else {
                                        appState.bindPlanToAnchor(anchorId: anchorId, planId: plan.id)
                                    }
                                }
                            } label: {
                                let subs = appState.directSubPlans(of: plan.id)
                                let doneSubs = subs.filter { $0.status == .completed }.count
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(isBound ? BotanicalTheme.primary : BotanicalTheme.surfaceMuted)
                                            .frame(width: 38, height: 38)
                                        Image(systemName: isBound ? "checkmark" : "list.bullet.clipboard")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(isBound ? .white : BotanicalTheme.textSecondary)
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(plan.name)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(BotanicalTheme.textPrimary)
                                            .lineLimit(1)
                                        Text(subs.isEmpty ? "微行动愿望" : "含 \(subs.count) 个微步骤 · 已完成 \(doneSubs)/\(subs.count)")
                                            .font(.system(size: 12))
                                            .foregroundColor(BotanicalTheme.textSecondary)
                                    }

                                    Spacer()

                                    Text(isBound ? "已关联" : "关联")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(isBound ? BotanicalTheme.primaryDark : BotanicalTheme.textSecondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(isBound ? BotanicalTheme.primarySoft : BotanicalTheme.surfaceMuted)
                                        .clipShape(Capsule())
                                }
                                .padding(12)
                                .liquidGlassCard(cornerRadius: 16, tint: isBound ? BotanicalTheme.primaryLight : BotanicalTheme.surface, interactive: false, shadowRadius: isBound ? 12 : 6)
                            }
                            .buttonStyle(ScaleBounceButtonStyle(scale: 0.98))
                        }
                    }
                }
                .padding(18)
            }
            .background(BotanicalTheme.backgroundTop.ignoresSafeArea())
            .navigationTitle("关联微行动愿望")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        SensoryFeedbackService.shared.lightTap()
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(BotanicalTheme.primary)
                }
            }
        }
    }
}

/// 现代 Liquid Glass 风格「关联微习惯」多选弹窗
private struct AnchorHabitBindSheet: View {
    let anchorId: String
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private var anchor: AnchorItem? {
        appState.anchors.first(where: { $0.id == anchorId })
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    if appState.activeHabits.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "leaf")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(BotanicalTheme.textHint)
                            Text("暂无进行中的微习惯")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(BotanicalTheme.textSecondary)
                            Text("先去“习惯”页创建一个微习惯，再回来绑定时间锚点吧")
                                .font(.system(size: 12.5))
                                .foregroundColor(BotanicalTheme.textHint)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 44)
                        .padding(.horizontal, 20)
                        .liquidGlassCard(cornerRadius: 20, tint: BotanicalTheme.primaryLight, interactive: false, shadowRadius: 10)
                    } else {
                        let boundCount = appState.activeHabits.filter { anchor?.habitIds.contains($0.id) == true }.count
                        HStack {
                            Text("轻点卡片即可即时绑定或取消")
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundColor(BotanicalTheme.textSecondary)
                            Spacer()
                            Text("已关联 \(boundCount) 项")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(BotanicalTheme.primaryDark)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(BotanicalTheme.primarySoft.opacity(0.75))
                                .clipShape(Capsule())
                        }
                        .padding(.bottom, 4)

                        ForEach(appState.activeHabits) { habit in
                            let isBound = anchor?.habitIds.contains(habit.id) == true
                            Button {
                                SensoryFeedbackService.shared.selection()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    if isBound {
                                        appState.unbindHabitFromAnchor(anchorId: anchorId, habitId: habit.id)
                                    } else {
                                        appState.bindHabitToAnchor(anchorId: anchorId, habitId: habit.id)
                                    }
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(isBound ? BotanicalTheme.primary : BotanicalTheme.surfaceMuted)
                                            .frame(width: 38, height: 38)
                                        Image(systemName: isBound ? "checkmark" : "flame.fill")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(isBound ? .white : BotanicalTheme.warning)
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(habit.name)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(BotanicalTheme.textPrimary)
                                            .lineLimit(1)
                                        Text("已累计打卡 \(habit.totalDays) 次")
                                            .font(.system(size: 12))
                                            .foregroundColor(BotanicalTheme.textSecondary)
                                    }

                                    Spacer()

                                    Text(isBound ? "已关联" : "关联")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(isBound ? BotanicalTheme.primaryDark : BotanicalTheme.textSecondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(isBound ? BotanicalTheme.primarySoft : BotanicalTheme.surfaceMuted)
                                        .clipShape(Capsule())
                                }
                                .padding(12)
                                .liquidGlassCard(cornerRadius: 16, tint: isBound ? BotanicalTheme.primaryLight : BotanicalTheme.surface, interactive: false, shadowRadius: isBound ? 12 : 6)
                            }
                            .buttonStyle(ScaleBounceButtonStyle(scale: 0.98))
                        }
                    }
                }
                .padding(18)
            }
            .background(BotanicalTheme.backgroundTop.ignoresSafeArea())
            .navigationTitle("关联微习惯")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        SensoryFeedbackService.shared.lightTap()
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(BotanicalTheme.primary)
                }
            }
        }
    }
}
