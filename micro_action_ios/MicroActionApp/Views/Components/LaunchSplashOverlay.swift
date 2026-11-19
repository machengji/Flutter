import SwiftUI

/// 「微步 / TinyStep」自然晨雾开屏过渡（无生硬方框，透明小芽精灵如晨露般轻盈绽放后无缝融入主屏）
struct LaunchSplashOverlay: View {
    let onFinished: () -> Void

    @State private var appeared: Bool = false
    @State private var mistExpanded: Bool = false
    @State private var isFadingOut: Bool = false

    var body: some View {
        ZStack {
            ImmersiveBackgroundView()

            // 极轻柔扩散的清晨翡翠柔雾光晕
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            BotanicalTheme.primaryLight.opacity(0.28),
                            BotanicalTheme.primarySoft.opacity(0.08),
                            .clear
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 110
                    )
                )
                .frame(width: 220, height: 220)
                .scaleEffect(mistExpanded ? 1.25 : 0.72)
                .opacity(appeared ? (isFadingOut ? 0 : 1) : 0)

            VStack(spacing: 14) {
                // 直接使用无框透明底的版画插画，自然轻盈悬浮
                Image("IllustEmptyPlan")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 128, height: 128)
                    .scaleEffect(appeared ? 1.0 : 0.86)
                    .offset(y: appeared ? 0 : 10)
                    .opacity(appeared ? 1.0 : 0.0)

                VStack(spacing: 4) {
                    Text("微步")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(BotanicalTheme.textPrimary)
                        .tracking(3)

                    Text("让小步自然长成大树")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(BotanicalTheme.primaryDark.opacity(0.72))
                }
                .offset(y: appeared ? 0 : 8)
                .opacity(appeared ? 1.0 : 0.0)
            }
        }
        .opacity(isFadingOut ? 0.0 : 1.0)
        .allowsHitTesting(!isFadingOut)
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 0.75)) {
                mistExpanded = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.62) {
                withAnimation(.easeOut(duration: 0.30)) {
                    isFadingOut = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.31) {
                    onFinished()
                }
            }
        }
    }
}
