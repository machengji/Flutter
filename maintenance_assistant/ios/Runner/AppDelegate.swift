import Flutter
import UIKit
import EventKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let eventStore = EKEventStore()
  private let ecoQueue = DispatchQueue(label: "com.maintenance.assistant.eco_queue", qos: .userInitiated)
  private var suppressStoreChangeUntil: Date = .distantPast
  private let channelName = "com.maintenance.assistant/apple_eco"
  private var methodChannel: FlutterMethodChannel?
  private var documentPickerResult: FlutterResult?

  private func markInternalEventStoreWrite() {
    suppressStoreChangeUntil = Date().addingTimeInterval(2.5)
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      // 彻底清除历史版本遗留的 App 本地定时重复通知，所有提醒完全交由 iOS 系统日历处理
      UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
      UNUserNotificationCenter.current().removeAllDeliveredNotifications()
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
    // 忽略 App 自身写入/删除提醒与日历所触发的通知，杜绝双向同步递归风暴
    if Date() < suppressStoreChangeUntil {
      return
    }
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      if Date() < self.suppressStoreChangeUntil {
        return
      }
      self.methodChannel?.invokeMethod("onEventStoreChanged", arguments: nil)
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

    case "deletePlanFromSystem":
      let title = args["title"] as? String ?? ""
      let reminderId = args["reminderId"] as? String
      let alsoDeleteCalendarEvents = args["alsoDeleteCalendarEvents"] as? Bool ?? true
      deletePlanFromSystem(
        title: title,
        reminderId: reminderId,
        alsoDeleteCalendarEvents: alsoDeleteCalendarEvents,
        result: result
      )

    case "deleteAnchorFromSystem":
      let name = args["name"] as? String ?? ""
      deleteAnchorFromSystem(name: name, result: result)

    case "clearAnchorCalendarEvents":
      let anchorNames = args["anchorNames"] as? [String] ?? []
      clearAnchorCalendarEvents(anchorNames: anchorNames, result: result)

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
      let repeatMode = args["repeatMode"] as? String ?? "daily"
      let repeatLabel = args["repeatLabel"] as? String ?? "每天"
      let effectiveDays = args["effectiveDays"] as? [Int] ?? [1, 2, 3, 4, 5, 6, 7]
      syncAnchor(
        name: name,
        time: time,
        items: items,
        repeatMode: repeatMode,
        repeatLabel: repeatLabel,
        effectiveDays: effectiveDays,
        result: result
      )

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
      let syncAnchorToCalendar = args["syncAnchorToCalendar"] as? Bool ?? false
      batchSync(plans: plans, anchors: anchors, syncAnchorToCalendar: syncAnchorToCalendar, result: result)

    case "shareFile":
      let filePath = args["filePath"] as? String ?? ""
      shareFile(filePath: filePath, result: result)

    case "shareText":
      let text = args["text"] as? String ?? ""
      shareText(text: text, result: result)

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

  // MARK: - Dedicated "微行动锚点" Event Calendar (独立日历分组，直接按重复日期展示锚点与关联任务)

  private func getOrCreateAnchorEventCalendar() -> (calendar: EKCalendar?, errorMessage: String?) {
    let calendars = eventStore.calendars(for: .event)
    if let existing = calendars.first(where: { $0.title == "微行动锚点" && $0.allowsContentModifications }) {
      return (existing, nil)
    }

    var candidateSources: [EKSource] = []
    if let defaultSource = eventStore.defaultCalendarForNewEvents?.source,
       defaultSource.sourceType == .calDAV || defaultSource.sourceType == .local || defaultSource.sourceType == .exchange {
      candidateSources.append(defaultSource)
    }
    for src in eventStore.sources where src.sourceType == .calDAV || src.sourceType == .local || src.sourceType == .exchange {
      if !candidateSources.contains(where: { $0.sourceIdentifier == src.sourceIdentifier }) {
        candidateSources.append(src)
      }
    }

    if candidateSources.isEmpty {
      return (nil, "未找到支持创建新日历分组的账户源，请在系统「日历」App中检查账户设置")
    }

    var lastError: String = "无法创建「微行动锚点」专属日历分组"
    for source in candidateSources {
      let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
      newCalendar.title = "微行动锚点"
      newCalendar.cgColor = UIColor(red: 45.0 / 255.0, green: 106.0 / 255.0, blue: 79.0 / 255.0, alpha: 1.0).cgColor
      newCalendar.source = source
      do {
        try eventStore.saveCalendar(newCalendar, commit: true)
        return (newCalendar, nil)
      } catch {
        lastError = error.localizedDescription
      }
    }

    return (nil, "无法创建「微行动锚点」专属日历分组: \(lastError)")
  }

  /// 计算从今天起第一个符合 effectiveDays (1=周一 ... 7=周日) 的触发时间
  private func computeNextAnchorDueDate(hour: Int, minute: Int, effectiveDays: [Int]) -> Date {
    let validDays = Set(effectiveDays.filter { $0 >= 1 && $0 <= 7 })
    let cal = Calendar.current
    let now = Date()

    for offset in 0..<8 {
      guard let candidateDay = cal.date(byAdding: .day, value: offset, to: now) else { continue }
      let weekday = cal.component(.weekday, from: candidateDay) // 1=Sun, 2=Mon ... 7=Sat
      let isoDay = weekday == 1 ? 7 : (weekday - 1) // 1=Mon ... 7=Sun
      if validDays.isEmpty || validDays.contains(isoDay) {
        var comps = cal.dateComponents([.year, .month, .day], from: candidateDay)
        comps.hour = hour
        comps.minute = minute
        if let candidateDate = cal.date(from: comps) {
          return candidateDate
        }
      }
    }

    var fallbackComps = cal.dateComponents([.year, .month, .day], from: now)
    fallbackComps.hour = hour
    fallbackComps.minute = minute
    return cal.date(from: fallbackComps) ?? now
  }

  /// 根据 effectiveDays (1=周一 ... 7=周日) 构建 EKRecurrenceRule
  private func buildAnchorRecurrenceRule(effectiveDays: [Int]) -> EKRecurrenceRule {
    let uniqueDays = Array(Set(effectiveDays.filter { $0 >= 1 && $0 <= 7 })).sorted()
    if uniqueDays.count == 7 || uniqueDays.isEmpty {
      return EKRecurrenceRule(recurrenceWith: .daily, interval: 1, end: nil)
    }

    let ekDays: [EKRecurrenceDayOfWeek] = uniqueDays.compactMap { isoDay in
      switch isoDay {
      case 1: return EKRecurrenceDayOfWeek(.monday)
      case 2: return EKRecurrenceDayOfWeek(.tuesday)
      case 3: return EKRecurrenceDayOfWeek(.wednesday)
      case 4: return EKRecurrenceDayOfWeek(.thursday)
      case 5: return EKRecurrenceDayOfWeek(.friday)
      case 6: return EKRecurrenceDayOfWeek(.saturday)
      case 7: return EKRecurrenceDayOfWeek(.sunday)
      default: return nil
      }
    }

    return EKRecurrenceRule(
      recurrenceWith: .weekly,
      interval: 1,
      daysOfTheWeek: ekDays,
      daysOfTheMonth: nil,
      monthsOfTheYear: nil,
      weeksOfTheYear: nil,
      daysOfTheYear: nil,
      setPositions: nil,
      end: nil
    )
  }

  /// 检查当前是否已拥有提醒事项访问权限（仅用于静默清理旧锚点提醒，不主动弹权限窗）
  private func isRemindersAuthorized() -> Bool {
    let status = EKEventStore.authorizationStatus(for: .reminder)
    if #available(iOS 17.0, *) {
      return status == .authorized || status == .fullAccess
    }
    return status == .authorized
  }

  /// 获取「微行动锚点」相关的提醒事项列表（优先只检索专属列表与「微行动」列表，避免扫描用户手机上其他列表的历史提醒）
  private func getRelevantAnchorReminderCalendars() -> [EKCalendar] {
    let writable = eventStore.calendars(for: .reminder).filter { $0.allowsContentModifications }
    return writable.filter { $0.title == "微行动锚点" || $0.title == "微行动" }
  }

  /// 清理系统提醒事项中旧版本遗留的锚点提醒（仅在提醒事项已授权时调用；不会影响普通微行动计划）
  /// - Parameter name: 传特定锚点名时只清该锚点；传 nil 时清理所有历史锚点提醒及空的「微行动锚点」列表
  private func removeLegacyAnchorRemindersIfAuthorized(name: String?, completion: @escaping (Int) -> Void) {
    guard isRemindersAuthorized() else {
      completion(0)
      return
    }

    let targetCals = getRelevantAnchorReminderCalendars()
    guard !targetCals.isEmpty else {
      completion(0)
      return
    }

    let remPred = eventStore.predicateForReminders(in: targetCals)
    eventStore.fetchReminders(matching: remPred) { [weak self] reminders in
      guard let self = self else {
        completion(0)
        return
      }
      self.ecoQueue.async {
        self.markInternalEventStoreWrite()
        let allReminders = reminders ?? []
        var removedCount = 0

        let targets = allReminders.filter { rem in
          let t = rem.title ?? ""
          let n = rem.notes ?? ""
          let calTitle = rem.calendar.title

          if let targetName = name {
            if calTitle == "微行动锚点" {
              return t == targetName || t == "[微行动锚点] \(targetName)" || t == "⚓️ [微行动锚点] \(targetName)"
            }
            return t == "[微行动锚点] \(targetName)" ||
                   t == "⚓️ [微行动锚点] \(targetName)" ||
                   (t == targetName && (n.contains("[微行动锚点]") || n.contains("关联微行动清单") || n.contains("触发时间：")))
          } else {
            return calTitle == "微行动锚点" ||
                   t.contains("[微行动锚点]") ||
                   t.contains("⚓️ [微行动锚点]") ||
                   n.contains("[微行动锚点]") ||
                   n.contains("关联微行动清单") ||
                   n.contains("触发时间：每天") ||
                   n.contains("来自「微行动助手」的时间锚点")
          }
        }

        for item in targets {
          if (try? self.eventStore.remove(item, commit: false)) != nil {
            removedCount += 1
          }
        }
        if removedCount > 0 {
          try? self.eventStore.commit()
        }

        // 若「微行动锚点」提醒列表已无任何剩余提醒，顺手删除该空列表，使提醒事项界面彻底整洁
        if let anchorRemCal = self.eventStore.calendars(for: .reminder).first(where: { $0.title == "微行动锚点" && $0.allowsContentModifications }) {
          let remainingInAnchorCal = allReminders.filter { rem in
            rem.calendar.calendarIdentifier == anchorRemCal.calendarIdentifier &&
            !targets.contains(where: { $0.calendarItemIdentifier == rem.calendarItemIdentifier })
          }
          if remainingInAnchorCal.isEmpty {
            try? self.eventStore.removeCalendar(anchorRemCal, commit: true)
          }
        }

        completion(removedCount)
      }
    }
  }

  /// 判断某一条日历事件是否属于指定锚点日程（严格区分微行动打卡足迹，避免误删单次打卡足迹）
  private func isMatchingAnchorCalendarEvent(_ ev: EKEvent, anchorName: String?, anchorCalendarId: String?) -> Bool {
    let evTitle = ev.title ?? ""
    let notes = ev.notes ?? ""
    let inDedicatedAnchorCal = (anchorCalendarId != nil && ev.calendar.calendarIdentifier == anchorCalendarId) ||
                               ev.calendar.title == "微行动锚点"

    if let targetName = anchorName {
      if inDedicatedAnchorCal {
        return evTitle == targetName ||
               evTitle == "[微行动锚点] \(targetName)" ||
               evTitle == "⚓️ [微行动锚点] \(targetName)"
      }
      // 非专属日历（兼容更早期历史版本直接写入个人日历的锚点日程）：必须带有明确锚点特征
      return evTitle == "[微行动锚点] \(targetName)" ||
             evTitle == "⚓️ [微行动锚点] \(targetName)" ||
             (evTitle == targetName && (notes.contains("[微行动锚点]") || notes.contains("关联微行动清单") || notes.contains("关联任务与计划") || notes.contains("触发时间：") || (notes.contains("重复周期：") && ev.hasRecurrenceRules)))
    } else {
      if inDedicatedAnchorCal {
        return true
      }
      return evTitle.contains("[微行动锚点]") ||
             evTitle.contains("⚓️ [微行动锚点]") ||
             notes.contains("[微行动锚点]") ||
             notes.contains("关联微行动清单") ||
             notes.contains("关联任务与计划") ||
             notes.contains("触发时间：") ||
             notes.contains("来自「微行动助手」的时间锚点")
    }
  }

  /// 清理系统日历中旧版/同名的锚点日程（必须在 ecoQueue 后台线程调用）
  @discardableResult
  private func removeAnchorCalendarEventsOnQueue(name: String?, anchorCalendarId: String?) -> Int {
    let calStatus = EKEventStore.authorizationStatus(for: .event)
    var hasCalAuth = (calStatus == .authorized)
    if #available(iOS 17.0, *) {
      hasCalAuth = hasCalAuth || (calStatus == .fullAccess)
    }
    guard hasCalAuth else { return 0 }

    let writableCals = eventStore.calendars(for: .event).filter { $0.allowsContentModifications }
    guard !writableCals.isEmpty else { return 0 }

    // 扫描 [-7天, +14天] 窗口足以命中每日及每周重复规则的所有系列事件
    let rangeStart = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    let rangeEnd = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    let existingPred = eventStore.predicateForEvents(withStart: rangeStart, end: rangeEnd, calendars: writableCals)
    let existingEvents = eventStore.events(matching: existingPred)

    var removedCount = 0
    var processedSeriesIds = Set<String>()

    for ev in existingEvents {
      let seriesId = ev.calendarItemIdentifier
      if !seriesId.isEmpty && processedSeriesIds.contains(seriesId) {
        continue
      }

      if isMatchingAnchorCalendarEvent(ev, anchorName: name, anchorCalendarId: anchorCalendarId) {
        if !seriesId.isEmpty {
          processedSeriesIds.insert(seriesId)
        }
        let span: EKSpan = ev.hasRecurrenceRules ? .futureEvents : .thisEvent
        if (try? eventStore.remove(ev, span: span, commit: false)) != nil {
          removedCount += 1
        }
      }
    }
    if removedCount > 0 {
      markInternalEventStoreWrite()
      try? eventStore.commit()
    }
    return removedCount
  }

  // MARK: - Sync Anchor Directly to Dedicated "微行动锚点" Calendar (No Alarms, No Reminders)

  private func syncAnchor(
    name: String,
    time: String,
    items: [String],
    repeatMode: String,
    repeatLabel: String,
    effectiveDays: [Int],
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
      ? "关联任务与计划：暂无关联任务或计划（可在「微行动助手」中添加绑定）"
      : "关联任务与计划：\n" + items.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")

    requestCalendarAccess { [weak self] calGranted, errMsg in
      guard let self = self else { return }
      guard calGranted else {
        result(FlutterError(
          code: "PERMISSION_DENIED",
          message: errMsg ?? "请在 iOS「设置 -> 隐私与安全性 -> 日历」中开启微行动助手的完整日历访问权限",
          details: nil
        ))
        return
      }

      self.ecoQueue.async { [weak self] in
        guard let self = self else { return }
        self.markInternalEventStoreWrite()

        let calResult = self.getOrCreateAnchorEventCalendar()
        guard let anchorEventCal = calResult.calendar else {
          DispatchQueue.main.async {
            result(FlutterError(
              code: "CREATE_CALENDAR_FAILED",
              message: calResult.errorMessage ?? "无法获取或创建「微行动锚点」专属日历分组",
              details: nil
            ))
          }
          return
        }

        // 1. 先在后台清理日历中旧版/同名的该锚点重复日程，防止重影
        self.removeAnchorCalendarEventsOnQueue(
          name: name,
          anchorCalendarId: anchorEventCal.calendarIdentifier
        )

        // 2. 创建新的「微行动锚点」专属日历重复日程（只显示锚点名称，备注含完整任务和计划清单，不设闹钟）
        let event = EKEvent(eventStore: self.eventStore)
        event.calendar = anchorEventCal
        event.title = name

        let startDate = self.computeNextAnchorDueDate(hour: hour, minute: minute, effectiveDays: effectiveDays)
        event.startDate = startDate
        event.endDate = startDate.addingTimeInterval(15 * 60)
        event.notes = "重复周期：\(repeatLabel) \(time)\n\(itemsText)"
        event.addRecurrenceRule(self.buildAnchorRecurrenceRule(effectiveDays: effectiveDays))

        do {
          self.markInternalEventStoreWrite()
          try self.eventStore.save(event, span: .futureEvents, commit: true)

          // 3. 顺手在后台清理系统「提醒事项」中旧版本遗留的该锚点提醒（仅在已授权时静默执行，不影响普通微行动计划）
          self.removeLegacyAnchorRemindersIfAuthorized(name: name) { _ in }

          DispatchQueue.main.async {
            result([
              "success": true,
              "syncedToCalendar": true,
              "syncedToReminder": false,
              "calendarName": anchorEventCal.title
            ])
          }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "SAVE_FAILED", message: error.localizedDescription, details: nil))
          }
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

  // MARK: - Batch Sync Plans (Reminders Only, Anchors Are In Calendar)

  private func batchSync(
    plans: [[String: Any]],
    anchors: [[String: Any]],
    syncAnchorToCalendar: Bool,
    result: @escaping FlutterResult
  ) {
    requestRemindersAccess { [weak self] remGranted, _ in
      guard let self = self else { return }
      guard remGranted else {
        result(FlutterError(
          code: "PERMISSION_DENIED",
          message: "请在 iOS「设置 -> 隐私与安全性 -> 提醒事项」中开启权限",
          details: nil
        ))
        return
      }

      self.ecoQueue.async { [weak self] in
        guard let self = self else { return }
        self.markInternalEventStoreWrite()

        guard let remCal = self.getOrCreateMicroActionReminderList() else {
          DispatchQueue.main.async {
            result(FlutterError(code: "NO_CALENDAR", message: "无法获取提醒事项列表", details: nil))
          }
          return
        }

        let predicate = self.eventStore.predicateForIncompleteReminders(
          withDueDateStarting: nil,
          ending: nil,
          calendars: [remCal]
        )

        self.eventStore.fetchReminders(matching: predicate) { [weak self] existingReminders in
          guard let self = self else { return }
          self.ecoQueue.async {
            self.markInternalEventStoreWrite()
            let planReminders = existingReminders ?? []
            let existingTitles = Set(planReminders.compactMap { $0.title })
            var syncedPlansCount = 0

            // 1. 批量同步未完成计划到专属「微行动」提醒事项列表
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

            try? self.eventStore.commit()

            // 2. 顺手清理系统「提醒事项」中历史遗留的全部锚点提醒（锚点已迁移至系统专属日历）
            self.removeLegacyAnchorRemindersIfAuthorized(name: nil) { _ in }

            DispatchQueue.main.async {
              result([
                "success": true,
                "syncedPlans": syncedPlansCount,
                "syncedAnchors": 0,
                "listName": remCal.title
              ])
            }
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

  // MARK: - Delete Plan From System (Reminders + Calendar Events)

  private func deletePlanFromSystem(
    title: String,
    reminderId: String?,
    alsoDeleteCalendarEvents: Bool,
    result: @escaping FlutterResult
  ) {
    var reminderDeleted = false
    var calendarEventsDeleted = 0
    let group = DispatchGroup()

    // 1. 删除系统提醒事项中的该计划
    group.enter()
    requestRemindersAccess { [weak self] granted, _ in
      guard let self = self, granted else {
        group.leave()
        return
      }

      // 如果有 reminderId，优先按 identifier 删除
      if let id = reminderId, !id.isEmpty,
         let item = self.eventStore.calendarItem(withIdentifier: id) as? EKReminder {
        do {
          try self.eventStore.remove(item, commit: true)
          reminderDeleted = true
        } catch {}
        group.leave()
        return
      }

      // 否则在可写提醒事项列表中按标题查找并删除
      guard !title.isEmpty else {
        group.leave()
        return
      }

      let reminderCals = self.eventStore.calendars(for: .reminder).filter { $0.allowsContentModifications }
      let predicate = self.eventStore.predicateForReminders(in: reminderCals)
      self.eventStore.fetchReminders(matching: predicate) { reminders in
        DispatchQueue.main.async {
          let targets = (reminders ?? []).filter { $0.title == title }
          for target in targets {
            if (try? self.eventStore.remove(target, commit: false)) != nil {
              reminderDeleted = true
            }
          }
          try? self.eventStore.commit()
          group.leave()
        }
      }
    }

    // 2. 删除系统日历中的关联足迹（如果计划打过卡生成过日程）
    if alsoDeleteCalendarEvents && !title.isEmpty {
      group.enter()
      requestCalendarAccess { [weak self] granted, _ in
        guard let self = self, granted else {
          group.leave()
          return
        }

        let writableCals = self.eventStore.calendars(for: .event).filter { $0.allowsContentModifications }
        let start = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        let end = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        let predicate = self.eventStore.predicateForEvents(withStart: start, end: end, calendars: writableCals)
        let events = self.eventStore.events(matching: predicate)

        for ev in events {
          let evTitle = ev.title ?? ""
          if evTitle == title ||
             evTitle == "[微行动] 🌟 梦想达成：\(title)" ||
             evTitle == "[微行动] ✅ 打卡：\(title)" ||
             (evTitle.contains(title) && (evTitle.contains("微行动") || (ev.notes ?? "").contains("微行动助手"))) {
            if (try? self.eventStore.remove(ev, span: .thisEvent, commit: false)) != nil {
              calendarEventsDeleted += 1
            }
          }
        }
        try? self.eventStore.commit()
        group.leave()
      }
    }

    group.notify(queue: .main) {
      result([
        "success": true,
        "reminderDeleted": reminderDeleted,
        "calendarEventsDeleted": calendarEventsDeleted
      ])
    }
  }

  // MARK: - Delete Anchor From System (Calendar Events + Legacy Reminders)

  private func deleteAnchorFromSystem(
    name: String,
    result: @escaping FlutterResult
  ) {
    guard !name.isEmpty else {
      result(["success": true, "deletedReminders": 0, "deletedCalendarEvents": 0])
      return
    }

    requestCalendarAccess { [weak self] calGranted, errMsg in
      guard let self = self else { return }
      guard calGranted else {
        result(FlutterError(code: "PERMISSION_DENIED", message: errMsg ?? "未开启日历权限", details: nil))
        return
      }

      self.ecoQueue.async { [weak self] in
        guard let self = self else { return }
        self.markInternalEventStoreWrite()

        let anchorCalId = self.eventStore.calendars(for: .event).first(where: { $0.title == "微行动锚点" })?.calendarIdentifier
        let deletedCalendarEvents = self.removeAnchorCalendarEventsOnQueue(
          name: name,
          anchorCalendarId: anchorCalId
        )

        self.removeLegacyAnchorRemindersIfAuthorized(name: name) { deletedReminders in
          DispatchQueue.main.async {
            result([
              "success": true,
              "deletedReminders": deletedReminders,
              "deletedCalendarEvents": deletedCalendarEvents
            ])
          }
        }
      }
    }
  }

  // MARK: - Clear All Anchor Calendars (and Legacy Reminders) From System

  private func clearAnchorCalendarEvents(
    anchorNames: [String],
    result: @escaping FlutterResult
  ) {
    requestCalendarAccess { [weak self] calGranted, errMsg in
      guard let self = self else { return }
      guard calGranted else {
        result(FlutterError(code: "PERMISSION_DENIED", message: errMsg ?? "未开启日历权限", details: nil))
        return
      }

      self.ecoQueue.async { [weak self] in
        guard let self = self else { return }
        self.markInternalEventStoreWrite()

        let anchorCalId = self.eventStore.calendars(for: .event).first(where: { $0.title == "微行动锚点" })?.calendarIdentifier
        let deletedCalendarEvents = self.removeAnchorCalendarEventsOnQueue(
          name: nil,
          anchorCalendarId: anchorCalId
        )

        self.removeLegacyAnchorRemindersIfAuthorized(name: nil) { deletedReminders in
          DispatchQueue.main.async {
            result([
              "success": true,
              "deletedCount": deletedCalendarEvents + deletedReminders
            ])
          }
        }
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

  private func shareText(text: String, result: @escaping FlutterResult) {
    guard !text.isEmpty else {
      result(false)
      return
    }

    let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
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

