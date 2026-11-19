import SwiftUI

/// 新建或编辑微行动计划弹窗（森系视觉统一升级）
struct AddPlanSheet: View {
    var editingPlan: PlanItem? = nil

    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("写下一个具体的微行动目标")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(BotanicalTheme.textSecondary)

                TextField("输入你的梦想...", text: $name, axis: .vertical)
                    .font(.system(size: 15.5))
                    .lineLimit(2...4)
                    .focused($isFocused)
                    .padding(14)
                    .background(BotanicalTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                isFocused ? BotanicalTheme.primary : BotanicalTheme.border,
                                lineWidth: isFocused ? 1.8 : 1
                            )
                    )

                Button {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    SensoryFeedbackService.shared.lightTap()
                    if let existing = editingPlan {
                        appState.updatePlanName(id: existing.id, newName: trimmed)
                    } else {
                        appState.addPlan(name: trimmed)
                    }
                    dismiss()
                } label: {
                    Text(editingPlan == nil ? "添加计划" : "保存修改")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(BotanicalTheme.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: BotanicalTheme.primary.opacity(0.25), radius: 12, y: 5)
                }
                .buttonStyle(ScaleBounceButtonStyle(scale: 0.97))
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding(22)
            .background(BotanicalTheme.backgroundBottom.ignoresSafeArea())
            .navigationTitle(editingPlan == nil ? "新计划" : "编辑计划")
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
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    isFocused = true
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
