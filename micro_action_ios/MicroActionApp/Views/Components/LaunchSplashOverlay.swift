import SwiftUI

/// 「微步 / TinyStep」优雅开屏品牌微动画（约 0.9s，柔和绽放后羽化消散无缝过渡到主屏）
struct LaunchSplashOverlay: View {
    let onFinished: () -> Void

    @State private var logoAppeared: Bool = false
    @State private var haloExpanded: Bool = false
    @State private var textAppeared: Bool = false
    @State private var isDismissing: Bool = false

    var body: some View {
        ZStack {
            ImmersiveBackgroundView()

            // 中心柔和翡翠光环波纹
            Circle()
                .stroke(BotanicalTheme.primaryLight.opacity(haloExpanded ? 0.0 : 0.36), lineWidth: 2)
                .frame(width: haloExpanded ? 210 : 104, height: haloExpanded ? 210 : 104)
                .animation(.easeOut(duration: 0.85), value: haloExpanded)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            BotanicalTheme.primaryLight.opacity(0.24),
                            BotanicalTheme.primarySoft.opacity(0.06),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 96
                    )
                )
                .frame(width: 192, height: 192)
                .scaleEffect(logoAppeared ? 1.05 : 0.72)
                .opacity(logoAppeared ? 1.0 : 0.0)

            VStack(spacing: 18) {
                Image("BrandLogoMark")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.88), lineWidth: 1.5)
                    )
                    .shadow(color: BotanicalTheme.primaryDark.opacity(0.16), radius: 22, y: 10)
                    .scaleEffect(logoAppeared ? 1.0 : 0.78)
                    .opacity(logoAppeared ? 1.0 : 0.0)

                VStack(spacing: 5) {
                    Text("微步")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundColor(BotanicalTheme.textPrimary)
                        .tracking(2)

                    Text("TinyStep · 让小步长成大树")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(BotanicalTheme.primaryDark.opacity(0.75))
                }
                .offset(y: textAppeared ? 0 : 10)
                .opacity(textAppeared ? 1.0 : 0.0)
            }
        }
        .scaleEffect(isDismissing ? 1.05 : 1.0)
        .opacity(isDismissing ? 0.0 : 1.0)
        .allowsHitTesting(!isDismissing)
        .onAppear {
            withAnimation(.spring(response: 0.52, dampingFraction: 0.76)) {
                logoAppeared = true
            }
            haloExpanded = true
            withAnimation(.spring(response: 0.50, dampingFraction: 0.84).delay(0.14)) {
                textAppeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.88) {
                withAnimation(.easeInOut(duration: 0.34)) {
                    isDismissing = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    onFinished()
                }
            }
        }
    }
}
