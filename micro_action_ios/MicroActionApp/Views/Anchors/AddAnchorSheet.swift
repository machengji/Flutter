import SwiftUI

/// 新建或编辑时间锚点弹窗
struct AddAnchorSheet: View {
    var editingAnchor: AnchorItem? = nil

    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedTime: Date = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var repeatCycle: AnchorRepeatCycle = .daily

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("绑定一个每天固定发生的生活时刻")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(BotanicalTheme.textSecondary)

                TextField("例如：早上起床、午饭后、睡觉前", text: $name)
                    .font(.system(size: 15))
                    .padding(14)
                    .background(BotanicalTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(BotanicalTheme.anchorAccent.opacity(0.28), lineWidth: 1.2)
                    )

                DatePicker("提醒时间", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .tint(BotanicalTheme.primary)
                    .padding(14)
                    .background(BotanicalTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(BotanicalTheme.border, lineWidth: 1)
                    )

                Picker("重复周期", selection: $repeatCycle) {
                    ForEach(AnchorRepeatCycle.allCases, id: \.self) { cycle in
                        Text(cycle.rawValue).tag(cycle)
                    }
                }
                .pickerStyle(.segmented)

                Button {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    SensoryFeedbackService.shared.lightTap()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    let timeStr = formatter.string(from: selectedTime)

                    if var existing = editingAnchor {
                        existing.name = trimmed
                        existing.triggerTime = timeStr
                        existing.repeatCycle = repeatCycle
                        appState.updateAnchor(existing)
                    } else {
                        appState.addAnchor(
                            name: trimmed,
                            triggerTime: timeStr,
                            repeatCycle: repeatCycle
                        )
                    }
                    dismiss()
                } label: {
                    Text(editingAnchor == nil ? "创建时间锚点" : "保存锚点修改")
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
            .navigationTitle(editingAnchor == nil ? "新建时间锚点" : "编辑时间锚点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(BotanicalTheme.textSecondary)
                }
            }
            .onAppear {
                if let existing = editingAnchor {
                    name = existing.name
                    repeatCycle = existing.repeatCycle
                    if let hm = existing.hourAndMinute,
                       let date = Calendar.current.date(bySettingHour: hm.hour, minute: hm.minute, second: 0, of: Date()) {
                        selectedTime = date
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
