import Foundation

/// 习惯状态
enum HabitStatus: String, Codable, CaseIterable, Sendable {
    case active = "进行中"
    case stopped = "已停用"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = (try? container.decode(String.self))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        switch raw {
        case "已停用", "已停止", "stopped", "paused":
            self = .stopped
        default:
            self = .active
        }
    }
}

/// 微习惯模型（记录每日打卡时间戳历史与累计次数，完整兼容 Flutter 历史导出 JSON）
struct HabitItem: Identifiable, Codable, Equatable, Sendable {
    var id: String
    var name: String
    var status: HabitStatus
    var createTime: Int64
    var totalDays: Int
    var completionHistory: [Int64]
    var isPinned: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, status, createTime, totalDays, completionHistory, isPinned
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        status: HabitStatus = .active,
        createTime: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        totalDays: Int = 0,
        completionHistory: [Int64] = [],
        isPinned: Bool = false
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.createTime = createTime
        self.totalDays = totalDays
        self.completionHistory = completionHistory
        self.isPinned = isPinned
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        status = (try? container.decode(HabitStatus.self, forKey: .status)) ?? .active
        createTime = (try? container.decode(Int64.self, forKey: .createTime)) ?? Int64(Date().timeIntervalSince1970 * 1000)
        totalDays = try container.decodeIfPresent(Int.self, forKey: .totalDays) ?? 0
        completionHistory = try container.decodeIfPresent([Int64].self, forKey: .completionHistory) ?? []
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
    }

    /// 计算今日已打卡次数
    func todayCheckCount(referenceDate: Date = Date()) -> Int {
        let startOfDay = Calendar.current.startOfDay(for: referenceDate)
        let startMs = Int64(startOfDay.timeIntervalSince1970 * 1000)
        return completionHistory.filter { $0 >= startMs }.count
    }
}
