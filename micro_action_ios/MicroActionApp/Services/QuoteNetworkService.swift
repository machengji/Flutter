import Foundation

/// 在线彩虹屁与冷笑话并发预加载队列服务（带合规 UA Header + 本地缓存池 + 极速响应保护）
/// - 彩虹屁源：https://api.shadiao.pro/chp
/// - 冷笑话源：https://60s.viki.moe/v2/dad-joke (开源项目 vikiboss/60s)
actor QuoteNetworkService {
    private static let rainbowCacheKey = "quote_cache_rainbow_v1"
    private static let jokeCacheKey = "quote_cache_joke_v1"

    private var rainbowQueue: [String] = []
    private var coldJokeQueue: [String] = []
    private var lastPicked: String = ""

    private let rainbowURL = URL(string: "https://api.shadiao.pro/chp")!
    private let coldJokeURL = URL(string: "https://60s.viki.moe/v2/dad-joke")!

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 4.5
        config.timeoutIntervalForResource = 6.0
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148",
            "Accept": "application/json, text/plain, */*"
        ]
        return URLSession(configuration: config)
    }()

    init() {
        self.rainbowQueue = UserDefaults.standard.stringArray(forKey: Self.rainbowCacheKey) ?? []
        self.coldJokeQueue = UserDefaults.standard.stringArray(forKey: Self.jokeCacheKey) ?? []
    }

    private func persistQueues() {
        UserDefaults.standard.set(Array(rainbowQueue.prefix(12)), forKey: Self.rainbowCacheKey)
        UserDefaults.standard.set(Array(coldJokeQueue.prefix(12)), forKey: Self.jokeCacheKey)
    }

    /// 启动时并发预热在线彩虹屁与冷笑话队列
    func warmUp() async {
        await ensureWarmedUp()
    }

    /// 若队列余量不足，自动并发补齐至 4 条彩虹屁 + 3 条冷笑话（提前加载好下一条）
    func ensureWarmedUp() async {
        await withTaskGroup(of: Void.self) { group in
            let needRainbow = max(0, 4 - rainbowQueue.count)
            let needJoke = max(0, 3 - coldJokeQueue.count)
            for _ in 0..<needRainbow {
                group.addTask { await self.fetchOneRainbowFart() }
            }
            for _ in 0..<needJoke {
                group.addTask { await self.fetchOneColdJoke() }
            }
        }
        persistQueues()
    }

    /// 优先从在线预加载队列秒取新鲜原版彩虹屁，队列为空时限时 1.8s 极速拉取，绝不阻塞卡死弹窗
    func takeRainbowQuote() async -> String {
        if rainbowQueue.isEmpty {
            await fetchWithFastDeadline(timeoutSeconds: 1.8) {
                await self.fetchOneRainbowFart()
            }
        }
        Task { await self.ensureWarmedUp() }
        while !rainbowQueue.isEmpty {
            let candidate = rainbowQueue.removeFirst()
            if candidate != lastPicked {
                lastPicked = candidate
                persistQueues()
                return candidate
            }
        }
        persistQueues()
        let picked = pickNonRepeating(from: CelebrationLibrary.playfulQuotes)
        lastPicked = picked
        return picked
    }

    /// 优先从在线预加载队列秒取新鲜冷笑话，队列为空时限时 1.8s 极速拉取，绝不阻塞卡死弹窗
    func takeColdJokeQuote() async -> String {
        if coldJokeQueue.isEmpty {
            await fetchWithFastDeadline(timeoutSeconds: 1.8) {
                await self.fetchOneColdJoke()
            }
        }
        Task { await self.ensureWarmedUp() }
        while !coldJokeQueue.isEmpty {
            let candidate = coldJokeQueue.removeFirst()
            if candidate != lastPicked {
                lastPicked = candidate
                persistQueues()
                return candidate
            }
        }
        persistQueues()
        let picked = pickNonRepeating(from: CelebrationLibrary.coldJokes)
        lastPicked = picked
        return picked
    }

    private func fetchWithFastDeadline(timeoutSeconds: Double, operation: @escaping @Sendable () async -> Void) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await operation()
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
            }
            await group.next()
            group.cancelAll()
        }
    }

    private func pickNonRepeating(from pool: [String]) -> String {
        guard !pool.isEmpty else { return "" }
        let alternatives = pool.filter { $0 != lastPicked }
        return (alternatives.isEmpty ? pool : alternatives).randomElement() ?? pool[0]
    }

    private func makeRequest(url: URL) -> URLRequest {
        var req = URLRequest(url: url)
        req.timeoutInterval = 4.5
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148",
            forHTTPHeaderField: "User-Agent"
        )
        req.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        return req
    }

    private func fetchOneRainbowFart() async {
        guard rainbowQueue.count < 8 else { return }
        do {
            let (data, response) = try await session.data(for: makeRequest(url: rainbowURL))
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }
            struct RainbowResp: Decodable {
                struct Payload: Decodable { let text: String? }
                let data: Payload?
                let text: String?
            }
            let decoded = try JSONDecoder().decode(RainbowResp.self, from: data)
            let rawText = decoded.data?.text ?? decoded.text
            if let text = rawText?.trimmingCharacters(in: .whitespacesAndNewlines),
               !text.isEmpty,
               !rainbowQueue.contains(text),
               text != lastPicked {
                rainbowQueue.append(text)
            }
        } catch {
            // 忽略单次网络波动，交由异步补货重试
        }
    }

    private func fetchOneColdJoke() async {
        guard coldJokeQueue.count < 6 else { return }
        do {
            let (data, response) = try await session.data(for: makeRequest(url: coldJokeURL))
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }
            struct JokeResp: Decodable {
                struct Payload: Decodable {
                    let content: String?
                    let text: String?
                }
                let code: Int?
                let data: Payload?
                let content: String?
            }
            let decoded = try JSONDecoder().decode(JokeResp.self, from: data)
            let rawContent = decoded.data?.content ?? decoded.data?.text ?? decoded.content
            if (decoded.code == nil || decoded.code == 200),
               let content = rawContent?.trimmingCharacters(in: .whitespacesAndNewlines),
               !content.isEmpty,
               !coldJokeQueue.contains(content),
               content != lastPicked {
                coldJokeQueue.append(content)
            }
        } catch {
            // 忽略单次网络波动，交由异步补货重试
        }
    }
}
