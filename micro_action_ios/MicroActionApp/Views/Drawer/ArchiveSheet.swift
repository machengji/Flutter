import SwiftUI

/// 已归档任务收纳与恢复视图
struct ArchiveSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if appState.archivedPlans.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 36))
                            .foregroundColor(BotanicalTheme.textHint)
                        Text("暂无已归档任务")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(BotanicalTheme.textSecondary)
                    }
                } else {
                    List {
                        ForEach(appState.archivedPlans) { plan in
                            HStack {
                                Text(plan.name)
                                    .font(.system(size: 15))
                                Spacer()
                                Button("恢复") {
                                    appState.restoreArchivedPlan(id: plan.id)
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(BotanicalTheme.primary)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    appState.deletePlan(id: plan.id)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("已归档任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(BotanicalTheme.primary)
                }
            }
        }
    }
}
