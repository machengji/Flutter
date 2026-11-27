import Foundation

/// 庆祝语料来源模式
enum QuoteSourceMode: String, Codable, CaseIterable, Sendable {
    case onlineFirst = "onlineFirst"
    case localOnly = "localOnly"

    var displayName: String {
        switch self {
        case .onlineFirst: return "在线接口优先"
        case .localOnly: return "仅本地离线库"
        }
    }
}

/// 庆祝语料双引擎服务（全年龄段纯净级）：
/// 1) 在线多源纯净轮询（今日诗词 + 一言文学诗词哲学 + 彩虹屁 + 夏柔一言 + 60s冷笑话），
///    错峰防限流，且全部返回值强制经过 HTML 净洗与全年龄段安全内容过滤器；
/// 2) 本地全年龄段纯净 zlib 压缩语料包（离线秒出 + 持久化 Fisher-Yates 洗牌跨重启防重复）。
actor QuoteNetworkService {
    private static let poolStatesKey = "micro_quotes_pool_states_v3"
    private static let onlineCacheRainbowKey = "quote_cache_rainbow_v3"
    private static let onlineCacheJokeKey = "quote_cache_joke_v3"

    // 旧版缓存键（升级后主动清除，防止残留未过滤的历史缓存）
    private static let legacyKeys = [
        "micro_quotes_pool_states_v2",
        "quote_cache_rainbow_v2",
        "quote_cache_joke_v2"
    ]

    private struct BundleCorpus: Decodable {
        let praise: [String]
        let healing: [String]
        let sweet: [String]
        let joke: [String]
        let witty: [String]
    }

    private enum PoolKey: String, CaseIterable {
        case praise, healing, sweet, joke, witty
    }

    private struct PoolCursorState: Codable {
        var seed: UInt64
        var cursor: Int
        var lastText: String?
    }

    private struct SeededRNG: RandomNumberGenerator {
        private var state: UInt64
        init(seed: UInt64) {
            self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
        }
        mutating func next() -> UInt64 {
            state &+= 0x9E3779B97F4A7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
            z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
            return z ^ (z >> 31)
        }
    }

    private var corpus: BundleCorpus?
    private var didAttemptLoad: Bool = false
    private var poolStates: [String: PoolCursorState] = [:]
    private var shuffledIndicesCache: [PoolKey: [Int]] = [:]

    private var onlineRainbowQueue: [String] = []
    private var onlineJokeQueue: [String] = []
    private var recentOnlineSet: [String] = []
    private var rainbowSourceCursor: Int = 0
    private var isWarmingUp: Bool = false

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 4.2
        config.timeoutIntervalForResource = 5.5
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148",
            "Accept": "application/json, text/plain, */*"
        ]
        return URLSession(configuration: config)
    }()

    init() {
        for legacy in Self.legacyKeys {
            UserDefaults.standard.removeObject(forKey: legacy)
        }
        if let data = UserDefaults.standard.data(forKey: Self.poolStatesKey),
           let decoded = try? JSONDecoder().decode([String: PoolCursorState].self, from: data) {
            self.poolStates = decoded
        }
        self.onlineRainbowQueue = (UserDefaults.standard.stringArray(forKey: Self.onlineCacheRainbowKey) ?? [])
            .compactMap { Self.sanitizeQuote($0) }
        self.onlineJokeQueue = (UserDefaults.standard.stringArray(forKey: Self.onlineCacheJokeKey) ?? [])
            .compactMap { Self.sanitizeQuote($0, maxLength: 82) }
    }

    /// 预热：本地解压 + 若开启在线模式则错峰补齐在线队列
    func warmUp(preferOnline: Bool = true) async {
        loadBundleIfNeeded()
        if preferOnline {
            await ensureWarmedUp(preferOnline: true)
        }
    }

    func ensureWarmedUp(preferOnline: Bool = true) async {
        loadBundleIfNeeded()
        guard preferOnline, !isWarmingUp else { return }
        isWarmingUp = true
        defer { isWarmingUp = false }

        // 错峰串行补货：相邻请求间隔 0.55s，严格遵守 Hitokoto QPS <= 2 限制
        var rainbowAttempts = 0
        while onlineRainbowQueue.count < 3 && rainbowAttempts < 6 {
            rainbowAttempts += 1
            await fetchNextRainbowFromOnline()
            if onlineRainbowQueue.count < 3 && rainbowAttempts < 6 {
                try? await Task.sleep(nanoseconds: 550_000_000)
            }
        }

        var jokeAttempts = 0
        while onlineJokeQueue.count < 3 && jokeAttempts < 5 {
            jokeAttempts += 1
            await fetchNextJokeFromOnline()
            if onlineJokeQueue.count < 3 && jokeAttempts < 5 {
                try? await Task.sleep(nanoseconds: 550_000_000)
            }
        }
        persistOnlineQueues()
    }

    /// 获取下一条纯净夸赞/雅致治愈语录
    func takeRainbowQuote(preferOnline: Bool = true) async -> String {
        loadBundleIfNeeded()
        if preferOnline {
            if onlineRainbowQueue.isEmpty {
                await fetchWithFastDeadline(timeoutSeconds: 1.8) {
                    await self.fetchNextRainbowFromOnline()
                }
            }
            Task { await self.ensureWarmedUp(preferOnline: true) }
            while !onlineRainbowQueue.isEmpty {
                let candidate = onlineRainbowQueue.removeFirst()
                if Self.isSafeCleanText(candidate), !recentOnlineSet.contains(candidate) {
                    recordOnlinePicked(candidate)
                    persistOnlineQueues()
                    return candidate
                }
            }
            persistOnlineQueues()
        }
        return takeLocalRainbowQuote()
    }

    /// 获取下一条纯净冷笑话/机灵脑洞
    func takeColdJokeQuote(preferOnline: Bool = true) async -> String {
        loadBundleIfNeeded()
        if preferOnline {
            if onlineJokeQueue.isEmpty {
                await fetchWithFastDeadline(timeoutSeconds: 1.8) {
                    await self.fetchNextJokeFromOnline()
                }
            }
            Task { await self.ensureWarmedUp(preferOnline: true) }
            while !onlineJokeQueue.isEmpty {
                let candidate = onlineJokeQueue.removeFirst()
                if Self.isSafeCleanText(candidate), !recentOnlineSet.contains(candidate) {
                    recordOnlinePicked(candidate)
                    persistOnlineQueues()
                    return candidate
                }
            }
            persistOnlineQueues()
        }
        return takeLocalColdJokeQuote()
    }

    // MARK: - 在线纯净多源轮询（已移除高危段子库与社区抖机灵）

    private func fetchNextRainbowFromOnline() async {
        // 优先保留并高频轮询原版彩虹屁接口（占 2/5 权重且为第 1 顺位），穿插今日诗词、一言文学诗词与夏柔一言
        let idx = rainbowSourceCursor % 5
        rainbowSourceCursor += 1

        let urlString: String
        let kind: Int // 0=shadiao, 1=jinrishici, 2=hitokoto, 3=aa1
        switch idx {
        case 0, 2:
            urlString = "https://api.shadiao.pro/chp"
            kind = 0
        case 1:
            urlString = "https://v2.jinrishici.com/one.json"
            kind = 1
        case 3:
            urlString = "https://v1.hitokoto.cn/?c=d&c=i&c=k"
            kind = 2
        default:
            urlString = "https://v.api.aa1.cn/api/yiyan/index.php"
            kind = 3
        }
        guard let url = URL(string: urlString) else { return }

        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = 4.0
            req.cachePolicy = .reloadIgnoringLocalCacheData
            let (data, response) = try await session.data(for: req)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }

            var extracted: String?
            if kind == 0 {
                struct ShadiaoResp: Decodable {
                    struct Payload: Decodable {
                        let type: String?
                        let text: String?
                    }
                    let data: Payload?
                    let text: String?
                }
                let decoded = try? JSONDecoder().decode(ShadiaoResp.self, from: data)
                if decoded?.data?.type != "禁爬虫喔" {
                    extracted = decoded?.data?.text ?? decoded?.text
                }
            } else if kind == 1 {
                struct JinrishiciResp: Decodable {
                    struct Payload: Decodable { let content: String? }
                    let data: Payload?
                }
                extracted = (try? JSONDecoder().decode(JinrishiciResp.self, from: data))?.data?.content
            } else if kind == 2 {
                struct HitokotoResp: Decodable { let hitokoto: String? }
                extracted = (try? JSONDecoder().decode(HitokotoResp.self, from: data))?.hitokoto
            } else {
                extracted = String(data: data, encoding: .utf8)
            }

            if let clean = Self.sanitizeQuote(extracted),
               !onlineRainbowQueue.contains(clean),
               !recentOnlineSet.contains(clean) {
                onlineRainbowQueue.append(clean)
            }
        } catch {
            // 单源网络异常跳过，由后续轮询或本地纯净库接管
        }
    }

    private func fetchNextJokeFromOnline() async {
        // 仅保留纯净度较高的 60s 冷笑话接口，并经全年龄段安全过滤器严格拦截
        guard let url = URL(string: "https://60s.viki.moe/v2/dad-joke") else { return }

        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = 4.0
            req.cachePolicy = .reloadIgnoringLocalCacheData
            let (data, response) = try await session.data(for: req)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }

            struct Joke60sResp: Decodable {
                struct Payload: Decodable { let content: String? }
                let data: Payload?
            }
            let extracted = (try? JSONDecoder().decode(Joke60sResp.self, from: data))?.data?.content

            if let clean = Self.sanitizeQuote(extracted, maxLength: 82),
               !onlineJokeQueue.contains(clean),
               !recentOnlineSet.contains(clean) {
                onlineJokeQueue.append(clean)
            }
        } catch {
            // 网络异常或被过滤拦截时自动由本地白名单纯净冷笑话接管
        }
    }

    private func fetchWithFastDeadline(timeoutSeconds: Double, operation: @escaping @Sendable () async -> Void) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await operation() }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
            }
            await group.next()
            group.cancelAll()
        }
    }

    private func recordOnlinePicked(_ text: String) {
        recentOnlineSet.append(text)
        if recentOnlineSet.count > 200 {
            recentOnlineSet.removeFirst(recentOnlineSet.count - 200)
        }
    }

    private func persistOnlineQueues() {
        UserDefaults.standard.set(Array(onlineRainbowQueue.prefix(10)), forKey: Self.onlineCacheRainbowKey)
        UserDefaults.standard.set(Array(onlineJokeQueue.prefix(10)), forKey: Self.onlineCacheJokeKey)
    }

    // MARK: - 全年龄段纯净级内容安全过滤（在线 + 本地双保险）

    private static let bannedTerms: [String] = [
        // 广告、代码残片与接口限流提示
        "微信", "QQ", "qq", "公众号", "关注", "http", "www.", "点击", "下载", "二维码",
        "广告", "客服", "代购", "淘宝", "京东", "拼多多", "加群", "私信", "转发",
        "blockquote", "script", "href", "src=", "div", "span",
        "访问太快", "请稍后再试", "禁爬虫",
        // 色情/荤段子/擦边/身体低俗词
        "嫖", "妓", "鸡巴", "操你", "妈逼", "性交", "做爱", "强奸", "乱伦", "裸聊",
        "成人", "小电影", "av", "AV", "约炮", "出轨", "小三", "一夜情", "开房",
        "上床", "床单", "滚床单", "脱衣", "脱光", "裸奔", "内裤", "胸罩", "丝袜",
        "贫乳", "大胸", "咪咪", "蛋蛋", "屁股", "色狼", "咸猪手", "调戏", "揩油",
        "避孕", "安全套", "套套", "怀孕", "ooxx", "OOXX", "啪啪", "高潮", "自慰",
        "打飞机", "撸管", "湿了", "硬了", "亲嘴", "情妇", "包养", "陪睡",
        "卖身", "坐台", "鸭子", "牛郎", "老司机", "荤段子", "流氓", "猥琐",
        "变态", "色情", "黄片", "毛片", "苍老师", "岛国", "洞房", "绿帽", "小姨子",
        "隔壁老王", "舔狗", "绿茶", "渣男", "渣女", "偷情", "第三者", "风骚",
        "色腥", "色欲", "情欲", "肉体", "春宵", "青楼", "妓院", "娼", "淫",
        "睡你", "生猴子", "有本事上我", "捏爆", "揉爆",
        // 脏话粗口与辱骂
        "傻逼", "沙雕", "草泥马", "他妈", "她妈", "你妈", "妈的", "卧槽", "我操", "我靠",
        "尼玛", "屌", "滚蛋", "滚开", "滚出", "去死", "死全家", "神经病", "弱智",
        "脑残", "智障", "有病", "贱人", "婊", "混蛋", "王八", "畜生", "狗东西", "狗屎",
        "蠢货", "废物", "垃圾", "白痴", "笨蛋", "变态", "恶心", "闭嘴",
        "放屁", "屁话", "扯淡", "装逼", "牛逼", "二逼", "坑爹", "特么", "他娘", "本大爷",
        "狗血", "禽兽", "杂种", "泼妇", "荡妇", "tmd", "TMD",
        // 屎尿屁与生理不适
        "屎", "尿", "大便", "小便", "拉稀", "腹泻", "马桶", "呕吐", "吐了",
        "鼻屎", "鼻涕", "抠脚", "脚臭", "臭袜", "香港脚", "狐臭", "口臭",
        // 暴力/血腥/极端负能量（不误杀古诗词与情话正常用字）
        "自杀", "割腕", "跳楼", "斩尽杀绝", "尸", "坟墓", "骨灰", "棺材",
        "冥婚", "癌症", "肿瘤", "猝死", "强盗", "抢劫", "坐牢", "越狱", "地狱",
        "绝望", "崩溃", "抑郁", "醉生梦死", "吸毒", "赌博",
        // 饭圈/二次元擦边
        "死宅", "宅男", "宅女", "鸟厨", "真源", "应援", "爱豆", "打call", "大小姐"
    ]

    private static func isSafeCleanText(_ text: String) -> Bool {
        let dirtyTokens = ["<", ">", "\\n", "\\t", "{", "}", "blockquote", "http://", "https://"]
        if dirtyTokens.contains(where: { text.contains($0) }) { return false }
        if bannedTerms.contains(where: { text.contains($0) }) { return false }
        return true
    }

    /// 严格净洗在线与本地文本：剥离包裹标签、校验长度，并通过全年龄段安全内容过滤
    private static func sanitizeQuote(_ raw: String?, maxLength: Int = 72) -> String? {
        guard var text = raw else { return nil }
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 6, text.count <= maxLength else { return nil }
        guard isSafeCleanText(text) else { return nil }
        return text
    }

    // MARK: - 本地全年龄段纯净压缩包（按比例抽取 + 跨重启零重复）

    private func loadBundleIfNeeded() {
        guard !didAttemptLoad else { return }
        didAttemptLoad = true
        guard let url = Bundle.main.url(forResource: "MicroQuotesBundle", withExtension: "zlib"),
              let compressed = try? Data(contentsOf: url),
              let decompressed = try? (compressed as NSData).decompressed(using: .zlib) as Data,
              let decoded = try? JSONDecoder().decode(BundleCorpus.self, from: decompressed) else {
            return
        }
        corpus = decoded
    }

    private func takeLocalRainbowQuote() -> String {
        if let corpus {
            let roll = Int.random(in: 0..<100)
            let targetKey: PoolKey = roll < 45 ? .praise : (roll < 80 ? .healing : .sweet)
            if let picked = drawNext(from: targetKey, corpus: corpus)
                ?? drawNext(from: .praise, corpus: corpus)
                ?? drawNext(from: .healing, corpus: corpus) {
                return picked
            }
        }
        return drawFallback(from: CelebrationLibrary.playfulQuotes, key: "fallback_praise")
            ?? "这一小步落地得很稳，今天的节奏被你亲手点亮了。"
    }

    private func takeLocalColdJokeQuote() -> String {
        if let corpus {
            let roll = Int.random(in: 0..<100)
            let targetKey: PoolKey = roll < 75 ? .joke : .witty
            if let picked = drawNext(from: targetKey, corpus: corpus)
                ?? drawNext(from: .joke, corpus: corpus)
                ?? drawNext(from: .witty, corpus: corpus) {
                return picked
            }
        }
        return drawFallback(from: CelebrationLibrary.coldJokes, key: "fallback_joke")
            ?? "为什么企鹅的肚子是白的？因为手太短，搓澡搓不到背。"
    }

    private func items(for key: PoolKey, in corpus: BundleCorpus) -> [String] {
        switch key {
        case .praise: return corpus.praise
        case .healing: return corpus.healing
        case .sweet: return corpus.sweet
        case .joke: return corpus.joke
        case .witty: return corpus.witty
        }
    }

    private func drawNext(from key: PoolKey, corpus: BundleCorpus) -> String? {
        let pool = items(for: key, in: corpus)
        guard !pool.isEmpty else { return nil }

        var state = poolStates[key.rawValue] ?? PoolCursorState(seed: UInt64.random(in: 1...UInt64.max), cursor: 0, lastText: nil)
        if state.cursor >= pool.count || state.cursor < 0 {
            state.seed = UInt64.random(in: 1...UInt64.max)
            state.cursor = 0
            shuffledIndicesCache[key] = nil
        }

        let indices: [Int]
        if let cached = shuffledIndicesCache[key], cached.count == pool.count {
            indices = cached
        } else {
            var rng = SeededRNG(seed: state.seed)
            var arr = Array(0..<pool.count)
            arr.shuffle(using: &rng)
            shuffledIndicesCache[key] = arr
            indices = arr
        }

        var chosen = pool[indices[state.cursor]]
        state.cursor += 1
        if chosen == state.lastText, pool.count > 1 {
            if state.cursor >= pool.count {
                state.seed = UInt64.random(in: 1...UInt64.max)
                state.cursor = 0
                var rng = SeededRNG(seed: state.seed)
                var arr = Array(0..<pool.count)
                arr.shuffle(using: &rng)
                shuffledIndicesCache[key] = arr
                chosen = pool[arr[0]]
                state.cursor = 1
            } else {
                chosen = pool[indices[state.cursor]]
                state.cursor += 1
            }
        }

        state.lastText = chosen
        poolStates[key.rawValue] = state
        persistStates()
        return chosen
    }

    private func drawFallback(from pool: [String], key: String) -> String? {
        let safePool = pool.filter { Self.isSafeCleanText($0) }
        guard !safePool.isEmpty else { return nil }
        var state = poolStates[key] ?? PoolCursorState(seed: UInt64.random(in: 1...UInt64.max), cursor: 0, lastText: nil)
        if state.cursor >= safePool.count || state.cursor < 0 {
            state.seed = UInt64.random(in: 1...UInt64.max)
            state.cursor = 0
        }
        var rng = SeededRNG(seed: state.seed)
        var arr = Array(0..<safePool.count)
        arr.shuffle(using: &rng)
        let chosen = safePool[arr[state.cursor]]
        state.cursor += 1
        state.lastText = chosen
        poolStates[key] = state
        persistStates()
        return chosen
    }

    private func persistStates() {
        if let data = try? JSONEncoder().encode(poolStates) {
            UserDefaults.standard.set(data, forKey: Self.poolStatesKey)
        }
    }
}
