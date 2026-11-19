import Foundation

/// 计划任务状态
enum PlanStatus: String, Codable, CaseIterable, Sendable {
    case ongoing = "进行中"
    case completed = "已完成"
    case archived = "已归档"
}

/// 微行动计划模型（支持多级子任务分解与自动叶节点前置提升）
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
}
