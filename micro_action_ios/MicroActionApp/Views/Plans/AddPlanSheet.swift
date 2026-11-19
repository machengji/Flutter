import SwiftUI

/// 新建或编辑微行动计划弹窗
struct AddPlanSheet: View {
    var editingPlan: PlanItem? = nil

    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("写下一个具体的微行动目标")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(BotanicalTheme.textSecondary)

                TextField("例如：在网上查一下便宜的全面体检", text: $name, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(14)
                    .background(BotanicalTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(BotanicalTheme.border, lineWidth: 1))

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
                        .frame(height: 48)
                        .background(BotanicalTheme.primaryGradient)
                        .clipShape(Capsule())
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding(20)
            .background(BotanicalTheme.backgroundTop.ignoresSafeArea())
            .navigationTitle(editingPlan == nil ? "新建微行动" : "编辑微行动")
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
            }
        }
        .presentationDetents([.medium])
    }
}
