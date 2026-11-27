import Foundation
import SwiftUI

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

/// 单次发光庆祝记录（对应发光星籽罐中的一颗星籽）
struct ShineRecord: Identifiable, Codable, Equatable, Sendable {
    var id: String
    var timestamp: Int64
    var title: String
    var isGrand: Bool
    var colorSeed: Int

    init(
        id: String = UUID().uuidString,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        title: String,
        isGrand: Bool = true,
        colorSeed: Int = Int.random(in: 0..<6)
    ) {
        self.id = id
        self.timestamp = timestamp
        self.title = title
        self.isGrand = isGrand
        self.colorSeed = colorSeed
    }
}

/// 庆祝海报布局与动画样式（可在设置中自由切换）
enum CelebrationLayoutStyle: String, Codable, CaseIterable, Sendable {
    case morningEditorial = "morningEditorial"
    case classicSpotlight = "classicSpotlight"
    case classicFirework = "classicFirework"

    var displayName: String {
        switch self {
        case .morningEditorial: return "晨光诗笺版"
        case .classicSpotlight: return "森系花信版"
        case .classicFirework: return "经典烟花版"
        }
    }

    init(fromRawCompat raw: String) {
        if raw == "emberFocus" {
            self = .morningEditorial
        } else {
            self = CelebrationLayoutStyle(rawValue: raw) ?? .morningEditorial
        }
    }
}

/// 庆祝交互触发方式（可在设置中自由切换，每种方式配专属页面动画与水彩插画）
enum CelebrationInteractionMode: String, Codable, CaseIterable, Sendable {
    case longPress = "longPress"
    case pullLaunch = "pullLaunch"
    case swipeLight = "swipeLight"
    case tapCombo = "tapCombo"
    case shakeWish = "shakeWish"

    var displayName: String {
        switch self {
        case .longPress: return "按住发光"
        case .pullLaunch: return "下拉放飞"
        case .swipeLight: return "划亮一笔"
        case .tapCombo: return "三连暴击"
        case .shakeWish: return "摇摇许愿"
        }
    }

    var subtitle: String {
        switch self {
        case .longPress: return "按住蓄力棘轮加速，满格破壳释放"
        case .pullLaunch: return "下拉蓄力拉伸弓弦，松手天灯冲向树苗"
        case .swipeLight: return "指尖划出微笑金粉轨迹，一笔生花点亮"
        case .tapCombo: return "连续轻点 3 下节拍鼓点，逐级叠加暴击"
        case .shakeWish: return "轻摇手机晃动花瓣许愿瓶，摇满 3 下绽放"
        }
    }

    var iconName: String {
        switch self {
        case .longPress: return "hand.tap.fill"
        case .pullLaunch: return "arrow.up.circle.fill"
        case .swipeLight: return "scribble.variable"
        case .tapCombo: return "bolt.circle.fill"
        case .shakeWish: return "iphone.gen3.radiowaves.left.and.right"
        }
    }
}

/// 触发全屏高光庆祝海报的事件载荷
struct CelebrationPayload: Identifiable, Equatable, Sendable {
    let id: Int
    let actionTitle: String
    let quote: String
    var jokeQuote: String? = nil
    var aiQuote: String? = nil
    var fortuneSlip: MicroFortuneSlip? = nil
    let isGrand: Bool
    let milestoneTag: String?
}

/// AI 专属夸夸官四大人设（Pro 会员核心权益）
enum AiCelebrationPersona: String, Codable, CaseIterable, Identifiable, Sendable {
    case sweetBestie = "sweet_bestie"
    case tsundereRoast = "tsundere_roast"
    case domineeringCeo = "domineering_ceo"
    case coldJokeMaster = "cold_joke_master"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .sweetBestie: return "嘴甜闺蜜"
        case .tsundereRoast: return "冷面吐槽"
        case .domineeringCeo: return "霸总语录"
        case .coldJokeMaster: return "冷笑话大师"
        }
    }

    var iconName: String {
        switch self {
        case .sweetBestie: return "heart.text.square.fill"
        case .tsundereRoast: return "face.smiling.inverse"
        case .domineeringCeo: return "crown.fill"
        case .coldJokeMaster: return "snowflake"
        }
    }

    var subtitle: String {
        switch self {
        case .sweetBestie: return "温柔高情商，放大你的每一个闪光细节"
        case .tsundereRoast: return "嘴硬心软傲娇式肯定，反差感拉满"
        case .domineeringCeo: return "霸总宠溺式表扬，情绪价值拉满"
        case .coldJokeMaster: return "紧扣你刚做的事，现场编一条高级冷笑话"
        }
    }
}

