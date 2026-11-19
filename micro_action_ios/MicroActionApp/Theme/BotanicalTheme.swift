import SwiftUI

/// Tiimo 风格梦幻薰衣草柔雾视觉设计系统（保留 BotanicalTheme 符号以全工程无缝兼容）
enum BotanicalTheme {
    // MARK: - 主色调（Tiimo 梦幻薰衣草紫）
    static let primary = Color(hex: 0x7C5CFF)
    static let primaryLight = Color(hex: 0xA88BFF)
    static let primaryDark = Color(hex: 0x5A3CD6)
    static let primarySoft = Color(hex: 0xEFEAFF)

    // MARK: - 次要色（晴空柔雾矢车菊蓝）
    static let secondary = Color(hex: 0x5B7CFA)
    static let secondaryLight = Color(hex: 0x8EA6FF)
    static let secondaryDark = Color(hex: 0x3D5AD8)

    // MARK: - 功能色（柔和马卡龙语义色）
    static let success = Color(hex: 0x38B685)
    static let warning = Color(hex: 0xE88B5A)
    static let accentWarm = Color(hex: 0xE88B5A)
    static let gold = Color(hex: 0xE9B959)
    static let danger = Color(hex: 0xE06363)
    static let info = Color(hex: 0x5B7CFA)

    // MARK: - 语义化卡片主题色（极浅柔雾白底）
    static let planCardTint = Color(hex: 0xFAF8FF)
    static let planAccent = Color(hex: 0x7C5CFF)

    static let habitCardTint = Color(hex: 0xF6F8FF)
    static let habitAccent = Color(hex: 0x5B7CFA)

    static let anchorCardTint = Color(hex: 0xFFF9F5)
    static let anchorAccent = Color(hex: 0xE58454)

    // MARK: - 中性色（Tiimo 空气感柔雾画布与极细浅紫灰边框）
    static let backgroundTop = Color(hex: 0xEFE9FF)
    static let backgroundBottom = Color(hex: 0xFAF9FF)
    static let surface = Color(hex: 0xFFFFFF)
    static let surfaceMuted = Color(hex: 0xF5F2FC)
    static let border = Color(hex: 0xE9E4F5)
    static let divider = Color(hex: 0xF0ECF9)

    // MARK: - 卡片内嵌托盘色
    static let trayBackground = Color(hex: 0xF4F1FC)
    static let trayBorder = Color(hex: 0xE5DEF7)
    static let habitTrayBackground = Color(hex: 0xF0F4FF)
    static let habitTrayBorder = Color(hex: 0xDEE6FC)

    // MARK: - 文字颜色（高对比深石墨黑与清爽冷灰）
    static let textPrimary = Color(hex: 0x181724)
    static let textSecondary = Color(hex: 0x6B687D)
    static let textHint = Color(hex: 0xA4A0B5)

    // MARK: - 柔和弥散阴影色
    static let shadowLight = Color(hex: 0x4E3A9B).opacity(0.06)
    static let shadowMedium = Color(hex: 0x4E3A9B).opacity(0.11)

    // MARK: - 渐变体系
    static let backgroundGradient = LinearGradient(
        stops: [
            .init(color: Color(hex: 0xEFE9FF), location: 0.0),
            .init(color: Color(hex: 0xF9F7FF), location: 0.42),
            .init(color: Color(hex: 0xFDFCFF), location: 0.78),
            .init(color: Color(hex: 0xF7F4FE), location: 1.0)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let primaryGradient = LinearGradient(
        colors: [Color(hex: 0x957BFF), Color(hex: 0x6D4AFF)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let secondaryGradient = LinearGradient(
        colors: [Color(hex: 0x7A98FF), Color(hex: 0x5272F5)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let activePillGradient = LinearGradient(
        colors: [Color(hex: 0x967CFF), Color(hex: 0x714FFF)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Tiimo 截图同款淡紫玻璃横幅渐变
    static let tiimoBannerGradient = LinearGradient(
        stops: [
            .init(color: Color(hex: 0xE4DCFF).opacity(0.92), location: 0.0),
            .init(color: Color(hex: 0xD8CCFF).opacity(0.88), location: 0.55),
            .init(color: Color(hex: 0xE8DFFF).opacity(0.92), location: 1.0)
        ],
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

    // MARK: - 分组标签色（柔和马卡龙 8 色系）
    static let groupColors: [Color] = [
        Color(hex: 0x8B6BFF), // 薰衣草紫
        Color(hex: 0x5B7CFA), // 矢车菊蓝
        Color(hex: 0xE0749A), // 山茶樱粉
        Color(hex: 0xE88B5A), // 暖杏珊瑚
        Color(hex: 0x3EB89A), // 薄荷青碧
        Color(hex: 0x7CA855), // 嫩芽青绿
        Color(hex: 0xC97A63), // 陶土暖棕
        Color(hex: 0x73849C)  // 雾霭蓝灰
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
