import SwiftUI

/// 森系有机美学视觉设计系统（对齐微行动助手高级低饱和自然配色）
enum BotanicalTheme {
    static let primary = Color(hex: 0x2D6A4F)
    static let primaryDark = Color(hex: 0x1B4332)
    static let primarySoft = Color(hex: 0xD8F3DC)
    static let secondary = Color(hex: 0x52B788)
    static let accentWarm = Color(hex: 0xE76F51)
    static let gold = Color(hex: 0xE9C46A)

    static let backgroundTop = Color(hex: 0xF4F7F4)
    static let backgroundBottom = Color(hex: 0xEBF2EC)
    static let surface = Color(hex: 0xFFFFFF)
    static let surfaceMuted = Color(hex: 0xF7FAF7)
    static let border = Color(hex: 0xDCE7DE)

    static let textPrimary = Color(hex: 0x1E2D24)
    static let textSecondary = Color(hex: 0x5B6E62)
    static let textHint = Color(hex: 0x8FA196)
    static let danger = Color(hex: 0xD64545)

    static let backgroundGradient = LinearGradient(
        colors: [backgroundTop, backgroundBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let primaryGradient = LinearGradient(
        colors: [primary, primaryDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// 多级子任务归属色板（用于直观区分不同父目标分支）
    static let groupColors: [Color] = [
        Color(hex: 0x2D6A4F),
        Color(hex: 0x3A86FF),
        Color(hex: 0xE76F51),
        Color(hex: 0x8338EC),
        Color(hex: 0xD97706),
        Color(hex: 0x0F766E)
    ]

    static func groupColor(for index: Int) -> Color {
        guard index >= 0 else { return primary }
        return groupColors[index % groupColors.count]
    }
}
