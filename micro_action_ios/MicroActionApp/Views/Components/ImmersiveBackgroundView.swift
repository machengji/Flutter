import SwiftUI

/// 森系清晨柔雾氛围背景（顶部薄荷翡翠晨雾 -> 中部纯净雪白 -> 底部清透绿意衬托液态玻璃 Dock）
struct ImmersiveBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(hex: 0xE1F2E8), location: 0.0),
                    .init(color: Color(hex: 0xEFF8F2), location: 0.24),
                    .init(color: Color(hex: 0xFAFDFB), location: 0.56),
                    .init(color: Color(hex: 0xF3FAF6), location: 0.86),
                    .init(color: Color(hex: 0xEBF6F0), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                ZStack {
                    // 1. 顶部居中偏右清透翡翠光晕
                    Circle()
                        .fill(
                            RadialGradient(
                                stops: [
                                    .init(color: Color(hex: 0x52B788).opacity(0.18), location: 0.0),
                                    .init(color: Color(hex: 0x95D5B2).opacity(0.07), location: 0.52),
                                    .init(color: .clear, location: 1.0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 190
                            )
                        )
                        .frame(width: 380, height: 380)
                        .position(x: geo.size.width * 0.72, y: 65)

                    // 2. 左上角柔和浅薄荷晨雾
                    Circle()
                        .fill(
                            RadialGradient(
                                stops: [
                                    .init(color: Color(hex: 0x74C69D).opacity(0.14), location: 0.0),
                                    .init(color: Color(hex: 0xB7E4C7).opacity(0.05), location: 0.55),
                                    .init(color: .clear, location: 1.0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 155
                            )
                        )
                        .frame(width: 310, height: 310)
                        .position(x: 42, y: 120)

                    // 3. 底部轻柔森绿与暖金折射底光
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: 0x40916C).opacity(0.11),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 170
                            )
                        )
                        .frame(width: 340, height: 340)
                        .position(x: geo.size.width * 0.78, y: geo.size.height - 36)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
            }
            .ignoresSafeArea()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
