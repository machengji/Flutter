import Foundation
import WidgetKit

/// 主 App 与桌面/锁屏发光星籽罐小组件共享的数据快照
struct ShineWidgetSnapshot: Codable, Equatable, Sendable {
    var todayShineCount: Int
    var totalShineCount: Int
    var themeId: String
    var latestActionTitle: String
    var seedColorSeeds: [Int]
    var updatedAtMs: Int64

    static let empty = ShineWidgetSnapshot(
        todayShineCount: 0,
        totalShineCount: 0,
        themeId: CelebrationThemeSkin.emerald.rawValue,
        latestActionTitle: "完成一件微小的事，点亮今日星籽",
        seedColorSeeds: [],
        updatedAtMs: 0
    )
}

/// App Group 跨进程共享存储（正式签名时在主 App 与 Widget Target 均开启 App Group 即可实时互通）
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
