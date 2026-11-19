import SwiftUI

/// 新建时间锚点弹窗
struct AddAnchorSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedTime: Date = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var repeatCycle: AnchorRepeatCycle = .daily

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("绑定一个每天固定发生的生活时刻")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(BotanicalTheme.textSecondary)

                TextField("例如：早上起床、午饭后、睡觉前", text: $name)
                    .padding(14)
                    .background(BotanicalTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(BotanicalTheme.border, lineWidth: 1))

                DatePicker("提醒时间", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .padding(14)
                    .background(BotanicalTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Picker("重复周期", selection: $repeatCycle) {
                    ForEach(AnchorRepeatCycle.allCases, id: \.self) { cycle in
                        Text(cycle.rawValue).tag(cycle)
                    }
                }
                .pickerStyle(.segmented)

                Button {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    appState.addAnchor(
                        name: trimmed,
                        triggerTime: formatter.string(from: selectedTime),
                        repeatCycle: repeatCycle
                    )
                    dismiss()
                } label: {
                    Text("创建时间锚点")
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
            .navigationTitle("新建时间锚点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(BotanicalTheme.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
