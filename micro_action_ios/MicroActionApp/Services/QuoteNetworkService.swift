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

/// 庆祝语料双引擎服务：
/// 1) 在线多源轮询（沙雕彩虹屁 + 一言治愈 + 夏柔一言 + 60s冷笑话 + 一言抖机灵 + RollTools段子），错峰防限流且带 HTML 净洗
/// 2) 本地 12,426 条纯净 zlib 压缩语料包（离线秒出 + 持久化 Fisher-Yates 洗牌种子跨重启防重复）
actor QuoteNetworkService {
    private static let poolStatesKey = "micro_quotes_pool_states_v2"
    private static let onlineCacheRainbowKey = "quote_cache_rainbow_v2"
    private static let onlineCacheJokeKey = "quote_cache_joke_v2"

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
    private var jokeSourceCursor: Int = 0
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
        if let data = UserDefaults.standard.data(forKey: Self.poolStatesKey),
           let decoded = try? JSONDecoder().decode([String: PoolCursorState].self, from: data) {
            self.poolStates = decoded
        }
        self.onlineRainbowQueue = (UserDefaults.standard.stringArray(forKey: Self.onlineCacheRainbowKey) ?? [])
            .compactMap { Self.sanitizeQuote($0) }
        self.onlineJokeQueue = (UserDefaults.standard.stringArray(forKey: Self.onlineCacheJokeKey) ?? [])
            .compactMap { Self.sanitizeQuote($0) }
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
        while onlineRainbowQueue.count < 3 {
            await fetchNextRainbowFromOnline()
            if onlineRainbowQueue.count < 3 {
                try? await Task.sleep(nanoseconds: 550_000_000)
            }
        }
        while onlineJokeQueue.count < 3 {
            await fetchNextJokeFromOnline()
            if onlineJokeQueue.count < 3 {
                try? await Task.sleep(nanoseconds: 550_000_000)
            }
        }
        persistOnlineQueues()
    }

    /// 获取下一条彩虹屁/治愈语录
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
                if !recentOnlineSet.contains(candidate) {
                    recordOnlinePicked(candidate)
                    persistOnlineQueues()
                    return candidate
                }
            }
            persistOnlineQueues()
        }
        return takeLocalRainbowQuote()
    }

    /// 获取下一条冷笑话/抖机灵
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
                if !recentOnlineSet.contains(candidate) {
                    recordOnlinePicked(candidate)
                    persistOnlineQueues()
                    return candidate
                }
            }
            persistOnlineQueues()
        }
        return takeLocalColdJokeQuote()
    }

    // MARK: - 在线多源轮询（含严格 HTML 净洗）

    private func fetchNextRainbowFromOnline() async {
        let idx = rainbowSourceCursor % 3
        rainbowSourceCursor += 1

        let urlString: String
        switch idx {
        case 0: urlString = "https://api.shadiao.pro/chp"
        case 1: urlString = "https://v1.hitokoto.cn/?c=d&c=e&c=k"
        default: urlString = "https://v.api.aa1.cn/api/yiyan/index.php"
        }
        guard let url = URL(string: urlString) else { return }

        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = 4.0
            req.cachePolicy = .reloadIgnoringLocalCacheData
            let (data, response) = try await session.data(for: req)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }

            var extracted: String?
            if idx == 0 {
                struct Resp: Decodable {
                    struct Payload: Decodable { let text: String? }
                    let data: Payload?
                    let text: String?
                }
                let decoded = try? JSONDecoder().decode(Resp.self, from: data)
                extracted = decoded?.data?.text ?? decoded?.text
            } else if idx == 1 {
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
            // 单源网络异常静默跳过，由后续轮询或本地纯净库无缝接管
        }
    }

    private func fetchNextJokeFromOnline() async {
        let idx = jokeSourceCursor % 3
        jokeSourceCursor += 1

        let urlString: String
        switch idx {
        case 0: urlString = "https://60s.viki.moe/v2/dad-joke"
        case 1: urlString = "https://v1.hitokoto.cn/?c=l"
        default: urlString = "https://mxnzp.com/api/jokes/list/random"
        }
        guard let url = URL(string: urlString) else { return }

        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = 4.0
            req.cachePolicy = .reloadIgnoringLocalCacheData
            let (data, response) = try await session.data(for: req)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }

            var extracted: String?
            if idx == 0 {
                struct Joke60sResp: Decodable {
                    struct Payload: Decodable { let content: String? }
                    let data: Payload?
                }
                extracted = (try? JSONDecoder().decode(Joke60sResp.self, from: data))?.data?.content
            } else if idx == 1 {
                struct HitokotoResp: Decodable { let hitokoto: String? }
                extracted = (try? JSONDecoder().decode(HitokotoResp.self, from: data))?.hitokoto
            } else {
                struct RollResp: Decodable {
                    struct Item: Decodable { let content: String? }
                    let data: [Item]?
                }
                extracted = (try? JSONDecoder().decode(RollResp.self, from: data))?.data?.first?.content
            }

            if let clean = Self.sanitizeQuote(extracted, maxLength: 82),
               !onlineJokeQueue.contains(clean),
               !recentOnlineSet.contains(clean) {
                onlineJokeQueue.append(clean)
            }
        } catch {
            // 单源网络异常静默跳过，由后续轮询或本地纯净库无缝接管
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

    /// 严格净洗在线与本地文本：剥离简单包裹标签（如 <p>），若仍含残余 HTML/转义/代码符号则直接丢弃
    private static func sanitizeQuote(_ raw: String?, maxLength: Int = 72) -> String? {
        guard var text = raw else { return nil }
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 5, text.count <= maxLength else { return nil }
        let dirtyTokens = ["<", ">", "\\n", "\\t", "{", "}", "blockquote", "http://", "https://"]
        if dirtyTokens.contains(where: { text.contains($0) }) { return nil }
        return text
    }

    // MARK: - 本地万级纯净压缩包（按比例抽取 + 跨重启零重复）

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
            let targetKey: PoolKey = roll < 50 ? .praise : (roll < 80 ? .healing : .sweet)
            if let picked = drawNext(from: targetKey, corpus: corpus)
                ?? drawNext(from: .praise, corpus: corpus)
                ?? drawNext(from: .healing, corpus: corpus) {
                return picked
            }
        }
        return drawFallback(from: CelebrationLibrary.playfulQuotes, key: "fallback_praise")
            ?? "你今天的执行力简直自带追光灯！"
    }

    private func takeLocalColdJokeQuote() -> String {
        if let corpus {
            let roll = Int.random(in: 0..<100)
            let targetKey: PoolKey = roll < 65 ? .joke : .witty
            if let picked = drawNext(from: targetKey, corpus: corpus)
                ?? drawNext(from: .joke, corpus: corpus)
                ?? drawNext(from: .witty, corpus: corpus) {
                return picked
            }
        }
        return drawFallback(from: CelebrationLibrary.coldJokes, key: "fallback_joke")
            ?? "为什么企鹅的肚子是白的？因为手太短，洗不到。"
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
        guard !pool.isEmpty else { return nil }
        var state = poolStates[key] ?? PoolCursorState(seed: UInt64.random(in: 1...UInt64.max), cursor: 0, lastText: nil)
        if state.cursor >= pool.count || state.cursor < 0 {
            state.seed = UInt64.random(in: 1...UInt64.max)
            state.cursor = 0
        }
        var rng = SeededRNG(seed: state.seed)
        var arr = Array(0..<pool.count)
        arr.shuffle(using: &rng)
        let chosen = pool[arr[state.cursor]]
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
