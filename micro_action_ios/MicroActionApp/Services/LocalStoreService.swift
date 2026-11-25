import Foundation

/// 完整本地数据快照（同时兼容原生 v2 JSON 与 Flutter 历史版本导出的 schemaVersion 2 JSON）
struct AppBackupData: Codable, Equatable, Sendable {
    static let currentBackupSchemaVersion: Int = 3

    var backupSchemaVersion: Int
    var appVersion: String?
    var plans: [PlanItem]
    var habits: [HabitItem]
    var anchors: [AnchorItem]
    var shineRecords: [ShineRecord]
    var customAffirmations: [String]
    var rainbowRatio: Int
    var fortuneRatio: Int?
    var aiRatio: Int
    var soundEnabled: Bool
    var aiPersona: AiCelebrationPersona
    var themeSkin: CelebrationThemeSkin
    var soundPack: CelebrationSoundPack
    var autoCalendarFootprint: Bool
    var twoWayRemindersSync: Bool
    var isCelebrationRandomStyle: Bool?
    var fixedCelebrationStyleIndex: Int?
    var enabledCelebrationRituals: [String]?
    var customCelebrationRituals: [String]?
    var isCelebrationRitualRandom: Bool?
    var fixedCelebrationRitual: String?
    var hapticProfileRaw: String?
    var cachedMindMap: AiMindMapDocument?

    enum CodingKeys: String, CodingKey {
        case backupSchemaVersion, appVersion
        case plans, habits, anchors, shineRecords, customAffirmations
        case rainbowRatio, celebrationRainbowRatio, fortuneRatio, aiRatio
        case soundEnabled, celebrationSoundEnabled
        case aiPersona, themeSkin, soundPack
        case autoCalendarFootprint, twoWayRemindersSync
        case isCelebrationRandomStyle, fixedCelebrationStyleIndex
        case enabledCelebrationRituals, customCelebrationRituals, isCelebrationRitualRandom, fixedCelebrationRitual
        case hapticProfileRaw, cachedMindMap
    }

    static let empty = AppBackupData(
        backupSchemaVersion: currentBackupSchemaVersion,
        appVersion: nil,
        plans: [],
        habits: [],
        anchors: [],
        shineRecords: [],
        customAffirmations: [],
        rainbowRatio: 60,
        fortuneRatio: 20,
        aiRatio: 0,
        soundEnabled: true,
        aiPersona: .sweetBestie,
        themeSkin: .emerald,
        soundPack: .crystalBell,
        autoCalendarFootprint: true,
        twoWayRemindersSync: false
    )

