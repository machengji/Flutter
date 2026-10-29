import Flutter
import UIKit
import EventKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let eventStore = EKEventStore()
  private let channelName = "com.maintenance.assistant/apple_eco"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: channelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        self?.handleAppleEcoMethodCall(call: call, result: result)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleAppleEcoMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]

    switch call.method {
    case "addPlanReminder":
      let title = args["title"] as? String ?? ""
      let notes = args["notes"] as? String
      let alarmEpochMs = args["alarmEpochMs"] as? Int64
      addPlanReminder(title: title, notes: notes, alarmEpochMs: alarmEpochMs, result: result)

    case "syncAnchor":
      let name = args["name"] as? String ?? ""
      let time = args["time"] as? String ?? "08:00"
      let items = args["items"] as? [String] ?? []
      syncAnchor(name: name, time: time, items: items, result: result)

    case "recordFootprint":
      let title = args["title"] as? String ?? ""
      let category = args["category"] as? String ?? "action"
      let notes = args["notes"] as? String
      recordFootprint(title: title, category: category, notes: notes, result: result)

    case "batchSync":
      let plans = args["plans"] as? [[String: Any]] ?? []
      let anchors = args["anchors"] as? [[String: Any]] ?? []
      batchSync(plans: plans, anchors: anchors, result: result)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Permissions

  private func requestRemindersAccess(completion: @escaping (Bool, String?) -> Void) {
    if #available(iOS 17.0, *) {
      eventStore.requestFullAccessToReminders { granted, error in
        DispatchQueue.main.async {
          completion(granted, error?.localizedDescription)
        }
      }
    } else {
      eventStore.requestAccess(to: .reminder) { granted, error in
        DispatchQueue.main.async {
          completion(granted, error?.localizedDescription)
        }
      }
    }
  }

  private func requestCalendarAccess(completion: @escaping (Bool, String?) -> Void) {
    if #available(iOS 17.0, *) {
      eventStore.requestFullAccessToEvents { granted, error in
        DispatchQueue.main.async {
          completion(granted, error?.localizedDescription)
        }
      }
    } else {
      eventStore.requestAccess(to: .event) { granted, error in
        DispatchQueue.main.async {
          completion(granted, error?.localizedDescription)
        }
      }
    }
  }

  // MARK: - Dedicated "微行动" Reminder List

  private func getOrCreateMicroActionReminderList() -> EKCalendar? {
    let calendars = eventStore.calendars(for: .reminder)
    if let existing = calendars.first(where: { $0.title == "微行动" && $0.allowsContentModifications }) {
      return existing
    }

    let newCalendar = EKCalendar(for: .reminder, eventStore: eventStore)
    newCalendar.title = "微行动"
    newCalendar.cgColor = UIColor(red: 16.0 / 255.0, green: 185.0 / 255.0, blue: 129.0 / 255.0, alpha: 1.0).cgColor

    if let defaultSource = eventStore.defaultCalendarForNewReminders()?.source {
      newCalendar.source = defaultSource
    } else if let calDavSource = eventStore.sources.first(where: { $0.sourceType == .calDAV || $0.sourceType == .local }) {
      newCalendar.source = calDavSource
    }

    if newCalendar.source != nil {
      do {
        try eventStore.saveCalendar(newCalendar, commit: true)
        return newCalendar
      } catch {
        return eventStore.defaultCalendarForNewReminders()
      }
    }

    return eventStore.defaultCalendarForNewReminders()
  }

  // MARK: - Add Single Plan to Reminders

  private func addPlanReminder(
    title: String,
    notes: String?,
    alarmEpochMs: Int64?,
    result: @escaping FlutterResult
  ) {
    guard !title.isEmpty else {
      result(FlutterError(code: "INVALID_ARGS", message: "计划标题不能为空", details: nil))
      return
    }

    requestRemindersAccess { [weak self] granted, errMsg in
      guard let self = self else { return }
      guard granted else {
        result(FlutterError(
          code: "PERMISSION_DENIED",
          message: errMsg ?? "请在 iOS「设置 -> 隐私与安全性 -> 提醒事项」中开启微行动助手的权限",
          details: nil
        ))
        return
      }

      guard let targetCalendar = self.getOrCreateMicroActionReminderList() else {
        result(FlutterError(code: "NO_CALENDAR", message: "无法获取系统提醒事项列表", details: nil))
        return
      }

      let predicate = self.eventStore.predicateForIncompleteReminders(
        withDueDateStarting: nil,
        ending: nil,
        calendars: [targetCalendar]
      )

      self.eventStore.fetchReminders(matching: predicate) { existingReminders in
        DispatchQueue.main.async {
          let existing = existingReminders?.first(where: { $0.title == title })
          let reminder = existing ?? EKReminder(eventStore: self.eventStore)
          reminder.calendar = targetCalendar
          reminder.title = title
          reminder.notes = notes ?? "来自「微行动助手」的梦想计划"

          if let alarms = reminder.alarms {
            for alarm in alarms {
              reminder.removeAlarm(alarm)
            }
          }

          if let ms = alarmEpochMs, ms > 0 {
            let alarmDate = Date(timeIntervalSince1970: TimeInterval(ms) / 1000.0)
            reminder.dueDateComponents = Calendar.current.dateComponents(
              [.year, .month, .day, .hour, .minute],
              from: alarmDate
            )
            reminder.addAlarm(EKAlarm(absoluteDate: alarmDate))
          }

          do {
            try self.eventStore.save(reminder, commit: true)
            result([
              "success": true,
              "listName": targetCalendar.title,
              "updated": existing != nil
            ])
          } catch {
            result(FlutterError(code: "SAVE_FAILED", message: error.localizedDescription, details: nil))
          }
        }
      }
    }
  }

  // MARK: - Sync Anchor to Both Reminders & Calendar

  private func syncAnchor(
    name: String,
    time: String,
    items: [String],
    result: @escaping FlutterResult
  ) {
    guard !name.isEmpty else {
      result(FlutterError(code: "INVALID_ARGS", message: "锚点名称不能为空", details: nil))
      return
    }

    let parts = time.split(separator: ":")
    let hour = parts.count > 0 ? (Int(parts[0]) ?? 8) : 8
    let minute = parts.count > 1 ? (Int(parts[1]) ?? 0) : 0

    let itemsText = items.isEmpty
      ? "暂无绑定微行动，可在微行动助手中添加关联项"
      : "关联微行动清单：\n" + items.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")

    requestRemindersAccess { [weak self] remGranted, _ in
      guard let self = self else { return }
      self.requestCalendarAccess { calGranted, _ in
        guard remGranted || calGranted else {
          result(FlutterError(
            code: "PERMISSION_DENIED",
            message: "请在 iOS「设置 -> 隐私与安全性」中开启日历与提醒事项权限",
            details: nil
          ))
          return
        }

        var syncedToReminder = false
        var syncedToCalendar = false

        let group = DispatchGroup()

        // 1. 写入「微行动」提醒事项（每日重复提醒）
        if remGranted, let remCal = self.getOrCreateMicroActionReminderList() {
          group.enter()
          let remTitle = "⚓️ [微行动锚点] \(name)"
          let predicate = self.eventStore.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: nil,
            calendars: [remCal]
          )
          self.eventStore.fetchReminders(matching: predicate) { existingList in
            DispatchQueue.main.async {
              let reminder = existingList?.first(where: { $0.title == remTitle }) ?? EKReminder(eventStore: self.eventStore)
              reminder.calendar = remCal
              reminder.title = remTitle
              reminder.notes = "触发时间：每天 \(time)\n\(itemsText)"

              var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
              comps.hour = hour
              comps.minute = minute
              reminder.dueDateComponents = comps

              if let alarms = reminder.alarms {
                for a in alarms { reminder.removeAlarm(a) }
              }
              if let alarmDate = Calendar.current.date(from: comps) {
                reminder.addAlarm(EKAlarm(absoluteDate: alarmDate))
              }

              if let rules = reminder.recurrenceRules {
                for r in rules { reminder.removeRecurrenceRule(r) }
              }
              reminder.addRecurrenceRule(EKRecurrenceRule(recurrenceWith: .daily, interval: 1, end: nil))

              if (try? self.eventStore.save(reminder, commit: true)) != nil {
                syncedToReminder = true
              }
              group.leave()
            }
          }
        }

        // 2. 写入系统日历（每日重复日程）
        if calGranted, let evCal = self.eventStore.defaultCalendarForNewEvents {
          let evTitle = "[微行动锚点] \(name)"
          var startComps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
          startComps.hour = hour
          startComps.minute = minute
          let startDate = Calendar.current.date(from: startComps) ?? Date()
          let endDate = startDate.addingTimeInterval(15 * 60)

          let dayStart = Calendar.current.startOfDay(for: startDate)
          let dayEnd = dayStart.addingTimeInterval(24 * 3600)
          let evPredicate = self.eventStore.predicateForEvents(withStart: dayStart, end: dayEnd, calendars: [evCal])
          let existingEvent = self.eventStore.events(matching: evPredicate).first(where: { $0.title == evTitle })

          let event = existingEvent ?? EKEvent(eventStore: self.eventStore)
          event.calendar = evCal
          event.title = evTitle
          event.notes = itemsText
          event.startDate = startDate
          event.endDate = endDate

          if let alarms = event.alarms {
            for a in alarms { event.removeAlarm(a) }
          }
          event.addAlarm(EKAlarm(relativeOffset: 0))

          if existingEvent == nil {
            event.addRecurrenceRule(EKRecurrenceRule(recurrenceWith: .daily, interval: 1, end: nil))
          }

          if (try? self.eventStore.save(event, span: .futureEvents, commit: true)) != nil {
            syncedToCalendar = true
          }
        }

        group.notify(queue: .main) {
          result([
            "success": syncedToReminder || syncedToCalendar,
            "syncedToReminder": syncedToReminder,
            "syncedToCalendar": syncedToCalendar
          ])
        }
      }
    }
  }

  // MARK: - Record Action Footprint to Calendar

  private func recordFootprint(
    title: String,
    category: String,
    notes: String?,
    result: @escaping FlutterResult
  ) {
    guard !title.isEmpty else {
      result(["success": false])
      return
    }

    requestCalendarAccess { [weak self] granted, errMsg in
      guard let self = self else { return }
      guard granted, let targetCal = self.eventStore.defaultCalendarForNewEvents else {
        result([
          "success": false,
          "message": errMsg ?? "未开启日历权限"
        ])
        return
      }

      let now = Date()
      let event = EKEvent(eventStore: self.eventStore)
      event.calendar = targetCal
      let badge = category == "dream" ? "🌟 梦想达成" : "✅ 微行动打卡"
      event.title = "[微行动] \(badge)：\(title)"
      event.startDate = now
      event.endDate = now.addingTimeInterval(15 * 60)
      event.notes = notes ?? "通过「微行动助手」完成的今日行动足迹"

      do {
        try self.eventStore.save(event, span: .thisEvent, commit: true)
        result(["success": true])
      } catch {
        result(["success": false, "message": error.localizedDescription])
      }
    }
  }

  // MARK: - Batch Sync Plans & Anchors

  private func batchSync(
    plans: [[String: Any]],
    anchors: [[String: Any]],
    result: @escaping FlutterResult
  ) {
    requestRemindersAccess { [weak self] remGranted, _ in
      guard let self = self else { return }
      self.requestCalendarAccess { calGranted, _ in
        guard remGranted || calGranted else {
          result(FlutterError(
            code: "PERMISSION_DENIED",
            message: "请在 iOS「设置 -> 隐私与安全性」中开启提醒事项与日历权限",
            details: nil
          ))
          return
        }

        guard let remCal = self.getOrCreateMicroActionReminderList() else {
          result(FlutterError(code: "NO_CALENDAR", message: "无法获取提醒事项列表", details: nil))
          return
        }

        let predicate = self.eventStore.predicateForIncompleteReminders(
          withDueDateStarting: nil,
          ending: nil,
          calendars: [remCal]
        )

        self.eventStore.fetchReminders(matching: predicate) { existingReminders in
          DispatchQueue.main.async {
            let existingTitles = Set((existingReminders ?? []).compactMap { $0.title })
            var syncedPlansCount = 0
            var syncedAnchorsCount = 0

            // 1. 批量同步未完成计划到「微行动」提醒事项列表
            if remGranted {
              for plan in plans {
                guard let name = plan["name"] as? String, !name.isEmpty else { continue }
                if !existingTitles.contains(name) {
                  let reminder = EKReminder(eventStore: self.eventStore)
                  reminder.calendar = remCal
                  reminder.title = name
                  reminder.notes = "来自「微行动助手」的进行中计划"
                  if (try? self.eventStore.save(reminder, commit: false)) != nil {
                    syncedPlansCount += 1
                  }
                } else {
                  syncedPlansCount += 1
                }
              }
            }

            // 2. 批量同步锚点到提醒事项与日历
            let evCal = self.eventStore.defaultCalendarForNewEvents
            let dayStart = Calendar.current.startOfDay(for: Date())
            let dayEnd = dayStart.addingTimeInterval(24 * 3600)
            let existingEvents: [EKEvent]
            if calGranted, let c = evCal {
              let evPred = self.eventStore.predicateForEvents(withStart: dayStart, end: dayEnd, calendars: [c])
              existingEvents = self.eventStore.events(matching: evPred)
            } else {
              existingEvents = []
            }

            for anchor in anchors {
              guard let name = anchor["name"] as? String, !name.isEmpty else { continue }
              let time = anchor["time"] as? String ?? "08:00"
              let items = anchor["items"] as? [String] ?? []
              let parts = time.split(separator: ":")
              let hour = parts.count > 0 ? (Int(parts[0]) ?? 8) : 8
              let minute = parts.count > 1 ? (Int(parts[1]) ?? 0) : 0
              let itemsText = items.isEmpty
                ? "来自「微行动助手」的时间锚点"
                : "关联微行动清单：\n" + items.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")

              var anchorSaved = false

              if remGranted {
                let remTitle = "⚓️ [微行动锚点] \(name)"
                let reminder = (existingReminders ?? []).first(where: { $0.title == remTitle }) ?? EKReminder(eventStore: self.eventStore)
                reminder.calendar = remCal
                reminder.title = remTitle
                reminder.notes = "触发时间：每天 \(time)\n\(itemsText)"
                var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                comps.hour = hour
                comps.minute = minute
                reminder.dueDateComponents = comps
                if let alarms = reminder.alarms {
                  for a in alarms { reminder.removeAlarm(a) }
                }
                if let alarmDate = Calendar.current.date(from: comps) {
                  reminder.addAlarm(EKAlarm(absoluteDate: alarmDate))
                }
                if let rules = reminder.recurrenceRules {
                  for r in rules { reminder.removeRecurrenceRule(r) }
                }
                reminder.addRecurrenceRule(EKRecurrenceRule(recurrenceWith: .daily, interval: 1, end: nil))
                if (try? self.eventStore.save(reminder, commit: false)) != nil {
                  anchorSaved = true
                }
              }

              if calGranted, let targetEvCal = evCal {
                let evTitle = "[微行动锚点] \(name)"
                var startComps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                startComps.hour = hour
                startComps.minute = minute
                let startDate = Calendar.current.date(from: startComps) ?? Date()
                let endDate = startDate.addingTimeInterval(15 * 60)

                let existingEv = existingEvents.first(where: { $0.title == evTitle })
                let event = existingEv ?? EKEvent(eventStore: self.eventStore)
                event.calendar = targetEvCal
                event.title = evTitle
                event.notes = itemsText
                event.startDate = startDate
                event.endDate = endDate
                if let alarms = event.alarms {
                  for a in alarms { event.removeAlarm(a) }
                }
                event.addAlarm(EKAlarm(relativeOffset: 0))
                if existingEv == nil {
                  event.addRecurrenceRule(EKRecurrenceRule(recurrenceWith: .daily, interval: 1, end: nil))
                }
                if (try? self.eventStore.save(event, span: .futureEvents, commit: false)) != nil {
                  anchorSaved = true
                }
              }

              if anchorSaved {
                syncedAnchorsCount += 1
              }
            }

            try? self.eventStore.commit()
            result([
              "success": true,
              "syncedPlans": syncedPlansCount,
              "syncedAnchors": syncedAnchorsCount,
              "listName": remCal.title
            ])
          }
        }
      }
    }
  }
}
