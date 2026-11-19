import Foundation

/// 完整本地数据快照（用于本地持久化与 JSON 备份导入导出）
struct AppBackupData: Codable, Equatable, Sendable {
    var plans: [PlanItem]
    var habits: [HabitItem]
    var anchors: [AnchorItem]
    var shineRecords: [ShineRecord]
    var customAffirmations: [String]
    var rainbowRatio: Int
    var soundEnabled: Bool
    var aiPersona: AiCelebrationPersona
    var themeSkin: CelebrationThemeSkin
    var soundPack: CelebrationSoundPack
    var autoCalendarFootprint: Bool
    var twoWayRemindersSync: Bool

    static let empty = AppBackupData(
        plans: [],
        habits: [],
        anchors: [],
        shineRecords: [],
        customAffirmations: [],
        rainbowRatio: 80,
        soundEnabled: true,
        aiPersona: .sweetBestie,
        themeSkin: .emerald,
        soundPack: .crystalBell,
        autoCalendarFootprint: true,
        twoWayRemindersSync: false
    )
}

/// 本地 JSON 持久化服务（数据默认全部存储于用户设备本地）
final class LocalStoreService {
    private let fileURL: URL

    init(fileName: String = "micro_action_store_v2.json") {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = docs.appendingPathComponent(fileName)
    }

    init(customURL: URL) {
        self.fileURL = customURL
    }

    func load() -> AppBackupData {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode(AppBackupData.self, from: data) else {
            return .empty
        }
        return decoded
    }

    func save(_ state: AppBackupData) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(state)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[LocalStoreService] 保存失败: \(error)")
        }
    }

    func exportJSONString(_ state: AppBackupData) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(state)
        guard let str = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "LocalStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "JSON 编码失败"])
        }
        return str
    }

    func decodeJSONString(_ raw: String) throws -> AppBackupData {
        var clean = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("\u{FEFF}") {
            clean.removeFirst()
        }
        guard let data = clean.data(using: .utf8) else {
            throw NSError(domain: "LocalStore", code: -2, userInfo: [NSLocalizedDescriptionKey: "无效文本格式"])
        }
        return try JSONDecoder().decode(AppBackupData.self, from: data)
    }
}
