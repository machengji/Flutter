import SwiftUI

/// 新建或编辑时间锚点弹窗（支持每天/工作日/周末/每周/每月周期 + 附加闹钟强提醒）
struct AddAnchorSheet: View {
    var editingAnchor: AnchorItem? = nil

    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedTime: Date = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var repeatCycle: AnchorRepeatCycle = .daily
    @State private var weeklyWeekday: Int = Calendar.current.component(.weekday, from: Date())
    @State private var monthlyDay: Int = Calendar.current.component(.day, from: Date())
    @State private var alarmEnabled: Bool = false

    private let weekdayOptions: [(weekday: Int, short: String)] = [
        (2, "一"), (3, "二"), (4, "三"), (5, "四"), (6, "五"), (7, "六"), (1, "日")
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("绑定一个固定周期发生的生活时刻")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(BotanicalTheme.textSecondary)

                    TextField("例如：早上起床、每周复盘、每月缴水电", text: $name)
                        .font(.system(size: 15))
                        .submitLabel(.done)
                        .onSubmit { submitAnchor() }
                        .padding(14)
                        .liquidGlassCard(cornerRadius: 16, tint: BotanicalTheme.anchorAccent, interactive: false, shadowRadius: 8)

                    DatePicker("提醒时间", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .tint(BotanicalTheme.primary)
                        .padding(14)
                        .liquidGlassCard(cornerRadius: 16, tint: BotanicalTheme.primaryLight, interactive: false, shadowRadius: 8)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("重复周期")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(BotanicalTheme.textSecondary)

                        Picker("重复周期", selection: $repeatCycle) {
                            ForEach(AnchorRepeatCycle.allCases, id: \.self) { cycle in
                                Text(cycle.rawValue).tag(cycle)
                            }
                        }
                        .pickerStyle(.segmented)

                        if repeatCycle == .weekly {
                            HStack(spacing: 6) {
                                ForEach(weekdayOptions, id: \.weekday) { opt in
                                    let active = weeklyWeekday == opt.weekday
                                    Button {
                                        SensoryFeedbackService.shared.selection()
                                        weeklyWeekday = opt.weekday
                                    } label: {
                                        Text(opt.short)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(active ? .white : BotanicalTheme.textPrimary)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 34)
                                            .background(active ? BotanicalTheme.primary : BotanicalTheme.surfaceMuted)
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                    .buttonStyle(ScaleBounceButtonStyle(scale: 0.94))
                                }
                            }
                            .padding(.top, 2)
                            .transition(.opacity)
                        } else if repeatCycle == .monthly {
                            HStack {
                                Text("每月触发日期")
                                    .font(.system(size: 13.5, weight: .semibold))
                                    .foregroundColor(BotanicalTheme.textPrimary)
                                Spacer()
                                Picker("每月几号", selection: $monthlyDay) {
                                    ForEach(1...31, id: \.self) { day in
                                        Text("\(day) 日").tag(day)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(BotanicalTheme.primaryDark)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(BotanicalTheme.surfaceMuted)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .transition(.opacity)
                        }
                    }

                    // 附加闹钟强提醒开关
                    Toggle(isOn: $alarmEnabled) {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 5) {
                                Image(systemName: "alarm.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(BotanicalTheme.anchorAccent)
                                Text("附加闹钟强提醒")
                                    .font(.system(size: 14.5, weight: .bold))
                                    .foregroundColor(BotanicalTheme.textPrimary)
                            }
                            Text("到点开启时效性强提醒并连响 3 次，支持「5 分钟后再响」")
                                .font(.system(size: 11.5))
                                .foregroundColor(BotanicalTheme.textSecondary)
                        }
                    }
                    .tint(BotanicalTheme.anchorAccent)
                    .padding(14)
                    .liquidGlassCard(cornerRadius: 16, tint: BotanicalTheme.anchorAccent, interactive: false, shadowRadius: 6)

                    Button {
                        submitAnchor()
                    } label: {
                        Text(editingAnchor == nil ? "创建时间锚点" : "保存锚点修改")
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
                    .padding(.top, 4)
                }
                .padding(22)
            }
            .liquidSheetCanvasBackground()
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
                    weeklyWeekday = existing.weeklyWeekday
                    monthlyDay = existing.monthlyDay
                    alarmEnabled = existing.alarmEnabled
                    if let hm = existing.hourAndMinute,
                       let date = Calendar.current.date(bySettingHour: hm.hour, minute: hm.minute, second: 0, of: Date()) {
                        selectedTime = date
                    }
                }
            }
        }
        .liquidGlassSheet(detents: [.height(560), .large], cornerRadius: 34)
    }

    private func submitAnchor() {
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
            existing.weeklyWeekday = weeklyWeekday
            existing.monthlyDay = monthlyDay
            existing.alarmEnabled = alarmEnabled
            if alarmEnabled { existing.reminderEnabled = true }
            appState.updateAnchor(existing)
        } else {
            appState.addAnchor(
                name: trimmed,
                triggerTime: timeStr,
                repeatCycle: repeatCycle,
                weeklyWeekday: weeklyWeekday,
                monthlyDay: monthlyDay,
                alarmEnabled: alarmEnabled
            )
        }
        dismiss()
    }
}
