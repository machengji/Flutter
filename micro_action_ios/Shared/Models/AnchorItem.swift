import Foundation

/// 锚点重复周期
enum AnchorRepeatCycle: String, Codable, CaseIterable, Sendable {
    case daily = "每天"
    case weekdays = "工作日"
    case weekends = "周末"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = (try? container.decode(String.self))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        switch raw {
        case "工作日", "weekdays":
            self = .weekdays
        case "周末", "休息日", "weekends":
            self = .weekends
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
    var reminderEnabled: Bool
    var planIds: [String]
    var habitIds: [String]
    var createTime: Int64

    enum CodingKeys: String, CodingKey {
        case id, name, triggerTime, time, repeatCycle, repeatMode
        case reminderEnabled, isReminderEnabled, planIds, habitIds, createTime
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        triggerTime: String = "08:30",
        repeatCycle: AnchorRepeatCycle = .daily,
        reminderEnabled: Bool = true,
        planIds: [String] = [],
        habitIds: [String] = [],
        createTime: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.name = name
        self.triggerTime = triggerTime
        self.repeatCycle = repeatCycle
        self.reminderEnabled = reminderEnabled
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
        let nativeRem = try c.decodeIfPresent(Bool.self, forKey: .reminderEnabled)
        let flutterRem = try c.decodeIfPresent(Bool.self, forKey: .isReminderEnabled)
        reminderEnabled = nativeRem ?? flutterRem ?? true
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
        try c.encode(reminderEnabled, forKey: .reminderEnabled)
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
}
