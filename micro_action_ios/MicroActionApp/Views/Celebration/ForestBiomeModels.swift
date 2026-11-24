import SwiftUI

/// 六大独立手绘水彩群落定义（每满 100 步解锁一个完全不同地貌、树干骨架、树冠排布与生态伙伴的群落）
enum ForestTreeSpecies: Int, CaseIterable {
    case ancientOak = 0     // 第 1 棵：林间古橡（春日草坡）
    case weepingSakura = 1  // 第 2 棵：垂枝樱木（花坡春晴）
    case autumnMaple = 2    // 第 3 棵：秋日红枫（鎏金枫坡）
    case winterPine = 3     // 第 4 棵：冬夜雪松（静谧雪原）
    case bambooGrove = 4    // 第 5 棵：幽谷翠竹（青石溪涧）
    case islandPalm = 5     // 第 6 棵：暖夏椰岛（金沙海湾）

    static func forIndex(_ index: Int) -> ForestTreeSpecies {
        let safeIdx = max(0, index) % allCases.count
        return ForestTreeSpecies(rawValue: safeIdx) ?? .ancientOak
    }

    var displayName: String {
        switch self {
        case .ancientOak: return "林间古橡"
        case .weepingSakura: return "垂枝樱木"
        case .autumnMaple: return "秋日红枫"
        case .winterPine: return "冬夜雪松"
        case .bambooGrove: return "幽谷翠竹"
        case .islandPalm: return "暖夏椰岛"
        }
    }

    var biomeTagline: String {
        switch self {
        case .ancientOak: return "春日草坡 · 蘑菇与蓝鹊"
        case .weepingSakura: return "樱花春晴 · 暖灯与白鸽"
        case .autumnMaple: return "鎏金秋坡 · 橡果与松鼠"
        case .winterPine: return "静谧雪原 · 暖灯与雪兔"
        case .bambooGrove: return "青石溪涧 · 翠竹与熊猫"
        case .islandPalm: return "碧海金沙 · 贝壳与海鸥"
        }
    }

    /// 独立手绘水彩背景资源名
    var backgroundImageName: String {
        switch self {
        case .ancientOak: return "IllustGrowthTreeBg"
        case .weepingSakura: return "IllustBgSakura"
        case .autumnMaple: return "IllustBgMaple"
        case .winterPine: return "IllustBgPine"
        case .bambooGrove: return "IllustBgBamboo"
        case .islandPalm: return "IllustBgPalm"
        }
    }

    /// 独立手绘水彩树干骨架资源名
    var trunkImageName: String {
        switch self {
        case .ancientOak: return "IllustTreeTrunk"
        case .weepingSakura: return "IllustTrunkSakura"
        case .autumnMaple: return "IllustTrunkMaple"
        case .winterPine: return "IllustTrunkPine"
        case .bambooGrove: return "IllustTrunkBamboo"
        case .islandPalm: return "IllustTrunkPalm"
        }
    }

    /// 第 7 棵起同群落再次轮换时镜像翻转树干，保证前后不重样
    func isMirrored(treeIndex: Int) -> Bool {
        (treeIndex / Self.allCases.count) % 2 == 1
    }

    /// 群落专属对版手绘水彩花叶原画
    var leafImageName: String {
        switch self {
        case .ancientOak: return "IllustLeafCluster"
        case .weepingSakura: return "IllustLeafSakura"
        case .autumnMaple: return "IllustLeafMaple"
        case .winterPine: return "IllustLeafPine"
        case .bambooGrove: return "IllustLeafBamboo"
        case .islandPalm: return "IllustLeafPalm"
        }
    }

    /// 树根同色系地貌接地阴影主色
    var groundShadowPrimary: Color {
        switch self {
        case .ancientOak, .weepingSakura, .bambooGrove: return Color(hex: 0x3A5E35)
        case .autumnMaple: return Color(hex: 0x9C6226)
        case .winterPine: return Color(hex: 0x6F8EAD)
        case .islandPalm: return Color(hex: 0x9E7843)
        }
    }

