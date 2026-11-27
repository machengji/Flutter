import SwiftUI
import UIKit

/// 全屏沉浸式「AI 全景思维导图」画布（类 XMind 横向贝塞尔曲线树 + 双指缩放/单指拖拽 + 分支折叠 + 状态筛选 + 高清导出相册）
struct AiMindMapFullScreenView: View {
    enum NodeFilter: String, CaseIterable, Identifiable {
        case all = "全部"
        case ongoing = "仅未完成"
        case completed = "仅已完成"
        var id: String { rawValue }
    }

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var proStore: ProStoreService
    @Environment(\.dismiss) private var dismiss

    @State private var filter: NodeFilter = .all
    @State private var collapsedIds: Set<String> = []
    @State private var isGenerating: Bool = false
    @State private var generationStartDate: Date? = nil
    @State private var generateTask: Task<Void, Never>? = nil
    @State private var streamStageText: String = "正在连接 AI 接口..."
    @State private var errorMessage: String? = nil
    @State private var toastMessage: String? = nil
    @State private var isExporting: Bool = false
    @State private var showApiConfigAlert: Bool = false
    @State private var showSettingsSheet: Bool = false
    @State private var showProPaywall: Bool = false

    // 无限画布平移与缩放状态
    @State private var scale: CGFloat = 0.85
    @State private var lastScale: CGFloat = 0.85
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let branchColors: [Color] = [
        Color(hex: 0x2D6A4F), // 翡翠森绿
        Color(hex: 0xD97706), // 暖阳琥珀
        Color(hex: 0xD95D39), // 珊瑚赤陶
        Color(hex: 0x2B6CB0), // 雾湖靛蓝
        Color(hex: 0x7C3AED), // 薰衣草紫
        Color(hex: 0x0F766E)  // 溪流青碧
    ]

