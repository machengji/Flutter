import SwiftUI

/// App Store 上架合规：隐私政策与用户服务协议视图
struct LegalSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    section(
                        title: "1. 数据存储与本地优先原则",
                        body: "「微行动助手」高度重视您的个人隐私。您的计划、子任务、习惯打卡记录、时间锚点及发光庆祝记录默认均仅保存在您的设备本地。您可随时在「数据管理」中导出完整 JSON 备份，或通过卸载应用清除全部本地数据。"
                    )
                    section(
                        title: "2. 系统权限用途说明",
                        body: "• 系统日历权限：仅在您开启「完成足迹自动记入系统日历」时使用，用于向您的专属「微行动」日历写入已完成事项足迹。\n• 系统提醒事项权限：仅在您开启双向同步或将计划加入提醒事项时使用，用于在「微行动」列表中同步待办状态。\n• 本地通知权限：用于按您设定的时间锚点发送本地定时提醒。\n• 相册写入权限：仅在您主动点击「保存发光海报」时使用，用于将海报图片保存至系统相册，我们不会读取您的相册内容。"
                    )
                    section(
                        title: "3. 第三方接口与智能 AI 服务说明",
                        body: "• 在线彩虹屁与冷笑话：仅通过加密 HTTPS 获取公开趣味文案，不向接口上传您的个人任务、身份或设备隐私信息。\n• 智能 AI 助手（AI 定制庆祝语、AI 微步骤拆解与数据分析）：仅在您主动点击触发对应 AI 功能时，将您当前选择的任务名称或统计摘要发送至加密的智能大语言模型服务接口以生成响应内容。"
                    )
                    section(
                        title: "4. 订阅与内购说明",
                        body: "微行动 Pro 会员支持月度订阅、年度订阅与终身买断，全部通过 Apple App Store 内购（StoreKit 2）完成结算。您可随时在系统「设置 -> Apple ID -> 订阅」中管理或取消自动续期，亦可在付费页随时点击「恢复购买」。"
                    )
                    section(
                        title: "5. 免责声明",
                        body: "AI 生成的拆解建议、庆祝语与成长洞察仅供日常自我激励与效率参考，不构成医疗、心理诊疗或专业建议。"
                    )
                }
                .padding(20)
            }
            .background(BotanicalTheme.backgroundTop.ignoresSafeArea())
            .navigationTitle("隐私政策与用户协议")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(BotanicalTheme.primary)
                }
            }
        }
    }

    private func section(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(BotanicalTheme.primaryDark)
            Text(body)
                .font(.system(size: 13.5))
                .foregroundColor(BotanicalTheme.textSecondary)
                .lineSpacing(4)
        }
    }
}