    var groundShadowSecondary: Color {
        switch self {
        case .ancientOak, .weepingSakura, .bambooGrove: return Color(hex: 0x6A9352)
        case .autumnMaple: return Color(hex: 0xD19749)
        case .winterPine: return Color(hex: 0xB4CEE8)
        case .islandPalm: return Color(hex: 0xD2B37D)
        }
    }

    var leafHueBase: Double { 0 }

    var leafSaturation: Double {
        switch self {
        case .ancientOak: return 1.04
        default: return 1.02
        }
    }

    var leafBrightness: Double { 0.0 }

    var leafMultiply: Color { .white }

    var blossomHueShift: Double {
        switch self {
        case .ancientOak: return 0
        case .weepingSakura: return -38
        case .autumnMaple: return -16
        case .winterPine: return 165
        case .bambooGrove: return 10
        case .islandPalm: return -24
        }
    }

    var blossomGlow: Color {
        switch self {
        case .ancientOak: return Color(hex: 0xFFD15C)
        case .weepingSakura: return Color(hex: 0xFF9EB5)
        case .autumnMaple: return Color(hex: 0xFF9B42)
        case .winterPine: return Color(hex: 0xBCE3FF)
        case .bambooGrove: return Color(hex: 0xB8E986)
        case .islandPalm: return Color(hex: 0xFFE066)
        }
    }

    var ringColor: Color {
        switch self {
        case .ancientOak: return Color(hex: 0xFFD966)
        case .weepingSakura: return Color(hex: 0xFFA6BE)
        case .autumnMaple: return Color(hex: 0xFFB347)
        case .winterPine: return Color(hex: 0xA8D8FF)
        case .bambooGrove: return Color(hex: 0x9BE08E)
        case .islandPalm: return Color(hex: 0xFFD452)
        }
    }

    var canopyWashPrimary: Color {
        switch self {
        case .ancientOak: return Color(hex: 0x7BC47F)
        case .weepingSakura: return Color(hex: 0xF5B5C8)
        case .autumnMaple: return Color(hex: 0xEE7F3D)
        case .winterPine: return Color(hex: 0x62A88E)
        case .bambooGrove: return Color(hex: 0x82CE7C)
        case .islandPalm: return Color(hex: 0x7ACB6F)
        }
    }

    var canopyWashSecondary: Color {
        switch self {
        case .ancientOak: return Color(hex: 0xA8DC8C)
        case .weepingSakura: return Color(hex: 0xFAD7E2)
        case .autumnMaple: return Color(hex: 0xF7C65E)
        case .winterPine: return Color(hex: 0xBFE3F2)
        case .bambooGrove: return Color(hex: 0xBEEB9B)
        case .islandPalm: return Color(hex: 0xC6E87E)
        }
    }

    func canopyGlowColor(isNight: Bool) -> Color {
        switch self {
        case .ancientOak: return isNight ? Color(hex: 0x8DE4AF) : Color(hex: 0xEEF9D6)
        case .weepingSakura: return isNight ? Color(hex: 0xF4B2C9) : Color(hex: 0xFFE6EE)
        case .autumnMaple: return isNight ? Color(hex: 0xF5A855) : Color(hex: 0xFFE7C2)
        case .winterPine: return isNight ? Color(hex: 0x9ED4FF) : Color(hex: 0xE6F4FF)
        case .bambooGrove: return isNight ? Color(hex: 0xA2E8B5) : Color(hex: 0xE8F8DE)
        case .islandPalm: return isNight ? Color(hex: 0xFCE08B) : Color(hex: 0xFFF6D6)
        }
    }

    var petalPrimary: Color {
        switch self {
        case .ancientOak: return Color(hex: 0xF7C6CF)
        case .weepingSakura: return Color(hex: 0xF7A8BD)
        case .autumnMaple: return Color(hex: 0xE86A33)
        case .winterPine: return Color(hex: 0xFFFFFF)
        case .bambooGrove: return Color(hex: 0x9AD98B)
        case .islandPalm: return Color(hex: 0xFFE699)
        }
    }

