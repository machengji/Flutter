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
    static let builtinCelebrateId = "builtin_core_celebrate_habit"
    static let builtinSimplifyId = "builtin_core_simplify_habit"

    static func isBuiltinLockedId(_ id: String) -> Bool {
        id == builtinCelebrateId || id == builtinSimplifyId
    }

    var isBuiltinLocked: Bool { Self.isBuiltinLockedId(id) }

    var builtinPriority: Int {
        switch id {
        case Self.builtinCelebrateId: return 0
        case Self.builtinSimplifyId: return 1
        default: return 99
        }
    }

    /// 双基石常驻核心习惯的具体原理与实操介绍
    var builtinGuideText: String? {
        switch id {
        case Self.builtinCelebrateId:
            return "福格行为模型核心：大脑靠「即时正向情绪」记住好习惯。每做完一件小事，立刻微笑、握拳或长按发光庆祝一次，就能把新行动稳稳刻进神经回路。"
        case Self.builtinSimplifyId:
            return "行动卡住往往不是意志力不够，而是第一步阻力太大。把太难的事不断拆小到「30 秒就能无痛动手」的微步，先动起来就赢了一半。"
        default:
            return nil
        }
    }

    var id: String
    var name: String
    var status: HabitStatus
    var createTime: Int64
    var totalDays: Int
    var completionHistory: [Int64]
    var isPinned: Bool
    var isCoreHabit: Bool
    var starterStep: String?

    enum CodingKeys: String, CodingKey {
        case id, name, status, createTime, totalDays, completionHistory, isPinned, isCoreHabit, starterStep
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        status: HabitStatus = .active,
        createTime: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        totalDays: Int = 0,
        completionHistory: [Int64] = [],
        isPinned: Bool = false,
        isCoreHabit: Bool = false,
        starterStep: String? = nil
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.createTime = createTime
        self.totalDays = totalDays
        self.completionHistory = completionHistory
        self.isPinned = isPinned
        self.isCoreHabit = isCoreHabit
        self.starterStep = starterStep
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
        isCoreHabit = try container.decodeIfPresent(Bool.self, forKey: .isCoreHabit) ?? false
        starterStep = try container.decodeIfPresent(String.self, forKey: .starterStep)
    }

    /// 计算今日已打卡次数
    func todayCheckCount(referenceDate: Date = Date()) -> Int {
        let startOfDay = Calendar.current.startOfDay(for: referenceDate)
        let startMs = Int64(startOfDay.timeIntervalSince1970 * 1000)
        return completionHistory.filter { $0 >= startMs }.count
    }
}
