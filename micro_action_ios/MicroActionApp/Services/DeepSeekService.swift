import Foundation

/// AI 全周期数据分析报告模型
struct AiAnalyticsReport: Codable, Sendable {
    struct HabitRank: Codable, Identifiable, Sendable {
        var id: String { name }
        let name: String
        let count: Int
    }

    struct LifeDimensions: Codable, Sendable {
        let health: Int
        let family: Int
        let career: Int
        let learning: Int
        let leisure: Int
        let wealth: Int
    }

    let summary: String
    let habitRank: [HabitRank]
    let lifeDimensions: LifeDimensions
    let highlights: [String]?
    let bottlenecks: [String]?
    let actionSuggestions: [String]?

    enum CodingKeys: String, CodingKey {
        case summary
        case habitRank = "habit_rank"
        case lifeDimensions = "life_dimensions"
        case highlights
        case bottlenecks
        case actionSuggestions = "action_suggestions"
    }

    init(
        summary: String,
        habitRank: [HabitRank],
        lifeDimensions: LifeDimensions,
        highlights: [String]? = nil,
        bottlenecks: [String]? = nil,
        actionSuggestions: [String]? = nil
    ) {
        self.summary = summary
        self.habitRank = habitRank
        self.lifeDimensions = lifeDimensions
        self.highlights = highlights
        self.bottlenecks = bottlenecks
        self.actionSuggestions = actionSuggestions
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        summary = try c.decode(String.self, forKey: .summary)
        habitRank = (try? c.decodeIfPresent([HabitRank].self, forKey: .habitRank)) ?? []
        lifeDimensions = try c.decode(LifeDimensions.self, forKey: .lifeDimensions)
        highlights = try? c.decodeIfPresent([String].self, forKey: .highlights)
        bottlenecks = try? c.decodeIfPresent([String].self, forKey: .bottlenecks)
        actionSuggestions = try? c.decodeIfPresent([String].self, forKey: .actionSuggestions)
    }
}

/// 单任务 AI 深度剖析结果模型
struct SinglePlanDiagnosis: Codable, Sendable {
    let difficultyScore: Int
    let difficultyReason: String
    let likelyBlocker: String
    let microSteps: [String]
    let suggestedAnchor: String

    enum CodingKeys: String, CodingKey {
        case difficultyScore = "difficulty_score"
        case difficultyReason = "difficulty_reason"
        case likelyBlocker = "likely_blocker"
        case microSteps = "micro_steps"
        case suggestedAnchor = "suggested_anchor"
    }
}

/// 常见 OpenAI 兼容平台预设（一键填入接口地址与高性价比/免费模型名）
enum AiProviderPreset: String, CaseIterable, Identifiable {
    case opencodeZen = "OpenCode Zen(免费)"
    case siliconflowFree = "硅基流动(免费)"
    case zhipuFree = "智谱(免费)"
    case aliyunTurbo = "阿里百炼"
    case deepseek = "DeepSeek"

    var id: String { rawValue }

    var baseURL: String {
        switch self {
        case .opencodeZen: return "https://opencode.ai/zen/v1/chat/completions"
        case .siliconflowFree: return "https://api.siliconflow.cn/v1/chat/completions"
        case .zhipuFree: return "https://open.bigmodel.cn/api/paas/v4/chat/completions"
        case .aliyunTurbo: return "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
        case .deepseek: return "https://api.deepseek.com/chat/completions"
        }
    }

    var modelName: String {
        switch self {
        case .opencodeZen: return "big-pickle"
        case .siliconflowFree: return "Qwen/Qwen2.5-7B-Instruct"
        case .zhipuFree: return "glm-4-flash"
        case .aliyunTurbo: return "qwen-turbo"
        case .deepseek: return "deepseek-chat"
        }
    }

