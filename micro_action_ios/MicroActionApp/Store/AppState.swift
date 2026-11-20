import Foundation
import SwiftUI

/// 应用全局核心状态引擎（管理愿望/多级子任务前置、习惯、时间锚点、发光庆祝体系、AI 拆解与夸夸、苹果生态与 Widget 同步）
@MainActor
final class AppState: ObservableObject {
    @Published var plans: [PlanItem] = []
    @Published var habits: [HabitItem] = []
    @Published var anchors: [AnchorItem] = []
    @Published var shineRecords: [ShineRecord] = []
    @Published var customAffirmations: [String] = []

    @Published var rainbowRatio: Int = 50
    @Published var aiRatio: Int = 30
    @Published var soundEnabled: Bool = true
    @Published var aiPersona: AiCelebrationPersona = .sweetBestie
    @Published var themeSkin: CelebrationThemeSkin = .emerald
    @Published var soundPack: CelebrationSoundPack = .crystalBell
    @Published var autoCalendarFootprint: Bool = true
    @Published var twoWayRemindersSync: Bool = false

    /// 缓存排序后的列表与父子树索引（O(1) 读取，彻底消除滚动时的 O(N^2) 重复计算）
    @Published private(set) var ongoingPlans: [PlanItem] = []
    @Published private(set) var mainContradictionPlans: [PlanItem] = []
    @Published private(set) var normalOngoingPlans: [PlanItem] = []
    @Published private(set) var completedPlans: [PlanItem] = []
    @Published private(set) var archivedPlans: [PlanItem] = []
    @Published private(set) var activeHabits: [HabitItem] = []
    @Published private(set) var coreHabits: [HabitItem] = []
    @Published private(set) var normalActiveHabits: [HabitItem] = []
    @Published private(set) var stoppedHabits: [HabitItem] = []

    /// 顶层全局庆祝海报载荷（挂载于 App 根视图最顶层，彻底解决被锚点弹窗遮挡问题）
    @Published var activeCelebration: CelebrationPayload? = nil
    /// 控制弹出 Pro 会员付费墙
    @Published var showProPaywall: Bool = false
    /// 点击时间锚点系统通知后待直接打开的锚点 ID
    @Published var pendingOpenedAnchorId: String? = nil

    /// 成长洞察 AI 分析状态与持久化缓存（切换 Tab 或重启 App 不丢失）
    @Published var cachedAnalyticsReport: AiAnalyticsReport? = nil
    @Published var cachedAnalyticsTimestamp: Int64? = nil
    @Published var isAnalyzingOverview: Bool = false
    @Published var analyticsErrorMessage: String? = nil

    private let store: LocalStoreService
    private let quoteService = QuoteNetworkService()
    private let deepSeek = DeepSeekService()
    private var celebrationSeq: Int = 0
    private var anchorNotifObserver: NSObjectProtocol?
    private var planByIdCache: [String: PlanItem] = [:]
    private var directSubsCache: [String: [PlanItem]] = [:]
    private var subProgressCache: [String: (completed: Int, total: Int)] = [:]
    private static let analyticsCacheKey = "micro_action_cached_ai_report_v1"
    private static let analyticsTimeKey = "micro_action_cached_ai_report_ts_v1"

    init(store: LocalStoreService = LocalStoreService(), preloadNetwork: Bool = true) {
        self.store = store
        loadFromDisk()
        loadCachedAnalytics()
        syncWidgetSnapshot()
        if preloadNetwork {
            if let pending = AppleEcoService.shared.consumePendingAnchorId() {
                self.pendingOpenedAnchorId = pending
            }
            anchorNotifObserver = NotificationCenter.default.addObserver(
                forName: AppleEcoService.didTapAnchorNotification,
                object: nil,
                queue: .main
            ) { [weak self] notif in
                guard let id = notif.userInfo?["anchorId"] as? String else { return }
                Task { @MainActor in
                    self?.pendingOpenedAnchorId = id
                }
            }
            Task { await quoteService.warmUp() }
            refreshAnchorNotificationsSoon()
            if twoWayRemindersSync {
                AppleEcoService.shared.startObservingReminderChanges { [weak self] in
                    Task { @MainActor in
                        await self?.syncWithAppleReminders()
                    }
                }
            }
        }
    }

    // MARK: - 持久化

    private func deduplicateById<T: Identifiable>(_ items: [T]) -> [T] {
        var seen = Set<T.ID>()
        var result: [T] = []
        result.reserveCapacity(items.count)
        for item in items {
            if seen.insert(item.id).inserted {
                result.append(item)
            }
        }
        return result
    }

