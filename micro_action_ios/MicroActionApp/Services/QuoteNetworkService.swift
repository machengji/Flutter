import Foundation

/// 本地万级精品语料压缩包服务（13,101 条开源精选清洗语料，zlib 压缩打包进 App，0 延迟离线秒出）
/// - 跨重启永久防重复：为每个子池持久化 Fisher-Yates 洗牌种子与游标至 UserDefaults，同一个人用遍全部语料前绝不重复
/// - 彩虹屁池配比：夸夸鼓励 50% + 一言治愈（文学/诗词/哲学）30% + 轻甜情话 20%
/// - 冷笑话池配比：精选冷笑话 65% + 一言抖机灵/脑洞冷梗 35%
actor QuoteNetworkService {
    private static let poolStatesKey = "micro_quotes_pool_states_v1"

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

    /// 确定性 SplitMix64 伪随机数生成器，用于按持久化 seed 复现洗牌序列
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

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.poolStatesKey),
           let decoded = try? JSONDecoder().decode([String: PoolCursorState].self, from: data) {
            self.poolStates = decoded
        }
    }

    /// 启动时后台预解压本地精品压缩语料包
    func warmUp() async {
        loadBundleIfNeeded()
    }

    func ensureWarmedUp() async {
        loadBundleIfNeeded()
    }

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

    /// 按「夸夸鼓励 50% + 一言治愈 30% + 轻甜情话 20%」配比秒抽彩虹屁（跨重启永久不重复）
    func takeRainbowQuote() async -> String {
        loadBundleIfNeeded()
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

    /// 按「冷笑话 65% + 一言抖机灵 35%」配比秒抽冷笑话（跨重启永久不重复）
    func takeColdJokeQuote() async -> String {
        loadBundleIfNeeded()
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

        // 若本轮已全部看遍，重新生成洗牌种子并归零游标
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

        // 跨轮交界处若恰好与上一轮最后一条相同，顺延一条避免连续重复
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
