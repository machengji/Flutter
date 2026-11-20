import SwiftUI

/// 新建或编辑微习惯弹窗（森系视觉统一升级）
struct AddHabitSheet: View {
    var editingHabit: HabitItem? = nil

    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var isCoreHabit: Bool = false
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("写下一个低阻力、每天都能做到的微习惯")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(BotanicalTheme.textSecondary)

                TextField("输入你的习惯...", text: $name)
                    .font(.system(size: 15.5))
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit { submitHabit() }
                    .padding(14)
                    .liquidGlassCard(
                        cornerRadius: 16,
                        tint: isFocused ? BotanicalTheme.secondary : BotanicalTheme.primaryLight,
                        interactive: false,
                        shadowRadius: 8
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                isFocused ? BotanicalTheme.secondary.opacity(0.65) : Color.clear,
                                lineWidth: 1.6
                            )
                    )

                Toggle(isOn: $isCoreHabit) {
                    HStack(spacing: 8) {
                        Image(systemName: isCoreHabit ? "flame.fill" : "flame")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(isCoreHabit ? Color(hex: 0xD96B27) : BotanicalTheme.textSecondary)
                        Text("设为核心习惯（优先坚持）")
                            .font(.system(size: 14.5, weight: .medium))
                            .foregroundColor(BotanicalTheme.textPrimary)
                    }
                }
                .tint(Color(hex: 0xD96B27))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .liquidGlassCard(
                    cornerRadius: 14,
                    tint: isCoreHabit ? Color(hex: 0xD96B27) : BotanicalTheme.primaryLight,
                    interactive: false,
                    shadowRadius: 6
                )

                Button {
                    submitHabit()
                } label: {
                    Text(editingHabit == nil ? "创建微习惯" : "保存修改")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(BotanicalTheme.secondaryGradient)
                        .clipShape(Capsule())
                        .shadow(color: BotanicalTheme.secondary.opacity(0.25), radius: 12, y: 5)
                }
                .buttonStyle(ScaleBounceButtonStyle(scale: 0.97))
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding(22)
            .liquidSheetCanvasBackground()
            .navigationTitle(editingHabit == nil ? "新习惯" : "编辑习惯")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(BotanicalTheme.textSecondary)
                }
            }
            .onAppear {
                if let existing = editingHabit {
                    name = existing.name
                    isCoreHabit = existing.isCoreHabit
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    isFocused = true
                }
            }
        }
        .liquidGlassSheet(detents: [.height(340), .medium], cornerRadius: 34)
    }

    private func submitHabit() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        SensoryFeedbackService.shared.lightTap()
        if let existing = editingHabit {
            appState.updateHabitName(id: existing.id, newName: trimmed)
            appState.setCoreHabit(id: existing.id, value: isCoreHabit)
        } else {
            appState.addHabit(name: trimmed, isCoreHabit: isCoreHabit)
        }
        dismiss()
    }
}
