import SwiftUI

/// iOS 26 液态玻璃（Liquid Glass）自适应视觉与现代弹窗形变修饰器套件
/// - 在 Xcode 26 / iOS 26+ 环境自动启用系统原生 `.glassEffect(.regular.interactive(), in: ...)` 与原生 Liquid Glass Sheet
/// - 在 iOS 16–18 及 Xcode 16 环境呈现晶莹通透的多层次光学折射液态玻璃材质、大圆角磨砂悬浮 Sheet 及 iOS 18+ 原生 Zoom Morph 形变动画
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
                    interactive ? .regular.tint(tint.opacity(0.14)).interactive() : .regular.tint(tint.opacity(0.09)),
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
        // 高性能光学玻璃层：彻底避免每帧重算 .ultraThinMaterial 与双层大阴影，确保全站慢速拖动与高速滚动满帧 120Hz
        let topAlpha: Double = interactive ? 0.90 : 0.96
        let midAlpha: Double = interactive ? 0.80 : 0.90
        return content
            .background {
                ZStack {
                    shape.fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(topAlpha), location: 0.0),
                                .init(color: Color.white.opacity(midAlpha), location: 0.48),
                                .init(color: tint.opacity(interactive ? 0.12 : 0.07), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                    shape
                        .stroke(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.95), location: 0.0),
                                    .init(color: tint.opacity(0.20), location: 0.65),
                                    .init(color: Color.white.opacity(0.75), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: interactive ? 1.1 : 0.9
                        )
                }
            }
            .shadow(
                color: BotanicalTheme.primaryDark.opacity(interactive ? 0.08 : 0.03),
                radius: interactive ? min(shadowRadius, 6) : 2.5,
                y: interactive ? 2.5 : 1.0
            )
    }
}

/// 现代 iOS 18/26 液态玻璃悬浮大圆角 Sheet 修饰器
/// - iOS 26+: 遵循 Apple HIG 不覆写系统原生 Liquid Glass Sheet 材质，仅设置 detents 与圆角
/// - iOS 16.4–18: 自动应用 `.ultraThinMaterial` 半透明悬浮玻璃背景与 34pt 大圆角
struct LiquidGlassSheetModifier: ViewModifier {
    let detents: Set<PresentationDetent>
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let base = content
            .presentationDetents(detents)
            .presentationDragIndicator(.visible)

        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            base
                .presentationCornerRadius(cornerRadius)
        } else if #available(iOS 16.4, *) {
            base
                .presentationCornerRadius(cornerRadius)
                .presentationBackground(.ultraThinMaterial)
        } else {
            base
        }
        #else
        if #available(iOS 16.4, *) {
            base
                .presentationCornerRadius(cornerRadius)
                .presentationBackground(.ultraThinMaterial)
        } else {
            base
        }
        #endif
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

    /// 滚动列表专用高性能轻盈卡片（纯色不透明背景 + 极简 1px 描边，零实时模糊与零渐变合成，保证慢速与高速滚动均满帧 120Hz）
    func lightweightListCard(
        cornerRadius: CGFloat = 19,
        tint: Color = BotanicalTheme.primaryLight
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return self
            .background(Color.white, in: shape)
            .overlay(
                shape
                    .stroke(BotanicalTheme.border.opacity(0.85), lineWidth: 0.9)
            )
    }

    /// 现代 iOS 液态玻璃悬浮 Sheet 样式（自动适配 iOS 26 原生 Liquid Glass 与 iOS 16.4–18 磨砂玻璃）
    func liquidGlassSheet(
        detents: Set<PresentationDetent> = [.large],
        cornerRadius: CGFloat = 34
    ) -> some View {
        modifier(LiquidGlassSheetModifier(detents: detents, cornerRadius: cornerRadius))
    }

    /// Sheet 内部轻盈半透明森雾渐变薄纱（绝不遮盖底层液态玻璃透视感，同时铺满全屏防断层）
    func liquidSheetCanvasBackground() -> some View {
        self.background(
            LinearGradient(
                stops: [
                    .init(color: BotanicalTheme.primarySoft.opacity(0.28), location: 0.0),
                    .init(color: Color.white.opacity(0.24), location: 0.48),
                    .init(color: BotanicalTheme.primaryLight.opacity(0.14), location: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
        )
    }

    /// iOS 18/26 原生液态形变弹窗起点标记（显式胶囊裁切 + 透明背景，彻底消除默认矩形方框阴影）
    @ViewBuilder
    func liquidZoomSource(id: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            self.matchedTransitionSource(id: id, in: namespace) { source in
                source
                    .background(Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        } else {
            self
        }
    }

    /// iOS 18/26 原生液态形变弹窗转场目标
    @ViewBuilder
    func liquidZoomTransition(sourceID: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            self.navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        } else {
            self
        }
    }
}
