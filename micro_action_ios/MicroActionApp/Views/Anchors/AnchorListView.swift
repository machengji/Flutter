import SwiftUI

/// 福格时间锚点列表视图
struct AnchorListView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedAnchorId: String? = nil

    private var selectedAnchor: AnchorItem? {
        appState.anchors.first(where: { $0.id == selectedAnchorId })
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if appState.anchors.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "clock.badge.checkmark")
                            .font(.system(size: 32))
                            .foregroundColor(BotanicalTheme.secondary)
                        Text("还没有设置时间锚点")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(BotanicalTheme.textPrimary)
                        Text("如「早上起床」「睡觉前」，把微习惯绑定到固定生活节点")
                            .font(.system(size: 13))
                            .foregroundColor(BotanicalTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 44)
                    .padding(.horizontal, 16)
                    .background(BotanicalTheme.surface.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(BotanicalTheme.border, lineWidth: 1))
                } else {
                    ForEach(appState.anchors) { anchor in
                        HStack(spacing: 14) {
                            Text(anchor.triggerTime)
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .foregroundColor(Color(hex: 0xB45309))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color(hex: 0xFEF3C7))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(anchor.name)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(BotanicalTheme.textPrimary)
                                Text("\(anchor.repeatCycle.rawValue) · 关联 \(anchor.planIds.count) 计划 / \(anchor.habitIds.count) 习惯")
                                    .font(.system(size: 12))
                                    .foregroundColor(BotanicalTheme.textSecondary)
                            }

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { anchor.reminderEnabled },
                                set: { _ in appState.toggleAnchorReminder(id: anchor.id) }
                            ))
                            .labelsHidden()
                            .tint(BotanicalTheme.primary)
                        }
                        .padding(14)
                        .background(BotanicalTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(BotanicalTheme.border, lineWidth: 1))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            SensoryFeedbackService.shared.selection()
                            selectedAnchorId = anchor.id
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
        .sheet(isPresented: Binding(
            get: { selectedAnchor != nil },
            set: { if !$0 { selectedAnchorId = nil } }
        )) {
            if let anchor = selectedAnchor {
                AnchorDetailSheet(anchorId: anchor.id)
            }
        }
    }
}
