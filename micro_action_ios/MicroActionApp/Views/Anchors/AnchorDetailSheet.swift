import SwiftUI

/// 时间锚点详情抽屉（支持关联计划/习惯及一键打卡；内建顶层庆祝海报层，彻底确保打卡弹窗绝不被抽屉遮挡！）
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

                            // 关联计划区块
                            sectionHeader(title: "关联计划") {
                                showPlanPicker = true
                            }

                            let boundPlans = appState.ongoingPlans.filter { anchor.planIds.contains($0.id) }
                            if boundPlans.isEmpty {
                                Text("暂无关联计划")
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
                    .confirmationDialog("选择要关联的计划", isPresented: $showPlanPicker, titleVisibility: .visible) {
                        ForEach(appState.ongoingPlans.filter { !anchor.planIds.contains($0.id) }) { p in
                            Button(p.name) {
                                appState.bindPlanToAnchor(anchorId: anchor.id, planId: p.id)
                            }
                        }
                        Button("取消", role: .cancel) {}
                    }
                    .confirmationDialog("选择要关联的习惯", isPresented: $showHabitPicker, titleVisibility: .visible) {
                        ForEach(appState.activeHabits.filter { !anchor.habitIds.contains($0.id) }) { h in
                            Button(h.name) {
                                appState.bindHabitToAnchor(anchorId: anchor.id, habitId: h.id)
                            }
                        }
                        Button("取消", role: .cancel) {}
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
                Text("+ 添加")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(BotanicalTheme.primaryDark)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(BotanicalTheme.primarySoft.opacity(0.7))
                    .clipShape(Capsule())
            }
        }
    }
}
