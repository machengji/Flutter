import SwiftUI

/// 新建或编辑微行动愿望弹窗（森系视觉统一升级）
struct AddPlanSheet: View {
    var editingPlan: PlanItem? = nil

    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var isMainContradiction: Bool = false
    @State private var isEasyToHandle: Bool = false
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("写下一个具体的愿望或待解决的问题")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(BotanicalTheme.textSecondary)

                TextField("输入你的愿望...", text: $name)
                    .font(.system(size: 15.5))
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit { submitPlan() }
                    .padding(14)
                    .liquidGlassCard(
                        cornerRadius: 16,
                        tint: isFocused ? BotanicalTheme.primary : BotanicalTheme.primaryLight,
                        interactive: false,
                        shadowRadius: 8
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                isFocused ? BotanicalTheme.primary.opacity(0.65) : Color.clear,
                                lineWidth: 1.6
                            )
                    )

                Toggle(isOn: $isMainContradiction) {
                    HStack(spacing: 8) {
                        Image(systemName: isMainContradiction ? "flame.fill" : "flame")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(isMainContradiction ? Color(hex: 0xD96B27) : BotanicalTheme.textSecondary)
                        Text("设为主要矛盾（优先解决）")
                            .font(.system(size: 14.5, weight: .medium))
                            .foregroundColor(BotanicalTheme.textPrimary)
                    }
                }
                .tint(Color(hex: 0xD96B27))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .liquidGlassCard(
                    cornerRadius: 14,
                    tint: isMainContradiction ? Color(hex: 0xD96B27) : BotanicalTheme.primaryLight,
                    interactive: false,
                    shadowRadius: 6
                )

                Toggle(isOn: $isEasyToHandle) {
                    HStack(spacing: 8) {
                        Image(systemName: isEasyToHandle ? "bolt.fill" : "bolt")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(isEasyToHandle ? Color(hex: 0xD97706) : BotanicalTheme.textSecondary)
                        Text("设为很好处理（碎片时间优先搞定）")
                            .font(.system(size: 14.5, weight: .medium))
                            .foregroundColor(BotanicalTheme.textPrimary)
                    }
                }
                .tint(Color(hex: 0xD97706))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .liquidGlassCard(
                    cornerRadius: 14,
                    tint: isEasyToHandle ? Color(hex: 0xD97706) : BotanicalTheme.primaryLight,
                    interactive: false,
                    shadowRadius: 6
                )

                Button {
                    submitPlan()
                } label: {
                    Text(editingPlan == nil ? "添加愿望" : "保存修改")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(BotanicalTheme.primaryGradient)
                        .clipShape(Capsule())
                        .shadow(color: BotanicalTheme.primary.opacity(0.25), radius: 12, y: 5)
                }
                .buttonStyle(ScaleBounceButtonStyle(scale: 0.97))
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding(22)
            .liquidSheetCanvasBackground()
            .navigationTitle(editingPlan == nil ? "新愿望" : "编辑愿望")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(BotanicalTheme.textSecondary)
                }
            }
            .onAppear {
                if let existing = editingPlan {
                    name = existing.name
                    isMainContradiction = existing.isMainContradiction
                    isEasyToHandle = existing.isEasyToHandle
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    isFocused = true
                }
            }
        }
        .liquidGlassSheet(detents: [.height(420), .medium], cornerRadius: 34)
    }

    private func submitPlan() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        SensoryFeedbackService.shared.lightTap()
        if let existing = editingPlan {
            appState.updatePlanName(id: existing.id, newName: trimmed)
            appState.setMainContradiction(id: existing.id, value: isMainContradiction)
            appState.setEasyToHandle(id: existing.id, value: isEasyToHandle)
        } else {
            appState.addPlan(
                name: trimmed,
                isMainContradiction: isMainContradiction,
                isEasyToHandle: isEasyToHandle
            )
        }
        dismiss()
    }
}
