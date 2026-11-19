import Foundation

/// 完整本地数据快照（同时兼容原生 v2 JSON 与 Flutter 历史版本导出的 schemaVersion 2 JSON）
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

    enum CodingKeys: String, CodingKey {
        case plans, habits, anchors, shineRecords, customAffirmations
        case rainbowRatio, celebrationRainbowRatio
        case soundEnabled, celebrationSoundEnabled
        case aiPersona, themeSkin, soundPack
        case autoCalendarFootprint, twoWayRemindersSync
    }

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

    init(
        plans: [PlanItem],
        habits: [HabitItem],
        anchors: [AnchorItem],
        shineRecords: [ShineRecord],
        customAffirmations: [String],
        rainbowRatio: Int,
        soundEnabled: Bool,
        aiPersona: AiCelebrationPersona,
        themeSkin: CelebrationThemeSkin,
        soundPack: CelebrationSoundPack,
        autoCalendarFootprint: Bool,
        twoWayRemindersSync: Bool
    ) {
        self.plans = plans
        self.habits = habits
        self.anchors = anchors
        self.shineRecords = shineRecords
        self.customAffirmations = customAffirmations
        self.rainbowRatio = rainbowRatio
        self.soundEnabled = soundEnabled
        self.aiPersona = aiPersona
        self.themeSkin = themeSkin
        self.soundPack = soundPack
        self.autoCalendarFootprint = autoCalendarFootprint
        self.twoWayRemindersSync = twoWayRemindersSync
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        plans = try c.decodeIfPresent([PlanItem].self, forKey: .plans) ?? []
        habits = try c.decodeIfPresent([HabitItem].self, forKey: .habits) ?? []
        anchors = try c.decodeIfPresent([AnchorItem].self, forKey: .anchors) ?? []
        shineRecords = try c.decodeIfPresent([ShineRecord].self, forKey: .shineRecords) ?? []
        customAffirmations = try c.decodeIfPresent([String].self, forKey: .customAffirmations) ?? []

        let nativeRatio = try c.decodeIfPresent(Int.self, forKey: .rainbowRatio)
        let flutterRatio = try c.decodeIfPresent(Int.self, forKey: .celebrationRainbowRatio)
        rainbowRatio = max(0, min(100, nativeRatio ?? flutterRatio ?? 80))

        let nativeSound = try c.decodeIfPresent(Bool.self, forKey: .soundEnabled)
        let flutterSound = try c.decodeIfPresent(Bool.self, forKey: .celebrationSoundEnabled)
        soundEnabled = nativeSound ?? flutterSound ?? true

        aiPersona = (try? c.decodeIfPresent(AiCelebrationPersona.self, forKey: .aiPersona)) ?? .sweetBestie
        themeSkin = (try? c.decodeIfPresent(CelebrationThemeSkin.self, forKey: .themeSkin)) ?? .emerald
        soundPack = (try? c.decodeIfPresent(CelebrationSoundPack.self, forKey: .soundPack)) ?? .crystalBell
        autoCalendarFootprint = try c.decodeIfPresent(Bool.self, forKey: .autoCalendarFootprint) ?? true
        twoWayRemindersSync = try c.decodeIfPresent(Bool.self, forKey: .twoWayRemindersSync) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(plans, forKey: .plans)
        try c.encode(habits, forKey: .habits)
        try c.encode(anchors, forKey: .anchors)
        try c.encode(shineRecords, forKey: .shineRecords)
        try c.encode(customAffirmations, forKey: .customAffirmations)
        try c.encode(rainbowRatio, forKey: .rainbowRatio)
        try c.encode(soundEnabled, forKey: .soundEnabled)
        try c.encode(aiPersona, forKey: .aiPersona)
        try c.encode(themeSkin, forKey: .themeSkin)
        try c.encode(soundPack, forKey: .soundPack)
        try c.encode(autoCalendarFootprint, forKey: .autoCalendarFootprint)
        try c.encode(twoWayRemindersSync, forKey: .twoWayRemindersSync)
    }
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
        // 先校验顶层必须为 JSON Object 且至少包含任意一个业务字段，避免空对象或无关 JSON 静默覆写本地数据
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "LocalStore", code: -3, userInfo: [NSLocalizedDescriptionKey: "备份文件顶层必须是 JSON 对象"])
        }
        let knownKeys: Set<String> = ["plans", "habits", "anchors", "shineRecords", "customAffirmations", "schemaVersion"]
        guard !knownKeys.isDisjoint(with: obj.keys) else {
            throw NSError(domain: "LocalStore", code: -4, userInfo: [NSLocalizedDescriptionKey: "未识别到微步或历史版本的备份数据字段"])
        }
        return try JSONDecoder().decode(AppBackupData.self, from: data)
    }
}