    init(
        backupSchemaVersion: Int = AppBackupData.currentBackupSchemaVersion,
        appVersion: String? = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
        plans: [PlanItem],
        habits: [HabitItem],
        anchors: [AnchorItem],
        shineRecords: [ShineRecord],
        customAffirmations: [String],
        rainbowRatio: Int,
        fortuneRatio: Int? = nil,
        aiRatio: Int = 0,
        soundEnabled: Bool,
        aiPersona: AiCelebrationPersona,
        themeSkin: CelebrationThemeSkin,
        soundPack: CelebrationSoundPack,
        autoCalendarFootprint: Bool,
        twoWayRemindersSync: Bool,
        isCelebrationRandomStyle: Bool? = nil,
        fixedCelebrationStyleIndex: Int? = nil,
        enabledCelebrationRituals: [String]? = nil,
        customCelebrationRituals: [String]? = nil,
        isCelebrationRitualRandom: Bool? = nil,
        fixedCelebrationRitual: String? = nil,
        hapticProfileRaw: String? = nil,
        cachedMindMap: AiMindMapDocument? = nil
    ) {
        self.backupSchemaVersion = backupSchemaVersion
        self.appVersion = appVersion
        self.plans = plans
        self.habits = habits
        self.anchors = anchors
        self.shineRecords = shineRecords
        self.customAffirmations = customAffirmations
        self.rainbowRatio = rainbowRatio
        self.fortuneRatio = fortuneRatio
        self.aiRatio = aiRatio
        self.soundEnabled = soundEnabled
        self.aiPersona = aiPersona
        self.themeSkin = themeSkin
        self.soundPack = soundPack
        self.autoCalendarFootprint = autoCalendarFootprint
        self.twoWayRemindersSync = twoWayRemindersSync
        self.isCelebrationRandomStyle = isCelebrationRandomStyle
        self.fixedCelebrationStyleIndex = fixedCelebrationStyleIndex
        self.enabledCelebrationRituals = enabledCelebrationRituals
        self.customCelebrationRituals = customCelebrationRituals
        self.isCelebrationRitualRandom = isCelebrationRitualRandom
        self.fixedCelebrationRitual = fixedCelebrationRitual
        self.hapticProfileRaw = hapticProfileRaw
        self.cachedMindMap = cachedMindMap
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        backupSchemaVersion = try c.decodeIfPresent(Int.self, forKey: .backupSchemaVersion) ?? 2
        appVersion = try c.decodeIfPresent(String.self, forKey: .appVersion)
        plans = try c.decodeIfPresent([PlanItem].self, forKey: .plans) ?? []
        habits = try c.decodeIfPresent([HabitItem].self, forKey: .habits) ?? []
        anchors = try c.decodeIfPresent([AnchorItem].self, forKey: .anchors) ?? []
        shineRecords = try c.decodeIfPresent([ShineRecord].self, forKey: .shineRecords) ?? []
        customAffirmations = try c.decodeIfPresent([String].self, forKey: .customAffirmations) ?? []

        let nativeRatio = try c.decodeIfPresent(Int.self, forKey: .rainbowRatio)
        let flutterRatio = try c.decodeIfPresent(Int.self, forKey: .celebrationRainbowRatio)
        let decodedRainbow = max(0, min(100, nativeRatio ?? flutterRatio ?? 60))
        fortuneRatio = try c.decodeIfPresent(Int.self, forKey: .fortuneRatio)
        let decodedAi = max(0, min(100, (try c.decodeIfPresent(Int.self, forKey: .aiRatio)) ?? 0))
        if decodedAi + decodedRainbow > 100 {
            aiRatio = decodedAi
            rainbowRatio = max(0, 100 - decodedAi)
        } else {
            aiRatio = decodedAi
            rainbowRatio = decodedRainbow
        }

        let nativeSound = try c.decodeIfPresent(Bool.self, forKey: .soundEnabled)
        let flutterSound = try c.decodeIfPresent(Bool.self, forKey: .celebrationSoundEnabled)
        soundEnabled = nativeSound ?? flutterSound ?? true

        aiPersona = (try? c.decodeIfPresent(AiCelebrationPersona.self, forKey: .aiPersona)) ?? .sweetBestie
        themeSkin = (try? c.decodeIfPresent(CelebrationThemeSkin.self, forKey: .themeSkin)) ?? .emerald
        soundPack = (try? c.decodeIfPresent(CelebrationSoundPack.self, forKey: .soundPack)) ?? .crystalBell
        autoCalendarFootprint = try c.decodeIfPresent(Bool.self, forKey: .autoCalendarFootprint) ?? true
        twoWayRemindersSync = try c.decodeIfPresent(Bool.self, forKey: .twoWayRemindersSync) ?? false
        isCelebrationRandomStyle = try c.decodeIfPresent(Bool.self, forKey: .isCelebrationRandomStyle)
        fixedCelebrationStyleIndex = try c.decodeIfPresent(Int.self, forKey: .fixedCelebrationStyleIndex)
        enabledCelebrationRituals = try c.decodeIfPresent([String].self, forKey: .enabledCelebrationRituals)
        customCelebrationRituals = try c.decodeIfPresent([String].self, forKey: .customCelebrationRituals)
        isCelebrationRitualRandom = try c.decodeIfPresent(Bool.self, forKey: .isCelebrationRitualRandom)
        fixedCelebrationRitual = try c.decodeIfPresent(String.self, forKey: .fixedCelebrationRitual)
        hapticProfileRaw = try c.decodeIfPresent(String.self, forKey: .hapticProfileRaw)
        cachedMindMap = try? c.decodeIfPresent(AiMindMapDocument.self, forKey: .cachedMindMap)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(backupSchemaVersion, forKey: .backupSchemaVersion)
        try c.encodeIfPresent(appVersion, forKey: .appVersion)
        try c.encode(plans, forKey: .plans)
        try c.encode(habits, forKey: .habits)
        try c.encode(anchors, forKey: .anchors)
        try c.encode(shineRecords, forKey: .shineRecords)
        try c.encode(customAffirmations, forKey: .customAffirmations)
        try c.encode(rainbowRatio, forKey: .rainbowRatio)
        try c.encodeIfPresent(fortuneRatio, forKey: .fortuneRatio)
        try c.encode(aiRatio, forKey: .aiRatio)
        try c.encode(soundEnabled, forKey: .soundEnabled)
        try c.encode(aiPersona, forKey: .aiPersona)
        try c.encode(themeSkin, forKey: .themeSkin)
        try c.encode(soundPack, forKey: .soundPack)
        try c.encode(autoCalendarFootprint, forKey: .autoCalendarFootprint)
        try c.encode(twoWayRemindersSync, forKey: .twoWayRemindersSync)
        try c.encodeIfPresent(isCelebrationRandomStyle, forKey: .isCelebrationRandomStyle)
        try c.encodeIfPresent(fixedCelebrationStyleIndex, forKey: .fixedCelebrationStyleIndex)
        try c.encodeIfPresent(enabledCelebrationRituals, forKey: .enabledCelebrationRituals)
        try c.encodeIfPresent(customCelebrationRituals, forKey: .customCelebrationRituals)
        try c.encodeIfPresent(isCelebrationRitualRandom, forKey: .isCelebrationRitualRandom)
        try c.encodeIfPresent(fixedCelebrationRitual, forKey: .fixedCelebrationRitual)
        try c.encodeIfPresent(hapticProfileRaw, forKey: .hapticProfileRaw)
        try c.encodeIfPresent(cachedMindMap, forKey: .cachedMindMap)
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
        let decoded = try JSONDecoder().decode(AppBackupData.self, from: data)
        if decoded.backupSchemaVersion > AppBackupData.currentBackupSchemaVersion {
            throw NSError(
                domain: "LocalStore",
                code: 409,
                userInfo: [NSLocalizedDescriptionKey: "该备份来自更新版本（v\(decoded.backupSchemaVersion)），请先将当前设备上的应用更新至最新版本后再导入，以确保全部数据完整恢复。"]
            )
        }
        return decoded
    }
}
