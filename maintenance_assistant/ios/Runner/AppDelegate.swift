import Flutter
import UIKit
import EventKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let eventStore = EKEventStore()
  private let channelName = "com.maintenance.assistant/apple_eco"
  private var methodChannel: FlutterMethodChannel?
  private var documentPickerResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: channelName,
        binaryMessenger: controller.binaryMessenger
      )
      self.methodChannel = channel
      channel.setMethodCallHandler { [weak self] call, result in
        self?.handleAppleEcoMethodCall(call: call, result: result)
      }
    }

    // 注册系统 EventStore 变化监听，用于双向实时感应系统「提醒事项」的完成/新增/删除
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onEventStoreChanged(_:)),
      name: .EKEventStoreChanged,
      object: eventStore
    )

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Foreground Notification Delegate
  // 确保在 App 前台运行期间，本地通知同样能够正常弹出横幅与声音
  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .badge, .sound])
    } else {
      completionHandler([.alert, .badge, .sound])
    }
  }

  @objc private func onEventStoreChanged(_ notification: Notification) {
    DispatchQueue.main.async { [weak self] in
      self?.methodChannel?.invokeMethod("onEventStoreChanged", arguments: nil)
    }
  }

  private func handleAppleEcoMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]

    switch call.method {
    case "syncPlanReminder":
      let title = args["title"] as? String ?? ""
      let status = args["status"] as? String ?? "未开始"
      let notes = args["notes"] as? String
      let reminderId = args["reminderId"] as? String
      let alarmEpochMs = args["alarmEpochMs"] as? Int64
      syncPlanReminder(
        title: title,
        status: status,
        notes: notes,
        reminderId: reminderId,
        alarmEpochMs: alarmEpochMs,
        result: result
      )

    case "deletePlanReminder":
      let reminderId = args["reminderId"] as? String ?? ""
      deletePlanReminder(reminderId: reminderId, result: result)

    case "fetchAllReminders":
      fetchAllReminders(result: result)

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
      let timestampEpochMs = args["timestampEpochMs"] as? Int64
      recordFootprint(
        title: title,
        category: category,
        notes: notes,
        timestampEpochMs: timestampEpochMs,
        result: result
      )

    case "batchRecordCompletedPlans":
      let plans = args["plans"] as? [[String: Any]] ?? []
      batchRecordCompletedPlans(plans: plans, result: result)

    case "batchSync":
      let plans = args["plans"] as? [[String: Any]] ?? []
      let anchors = args["anchors"] as? [[String: Any]] ?? []
      batchSync(plans: plans, anchors: anchors, result: result)

    case "shareFile":
      let filePath = args["filePath"] as? String ?? ""
      shareFile(filePath: filePath, result: result)

    case "pickJsonFile":
      pickJsonFile(result: result)

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

  // MARK: - Preferred Calendar for Events (优先归入「个人」蓝色日历)

  private func getPreferredEventCalendar() -> EKCalendar? {
    let calendars = eventStore.calendars(for: .event).filter { $0.allowsContentModifications }

    // 1. 优先完全匹配「个人」或「Personal」
    if let personalCal = calendars.first(where: {
      $0.title == "个人" || $0.title.caseInsensitiveCompare("Personal") == .orderedSame
    }) {
      return personalCal
    }

    // 2. 匹配标题包含「个人」或「Personal」的可编辑日历
    if let personalLike = calendars.first(where: {
      $0.title.contains("个人") || $0.title.lowercased().contains("personal")
    }) {
      return personalLike
    }

    // 3. 次优：使用系统默认新事件日历
    if let defaultCal = eventStore.defaultCalendarForNewEvents, defaultCal.allowsContentModifications {
      return defaultCal
    }

    // 4. 回退：首个可编辑日历
    return calendars.first
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
          let remTitle = name
          let predicate = self.eventStore.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: nil,
            calendars: [remCal]
          )
          self.eventStore.fetchReminders(matching: predicate) { existingList in
            DispatchQueue.main.async {
              let existingReminder = existingList?.first(where: {
                $0.title == remTitle || $0.title == "⚓️ [微行动锚点] \(name)" || $0.title == "[微行动锚点] \(name)"
              })
              let reminder = existingReminder ?? EKReminder(eventStore: self.eventStore)
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

        // 2. 写入系统日历（优先使用「个人」蓝色日历，每日重复日程）
        if calGranted, let evCal = self.getPreferredEventCalendar() {
          let evTitle = name
          var startComps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
          startComps.hour = hour
          startComps.minute = minute
          let startDate = Calendar.current.date(from: startComps) ?? Date()
          let endDate = startDate.addingTimeInterval(15 * 60)

          let dayStart = Calendar.current.startOfDay(for: startDate)
          let dayEnd = dayStart.addingTimeInterval(24 * 3600)
          let writableCals = self.eventStore.calendars(for: .event).filter { $0.allowsContentModifications }
          let evPredicate = self.eventStore.predicateForEvents(withStart: dayStart, end: dayEnd, calendars: writableCals)
          let existingEvent = self.eventStore.events(matching: evPredicate).first(where: {
            $0.title == evTitle || $0.title == "[微行动锚点] \(name)" || $0.title == "⚓️ [微行动锚点] \(name)"
          })

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
    timestampEpochMs: Int64?,
    result: @escaping FlutterResult
  ) {
    guard !title.isEmpty else {
      result(["success": false])
      return
    }

    requestCalendarAccess { [weak self] granted, errMsg in
      guard let self = self else { return }
      guard granted, let targetCal = self.getPreferredEventCalendar() else {
        result([
          "success": false,
          "message": errMsg ?? "未开启日历权限"
        ])
        return
      }

      let eventDate: Date
      if let ms = timestampEpochMs, ms > 0 {
        eventDate = Date(timeIntervalSince1970: TimeInterval(ms) / 1000.0)
      } else {
        eventDate = Date()
      }

      let dayStart = Calendar.current.startOfDay(for: eventDate)
      let dayEnd = dayStart.addingTimeInterval(24 * 3600)
      let evTitle = title

      // 智能去重：如果在目标完成日期的日历中已存在该任务的日程，跳过避免重复
      let writableCals = self.eventStore.calendars(for: .event).filter { $0.allowsContentModifications }
      let predicate = self.eventStore.predicateForEvents(withStart: dayStart, end: dayEnd, calendars: writableCals)
      let existingEvents = self.eventStore.events(matching: predicate)
      let badge = category == "dream" ? "🌟 梦想达成" : "✅ 打卡"
      if existingEvents.contains(where: {
        $0.title == evTitle || $0.title == "[微行动] \(badge)：\(title)" || ($0.title.contains(title) && $0.title.contains("微行动"))
      }) {
        result(["success": true, "alreadyExists": true])
        return
      }

      let event = EKEvent(eventStore: self.eventStore)
      event.calendar = targetCal
      event.title = evTitle
      event.startDate = eventDate
      event.endDate = eventDate.addingTimeInterval(15 * 60)
      event.notes = notes ?? "通过「微行动助手」完成的今日行动足迹"

      do {
        try self.eventStore.save(event, span: .thisEvent, commit: true)
        result(["success": true, "alreadyExists": false])
      } catch {
        result(["success": false, "message": error.localizedDescription])
      }
    }
  }

  // MARK: - Batch Record Completed Plans to Calendar

  private func batchRecordCompletedPlans(
    plans: [[String: Any]],
    result: @escaping FlutterResult
  ) {
    guard !plans.isEmpty else {
      result(["success": true, "recordedCount": 0, "skippedCount": 0])
      return
    }

    requestCalendarAccess { [weak self] granted, errMsg in
      guard let self = self else { return }
      guard granted, let targetCal = self.getPreferredEventCalendar() else {
        result([
          "success": false,
          "message": errMsg ?? "未开启日历权限"
        ])
        return
      }

      var recordedCount = 0
      var skippedCount = 0
      let writableCals = self.eventStore.calendars(for: .event).filter { $0.allowsContentModifications }

      for item in plans {
        guard let title = item["title"] as? String, !title.isEmpty else { continue }
        let ms = item["completeTimeEpochMs"] as? Int64
        let eventDate: Date
        if let timeMs = ms, timeMs > 0 {
          eventDate = Date(timeIntervalSince1970: TimeInterval(timeMs) / 1000.0)
        } else {
          eventDate = Date()
        }

        let dayStart = Calendar.current.startOfDay(for: eventDate)
        let dayEnd = dayStart.addingTimeInterval(24 * 3600)
        let evTitle = title

        let predicate = self.eventStore.predicateForEvents(withStart: dayStart, end: dayEnd, calendars: writableCals)
        let existingEvents = self.eventStore.events(matching: predicate)
        if existingEvents.contains(where: {
          $0.title == evTitle || $0.title == "[微行动] 🌟 梦想达成：\(title)" || ($0.title.contains(title) && $0.title.contains("微行动"))
        }) {
          skippedCount += 1
          continue
        }

        let event = EKEvent(eventStore: self.eventStore)
        event.calendar = targetCal
        event.title = evTitle
        event.startDate = eventDate
        event.endDate = eventDate.addingTimeInterval(15 * 60)
        event.notes = item["notes"] as? String ?? "通过「微行动助手」完成的已完成计划日程记录"

        if (try? self.eventStore.save(event, span: .thisEvent, commit: false)) != nil {
          recordedCount += 1
        }
      }

      try? self.eventStore.commit()
      result([
        "success": true,
        "recordedCount": recordedCount,
        "skippedCount": skippedCount
      ])
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

            // 2. 批量同步锚点到提醒事项与日历（优先使用「个人」蓝色日历）
            let evCal = self.getPreferredEventCalendar()
            let dayStart = Calendar.current.startOfDay(for: Date())
            let dayEnd = dayStart.addingTimeInterval(24 * 3600)
            let writableCals = self.eventStore.calendars(for: .event).filter { $0.allowsContentModifications }
            let existingEvents: [EKEvent]
            if calGranted && !writableCals.isEmpty {
              let evPred = self.eventStore.predicateForEvents(withStart: dayStart, end: dayEnd, calendars: writableCals)
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
                let remTitle = name
                let reminder = (existingReminders ?? []).first(where: {
                  $0.title == remTitle || $0.title == "⚓️ [微行动锚点] \(name)" || $0.title == "[微行动锚点] \(name)"
                }) ?? EKReminder(eventStore: self.eventStore)
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
                let evTitle = name
                var startComps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                startComps.hour = hour
                startComps.minute = minute
                let startDate = Calendar.current.date(from: startComps) ?? Date()
                let endDate = startDate.addingTimeInterval(15 * 60)

                let existingEv = existingEvents.first(where: {
                  $0.title == evTitle || $0.title == "[微行动锚点] \(name)" || $0.title == "⚓️ [微行动锚点] \(name)"
                })
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

  // MARK: - Two-way Sync: Plan to EKReminder

  private func syncPlanReminder(
    title: String,
    status: String,
    notes: String?,
    reminderId: String?,
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
        result(FlutterError(code: "PERMISSION_DENIED", message: errMsg ?? "请在系统设置中开启提醒事项权限", details: nil))
        return
      }

      guard let targetCalendar = self.getOrCreateMicroActionReminderList() else {
        result(FlutterError(code: "NO_CALENDAR", message: "无法获取微行动提醒事项列表", details: nil))
        return
      }

      var matchedReminder: EKReminder? = nil
      if let id = reminderId, !id.isEmpty {
        matchedReminder = self.eventStore.calendarItem(withIdentifier: id) as? EKReminder
      }

      let performSave = { (reminder: EKReminder) in
        reminder.calendar = targetCalendar
        reminder.title = title
        if let n = notes {
          reminder.notes = n
        }
        let isCompleted = (status == "已完成")
        reminder.isCompleted = isCompleted
        if isCompleted && reminder.completionDate == nil {
          reminder.completionDate = Date()
        } else if !isCompleted {
          reminder.completionDate = nil
        }

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
            "reminderId": reminder.calendarItemIdentifier,
            "isCompleted": reminder.isCompleted
          ])
        } catch {
          result(FlutterError(code: "SAVE_FAILED", message: error.localizedDescription, details: nil))
        }
      }

      if let found = matchedReminder {
        performSave(found)
      } else {
        let predicate = self.eventStore.predicateForReminders(in: [targetCalendar])
        self.eventStore.fetchReminders(matching: predicate) { list in
          DispatchQueue.main.async {
            let existing = list?.first(where: { $0.title == title })
            let targetReminder = existing ?? EKReminder(eventStore: self.eventStore)
            performSave(targetReminder)
          }
        }
      }
    }
  }

  // MARK: - Delete Plan Reminder

  private func deletePlanReminder(
    reminderId: String,
    result: @escaping FlutterResult
  ) {
    guard !reminderId.isEmpty else {
      result(["success": true, "removed": false])
      return
    }

    requestRemindersAccess { [weak self] granted, errMsg in
      guard let self = self else { return }
      guard granted else {
        result(FlutterError(code: "PERMISSION_DENIED", message: errMsg ?? "未开启提醒事项权限", details: nil))
        return
      }

      if let item = self.eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder {
        do {
          try self.eventStore.remove(item, commit: true)
          result(["success": true, "removed": true])
        } catch {
          result(FlutterError(code: "DELETE_FAILED", message: error.localizedDescription, details: nil))
        }
      } else {
        result(["success": true, "removed": false])
      }
    }
  }

  // MARK: - Fetch All Reminders in "微行动" List

  private func fetchAllReminders(result: @escaping FlutterResult) {
    requestRemindersAccess { [weak self] granted, errMsg in
      guard let self = self else { return }
      guard granted else {
        result(FlutterError(code: "PERMISSION_DENIED", message: errMsg ?? "未开启提醒事项权限", details: nil))
        return
      }

      guard let targetCalendar = self.getOrCreateMicroActionReminderList() else {
        result(FlutterError(code: "NO_CALENDAR", message: "无法获取微行动提醒事项列表", details: nil))
        return
      }

      let predicate = self.eventStore.predicateForReminders(in: [targetCalendar])
      self.eventStore.fetchReminders(matching: predicate) { reminders in
        DispatchQueue.main.async {
          let items: [[String: Any?]] = (reminders ?? []).map { reminder in
            let completionEpochMs: Int64? = reminder.completionDate != nil
              ? Int64(reminder.completionDate!.timeIntervalSince1970 * 1000)
              : nil
            let creationEpochMs: Int64? = reminder.creationDate != nil
              ? Int64(reminder.creationDate!.timeIntervalSince1970 * 1000)
              : nil

            return [
              "reminderId": reminder.calendarItemIdentifier,
              "title": reminder.title ?? "",
              "isCompleted": reminder.isCompleted,
              "notes": reminder.notes,
              "completionDateEpochMs": completionEpochMs,
              "creationDateEpochMs": creationEpochMs
            ]
          }
          result([
            "success": true,
            "reminders": items
          ])
        }
      }
    }
  }
}

