import Foundation
import StoreKit

/// Pro 会员套餐定义（对应 App Store Connect 内购商品 ID）
struct ProPlanOption: Identifiable, Sendable {
    var id: String { productId }
    let productId: String
    let title: String
    let badge: String
    let fallbackPrice: String
    let periodLabel: String
    let subtitle: String
    let isLifetime: Bool
    let isRecommended: Bool

    static let monthlyId = "com.microaction.pro.monthly"
    static let yearlyId = "com.microaction.pro.yearly"
    static let lifetimeId = "com.microaction.pro.lifetime"

    static let defaults: [ProPlanOption] = [
        ProPlanOption(
            productId: monthlyId,
            title: "月度 Pro",
            badge: "灵活体验",
            fallbackPrice: "¥8",
            periodLabel: "/ 月",
            subtitle: "随时可取消，先试一个月",
            isLifetime: false,
            isRecommended: false
        ),
        ProPlanOption(
            productId: yearlyId,
            title: "年度 Pro",
            badge: "最受欢迎 · 省50%",
            fallbackPrice: "¥48",
            periodLabel: "/ 年",
            subtitle: "折合每月仅 ¥4，性价比之选",
            isLifetime: false,
            isRecommended: true
        ),
        ProPlanOption(
            productId: lifetimeId,
            title: "终身买断 Pro",
            badge: "一次付费 永久尊享",
            fallbackPrice: "¥98",
            periodLabel: "买断",
            subtitle: "无续费焦虑，永久解锁未来所有皮肤与能力",
            isLifetime: true,
            isRecommended: false
        )
    ]

    static let allProductIds: Set<String> = [monthlyId, yearlyId, lifetimeId]
}

/// 纯原生 StoreKit 2 商业化内购服务（订阅 + 终身买断 + 恢复购买 + 测试期体验开关）
@MainActor
final class ProStoreService: ObservableObject {
    @Published private(set) var isPro: Bool = false
    @Published private(set) var activePlanId: String? = nil
    @Published private(set) var storeProducts: [String: Product] = [:]
    @Published private(set) var isLoadingProducts: Bool = false
    @Published private(set) var statusMessage: String? = nil

    private let previewUnlockedKey = "pro_preview_unlocked_v1"
    private var transactionListener: Task<Void, Never>?

    /// 编译期开关：测试期允许在付费墙切换体验 Pro；正式提交 App Store 审核时将 Info.plist 的 ENABLE_PRO_PREVIEW 设为 NO 即可完全隐藏
    var allowPreviewToggle: Bool {
        let raw = (Bundle.main.object(forInfoDictionaryKey: "ENABLE_PRO_PREVIEW") as? String ?? "YES")
            .uppercased()
        return raw == "YES" || raw == "TRUE" || raw == "1"
    }

    init() {
        if allowPreviewToggle && UserDefaults.standard.bool(forKey: previewUnlockedKey) {
            self.isPro = true
            self.activePlanId = "preview_mode"
        }
        startTransactionListener()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    func displayPrice(for option: ProPlanOption) -> String {
        storeProducts[option.productId]?.displayPrice ?? option.fallbackPrice
    }

    /// 测试期本地一键切换 Pro 体验（仅在 ENABLE_PRO_PREVIEW=YES 时生效）
    func setPreviewProEnabled(_ enabled: Bool) {
        guard allowPreviewToggle else { return }
        UserDefaults.standard.set(enabled, forKey: previewUnlockedKey)
        if enabled {
            isPro = true
            activePlanId = "preview_mode"
            statusMessage = "已开启测试期 Pro 全功能体验"
        } else {
            isPro = false
            activePlanId = nil
            statusMessage = "已切回免费版视角"
            Task { await refreshEntitlements() }
        }
    }

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let products = try await Product.products(for: ProPlanOption.allProductIds)
            var dict: [String: Product] = [:]
            for p in products {
                dict[p.id] = p
            }
            storeProducts = dict
        } catch {
            print("[ProStoreService] 拉取 StoreKit 商品失败: \(error)")
        }
    }

    func purchase(productId: String) async -> (Bool, String) {
        guard let product = storeProducts[productId] else {
            return (false, "尚未从 App Store 获取到商品 \(productId)（购买苹果开发者并在 App Store Connect 配置对应商品 ID 后即可拉起 Apple Pay）")
        }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await refreshEntitlements()
                    return (true, "升级成功，欢迎成为微行动 Pro 会员！")
                case .unverified(_, let error):
                    return (false, "交易校验失败：\(error.localizedDescription)")
                }
            case .userCancelled:
                return (false, "已取消支付")
            case .pending:
                return (false, "支付等待确认中")
            @unknown default:
                return (false, "未知支付状态")
            }
        } catch {
            return (false, "发起购买失败：\(error.localizedDescription)")
        }
    }

    /// 恢复已购项目（App Store 审核强制要求）
    func restorePurchases() async -> (Bool, String) {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if isPro {
                return (true, "已成功恢复您的 Pro 会员权益")
            }
            return (false, "未查询到有效的历史购买记录")
        } catch {
            return (false, "恢复购买失败：\(error.localizedDescription)")
        }
    }

    func refreshEntitlements() async {
        var foundActiveId: String? = nil
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               ProPlanOption.allProductIds.contains(transaction.productID),
               transaction.revocationDate == nil {
                foundActiveId = transaction.productID
                break
            }
        }
        if let active = foundActiveId {
            isPro = true
            activePlanId = active
        } else if allowPreviewToggle && UserDefaults.standard.bool(forKey: previewUnlockedKey) {
            isPro = true
            activePlanId = "preview_mode"
        } else {
            isPro = false
            activePlanId = nil
        }
    }

    private func startTransactionListener() {
        transactionListener = Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.refreshEntitlements()
                }
            }
        }
    }
}
