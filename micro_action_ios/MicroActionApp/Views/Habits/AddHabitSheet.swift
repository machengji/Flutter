import SwiftUI

/// 新建或编辑微习惯弹窗
struct AddHabitSheet: View {
    var editingHabit: HabitItem? = nil

    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("写下一个低阻力、每天都能做到的微习惯")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(BotanicalTheme.textSecondary)

                TextField("例如：早睡、多读书、喝一杯温水", text: $name)
                    .padding(14)
                    .background(BotanicalTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(BotanicalTheme.border, lineWidth: 1))

                Button {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    SensoryFeedbackService.shared.lightTap()
                    if let existing = editingHabit {
                        appState.updateHabitName(id: existing.id, newName: trimmed)
                    } else {
                        appState.addHabit(name: trimmed)
                    }
                    dismiss()
                } label: {
                    Text(editingHabit == nil ? "创建微习惯" : "保存修改")
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
            .navigationTitle(editingHabit == nil ? "新建微习惯" : "编辑微习惯")
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
                }
            }
        }
        .presentationDetents([.medium])
    }
}
