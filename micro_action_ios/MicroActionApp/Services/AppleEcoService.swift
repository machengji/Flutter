import Foundation
import EventKit
import UserNotifications
import Combine

/// 苹果原生生态集成服务（EventKit 提醒事项双向同步 + 系统日历足迹 + UserNotifications 锚点定时通知）
final class AppleEcoService {
    static let shared = AppleEcoService()

    private let eventStore = EKEventStore()
    private let calendarTitle = "微行动"
    private let remindersListTitle = "微行动"
    private var storeObserver: NSObjectProtocol?

    private init() {}

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

    func refreshAnchorNotifications(anchors: [AnchorItem]) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }

        let pending = await center.pendingNotificationRequests()
        let anchorReqIds = pending.map(\.identifier).filter { $0.hasPrefix("anchor_") }
        center.removePendingNotificationRequests(withIdentifiers: anchorReqIds)

        for anchor in anchors where anchor.reminderEnabled {
            guard let hm = anchor.hourAndMinute else { continue }
            let content = UNMutableNotificationContent()
            content.title = "微行动时间锚点 · \(anchor.name)"
            content.body = "到了「\(anchor.name)」时刻，完成一个 2 分钟微行动点亮今天吧！"
            content.sound = .default

            let weekdays: [Int]
            switch anchor.repeatCycle {
            case .daily: weekdays = []
            case .weekdays: weekdays = [2, 3, 4, 5, 6]
            case .weekends: weekdays = [1, 7]
            }

            if weekdays.isEmpty {
                var comps = DateComponents()
                comps.hour = hm.hour
                comps.minute = hm.minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                let req = UNNotificationRequest(identifier: "anchor_\(anchor.id)", content: content, trigger: trigger)
                try? await center.add(req)
            } else {
                for wd in weekdays {
                    var comps = DateComponents()
                    comps.weekday = wd
                    comps.hour = hm.hour
                    comps.minute = hm.minute
                    let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                    let req = UNNotificationRequest(identifier: "anchor_\(anchor.id)_w\(wd)", content: content, trigger: trigger)
                    try? await center.add(req)
                }
            }
        }
    }
}
