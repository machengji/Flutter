import SwiftUI

/// 侧边栏菜单弹窗（无任何外部二维码打赏与 API Key 配置入口，100% App Store 审核合规）
struct SideMenuSheet: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var proStore: ProStoreService
    @Environment(\.dismiss) private var dismiss

    @State private var activeDestination: MenuDestination? = nil

    enum MenuDestination: Identifiable {
        case settings, analytics, archive, help, legal
        var id: Int { hashValue }
    }

    var body: some View {
        NavigationStack {
            List {
                // Pro 会员入口横幅
                Section {
                    Button {
                        appState.showProPaywall = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: 0xFFE08A))
                                .frame(width: 42, height: 42)
                                .background(Color.white.opacity(0.16))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(proStore.isPro ? "已尊享微行动 Pro" : "升级微行动 Pro")
                                    .font(.system(size: 16, weight: .heavy))
                                    .foregroundColor(.white)
                                Text(proStore.isPro
                                     ? "AI四大人设 · 拆微步骤 · 苹果同步 · 全皮肤已解锁"
                                     : "解锁 AI 专属夸夸官、微步骤拆解、主题皮肤与小组件")
                                    .font(.system(size: 11.5))
                                    .foregroundColor(Color.white.opacity(0.86))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color.white.opacity(0.8))
                        }
                        .padding(14)
                        .background(BotanicalTheme.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }

                Section("效率与洞察") {
                    menuRow(icon: "externaldrive.badge.icloud", title: "数据管理与苹果同步", subtitle: "本地备份、iOS 提醒事项与日历足迹", color: BotanicalTheme.primary) {
                        activeDestination = .settings
                    }
                    menuRow(icon: "chart.bar.xaxis", title: "AI 数据分析", subtitle: "DeepSeek 生命六维度与成长轨迹洞察", color: Color(hex: 0x3A86FF)) {
                        activeDestination = .analytics
                    }
                    menuRow(icon: "archivebox", title: "已归档任务 (\(appState.archivedPlans.count))", subtitle: "暂非当前重点的收纳专区", color: BotanicalTheme.textSecondary) {
                        activeDestination = .archive
                    }
                }

                Section("指南与合规") {
                    menuRow(icon: "book.pages", title: "使用帮助", subtitle: "了解福格微习惯行为模型 (B=MAP)", color: BotanicalTheme.primaryDark) {
                        activeDestination = .help
                    }
                    menuRow(icon: "hand.raised.fill", title: "隐私政策与用户协议", subtitle: "数据本地优先、权限用途与 AI 服务说明", color: BotanicalTheme.secondary) {
                        activeDestination = .legal
                    }
                }

                Section {
                    HStack {
                        Spacer()
                        Text("微行动助手 · SwiftUI 原生版 v2.0.0")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(BotanicalTheme.textHint)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("微行动")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                        .foregroundColor(BotanicalTheme.primary)
                }
            }
            .sheet(item: $activeDestination) { dest in
                switch dest {
                case .settings: SettingsSheet()
                case .analytics: AnalyticsSheet()
                case .archive: ArchiveSheet()
                case .help: HelpSheet()
                case .legal: LegalSheet()
                }
            }
        }
    }

    private func menuRow(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 34, height: 34)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(BotanicalTheme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 11.5))
                        .foregroundColor(BotanicalTheme.textSecondary)
                }
            }
            .padding(.vertical, 3)
        }
    }
}
