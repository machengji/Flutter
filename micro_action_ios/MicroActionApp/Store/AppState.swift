import Foundation
import SwiftUI

/// 应用全局核心状态引擎（管理计划/多级子任务前置、习惯、时间锚点、发光庆祝体系、AI 拆解与夸夸、苹果生态与 Widget 同步）
@MainActor
final class AppState: ObservableObject {
    @Published var plans: [PlanItem] = []
    @Published var habits: [HabitItem] = []
    @Published var anchors: [AnchorItem] = []
    @Published var shineRecords: [ShineRecord] = []
    @Published var customAffirmations: [String] = []

    @Published var rainbowRatio: Int = 80
    @Published var soundEnabled: Bool = true
    @Published var aiPersona: AiCelebrationPersona = .sweetBestie
    @Published var themeSkin: CelebrationThemeSkin = .emerald
    @Published var soundPack: CelebrationSoundPack = .crystalBell
    @Published var autoCalendarFootprint: Bool = true
    @Published var twoWayRemindersSync: Bool = false

    /// 顶层全局庆祝海报载荷（挂载于 App 根视图最顶层，彻底解决被锚点弹窗遮挡问题）
    @Published var activeCelebration: CelebrationPayload? = nil
    /// 控制弹出 Pro 会员付费墙
    @Published var showProPaywall: Bool = false

    private let store: LocalStoreService
    private let quoteService = QuoteNetworkService()
    private let deepSeek = DeepSeekService()
    private var celebrationSeq: Int = 0

