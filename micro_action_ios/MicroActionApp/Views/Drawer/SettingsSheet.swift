import SwiftUI
import UIKit

/// 数据管理与苹果生态同步设置（无任何外部 API Key 入口）
struct SettingsSheet: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var proStore: ProStoreService
    @Environment(\.dismiss) private var dismiss

    @State private var importJSONText: String = ""
    @State private var showImportDialog: Bool = false
    @State private var feedbackMessage: String? = nil
    @State private var isSyncingReminders: Bool = false

    var body: some View {
        NavigationStack {
            List {
                if let msg = feedbackMessage {
                    Section {
                        Text(msg)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(BotanicalTheme.primaryDark)
                    }
                }

                Section {
                    Toggle(isOn: Binding(
                        get: { proStore.isPro && appState.twoWayRemindersSync },
                        set: { newVal in
                            if !proStore.isPro {
                                appState.showProPaywall = true
                            } else {
                                appState.setTwoWayRemindersSync(newVal)
                            }
                        }
                    )) {
                        HStack(spacing: 6) {
                            Text("iOS 提醒事项双向同步")
                            proTag
                        }
                    }
                    .tint(BotanicalTheme.primary)

                    Toggle(isOn: Binding(
                        get: { proStore.isPro && appState.autoCalendarFootprint },
                        set: { newVal in
                            if !proStore.isPro {
                                appState.showProPaywall = true
                            } else {
                                appState.setAutoCalendarFootprint(newVal)
                            }
                        }
                    )) {
                        HStack(spacing: 6) {
                            Text("完成足迹自动记入系统日历")
                            proTag
                        }
                    }
                    .tint(BotanicalTheme.primary)

                    Button {
                        if !proStore.isPro {
                            appState.showProPaywall = true
                            return
                        }
                        isSyncingReminders = true
                        Task {
                            let res = await appState.syncWithAppleReminders()
                            await MainActor.run {
                                isSyncingReminders = false
                                feedbackMessage = "双向同步完成：导入 \(res.imported) 项，同步完成 \(res.completed) 项"
                            }
                        }
                    } label: {
                        HStack {
                            Text(isSyncingReminders ? "正在同步系统提醒事项..." : "立即双向对齐「微行动」提醒列表")
                                .foregroundColor(BotanicalTheme.primary)
                            Spacer()
                            if isSyncingReminders {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isSyncingReminders)
                } header: {
                    Text("苹果全家桶生态（Pro）")
                }

                Section("本地数据备份") {
                    Button {
                        do {
                            let json = try appState.exportBackupJSON()
                            UIPasteboard.general.string = json
                            feedbackMessage = "完整备份 JSON 已复制到剪贴板，可粘贴保存至备忘录或文件"
                        } catch {
                            feedbackMessage = "导出失败：\(error.localizedDescription)"
                        }
                    } label: {
                        Label("导出完整数据 JSON 到剪贴板", systemImage: "doc.on.doc")
                            .foregroundColor(BotanicalTheme.textPrimary)
                    }

                    Button {
                        showImportDialog = true
                    } label: {
                        Label("从 JSON 文本恢复数据", systemImage: "square.and.arrow.down")
                            .foregroundColor(BotanicalTheme.textPrimary)
                    }
                }
            }
            .navigationTitle("数据与苹果同步")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(BotanicalTheme.primary)
                }
            }
            .sheet(isPresented: $showImportDialog) {
                NavigationStack {
                    VStack(spacing: 14) {
                        Text("粘贴之前导出的 JSON 备份内容")
                            .font(.system(size: 13))
                            .foregroundColor(BotanicalTheme.textSecondary)
                        TextEditor(text: $importJSONText)
                            .font(.system(size: 12, design: .monospaced))
                            .padding(8)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(BotanicalTheme.border))
                        Button("确认恢复") {
                            do {
                                try appState.importBackupJSON(importJSONText)
                                feedbackMessage = "数据恢复成功"
                                importJSONText = ""
                                showImportDialog = false
                            } catch {
                                feedbackMessage = "恢复失败：\(error.localizedDescription)"
                            }
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(BotanicalTheme.primary)
                        .clipShape(Capsule())
                    }
                    .padding(20)
                    .navigationTitle("恢复备份")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("取消") { showImportDialog = false }
                        }
                    }
                }
            }
        }
    }

    private var proTag: some View {
        Text("PRO")
            .font(.system(size: 9, weight: .heavy))
            .foregroundColor(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color(hex: 0xD97706))
            .clipShape(Capsule())
    }
}