    var petalSecondary: Color {
        switch self {
        case .ancientOak: return Color(hex: 0xB8E0B6)
        case .weepingSakura: return Color(hex: 0xFFF1F5)
        case .autumnMaple: return Color(hex: 0xF5B841)
        case .winterPine: return Color(hex: 0xDCEFFF)
        case .bambooGrove: return Color(hex: 0xDDF5BE)
        case .islandPalm: return Color(hex: 0xA6E3E9)
        }
    }

    /// 群落专属 10 步地面生态彩蛋（贴合各自地貌）
    var groundEasterEggImage: String {
        switch self {
        case .ancientOak: return "IllustForestMushrooms"
        case .weepingSakura: return "IllustForestMushrooms"
        case .autumnMaple: return "IllustEcoSquirrel"
        case .winterPine: return "IllustEcoRabbit"
        case .bambooGrove: return "IllustEcoPanda"
        case .islandPalm: return "IllustEcoSeagull"
        }
    }

    var groundEasterEggLabel: String {
        switch self {
        case .ancientOak: return "野花蘑菇"
        case .weepingSakura: return "花间野草"
        case .autumnMaple: return "秋日红松鼠"
        case .winterPine: return "暖灯小雪兔"
        case .bambooGrove: return "竹林小熊猫"
        case .islandPalm: return "沙滩海鸥贝壳"
        }
    }

    /// 群落专属 25 步中阶彩蛋样式
    enum MidEcoStyle {
        case treeHollow
        case stoneLantern
        case beachCrab
    }

    var midEcoStyle: MidEcoStyle {
        switch self {
        case .ancientOak, .autumnMaple, .winterPine:
            return .treeHollow
        case .weepingSakura, .bambooGrove:
            return .stoneLantern
        case .islandPalm:
            return .beachCrab
        }
    }

    var midEcoLabel: String {
        switch midEcoStyle {
        case .treeHollow: return "暖光树洞"
        case .stoneLantern: return "苔藓石灯"
        case .beachCrab: return "沙滩小螃蟹"
        }
    }

    var usesTreeHollow: Bool {
        midEcoStyle == .treeHollow
    }

    /// 群落专属 45 步枝梢生态彩蛋
    var canopyEasterEggImage: String {
        switch self {
        case .weepingSakura: return "IllustEcoDove"
        case .winterPine: return "IllustEcoOwl"
        default: return "IllustCanopyBird"
        }
    }

    var canopyEasterEggLabel: String {
        switch self {
        case .weepingSakura: return "樱枝白鸽"
        case .winterPine: return "松枝猫头鹰"
        default: return "枝头蓝鹊"
        }
    }

    /// 群落专属 65 步高阶灵兽伙伴
    var companionAnimalImage: String {
        switch self {
        case .ancientOak, .autumnMaple: return "IllustEcoFox"
        case .weepingSakura, .winterPine, .bambooGrove: return "IllustEcoDeer"
        case .islandPalm: return "IllustEcoStoneLantern"
        }
    }

    var companionAnimalLabel: String {
        switch self {
        case .ancientOak, .autumnMaple: return "打盹红狐狸"
        case .weepingSakura, .winterPine, .bambooGrove: return "梅花小鹿"
        case .islandPalm: return "海岛石灯塔"
        }
    }

    /// 85 步终极森林茶桌营地
    var campEasterEggImage: String { "IllustEcoCampfire" }
    var campEasterEggLabel: String { "暖茶篝火营地" }
}

/// 第 7 棵起无限扩展的高阶天光变体（同一群落二次、三次轮回时自动叠加稀有天光与称号）
enum ForestCosmicVariant: Int {
    case natural = 0    // 第 1~6 棵：自然本色
    case starlight = 1  // 第 7~12 棵：星辉秘境
    case dawnGlow = 2   // 第 13~18 棵：晨曦琉璃
    case aurora = 3     // 第 19 棵起：极光幻境