    private func loadFromDisk() {
        let data = store.load()
        plans = deduplicateById(data.plans)
        habits = deduplicateById(data.habits)
        anchors = deduplicateById(data.anchors)
        shineRecords = data.shineRecords
        customAffirmations = data.customAffirmations
        aiRatio = max(0, min(100, data.aiRatio))
        rainbowRatio = max(0, min(100 - aiRatio, data.rainbowRatio))
        soundEnabled = data.soundEnabled
        aiPersona = data.aiPersona
        themeSkin = data.themeSkin
        soundPack = data.soundPack
        autoCalendarFootprint = data.autoCalendarFootprint
        twoWayRemindersSync = data.twoWayRemindersSync
        rebuildCaches()
    }

    private func persist() {
        rebuildCaches()
        let snapshot = AppBackupData(
            plans: plans,
            habits: habits,
            anchors: anchors,
            shineRecords: shineRecords,
            customAffirmations: customAffirmations,
            rainbowRatio: rainbowRatio,
            aiRatio: aiRatio,
            soundEnabled: soundEnabled,
            aiPersona: aiPersona,
            themeSkin: themeSkin,
            soundPack: soundPack,
            autoCalendarFootprint: autoCalendarFootprint,
            twoWayRemindersSync: twoWayRemindersSync
        )
        store.save(snapshot)
        syncWidgetSnapshot()
    }

    func exportBackupJSON() throws -> String {
        let snapshot = AppBackupData(
            plans: plans,
            habits: habits,
            anchors: anchors,
            shineRecords: shineRecords,
            customAffirmations: customAffirmations,
            rainbowRatio: rainbowRatio,
            aiRatio: aiRatio,
            soundEnabled: soundEnabled,
            aiPersona: aiPersona,
            themeSkin: themeSkin,
            soundPack: soundPack,
            autoCalendarFootprint: autoCalendarFootprint,
            twoWayRemindersSync: twoWayRemindersSync
        )
        return try store.exportJSONString(snapshot)
    }

    func importBackupJSON(_ raw: String) throws {
        let imported = try store.decodeJSONString(raw)
        plans = imported.plans
        habits = imported.habits
        anchors = imported.anchors
        shineRecords = imported.shineRecords
        customAffirmations = imported.customAffirmations
        aiRatio = max(0, min(100, imported.aiRatio))
        rainbowRatio = max(0, min(100 - aiRatio, imported.rainbowRatio))
        soundEnabled = imported.soundEnabled
        aiPersona = imported.aiPersona
        themeSkin = imported.themeSkin
        soundPack = imported.soundPack
        autoCalendarFootprint = imported.autoCalendarFootprint
        twoWayRemindersSync = imported.twoWayRemindersSync
        persist()
        refreshAnchorNotificationsSoon()
    }

    func syncWidgetSnapshot() {
        let recentSeeds = Array(shineRecords.prefix(24)).map(\.colorSeed)
        let latestTitle = shineRecords.first?.title ?? "完成一件微小的事，点亮今日星籽"
        let snapshot = ShineWidgetSnapshot(
            todayShineCount: todayShineCount,
            totalShineCount: shineRecords.count,
            themeId: themeSkin.rawValue,
            latestActionTitle: latestTitle,
            seedColorSeeds: recentSeeds,
            updatedAtMs: Int64(Date().timeIntervalSince1970 * 1000)
        )
        SharedWidgetStore.save(snapshot)
    }

    // MARK: - 统计计算属性

    var todayShineCount: Int {
        let startMs = Int64(Calendar.current.startOfDay(for: Date()).timeIntervalSince1970 * 1000)
        return shineRecords.filter { $0.timestamp >= startMs }.count
    }

    var coldJokeRatio: Int {
        max(0, 100 - aiRatio - rainbowRatio)
    }

