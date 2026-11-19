import SwiftUI
import UIKit

/// 侧边栏目标功能页路由枚举
enum SideMenuDestination: Identifiable {
    case settings, analytics, archive, help, legal
    var id: Int { hashValue }
}

/// 原版风格左侧滑出式森系圆角抽屉（复刻 AppDrawer 品牌头、柔和色卡菜单项、28pt 右侧大圆角、左滑手势关闭）
struct SideDrawerOverlay: View {
    @Binding var isPresented: Bool
    var topInset: CGFloat = 0
    var bottomInset: CGFloat = 0
    let onSelectDestination: (SideMenuDestination) -> Void

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var proStore: ProStoreService

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let drawerWidth = min(geo.size.width * 0.82, 316)

            ZStack(alignment: .leading) {
                if isPresented {
                    Color.black.opacity(0.32)
                        .ignoresSafeArea()
                        .onTapGesture { closeDrawer() }
                        .transition(.opacity)
                }

                if isPresented {
                    drawerContent(topInset: topInset, bottomInset: bottomInset)
                        .frame(width: drawerWidth)
                        .frame(maxHeight: .infinity)
                        .background(
                            ZStack {
                                Rectangle().fill(.ultraThinMaterial)
                                BotanicalTheme.surface.opacity(0.88)
                            }
                        )
                        .clipShape(RightRoundedCornerShape(radius: 28))
                        .overlay(
                            RightRoundedCornerShape(radius: 28)
                                .stroke(Color.white.opacity(0.85), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.14), radius: 26, x: 8, y: 0)
                        .offset(x: min(0, dragOffset))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if value.translation.width < 0 {
                                        dragOffset = value.translation.width
                                    }
                                }
                                .onEnded { value in
                                    if value.translation.width < -70 || value.predictedEndTranslation.width < -120 {
                                        closeDrawer()
                                    } else {
                                        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                                            dragOffset = 0
                                        }
                                    }
                                }
                        )
                        .transition(.move(edge: .leading))
                }
            }
            .animation(.spring(response: 0.34, dampingFraction: 0.86), value: isPresented)
        }
        .ignoresSafeArea()
    }

    private func drawerContent(topInset: CGFloat, bottomInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            // 顶部森系精灵品牌头（柔光翡翠精灵头像 + 清晨森雾底）
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0xEEF9F2), Color(hex: 0xD5EFE0)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 68, height: 68)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(BotanicalTheme.primary.opacity(0.20), lineWidth: 1.2)
                        )
                        .shadow(color: BotanicalTheme.primary.opacity(0.14), radius: 14, y: 6)

                    TiimoMascotOrbView(style: .dockAvatar)
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                }
                .padding(.bottom, 16)

                Text("微行动")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(BotanicalTheme.textPrimary)

                Text("让微小改变自然发生")
                    .font(.system(size: 14))
                    .foregroundColor(BotanicalTheme.textSecondary)
                    .padding(.top, 5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 26)
            .padding(.top, max(topInset, 24) + 28)
            .padding(.bottom, 24)
            .background(BotanicalTheme.backgroundGradient)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(BotanicalTheme.border.opacity(0.55))
                    .frame(height: 1)
            }

            // 菜单列表
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    // Pro 会员入口横幅
                    Button {
                        SensoryFeedbackService.shared.selection()
                        closeDrawer()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            appState.showProPaywall = true
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: 0xFFE08A))
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.16))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(proStore.isPro ? "已尊享微行动 Pro" : "升级微行动 Pro")
                                    .font(.system(size: 15, weight: .heavy))
                                    .foregroundColor(.white)
                                Text(proStore.isPro
                                     ? "AI人设 · 拆微步骤 · 全皮肤已解锁"
                                     : "解锁 AI 夸夸官、拆微步骤与皮肤")
                                    .font(.system(size: 11.5))
                                    .foregroundColor(Color.white.opacity(0.86))
                                    .lineLimit(1)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color.white.opacity(0.85))
                        }
                        .padding(14)
                        .background(BotanicalTheme.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: BotanicalTheme.primary.opacity(0.22), radius: 10, y: 4)
                    }
                    .buttonStyle(ScaleBounceButtonStyle(scale: 0.97))

                    drawerItem(
                        icon: "externaldrive.badge.icloud",
                        label: "数据管理",
                        subtitle: "备份与苹果提醒/日历同步",
                        color: BotanicalTheme.secondaryDark
                    ) {
                        navigate(to: .settings)
                    }

                    drawerItem(
                        icon: "chart.bar.xaxis",
                        label: "数据分析",
                        subtitle: "查看你的进步轨迹与 AI 洞察",
                        color: BotanicalTheme.primary
                    ) {
                        navigate(to: .analytics)
                    }

                    drawerItem(
                        icon: "archivebox",
                        label: "已归档任务",
                        subtitle: "暂非未来重点的收纳专区",
                        color: BotanicalTheme.textSecondary,
                        badgeCount: appState.archivedPlans.count
                    ) {
                        navigate(to: .archive)
                    }

                    drawerItem(
                        icon: "book.pages",
                        label: "使用帮助",
                        subtitle: "了解福格微习惯行为模型",
                        color: BotanicalTheme.primaryDark
                    ) {
                        navigate(to: .help)
                    }

                    Divider()
                        .background(BotanicalTheme.border.opacity(0.55))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 6)

                    drawerItem(
                        icon: "hand.raised.fill",
                        label: "隐私与协议",
                        subtitle: "数据本地存储与权限说明",
                        color: BotanicalTheme.primary
                    ) {
                        navigate(to: .legal)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }

            // 底部版本胶囊
            HStack {
                Spacer()
                Text("iOS Native • v2.0.0")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(BotanicalTheme.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(BotanicalTheme.primary.opacity(0.10))
                    .clipShape(Capsule())
                Spacer()
            }
            .padding(.top, 8)
            .padding(.bottom, max(bottomInset, 16) + 8)
        }
    }

    private func drawerItem(
        icon: String,
        label: String,
        subtitle: String,
        color: Color,
        badgeCount: Int? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            SensoryFeedbackService.shared.selection()
            action()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 15.5, weight: .semibold))
                        .foregroundColor(BotanicalTheme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(BotanicalTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                if let count = badgeCount, count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2.5)
                        .background(color.opacity(0.16))
                        .clipShape(Capsule())
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(BotanicalTheme.textHint)
            }
            .padding(14)
            .background(color.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(color.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleBounceButtonStyle(scale: 0.97))
    }

    private func navigate(to destination: SideMenuDestination) {
        closeDrawer()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            onSelectDestination(destination)
        }
    }

    private func closeDrawer() {
        dragOffset = 0
        withAnimation(.spring(response: 0.30, dampingFraction: 0.86)) {
            isPresented = false
        }
    }
}

/// 仅右侧圆角形状（用于左侧滑出抽屉）
private struct RightRoundedCornerShape: Shape {
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topRight, .bottomRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