    init(store: LocalStoreService = LocalStoreService(), preloadNetwork: Bool = true) {
        self.store = store
        loadFromDisk()
        syncWidgetSnapshot()
        if preloadNetwork {
            Task { await quoteService.warmUp() }
            Task { await AppleEcoService.shared.refreshAnchorNotifications(anchors: anchors) }
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

    private func loadFromDisk() {
        let data = store.load()
        plans = data.plans
        habits = data.habits
        anchors = data.anchors
        shineRecords = data.shineRecords
        customAffirmations = data.customAffirmations
        rainbowRatio = max(0, min(100, data.rainbowRatio))
        soundEnabled = data.soundEnabled
        aiPersona = data.aiPersona
        themeSkin = data.themeSkin
        soundPack = data.soundPack
        autoCalendarFootprint = data.autoCalendarFootprint
        twoWayRemindersSync = data.twoWayRemindersSync
    }

    private func persist() {
        let snapshot = AppBackupData(
            plans: plans,
            habits: habits,
            anchors: anchors,
            shineRecords: shineRecords,
            customAffirmations: customAffirmations,
            rainbowRatio: rainbowRatio,
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
        rainbowRatio = max(0, min(100, imported.rainbowRatio))
        soundEnabled = imported.soundEnabled
        aiPersona = imported.aiPersona
        themeSkin = imported.themeSkin
        soundPack = imported.soundPack
        autoCalendarFootprint = imported.autoCalendarFootprint
        twoWayRemindersSync = imported.twoWayRemindersSync
        persist()
        Task { await AppleEcoService.shared.refreshAnchorNotifications(anchors: anchors) }
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
        100 - rainbowRatio
    }

    var completedPlans: [PlanItem] {
        plans
            .filter { $0.status == .completed }
            .sorted { ($0.completeTime ?? 0) > ($1.completeTime ?? 0) }
    }

    var archivedPlans: [PlanItem] {
        plans
            .filter { $0.status == .archived }
            .sorted { $0.createTime > $1.createTime }
    }

    var activeHabits: [HabitItem] {
        habits.filter { $0.status == .active }
    }

    /// 核心排序算法：多级子任务自动前置提升到首页顶部，叶节点微行动优先可见，同批子任务保持录入正序
    var ongoingPlans: [PlanItem] {
        let ongoing = plans.filter { $0.status == .ongoing }
        let ongoingParentIds = Set(ongoing.compactMap(\.parentId))

        return ongoing.sorted { a, b in
            if a.isPinned != b.isPinned { return a.isPinned }

            let aIsPromotedLeaf = a.parentId != nil && !ongoingParentIds.contains(a.id)
            let bIsPromotedLeaf = b.parentId != nil && !ongoingParentIds.contains(b.id)
            if aIsPromotedLeaf != bIsPromotedLeaf { return aIsPromotedLeaf }

            let aDepth = effectiveDepth(of: a)
            let bDepth = effectiveDepth(of: b)
            if aDepth != bDepth { return aDepth > bDepth }

            // 同父级子任务保持录入正序，顶层大目标按最新创建倒序
            if a.parentId != nil && a.parentId == b.parentId {
                return a.createTime < b.createTime
            }
            return a.createTime > b.createTime
        }
    }

    func effectiveDepth(of plan: PlanItem) -> Int {
        var depth = 0
        var currentParentId = plan.parentId
        var visited: Set<String> = [plan.id]
        while let pid = currentParentId, !visited.contains(pid) {
            visited.insert(pid)
            depth += 1
            currentParentId = plans.first(where: { $0.id == pid })?.parentId
        }
        return max(depth, plan.decompositionLevel)
    }

    func parentPlan(of plan: PlanItem) -> PlanItem? {
        guard let pid = plan.parentId else { return nil }
        return plans.first(where: { $0.id == pid })
    }

    func directSubPlans(of parentId: String) -> [PlanItem] {
        plans
            .filter { $0.parentId == parentId && $0.status != .archived }
            .sorted { $0.createTime < $1.createTime }
    }

    func subProgress(of parentId: String) -> (completed: Int, total: Int) {
        let descendants = descendantIds(of: parentId)
        let subItems = plans.filter { descendants.contains($0.id) && $0.status != .archived }
        let done = subItems.filter { $0.status == .completed }.count
        return (done, subItems.count)
    }

    func descendantIds(of rootId: String) -> Set<String> {
        var result: Set<String> = []
        var queue: [String] = [rootId]
        while !queue.isEmpty {
            let current = queue.removeFirst()
            for p in plans where p.parentId == current && !result.contains(p.id) {
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

    // MARK: - 计划 CRUD、子任务拆解与完成庆祝

    @discardableResult
    func addPlan(name: String, dueDateMs: Int64? = nil) -> PlanItem? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let item = PlanItem(name: trimmed, dueDateMs: dueDateMs)
        plans.insert(item, at: 0)
        persist()
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

        // 解绑锚点中已完成的计划
        let completedSet = descIds.union([id])
        for i in anchors.indices {
            anchors[i].planIds.removeAll { completedSet.contains($0) }
        }

        let quote = await pickNextCelebrationQuote()
        let tag = wasFirstToday ? "今日首胜" : "目标达成"
        recordAndEmitCelebration(actionTitle: targetName, quote: quote, milestoneTag: tag)
        persist()

        if isPro && autoCalendarFootprint {
            _ = await AppleEcoService.shared.recordFootprintToCalendar(
                title: targetName,
                notes: "微行动计划达成\n\(quote)"
            )
        }
        if let remId, isPro && twoWayRemindersSync {
            await AppleEcoService.shared.markReminderCompleted(identifier: remId, completed: true)
        }
    }

    // MARK: - 习惯 CRUD 与打卡

    @discardableResult
    func addHabit(name: String) -> HabitItem? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let habit = HabitItem(name: trimmed)
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

    func checkHabit(id: String, isPro: Bool = false) async {
        guard let idx = habits.firstIndex(where: { $0.id == id }) else { return }
        let wasFirstToday = todayShineCount == 0
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        habits[idx].totalDays += 1
        habits[idx].completionHistory.append(nowMs)
        let name = habits[idx].name
        let todayCount = habits[idx].todayCheckCount()
        let total = habits[idx].totalDays

        let quote = await pickNextCelebrationQuote()
        let tag = wasFirstToday ? "今日首胜" : "习惯发光"
        recordAndEmitCelebration(actionTitle: name, quote: quote, milestoneTag: tag)
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
        Task { await AppleEcoService.shared.refreshAnchorNotifications(anchors: anchors) }
        return anchor
    }

    func updateAnchor(_ anchor: AnchorItem) {
        guard let idx = anchors.firstIndex(where: { $0.id == anchor.id }) else { return }
        anchors[idx] = anchor
        persist()
        Task { await AppleEcoService.shared.refreshAnchorNotifications(anchors: anchors) }
    }

    func deleteAnchor(id: String) {
        anchors.removeAll { $0.id == id }
        persist()
        Task { await AppleEcoService.shared.refreshAnchorNotifications(anchors: anchors) }
    }

    func toggleAnchorReminder(id: String) {
        guard let idx = anchors.firstIndex(where: { $0.id == id }) else { return }
        anchors[idx].reminderEnabled.toggle()
        persist()
        Task { await AppleEcoService.shared.refreshAnchorNotifications(anchors: anchors) }
    }

    func bindPlanToAnchor(anchorId: String, planId: String) {
        guard let idx = anchors.firstIndex(where: { $0.id == anchorId }) else { return }
        if !anchors[idx].planIds.contains(planId) {
            anchors[idx].planIds.append(planId)
            persist()
        }
    }

    func unbindPlanFromAnchor(anchorId: String, planId: String) {
        guard let idx = anchors.firstIndex(where: { $0.id == anchorId }) else { return }
        anchors[idx].planIds.removeAll { $0 == planId }
        persist()
    }

    func bindHabitToAnchor(anchorId: String, habitId: String) {
        guard let idx = anchors.firstIndex(where: { $0.id == anchorId }) else { return }
        if !anchors[idx].habitIds.contains(habitId) {
            anchors[idx].habitIds.append(habitId)
            persist()
        }
    }

    func unbindHabitFromAnchor(anchorId: String, habitId: String) {
        guard let idx = anchors.firstIndex(where: { $0.id == anchorId }) else { return }
        anchors[idx].habitIds.removeAll { $0 == habitId }
        persist()
    }

    // MARK: - 庆祝体系与比例控制（仅彩虹屁 & 冷笑话两种方式，支持 0%~100% 自定义比例）

    func setRainbowRatio(_ ratio: Int) {
        rainbowRatio = max(0, min(100, ratio))
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

    private func recordAndEmitCelebration(actionTitle: String, quote: String, milestoneTag: String?) {
        let record = ShineRecord(title: actionTitle, isGrand: true)
        shineRecords.insert(record, at: 0)
        celebrationSeq += 1
        SensoryFeedbackService.shared.celebrateGrand(soundEnabled: soundEnabled, soundPack: soundPack)
        activeCelebration = CelebrationPayload(
            id: celebrationSeq,
            actionTitle: actionTitle,
            quote: quote,
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

    func aiBreakdownPlan(parentId: String) async throws -> [PlanItem] {
        guard let parent = plans.first(where: { $0.id == parentId }) else {
            throw NSError(domain: "AppState", code: 404, userInfo: [NSLocalizedDescriptionKey: "未找到对应计划"])
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
            throw NSError(domain: "AppState", code: 404, userInfo: [NSLocalizedDescriptionKey: "未找到对应计划"])
        }
        let subs = directSubPlans(of: planId).map(\.name)
        return try await deepSeek.analyzeSinglePlan(planName: plan.name, subtasks: subs)
    }

    func analyzeOverview() async throws -> AiAnalyticsReport {
        let ongoingNames = ongoingPlans.prefix(10).map(\.name).joined(separator: "、")
        let doneCount = completedPlans.count
        let planText = "进行中 \(ongoingPlans.count) 项（\(ongoingNames)），已完成 \(doneCount) 项"
        let habitText = habits.map { "\($0.name)(\($0.totalDays)次)" }.joined(separator: "、")
        return try await deepSeek.analyzeOverview(
            plansSummary: planText,
            habitsSummary: habitText.isEmpty ? "暂无习惯" : habitText,
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

    func pushPlanToAppleReminders(planId: String) async -> Bool {
        guard let idx = plans.firstIndex(where: { $0.id == planId }) else { return false }
        let due = plans[idx].dueDateMs.map { Date(timeIntervalSince1970: Double($0) / 1000.0) }
        if let identifier = await AppleEcoService.shared.addPlanToReminders(
            title: plans[idx].name,
            notes: "来自「微行动助手」",
            dueDate: due
        ) {
            plans[idx].reminderIdentifier = identifier
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
