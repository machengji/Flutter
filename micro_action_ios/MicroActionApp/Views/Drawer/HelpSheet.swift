import SwiftUI

/// 福格微习惯行为模型指南
struct HelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    guideCard(
                        badge: "B = MAP",
                        title: "福格微习惯行为模型",
                        content: "行为（Behavior）的发生需要同时具备三个要素：动机（Motivation）、能力（Ability）与提示（Prompt）。与其苦撑意志力，不如把行动变小、把提示固定，并立刻庆祝。"
                    )
                    guideCard(
                        badge: "STEP 1",
                        title: "微步骤拆解与自动前置",
                        content: "遇到不想动的大目标，展开卡片点「AI拆微步骤」或手动添加 2 分钟能完成的子任务，系统会自动把最容易动手的叶节点微步骤提升到首页最上方。"
                    )
                    guideCard(
                        badge: "STEP 2",
                        title: "绑定生活时间锚点",
                        content: "利用「早上起床」「午饭后」「睡觉前」等每天必做的固定生活节点作为提示锚点，将微习惯与计划绑定上去，到点提醒自然触发。"
                    )
                    guideCard(
                        badge: "STEP 3",
                        title: "1 秒即刻庆祝（Shine 发光感）",
                        content: "每完成一件微小的事，都会弹出高光庆祝海报送上彩虹屁、冷笑话或 AI 专属夸夸，并为你点亮一颗星籽收进星籽罐，让大脑记住“赢的感觉”。"
                    )
                }
                .padding(20)
            }
            .background(BotanicalTheme.backgroundTop.ignoresSafeArea())
            .navigationTitle("使用帮助")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(BotanicalTheme.primary)
                }
            }
        }
    }

    private func guideCard(badge: String, title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(badge)
                .font(.system(size: 11, weight: .heavy))
                .foregroundColor(BotanicalTheme.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(BotanicalTheme.primarySoft)
                .clipShape(Capsule())
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(BotanicalTheme.textPrimary)
            Text(content)
                .font(.system(size: 13.5))
                .foregroundColor(BotanicalTheme.textSecondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(BotanicalTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(BotanicalTheme.border, lineWidth: 1))
    }
}
