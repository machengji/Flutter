import Foundation

/// 锚点重复周期
enum AnchorRepeatCycle: String, Codable, CaseIterable, Sendable {
    case daily = "每天"
    case weekdays = "工作日"
    case weekends = "周末"
}

/// 福格时间锚点模型（将已有日常场景与微行动/微习惯绑定）
struct AnchorItem: Identifiable, Codable, Equatable, Sendable {
    var id: String
    var name: String
    var triggerTime: String // "HH:mm"
    var repeatCycle: AnchorRepeatCycle
    var reminderEnabled: Bool
    var planIds: [String]
    var habitIds: [String]
    var createTime: Int64

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
