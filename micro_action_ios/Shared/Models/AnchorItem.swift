import Foundation

/// 锚点重复周期
enum AnchorRepeatCycle: String, Codable, CaseIterable, Sendable {
    case daily = "每天"
    case weekdays = "工作日"
    case weekends = "周末"
    case weekly = "每周"
    case monthly = "每月"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = (try? container.decode(String.self))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        switch raw {
        case "工作日", "weekdays":
            self = .weekdays
        case "周末", "休息日", "weekends":
            self = .weekends
        case "每周", "每周一次", "weekly":
            self = .weekly
        case "每月", "每月一次", "monthly":
            self = .monthly
        default:
            self = .daily
        }
    }
}

/// 福格时间锚点模型（完整兼容 Flutter 历史导出 JSON 的 time / repeatMode / isReminderEnabled 字段）
struct AnchorItem: Identifiable, Codable, Equatable, Sendable {
    var id: String
    var name: String
    var triggerTime: String // "HH:mm"
    var repeatCycle: AnchorRepeatCycle
    var weeklyWeekday: Int // 1=周日, 2=周一 ... 7=周六
    var monthlyDay: Int    // 1...31
    var reminderEnabled: Bool
    var alarmEnabled: Bool // 是否开启附加闹钟强提醒（时效性通知 + 间隔连响 3 次 + 5 分钟再响）
    var planIds: [String]
    var habitIds: [String]
    var createTime: Int64

    enum CodingKeys: String, CodingKey {
        case id, name, triggerTime, time, repeatCycle, repeatMode
        case weeklyWeekday, monthlyDay, reminderEnabled, isReminderEnabled, alarmEnabled
        case planIds, habitIds, createTime
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        triggerTime: String = "08:30",
        repeatCycle: AnchorRepeatCycle = .daily,
        weeklyWeekday: Int = 2,
        monthlyDay: Int = 1,
        reminderEnabled: Bool = true,
        alarmEnabled: Bool = false,
        planIds: [String] = [],
        habitIds: [String] = [],
        createTime: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.name = name
        self.triggerTime = triggerTime
        self.repeatCycle = repeatCycle
        self.weeklyWeekday = min(7, max(1, weeklyWeekday))
        self.monthlyDay = min(31, max(1, monthlyDay))
        self.reminderEnabled = reminderEnabled
        self.alarmEnabled = alarmEnabled
        self.planIds = planIds
        self.habitIds = habitIds
        self.createTime = createTime
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        let nativeTime = try c.decodeIfPresent(String.self, forKey: .triggerTime)
        let flutterTime = try c.decodeIfPresent(String.self, forKey: .time)
        triggerTime = nativeTime ?? flutterTime ?? "08:30"
        let nativeCycle = try c.decodeIfPresent(AnchorRepeatCycle.self, forKey: .repeatCycle)
        let flutterCycle = try c.decodeIfPresent(AnchorRepeatCycle.self, forKey: .repeatMode)
        repeatCycle = nativeCycle ?? flutterCycle ?? .daily
        weeklyWeekday = min(7, max(1, try c.decodeIfPresent(Int.self, forKey: .weeklyWeekday) ?? 2))
        monthlyDay = min(31, max(1, try c.decodeIfPresent(Int.self, forKey: .monthlyDay) ?? 1))
        let nativeRem = try c.decodeIfPresent(Bool.self, forKey: .reminderEnabled)
        let flutterRem = try c.decodeIfPresent(Bool.self, forKey: .isReminderEnabled)
        reminderEnabled = nativeRem ?? flutterRem ?? true
        alarmEnabled = try c.decodeIfPresent(Bool.self, forKey: .alarmEnabled) ?? false
        planIds = try c.decodeIfPresent([String].self, forKey: .planIds) ?? []
        habitIds = try c.decodeIfPresent([String].self, forKey: .habitIds) ?? []
        createTime = try c.decodeIfPresent(Int64.self, forKey: .createTime) ?? Int64(Date().timeIntervalSince1970 * 1000)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(triggerTime, forKey: .triggerTime)
        try c.encode(repeatCycle, forKey: .repeatCycle)
        try c.encode(weeklyWeekday, forKey: .weeklyWeekday)
        try c.encode(monthlyDay, forKey: .monthlyDay)
        try c.encode(reminderEnabled, forKey: .reminderEnabled)
        try c.encode(alarmEnabled, forKey: .alarmEnabled)
        try c.encode(planIds, forKey: .planIds)
        try c.encode(habitIds, forKey: .habitIds)
        try c.encode(createTime, forKey: .createTime)
    }

    var hourAndMinute: (hour: Int, minute: Int)? {
        let parts = triggerTime.split(separator: ":")
        guard parts.count == 2,
              let h = Int(parts[0]),
              let m = Int(parts[1]),
              (0...23).contains(h),
              (0...59).contains(m) else {
            return nil
        }
        return (h, m)
    }

    static func weekdayDisplayName(_ weekday: Int) -> String {
        switch weekday {
        case 1: return "周日"
        case 2: return "周一"
        case 3: return "周二"
        case 4: return "周三"
        case 5: return "周四"
        case 6: return "周五"
        case 7: return "周六"
        default: return "周一"
        }
    }

    /// 完整可读周期描述（如「每天」「每周三」「每月15日」）
    var scheduleLabel: String {
        switch repeatCycle {
        case .daily: return "每天"
        case .weekdays: return "工作日"
        case .weekends: return "周末"
        case .weekly: return "每\(Self.weekdayDisplayName(weeklyWeekday))"
        case .monthly: return "每月\(monthlyDay)日"
        }
    }
}