    static func forTreeIndex(_ index: Int) -> ForestCosmicVariant {
        let cycle = max(0, index) / ForestTreeSpecies.allCases.count
        switch cycle {
        case 0: return .natural
        case 1: return .starlight
        case 2: return .dawnGlow
        default: return .aurora
        }
    }

    var prefixTitle: String? {
        switch self {
        case .natural: return nil
        case .starlight: return "星辉"
        case .dawnGlow: return "晨曦"
        case .aurora: return "极光"
        }
    }

    var atmosphereTint: Color {
        switch self {
        case .natural: return .clear
        case .starlight: return Color(hex: 0x90A8FF).opacity(0.14)
        case .dawnGlow: return Color(hex: 0xFFB870).opacity(0.14)
        case .aurora: return Color(hex: 0x64E8C6).opacity(0.14)
        }
    }

    var badgeColor: Color {
        switch self {
        case .natural: return Color(hex: 0x3A7D56)
        case .starlight: return Color(hex: 0x5B6CE2)
        case .dawnGlow: return Color(hex: 0xD97706)
        case .aurora: return Color(hex: 0x0D9488)
        }
    }
}

/// 独立水彩叶簇/星花槽位（按 6 大群落各自生成贴合真实树形的 100 叶排布）
struct WatercolorLeafSlot: Identifiable {
    let id: Int
    let nx: CGFloat
    let ny: CGFloat
    let angle: Double
    let size: CGFloat
    let hueShift: Double
    let isStarBlossom: Bool

    static func slots(for species: ForestTreeSpecies) -> [WatercolorLeafSlot] {
        switch species {
        case .ancientOak: return oakSlots
        case .weepingSakura: return sakuraSlots
        case .autumnMaple: return mapleSlots
        case .winterPine: return pineSlots
        case .bambooGrove: return bambooSlots
        case .islandPalm: return palmSlots
        }
    }

    private static let oakSlots: [WatercolorLeafSlot] = {
        var slots: [WatercolorLeafSlot] = []
        let earlyPts: [(CGFloat, CGFloat, Double, CGFloat)] = [
            (0.49, 0.42, -12, 60), (0.35, 0.39, -38, 58), (0.64, 0.38, 32, 60),
            (0.24, 0.33, -52, 58), (0.76, 0.32, 46, 58), (0.50, 0.25, 6, 62),
            (0.38, 0.23, -24, 60), (0.62, 0.22, 22, 60), (0.16, 0.42, -64, 56),
            (0.84, 0.41, 58, 56), (0.49, 0.12, -4, 60), (0.31, 0.16, -32, 58)
        ]
        for i in 0..<100 {
            let nx: CGFloat, ny: CGFloat, angle: Double, size: CGFloat
            if i < earlyPts.count {
                (nx, ny, angle, size) = earlyPts[i]
            } else {
                let k = Double(i - earlyPts.count + 1)
                let golden = k * 2.3999632297
                let r = sqrt(k / 88.0)
                nx = min(0.95, max(0.05, 0.50 + CGFloat(cos(golden) * 0.45 * r + sin(k * 6.7) * 0.028)))
                ny = min(0.62, max(0.04, 0.33 + CGFloat(sin(golden) * 0.28 * r + cos(k * 4.3) * 0.024)))
                angle = cos(golden) * 52.0 + sin(k * 3.1) * 18.0
                size = CGFloat((r < 0.72 ? 62 : 54) + (i * 13) % 15)
            }
            let hue = Double(((i * 19) % 15) - 7) * 1.6
            slots.append(WatercolorLeafSlot(id: i, nx: nx, ny: ny, angle: angle, size: size, hueShift: hue, isStarBlossom: i > 0 && (i + 1) % 5 == 0))
        }
        return slots
    }()