/// 庆祝仪式主题皮肤（4 套）
enum CelebrationThemeSkin: String, Codable, CaseIterable, Identifiable, Sendable {
    case emerald = "emerald"
    case sunsetGold = "sunset_gold"
    case auroraNight = "aurora_night"
    case sakuraMist = "sakura_mist"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .emerald: return "森系翡翠"
        case .sunsetGold: return "落日熔金"
        case .auroraNight: return "极光星夜"
        case .sakuraMist: return "樱雾桃韵"
        }
    }

    var isPro: Bool {
        false
    }

    var bgHex: UInt32 {
        switch self {
        case .emerald: return 0x006768
        case .sunsetGold: return 0x8C3B2B
        case .auroraNight: return 0x1A2456
        case .sakuraMist: return 0x7A2848
        }
    }

    var peachHex: UInt32 {
        switch self {
        case .emerald: return 0xF5B9AB
        case .sunsetGold: return 0xFFC08A
        case .auroraNight: return 0x8EE3D5
        case .sakuraMist: return 0xFFB7C5
        }
    }

    var accentHex: UInt32 {
        switch self {
        case .emerald: return 0xFF4735
        case .sunsetGold: return 0xFF7A2F
        case .auroraNight: return 0x3FD0B3
        case .sakuraMist: return 0xFF5C8A
        }
    }

    var darkHex: UInt32 {
        switch self {
        case .emerald: return 0x620033
        case .sunsetGold: return 0x4A1810
        case .auroraNight: return 0x101738
        case .sakuraMist: return 0x4A0E27
        }
    }

    var creamHex: UInt32 {
        switch self {
        case .emerald: return 0xF4EFD8
        case .sunsetGold: return 0xFFF3E2
        case .auroraNight: return 0xEEF7FF
        case .sakuraMist: return 0xFFF0F4
        }
    }

    var goldHex: UInt32 {
        switch self {
        case .emerald: return 0xFFE08A
        case .sunsetGold: return 0xFFE394
        case .auroraNight: return 0xA5F3FC
        case .sakuraMist: return 0xFFD6A5
        }
    }

    var bgColor: Color { Color(hex: bgHex) }
    var peachColor: Color { Color(hex: peachHex) }
    var accentColor: Color { Color(hex: accentHex) }
    var darkColor: Color { Color(hex: darkHex) }
    var creamColor: Color { Color(hex: creamHex) }
    var goldColor: Color { Color(hex: goldHex) }
}

/// 庆祝微音效风格包（3 套）
enum CelebrationSoundPack: String, Codable, CaseIterable, Identifiable, Sendable {
    case crystalBell = "crystal_bell"
    case warmMarimba = "warm_marimba"
    case royalChord = "royal_chord"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .crystalBell: return "清脆星铃"
        case .warmMarimba: return "柔和木琴"
        case .royalChord: return "典雅和弦"
        }
    }

    var isPro: Bool {
        self != .crystalBell
    }
}

/// 本地精选彩虹屁与冷笑话词库（配合在线接口预加载队列共同服务）
enum CelebrationLibrary {
    static let playfulQuotes: [String] = [
        "你今天的执行力简直自带追光灯！",
        "又是被自己靠谱到的一天！",
        "连微风路过都要夸一句：这人真行！",
        "这点小事遇到你，算是踢到铁板啦！",
        "今日份闪闪发光额度已超标达成！",
        "请收下今日最佳行动派小金人！",
        "宇宙刚刚收到一条你变强的信号！",
        "太丝滑了，自律界今天为你亮绿灯！"
    ]

    static let coldJokes: [String] = [
        "为什么企鹅的肚子是白的？因为手太短，洗不到。",
        "有一只北极熊觉得很冷，于是拔了一根毛，结果更冷了，又拔了一根，结果……成了北极秃熊。",
        "小猪佩奇为什么总是侧着脸？因为正面猪不让画。",
        "什么动物最没有方向感？麋鹿（迷路）。",
        "为什么草莓会被抓进警察局？因为它是莓（没）良心的。",
        "哪一种蛇最容易受骗？竹叶青（猪也轻信）。",
        "什么水果视力最差？芒果（盲果）。",
        "热胀冷缩，那为什么人一到冬天就变胖了？因为穿得多，不是膨胀。",
        "为什么海星没有大脑？因为它们全靠“随波逐流”。",
        "为什么电脑经常生病？因为它总是开着 Windows。"
    ]

