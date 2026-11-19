import Foundation

/// 习惯状态
enum HabitStatus: String, Codable, CaseIterable, Sendable {
    case active = "进行中"
    case stopped = "已停用"
}

/// 微习惯模型（记录每日打卡时间戳历史与累计次数）
struct HabitItem: Identifiable, Codable, Equatable, Sendable {
    var id: String
    var name: String
    var status: HabitStatus
    var createTime: Int64
    var totalDays: Int
    var completionHistory: [Int64]

    init(
        id: String = UUID().uuidString,
        name: String,
        status: HabitStatus = .active,
        createTime: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        totalDays: Int = 0,
        completionHistory: [Int64] = []
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.createTime = createTime
        self.totalDays = totalDays
        self.completionHistory = completionHistory
    }

    /// 计算今日已打卡次数
    func todayCheckCount(referenceDate: Date = Date()) -> Int {
        let startOfDay = Calendar.current.startOfDay(for: referenceDate)
        let startMs = Int64(startOfDay.timeIntervalSince1970 * 1000)
        return completionHistory.filter { $0 >= startMs }.count
    }
}
