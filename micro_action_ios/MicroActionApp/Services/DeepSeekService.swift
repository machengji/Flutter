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

/// 常见 OpenAI 兼容平台预设（一键填入接口地址与常用模型名）
enum AiProviderPreset: String, CaseIterable, Identifiable {
    case deepseek = "DeepSeek"
    case siliconflowFree = "硅基流动(免费)"
    case zhipuFree = "智谱(免费)"
    case aliyunTurbo = "阿里百炼"

    var id: String { rawValue }

    var baseURL: String {
        switch self {
        case .deepseek: return "https://api.deepseek.com/chat/completions"
        case .siliconflowFree: return "https://api.siliconflow.cn/v1/chat/completions"
        case .zhipuFree: return "https://open.bigmodel.cn/api/paas/v4/chat/completions"
        case .aliyunTurbo: return "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
        }
    }

    var modelName: String {
        switch self {
        case .deepseek: return "deepseek-chat"
        case .siliconflowFree: return "Qwen/Qwen2.5-7B-Instruct"
        case .zhipuFree: return "glm-4-flash"
        case .aliyunTurbo: return "qwen-turbo"
        }
    }
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
        case httpError(Int, String? = nil)
        case emptyResponse
        case invalidJSON

        var errorDescription: String? {
            switch self {
            case .missingApiKey: return "尚未配置 AI 接口，请前往「设置 → 自定义 AI 接口」填入个人 API Key"
            case .invalidEndpoint: return "AI 接口地址格式无效，请检查 Base URL"
            case .httpError(let code, let detail):
                if let detail, !detail.isEmpty {
                    return "AI 请求失败（HTTP \(code)）：\(detail)"
                }
                return "AI 服务请求失败（HTTP \(code)），请检查 Key 或模型名称"
            case .emptyResponse: return "AI 返回内容为空"
            case .invalidJSON: return "AI 返回数据格式解析失败"
            }
        }
    }

    enum MindMapStreamProgress: Sendable, Equatable {
        case connecting
        case thinking(chars: Int)
        case receiving(chars: Int)
        case assembling
    }

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300
        config.timeoutIntervalForResource = 320
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

    func fetchAvailableModels(baseURL: String, apiKey: String) async throws -> [String] {
        var trimmed = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            trimmed = "https://api.deepseek.com"
        }
        while trimmed.hasSuffix("/") { trimmed.removeLast() }
        if trimmed.hasSuffix("/chat/completions") {
            trimmed = String(trimmed.dropLast("/chat/completions".count)) + "/models"
        } else if !trimmed.hasSuffix("/models") {
            trimmed += "/models"
        }
        guard let url = URL(string: trimmed) else { throw ServiceError.invalidEndpoint }

        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw ServiceError.missingApiKey }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("MicroActionApp/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ServiceError.httpError(-1) }
        guard http.statusCode == 200 else {
            throw ServiceError.httpError(http.statusCode, extractServerErrorMessage(from: data))
        }

        struct ModelsResp: Decodable {
            struct Item: Decodable { let id: String }
            let data: [Item]?
        }
        let decoded = try JSONDecoder().decode(ModelsResp.self, from: data)
        return (decoded.data ?? []).map { $0.id }
    }

    private func extractServerErrorMessage(from data: Data) -> String? {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let err = json["error"] as? [String: Any],
           let msg = err["message"] as? String {
            return msg
        }
        let raw = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return raw.isEmpty ? nil : String(raw.prefix(160))
    }

    func testConnection() async throws -> String {
        return try await chat(
            systemPrompt: "你是连接测试助手。",
            userPrompt: "请只回复“连接成功”四个字。",
            temperature: 0.2,
            maxTokens: 20
        )
    }

    private func chat(
        systemPrompt: String,
        userPrompt: String,
        temperature: Double = 0.8,
        maxTokens: Int = 400,
        timeout: TimeInterval = 60
    ) async throws -> String {
        let key = apiKey
        guard !key.isEmpty else { throw ServiceError.missingApiKey }
        guard let url = endpointURL else { throw ServiceError.invalidEndpoint }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("MicroActionApp/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")

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
        guard http.statusCode == 200 else {
            throw ServiceError.httpError(http.statusCode, extractServerErrorMessage(from: data))
        }

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

    /// SSE 流式请求（兼容 delta.content、推理模型 delta.reasoning_content，以及非流式 JSON 回落）
    private func chatStream(
        systemPrompt: String,
        userPrompt: String,
        temperature: Double = 0.35,
        maxTokens: Int = 1500,
        timeout: TimeInterval = 300,
        onProgress: (@Sendable (MindMapStreamProgress) -> Void)? = nil
    ) async throws -> String {
        let key = apiKey
        guard !key.isEmpty else { throw ServiceError.missingApiKey }
        guard let url = endpointURL else { throw ServiceError.invalidEndpoint }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream, application/json", forHTTPHeaderField: "Accept")
        request.setValue("MicroActionApp/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")

        let payload: [String: Any] = [
            "model": modelName,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": temperature,
            "max_tokens": maxTokens,
            "stream": true
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        onProgress?(.connecting)

        let (bytes, response) = try await session.bytes(for: request)
        guard let http = response as? HTTPURLResponse else { throw ServiceError.httpError(-1) }

        guard http.statusCode == 200 else {
            var errData = Data()
            for try await b in bytes {
                errData.append(b)
                if errData.count > 4096 { break }
            }
            throw ServiceError.httpError(http.statusCode, extractServerErrorMessage(from: errData))
        }

        struct StreamChunk: Decodable {
            struct Choice: Decodable {
                struct Delta: Decodable {
                    let content: String?
                    let reasoning_content: String?
                }
                struct Msg: Decodable {
                    let content: String?
                }
                let delta: Delta?
                let message: Msg?
            }
            let choices: [Choice]?
        }

        var contentBuffer = ""
        var thinkingChars = 0
        var rawFallbackBuffer = ""
        var lastReportedChars = -1

        for try await line in bytes.lines {
            try Task.checkCancellation()
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }

            if trimmed.hasPrefix("data:") {
                let dataStr = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
                if dataStr == "[DONE]" { break }
                guard let chunkData = dataStr.data(using: .utf8),
                      let chunk = try? JSONDecoder().decode(StreamChunk.self, from: chunkData),
                      let choice = chunk.choices?.first else {
                    continue
                }
                if let r = choice.delta?.reasoning_content, !r.isEmpty {
                    thinkingChars += r.count
                    if thinkingChars - lastReportedChars >= 16 || lastReportedChars < 0 {
                        lastReportedChars = thinkingChars
                        onProgress?(.thinking(chars: thinkingChars))
                    }
                }
                if let piece = choice.delta?.content ?? choice.message?.content, !piece.isEmpty {
                    contentBuffer += piece
                    if contentBuffer.count - lastReportedChars >= 12 || lastReportedChars < 0 {
                        lastReportedChars = contentBuffer.count
                        onProgress?(.receiving(chars: contentBuffer.count))
                    }
                }
            } else {
                // 若中转站忽略 stream=true 直接返回普通 JSON
                rawFallbackBuffer += trimmed
            }
        }

        let finalContent = contentBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        if !finalContent.isEmpty {
            return finalContent
        }

        if let fallbackData = rawFallbackBuffer.data(using: .utf8),
           let full = try? JSONDecoder().decode(StreamChunk.self, from: fallbackData),
           let msg = full.choices?.first?.message?.content?.trimmingCharacters(in: .whitespacesAndNewlines),
           !msg.isEmpty {
            return msg
        }

        throw ServiceError.emptyResponse
    }

    private func stripCodeFences(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        // 剥离推理模型（如 R1）可能附带的 <think>...</think> 思考过程
        if let thinkRange = text.range(of: "<think>[\\s\\S]*?</think>", options: .regularExpression) {
            text.removeSubrange(thinkRange)
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if text.hasPrefix("```json") {
            text = String(text.dropFirst(7))
        } else if text.hasPrefix("```") {
            text = String(text.dropFirst(3))
        }
        if text.hasSuffix("```") {
            text = String(text.dropLast(3))
        }
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // 精准截取外层 JSON 对象，防止模型前后夹带说明文字导致解析失败
        if let firstBrace = text.firstIndex(of: "{"),
           let lastBrace = text.lastIndex(of: "}"),
           firstBrace <= lastBrace {
            return String(text[firstBrace...lastBrace])
        }
        return text
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

    /// 5. AI 全景思维导图聚类（SSE 流式 + 极简编号聚类协议 + 120s 宽松总超时）
    func generateFullMindMap(
        plans: [PlanItem],
        habits: [HabitItem],
        anchors: [AnchorItem],
        onProgress: (@Sendable (MindMapStreamProgress) -> Void)? = nil
    ) async throws -> AiMindMapDocument {
        struct IndexedEntry {
            let idx: Int
            let nodeId: String
            let title: String
            let kind: String
            let meta: String?
            let promptTag: String
        }

        let ongoingPlans = plans.filter { $0.status == .ongoing }
        let completedPlans = plans.filter { $0.status == .completed }

        var entries: [IndexedEntry] = []
        var nextIdx = 0

        for p in ongoingPlans.prefix(60) {
            var tags: [String] = []
            if p.isMainContradiction { tags.append("主要矛盾") }
            if p.isEasyToHandle { tags.append("很好处理") }
            let meta = tags.isEmpty ? nil : tags.joined(separator: "·")
            entries.append(IndexedEntry(
                idx: nextIdx,
                nodeId: "p_\(p.id)",
                title: p.name,
                kind: "plan_ongoing",
                meta: meta,
                promptTag: "进行愿望"
            ))
            nextIdx += 1
        }

        for p in completedPlans.prefix(50) {
            entries.append(IndexedEntry(
                idx: nextIdx,
                nodeId: "pd_\(p.id)",
                title: p.name,
                kind: "plan_done",
                meta: nil,
                promptTag: "完成愿望"
            ))
            nextIdx += 1
        }

        for h in habits.prefix(40) {
            let statusStr = h.status == .active ? "进行中" : "已停用"
            let meta = "累计\(h.totalDays)次 · \(statusStr)"
            entries.append(IndexedEntry(
                idx: nextIdx,
                nodeId: "h_\(h.id)",
                title: h.name,
                kind: "habit",
                meta: meta,
                promptTag: "微习惯"
            ))
            nextIdx += 1
        }

        for a in anchors.prefix(30) {
            let meta = "\(a.scheduleLabel) \(a.triggerTime)" + (a.alarmEnabled ? " 闹钟" : "")
            entries.append(IndexedEntry(
                idx: nextIdx,
                nodeId: "a_\(a.id)",
                title: a.name,
                kind: "anchor",
                meta: meta,
                promptTag: "锚点"
            ))
            nextIdx += 1
        }

        guard !entries.isEmpty else {
            throw NSError(
                domain: "DeepSeekService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "当前还没有任何愿望、习惯或锚点记录，请先添加后再生成思维导图"]
            )
        }

        let compactLines = entries.map { e in
            let shortName = e.title.count > 24 ? String(e.title.prefix(24)) + "…" : e.title
            return "[\(e.idx)]\(e.promptTag):\(shortName)"
        }.joined(separator: "\n")

        let systemPrompt = """
        你是个人成长知识架构师。请把用户编号条目按人生/生活主题聚类为 3~6 个均衡的一级领域。
        注意：你只需要输出编号数组，绝对不要复写条目原名！严格输出纯 JSON：
        {"summary":"25~40字总结格局与亮点","domains":[{"title":"4~8字领域名","meta":"6~12字领域状态","ids":[0,1,2]}]}
        规则：每个编号 0...\(entries.count - 1) 只分配一次，尽量全部覆盖。
        """

        let userPrompt = "共\(entries.count)条：\n\(compactLines)"

        let raw = try await chatStream(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.35,
            maxTokens: 1500,
            timeout: 300,
            onProgress: onProgress
        )
        onProgress?(.assembling)
        let cleaned = stripCodeFences(raw)

        struct CompactClusterPayload: Decodable {
            struct DomainGroup: Decodable {
                let title: String
                let meta: String?
                let ids: [Int]?
            }
            let summary: String?
            let domains: [DomainGroup]?
        }

        guard let data = cleaned.data(using: .utf8),
              let cluster = try? JSONDecoder().decode(CompactClusterPayload.self, from: data),
              let groups = cluster.domains,
              !groups.isEmpty else {
            throw ServiceError.invalidJSON
        }

        // 本地毫秒级组装完整树结构，并确保任何未归类的条目也不遗漏
        var assigned = Set<Int>()
        var domainNodes: [AiMindMapNode] = []

        for (gIdx, g) in groups.enumerated() {
            var leafNodes: [AiMindMapNode] = []
            for rawId in (g.ids ?? []) {
                guard rawId >= 0, rawId < entries.count, !assigned.contains(rawId) else { continue }
                assigned.insert(rawId)
                let e = entries[rawId]
                leafNodes.append(AiMindMapNode(
                    id: e.nodeId,
                    title: e.title,
                    kind: e.kind,
                    meta: e.meta,
                    children: []
                ))
            }
            guard !leafNodes.isEmpty else { continue }
            domainNodes.append(AiMindMapNode(
                id: "d_\(gIdx)",
                title: g.title.isEmpty ? "生活主题" : g.title,
                kind: "domain",
                meta: g.meta,
                children: leafNodes
            ))
        }

        let unassigned = entries.filter { !assigned.contains($0.idx) }
        if !unassigned.isEmpty {
            let extraLeaves = unassigned.map { e in
                AiMindMapNode(id: e.nodeId, title: e.title, kind: e.kind, meta: e.meta, children: [])
            }
            domainNodes.append(AiMindMapNode(
                id: "d_extra",
                title: "其他日常记录",
                kind: "domain",
                meta: "共\(extraLeaves.count)项待归类",
                children: extraLeaves
            ))
        }

        guard !domainNodes.isEmpty else {
            throw ServiceError.invalidJSON
        }

        let rootNode = AiMindMapNode(
            id: "root",
            title: "我的微步全景",
            kind: "root",
            meta: "共\(entries.count)项记录",
            children: domainNodes
        )

        let summaryText = (cluster.summary ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return AiMindMapDocument(
            root: rootNode,
            summary: summaryText.isEmpty ? "已为你将 \(entries.count) 项微步记录按生活主题完成智能聚类" : summaryText,
            generatedAtMs: Int64(Date().timeIntervalSince1970 * 1000)
        )
    }
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