    /// 垂枝樱木：顺着倾斜主干向左右垂落的花帘分布
    private static let sakuraSlots: [WatercolorLeafSlot] = {
        var slots: [WatercolorLeafSlot] = []
        let earlyPts: [(CGFloat, CGFloat, Double, CGFloat)] = [
            (0.50, 0.26, -8, 60), (0.34, 0.30, -34, 58), (0.68, 0.28, 30, 58),
            (0.22, 0.40, -54, 56), (0.78, 0.38, 48, 56), (0.44, 0.14, -14, 58),
            (0.60, 0.15, 16, 58), (0.17, 0.54, -70, 54), (0.83, 0.52, 66, 54),
            (0.30, 0.50, -48, 54), (0.72, 0.48, 42, 54), (0.52, 0.38, 4, 56)
        ]
        for i in 0..<100 {
            let nx: CGFloat, ny: CGFloat, angle: Double, size: CGFloat
            if i < earlyPts.count {
                (nx, ny, angle, size) = earlyPts[i]
            } else {
                let k = Double(i - earlyPts.count + 1)
                let golden = k * 2.3999632297
                let r = sqrt(k / 88.0)
                let baseNx = 0.50 + cos(golden) * 0.43 * r
                // 左右两侧边缘自然下垂形成垂枝弧度
                let edgeDroop = pow(abs(baseNx - 0.50) * 2.0, 1.5) * 0.22
                nx = min(0.94, max(0.06, CGFloat(baseNx + sin(k * 5.3) * 0.025)))
                ny = min(0.68, max(0.05, CGFloat(0.27 + sin(golden) * 0.21 * r + edgeDroop + cos(k * 3.7) * 0.02)))
                angle = (baseNx < 0.5 ? -1 : 1) * (24.0 + edgeDroop * 180.0)
                size = CGFloat((r < 0.65 ? 60 : 50) + (i * 11) % 14)
            }
            let hue = Double(((i * 17) % 13) - 6) * 1.8
            slots.append(WatercolorLeafSlot(id: i, nx: nx, ny: ny, angle: angle, size: size, hueShift: hue, isStarBlossom: i > 0 && (i + 1) % 3 == 0))
        }
        return slots
    }()

    /// 秋日红枫：宽阔舒展分层伞形枫冠
    private static let mapleSlots: [WatercolorLeafSlot] = {
        var slots: [WatercolorLeafSlot] = []
        let earlyPts: [(CGFloat, CGFloat, Double, CGFloat)] = [
            (0.50, 0.28, 0, 62), (0.33, 0.33, -28, 60), (0.67, 0.32, 26, 60),
            (0.20, 0.40, -48, 58), (0.80, 0.39, 46, 58), (0.42, 0.17, -14, 60),
            (0.58, 0.17, 14, 60), (0.12, 0.48, -62, 56), (0.88, 0.47, 60, 56),
            (0.50, 0.10, 2, 58), (0.28, 0.23, -34, 58), (0.72, 0.23, 34, 58)
        ]
        for i in 0..<100 {
            let nx: CGFloat, ny: CGFloat, angle: Double, size: CGFloat
            if i < earlyPts.count {
                (nx, ny, angle, size) = earlyPts[i]
            } else {
                let k = Double(i - earlyPts.count + 1)
                let golden = k * 2.3999632297
                let r = sqrt(k / 88.0)
                nx = min(0.96, max(0.04, 0.50 + CGFloat(cos(golden) * 0.47 * r + sin(k * 6.1) * 0.024)))
                ny = min(0.56, max(0.05, 0.29 + CGFloat(sin(golden) * 0.23 * r + cos(k * 4.7) * 0.020)))
                angle = cos(golden) * 48.0 + sin(k * 2.9) * 16.0
                size = CGFloat((r < 0.7 ? 64 : 55) + (i * 13) % 14)
            }
            let hue = Double(((i * 23) % 19) - 9) * 1.8
            slots.append(WatercolorLeafSlot(id: i, nx: nx, ny: ny, angle: angle, size: size, hueShift: hue, isStarBlossom: i > 0 && (i + 1) % 6 == 0))
        }
        return slots
    }()

