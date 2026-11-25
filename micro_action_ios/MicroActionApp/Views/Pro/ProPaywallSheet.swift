import SwiftUI

/// 原生 StoreKit 2 Pro 会员付费墙（月度 / 年度 / 终身买断 + 恢复购买 + 隐私与协议 + 测试期体验开关）
struct ProPaywallSheet: View {
    @EnvironmentObject private var proStore: ProStoreService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlanId: String = ProPlanOption.yearlyId
    @State private var isProcessing: Bool = false
    @State private var feedbackText: String? = nil
    @State private var showLegalSheet: Bool = false
    @State private var showSettingsSheet: Bool = false

    private let benefits: [(icon: String, title: String, desc: String)] = [
        ("quote.bubble.fill", "AI 专属夸夸官（四大人设）", "结合你刚完成的具体事项，用嘴甜闺蜜/冷面吐槽/霸总/冷笑话大师量身夸你"),
        ("wand.and.stars", "AI 一键微行动拆解", "输入大目标，AI 一键拆出 3–5 个 2 分钟可动手的子步骤并前置到首页"),
        ("calendar.badge.clock", "苹果全家桶同步 + 桌面成长树小组件", "系统提醒事项双向实时对齐、日历足迹自动记录与锁屏/桌面成长树小组件"),
        ("paintpalette.fill", "全套庆祝仪式皮肤与微音效包", "解锁落日熔金、极光星夜、樱雾桃韵主题与柔和木琴、典雅和弦音效")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // 顶部「微步 Pro」原创 3D 液态玻璃主视觉卡片
                    ZStack(alignment: .leading) {
                        Image("IllustProHero")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 156)
                            .clipped()

                        LinearGradient(
                            stops: [
                                .init(color: Color(hex: 0x102A1E).opacity(0.84), location: 0.0),
                                .init(color: Color(hex: 0x1B4332).opacity(0.45), location: 0.56),
                                .init(color: Color.clear, location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(hex: 0xFFE08A))
                                Text(proStore.isPro ? "已尊享微步 Pro" : "升级微步 Pro")
                                    .font(.system(size: 22, weight: .heavy))
                                    .foregroundColor(.white)
                            }
                            Text("把每一次微小行动\n变成自带追光灯的高光时刻")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.88))
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 156)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.28), lineWidth: 1)
                    )
                    .shadow(color: BotanicalTheme.primaryDark.opacity(0.22), radius: 18, y: 8)

                    // 4 大核心权益列表
                    VStack(spacing: 12) {
                        ForEach(benefits, id: \.title) { item in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(BotanicalTheme.primary)
                                    .frame(width: 36, height: 36)
                                    .background(BotanicalTheme.primarySoft.opacity(0.6))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.title)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(BotanicalTheme.textPrimary)
                                    Text(item.desc)
                                        .font(.system(size: 12))
                                        .foregroundColor(BotanicalTheme.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding(16)
                    .background(BotanicalTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(BotanicalTheme.border, lineWidth: 1))

                    // 自定义 AI 接口配置提示（BYOK 透明说明）
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: 0xC68314))
                            .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 5) {
                            Text("AI 能力需配合自定义 AI 接口使用")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(BotanicalTheme.textPrimary)
                            Text("解锁微步 Pro 后，需前往「设置与同步 → 自定义 AI 接口」填入您自己的 API Key 与模型（支持 DeepSeek、OpenAI 兼容接口等，仅保存在本地设备直连）。")
                                .font(.system(size: 11.5))
                                .foregroundColor(BotanicalTheme.textSecondary)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)

                            if proStore.isPro {
                                Button {
                                    SensoryFeedbackService.shared.lightTap()
                                    showSettingsSheet = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Text("前往配置自定义 AI")
                                            .font(.system(size: 11.5, weight: .bold))
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 11)
                                    .padding(.vertical, 5)
                                    .background(BotanicalTheme.primary)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(ScaleBounceButtonStyle(scale: 0.95))
                                .padding(.top, 2)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(14)
                    .background(Color(hex: 0xFFF9EC))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color(hex: 0xE5A93B).opacity(0.45), lineWidth: 1)
                    )

                    // 三档套餐选择（月度 / 年度推荐 / 终身买断）
                    VStack(spacing: 10) {
                        ForEach(ProPlanOption.defaults) { option in
                            let selected = selectedPlanId == option.productId
                            Button {
                                SensoryFeedbackService.shared.selection()
                                selectedPlanId = option.productId
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 6) {
                                            Text(option.title)
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(BotanicalTheme.textPrimary)
                                            Text(option.badge)
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(option.isRecommended ? .white : BotanicalTheme.primaryDark)
                                                .padding(.horizontal, 7)
                                                .padding(.vertical, 2)
                                                .background(option.isRecommended ? BotanicalTheme.accentWarm : BotanicalTheme.primarySoft)
                                                .clipShape(Capsule())
                                        }
                                        Text(option.subtitle)
                                            .font(.system(size: 12))
                                            .foregroundColor(BotanicalTheme.textSecondary)
                                    }
                                    Spacer()
                                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                                        Text(proStore.displayPrice(for: option))
                                            .font(.system(size: 20, weight: .heavy))
                                            .foregroundColor(BotanicalTheme.primaryDark)
                                        Text(option.periodLabel)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(BotanicalTheme.textSecondary)
                                    }
                                }
                                .padding(14)
                                .background(selected ? BotanicalTheme.primarySoft.opacity(0.32) : BotanicalTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(selected ? BotanicalTheme.primary : BotanicalTheme.border, lineWidth: selected ? 2 : 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // 主升级按钮
                    Button {
                        handlePurchase()
                    } label: {
                        HStack(spacing: 8) {
                            if isProcessing {
                                ProgressView().tint(.white)
                            }
                            Text(proStore.isPro ? "已是 Pro 会员" : "立即解锁微行动 Pro")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(BotanicalTheme.primaryGradient)
                        .clipShape(Capsule())
                    }
                    .disabled(isProcessing)

                    if let msg = feedbackText {
                        Text(msg)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(BotanicalTheme.primaryDark)
                            .multilineTextAlignment(.center)
                    }

                    // 测试期本地体验开关（受编译期 ENABLE_PRO_PREVIEW 控制，正式上架打包时设为 NO 即隐藏）
                    if proStore.allowPreviewToggle {
                        VStack(alignment: .leading, spacing: 6) {
                            Toggle(isOn: Binding(
                                get: { proStore.isPro },
                                set: { proStore.setPreviewProEnabled($0) }
                            )) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("测试期：一键切换 Pro 体验")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Color(hex: 0xB45309))
                                    Text("便于未上架前真机体验全部 Pro 权益；正式提审打包时设为 NO 自动隐藏")
                                        .font(.system(size: 11))
                                        .foregroundColor(BotanicalTheme.textSecondary)
                                }
                            }
                            .tint(Color(hex: 0xD97706))
                        }
                        .padding(14)
                        .background(Color(hex: 0xFEF3C7).opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    // App Store 审核强制要求：恢复购买 + 订阅条款 + 隐私政策/用户协议
                    HStack(spacing: 20) {
                        Button("恢复购买") {
                            handleRestore()
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(BotanicalTheme.primary)

                        Button("隐私政策与用户协议") {
                            showLegalSheet = true
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(BotanicalTheme.textSecondary)
                    }

                    Text("确认购买后将通过您的 Apple ID 账户扣款。订阅方案将在当前周期结束前 24 小时自动续费，您可随时前往 iPhone「设置 -> Apple ID -> 订阅」中管理或取消。终身买断为一次性付费，永久有效。")
                        .font(.system(size: 10.5))
                        .foregroundColor(BotanicalTheme.textHint)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(BotanicalTheme.backgroundTop.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(BotanicalTheme.textHint)
                    }
                }
            }
            .sheet(isPresented: $showLegalSheet) {
                LegalSheet()
            }
            .sheet(isPresented: $showSettingsSheet) {
                SettingsSheet()
            }
        }
    }

    private func handlePurchase() {
        isProcessing = true
        feedbackText = nil
        Task {
            let (ok, msg) = await proStore.purchase(productId: selectedPlanId)
            await MainActor.run {
                isProcessing = false
                feedbackText = msg
                if ok {
                    SensoryFeedbackService.shared.celebrateGrand(soundEnabled: true, soundPack: .crystalBell)
                }
            }
        }
    }

    private func handleRestore() {
        isProcessing = true
        feedbackText = nil
        Task {
            let (_, msg) = await proStore.restorePurchases()
            await MainActor.run {
                isProcessing = false
                feedbackText = msg
            }
        }
    }
}