    /// 一次性构建全量列表与父子树索引缓存，彻底消除列表滚动时的 O(N^2) 计算开销
    private func rebuildCaches() {
        var byId: [String: PlanItem] = [:]
        byId.reserveCapacity(plans.count)
        for p in plans {
            byId[p.id] = p
        }
        planByIdCache = byId

        var subsMap: [String: [PlanItem]] = [:]
        for p in plans where p.status != .archived {
            if let pid = p.parentId {
                subsMap[pid, default: []].append(p)
            }
        }
        for (pid, list) in subsMap {
            subsMap[pid] = list.sorted { $0.createTime < $1.createTime }
        }
        directSubsCache = subsMap

        // 计算每个父级愿望的递归子任务进度缓存
        var progMap: [String: (completed: Int, total: Int)] = [:]
        func computeProgress(for id: String, visited: inout Set<String>) -> (completed: Int, total: Int) {
            if let cached = progMap[id] { return cached }
            guard let children = subsMap[id], !children.isEmpty else {
                progMap[id] = (0, 0)
                return (0, 0)
            }
            var done = 0
            var total = 0
            for child in children {
                total += 1
                if child.status == .completed { done += 1 }
                if !visited.contains(child.id) {
                    visited.insert(child.id)
                    let sub = computeProgress(for: child.id, visited: &visited)
                    done += sub.completed
                    total += sub.total
                }
            }
            progMap[id] = (done, total)
            return (done, total)
        }
        for pid in subsMap.keys {
            var visited: Set<String> = [pid]
            _ = computeProgress(for: pid, visited: &visited)
        }
        subProgressCache = progMap

        // 预排序列表缓存
        let ongoing = plans.filter { $0.status == .ongoing }
        let ongoingParentIds = Set(ongoing.compactMap(\.parentId))
        var depthMap: [String: Int] = [:]
        for p in ongoing {
            var d = 0
            var cur = p.parentId
            var seen: Set<String> = [p.id]
            while let pid = cur, !seen.contains(pid) {
                seen.insert(pid)
                d += 1
                cur = byId[pid]?.parentId
            }
            depthMap[p.id] = max(d, p.decompositionLevel)
        }

        ongoingPlans = ongoing.sorted { a, b in
            if a.isMainContradiction != b.isMainContradiction { return a.isMainContradiction }
            if a.isPinned != b.isPinned { return a.isPinned }
            let aLeaf = a.parentId != nil && !ongoingParentIds.contains(a.id)
            let bLeaf = b.parentId != nil && !ongoingParentIds.contains(b.id)
            if aLeaf != bLeaf { return aLeaf }
            let aDepth = depthMap[a.id] ?? 0
            let bDepth = depthMap[b.id] ?? 0
            if aDepth != bDepth { return aDepth > bDepth }
            if a.parentId != nil && a.parentId == b.parentId {
                return a.createTime < b.createTime
            }
            return a.createTime > b.createTime
        }
        mainContradictionPlans = ongoingPlans.filter { $0.isMainContradiction }
        normalOngoingPlans = ongoingPlans.filter { !$0.isMainContradiction }

        completedPlans = plans
            .filter { $0.status == .completed }
            .sorted { ($0.completeTime ?? 0) > ($1.completeTime ?? 0) }

        archivedPlans = plans
            .filter { $0.status == .archived }
            .sorted { $0.createTime > $1.createTime }

        activeHabits = habits
            .filter { $0.status == .active }
            .sorted { a, b in
                if a.isCoreHabit != b.isCoreHabit { return a.isCoreHabit }
                if a.isPinned != b.isPinned { return a.isPinned }
                return a.createTime > b.createTime
            }
        coreHabits = activeHabits.filter { $0.isCoreHabit }
        normalActiveHabits = activeHabits.filter { !$0.isCoreHabit }

        stoppedHabits = habits
            .filter { $0.status == .stopped }
            .sorted { $0.createTime > $1.createTime }
    }

    func effectiveDepth(of plan: PlanItem) -> Int {
        var depth = 0
        var currentParentId = plan.parentId
        var visited: Set<String> = [plan.id]
        while let pid = currentParentId, !visited.contains(pid) {
            visited.insert(pid)
            depth += 1
            currentParentId = planByIdCache[pid]?.parentId
        }
        return max(depth, plan.decompositionLevel)
    }

    func parentPlan(of plan: PlanItem) -> PlanItem? {
        guard let pid = plan.parentId else { return nil }
        return planByIdCache[pid]
    }

    func directSubPlans(of parentId: String) -> [PlanItem] {
        directSubsCache[parentId] ?? []
    }

    func subProgress(of parentId: String) -> (completed: Int, total: Int) {
        subProgressCache[parentId] ?? (0, 0)
    }

    func descendantIds(of rootId: String) -> Set<String> {
        var result: Set<String> = []
        var queue: [String] = [rootId]
        while !queue.isEmpty {
            let current = queue.removeFirst()
            for p in directSubsCache[current] ?? [] where !result.contains(p.id) {
                result.insert(p.id)
                queue.append(p.id)
            }
        }
        return result
    }

    private func nextGroupColorIndex() -> Int {
        let used = plans.map(\.groupColorIndex).filter { $0 >= 0 }
        return (used.max() ?? -1) + 1
    }

    // MARK: - 愿望 CRUD、主要矛盾标记、子任务拆解与完成庆祝

