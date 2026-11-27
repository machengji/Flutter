import SwiftUI
import UIKit

/// 侧边栏目标功能页路由枚举
enum SideMenuDestination: Identifiable {
    case search, settings, archive, help, legal
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
                    Color.black.opacity(0.30)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture { closeDrawer() }
                        .transition(.opacity)
                        .zIndex(0)
                }

                if isPresented {
                    drawerContent(drawerWidth: drawerWidth, topInset: topInset, bottomInset: bottomInset)
                        .frame(width: drawerWidth)
                        .frame(maxHeight: .infinity)
                        .background(
                            ZStack {
                                Rectangle().fill(.ultraThinMaterial)
                                BotanicalTheme.surface.opacity(0.90)
                            }
                        )
                        .clipShape(RightRoundedCornerShape(radius: 28))
                        .overlay(
                            RightRoundedCornerShape(radius: 28)
                                .stroke(Color.white.opacity(0.85), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.14), radius: 26, x: 8, y: 0)
                        .offset(x: min(0, dragOffset))
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 16)
                                .onChanged { value in
                                    if value.translation.width < 0 {
                                        dragOffset = value.translation.width
                                    }
                                }
                                .onEnded { value in
                                    if value.translation.width < -65 || value.predictedEndTranslation.width < -110 {
                                        closeDrawer()
                                    } else {
                                        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                                            dragOffset = 0
                                        }
                                    }
                                }
                        )
                        .transition(.move(edge: .leading))
                        .zIndex(1)
                }
            }
            .animation(.spring(response: 0.34, dampingFraction: 0.86), value: isPresented)
        }
        .ignoresSafeArea()
        .allowsHitTesting(isPresented)
    }

    private func drawerContent(drawerWidth: CGFloat, topInset: CGFloat, bottomInset: CGFloat) -> some View {
        let headerHeight = max(topInset, 24) + 178
        return VStack(spacing: 0) {
            // 顶部「微步」全幅版画晨曦插画品牌头（背景层严格限宽，确保左下品牌文字完整左对齐绝不裁切）
            ZStack(alignment: .bottomLeading) {
                Color.clear
                    .frame(width: drawerWidth, height: headerHeight)
                    .background(
                        Image("IllustDrawerHeader")
                            .resizable()
                            .scaledToFill()
                            .frame(width: drawerWidth, height: headerHeight, alignment: .trailing)
                    )
                    .clipped()

                LinearGradient(
                    stops: [
                        .init(color: BotanicalTheme.surface.opacity(0.0), location: 0.0),
                        .init(color: BotanicalTheme.surface.opacity(0.16), location: 0.62),
                        .init(color: BotanicalTheme.surface.opacity(0.90), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 5) {
                    Text("微步")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(BotanicalTheme.textPrimary)

                    Text("TinyStep · 福格微行动")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(BotanicalTheme.primaryDark.opacity(0.88))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 18)
            }
            .frame(width: drawerWidth, height: headerHeight)
            .clipped()
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(BotanicalTheme.border.opacity(0.45))
                    .frame(height: 0.8)
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
                                Text(proStore.isPro ? "已尊享微步 Pro" : "升级微步 Pro")
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
                        icon: "magnifyingglass",
                        label: "全局搜索",
                        subtitle: "检索愿望、习惯、锚点与发光记录",
                        color: BotanicalTheme.primary
                    ) {
                        navigate(to: .search)
                    }

                    drawerItem(
                        icon: "externaldrive.badge.icloud",
                        label: "数据管理",
                        subtitle: "备份与苹果提醒/日历同步",
                        color: BotanicalTheme.secondaryDark
                    ) {
                        navigate(to: .settings)
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
