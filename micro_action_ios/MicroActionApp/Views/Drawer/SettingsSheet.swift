import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// 标准 JSON 备份文件文档（支持原生 iOS「文件」App 导出与 iCloud 云盘保存）
struct TinyStepBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var jsonString: String

    init(jsonString: String = "{}") {
        self.jsonString = jsonString
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.jsonString = text
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(jsonString.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}

/// 数据管理与苹果生态同步设置（原生 JSON 文件导入/导出 + 液态玻璃卡片界面，无任何外部 Key 入口）
struct SettingsSheet: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var proStore: ProStoreService
    @Environment(\.dismiss) private var dismiss

    @State private var exportDocument: TinyStepBackupDocument? = nil
    @State private var showFileExporter: Bool = false
    @State private var showFileImporter: Bool = false
    @State private var pendingImportText: String? = nil
    @State private var pendingImportFileName: String = ""
    @State private var showRestoreConfirm: Bool = false
    @State private var feedbackMessage: String? = nil
    @State private var feedbackIsError: Bool = false
    @State private var isSyncingReminders: Bool = false
    @State private var customBaseUrl: String = ""
    @State private var customModel: String = ""
    @State private var customApiKey: String = ""
    @State private var isTestingAi: Bool = false
    @State private var openCodeModels: [String] = AiProviderPreset.openCodeFreeModels
    @State private var isFetchingModels: Bool = false

    private var defaultExportFileName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmm"
        return "微步备份_\(formatter.string(from: Date()))"
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if let msg = feedbackMessage {
                        HStack(spacing: 10) {
                            Image(systemName: feedbackIsError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(feedbackIsError ? BotanicalTheme.danger : BotanicalTheme.primary)
                            Text(msg)
                                .font(.system(size: 13.5, weight: .semibold))
                                .foregroundColor(BotanicalTheme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                        .liquidGlassCard(
                            cornerRadius: 18,
                            tint: feedbackIsError ? BotanicalTheme.danger : BotanicalTheme.primaryLight,
                            interactive: false,
                            shadowRadius: 8
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // 1. 本地 JSON 文件备份与恢复（核心原生文件交互）
                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("本地 JSON 文件备份与恢复", icon: "folder.badge.gearshape")

                        Button {
                            SensoryFeedbackService.shared.selection()
                            do {
                                let json = try appState.exportBackupJSON()
                                exportDocument = TinyStepBackupDocument(jsonString: json)
                                showFileExporter = true
                            } catch {
                                showFeedback("导出失败：\(error.localizedDescription)", isError: true)
                            }
                        } label: {
                            glassActionRow(
                                icon: "square.and.arrow.up.fill",
                                iconColor: BotanicalTheme.primary,
                                title: "导出 JSON 备份文件",
                                subtitle: "保存至 iPhone「文件」或 iCloud 云盘"
                            )
                        }
                        .buttonStyle(ScaleBounceButtonStyle(scale: 0.98))

                        Divider().opacity(0.45)

                        Button {
                            SensoryFeedbackService.shared.selection()
                            showFileImporter = true
                        } label: {
                            glassActionRow(
                                icon: "doc.badge.arrow.up.fill",
                                iconColor: BotanicalTheme.secondaryDark,
                                title: "从 JSON 文件恢复数据",
                                subtitle: "从「文件」App 选取 .json 备份一键还原"
                            )
                        }
                        .buttonStyle(ScaleBounceButtonStyle(scale: 0.98))
                    }
                    .padding(18)
                    .liquidGlassCard(cornerRadius: 24, tint: BotanicalTheme.primaryLight, interactive: false, shadowRadius: 12)

                    // 2. 苹果全家桶生态（Pro）
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 6) {
                            sectionTitle("苹果全家桶生态", icon: "applelogo")
                            proTag
                            Spacer()
                        }

                        Toggle(isOn: Binding(
                            get: { proStore.isPro && appState.twoWayRemindersSync },
                            set: { newVal in
                                SensoryFeedbackService.shared.selection()
                                if !proStore.isPro {
                                    appState.showProPaywall = true
                                } else {
                                    appState.setTwoWayRemindersSync(newVal)
                                }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("iOS 提醒事项双向同步")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(BotanicalTheme.textPrimary)
                                Text("自动同步待办愿望与系统提醒事项状态")
                                    .font(.system(size: 12))
                                    .foregroundColor(BotanicalTheme.textSecondary)
                            }
                        }
                        .tint(BotanicalTheme.primary)

                        Divider().opacity(0.45)

                        Toggle(isOn: Binding(
                            get: { proStore.isPro && appState.autoCalendarFootprint },
                            set: { newVal in
                                SensoryFeedbackService.shared.selection()
                                if !proStore.isPro {
                                    appState.showProPaywall = true
                                } else {
                                    appState.setAutoCalendarFootprint(newVal)
                                }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("完成足迹自动记入系统日历")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(BotanicalTheme.textPrimary)
                                Text("每次打卡后在专属日历留下成长足迹")
                                    .font(.system(size: 12))
                                    .foregroundColor(BotanicalTheme.textSecondary)
                            }
                        }
                        .tint(BotanicalTheme.primary)

                        Divider().opacity(0.45)

                        Button {
                            SensoryFeedbackService.shared.lightTap()
                            if !proStore.isPro {
                                appState.showProPaywall = true
                                return
                            }
                            isSyncingReminders = true
                            Task {
                                let res = await appState.syncWithAppleReminders()
                                await MainActor.run {
                                    isSyncingReminders = false
                                    showFeedback("双向同步完成：导入 \(res.imported) 项，同步完成 \(res.completed) 项", isError: false)
                                }
                            }
                        } label: {
                            HStack(spacing: 10) {
                                if isSyncingReminders {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.85)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                Text(isSyncingReminders ? "正在同步系统提醒事项..." : "立即双向对齐系统提醒列表")
                                    .font(.system(size: 14.5, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(BotanicalTheme.primaryGradient)
                            .clipShape(Capsule())
                            .shadow(color: BotanicalTheme.primary.opacity(0.24), radius: 10, y: 4)
                        }
                        .buttonStyle(ScaleBounceButtonStyle(scale: 0.97))
                        .disabled(isSyncingReminders)
                    }
                    .padding(18)
                    .liquidGlassCard(cornerRadius: 24, tint: BotanicalTheme.primaryLight, interactive: false, shadowRadius: 12)

                    // 3. 自定义 AI 接口（自带 API / Key / 模型，纯本地存储直连）
                    customAiConfigCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .liquidSheetCanvasBackground()
            .navigationTitle("设置与同步")
            .onAppear {
                let cfg = AiApiConfig.load()
                customBaseUrl = cfg.baseURL
                customModel = cfg.model
                customApiKey = cfg.apiKey
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        SensoryFeedbackService.shared.lightTap()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(BotanicalTheme.primary)
                }
            }
            .fileExporter(
                isPresented: $showFileExporter,
                document: exportDocument,
                contentType: .json,
                defaultFilename: defaultExportFileName
            ) { result in
                switch result {
                case .success(let url):
                    showFeedback("已成功导出备份文件：\(url.lastPathComponent)", isError: false)
                case .failure(let error):
                    showFeedback("导出已取消或失败：\(error.localizedDescription)", isError: true)
                }
            }
            .sheet(isPresented: $showFileImporter) {
                NativeJSONDocumentPicker { url in
                    showFileImporter = false
                    handleImportedURL(url)
                } onCancel: {
                    showFileImporter = false
                }
                .ignoresSafeArea()
            }
            .confirmationDialog(
                "确认从「\(pendingImportFileName)」恢复数据？",
                isPresented: $showRestoreConfirm,
                titleVisibility: .visible
            ) {
                Button("确认覆盖并恢复数据", role: .destructive) {
                    guard let jsonText = pendingImportText else { return }
                    do {
                        try appState.importBackupJSON(jsonText)
                        SensoryFeedbackService.shared.selection()
                        showFeedback("已从「\(pendingImportFileName)」成功恢复全部数据", isError: false)
                    } catch {
                        showFeedback("JSON 格式无效或恢复失败：\(error.localizedDescription)", isError: true)
                    }
                    pendingImportText = nil
                }
                Button("取消", role: .cancel) {
                    pendingImportText = nil
                }
            } message: {
                Text("将使用所选 JSON 文件中的愿望、微习惯、时间锚点与成长树记录覆盖当前本地数据。")
            }
        }
        .liquidGlassSheet(detents: [.large], cornerRadius: 34)
    }

    private func handleImportedURL(_ fileURL: URL) {
        let accessed = fileURL.startAccessingSecurityScopedResource()
        defer {
            if accessed { fileURL.stopAccessingSecurityScopedResource() }
        }
        do {
            let data = try Data(contentsOf: fileURL)
            guard let text = String(data: data, encoding: .utf8), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                showFeedback("所选文件为空或不是有效的 UTF-8 JSON 文件", isError: true)
                return
            }
            // 预先校验是否为合法 JSON 结构
            _ = try JSONSerialization.jsonObject(with: data)
            pendingImportText = text
            pendingImportFileName = fileURL.lastPathComponent
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                showRestoreConfirm = true
            }
        } catch {
            showFeedback("读取或解析 JSON 文件失败：\(error.localizedDescription)", isError: true)
        }
    }

    private func showFeedback(_ message: String, isError: Bool) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            feedbackIsError = isError
            feedbackMessage = message
        }
    }

    private func sectionTitle(_ title: String, icon: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 13.5, weight: .bold))
                .foregroundColor(BotanicalTheme.primary)
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(BotanicalTheme.textPrimary)
        }
    }

    private func glassActionRow(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.13))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(BotanicalTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(BotanicalTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundColor(BotanicalTheme.textHint)
        }
        .contentShape(Rectangle())
    }

    private var proTag: some View {
        Text("PRO")
            .font(.system(size: 9, weight: .heavy))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(BotanicalTheme.accentWarm)
            .clipShape(Capsule())
    }

    private var customAiConfigCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("自定义 AI 接口（自带 Key）", icon: "sparkles")
                Spacer()
                if !customApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("已配置")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundColor(BotanicalTheme.primaryDark)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(BotanicalTheme.primarySoft)
                        .clipShape(Capsule())
                }
            }

            Text("提示词全内置在本地，填入个人 API Key 即可使用愿望拆解与 AI 诊断；仅保存在本地设备。")
                .font(.system(size: 12))
                .foregroundColor(BotanicalTheme.textSecondary)
                .lineSpacing(3)

            // 常用平台一键预设
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(AiProviderPreset.allCases) { preset in
                        let selected = customBaseUrl == preset.baseURL && (preset == .opencodeZen || customModel == preset.modelName)
                        Button {
                            SensoryFeedbackService.shared.selection()
                            customBaseUrl = preset.baseURL
                            customModel = preset.modelName
                        } label: {
                            Text(preset.rawValue)
                                .font(.system(size: 11.5, weight: .semibold))
                                .foregroundColor(selected ? .white : BotanicalTheme.primaryDark)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(selected ? BotanicalTheme.primary : BotanicalTheme.primarySoft.opacity(0.75))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // OpenCode Zen 免费模型快捷切换 & 实时拉取
            if customBaseUrl.lowercased().contains("opencode.ai/zen") {
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text("OpenCode Zen 免费模型")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(BotanicalTheme.primaryDark)
                        Spacer()
                        Button {
                            SensoryFeedbackService.shared.lightTap()
                            isFetchingModels = true
                            Task {
                                do {
                                    let ids = try await DeepSeekService().fetchAvailableModels(
                                        baseURL: customBaseUrl,
                                        apiKey: customApiKey
                                    )
                                    await MainActor.run {
                                        isFetchingModels = false
                                        if ids.isEmpty {
                                            showFeedback("未从 /models 获取到可用模型", isError: true)
                                        } else {
                                            openCodeModels = ids
                                            if !ids.contains(customModel), let first = ids.first {
                                                customModel = first
                                            }
                                            showFeedback("已刷新 \(ids.count) 个 OpenCode 实时可用模型", isError: false)
                                        }
                                    }
                                } catch {
                                    await MainActor.run {
                                        isFetchingModels = false
                                        showFeedback("刷新模型失败：\(error.localizedDescription)", isError: true)
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                if isFetchingModels {
                                    ProgressView()
                                        .scaleEffect(0.6)
                                        .tint(BotanicalTheme.primaryDark)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                Text(isFetchingModels ? "刷新中..." : "刷新实时列表")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(BotanicalTheme.primaryDark)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(BotanicalTheme.primarySoft)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(isFetchingModels)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(openCodeModels, id: \.self) { model in
                                let isChosen = customModel == model
                                Button {
                                    SensoryFeedbackService.shared.selection()
                                    customModel = model
                                } label: {
                                    Text(model)
                                        .font(.system(size: 11, weight: isChosen ? .bold : .medium, design: .monospaced))
                                        .foregroundColor(isChosen ? .white : BotanicalTheme.textPrimary)
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 5)
                                        .background(isChosen ? BotanicalTheme.accentWarm : BotanicalTheme.surface)
                                        .overlay(
                                            Capsule().stroke(isChosen ? Color.clear : BotanicalTheme.borderSoft, lineWidth: 0.8)
                                        )
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    HStack(spacing: 8) {
                        Text("建议前往 opencode.ai/zen 获取个人 Key（免登录试用可填 public；暂不支持 muse-spark-*）")
                            .font(.system(size: 10.5))
                            .foregroundColor(BotanicalTheme.textSecondary)
                            .lineSpacing(2)
                        Spacer(minLength: 4)
                        if customApiKey.trimmingCharacters(in: .whitespacesAndNewlines) != "public" {
                            Button {
                                SensoryFeedbackService.shared.selection()
                                customApiKey = "public"
                            } label: {
                                Text("填入 public")
                                    .font(.system(size: 10.5, weight: .semibold))
                                    .foregroundColor(BotanicalTheme.primaryDark)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(BotanicalTheme.primarySoft.opacity(0.85))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(10)
                .background(BotanicalTheme.background.opacity(0.75))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(BotanicalTheme.borderSoft, lineWidth: 0.8)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            VStack(spacing: 8) {
                aiFieldRow(title: "接口地址", placeholder: "https://opencode.ai/zen/v1/chat/completions", text: $customBaseUrl, isSecure: false)
                aiFieldRow(title: "模型名称", placeholder: "big-pickle 或 deepseek-v4.1-flash-free", text: $customModel, isSecure: false)
                aiFieldRow(title: "API Key", placeholder: "sk-... 或 public", text: $customApiKey, isSecure: true)
            }

            HStack(spacing: 10) {
                Button {
                    SensoryFeedbackService.shared.lightTap()
                    AiApiConfig(baseURL: customBaseUrl, apiKey: customApiKey, model: customModel).save()
                    showFeedback("自定义 AI 接口配置已保存到本地", isError: false)
                } label: {
                    Text("保存配置")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(BotanicalTheme.primaryGradient)
                        .clipShape(Capsule())
                }
                .buttonStyle(ScaleBounceButtonStyle(scale: 0.97))

                Button {
                    SensoryFeedbackService.shared.lightTap()
                    AiApiConfig(baseURL: customBaseUrl, apiKey: customApiKey, model: customModel).save()
                    isTestingAi = true
                    Task {
                        do {
                            let reply = try await DeepSeekService().testConnection()
                            await MainActor.run {
                                isTestingAi = false
                                showFeedback("接口测试成功：\(reply)", isError: false)
                            }
                        } catch {
                            await MainActor.run {
                                isTestingAi = false
                                showFeedback("测试失败：\(error.localizedDescription)", isError: true)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        if isTestingAi {
                            ProgressView()
                                .tint(BotanicalTheme.primaryDark)
                                .scaleEffect(0.75)
                        }
                        Text(isTestingAi ? "测试中..." : "测试连接")
                            .font(.system(size: 13.5, weight: .bold))
                            .foregroundColor(BotanicalTheme.primaryDark)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(BotanicalTheme.primarySoft)
                    .clipShape(Capsule())
                }
                .buttonStyle(ScaleBounceButtonStyle(scale: 0.97))
                .disabled(isTestingAi)
            }
        }
        .padding(18)
        .liquidGlassCard(cornerRadius: 24, tint: BotanicalTheme.primaryLight, interactive: false, shadowRadius: 12)
    }

    private func aiFieldRow(title: String, placeholder: String, text: Binding<String>, isSecure: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundColor(BotanicalTheme.textSecondary)

            Group {
                if isSecure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                }
            }
            .font(.system(size: 13))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .background(Color.white.opacity(0.85))
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(BotanicalTheme.border, lineWidth: 0.9)
            )
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
    }
}

/// 基于 UIKit 原生 UIDocumentPickerViewController 的文件选择器
/// 关键配置：forOpeningContentTypes: [.item] + asCopy: true，确保 iPhone「我的 iPhone」「iCloud 云盘」「下载项」中任意 .json 文件 100% 高亮可选并安全复制到沙盒读取
private struct NativeJSONDocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        let onCancel: () -> Void

        init(onPick: @escaping (URL) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                onPick(url)
            } else {
                onCancel()
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onCancel()
        }
    }
}