    /// 冬夜雪松：横向雪顶松针枝沿圆锥塔形层叠交错
    private static let pineSlots: [WatercolorLeafSlot] = {
        var slots: [WatercolorLeafSlot] = []
        for i in 0..<100 {
            let t = Double(i) / 99.0
            let tierY = 0.09 + t * 0.62
            let halfSpan = 0.07 + t * 0.36
            let side = (i % 2 == 0 ? 1.0 : -1.0)
            let wave = sin(Double(i) * 1.93) * 0.55 + cos(Double(i) * 0.87) * 0.45
            let nx = min(0.89, max(0.11, 0.50 + CGFloat(wave * halfSpan * (i < 3 ? 0.25 : 1.0))))
            let ny = min(0.75, max(0.06, CGFloat(tierY + sin(Double(i) * 3.1) * 0.015)))
            let angle = side * (6.0 + t * 14.0)
            let size = CGFloat(64 + Int(t * 22) + (i % 7))
            let hue = Double(((i * 11) % 7) - 3) * 1.2
            slots.append(WatercolorLeafSlot(id: i, nx: nx, ny: ny, angle: angle, size: size, hueShift: hue, isStarBlossom: i > 0 && (i + 1) % 10 == 0))
        }
        return slots
    }()

    /// 幽谷翠竹：围绕左、中、右三根竹竿分节簇生的修长竹叶
    private static let bambooSlots: [WatercolorLeafSlot] = {
        var slots: [WatercolorLeafSlot] = []
        let culmX: [Double] = [0.33, 0.50, 0.67]
        for i in 0..<100 {
            let culm = culmX[i % 3]
            let t = Double(i / 3) / 33.0
            let yBase = 0.11 + (1.0 - t) * 0.54
            let spread = 0.07 + sin(Double(i) * 2.1) * 0.08
            let side: Double = ((i / 3) % 2 == 0) ? 1.0 : -1.0
            let nx = min(0.88, max(0.12, CGFloat(culm + side * spread)))
            let ny = min(0.72, max(0.07, CGFloat(yBase + cos(Double(i) * 4.3) * 0.025)))
            let angle = side * (16.0 + Double(i % 4) * 9.0)
            let size = CGFloat(54 + (i * 7) % 16)
            let hue = Double(((i * 13) % 7) - 3) * 1.2
            slots.append(WatercolorLeafSlot(id: i, nx: nx, ny: ny, angle: angle, size: size, hueShift: hue, isStarBlossom: false))
        }
        return slots
    }()

    /// 暖夏椰岛：集中在椰树干顶端向外呈 10 条大羽叶扇弧度舒展
    private static let palmSlots: [WatercolorLeafSlot] = {
        var slots: [WatercolorLeafSlot] = []
        // IllustLeafPalm 原图本身向右上角约 -45° 伸展，通过角度旋转围绕椰树顶端 (0.42, 0.15) 放射展开
        let frondAngles: [Double] = [-165, -138, -108, -75, -45, -18, 12, 38, -122, -58]
        for i in 0..<100 {
            let frondIdx = i % frondAngles.count
            let baseDeg = frondAngles[frondIdx]
            let ring = Double(i / frondAngles.count) / 9.5 // 0...1
            let rad = baseDeg * .pi / 180.0
            let radius = 0.07 + ring * 0.24
            let droop = pow(ring, 1.5) * 0.10
            let jitterX = sin(Double(i) * 5.7) * 0.014
            let jitterY = cos(Double(i) * 4.9) * 0.012
            let nx = min(0.90, max(0.10, CGFloat(0.42 + cos(rad) * radius + jitterX)))
            let ny = min(0.46, max(0.05, CGFloat(0.16 + sin(rad) * radius * 0.70 + droop + jitterY)))
            let angle = baseDeg + 45.0 + sin(Double(i) * 2.3) * 8.0
            let size = CGFloat(92 + Int((1.0 - ring * 0.25) * 24) + (i % 9))
            let hue = Double(((i * 15) % 7) - 3) * 1.0
            slots.append(WatercolorLeafSlot(id: i, nx: nx, ny: ny, angle: angle, size: size, hueShift: hue, isStarBlossom: false))
        }
        return slots
    }()
}