    var body: some View {
        ZStack {
            // 1. 柔和手账点阵画布背景
            dotGridBackground
                .ignoresSafeArea()

            // 2. 无限缩放与拖拽导图舞台
            if let doc = appState.cachedMindMap {
                let filteredRoot = applyFilter(to: doc.root)
                let layout = buildLayout(root: filteredRoot)

                GeometryReader { geo in
                    mindMapCanvasContent(layout: layout)
                        .frame(width: layout.canvasSize.width, height: layout.canvasSize.height)
                        .scaleEffect(scale)
                        .offset(offset)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { val in
                                    offset = CGSize(
                                        width: lastOffset.width + val.translation.width,
                                        height: lastOffset.height + val.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .simultaneousGesture(
                            MagnificationGesture()
                                .onChanged { val in
                                    scale = max(0.35, min(2.2, lastScale * val))
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                }
                        )
                }
                .ignoresSafeArea()
            } else {
                emptyOnboardingView
            }

            // 3. 顶部悬浮控制栏
            VStack(spacing: 8) {
                topToolbar

                if appState.cachedMindMap != nil {
                    filterPillBar
                }

                if let err = errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                        Text(err)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(2)
                        Spacer()
                        Button("关闭") { errorMessage = nil }
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(Color(hex: 0x991B1B))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(hex: 0xFEE2E2).opacity(0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 16)
                }

                if let toast = toastMessage {
                    Text(toast)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(BotanicalTheme.primaryDark.opacity(0.92))
                        .clipShape(Capsule())
                        .transition(.opacity)
                }

                Spacer()

                // 底部 AI 洞察摘要 + 右下角快捷控制按钮
                if let doc = appState.cachedMindMap {
                    HStack(alignment: .bottom, spacing: 10) {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 5) {
                                Text("AI 全景摘要")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(BotanicalTheme.primaryDark)
                                Spacer()
                                Text(BotanicalTheme.formatRelativeDate(epochMs: doc.generatedAtMs))
                                    .font(.system(size: 10))
                                    .foregroundColor(BotanicalTheme.textHint)
                            }
                            Text(doc.summary)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(BotanicalTheme.textSecondary)
                                .lineLimit(2)
                        }
                        .padding(.horizontal, 13)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.92))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(BotanicalTheme.primary.opacity(0.14), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)

                        VStack(spacing: 8) {
                            Button {
                                SensoryFeedbackService.shared.selection()
                                withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                                    scale = 0.85
                                    lastScale = 0.85
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            } label: {
                                Image(systemName: "scope")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(BotanicalTheme.primaryDark)
                                    .frame(width: 40, height: 40)
                                    .background(Color.white.opacity(0.94))
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.08), radius: 8, y: 3)
                            }

                            Button {
                                exportMindMapImage(doc: doc)
                            } label: {
                                Group {
                                    if isExporting {
                                        ProgressView()
                                            .tint(BotanicalTheme.primaryDark)
                                            .scaleEffect(0.75)
                                    } else {
                                        Image(systemName: "square.and.arrow.down")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(BotanicalTheme.primaryDark)
                                    }
                                }
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.94))
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.08), radius: 8, y: 3)
                            }
                            .disabled(isExporting)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)
                }
            }

            if isGenerating {
                Color.black.opacity(0.24)
                    .ignoresSafeArea()
                TimelineView(.periodic(from: .now, by: 0.25)) { timeline in
                    let elapsed = Int(max(0, timeline.date.timeIntervalSince(generationStartDate ?? timeline.date)))

                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(BotanicalTheme.primary)
                            .scaleEffect(1.15)
                        Text("AI 正在梳理你的微步全景")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(BotanicalTheme.textPrimary)
                        Text("\(streamStageText) · 已耗时 \(elapsed) 秒")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(BotanicalTheme.textSecondary)
                            .multilineTextAlignment(.center)

                        Button {
                            cancelAiGenerate()
                        } label: {
                            Text("取消生成")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(BotanicalTheme.textSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.06))
                                .clipShape(Capsule())
                        }
                        .padding(.top, 2)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(Color(hex: 0xFAF7F0).opacity(0.96))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: Color.black.opacity(0.14), radius: 22, y: 8)
                }
            }
        }
        .alert("尚未配置 AI 接口", isPresented: $showApiConfigAlert) {
            Button("去配置 API") {
                showSettingsSheet = true
            }
            Button("稍后再说", role: .cancel) {}
        } message: {
            Text("生成 AI 全景思维导图前，请先在「设置 → 自定义 AI 接口」中填入个人 API Key（支持免费硅基流动 / 智谱 / DeepSeek）。")
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsSheet()
                .liquidGlassSheet(detents: [.large], cornerRadius: 34)
        }
        .sheet(isPresented: $showProPaywall) {
            ProPaywallSheet()
        }
    }

    // MARK: - 顶部工具栏与空状态

    private var topToolbar: some View {
        HStack(spacing: 10) {
            Button {
                SensoryFeedbackService.shared.selection()
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(BotanicalTheme.primaryDark)
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.92))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.07), radius: 8, y: 3)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("AI 全景思维导图")
                    .font(.system(size: 15.5, weight: .bold))
                    .foregroundColor(BotanicalTheme.textPrimary)
                Text("双指缩放 · 单指拖动 · 点分支折叠")
                    .font(.system(size: 10.5))
                    .foregroundColor(BotanicalTheme.textSecondary)
            }

            Spacer()

            Button {
                triggerAiGenerate()
            } label: {
                Text(appState.cachedMindMap == nil ? "AI 生成" : "AI 重新梳理")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(BotanicalTheme.primaryGradient)
                    .clipShape(Capsule())
                    .shadow(color: BotanicalTheme.primary.opacity(0.28), radius: 8, y: 3)
            }
            .disabled(isGenerating)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    private var filterPillBar: some View {
        HStack(spacing: 6) {
            ForEach(NodeFilter.allCases) { item in
                let selected = (filter == item)
                Button {
                    SensoryFeedbackService.shared.selection()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                        filter = item
                    }
                } label: {
                    Text(item.rawValue)
                        .font(.system(size: 11.5, weight: selected ? .bold : .semibold))
                        .foregroundColor(selected ? .white : BotanicalTheme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5.5)
                        .background(selected ? BotanicalTheme.primaryDark : Color.white.opacity(0.88))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private var emptyOnboardingView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(BotanicalTheme.primarySoft.opacity(0.75))
                    .frame(width: 82, height: 82)
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(BotanicalTheme.primaryDark)
            }

            Text("一键生成你的 AI 全景思维导图")
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(BotanicalTheme.textPrimary)

            Text("AI 会自动读取你全部已完成、未完成的愿望、每日微习惯与时间锚点，按人生主题智能聚类成一张可缩放拖拽的高清导图。")
                .font(.system(size: 13.5))
                .foregroundColor(BotanicalTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 34)

            Button {
                triggerAiGenerate()
            } label: {
                Text("立即让 AI 梳理全景导图")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 13)
                    .background(BotanicalTheme.primaryGradient)
                    .clipShape(Capsule())
                    .shadow(color: BotanicalTheme.primary.opacity(0.30), radius: 12, y: 5)
            }
            .disabled(isGenerating)
        }
        .padding(24)
    }

    private var dotGridBackground: some View {
        ZStack {
            Color(hex: 0xFAF7F0)
            Canvas { ctx, size in
                let step: CGFloat = 24
                var x: CGFloat = 12
                while x < size.width {
                    var y: CGFloat = 12
                    while y < size.height {
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: 1.8, height: 1.8)),
                            with: .color(Color(hex: 0x2D6A4F).opacity(0.11))
                        )
                        y += step
                    }
                    x += step
                }
            }
        }
    }

    // MARK: - 专业横向贝塞尔曲线树布局引擎

    private struct PositionedNode: Identifiable {
        let id: String
        let node: AiMindMapNode
        let center: CGPoint
        let size: CGSize
        let color: Color
        let depth: Int
        let isCollapsed: Bool
    }

    private struct PositionedEdge: Identifiable {
        let id: String
        let from: CGPoint
        let to: CGPoint
        let color: Color
    }

    private struct MindMapLayout {
        let nodes: [PositionedNode]
        let edges: [PositionedEdge]
        let canvasSize: CGSize
    }

    private func applyFilter(to node: AiMindMapNode) -> AiMindMapNode {
        guard filter != .all else { return node }
        if node.children.isEmpty {
            return node
        }
        let keptChildren: [AiMindMapNode] = node.children.compactMap { child in
            if child.children.isEmpty {
                switch filter {
                case .all: return child
                case .ongoing:
                    return child.kind == "plan_done" ? nil : child
                case .completed:
                    return child.kind == "plan_done" ? child : nil
                }
            } else {
                let sub = applyFilter(to: child)
                return sub.children.isEmpty ? nil : sub
            }
        }
        return AiMindMapNode(id: node.id, title: node.title, kind: node.kind, meta: node.meta, children: keptChildren)
    }

    private func nodeBoxSize(for node: AiMindMapNode, depth: Int) -> CGSize {
        if depth == 0 {
            return CGSize(width: 158, height: 58)
        } else if node.kind == "domain" {
            return CGSize(width: 162, height: (node.meta?.isEmpty == false) ? 54 : 42)
        } else {
            return CGSize(width: 196, height: (node.meta?.isEmpty == false) ? 50 : 38)
        }
    }

    private func buildLayout(root: AiMindMapNode) -> MindMapLayout {
        let hGap: CGFloat = 62
        let vGap: CGFloat = 14
        let pad: CGFloat = 72

        func subtreeHeight(_ node: AiMindMapNode, depth: Int) -> CGFloat {
            let ownH = nodeBoxSize(for: node, depth: depth).height
            if node.children.isEmpty || collapsedIds.contains(node.id) {
                return ownH
            }
            let childrenH = node.children.reduce(CGFloat(0)) { acc, child in
                acc + subtreeHeight(child, depth: depth + 1)
            } + CGFloat(max(0, node.children.count - 1)) * vGap
            return max(ownH, childrenH)
        }

        var nodes: [PositionedNode] = []
        var edges: [PositionedEdge] = []
        var maxX: CGFloat = 0
        var maxY: CGFloat = 0

        func place(_ node: AiMindMapNode, depth: Int, leftX: CGFloat, topY: CGFloat, branchColor: Color) -> CGPoint {
            let box = nodeBoxSize(for: node, depth: depth)
            let totalH = subtreeHeight(node, depth: depth)
            let centerY = topY + totalH / 2
            let center = CGPoint(x: leftX + box.width / 2, y: centerY)
            let collapsed = collapsedIds.contains(node.id)

            nodes.append(PositionedNode(
                id: node.id,
                node: node,
                center: center,
                size: box,
                color: branchColor,
                depth: depth,
                isCollapsed: collapsed
            ))
            maxX = max(maxX, leftX + box.width)
            maxY = max(maxY, topY + totalH)

            if !node.children.isEmpty && !collapsed {
                let childTotalH = node.children.reduce(CGFloat(0)) { $0 + subtreeHeight($1, depth: depth + 1) }
                    + CGFloat(max(0, node.children.count - 1)) * vGap
                var curY = centerY - childTotalH / 2
                let nextX = leftX + box.width + hGap
                let parentAnchor = CGPoint(x: leftX + box.width, y: centerY)

                for (idx, child) in node.children.enumerated() {
                    let childColor = (depth == 0) ? branchColors[idx % branchColors.count] : branchColor
                    let childH = subtreeHeight(child, depth: depth + 1)
                    let childCenter = place(child, depth: depth + 1, leftX: nextX, topY: curY, branchColor: childColor)
                    let childBox = nodeBoxSize(for: child, depth: depth + 1)
                    let childAnchor = CGPoint(x: childCenter.x - childBox.width / 2, y: childCenter.y)
                    edges.append(PositionedEdge(
                        id: "\(node.id)->\(child.id)",
                        from: parentAnchor,
                        to: childAnchor,
                        color: childColor
                    ))
                    curY += childH + vGap
                }
            }
            return center
        }

        _ = place(root, depth: 0, leftX: pad, topY: pad, branchColor: BotanicalTheme.primaryDark)
        let canvasW = max(500, maxX + pad)
        let canvasH = max(500, maxY + pad)
        return MindMapLayout(nodes: nodes, edges: edges, canvasSize: CGSize(width: canvasW, height: canvasH))
    }

    @ViewBuilder
    private func mindMapCanvasContent(layout: MindMapLayout) -> some View {
        ZStack(alignment: .topLeading) {
            // 三次贝塞尔曲线连接线层
            Canvas { ctx, _ in
                for edge in layout.edges {
                    let midX = (edge.from.x + edge.to.x) / 2
                    var path = Path()
                    path.move(to: edge.from)
                    path.addCurve(
                        to: edge.to,
                        control1: CGPoint(x: midX, y: edge.from.y),
                        control2: CGPoint(x: midX, y: edge.to.y)
                    )
                    ctx.stroke(
                        path,
                        with: .color(edge.color.opacity(0.55)),
                        style: StrokeStyle(lineWidth: 2.0, lineCap: .round)
                    )
                }
            }
            .allowsHitTesting(false)

            // 导图节点卡片层
            ForEach(layout.nodes) { item in
                mindMapNodeCard(item)
                    .frame(width: item.size.width, height: item.size.height)
                    .position(item.center)
            }
        }
    }

    @ViewBuilder
    private func mindMapNodeCard(_ item: PositionedNode) -> some View {
        let node = item.node
        let hasChildren = !node.children.isEmpty

        Button {
            guard hasChildren && item.depth > 0 else { return }
            SensoryFeedbackService.shared.selection()
            withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                if collapsedIds.contains(node.id) {
                    collapsedIds.remove(node.id)
                } else {
                    collapsedIds.insert(node.id)
                }
            }
        } label: {
            if item.depth == 0 {
                VStack(spacing: 2) {
                    Text(node.title)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text("共 \(node.totalLeafCount) 项微步")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(BotanicalTheme.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: BotanicalTheme.primary.opacity(0.32), radius: 12, y: 5)
            } else if node.kind == "domain" {
                HStack(spacing: 6) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(node.title)
                            .font(.system(size: 13.5, weight: .bold))
                            .foregroundColor(item.color)
                            .lineLimit(1)
                        if let meta = node.meta, !meta.isEmpty {
                            Text(meta)
                                .font(.system(size: 10))
                                .foregroundColor(BotanicalTheme.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 2)
                    if hasChildren {
                        Text(item.isCollapsed ? "+\(node.children.count)" : "\(node.children.count)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(item.isCollapsed ? .white : item.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(item.isCollapsed ? item.color : item.color.opacity(0.14))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(item.color.opacity(0.55), lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: item.color.opacity(0.10), radius: 6, y: 2)
            } else {
                let style = leafStyle(for: node.kind)
                HStack(spacing: 7) {
                    Image(systemName: style.icon)
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(style.iconColor)
                    VStack(alignment: .leading, spacing: 1.5) {
                        Text(node.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(BotanicalTheme.textPrimary)
                            .strikethrough(node.kind == "plan_done", color: BotanicalTheme.textHint)
                            .lineLimit(1)
                        if let meta = node.meta, !meta.isEmpty {
                            Text(meta)
                                .font(.system(size: 9.5, weight: .medium))
                                .foregroundColor(style.iconColor.opacity(0.9))
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(style.bg)
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(style.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            }
        }
        .buttonStyle(.plain)
    }

    private func leafStyle(for kind: String) -> (icon: String, iconColor: Color, bg: Color, border: Color) {
        switch kind {
        case "plan_done":
            return ("checkmark.circle.fill", Color(hex: 0x15803D), Color(hex: 0xECFDF3), Color(hex: 0x86EFAC))
        case "habit":
            return ("leaf.fill", Color(hex: 0x0F766E), Color(hex: 0xF0FDFA), Color(hex: 0x99F6E4))
        case "anchor":
            return ("alarm.fill", Color(hex: 0xB45309), Color(hex: 0xFFFBEB), Color(hex: 0xFDE68A))
        default: // plan_ongoing
            return ("circle", Color(hex: 0x4C6B5B), Color.white.opacity(0.94), Color(hex: 0xD8E2DC))
        }
    }

    // MARK: - AI 生成与高清图片导出

    private func triggerAiGenerate() {
        SensoryFeedbackService.shared.lightTap()
        guard proStore.isPro else {
            showProPaywall = true
            return
        }
        guard appState.isAiApiConfigured else {
            showApiConfigAlert = true
            return
        }
        generateTask?.cancel()
        errorMessage = nil
        generationStartDate = Date()
        streamStageText = "正在连接 AI 接口..."
        isGenerating = true
        generateTask = Task {
            do {
                _ = try await appState.refreshAiMindMap { stage in
                    switch stage {
                    case .connecting:
                        streamStageText = "正在连接 AI 模型..."
                    case .thinking(let chars):
                        streamStageText = "AI 深度思考中（已收到 \(chars) 字）"
                    case .receiving(let chars):
                        streamStageText = "正在实时接收导图数据（\(chars) 字）"
                    case .assembling:
                        streamStageText = "正在本地组装思维导图..."
                    }
                }
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    isGenerating = false
                    generationStartDate = nil
                    generateTask = nil
                    collapsedIds.removeAll()
                    scale = 0.85
                    lastScale = 0.85
                    offset = .zero
                    lastOffset = .zero
                    showToast("AI 已完成全景思维导图梳理")
                }
            } catch is CancellationError {
                await MainActor.run {
                    isGenerating = false
                    generationStartDate = nil
                    generateTask = nil
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    isGenerating = false
                    generationStartDate = nil
                    generateTask = nil
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func cancelAiGenerate() {
        SensoryFeedbackService.shared.selection()
        generateTask?.cancel()
        generateTask = nil
        isGenerating = false
        generationStartDate = nil
        showToast("已取消思维导图生成")
    }

    @MainActor
    private func exportMindMapImage(doc: AiMindMapDocument) {
        guard !isExporting else { return }
        isExporting = true
        let layout = buildLayout(root: applyFilter(to: doc.root))
        let exportView = ZStack {
            Color(hex: 0xFAF7F0)
            mindMapCanvasContent(layout: layout)
        }
        .frame(width: layout.canvasSize.width, height: layout.canvasSize.height)

        let renderer = ImageRenderer(content: exportView)
        renderer.scale = 2.0
        if let uiImage = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            SensoryFeedbackService.shared.lightTap()
            showToast("高清思维导图已保存到相册")
        } else {
            showToast("导出失败，请重试")
        }
        isExporting = false
    }

    private func showToast(_ text: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            toastMessage = text
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeInOut(duration: 0.25)) {
                if toastMessage == text { toastMessage = nil }
            }
        }
    }
}
