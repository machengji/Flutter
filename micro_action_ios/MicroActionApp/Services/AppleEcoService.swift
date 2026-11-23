import Foundation
import EventKit
import UserNotifications
import Combine

/// 苹果原生生态集成服务（EventKit 提醒事项双向同步 + 系统日历足迹 + UserNotifications 锚点定时通知）
final class AppleEcoService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = AppleEcoService()
    static let didTapAnchorNotification = Notification.Name("MicroActionDidTapAnchorNotification")

    private let eventStore = EKEventStore()
    private let calendarTitle = "微行动"
    private let remindersListTitle = "微行动"
    private var storeObserver: NSObjectProtocol?
    private var pendingAnchorId: String?

    private static let alarmCategoryId = "ANCHOR_ALARM_CATEGORY"
    private static let snoozeActionId = "ANCHOR_SNOOZE_5M"
    private static let openActionId = "ANCHOR_OPEN_NOW"

    private override init() {
        super.init()
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        let snoozeAction = UNNotificationAction(
            identifier: Self.snoozeActionId,
            title: "5 分钟后再响",
            options: []
        )
        let openAction = UNNotificationAction(
            identifier: Self.openActionId,
            title: "立即去完成",
            options: [.foreground]
        )
        let alarmCategory = UNNotificationCategory(
            identifier: Self.alarmCategoryId,
            actions: [snoozeAction, openAction],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([alarmCategory])
    }

    func consumePendingAnchorId() -> String? {
        defer { pendingAnchorId = nil }
        return pendingAnchorId
    }

    // MARK: - 权限请求（兼容 iOS 16 与 iOS 17+）

    func requestCalendarAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            return (try? await eventStore.requestFullAccessToEvents()) ?? false
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func requestRemindersAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            return (try? await eventStore.requestFullAccessToReminders()) ?? false
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .reminder) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    // MARK: - 系统日历足迹自动写入

    func recordFootprintToCalendar(title: String, notes: String, date: Date = Date()) async -> Bool {
        guard await requestCalendarAccess() else { return false }
        guard let calendar = findOrCreateCalendar(for: .event, title: calendarTitle) else { return false }

        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        event.title = "✨ \(title)"
        event.notes = notes
        event.startDate = date
        event.endDate = date.addingTimeInterval(15 * 60)

        do {
            try eventStore.save(event, span: .thisEvent)
            return true
        } catch {
            print("[AppleEcoService] 写入日历足迹失败: \(error)")
            return false
        }
    }

    // MARK: - 系统提醒事项写入与双向同步监听

    func addPlanToReminders(title: String, notes: String, dueDate: Date? = nil) async -> String? {
        guard await requestRemindersAccess() else { return nil }
        guard let list = findOrCreateCalendar(for: .reminder, title: remindersListTitle) else { return nil }

        let reminder = EKReminder(eventStore: eventStore)
        reminder.calendar = list
        reminder.title = title
        reminder.notes = notes
        if let due = dueDate {
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: due)
            reminder.dueDateComponents = comps
            reminder.addAlarm(EKAlarm(absoluteDate: due))
        }

        do {
            try eventStore.save(reminder, commit: true)
            return reminder.calendarItemIdentifier
        } catch {
            print("[AppleEcoService] 写入提醒事项失败: \(error)")
            return nil
        }
    }

    func fetchRemindersInMicroActionList() async -> [EKReminder] {
        guard await requestRemindersAccess() else { return [] }
        guard let list = findOrCreateCalendar(for: .reminder, title: remindersListTitle) else { return [] }
        let predicate = eventStore.predicateForReminders(in: [list])
        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }

    func markReminderCompleted(identifier: String, completed: Bool) async {
        guard await requestRemindersAccess() else { return }
        guard let item = eventStore.calendarItem(withIdentifier: identifier) as? EKReminder else { return }
        item.isCompleted = completed
        item.completionDate = completed ? Date() : nil
        try? eventStore.save(item, commit: true)
    }

    func startObservingReminderChanges(onChange: @escaping () -> Void) {
        stopObservingReminderChanges()
        storeObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { _ in
            onChange()
        }
    }

    func stopObservingReminderChanges() {
        if let observer = storeObserver {
            NotificationCenter.default.removeObserver(observer)
            storeObserver = nil
        }
    }

    private func findOrCreateCalendar(for entityType: EKEntityType, title: String) -> EKCalendar? {
        let calendars = eventStore.calendars(for: entityType)
        if let existing = calendars.first(where: { $0.title == title }) {
            return existing
        }
        let newCal = EKCalendar(for: entityType, eventStore: eventStore)
        newCal.title = title
        if let defaultSource = eventStore.defaultCalendarForNewEvents?.source, entityType == .event {
            newCal.source = defaultSource
        } else if let defaultRemSource = eventStore.defaultCalendarForNewReminders()?.source, entityType == .reminder {
            newCal.source = defaultRemSource
        } else if let localSource = eventStore.sources.first(where: { $0.sourceType == .calDAV || $0.sourceType == .local }) {
            newCal.source = localSource
        } else {
            return nil
        }
        do {
            try eventStore.saveCalendar(newCal, commit: true)
            return newCal
        } catch {
            print("[AppleEcoService] 创建 \(title) 列表失败: \(error)")
            return nil
        }
    }

    // MARK: - 时间锚点系统级定时本地通知

    func refreshAnchorNotifications(
        anchors: [AnchorItem],
        plans: [PlanItem] = [],
        habits: [HabitItem] = []
    ) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }

        let pending = await center.pendingNotificationRequests()
        let anchorReqIds = pending.map(\.identifier).filter { $0.hasPrefix("anchor_") }
        center.removePendingNotificationRequests(withIdentifiers: anchorReqIds)

        let planMap = Dictionary(plans.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let habitMap = Dictionary(habits.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        for anchor in anchors where anchor.reminderEnabled {
            guard let hm = anchor.hourAndMinute else { continue }
            let bodyText = buildAnchorNotificationBody(anchor: anchor, planMap: planMap, habitMap: habitMap)

            let offsets = anchor.alarmEnabled ? [0, 1, 2] : [0]
            for offsetMin in offsets {
                let content = UNMutableNotificationContent()
                content.title = offsetMin == 0
                    ? (anchor.alarmEnabled ? "⏰ 锚点闹钟 · \(anchor.name)" : "微步时间锚点 · \(anchor.name)")
                    : "⏰ 锚点闹钟再响 (\(offsetMin + 1)/3) · \(anchor.name)"
                content.body = bodyText
                content.sound = .default
                content.userInfo = ["anchorId": anchor.id, "anchorName": anchor.name]
                if anchor.alarmEnabled {
                    content.categoryIdentifier = Self.alarmCategoryId
                    if #available(iOS 15.0, *) {
                        content.interruptionLevel = .timeSensitive
                    }
                }

                let totalMin = hm.hour * 60 + hm.minute + offsetMin
                let targetHour = (totalMin / 60) % 24
                let targetMin = totalMin % 60
                let dayCarry = totalMin / (24 * 60)

                switch anchor.repeatCycle {
                case .daily:
                    var comps = DateComponents()
                    comps.hour = targetHour
                    comps.minute = targetMin
                    let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                    let req = UNNotificationRequest(
                        identifier: "anchor_\(anchor.id)_o\(offsetMin)",
                        content: content,
                        trigger: trigger
                    )
                    try? await center.add(req)

                case .weekdays:
                    for wd in [2, 3, 4, 5, 6] {
                        let shiftedWd = ((wd - 1 + dayCarry) % 7) + 1
                        var comps = DateComponents()
                        comps.weekday = shiftedWd
                        comps.hour = targetHour
                        comps.minute = targetMin
                        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                        let req = UNNotificationRequest(
                            identifier: "anchor_\(anchor.id)_w\(wd)_o\(offsetMin)",
                            content: content,
                            trigger: trigger
                        )
                        try? await center.add(req)
                    }

                case .weekends:
                    for wd in [1, 7] {
                        let shiftedWd = ((wd - 1 + dayCarry) % 7) + 1
                        var comps = DateComponents()
                        comps.weekday = shiftedWd
                        comps.hour = targetHour
                        comps.minute = targetMin
                        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                        let req = UNNotificationRequest(
                            identifier: "anchor_\(anchor.id)_w\(wd)_o\(offsetMin)",
                            content: content,
                            trigger: trigger
                        )
                        try? await center.add(req)
                    }

                case .weekly:
                    let shiftedWd = ((anchor.weeklyWeekday - 1 + dayCarry) % 7) + 1
                    var comps = DateComponents()
                    comps.weekday = shiftedWd
                    comps.hour = targetHour
                    comps.minute = targetMin
                    let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                    let req = UNNotificationRequest(
                        identifier: "anchor_\(anchor.id)_wk_o\(offsetMin)",
                        content: content,
                        trigger: trigger
                    )
                    try? await center.add(req)

                case .monthly:
                    // 若跨日进位导致跨越月末，则以次日（+1天）推算，常规时间在 1~31 日精准触发
                    let targetDay = min(31, anchor.monthlyDay + dayCarry)
                    var comps = DateComponents()
                    comps.day = targetDay
                    comps.hour = targetHour
                    comps.minute = targetMin
                    let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                    let req = UNNotificationRequest(
                        identifier: "anchor_\(anchor.id)_mo_o\(offsetMin)",
                        content: content,
                        trigger: trigger
                    )
                    try? await center.add(req)
                }
            }
        }
    }

    private func buildAnchorNotificationBody(
        anchor: AnchorItem,
        planMap: [String: PlanItem],
        habitMap: [String: HabitItem]
    ) -> String {
        let linkedPlans = anchor.planIds.compactMap { planMap[$0] }.filter { $0.status != .archived }
        let activePlans = linkedPlans.filter { $0.status == .ongoing }
        let displayPlans = activePlans.isEmpty ? linkedPlans : activePlans

        let linkedHabits = anchor.habitIds.compactMap { habitMap[$0] }
        let activeHabits = linkedHabits.filter { $0.status == .active }
        let displayHabits = activeHabits.isEmpty ? linkedHabits : activeHabits

        var lines: [String] = []
        if !displayPlans.isEmpty {
            let names = displayPlans.prefix(4).map(\.name).joined(separator: "、")
            let suffix = displayPlans.count > 4 ? " 等\(displayPlans.count)项" : ""
            lines.append("愿望：\(names)\(suffix)")
        }
        if !displayHabits.isEmpty {
            let names = displayHabits.prefix(4).map(\.name).joined(separator: "、")
            let suffix = displayHabits.count > 4 ? " 等\(displayHabits.count)项" : ""
            lines.append("习惯：\(names)\(suffix)")
        }

        if lines.isEmpty {
            return "到了「\(anchor.name)」时刻，点击查看并安排今天的微步吧！"
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let req = response.notification.request
        var anchorId = req.content.userInfo["anchorId"] as? String
        if anchorId == nil, req.identifier.hasPrefix("anchor_") {
            let trimmed = String(req.identifier.dropFirst("anchor_".count))
            if let range = trimmed.range(of: "_w", options: .backwards) ?? trimmed.range(of: "_o", options: .backwards) {
                anchorId = String(trimmed[..<range.lowerBound])
            } else {
                anchorId = trimmed
            }
        }

        if response.actionIdentifier == Self.snoozeActionId {
            let snoozeContent = UNMutableNotificationContent()
            snoozeContent.title = req.content.title.replacingOccurrences(of: "再响 (2/3)", with: "贪睡再响").replacingOccurrences(of: "再响 (3/3)", with: "贪睡再响")
            snoozeContent.body = req.content.body
            snoozeContent.sound = .default
            snoozeContent.categoryIdentifier = Self.alarmCategoryId
            snoozeContent.userInfo = req.content.userInfo
            if #available(iOS 15.0, *) {
                snoozeContent.interruptionLevel = .timeSensitive
            }
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 300, repeats: false)
            let snoozeReq = UNNotificationRequest(
                identifier: "anchor_snooze_\(anchorId ?? UUID().uuidString)_\(Int(Date().timeIntervalSince1970))",
                content: snoozeContent,
                trigger: trigger
            )
            center.add(snoozeReq)
            completionHandler()
            return
        }

        if let id = anchorId, !id.isEmpty {
            DispatchQueue.main.async {
                self.pendingAnchorId = id
                NotificationCenter.default.post(
                    name: Self.didTapAnchorNotification,
                    object: nil,
                    userInfo: ["anchorId": id]
                )
            }
        }
        completionHandler()
    }
}
