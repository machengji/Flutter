import SwiftUI

/// 单条微习惯卡片（完整复刻原版 HabitCard 溪流青碧视觉、50x50 彩蝶蜕变打卡框与内嵌浅青操作托盘）
struct HabitCardView: View {
    let habit: HabitItem
    let isExpanded: Bool
    let onTap: () -> Void
    let onEdit: () -> Void

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var proStore: ProStoreService
    @State private var showDeleteConfirm: Bool = false

    private var isStopped: Bool { habit.status == .stopped }
    private var lastCompleteTime: Int64 { habit.completionHistory.last ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                // 50x50 彩蝶蜕变打卡框（轻点即刻完成一次习惯打卡并触发庆祝）
                Button {
                    guard !isStopped else { return }
                    SensoryFeedbackService.shared.lightTap()
                    Task {
                        await appState.checkHabit(id: habit.id, isPro: proStore.isPro)
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(badgeFill)
                            .frame(width: 50, height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .stroke(badgeBorder, lineWidth: 1.6)
                            )

                        if habit.totalDays > 0 {
                            Text("\(habit.totalDays)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(isStopped ? BotanicalTheme.textSecondary : .white)
                        } else {
                            Image(systemName: "wind")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(isStopped ? BotanicalTheme.textHint : BotanicalTheme.secondary.opacity(0.62))
                        }
                    }
                }
                .buttonStyle(ScaleBounceButtonStyle(scale: 0.90))
                .disabled(isStopped)

                // 标题与蜕变状态
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 5) {
                        if habit.isPinned && !isStopped {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(BotanicalTheme.accentWarm)
                        }
                        Text(habit.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isStopped ? BotanicalTheme.textSecondary : BotanicalTheme.textPrimary)
                            .strikethrough(isStopped, color: BotanicalTheme.textSecondary)
                            .lineLimit(2)
                    }

                    HStack(spacing: 8) {
                        if !isStopped && habit.totalDays > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(BotanicalTheme.secondaryDark)
                                Text("已蜕变 \(habit.totalDays) 次")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(BotanicalTheme.secondaryDark)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2.5)
                            .background(BotanicalTheme.secondary.opacity(0.11))
                            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        }

                        Text(
                            isStopped
                                ? "休眠中"
                                : "最近: \(BotanicalTheme.formatRelativeDate(epochMs: lastCompleteTime))"
                        )
                        .font(.system(size: 13))
                        .foregroundColor(BotanicalTheme.textSecondary)
                    }
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(BotanicalTheme.textHint)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .animation(.easeOut(duration: 0.2), value: isExpanded)
            }
            .padding(15)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)

            // 展开区：柔雾冰蓝圆角操作托盘
            if isExpanded {
                HStack(spacing: 8) {
                    if !isStopped {
                        squareActionButton(
                            icon: "checkmark",
                            color: BotanicalTheme.primary
                        ) {
                            Task {
                                await appState.checkHabit(id: habit.id, isPro: proStore.isPro)
                            }
                        }
                    }

                    squareActionButton(
                        icon: "pencil",
                        color: BotanicalTheme.secondaryDark,
                        action: onEdit
                    )

                    squareActionButton(
                        icon: habit.isPinned ? "pin.slash" : "pin",
                        color: BotanicalTheme.accentWarm,
                        isHighlighted: habit.isPinned
                    ) {
                        appState.togglePinHabit(id: habit.id)
                    }

                    squareActionButton(
                        icon: isStopped ? "play.fill" : "pause.fill",
                        color: isStopped ? BotanicalTheme.primary : BotanicalTheme.textSecondary
                    ) {
                        appState.toggleHabitStatus(id: habit.id)
                    }

                    squareActionButton(
                        icon: "trash",
                        color: BotanicalTheme.danger,
                        isDanger: true
                    ) {
                        showDeleteConfirm = true
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(BotanicalTheme.habitTrayBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(BotanicalTheme.habitTrayBorder, lineWidth: 0.8)
                )
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(BotanicalTheme.habitCardGradient)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    isExpanded
                        ? BotanicalTheme.habitAccent.opacity(0.28)
                        : BotanicalTheme.border.opacity(0.90),
                    lineWidth: 1
                )
        )
        .shadow(color: BotanicalTheme.shadowLight, radius: 14, y: 5)
        .alert("确认删除习惯？", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                appState.deleteHabit(id: habit.id)
            }
        } message: {
            Text("确定要删除「\(habit.name)」及历史打卡记录吗？此操作不可撤销。")
        }
    }

    private var badgeFill: AnyShapeStyle {
        if isStopped {
            return AnyShapeStyle(BotanicalTheme.textHint.opacity(0.10))
        }
        if habit.totalDays > 0 {
            return AnyShapeStyle(BotanicalTheme.secondaryGradient)
        }
        return AnyShapeStyle(BotanicalTheme.secondary.opacity(0.06))
    }

    private var badgeBorder: Color {
        if isStopped { return BotanicalTheme.textHint.opacity(0.28) }
        if habit.totalDays > 0 { return BotanicalTheme.secondary }
        return BotanicalTheme.secondary.opacity(0.28)
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
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(effectiveColor)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
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
}