    @discardableResult
    func addPlan(name: String, dueDateMs: Int64? = nil, isMainContradiction: Bool = false) -> PlanItem? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let item = PlanItem(name: trimmed, isMainContradiction: isMainContradiction, dueDateMs: dueDateMs)
        plans.insert(item, at: 0)
        persist()
        if twoWayRemindersSync {
            let due = dueDateMs.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000.0) }
            Task {
                _ = await pushPlanToAppleReminders(planId: item.id, dueDate: due)
            }
        }
        return item
    }

    @discardableResult
    func addSubPlan(parentId: String, name: String) -> PlanItem? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let parentIdx = plans.firstIndex(where: { $0.id == parentId }) else { return nil }

        let resolvedColor: Int
        if plans[parentIdx].groupColorIndex >= 0 {
            resolvedColor = plans[parentIdx].groupColorIndex
        } else {
            resolvedColor = nextGroupColorIndex()
            plans[parentIdx].groupColorIndex = resolvedColor
        }

        let depth = effectiveDepth(of: plans[parentIdx]) + 1
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        // 保证连续快速添加时时间戳严格递增，维持正序
        let maxSiblingTs = plans.filter { $0.parentId == parentId }.map(\.createTime).max() ?? 0
        let ts = max(nowMs, maxSiblingTs + 1)

        let sub = PlanItem(
            name: trimmed,
            createTime: ts,
            parentId: parentId,
            decompositionLevel: depth,
            groupColorIndex: resolvedColor
        )
        plans.append(sub)
        persist()
        return sub
    }

    func updatePlanName(id: String, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let idx = plans.firstIndex(where: { $0.id == id }) else { return }
        plans[idx].name = trimmed
        persist()
    }

    func togglePinPlan(id: String) {
        guard let idx = plans.firstIndex(where: { $0.id == id }) else { return }
        plans[idx].isPinned.toggle()
        persist()
    }

    func toggleMainContradiction(id: String) {
        guard let idx = plans.firstIndex(where: { $0.id == id }) else { return }
        plans[idx].isMainContradiction.toggle()
        persist()
    }

    func setMainContradiction(id: String, value: Bool) {
        guard let idx = plans.firstIndex(where: { $0.id == id }) else { return }
        plans[idx].isMainContradiction = value
        persist()
    }

    func archivePlan(id: String) {
        guard let idx = plans.firstIndex(where: { $0.id == id }) else { return }
        plans[idx].status = .archived
        persist()
    }

    func restoreArchivedPlan(id: String) {
        guard let idx = plans.firstIndex(where: { $0.id == id }) else { return }
        plans[idx].status = .ongoing
        persist()
    }

    func deletePlan(id: String) {
        let toDelete = descendantIds(of: id).union([id])
        plans.removeAll { toDelete.contains($0.id) }
        for i in anchors.indices {
            anchors[i].planIds.removeAll { toDelete.contains($0) }
        }
        persist()
    }

    func togglePlanStatus(id: String, isPro: Bool = false) async {
        guard let idx = plans.firstIndex(where: { $0.id == id }) else { return }
        if plans[idx].status == .completed {
            plans[idx].status = .ongoing
            plans[idx].completeTime = nil
            let remId = plans[idx].reminderIdentifier
            persist()
            if let remId, isPro && twoWayRemindersSync {
                await AppleEcoService.shared.markReminderCompleted(identifier: remId, completed: false)
            }
            return
        }

        let wasFirstToday = todayShineCount == 0
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        plans[idx].status = .completed
        plans[idx].completeTime = nowMs
        let targetName = plans[idx].name
        let remId = plans[idx].reminderIdentifier

        // 级联完成后代未完成子任务
        let descIds = descendantIds(of: id)
        for i in plans.indices where descIds.contains(plans[i].id) && plans[i].status == .ongoing {
            plans[i].status = .completed
            plans[i].completeTime = nowMs
        }

        // 解绑锚点中已完成的愿望
        let completedSet = descIds.union([id])
        for i in anchors.indices {
            anchors[i].planIds.removeAll { completedSet.contains($0) }
        }

        let tag = wasFirstToday ? "今日首胜" : "目标达成"
        let quote = await emitCelebrationByRatio(actionTitle: targetName, isPro: isPro, defaultTag: tag)
        persist()

        if isPro && autoCalendarFootprint {
            _ = await AppleEcoService.shared.recordFootprintToCalendar(
                title: targetName,
                notes: "微行动愿望达成\n\(quote)"
            )
        }
        if let remId, isPro && twoWayRemindersSync {
            await AppleEcoService.shared.markReminderCompleted(identifier: remId, completed: true)
        }
    }

    // MARK: - 习惯 CRUD 与打卡

    @discardableResult
    func addHabit(name: String, isCoreHabit: Bool = false) -> HabitItem? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let habit = HabitItem(name: trimmed, isCoreHabit: isCoreHabit)
        habits.insert(habit, at: 0)
        persist()
        return habit
    }

    func updateHabitName(id: String, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let idx = habits.firstIndex(where: { $0.id == id }) else { return }
        habits[idx].name = trimmed
        persist()
    }

    func deleteHabit(id: String) {
        habits.removeAll { $0.id == id }
        for i in anchors.indices {
            anchors[i].habitIds.removeAll { $0 == id }
        }
        persist()
    }

    func toggleHabitStatus(id: String) {
        guard let idx = habits.firstIndex(where: { $0.id == id }) else { return }
        habits[idx].status = habits[idx].status == .active ? .stopped : .active
        persist()
    }

    func togglePinHabit(id: String) {
        guard let idx = habits.firstIndex(where: { $0.id == id }) else { return }
        habits[idx].isPinned.toggle()
        persist()
    }

    func toggleCoreHabit(id: String) {
        guard let idx = habits.firstIndex(where: { $0.id == id }) else { return }
        habits[idx].isCoreHabit.toggle()
        persist()
    }

    func setCoreHabit(id: String, value: Bool) {
        guard let idx = habits.firstIndex(where: { $0.id == id }) else { return }
        habits[idx].isCoreHabit = value
        persist()
    }

    func checkHabit(id: String, isPro: Bool = false) async {
        guard let idx = habits.firstIndex(where: { $0.id == id }) else { return }
        let wasFirstToday = todayShineCount == 0
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        habits[idx].totalDays += 1
        habits[idx].completionHistory.append(nowMs)
        let name = habits[idx].name
        let todayCount = habits[idx].todayCheckCount()
        let total = habits[idx].totalDays

        let tag = wasFirstToday ? "今日首胜" : "习惯发光"
        let quote = await emitCelebrationByRatio(actionTitle: name, isPro: isPro, defaultTag: tag)
        persist()

        if isPro && autoCalendarFootprint {
            _ = await AppleEcoService.shared.recordFootprintToCalendar(
                title: name,
                notes: "今日第 \(todayCount) 次打卡 · 累计 \(total) 次\n\(quote)"
            )
        }
    }

    // MARK: - 时间锚点管理

    @discardableResult
    func addAnchor(name: String, triggerTime: String, repeatCycle: AnchorRepeatCycle) -> AnchorItem? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let anchor = AnchorItem(name: trimmed, triggerTime: triggerTime, repeatCycle: repeatCycle)
        anchors.append(anchor)
        persist()
        refreshAnchorNotificationsSoon()
        return anchor
    }

    func updateAnchor(_ anchor: AnchorItem) {
        guard let idx = anchors.firstIndex(where: { $0.id == anchor.id }) else { return }
        anchors[idx] = anchor
        persist()
        refreshAnchorNotificationsSoon()
    }

    func deleteAnchor(id: String) {
        anchors.removeAll { $0.id == id }
        persist()
        refreshAnchorNotificationsSoon()
    }

    func toggleAnchorReminder(id: String) {
        guard let idx = anchors.firstIndex(where: { $0.id == id }) else { return }
        anchors[idx].reminderEnabled.toggle()
        persist()
        refreshAnchorNotificationsSoon()
    }

    func bindPlanToAnchor(anchorId: String, planId: String) {
        guard let idx = anchors.firstIndex(where: { $0.id == anchorId }) else { return }
        if !anchors[idx].planIds.contains(planId) {
            anchors[idx].planIds.append(planId)
            persist()
            refreshAnchorNotificationsSoon()
        }
    }

    func unbindPlanFromAnchor(anchorId: String, planId: String) {
        guard let idx = anchors.firstIndex(where: { $0.id == anchorId }) else { return }
        anchors[idx].planIds.removeAll { $0 == planId }
        persist()
        refreshAnchorNotificationsSoon()
    }

    func bindHabitToAnchor(anchorId: String, habitId: String) {
        guard let idx = anchors.firstIndex(where: { $0.id == anchorId }) else { return }
        if !anchors[idx].habitIds.contains(habitId) {
            anchors[idx].habitIds.append(habitId)
            persist()
            refreshAnchorNotificationsSoon()
        }
    }

    func unbindHabitFromAnchor(anchorId: String, habitId: String) {
        guard let idx = anchors.firstIndex(where: { $0.id == anchorId }) else { return }
        anchors[idx].habitIds.removeAll { $0 == habitId }
        persist()
        refreshAnchorNotificationsSoon()
    }

    func refreshAnchorNotificationsSoon() {
        let currentAnchors = anchors
        let currentPlans = plans
        let currentHabits = habits
        Task {
            await AppleEcoService.shared.refreshAnchorNotifications(
                anchors: currentAnchors,
                plans: currentPlans,
                habits: currentHabits
            )
        }
    }

    /// 一键完成指定时间锚点下的全部待完成愿望与今日未打卡微习惯
    func completeAllForAnchor(anchorId: String, isPro: Bool = false) async {
        guard let anchor = anchors.first(where: { $0.id == anchorId }) else { return }
        let targetPlans = plans.filter { anchor.planIds.contains($0.id) && $0.status == .ongoing }
        let targetHabits = habits.filter { anchor.habitIds.contains($0.id) && $0.status == .active && $0.todayCheckCount() == 0 }

        var count = 0
        for p in targetPlans {
            await togglePlanStatus(id: p.id, isPro: isPro)
            count += 1
        }
        for h in targetHabits {
            await checkHabit(id: h.id, isPro: isPro)
            count += 1
        }

        if count > 1, let last = activeCelebration {
            activeCelebration = CelebrationPayload(
                id: last.id,
                actionTitle: "「\(anchor.name)」全部 \(count) 项已一键完成",
                quote: last.quote,
                jokeQuote: last.jokeQuote,
                aiQuote: last.aiQuote,
                isGrand: true,
                milestoneTag: "锚点一键清零"
            )
        }
    }

    // MARK: - 庆祝体系与比例控制（AI 鼓励 / 彩虹屁 / 冷笑话三者比例自由调节，合计 100%）

    func setRainbowRatio(_ ratio: Int) {
        let clamped = max(0, min(100, ratio))
        rainbowRatio = clamped
        if aiRatio + rainbowRatio > 100 {
            aiRatio = 100 - rainbowRatio
        }
        persist()
    }

    func setCelebrationRatios(ai: Int, rainbow: Int) {
        let clampedAi = max(0, min(100, ai))
        let clampedRainbow = max(0, min(100 - clampedAi, rainbow))
        aiRatio = clampedAi
        rainbowRatio = clampedRainbow
        persist()
    }

    func setSoundEnabled(_ enabled: Bool) {
        soundEnabled = enabled
        persist()
    }

    func setAiPersona(_ persona: AiCelebrationPersona) {
        aiPersona = persona
        persist()
    }

    func setThemeSkin(_ skin: CelebrationThemeSkin) {
        themeSkin = skin
        persist()
    }

    func setSoundPack(_ pack: CelebrationSoundPack) {
        soundPack = pack
        persist()
    }

    func addCustomAffirmation(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        customAffirmations.removeAll { $0 == trimmed }
        customAffirmations.insert(trimmed, at: 0)
        persist()
    }

    func removeCustomAffirmation(_ text: String) {
        customAffirmations.removeAll { $0 == text }
        persist()
    }

    /// 严格按用户设定的 AI / 彩虹屁 / 冷笑话比例抽取唯一一条庆祝语
    @discardableResult
    private func emitCelebrationByRatio(actionTitle: String, isPro: Bool, defaultTag: String) async -> String {
        let effectiveAi = isPro ? aiRatio : 0
        let totalNonAi = max(1, 100 - effectiveAi)
        let roll = Int.random(in: 0..<100)

        if effectiveAi > 0 && roll < effectiveAi {
            // 抽中 AI 定制鼓励：先即刻弹出海报加载态，异步生成好后直接更新那唯一一条主卡片
            recordAndEmitCelebration(actionTitle: actionTitle, quote: "", milestoneTag: "\(aiPersona.name) · AI")
            let emittedId = celebrationSeq
            Task { [weak self] in
                guard let self else { return }
                let generated = try? await self.generateAiCelebration(actionTitle: actionTitle)
                let finalText: String
                if let text = generated, !text.isEmpty {
                    finalText = text
                } else {
                    finalText = await self.quoteService.takeRainbowQuote()
                }
                await MainActor.run {
                    if let current = self.activeCelebration, current.id == emittedId {
                        self.activeCelebration = CelebrationPayload(
                            id: current.id,
                            actionTitle: current.actionTitle,
                            quote: finalText,
                            isGrand: current.isGrand,
                            milestoneTag: generated != nil ? "\(self.aiPersona.name) · AI" : defaultTag
                        )
                    }
                }
            }
            return "\(aiPersona.name) · AI 鼓励"
        }

        let rainbowThreshold: Int
        if isPro {
            rainbowThreshold = effectiveAi + rainbowRatio
        } else {
            let scaledRainbow = Int(Double(rainbowRatio) / Double(totalNonAi) * 100.0)
            rainbowThreshold = scaledRainbow
        }

        if roll < rainbowThreshold {
            let quote: String
            if !customAffirmations.isEmpty, Double.random(in: 0..<1) < 0.25,
               let custom = customAffirmations.randomElement() {
                quote = custom
            } else {
                quote = await quoteService.takeRainbowQuote()
            }
            recordAndEmitCelebration(actionTitle: actionTitle, quote: quote, milestoneTag: defaultTag)
            return quote
        } else {
            let joke = await quoteService.takeColdJokeQuote()
            recordAndEmitCelebration(actionTitle: actionTitle, quote: joke, milestoneTag: "每日冷笑话")
            return joke
        }
    }

    /// 严格按用户设定的彩虹屁/冷笑话比例抽取庆祝文案
    func pickNextCelebrationQuote() async -> String {
        if !customAffirmations.isEmpty && Double.random(in: 0..<1) < 0.18 {
            return customAffirmations.randomElement() ?? customAffirmations[0]
        }
        let roll = Int.random(in: 0..<100)
        if roll < rainbowRatio {
            return await quoteService.takeRainbowQuote()
        } else {
            return await quoteService.takeColdJokeQuote()
        }
    }

    private func recordAndEmitCelebration(
        actionTitle: String,
        quote: String,
        jokeQuote: String? = nil,
        aiQuote: String? = nil,
        milestoneTag: String?
    ) {
        let record = ShineRecord(title: actionTitle, isGrand: true)
        shineRecords.insert(record, at: 0)
        celebrationSeq += 1
        SensoryFeedbackService.shared.celebrateGrand(soundEnabled: soundEnabled, soundPack: soundPack)
        activeCelebration = CelebrationPayload(
            id: celebrationSeq,
            actionTitle: actionTitle,
            quote: quote,
            jokeQuote: jokeQuote,
            aiQuote: aiQuote,
            isGrand: true,
            milestoneTag: milestoneTag
        )
    }

    /// 发光星籽罐内随时自由夸夸自己
    func celebrateFreely() async -> CelebrationPayload {
        let quote = await pickNextCelebrationQuote()
        let record = ShineRecord(title: "主动为自己庆祝", isGrand: true)
        shineRecords.insert(record, at: 0)
        persist()
        celebrationSeq += 1
        SensoryFeedbackService.shared.celebrateGrand(soundEnabled: soundEnabled, soundPack: soundPack)
        return CelebrationPayload(
            id: celebrationSeq,
            actionTitle: "主动为自己庆祝",
            quote: quote,
            isGrand: true,
            milestoneTag: "夸夸自己"
        )
    }

    // MARK: - DeepSeek AI 能力（Pro 专属）

    func generateAiCelebration(actionTitle: String, persona: AiCelebrationPersona? = nil) async throws -> String {
        let chosen = persona ?? aiPersona
        return try await deepSeek.generatePersonalizedCelebration(actionTitle: actionTitle, persona: chosen)
    }

    func previewAiBreakdownSteps(planId: String) async throws -> [String] {
        guard let parent = plans.first(where: { $0.id == planId }) else {
            throw NSError(domain: "AppState", code: 404, userInfo: [NSLocalizedDescriptionKey: "未找到对应愿望"])
        }
        return try await deepSeek.breakdownGoalToMicroSteps(goalTitle: parent.name)
    }

    func aiBreakdownPlan(parentId: String) async throws -> [PlanItem] {
        guard let parent = plans.first(where: { $0.id == parentId }) else {
            throw NSError(domain: "AppState", code: 404, userInfo: [NSLocalizedDescriptionKey: "未找到对应愿望"])
        }
        let steps = try await deepSeek.breakdownGoalToMicroSteps(goalTitle: parent.name)
        var created: [PlanItem] = []
        for step in steps {
            if let sub = addSubPlan(parentId: parentId, name: step) {
                created.append(sub)
            }
        }
        return created
    }

    func analyzeSinglePlan(planId: String) async throws -> SinglePlanDiagnosis {
        guard let plan = plans.first(where: { $0.id == planId }) else {
            throw NSError(domain: "AppState", code: 404, userInfo: [NSLocalizedDescriptionKey: "未找到对应愿望"])
        }
        let subs = directSubPlans(of: planId).map(\.name)
        return try await deepSeek.analyzeSinglePlan(planName: plan.name, subtasks: subs)
    }

    func runOverviewAnalysis() {
        guard !isAnalyzingOverview else { return }
        isAnalyzingOverview = true
        analyticsErrorMessage = nil
        Task {
            do {
                let report = try await analyzeOverview()
                let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
                await MainActor.run {
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
                        self.cachedAnalyticsReport = report
                        self.cachedAnalyticsTimestamp = nowMs
                        self.isAnalyzingOverview = false
                    }
                    self.saveCachedAnalytics(report, timestamp: nowMs)
                }
            } catch {
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.22)) {
                        self.analyticsErrorMessage = error.localizedDescription
                        self.isAnalyzingOverview = false
                    }
                }
            }
        }
    }

    private func loadCachedAnalytics() {
        if let data = UserDefaults.standard.data(forKey: Self.analyticsCacheKey),
           let decoded = try? JSONDecoder().decode(AiAnalyticsReport.self, from: data) {
            cachedAnalyticsReport = decoded
            let ts = UserDefaults.standard.object(forKey: Self.analyticsTimeKey) as? Int64
            cachedAnalyticsTimestamp = ts
        }
    }

    private func saveCachedAnalytics(_ report: AiAnalyticsReport, timestamp: Int64) {
        if let data = try? JSONEncoder().encode(report) {
            UserDefaults.standard.set(data, forKey: Self.analyticsCacheKey)
            UserDefaults.standard.set(timestamp, forKey: Self.analyticsTimeKey)
        }
    }

    func analyzeOverview() async throws -> AiAnalyticsReport {
        let mainDetails = mainContradictionPlans.prefix(8).map { p in
            let subs = directSubPlans(of: p.id)
            if subs.isEmpty { return p.name }
            let doneSubs = subs.filter { $0.status == .completed }.count
            return "\(p.name)(步骤\(doneSubs)/\(subs.count))"
        }.joined(separator: "、")

        let normalDetails = normalOngoingPlans.prefix(10).map { p in
            let subs = directSubPlans(of: p.id)
            if subs.isEmpty { return p.name }
            let doneSubs = subs.filter { $0.status == .completed }.count
            return "\(p.name)(步骤\(doneSubs)/\(subs.count))"
        }.joined(separator: "、")

        let doneNames = completedPlans.prefix(10).map(\.name).joined(separator: "、")
        let planText = """
        主要矛盾（优先解决）\(mainContradictionPlans.count) 项：\(mainDetails.isEmpty ? "暂无标记" : mainDetails)
        其他进行中愿望 \(normalOngoingPlans.count) 项：\(normalDetails.isEmpty ? "无" : normalDetails)
        已完成愿望 \(completedPlans.count) 项：\(doneNames.isEmpty ? "无" : doneNames)
        已归档 \(archivedPlans.count) 项
        """

        let coreHabitText = coreHabits.map { h in
            "\(h.name)(累计\(h.totalDays)次\(h.todayCheckCount() > 0 ? ",今日已打卡" : ""))"
        }.joined(separator: "、")
        let normalHabitText = normalActiveHabits.map { h in
            "\(h.name)(累计\(h.totalDays)次\(h.todayCheckCount() > 0 ? ",今日已打卡" : ""))"
        }.joined(separator: "、")
        let habitText = """
        核心习惯（优先坚持）\(coreHabits.count) 项：\(coreHabitText.isEmpty ? "暂无标记" : coreHabitText)
        其他活跃微习惯 \(normalActiveHabits.count) 项：\(normalHabitText.isEmpty ? "无" : normalHabitText)
        已停用微习惯 \(stoppedHabits.count) 项
        """

        let anchorText = anchors.prefix(10).map { a in
            "\(a.triggerTime) \(a.name)(绑定\(a.planIds.count)愿望/\(a.habitIds.count)习惯)"
        }.joined(separator: "、")

        return try await deepSeek.analyzeOverview(
            plansSummary: planText,
            habitsSummary: habitText,
            anchorsSummary: anchorText.isEmpty ? "暂无时间锚点" : anchorText,
            todayShines: todayShineCount,
            totalShines: shineRecords.count
        )
    }

    // MARK: - 苹果提醒事项双向同步（Pro 专属）

    func setAutoCalendarFootprint(_ enabled: Bool) {
        autoCalendarFootprint = enabled
        persist()
    }

    func setTwoWayRemindersSync(_ enabled: Bool) {
        twoWayRemindersSync = enabled
        persist()
        if enabled {
            AppleEcoService.shared.startObservingReminderChanges { [weak self] in
                Task { @MainActor in
                    await self?.syncWithAppleReminders()
                }
            }
            Task { await syncWithAppleReminders() }
        } else {
            AppleEcoService.shared.stopObservingReminderChanges()
        }
    }

    func pushPlanToAppleReminders(planId: String, dueDate: Date? = nil) async -> Bool {
        guard let idx = plans.firstIndex(where: { $0.id == planId }) else { return false }
        if let identifier = await AppleEcoService.shared.addPlanToReminders(
            title: plans[idx].name,
            notes: "来自「微行动助手」",
            dueDate: dueDate
        ) {
            plans[idx].reminderIdentifier = identifier
            plans[idx].dueDateMs = dueDate.map { Int64($0.timeIntervalSince1970 * 1000) }
            persist()
            return true
        }
        return false
    }

    @discardableResult
    func syncWithAppleReminders() async -> (imported: Int, completed: Int) {
        let reminders = await AppleEcoService.shared.fetchRemindersInMicroActionList()
        var imported = 0
        var completed = 0
        for rem in reminders {
            let remId = rem.calendarItemIdentifier
            let title = (rem.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { continue }

            if let idx = plans.firstIndex(where: { $0.reminderIdentifier == remId }) {
                if rem.isCompleted && plans[idx].status == .ongoing {
                    plans[idx].status = .completed
                    plans[idx].completeTime = Int64((rem.completionDate ?? Date()).timeIntervalSince1970 * 1000)
                    completed += 1
                }
            } else if !rem.isCompleted {
                var newPlan = PlanItem(name: title, reminderIdentifier: remId)
                if let comps = rem.dueDateComponents, let date = Calendar.current.date(from: comps) {
                    newPlan.dueDateMs = Int64(date.timeIntervalSince1970 * 1000)
                }
                plans.insert(newPlan, at: 0)
                imported += 1
            }
        }
        if imported > 0 || completed > 0 {
            persist()
        }
        return (imported, completed)
    }
}
