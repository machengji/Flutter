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
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                // 暖阳松果时间徽章
                HStack(spacing: 5) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(BotanicalTheme.anchorAccent)
                    Text(anchor.triggerTime)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(BotanicalTheme.anchorAccent)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    LinearGradient(
                        colors: [
                            BotanicalTheme.anchorAccent.opacity(0.13),
                            BotanicalTheme.anchorAccent.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(BotanicalTheme.anchorAccent.opacity(0.22), lineWidth: 1)
                )

                // 锚点名称与双标签胶囊
                VStack(alignment: .leading, spacing: 5) {
                    Text(anchor.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(BotanicalTheme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(anchor.repeatCycle.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(BotanicalTheme.anchorAccent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2.5)
                            .background(BotanicalTheme.anchorAccent.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                        Text("\(itemCount) 个关联项")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(itemCount > 0 ? BotanicalTheme.primary : BotanicalTheme.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2.5)
                            .background(itemCount > 0 ? BotanicalTheme.primary.opacity(0.10) : BotanicalTheme.textHint.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }

                Spacer(minLength: 4)

                // 快捷编辑按钮
                Button {
                    SensoryFeedbackService.shared.lightTap()
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(BotanicalTheme.anchorAccent)
                        .frame(width: 34, height: 34)
                        .background(BotanicalTheme.anchorAccent.opacity(0.09))
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                .buttonStyle(ScaleBounceButtonStyle(scale: 0.90))

                // 快捷删除按钮
                Button {
                    SensoryFeedbackService.shared.lightTap()
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(BotanicalTheme.danger)
                        .frame(width: 34, height: 34)
                        .background(BotanicalTheme.danger.opacity(0.09))
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                .buttonStyle(ScaleBounceButtonStyle(scale: 0.90))
            }

            // 底部定时提醒状态条
            HStack(spacing: 6) {
                Image(systemName: anchor.reminderEnabled ? "bell.fill" : "bell.slash")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(anchor.reminderEnabled ? BotanicalTheme.primaryDark : BotanicalTheme.textSecondary)

                Text(anchor.reminderEnabled ? "定时提醒" : "已暂停")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(anchor.reminderEnabled ? BotanicalTheme.primaryDark : BotanicalTheme.textSecondary)

                Spacer()

                Toggle("", isOn: Binding(
                    get: { anchor.reminderEnabled },
                    set: { _ in
                        SensoryFeedbackService.shared.selection()
                        onToggleReminder()
                    }
                ))
                .labelsHidden()
                .scaleEffect(0.82, anchor: .trailing)
                .tint(BotanicalTheme.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(anchor.reminderEnabled ? BotanicalTheme.primarySoft.opacity(0.72) : BotanicalTheme.surfaceMuted.opacity(0.75))
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(
                        anchor.reminderEnabled ? BotanicalTheme.trayBorder : BotanicalTheme.border.opacity(0.55),
                        lineWidth: 1
                    )
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .liquidGlassCard(
            cornerRadius: 22,
            tint: BotanicalTheme.anchorAccent,
            interactive: false,
            shadowRadius: 12
        )
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .onTapGesture(perform: onTap)
    }
}
