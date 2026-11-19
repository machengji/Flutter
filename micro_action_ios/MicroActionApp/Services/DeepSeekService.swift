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

/// 统一 DeepSeek AI 服务（仅由编译期 Info.plist/环境变量安全注入密钥，严禁在前端暴露 Key 配置入口）
final class DeepSeekService {
    enum ServiceError: LocalizedError {
        case missingApiKey
        case invalidEndpoint
        case httpError(Int)
        case emptyResponse
        case invalidJSON

        var errorDescription: String? {
            switch self {
            case .missingApiKey: return "AI 服务暂未就绪，请稍后再试"
            case .invalidEndpoint: return "AI 服务地址配置无效"
            case .httpError(let code): return "AI 服务请求失败（HTTP \(code)）"
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
        let raw = (Bundle.main.object(forInfoDictionaryKey: "DEEPSEEK_API_KEY") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.hasPrefix("$(") { return "" }
        return raw
    }

    private var endpointURL: URL? {
        let raw = (Bundle.main.object(forInfoDictionaryKey: "DEEPSEEK_BASE_URL") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !raw.isEmpty && !raw.hasPrefix("$(") {
            return URL(string: raw)
        }
        return URL(string: "https://api.deepseek.com/chat/completions")
    }

    private func chat(systemPrompt: String, userPrompt: String, temperature: Double = 0.8, maxTokens: Int = 400) async throws -> String {
        let key = apiKey
        guard !key.isEmpty else { throw ServiceError.missingApiKey }
        guard let url = endpointURL else { throw ServiceError.invalidEndpoint }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")

        let payload: [String: Any] = [
            "model": "deepseek-chat",
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
        你是一位基于福格行为模型（BJ Fogg）的个人效能教练。请分析用户的单条计划并返回纯 JSON（严禁 Markdown 代码块）：
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
            userPrompt: "计划名称：\(planName)\n已有子任务：\(subDesc)",
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
        你是一位资深个人成长与行为科学数据分析师。请基于用户真实的计划、微习惯、时间锚点与发光成长数据，做一次全面、具体、有洞察力且可落地的复盘。
        严格输出纯 JSON（严禁 Markdown 代码块或额外解释）：
        {
          "summary": "140~180字整体执行力画像：结合完成率、微习惯复利和当前重心，给出有温度的定性定量的总评",
          "highlights": ["2~3条结合具体数字与项目名的核心亮点与正向趋势"],
          "bottlenecks": ["2~3条客观指出的执行卡点、长期未推进项或生命维度失衡点"],
          "action_suggestions": ["3条立即可执行、颗粒度极小的下周微行动建议（明确做什么+什么时候/绑定什么锚点）"],
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
        【微行动计划全量数据】
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
}
