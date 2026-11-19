import SwiftUI

/// Tiimo 风格沉浸式梦幻薰衣草柔雾背景（顶部轻盈薰衣草雾 -> 中部纯净雪白 -> 底部柔雾微紫）
struct ImmersiveBackgroundView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: 0xEDE6FF), location: 0.0),
                        .init(color: Color(hex: 0xF5F1FF), location: 0.22),
                        .init(color: Color(hex: 0xFCFBFF), location: 0.56),
                        .init(color: Color(hex: 0xF9F7FE), location: 0.86),
                        .init(color: Color(hex: 0xF4F0FD), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // 1. 顶部居中偏右薰衣草轻雾光晕
                Circle()
                    .fill(
                        RadialGradient(
                            stops: [
                                .init(color: Color(hex: 0x9E82FF).opacity(0.16), location: 0.0),
                                .init(color: Color(hex: 0xBFA8FF).opacity(0.06), location: 0.52),
                                .init(color: .clear, location: 1.0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 180
                        )
                    )
                    .frame(width: 360, height: 360)
                    .position(x: geo.size.width * 0.72, y: 70)

                // 2. 左上角柔和淡丁香紫雾气
                Circle()
                    .fill(
                        RadialGradient(
                            stops: [
                                .init(color: Color(hex: 0xB89BFF).opacity(0.13), location: 0.0),
                                .init(color: Color(hex: 0xD5C4FF).opacity(0.04), location: 0.55),
                                .init(color: .clear, location: 1.0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .position(x: 40, y: 120)

                // 3. 底部柔和晴雾紫光衬托悬浮 Dock
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: 0x8F75FF).opacity(0.08),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 160
                        )
                    )
                    .frame(width: 320, height: 320)
                    .position(x: geo.size.width * 0.80, y: geo.size.height - 40)
            }
            .drawingGroup()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