/// 绘本风「我的森林图鉴」全览画廊（当用户微步无限增多时，一眼看到种出的全部群落森林）
struct ForestGallerySheet: View {
    @Environment(\.dismiss) private var dismiss

    let totalRecordsCount: Int
    let totalTreesCount: Int
    let activeTreeIndex: Int
    let leavesPerTree: Int
    let allRecords: [ShineRecord]
    let onSelectTree: (Int) -> Void

    @State private var selectedStamp: ForestStampCard? = nil

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var unlockedBiomesCount: Int {
        min(totalTreesCount, ForestTreeSpecies.allCases.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    summaryBanner

                    stampAlbumSection

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(0..<totalTreesCount, id: \.self) { idx in
                            treeCard(for: idx)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(Color(hex: 0xFAF6ED).ignoresSafeArea())
            .navigationTitle("我的森林图鉴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(BotanicalTheme.primaryDark)
                }
            }
            .alert(item: $selectedStamp) { stamp in
                Alert(
                    title: Text("\(stamp.animalEmoji) \(stamp.stampName)（\(stamp.rarity.badgeText)）"),
                    message: Text("来自 \(stamp.senderName)：\n“\(stamp.letterText)”"),
                    dismissButton: .default(Text("收好啦"))
                )
            }
        }
    }