// MARK: - Document Picker & File Sharing
extension AppDelegate: UIDocumentPickerDelegate {
  private func shareFile(filePath: String, result: @escaping FlutterResult) {
    guard !filePath.isEmpty, FileManager.default.fileExists(atPath: filePath) else {
      result(FlutterError(code: "FILE_NOT_FOUND", message: "文件不存在: \(filePath)", details: nil))
      return
    }

    let fileURL = URL(fileURLWithPath: filePath)
    let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)

    if let popover = activityVC.popoverPresentationController,
       let rootVC = window?.rootViewController {
      popover.sourceView = rootVC.view
      popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
      popover.permittedArrowDirections = []
    }

    window?.rootViewController?.present(activityVC, animated: true) {
      result(true)
    }
  }

  private func pickJsonFile(result: @escaping FlutterResult) {
    self.documentPickerResult = result
    let picker: UIDocumentPickerViewController
    if #available(iOS 14.0, *) {
      picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json, .plainText], asCopy: true)
    } else {
      picker = UIDocumentPickerViewController(documentTypes: ["public.json", "public.plain-text"], in: .import)
    }
    picker.delegate = self
    picker.allowsMultipleSelection = false
    window?.rootViewController?.present(picker, animated: true, completion: nil)
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let url = urls.first else {
      documentPickerResult?(nil)
      documentPickerResult = nil
      return
    }

    let shouldStopAccessing = url.startAccessingSecurityScopedResource()
    defer {
      if shouldStopAccessing {
        url.stopAccessingSecurityScopedResource()
      }
    }

    do {
      let data = try Data(contentsOf: url)
      var stringResult: String?

      // 1. 优先尝试标准 UTF-8
      if let str = String(data: data, encoding: .utf8) {
        stringResult = str
      } 
      // 2. 尝试 UTF-16 (带 BOM / 小端 / 大端)
      else if let str = String(data: data, encoding: .utf16) ?? String(data: data, encoding: .utf16LittleEndian) ?? String(data: data, encoding: .utf16BigEndian) {
        stringResult = str
      } 
      // 3. 尝试中文 Windows 常见编码 GB18030 / GBK
      else {
        let gbkEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))
        if let str = String(data: data, encoding: String.Encoding(rawValue: gbkEncoding)) {
          stringResult = str
        } else {
          // 4. 容错无损 UTF-8 解码
          stringResult = String(decoding: data, as: UTF8.self)
        }
      }

      if let content = stringResult {
        documentPickerResult?(content)
      } else {
        documentPickerResult?(FlutterError(code: "READ_FAILED", message: "文件编码无法识别", details: nil))
      }
    } catch {
      documentPickerResult?(FlutterError(code: "READ_FAILED", message: "读取文件失败: \(error.localizedDescription)", details: nil))
    }
    documentPickerResult = nil
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    documentPickerResult?(nil)
    documentPickerResult = nil
  }
}

