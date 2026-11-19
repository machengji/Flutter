import Foundation

/// 在线彩虹屁与冷笑话并发预加载队列服务
/// - 彩虹屁源：https://api.shadiao.pro/chp
/// - 冷笑话源：https://60s.viki.moe/v2/dad-joke (开源项目 vikiboss/60s)
actor QuoteNetworkService {
    private var rainbowQueue: [String] = []
    private var coldJokeQueue: [String] = []
    private var lastPicked: String = ""

    private let rainbowURL = URL(string: "https://api.shadiao.pro/chp")!
    private let coldJokeURL = URL(string: "https://60s.viki.moe/v2/dad-joke")!

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 6
        config.timeoutIntervalForResource = 8
        return URLSession(configuration: config)
    }()

    /// 启动时并发预热在线彩虹屁与冷笑话队列
    func warmUp() async {
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<3 {
                group.addTask { await self.fetchOneRainbowFart() }
            }
            for _ in 0..<2 {
                group.addTask { await self.fetchOneColdJoke() }
            }
        }
    }

    /// 优先从在线预加载队列取出新鲜原版彩虹屁，并异步补齐
    func takeRainbowQuote() async -> String {
        Task { await self.fetchOneRainbowFart() }
        while !rainbowQueue.isEmpty {
            let candidate = rainbowQueue.removeFirst()
            if candidate != lastPicked {
                lastPicked = candidate
                return candidate
            }
        }
        let fallback = pickNonRepeating(from: CelebrationLibrary.playfulQuotes)
        lastPicked = fallback
        return fallback
    }

    /// 优先从在线预加载队列取出新鲜冷笑话，并异步补齐
    func takeColdJokeQuote() async -> String {
        Task { await self.fetchOneColdJoke() }
        while !coldJokeQueue.isEmpty {
            let candidate = coldJokeQueue.removeFirst()
            if candidate != lastPicked {
                lastPicked = candidate
                return candidate
            }
        }
        let fallback = pickNonRepeating(from: CelebrationLibrary.coldJokes)
        lastPicked = fallback
        return fallback
    }

    private func pickNonRepeating(from pool: [String]) -> String {
        guard !pool.isEmpty else { return "" }
        let alternatives = pool.filter { $0 != lastPicked }
        return (alternatives.isEmpty ? pool : alternatives).randomElement() ?? pool[0]
    }

    private func fetchOneRainbowFart() async {
        guard rainbowQueue.count < 5 else { return }
        do {
            let (data, response) = try await session.data(from: rainbowURL)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }
            struct RainbowResp: Decodable {
                struct Payload: Decodable { let text: String? }
                let data: Payload?
            }
            let decoded = try JSONDecoder().decode(RainbowResp.self, from: data)
            if let text = decoded.data?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
               !text.isEmpty,
               !rainbowQueue.contains(text),
               text != lastPicked {
                rainbowQueue.append(text)
            }
        } catch {
            // 静默忽略单次网络波动
        }
    }

    private func fetchOneColdJoke() async {
        guard coldJokeQueue.count < 4 else { return }
        do {
            let (data, response) = try await session.data(from: coldJokeURL)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }
            struct JokeResp: Decodable {
                struct Payload: Decodable { let content: String? }
                let code: Int?
                let data: Payload?
            }
            let decoded = try JSONDecoder().decode(JokeResp.self, from: data)
            if decoded.code == 200,
               let content = decoded.data?.content?.trimmingCharacters(in: .whitespacesAndNewlines),
               !content.isEmpty,
               !coldJokeQueue.contains(content),
               content != lastPicked {
                coldJokeQueue.append(content)
            }
        } catch {
            // 静默忽略单次网络波动
        }
    }
}