    private var summaryBanner: some View {
        HStack(spacing: 0) {
            statCell(value: "\(totalRecordsCount)", label: "累计发光微步")
            Divider().frame(height: 28)
            statCell(value: "\(totalTreesCount)", label: "已培育大树")
            Divider().frame(height: 28)
            statCell(value: "\(unlockedBiomesCount)/\(ForestTreeSpecies.allCases.count)", label: "已解锁群落")
        }
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(BotanicalTheme.border, lineWidth: 0.9)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(BotanicalTheme.primaryDark)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(BotanicalTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func treeCard(for index: Int) -> some View {
        let species = ForestTreeSpecies.forIndex(index)
        let variant = ForestCosmicVariant.forTreeIndex(index)
        let start = index * leavesPerTree
        let end = min(start + leavesPerTree, allRecords.count)
        let count = max(0, end - start)
        let isSelected = (index == activeTreeIndex)
        let fullTitle = variant.prefixTitle.map { "\($0)·\(species.displayName)" } ?? species.displayName

        return Button {
            SensoryFeedbackService.shared.selection()
            onSelectTree(index)
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image(species.backgroundImageName)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 118)
                        .clipped()
                        .overlay(variant.atmosphereTint)
                        .overlay(alignment: .bottom) {
                            ZStack(alignment: .top) {
                                Image(species.trunkImageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 86)
                                    .scaleEffect(x: species.isMirrored(treeIndex: index) ? -1 : 1, y: 1)

                                if count > 0 {
                                    let thumbCount = min(8, max(2, count / 10))
                                    let offsets: [(CGFloat, CGFloat, Double)] = [
                                        (0, 6, 0), (-18, 12, -22), (18, 12, 22), (-10, 2, -12),
                                        (12, 3, 14), (-22, 24, -32), (22, 24, 30), (0, 18, 5)
                                    ]
                                    ZStack {
                                        Ellipse()
                                            .fill(species.canopyWashPrimary.opacity(0.32))
                                            .frame(width: 56, height: 34)
                                            .blur(radius: 6)
                                            .offset(y: 6)
                                        ForEach(0..<thumbCount, id: \.self) { i in
                                            let pt = offsets[i % offsets.count]
                                            Image(species.leafImageName)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: species == .islandPalm ? 32 : 24, height: species == .islandPalm ? 32 : 24)
                                                .rotationEffect(.degrees(pt.2))
                                                .offset(x: pt.0, y: pt.1)
                                        }
                                    }
                                    .offset(y: -4)
                                }
                            }
                            .padding(.bottom, 8)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Text("#\(index + 1)")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(variant.badgeColor.opacity(0.9))
                        .clipShape(Capsule())
                        .padding(6)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(fullTitle)
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(BotanicalTheme.textPrimary)
                        .lineLimit(1)

                    Text(species.biomeTagline)
                        .font(.system(size: 10.5))
                        .foregroundColor(BotanicalTheme.textSecondary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        ProgressView(value: Double(count), total: Double(leavesPerTree))
                            .tint(variant.badgeColor)
                        Text("\(count)/\(leavesPerTree)")
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundColor(BotanicalTheme.primaryDark)
                    }
                    .padding(.top, 2)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
            }
            .padding(8)
            .background(Color.white.opacity(0.95))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? BotanicalTheme.primary : BotanicalTheme.border, lineWidth: isSelected ? 2.0 : 0.8)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(isSelected ? 0.10 : 0.04), radius: 8, y: 3)
        }
        .buttonStyle(ScaleBounceButtonStyle(scale: 0.97))
    }

    private var stampAlbumSection: some View {
        let unlocked = ForestStampStore.shared.unlockedIds()
        let allStamps = CelebrationLibrary.forestStamps
        let unlockedCount = allStamps.filter { unlocked.contains($0.id) }.count

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("森林来信印章手账")
                    .font(.system(size: 14.5, weight: .bold))
                    .foregroundColor(BotanicalTheme.textPrimary)
                Spacer()
                Text("已集齐 \(unlockedCount)/\(allStamps.count)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(BotanicalTheme.primaryDark)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(BotanicalTheme.primary.opacity(0.12)))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(allStamps) { stamp in
                        let isUnlocked = unlocked.contains(stamp.id)
                        Button {
                            if isUnlocked {
                                selectedStamp = stamp
                            }
                        } label: {
                            VStack(spacing: 5) {
                                ZStack {
                                    Circle()
                                        .fill(isUnlocked ? Color(hex: 0xFAF6ED) : Color.black.opacity(0.04))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle().stroke(
                                                isUnlocked
                                                    ? (stamp.rarity == .ssr ? Color(hex: 0xE5A93B) : BotanicalTheme.primary.opacity(0.55))
                                                    : BotanicalTheme.border,
                                                style: StrokeStyle(lineWidth: 1.2, dash: isUnlocked ? [] : [3, 2])
                                            )
                                        )
                                    Text(isUnlocked ? stamp.animalEmoji : "🔒")
                                        .font(.system(size: isUnlocked ? 21 : 15))
                                        .opacity(isUnlocked ? 1.0 : 0.45)
                                }

                                Text(isUnlocked ? stamp.stampName : "未解锁")
                                    .font(.system(size: 10.5, weight: .semibold))
                                    .foregroundColor(isUnlocked ? BotanicalTheme.textPrimary : BotanicalTheme.textSecondary)
                                    .lineLimit(1)

                                Text(stamp.rarity.badgeText)
                                    .font(.system(size: 8.5, weight: .black, design: .rounded))
                                    .foregroundColor(isUnlocked && stamp.rarity == .ssr ? Color(hex: 0xB87B14) : BotanicalTheme.textSecondary)
                            }
                            .frame(width: 78)
                            .padding(.vertical, 9)
                            .padding(.horizontal, 4)
                            .background(Color.white.opacity(isUnlocked ? 0.94 : 0.55))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(BotanicalTheme.border.opacity(0.75), lineWidth: 0.8)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(ScaleBounceButtonStyle(scale: 0.95))
                        .disabled(!isUnlocked)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.82))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(BotanicalTheme.border, lineWidth: 0.9)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
