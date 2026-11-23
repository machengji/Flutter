import SwiftUI

/// 单条福格时间锚点卡片（完整复刻原版 AnchorCard 暖阳松果视觉、快捷编辑/删除按钮与底部定时提醒状态条）
struct AnchorCardView: View {
    let anchor: AnchorItem
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggleReminder: () -> Void

    private var itemCount: Int {
        anchor.planIds.count + anchor.habitIds.count
    }

    var body: some View {
        HStack(alignment: .center, spacing: 11) {
            // 左侧紧凑暖阳时间徽章
            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(BotanicalTheme.anchorAccent)
                Text(anchor.triggerTime)
                    .font(.system(size: 14.5, weight: .bold, design: .rounded))
                    .foregroundColor(BotanicalTheme.anchorAccent)
            }
            .padding(.horizontal, 9.5)
            .padding(.vertical, 7)
            .background(BotanicalTheme.anchorAccent.opacity(0.11))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(BotanicalTheme.anchorAccent.opacity(0.20), lineWidth: 0.9)
            )

            // 中间锚点名称 + 单行轻量标签
            VStack(alignment: .leading, spacing: 2.5) {
                Text(anchor.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(BotanicalTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Text(anchor.scheduleLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(BotanicalTheme.anchorAccent)

                    if anchor.alarmEnabled && anchor.reminderEnabled {
                        Image(systemName: "alarm.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: 0xD97706))
                    }

                    Text("·")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(BotanicalTheme.textHint)

                    Text(itemCount > 0 ? "已关联 \(itemCount) 项" : "暂无关联")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(itemCount > 0 ? BotanicalTheme.primaryDark : BotanicalTheme.textSecondary)
                }
                .lineLimit(1)
            }

            Spacer(minLength: 4)

            // 右侧铃铛提醒一键开关微胶囊
            Button {
                SensoryFeedbackService.shared.selection()
                withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                    onToggleReminder()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: anchor.reminderEnabled ? "bell.fill" : "bell.slash")
                        .font(.system(size: 11.5, weight: .semibold))
                    Text(anchor.reminderEnabled ? "提醒" : "静音")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(anchor.reminderEnabled ? BotanicalTheme.primaryDark : BotanicalTheme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(anchor.reminderEnabled ? BotanicalTheme.primarySoft.opacity(0.85) : BotanicalTheme.surfaceMuted)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            anchor.reminderEnabled ? BotanicalTheme.trayBorder : BotanicalTheme.border.opacity(0.6),
                            lineWidth: 0.9
                        )
                )
            }
            .buttonStyle(ScaleBounceButtonStyle(scale: 0.92))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .lightweightListCard(
            cornerRadius: 19,
            tint: BotanicalTheme.anchorAccent
        )
        .contentShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
        .onTapGesture(perform: onTap)
    }
}