    /// OpenCode Zen 常见免费模型参考（实时可用列表可通过 /v1/models 刷新）
    static let openCodeFreeModels: [String] = [
        "big-pickle",
        "deepseek-v4.1-flash-free",
        "minimax-m2.5-free",
        "mimo-v2.6-flash-free",
        "mimo-v2-pro-free",
        "nemotron-3-super-free",
        "flint-40b-free"
    ]
}

/// 本地持久化用户自定义 AI 接口配置（纯本地存储，不经任何中转服务器）
struct AiApiConfig: Equatable {
    var baseURL: String
    var apiKey: String
    var model: String

    private static let baseUrlKey = "micro_action_custom_ai_base_url"
    private static let apiKeyKey = "micro_action_custom_ai_api_key"
    private static let modelKey = "micro_action_custom_ai_model"

    static func load() -> AiApiConfig {
        let d = UserDefaults.standard
        return AiApiConfig(
            baseURL: d.string(forKey: baseUrlKey) ?? "",
            apiKey: d.string(forKey: apiKeyKey) ?? "",
            model: d.string(forKey: modelKey) ?? ""
        )
    }

    func save() {
        let d = UserDefaults.standard
        d.set(baseURL.trimmingCharacters(in: .whitespacesAndNewlines), forKey: Self.baseUrlKey)
        d.set(apiKey.trimmingCharacters(in: .whitespacesAndNewlines), forKey: Self.apiKeyKey)
        d.set(model.trimmingCharacters(in: .whitespacesAndNewlines), forKey: Self.modelKey)
    }

    static func clear() {
        let d = UserDefaults.standard
        d.removeObject(forKey: baseUrlKey)
        d.removeObject(forKey: apiKeyKey)
        d.removeObject(forKey: modelKey)
    }
}

/// 统一 OpenAI 兼容 AI 服务（所有提示词全部本地精调内置，支持用户自带 API 地址 / Key / 模型）
final class DeepSeekService {
    enum ServiceError: LocalizedError {
        case missingApiKey
        case invalidEndpoint
        case httpError(Int)
        case emptyResponse
        case invalidJSON