    /// 根据真实发光战绩与时段生成社交传播人设称号
    static func computeSocialPersona(todayCount: Int, totalCount: Int, date: Date = Date()) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        if hour >= 22 || hour < 5 {
            return "深夜自律发光体"
        }
        if hour >= 5 && hour < 8 && todayCount >= 1 {
            return "早起破晓行动派"
        }
        if todayCount >= 5 {
            return "今日连击永动机"
        }
        if todayCount >= 3 {
            return "拖延症粉碎机"
        }
        if totalCount >= 30 {
            return "森林守护魔法师"
        }
        if todayCount >= 2 {
            return "稳步进击小天才"
        }
        return "微光行动家"
    }

    /// 拆解冷笑话为（问句/铺垫, 梗底/答案），无明确分隔符时返回完整文本且 punchline 为 nil
    static func splitColdJoke(_ raw: String) -> (setup: String, punchline: String?) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return ("", nil) }

        for separator in ["？", "?"] {
            if let range = trimmed.range(of: separator) {
                let setup = String(trimmed[..<range.upperBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                let rest = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !rest.isEmpty {
                    return (setup, rest)
                }
            }
        }

        for separator in ["\n", "——"] {
            if let range = trimmed.range(of: separator) {
                let setup = String(trimmed[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                let rest = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !setup.isEmpty && !rest.isEmpty {
                    return (setup, rest)
                }
            }
        }

        return (trimmed, nil)
    }
}

/// 幸运签与森林印章稀有度
enum FortuneRarity: String, Codable, CaseIterable, Sendable {
    case r = "R"
    case sr = "SR"
    case ssr = "SSR"

    var badgeText: String { rawValue }
}

/// 今日微步宜忌幸运签
struct MicroFortuneSlip: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let rarity: FortuneRarity
    let signTitle: String
    let yiText: String
    let jiText: String
}

extension CelebrationLibrary {
    static let fortuneSlips: [MicroFortuneSlip] = [
        MicroFortuneSlip(id: "f1", rarity: .ssr, signTitle: "上上签", yiText: "理直气壮休息", jiText: "精神内耗"),
        MicroFortuneSlip(id: "f2", rarity: .ssr, signTitle: "金光签", yiText: "夸自己三分钟", jiText: "拿自己和别人比"),
        MicroFortuneSlip(id: "f3", rarity: .ssr, signTitle: "锦鲤签", yiText: "点一杯喜欢的小甜水", jiText: "过度完美主义"),
        MicroFortuneSlip(id: "f4", rarity: .sr, signTitle: "微风签", yiText: "深呼吸伸个懒腰", jiText: "自我怀疑"),
        MicroFortuneSlip(id: "f5", rarity: .sr, signTitle: "顺遂签", yiText: "把大目标拆成两分钟", jiText: "空想不行动"),
        MicroFortuneSlip(id: "f6", rarity: .sr, signTitle: "晴朗签", yiText: "早睡半小时", jiText: "深夜复盘遗憾"),
        MicroFortuneSlip(id: "f7", rarity: .sr, signTitle: "回血签", yiText: "发呆放空五分钟", jiText: "强迫自己连轴转"),
        MicroFortuneSlip(id: "f8", rarity: .r, signTitle: "小确幸", yiText: "晒一分钟太阳", jiText: "小事上死磕"),
        MicroFortuneSlip(id: "f9", rarity: .r, signTitle: "松弛签", yiText: "先完成再完美", jiText: "一次性想太远"),
        MicroFortuneSlip(id: "f10", rarity: .r, signTitle: "自在签", yiText: "喝口温水润润嗓", jiText: "憋着委屈不表达"),
        MicroFortuneSlip(id: "f11", rarity: .r, signTitle: "破冰签", yiText: "做完最小的那一步", jiText: "等状态满分才开始"),
        MicroFortuneSlip(id: "f12", rarity: .r, signTitle: "暖阳签", yiText: "给好朋友发个表情包", jiText: "独自消化坏情绪")
    ]

    /// 抽取一枚今日宜忌幸运签（逢 5 步必出 SSR，其余按概率抽取）
    static func drawFortuneSlip(totalCount: Int) -> MicroFortuneSlip {
        let hitGuaranteedSSR = totalCount > 0 && (totalCount % 5 == 0)
        let roll = Int.random(in: 0..<100)
        let targetRarity: FortuneRarity
        if hitGuaranteedSSR || roll < 18 {
            targetRarity = .ssr
        } else if roll < 54 {
            targetRarity = .sr
        } else {
            targetRarity = .r
        }

        let fortunePool = fortuneSlips.filter { $0.rarity == targetRarity }
        return fortunePool.randomElement() ?? fortuneSlips[0]
    }
}
