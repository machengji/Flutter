import Foundation
import WidgetKit

/// 桌面小组件展示用的精简待办愿望项
struct WidgetPlanSummary: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let pendingSubCount: Int
}

/// 桌面小组件展示用的精简每日微习惯项
struct WidgetHabitSummary: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let todayCount: Int
    let isCore: Bool
}

/// 主 App 与桌面/锁屏微步小组件共享的数据快照
struct ShineWidgetSnapshot: Codable, Equatable, Sendable {
    var todayShineCount: Int
    var totalShineCount: Int
    var themeId: String
    var latestActionTitle: String
    var seedColorSeeds: [Int]
    var updatedAtMs: Int64
    var pendingPlans: [WidgetPlanSummary]
    var pendingHabits: [WidgetHabitSummary]
    var totalPendingPlans: Int
    var todayHabitsDone: Int
    var totalHabitsCount: Int
    var treeSpeciesIndex: Int

    init(
        todayShineCount: Int,
        totalShineCount: Int,
        themeId: String,
        latestActionTitle: String,
        seedColorSeeds: [Int],
        updatedAtMs: Int64,
        pendingPlans: [WidgetPlanSummary] = [],
        pendingHabits: [WidgetHabitSummary] = [],
        totalPendingPlans: Int = 0,
        todayHabitsDone: Int = 0,
        totalHabitsCount: Int = 0,
        treeSpeciesIndex: Int = 0
    ) {
        self.todayShineCount = todayShineCount
        self.totalShineCount = totalShineCount
        self.themeId = themeId
        self.latestActionTitle = latestActionTitle
        self.seedColorSeeds = seedColorSeeds
        self.updatedAtMs = updatedAtMs
        self.pendingPlans = pendingPlans
        self.pendingHabits = pendingHabits
        self.totalPendingPlans = totalPendingPlans
        self.todayHabitsDone = todayHabitsDone
        self.totalHabitsCount = totalHabitsCount
        self.treeSpeciesIndex = treeSpeciesIndex
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        todayShineCount = try c.decodeIfPresent(Int.self, forKey: .todayShineCount) ?? 0
        totalShineCount = try c.decodeIfPresent(Int.self, forKey: .totalShineCount) ?? 0
        themeId = try c.decodeIfPresent(String.self, forKey: .themeId) ?? CelebrationThemeSkin.emerald.rawValue
        latestActionTitle = try c.decodeIfPresent(String.self, forKey: .latestActionTitle) ?? "完成一件微小的事，点亮今日星籽"
        seedColorSeeds = try c.decodeIfPresent([Int].self, forKey: .seedColorSeeds) ?? []
        updatedAtMs = try c.decodeIfPresent(Int64.self, forKey: .updatedAtMs) ?? 0
        pendingPlans = try c.decodeIfPresent([WidgetPlanSummary].self, forKey: .pendingPlans) ?? []
        pendingHabits = try c.decodeIfPresent([WidgetHabitSummary].self, forKey: .pendingHabits) ?? []
        totalPendingPlans = try c.decodeIfPresent(Int.self, forKey: .totalPendingPlans) ?? pendingPlans.count
        todayHabitsDone = try c.decodeIfPresent(Int.self, forKey: .todayHabitsDone) ?? 0
        totalHabitsCount = try c.decodeIfPresent(Int.self, forKey: .totalHabitsCount) ?? pendingHabits.count
        treeSpeciesIndex = try c.decodeIfPresent(Int.self, forKey: .treeSpeciesIndex) ?? 0
    }

    static let empty = ShineWidgetSnapshot(
        todayShineCount: 0,
        totalShineCount: 0,
        themeId: CelebrationThemeSkin.emerald.rawValue,
        latestActionTitle: "完成一件微小的事，点亮今日星籽",
        seedColorSeeds: [],
        updatedAtMs: 0,
        pendingPlans: [],
        pendingHabits: [],
        totalPendingPlans: 0,
        todayHabitsDone: 0,
        totalHabitsCount: 0,
        treeSpeciesIndex: 0
    )
}

/// App Group 跨进程共享存储
enum SharedWidgetStore {
    static let appGroupId = "group.com.microaction.assistant"
    private static let snapshotKey = "shine_widget_snapshot_v1"

    private static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupId) ?? .standard
    }

    static func save(_ snapshot: ShineWidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        sharedDefaults.set(data, forKey: snapshotKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func load() -> ShineWidgetSnapshot {
        guard let data = sharedDefaults.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(ShineWidgetSnapshot.self, from: data) else {
            return .empty
        }
        return snapshot
    }
}
