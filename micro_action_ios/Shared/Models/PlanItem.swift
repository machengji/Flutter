import Foundation

/// 计划任务状态
enum PlanStatus: String, Codable, CaseIterable, Sendable {
    case ongoing = "进行中"
    case completed = "已完成"
    case archived = "已归档"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = (try? container.decode(String.self))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        switch raw {
        case "已完成", "completed", "done":
            self = .completed
        case "已归档", "archived":
            self = .archived
        case "未开始", "进行中", "ongoing", "pending", "":
            self = .ongoing
        default:
            self = .ongoing
        }
    }
}

/// 微行动计划模型（支持多级子任务分解与自动叶节点前置提升，完整兼容 Flutter 历史导出 JSON）
struct PlanItem: Identifiable, Codable, Equatable, Sendable {
    var id: String
    var name: String
    var status: PlanStatus
    var createTime: Int64
    var completeTime: Int64?
    var isPinned: Bool
    var parentId: String?
    var decompositionLevel: Int
    var groupColorIndex: Int
    var reminderIdentifier: String?
    var calendarEventId: String?
    var dueDateMs: Int64?

    enum CodingKeys: String, CodingKey {
        case id, name, status, createTime, completeTime, isPinned, parentId
        case decompositionLevel, groupColorIndex, reminderIdentifier, reminderId
        case calendarEventId, dueDateMs
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        status: PlanStatus = .ongoing,
        createTime: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        completeTime: Int64? = nil,
        isPinned: Bool = false,
        parentId: String? = nil,
        decompositionLevel: Int = 0,
        groupColorIndex: Int = -1,
        reminderIdentifier: String? = nil,
        calendarEventId: String? = nil,
        dueDateMs: Int64? = nil
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.createTime = createTime
        self.completeTime = completeTime
        self.isPinned = isPinned
        self.parentId = parentId
        self.decompositionLevel = decompositionLevel
        self.groupColorIndex = groupColorIndex
        self.reminderIdentifier = reminderIdentifier
        self.calendarEventId = calendarEventId
        self.dueDateMs = dueDateMs
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        status = (try? c.decode(PlanStatus.self, forKey: .status)) ?? .ongoing
        createTime = (try? c.decode(Int64.self, forKey: .createTime)) ?? Int64(Date().timeIntervalSince1970 * 1000)
        completeTime = try c.decodeIfPresent(Int64.self, forKey: .completeTime)
        isPinned = try c.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        parentId = try c.decodeIfPresent(String.self, forKey: .parentId)
        decompositionLevel = try c.decodeIfPresent(Int.self, forKey: .decompositionLevel) ?? 0
        groupColorIndex = try c.decodeIfPresent(Int.self, forKey: .groupColorIndex) ?? -1
        let nativeRem = try c.decodeIfPresent(String.self, forKey: .reminderIdentifier)
        let flutterRem = try c.decodeIfPresent(String.self, forKey: .reminderId)
        reminderIdentifier = nativeRem ?? flutterRem
        calendarEventId = try c.decodeIfPresent(String.self, forKey: .calendarEventId)
        dueDateMs = try c.decodeIfPresent(Int64.self, forKey: .dueDateMs)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(status, forKey: .status)
        try c.encode(createTime, forKey: .createTime)
        try c.encodeIfPresent(completeTime, forKey: .completeTime)
        try c.encode(isPinned, forKey: .isPinned)
        try c.encodeIfPresent(parentId, forKey: .parentId)
        try c.encode(decompositionLevel, forKey: .decompositionLevel)
        try c.encode(groupColorIndex, forKey: .groupColorIndex)
        try c.encodeIfPresent(reminderIdentifier, forKey: .reminderIdentifier)
        try c.encodeIfPresent(calendarEventId, forKey: .calendarEventId)
        try c.encodeIfPresent(dueDateMs, forKey: .dueDateMs)
    }
}
