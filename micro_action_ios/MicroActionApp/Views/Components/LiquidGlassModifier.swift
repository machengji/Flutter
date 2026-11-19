import SwiftUI

/// iOS 26 液态玻璃（Liquid Glass）自适应视觉修饰器
/// - 在 Xcode 26 / iOS 26+ 环境自动启用系统原生 `.glassEffect(.regular.interactive(), in: ...)`
/// - 在 iOS 16–18 及 Xcode 16 环境呈现多层次光学折射液态玻璃材质（实时模糊 + 斜向镜面光泽 + 顶缘折射高光 + 柔焦双层投影）
struct LiquidGlassSurface<S: Shape>: ViewModifier {
    let shape: S
    let tint: Color
    let interactive: Bool
    let shadowRadius: CGFloat

    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            content
                .glassEffect(
                    interactive ? .regular.tint(tint.opacity(0.14)).interactive() : .regular.tint(tint.opacity(0.10)),
                    in: shape
                )
        } else {
            opticalLiquidGlass(content)
        }
        #else
        opticalLiquidGlass(content)
        #endif
    }

    private func opticalLiquidGlass(_ content: Content) -> some View {
        let topAlpha: Double = interactive ? 0.72 : 0.86
        let midAlpha: Double = interactive ? 0.36 : 0.62
        return content
            .background {
                ZStack {
                    shape.fill(.ultraThinMaterial)

                    // 斜向液态折射光泽层（左上明亮高光 -> 中部清透 -> 右下微绿环境反射）
                    shape.fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(topAlpha), location: 0.0),
                                .init(color: Color.white.opacity(midAlpha), location: 0.42),
                                .init(color: tint.opacity(0.11), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                    // 顶缘内嵌镜面折射高光弧（模拟真实曲面玻璃顶部聚光）
                    shape
                        .stroke(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.96), location: 0.0),
                                    .init(color: Color.white.opacity(0.35), location: 0.36),
                                    .init(color: tint.opacity(0.20), location: 0.72),
                                    .init(color: Color.white.opacity(0.55), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.25
                        )
                }
            }
            .shadow(color: BotanicalTheme.primaryDark.opacity(0.09), radius: shadowRadius, y: shadowRadius * 0.45)
            .shadow(color: Color.black.opacity(0.03), radius: 4, y: 1.5)
    }
}

extension View {
    func liquidGlassCapsule(
        tint: Color = BotanicalTheme.primaryLight,
        interactive: Bool = true,
        shadowRadius: CGFloat = 18
    ) -> some View {
        modifier(LiquidGlassSurface(shape: Capsule(), tint: tint, interactive: interactive, shadowRadius: shadowRadius))
    }

    func liquidGlassCircle(
        tint: Color = BotanicalTheme.primaryLight,
        interactive: Bool = true,
        shadowRadius: CGFloat = 16
    ) -> some View {
        modifier(LiquidGlassSurface(shape: Circle(), tint: tint, interactive: interactive, shadowRadius: shadowRadius))
    }

    func liquidGlassCard(
        cornerRadius: CGFloat = 22,
        tint: Color = BotanicalTheme.primaryLight,
        interactive: Bool = false,
        shadowRadius: CGFloat = 14
    ) -> some View {
        modifier(
            LiquidGlassSurface(
                shape: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous),
                tint: tint,
                interactive: interactive,
                shadowRadius: shadowRadius
            )
        )
    }
}