        var errorDescription: String? {
            switch self {
            case .missingApiKey: return "尚未配置 AI 接口，请前往「设置 → 自定义 AI 接口」填入个人 API Key"
            case .invalidEndpoint: return "AI 接口地址格式无效，请检查 Base URL"
            case .httpError(let code): return "AI 服务请求失败（HTTP \(code)），请检查 Key 或模型名称"
            case .emptyResponse: return "AI 返回内容为空"
            case .invalidJSON: return "AI 返回数据格式解析失败"
            }
        }
    }

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 25
        return URLSession(configuration: config)
    }()

    private var apiKey: String {
        let userKey = AiApiConfig.load().apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !userKey.isEmpty { return userKey }
        let raw = (Bundle.main.object(forInfoDictionaryKey: "DEEPSEEK_API_KEY") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.hasPrefix("$(") { return "" }
        return raw
    }

    var isApiConfigured: Bool {
        !apiKey.isEmpty
    }

    private var endpointURL: URL? {
        let userUrl = AiApiConfig.load().baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !userUrl.isEmpty {
            return normalizeChatEndpoint(userUrl)
        }
        let raw = (Bundle.main.object(forInfoDictionaryKey: "DEEPSEEK_BASE_URL") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !raw.isEmpty && !raw.hasPrefix("$(") {
            return normalizeChatEndpoint(raw)
        }
        return URL(string: "https://api.deepseek.com/chat/completions")
    }

    private var modelName: String {
        let userModel = AiApiConfig.load().model.trimmingCharacters(in: .whitespacesAndNewlines)
        if !userModel.isEmpty { return userModel }
        let raw = (Bundle.main.object(forInfoDictionaryKey: "AI_MODEL") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !raw.isEmpty && !raw.hasPrefix("$(") { return raw }
        return "deepseek-chat"
    }

    private func normalizeChatEndpoint(_ raw: String) -> URL? {
        var trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        while trimmed.hasSuffix("/") { trimmed.removeLast() }
        if !trimmed.hasSuffix("/chat/completions") {
            trimmed += "/chat/completions"
        }
        return URL(string: trimmed)
    }

    private static let openCodeSessionKey = "micro_action_opencode_session_id"

    private var openCodeSessionId: String {
        let d = UserDefaults.standard
        if let existing = d.string(forKey: Self.openCodeSessionKey), !existing.isEmpty {
            return existing
        }
        let created = "ses_\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased().prefix(20))"
        d.set(created, forKey: Self.openCodeSessionKey)
        return created
    }

    func fetchAvailableModels(baseURL: String, apiKey: String) async throws -> [String] {
        var trimmed = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        while trimmed.hasSuffix("/") { trimmed.removeLast() }
        if trimmed.hasSuffix("/chat/completions") {
            trimmed = String(trimmed.dropLast("/chat/completions".count)) + "/models"
        } else if !trimmed.hasSuffix("/models") {
            trimmed += "/models"
        }
        guard let url = URL(string: trimmed) else { throw ServiceError.invalidEndpoint }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !key.isEmpty {
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            if url.host?.contains("opencode.ai") == true && key == "public" {
                request.setValue(openCodeSessionId, forHTTPHeaderField: "x-opencode-session")
            }
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ServiceError.httpError(-1) }
        guard http.statusCode == 200 else { throw ServiceError.httpError(http.statusCode) }

        struct ModelsResp: Decodable {
            struct Item: Decodable { let id: String }
            let data: [Item]?
        }
        let decoded = try JSONDecoder().decode(ModelsResp.self, from: data)
        let ids = (decoded.data ?? [])
            .map { $0.id }
            .filter { !$0.hasPrefix("muse-spark") } // muse-spark-* 仅支持 /v1/responses
        return ids
    }

    func testConnection() async throws -> String {
        return try await chat(
            systemPrompt: "你是连接测试助手。",
            userPrompt: "请只回复“连接成功”四个字。",
            temperature: 0.2,
            maxTokens: 20
        )
    }

    private func chat(systemPrompt: String, userPrompt: String, temperature: Double = 0.8, maxTokens: Int = 400) async throws -> String {
        let key = apiKey
        guard !key.isEmpty else { throw ServiceError.missingApiKey }
        guard let url = endpointURL else { throw ServiceError.invalidEndpoint }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        if url.host?.contains("opencode.ai") == true && key == "public" {
            request.setValue(openCodeSessionId, forHTTPHeaderField: "x-opencode-session")
        }

        let payload: [String: Any] = [
            "model": modelName,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": temperature,
            "max_tokens": maxTokens
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ServiceError.httpError(-1) }
        guard http.statusCode == 200 else { throw ServiceError.httpError(http.statusCode) }

        struct ChatResp: Decodable {
            struct Choice: Decodable {
                struct Msg: Decodable { let content: String? }
                let message: Msg?
            }
            let choices: [Choice]?
        }
        let decoded = try JSONDecoder().decode(ChatResp.self, from: data)
        let content = decoded.choices?.first?.message?.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !content.isEmpty else { throw ServiceError.emptyResponse }
        return content
    }

    private func stripCodeFences(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```json") {
            text = String(text.dropFirst(7))
        } else if text.hasPrefix("```") {
            text = String(text.dropFirst(3))
        }
        if text.hasSuffix("```") {
            text = String(text.dropLast(3))
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 1. AI 专属夸夸官（支持四大人设，紧扣用户刚完成的具体事项）
    func generatePersonalizedCelebration(actionTitle: String, persona: AiCelebrationPersona) async throws -> String {
        let cleanTitle = actionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let systemPrompt: String
        switch persona {
        case .sweetBestie:
            systemPrompt = "你是一位高情商、嘴超甜、懂福格微习惯的“嘴甜闺蜜夸夸官”。用户刚刚完成了一件微行动，请你紧扣这件具体的事，写 1 句极具画面感、温柔又让人嘴角疯狂上扬的专属彩虹屁。要求：不超过 48 个汉字，直接输出正文，不要加引号、前缀或解释。"
        case .tsundereRoast:
            systemPrompt = "你是一位嘴硬心软、擅长傲娇反差夸奖的“冷面吐槽夸夸官”。用户刚刚完成了一件微行动，请你先轻微傲娇吐槽一下，再狠狠肯定用户的执行力。要求：紧扣用户刚做的具体事项，不超过 48 个汉字，直接输出正文，不要加引号或解释。"
        case .domineeringCeo:
            systemPrompt = "你是一位自带反差喜感的“霸道总裁夸夸官”。用户刚刚完成了一件微行动，请你用夸张宠溺、气场全开的霸总口吻狠狠表扬用户。要求：紧扣用户刚做的具体事项，不超过 48 个汉字，趣味十足不油腻，直接输出正文，不要加引号或解释。"
        case .coldJokeMaster:
            systemPrompt = "你是一位极具幽默感的中文冷笑话大师。用户刚刚完成了一件微行动，请你紧扣这件具体的事，现场创作 1 条简短、反转有趣、让人忍俊不禁的中文冷笑话来庆祝。要求：不超过 48 个汉字，直接输出冷笑话正文，不要加引号、序号或任何解释。"
        }

        let raw = try await chat(
            systemPrompt: systemPrompt,
            userPrompt: "我刚刚完成了：\(cleanTitle)",
            temperature: 0.9,
            maxTokens: 140
        )
        return raw.trimmingCharacters(in: CharacterSet(charactersIn: "「」『』\"“” "))
    }

    /// 2. AI 一键微行动拆解（把大目标拆成 3~5 个 2 分钟可动手的子步骤）
    func breakdownGoalToMicroSteps(goalTitle: String) async throws -> [String] {
        let systemPrompt = """
        你是一位精通福格微习惯与 ADHD 友好型任务拆解的行动教练。
        请将用户的目标拆解为 3 到 5 个极低门槛、2 分钟内就能马上动手的具体微行动步骤。
        严格要求：
        1. 必须仅返回纯 JSON 字符串数组，如 ["步骤1", "步骤2", "步骤3"]，禁止 Markdown 代码块或任何多余文字；
        2. 每条步骤必须是具体动词开头，简洁明了，不超过 18 个汉字，按先后执行顺序排列。
        """
        let raw = try await chat(
            systemPrompt: systemPrompt,
            userPrompt: "请帮我把目标拆成微步骤：\(goalTitle)",
            temperature: 0.7,
            maxTokens: 300
        )
        let cleaned = stripCodeFences(raw)
        guard let data = cleaned.data(using: .utf8),
              let steps = try? JSONDecoder().decode([String].self, from: data) else {
            throw ServiceError.invalidJSON
        }
        let filtered = steps.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard !filtered.isEmpty else { throw ServiceError.emptyResponse }
        return Array(filtered.prefix(5))
    }

    /// 3. 单任务 AI 深度剖析
    func analyzeSinglePlan(planName: String, subtasks: [String]) async throws -> SinglePlanDiagnosis {
        let systemPrompt = """
        你是一位基于福格行为模型（BJ Fogg）的个人效能教练。请分析用户的单条愿望并返回纯 JSON（严禁 Markdown 代码块）：
        {
          "difficulty_score": 1到10的整数,
          "difficulty_reason": "一句话说明阻力来源",
          "likely_blocker": "最可能卡壳的心理或执行障碍",
          "micro_steps": ["2分钟微步骤1", "微步骤2", "微步骤3"],
          "suggested_anchor": "推荐绑定的生活时间锚点（如：早饭后/晚间洗漱后）"
        }
        """
        let subDesc = subtasks.isEmpty ? "暂无子任务" : subtasks.joined(separator: "、")
        let raw = try await chat(
            systemPrompt: systemPrompt,
            userPrompt: "愿望名称：\(planName)\n已有子任务：\(subDesc)",
            temperature: 0.6,
            maxTokens: 450
        )
        let cleaned = stripCodeFences(raw)
        guard let data = cleaned.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(SinglePlanDiagnosis.self, from: data) else {
            throw ServiceError.invalidJSON
        }
        return decoded
    }

    /// 4. 全周期数据洞察与生命六维度全面深度评估
    func analyzeOverview(
        plansSummary: String,
        habitsSummary: String,
        anchorsSummary: String = "",
        todayShines: Int = 0,
        totalShines: Int
    ) async throws -> AiAnalyticsReport {
        let systemPrompt = """
        你是一位极简主义个人成长数据分析师。请基于用户的愿望（含主要矛盾）、微习惯、时间锚点与发光数据，给出高度凝练、直击要点的数据诊断。
        严禁长篇大论！严格输出纯 JSON（严禁 Markdown 代码块或额外解释）：
        {
          "summary": "35~55字一句话核心画像：点明当前主要矛盾推进度与核心节奏",
          "highlights": ["2条极简亮点，每条不超过18字"],
          "bottlenecks": ["2条核心卡点，每条不超过18字"],
          "action_suggestions": ["3条下周微行动指令（动词开头+时间/锚点，每条不超过22字）"],
          "habit_rank": [{"name": "习惯名", "count": 次数}],
          "life_dimensions": {
            "health": 0到10整数,
            "family": 0到10整数,
            "career": 0到10整数,
            "learning": 0到10整数,
            "leisure": 0到10整数,
            "wealth": 0到10整数
          }
        }
        """
        let userPrompt = """
        今日发光步数：\(todayShines)
        累计发光总步数：\(totalShines)
        【微行动愿望全量数据】
        \(plansSummary)
        【微习惯全量数据】
        \(habitsSummary)
        【时间锚点编排数据】
        \(anchorsSummary.isEmpty ? "暂无" : anchorsSummary)
        """
        let raw = try await chat(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.55,
            maxTokens: 1100
        )
        let cleaned = stripCodeFences(raw)
        guard let data = cleaned.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(AiAnalyticsReport.self, from: data) else {
            throw ServiceError.invalidJSON
        }
        return decoded
    }

    /// 5. AI 全景思维导图聚类（将全部未完成/已完成愿望、微习惯、时间锚点智能归类为多主题树）
    func generateFullMindMap(
        plans: [PlanItem],
        habits: [HabitItem],
        anchors: [AnchorItem]
    ) async throws -> AiMindMapDocument {
        let ongoingPlans = plans.filter { $0.status == .ongoing }
        let completedPlans = plans.filter { $0.status == .completed }

        let ongoingText = ongoingPlans.isEmpty ? "无" : ongoingPlans.prefix(60).map { p in
            var tags: [String] = []
            if p.isMainContradiction { tags.append("主要矛盾") }
            if p.isEasyToHandle { tags.append("很好处理") }
            return "- \(p.name)" + (tags.isEmpty ? "" : "（\(tags.joined(separator: "/"))）")
        }.joined(separator: "\n")

        let completedText = completedPlans.isEmpty ? "无" : completedPlans.prefix(60).map { p in
            "- \(p.name)"
        }.joined(separator: "\n")

        let habitsText = habits.isEmpty ? "无" : habits.prefix(40).map { h in
            let starter = (h.starterStep?.isEmpty == false) ? "，起步微步：\(h.starterStep!)" : ""
            return "- \(h.name)（\(h.status == .active ? "进行中" : "已停用")，累计\(h.totalDays)次\(starter)）"
        }.joined(separator: "\n")

        let anchorsText = anchors.isEmpty ? "无" : anchors.prefix(30).map { a in
            "- \(a.name)（\(a.scheduleLabel) \(a.triggerTime)\(a.alarmEnabled ? "，闹钟强提醒" : "")）"
        }.joined(separator: "\n")

        let systemPrompt = """
        你是一位顶级的个人成长知识架构师与思维导图专家。
        请把用户提供的全部「未完成愿望」「已完成愿望」「每日微习惯」「时间锚点」全部收纳进一张结构清晰、按人生/生活主题智能聚类的思维导图中，严禁遗漏重要条目！
        严格输出纯 JSON（严禁 Markdown 代码块或任何多余解释）：
        {
          "summary": "25~45字一句话总结这张全景思维导图的格局与亮点",
          "root": {
            "id": "root",
            "title": "我的微步全景",
            "kind": "root",
            "meta": "共X项记录",
            "children": [
              {
                "id": "d1",
                "title": "主题领域名（4~8字，如健康活力、事业精进、日常节奏）",
                "kind": "domain",
                "meta": "一句话领域状态（8~14字）",
                "children": [
                  {
                    "id": "n1",
                    "title": "原条目简洁名称",
                    "kind": "plan_ongoing 或 plan_done 或 habit 或 anchor",
                    "meta": "可选简短补充（如 累计12次 / 每天 08:30 / 主要矛盾）",
                    "children": []
                  }
                ]
              }
            ]
          }
        }
        规则：
        1. 一级分支（kind 必须为 "domain"）控制在 3~6 个自然主题域，尽量均衡。
        2. 叶子节点 kind 必须严格区分：未完成愿望用 "plan_ongoing"，已完成愿望用 "plan_done"，习惯用 "habit"，时间锚点用 "anchor"。
        3. 若有子主题需要再分一层，可再嵌套一层 domain，但最多不超过 3 层，保证导图清爽易读。
        """

        let userPrompt = """
        【进行中愿望（\(ongoingPlans.count)项）】
        \(ongoingText)

        【已完成愿望（\(completedPlans.count)项）】
        \(completedText)

        【微习惯（\(habits.count)项）】
        \(habitsText)

        【时间锚点（\(anchors.count)项）】
        \(anchorsText)
        """

        let raw = try await chat(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.45,
            maxTokens: 2800
        )
        let cleaned = stripCodeFences(raw)
        guard let data = cleaned.data(using: .utf8),
              let payload = try? JSONDecoder().decode(AiMindMapRawPayload.self, from: data) else {
            throw ServiceError.invalidJSON
        }
        return AiMindMapDocument(
            root: payload.root,
            summary: payload.summary,
            generatedAtMs: Int64(Date().timeIntervalSince1970 * 1000)
        )
    }
}

private struct AiMindMapRawPayload: Decodable {
    let summary: String
    let root: AiMindMapNode
}

/// AI 思维导图递归节点模型
struct AiMindMapNode: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let kind: String // "root" | "domain" | "plan_ongoing" | "plan_done" | "habit" | "anchor"
    let meta: String?
    let children: [AiMindMapNode]

    init(id: String = UUID().uuidString, title: String, kind: String, meta: String? = nil, children: [AiMindMapNode] = []) {
        self.id = id
        self.title = title
        self.kind = kind
        self.meta = meta
        self.children = children
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let rawId = try? c.decodeIfPresent(String.self, forKey: .id)
        id = (rawId?.isEmpty == false) ? rawId! : UUID().uuidString
        title = (try? c.decode(String.self, forKey: .title)) ?? "未命名节点"
        kind = (try? c.decodeIfPresent(String.self, forKey: .kind)) ?? "domain"
        meta = try? c.decodeIfPresent(String.self, forKey: .meta)
        children = (try? c.decodeIfPresent([AiMindMapNode].self, forKey: .children)) ?? []
    }

    var totalLeafCount: Int {
        if children.isEmpty { return kind == "root" ? 0 : 1 }
        return children.reduce(0) { $0 + $1.totalLeafCount }
    }
}

/// AI 全景思维导图缓存文档
struct AiMindMapDocument: Codable, Equatable, Sendable {
    let root: AiMindMapNode
    let summary: String
    let generatedAtMs: Int64
}
