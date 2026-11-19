import SwiftUI

/// 沉浸式森系晨雾与自然光影背景（复刻原版 Botanical Mist Background 三处弥散自然光晕）
struct ImmersiveBackgroundView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: 0xE8F3EC), location: 0.0),
                        .init(color: Color(hex: 0xF1F7F3), location: 0.35),
                        .init(color: Color(hex: 0xF6FAF7), location: 0.70),
                        .init(color: Color(hex: 0xF4F8F5), location: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // 1. 顶部晨光树影弥散圆 - 右上角
                Circle()
                    .fill(
                        RadialGradient(
                            stops: [
                                .init(color: BotanicalTheme.primary.opacity(0.095), location: 0.0),
                                .init(color: BotanicalTheme.primaryLight.opacity(0.032), location: 0.55),
                                .init(color: .clear, location: 1.0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 130
                        )
                    )
                    .frame(width: 260, height: 260)
                    .position(x: geo.size.width - 70, y: 55)

                // 2. 溪流青碧弥散圆 - 左下角
                Circle()
                    .fill(
                        RadialGradient(
                            stops: [
                                .init(color: BotanicalTheme.secondary.opacity(0.085), location: 0.0),
                                .init(color: BotanicalTheme.secondary.opacity(0.022), location: 0.55),
                                .init(color: .clear, location: 1.0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .position(x: 75, y: geo.size.height - 60)

                // 3. 暖阳松果微光 - 中间偏右
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                BotanicalTheme.warning.opacity(0.065),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 95
                        )
                    )
                    .frame(width: 190, height: 190)
                    .position(x: geo.size.width - 50, y: geo.size.height * 0.42)
            }
            .drawingGroup()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
