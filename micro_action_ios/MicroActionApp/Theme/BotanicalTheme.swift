import SwiftUI

/// 森系翡翠绿 + iOS 液态玻璃视觉设计系统（回归原版经典森林翡翠主色）
enum BotanicalTheme {
    // MARK: - 主色调（原版经典森系翡翠绿）
    static let primary = Color(hex: 0x2D6A4F)
    static let primaryLight = Color(hex: 0x52B788)
    static let primaryDark = Color(hex: 0x1B4332)
    static let primarySoft = Color(hex: 0xE5F4EB)

    // MARK: - 次要色（清翠鼠尾草与浅薄荷）
    static let secondary = Color(hex: 0x40916C)
    static let secondaryLight = Color(hex: 0x74C69D)
    static let secondaryDark = Color(hex: 0x245842)

    // MARK: - 功能色（柔和自然语义色）
    static let success = Color(hex: 0x2D936C)
    static let warning = Color(hex: 0xE28743)
    static let accentWarm = Color(hex: 0xE76F51)
    static let gold = Color(hex: 0xE9B959)
    static let danger = Color(hex: 0xD95B5B)
    static let info = Color(hex: 0x3D84A8)

    // MARK: - 语义化卡片主题色（极浅清新森雾白底）
    static let planCardTint = Color(hex: 0xF6FCF8)
    static let planAccent = Color(hex: 0x2D6A4F)

    static let habitCardTint = Color(hex: 0xF3FAF6)
    static let habitAccent = Color(hex: 0x40916C)

    static let anchorCardTint = Color(hex: 0xFFFBF5)
    static let anchorAccent = Color(hex: 0xE07A47)

    // MARK: - 中性色（清晨森雾空气感画布与细嫩绿灰边框）
    static let backgroundTop = Color(hex: 0xE4F2EA)
    static let backgroundBottom = Color(hex: 0xF7FBF8)
    static let surface = Color(hex: 0xFFFFFF)
    static let surfaceMuted = Color(hex: 0xF1F7F3)
    static let border = Color(hex: 0xD8E7DE)
    static let divider = Color(hex: 0xE6F0EA)

    // MARK: - 卡片内嵌托盘色
    static let trayBackground = Color(hex: 0xEFF7F2)
    static let trayBorder = Color(hex: 0xD5E8DC)
    static let habitTrayBackground = Color(hex: 0xEDF6F1)
    static let habitTrayBorder = Color(hex: 0xD1E6DA)

    // MARK: - 文字颜色（高对比深松墨绿与清爽灰绿）
    static let textPrimary = Color(hex: 0x16261E)
    static let textSecondary = Color(hex: 0x586E62)
    static let textHint = Color(hex: 0x8FA398)

    // MARK: - 柔和弥散阴影色
    static let shadowLight = Color(hex: 0x1B4332).opacity(0.06)
    static let shadowMedium = Color(hex: 0x1B4332).opacity(0.11)

    // MARK: - 渐变体系
    static let backgroundGradient = LinearGradient(
        stops: [
            .init(color: Color(hex: 0xE4F2EA), location: 0.0),
            .init(color: Color(hex: 0xF4FAF6), location: 0.42),
            .init(color: Color(hex: 0xFBFEFC), location: 0.78),
            .init(color: Color(hex: 0xEFF7F2), location: 1.0)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let primaryGradient = LinearGradient(
        colors: [Color(hex: 0x40916C), Color(hex: 0x2D6A4F)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let secondaryGradient = LinearGradient(
        colors: [Color(hex: 0x52B788), Color(hex: 0x2D6A4F)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let activePillGradient = LinearGradient(
        colors: [Color(hex: 0x40916C), Color(hex: 0x245842)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// 森系柔雾翡翠液态玻璃横幅渐变
    static let tiimoBannerGradient = LinearGradient(
        stops: [
            .init(color: Color(hex: 0xDCF2E5).opacity(0.90), location: 0.0),
            .init(color: Color(hex: 0xCBEAD8).opacity(0.86), location: 0.55),
            .init(color: Color(hex: 0xE5F6EC).opacity(0.92), location: 1.0)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let planCardGradient = LinearGradient(
        colors: [.white.opacity(0.92), planCardTint.opacity(0.88)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let habitCardGradient = LinearGradient(
        colors: [.white.opacity(0.92), habitCardTint.opacity(0.88)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let anchorCardGradient = LinearGradient(
        colors: [.white.opacity(0.92), anchorCardTint.opacity(0.88)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - 分组标签色（自然植物系 8 色）
    static let groupColors: [Color] = [
        Color(hex: 0x2D6A4F), // 翡翠深绿
        Color(hex: 0x40916C), // 苍翠薄荷
        Color(hex: 0xE07A47), // 暖杏珊瑚
        Color(hex: 0x3D84A8), // 溪涧晴蓝
        Color(hex: 0xC97A63), // 陶土暖棕
        Color(hex: 0x749F55), // 嫩芽橄榄
        Color(hex: 0xD49A3A), // 晨光琥珀
        Color(hex: 0x627D75)  // 雾霭青灰
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

extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
