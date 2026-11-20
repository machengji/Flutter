import SwiftUI

/// 现代 iOS 液态玻璃悬浮快捷录入条（紧贴键盘上方丝滑弹出，彻底替代臃肿半屏弹框）
/// 支持一键在「新愿望 / 新习惯 / 新锚点」之间弹性切换，输入后回车或轻点发送按钮即可秒速入列
struct QuickAddFloatingBar: View {
    @Binding var isPresented: Bool
    let initialMode: Mode

    enum Mode: String, CaseIterable {
        case plan = "新愿望"
        case habit = "新习惯"
        case anchor = "新锚点"

        var icon: String {
            switch self {
            case .plan: return "checkmark.square.fill"
            case .habit: return "leaf.fill"
            case .anchor: return "clock.fill"
            }
        }

        var placeholder: String {
            switch self {
            case .plan: return "写下一个现在想实现的愿望或待解决问题..."
            case .habit: return "写下一个每天都能轻松做到的微习惯..."
            case .anchor: return "例如：早上起床后、午饭前、睡前..."
            }
        }
    }

    @EnvironmentObject private var appState: AppState

    @State private var mode: Mode = .plan
    @State private var inputText: String = ""
    @State private var anchorTime: Date = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var anchorCycle: AnchorRepeatCycle = .daily
    @FocusState private var isInputFocused: Bool
    @Namespace private var modePillNS

    private var canSubmit: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // 轻柔全屏透明遮罩，轻点任意空白处丝滑收起键盘与快录条
            Color.black.opacity(0.18)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { dismissBar() }
                .transition(.opacity)

            // 紧贴键盘上方的液态玻璃悬浮快录卡
            VStack(alignment: .leading, spacing: 12) {
                // 顶部：类型切换小药丸 + 关闭微钮
                HStack(spacing: 6) {
                    ForEach(Mode.allCases, id: \.self) { item in
                        let selected = mode == item
                        Button {
                            SensoryFeedbackService.shared.selection()
                            withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                                mode = item
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 11, weight: .bold))
                                Text(item.rawValue)
                                    .font(.system(size: 12.5, weight: selected ? .bold : .medium))
                            }
                            .foregroundColor(selected ? .white : BotanicalTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6.5)
                            .background {
                                if selected {
                                    Capsule()
                                        .fill(BotanicalTheme.primaryGradient)
                                        .matchedGeometryEffect(id: "QuickAddModePill", in: modePillNS)
                                } else {
                                    Capsule()
                                        .fill(BotanicalTheme.primary.opacity(0.07))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    Button {
                        dismissBar()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(BotanicalTheme.textSecondary)
                            .frame(width: 28, height: 28)
                            .background(Color.black.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                // 锚点专属扩展行（仅选「新锚点」时弹簧展开）
                if mode == .anchor {
                    HStack(spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "alarm.fill")
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(BotanicalTheme.anchorAccent)
                            DatePicker("", selection: $anchorTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .tint(BotanicalTheme.primary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(BotanicalTheme.anchorAccent.opacity(0.10))
                        .clipShape(Capsule())

                        Spacer()

                        Picker("周期", selection: $anchorCycle) {
                            ForEach(AnchorRepeatCycle.allCases, id: \.self) { cycle in
                                Text(cycle.rawValue).tag(cycle)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 164)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // 主输入行：极简无压迫感输入框 + 圆形发送按钮
                HStack(alignment: .center, spacing: 10) {
                    TextField(mode.placeholder, text: $inputText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(BotanicalTheme.textPrimary)
                        .focused($isInputFocused)
                        .submitLabel(.done)
                        .onSubmit { submit() }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(Color.white.opacity(0.76))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(
                                    isInputFocused ? BotanicalTheme.primary.opacity(0.45) : BotanicalTheme.border.opacity(0.75),
                                    lineWidth: 1.2
                                )
                        )

                    Button {
                        submit()
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                canSubmit
                                    ? AnyShapeStyle(BotanicalTheme.primaryGradient)
                                    : AnyShapeStyle(BotanicalTheme.textHint.opacity(0.45))
                            )
                            .clipShape(Circle())
                            .shadow(
                                color: canSubmit ? BotanicalTheme.primary.opacity(0.30) : .clear,
                                radius: 10,
                                y: 4
                            )
                            .scaleEffect(canSubmit ? 1.0 : 0.92)
                            .animation(.spring(response: 0.24, dampingFraction: 0.72), value: canSubmit)
                    }
                    .buttonStyle(ScaleBounceButtonStyle(scale: 0.90))
                    .disabled(!canSubmit)
                    .accessibilityLabel("确认添加")
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.white.opacity(0.98))
                    .shadow(color: Color.black.opacity(0.10), radius: 14, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(BotanicalTheme.primaryLight.opacity(0.65), lineWidth: 1.0)
            )
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .onAppear {
            mode = initialMode
            // 立即同步拉起键盘，与系统键盘动画一气呵成，消除二段停顿卡顿
            isInputFocused = true
        }
    }

    private func submit() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        SensoryFeedbackService.shared.lightTap()

        switch mode {
        case .plan:
            appState.addPlan(name: trimmed)
        case .habit:
            appState.addHabit(name: trimmed)
        case .anchor:
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            appState.addAnchor(
                name: trimmed,
                triggerTime: formatter.string(from: anchorTime),
                repeatCycle: anchorCycle
            )
        }

        inputText = ""
        dismissBar()
    }

    private func dismissBar() {
        isInputFocused = false
        withAnimation(.easeOut(duration: 0.18)) {
            isPresented = false
        }
    }
}
