import SwiftUI

/// 单条微习惯卡片（完整复刻原版 HabitCard 溪流青碧视觉、50x50 彩蝶蜕变打卡框与内嵌浅青操作托盘）
struct HabitCardView: View {
    let habit: HabitItem
    let isExpanded: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    var onStarterInputFocused: (() -> Void)? = nil

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var proStore: ProStoreService
    @State private var showDeleteConfirm: Bool = false
    @State private var starterDraft: String = ""
    @State private var isAiShrinking: Bool = false
    @State private var aiStarterSuggestions: [String] = []
    @FocusState private var isStarterInputFocused: Bool

    private var isStopped: Bool { habit.status == .stopped }
    private var lastCompleteTime: Int64 { habit.completionHistory.last ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                // 50x50 彩蝶蜕变打卡框（轻点即刻完成一次习惯打卡并触发庆祝）
                Button {
                    guard !isStopped else { return }
                    SensoryFeedbackService.shared.microStepComplete()
                    Task {
                        await appState.checkHabit(id: habit.id, isPro: proStore.isPro)
                    }
                } label: {
                    let checkedToday = habit.todayCheckCount() > 0
                    ZStack {
                        Circle()
                            .fill(
                                isStopped
                                    ? AnyShapeStyle(BotanicalTheme.textHint.opacity(0.10))
                                    : (checkedToday ? AnyShapeStyle(BotanicalTheme.primaryGradient) : AnyShapeStyle(BotanicalTheme.primarySoft.opacity(0.65)))
                            )
                            .frame(width: 34, height: 34)
                            .overlay(
                                Circle()
                                    .stroke(
                                        isStopped
                                            ? BotanicalTheme.textHint.opacity(0.28)
                                            : (checkedToday ? Color.clear : BotanicalTheme.primary.opacity(0.38)),
                                        style: StrokeStyle(lineWidth: 1.4, dash: checkedToday || isStopped ? [] : [3, 2.5])
                                    )
                            )

                        if checkedToday && !isStopped {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        } else if isStopped {
                            Image(systemName: "pause")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(BotanicalTheme.textHint)
                        } else {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(BotanicalTheme.primary.opacity(0.75))
                        }
                    }
                }
                .buttonStyle(ScaleBounceButtonStyle(scale: 0.88))
                .disabled(isStopped)

                // 紧凑标题 + 缩小版起步微步 + 轻量日期
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        if habit.isPinned && !isStopped {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 10.5, weight: .semibold))
                                .foregroundColor(BotanicalTheme.accentWarm)
                        }
                        Text(habit.name)
                            .font(.system(size: 15, weight: habit.isCoreHabit && !isStopped ? .semibold : .medium))
                            .foregroundColor(isStopped ? BotanicalTheme.textSecondary : BotanicalTheme.textPrimary)
                            .strikethrough(isStopped, color: BotanicalTheme.textSecondary)
                            .lineLimit(1)
                    }

                    if let starter = habit.starterStep, !starter.isEmpty, !isStopped {
                        HStack(spacing: 4) {
                            Image(systemName: "leaf.arrow.triangle.circlepath")
                                .font(.system(size: 9.5, weight: .bold))
                            Text("起步微步：\(starter)")
                                .font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                        }
                        .foregroundColor(Color(hex: 0x166534))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color(hex: 0xDCFCE7).opacity(0.85))
                        .clipShape(Capsule())
                    }

                    Text(
                        isStopped
                            ? "休眠中"
                            : BotanicalTheme.formatRelativeDate(epochMs: lastCompleteTime)
                    )
                    .font(.system(size: 11.5))
                    .foregroundColor(BotanicalTheme.textSecondary.opacity(0.85))
                }

                Spacer(minLength: 4)

                // 右侧精简次数徽标（不再与左侧重复）
                if habit.totalDays > 0 {
                    Text("\(habit.totalDays)次")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundColor(isStopped ? BotanicalTheme.textHint : BotanicalTheme.primaryDark)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(isStopped ? BotanicalTheme.surfaceMuted : BotanicalTheme.primarySoft.opacity(0.85))
                        .clipShape(Capsule())
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(BotanicalTheme.textHint)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .animation(.easeOut(duration: 0.2), value: isExpanded)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)

            // 无框一体式快捷操作延展区（轻柔发丝分隔线 + 最小起步微步缩小器）
            if isExpanded {
                VStack(spacing: 8) {
                    Rectangle()
                        .fill(BotanicalTheme.primary.opacity(0.08))
                        .frame(height: 0.6)

                    if !isStopped {
                        // 福格微习惯缩小器：把大习惯拆小到 30 秒就能开始
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.right.and.arrow.up.left")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(BotanicalTheme.primary)

                                TextField(
                                    habit.starterStep == nil ? "太难坚持？写一个 30 秒起步微步" : "修改起步微步...",
                                    text: $starterDraft
                                )
                                .font(.system(size: 12.5))
                                .foregroundColor(BotanicalTheme.textPrimary)
                                .focused($isStarterInputFocused)
                                .onChange(of: isStarterInputFocused) { focused in
                                    if focused {
                                        onStarterInputFocused?()
                                    }
                                }
                                .submitLabel(.done)
                                .onSubmit { saveStarterDraft() }

                                if !starterDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Button {
                                        saveStarterDraft()
                                    } label: {
                                        Text("设为微步")
                                            .font(.system(size: 10.5, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(BotanicalTheme.primary)
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Button {
                                        triggerAiShrink()
                                    } label: {
                                        HStack(spacing: 3) {
                                            if isAiShrinking {
                                                ProgressView()
                                                    .tint(BotanicalTheme.primary)
                                                    .scaleEffect(0.65)
                                            }
                                            Text("AI 缩小")
                                                .font(.system(size: 10.5, weight: .bold))
                                        }
                                        .foregroundColor(BotanicalTheme.primaryDark)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(BotanicalTheme.primarySoft.opacity(0.85))
                                        .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isAiShrinking)
                                }

                                if habit.starterStep != nil {
                                    Button {
                                        SensoryFeedbackService.shared.selection()
                                        starterDraft = ""
                                        appState.updateHabitStarterStep(id: habit.id, starterStep: nil)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(BotanicalTheme.textHint)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 10)
                            .frame(height: 36)
                            .background(Color.white.opacity(0.92))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(BotanicalTheme.primary.opacity(0.16), lineWidth: 0.9)
                            )

                            if !aiStarterSuggestions.isEmpty {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("点选一个最轻松的起步微步：")
                                        .font(.system(size: 10.5, weight: .semibold))
                                        .foregroundColor(BotanicalTheme.textSecondary)
                                    ForEach(aiStarterSuggestions, id: \.self) { step in
                                        Button {
                                            SensoryFeedbackService.shared.lightTap()
                                            appState.updateHabitStarterStep(id: habit.id, starterStep: step)
                                            starterDraft = step
                                            withAnimation(.easeOut(duration: 0.2)) {
                                                aiStarterSuggestions = []
                                            }
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: "leaf.fill")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(BotanicalTheme.primary)
                                                Text(step)
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(BotanicalTheme.textPrimary)
                                                    .multilineTextAlignment(.leading)
                                                Spacer(minLength: 4)
                                                Text("采用")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(BotanicalTheme.primaryDark)
                                            }
                                            .padding(.horizontal, 9)
                                            .padding(.vertical, 6)
                                            .background(Color.white.opacity(0.85))
                                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(8)
                                .background(BotanicalTheme.primarySoft.opacity(0.32))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                        .onAppear {
                            if starterDraft.isEmpty, let existing = habit.starterStep {
                                starterDraft = existing
                            }
                        }
                    }

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

                        if !isStopped {
                            squareActionButton(
                                icon: habit.isCoreHabit ? "flame.fill" : "flame",
                                color: Color(hex: 0xD96B27),
                                isHighlighted: habit.isCoreHabit
                            ) {
                                SensoryFeedbackService.shared.lightTap()
                                appState.toggleCoreHabit(id: habit.id)
                            }
                        }

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
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
                .transition(
                    .asymmetric(
                        insertion: .opacity.animation(.easeOut(duration: 0.18).delay(0.05)),
                        removal: .opacity.animation(.easeOut(duration: 0.09))
                    )
                )
            }
        }
        .clipped()
        .lightweightListCard(
            cornerRadius: 19,
            tint: habit.isCoreHabit && !isStopped ? Color(hex: 0xD96B27) : BotanicalTheme.habitAccent
        )
        .overlay(
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .stroke(
                    habit.isCoreHabit && !isStopped
                        ? Color(hex: 0xE6954B).opacity(0.55)
                        : Color.clear,
                    lineWidth: 1.1
                )
        )
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

    private func saveStarterDraft() {
        let trimmed = starterDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        SensoryFeedbackService.shared.lightTap()
        appState.updateHabitStarterStep(id: habit.id, starterStep: trimmed)
        isStarterInputFocused = false
        UIApplication.shared.dismissKeyboard()
    }

    private func triggerAiShrink() {
        if !proStore.isPro {
            appState.showProPaywall = true
            return
        }
        guard appState.requireAiApiConfigured() else { return }
        isAiShrinking = true
        Task {
            do {
                let steps = try await appState.previewAiHabitStarterSteps(habitId: habit.id)
                await MainActor.run {
                    isAiShrinking = false
                    SensoryFeedbackService.shared.lightTap()
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.85)) {
                        aiStarterSuggestions = Array(steps.prefix(3))
                    }
                }
            } catch {
                await MainActor.run {
                    isAiShrinking = false
                }
            }
        }
    }
}
