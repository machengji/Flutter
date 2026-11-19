import SwiftUI

/// 森系植物园与自然生机视觉设计系统（完整对齐原版 Botanical & Woodland Palette，并针对 SwiftUI 原生质感优化）
enum BotanicalTheme {
    // MARK: - 主色调（森林新芽与苔藓绿）
    static let primary = Color(hex: 0x2E8B57)
    static let primaryLight = Color(hex: 0x52B788)
    static let primaryDark = Color(hex: 0x1B5E3A)
    static let primarySoft = Color(hex: 0xD8F3DC)

    // MARK: - 次要色（溪流鼠尾草青）
    static let secondary = Color(hex: 0x2A9D8F)
    static let secondaryLight = Color(hex: 0x56C2B4)
    static let secondaryDark = Color(hex: 0x1D7268)

    // MARK: - 功能色（自然果实与花卉色）
    static let success = Color(hex: 0x2E8B57)
    static let warning = Color(hex: 0xE08E35)
    static let accentWarm = Color(hex: 0xE08E35)
    static let gold = Color(hex: 0xE9C46A)
    static let danger = Color(hex: 0xD65A4F)
    static let info = Color(hex: 0x4A86B8)

    // MARK: - 语义化卡片主题色
    static let planCardTint = Color(hex: 0xF6FBF8)
    static let planAccent = Color(hex: 0x2E8B57)

    static let habitCardTint = Color(hex: 0xF4F9FA)
    static let habitAccent = Color(hex: 0x3A8699)

    static let anchorCardTint = Color(hex: 0xFDFAF4)
    static let anchorAccent = Color(hex: 0xD9822B)

    // MARK: - 中性色（晨雾宣纸与温润苔石）
    static let backgroundTop = Color(hex: 0xEAF4EE)
    static let backgroundBottom = Color(hex: 0xF5F9F6)
    static let surface = Color(hex: 0xFFFFFF)
    static let surfaceMuted = Color(hex: 0xF1F7F3)
    static let border = Color(hex: 0xDCE7E0)
    static let divider = Color(hex: 0xEBF2ED)

    // MARK: - 文字颜色（深林松墨色）
    static let textPrimary = Color(hex: 0x1F3328)
    static let textSecondary = Color(hex: 0x5C7265)
    static let textHint = Color(hex: 0x9EB0A5)

    // MARK: - 柔和弥散阴影色
    static let shadowLight = Color(hex: 0x1B4332).opacity(0.06)
    static let shadowMedium = Color(hex: 0x1B4332).opacity(0.11)

    // MARK: - 渐变体系
    static let backgroundGradient = LinearGradient(
        colors: [backgroundTop, backgroundBottom],
        startPoint: .top,
        endPoint: .bottom
    )

    static let primaryGradient = LinearGradient(
        colors: [Color(hex: 0x40916C), Color(hex: 0x2D6A4F)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let secondaryGradient = LinearGradient(
        colors: [Color(hex: 0x38A3A5), Color(hex: 0x227C7D)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let activePillGradient = LinearGradient(
        colors: [Color(hex: 0x52A67A), Color(hex: 0x36865D)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let planCardGradient = LinearGradient(
        colors: [.white, planCardTint],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let habitCardGradient = LinearGradient(
        colors: [.white, habitCardTint],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let anchorCardGradient = LinearGradient(
        colors: [.white, anchorCardTint],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - 分组标签色（自然花卉与矿石 8 色系）
    static let groupColors: [Color] = [
        Color(hex: 0x7E6B9F), // 薰衣草紫
        Color(hex: 0x4A86B8), // 矢车菊蓝
        Color(hex: 0xD46A84), // 山茶粉
        Color(hex: 0xE08E35), // 金盏花橙
        Color(hex: 0x2A9D8F), // 湖水青
        Color(hex: 0x6A994E), // 橄榄嫩绿
        Color(hex: 0xC86D51), // 枫叶赤褐
        Color(hex: 0x607D8B)  // 远山黛蓝
    ]

    static func groupColor(for index: Int) -> Color {
        guard index >= 0 else { return primary }
        return groupColors[index % groupColors.count]
    }

    // MARK: - 相对日期格式化（对齐原版 今天 / 昨天 / N天前 / yyyy/MM/dd）
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy/MM/dd"
        return f
    }()

    static func formatRelativeDate(epochMs: Int64) -> String {
        guard epochMs > 0 else { return "从未" }
        let date = Date(timeIntervalSince1970: Double(epochMs) / 1000.0)
        let diffDays = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: date),
            to: Calendar.current.startOfDay(for: Date())
        ).day ?? 0
        if diffDays <= 0 { return "今天" }
        if diffDays == 1 { return "昨天" }
        if diffDays < 7 { return "\(diffDays)天前" }
        return dateFormatter.string(from: date)
    }
}

/// 精致按压缩放按钮样式（提供细腻的物理回弹触感）
struct ScaleBounceButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.94

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.24, dampingFraction: 0.72), value: configuration.isPressed)
    }
}
