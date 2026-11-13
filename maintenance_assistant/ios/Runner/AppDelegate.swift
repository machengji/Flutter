import Flutter
import UIKit
import EventKit
import UserNotifications
import UniformTypeIdentifiers
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let eventStore = EKEventStore()
  private let ecoQueue = DispatchQueue(label: "com.maintenance.assistant.eco_queue", qos: .userInitiated)
  private var suppressStoreChangeUntil: Date = .distantPast
  private let channelName = "com.maintenance.assistant/apple_eco"
  private var methodChannel: FlutterMethodChannel?
  private var documentPickerResult: FlutterResult?
  private var pendingOpenedAnchorId: String?
  private var celebrationPlayer: AVAudioPlayer?

  private func markInternalEventStoreWrite() {
    suppressStoreChangeUntil = Date().addingTimeInterval(2.5)
  }

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

    // 启动后静默清理历史遗留的旧版「微行动锚点」系统日历分组及提醒事项残留
    cleanupLegacyAnchorSystemDataIfAuthorized()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Foreground & Tap Notification Delegate

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

  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    if let anchorId = userInfo["anchorId"] as? String, !anchorId.isEmpty {
      self.pendingOpenedAnchorId = anchorId
      DispatchQueue.main.async { [weak self] in
        self?.methodChannel?.invokeMethod(
          "onAnchorNotificationTapped",
          arguments: ["anchorId": anchorId]
        )
      }
      completionHandler()
      return
    }
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }

  @objc private func onEventStoreChanged(_ notification: Notification) {
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
    case "consumePendingOpenedAnchor":
      let id = pendingOpenedAnchorId
      pendingOpenedAnchorId = nil
      result(id)

    case "syncAnchorNotifications":
      let anchors = args["anchors"] as? [[String: Any]] ?? []
      let requestPermissionIfNeeded = args["requestPermissionIfNeeded"] as? Bool ?? false
      syncAnchorNotifications(
        anchors: anchors,
        requestPermissionIfNeeded: requestPermissionIfNeeded,
        result: result
      )

    case "cleanupLegacyAnchorSystemData":
      cleanupLegacyAnchorSystemDataIfAuthorized()
      result(["success": true])

    case "playCelebrationCue":
      let kind = args["kind"] as? String ?? "light"
      let soundEnabled = args["soundEnabled"] as? Bool ?? true
      let progress = (args["progress"] as? NSNumber)?.doubleValue ?? 0.5
      playCelebrationCue(kind: kind, soundEnabled: soundEnabled, progress: progress)
      result(["success": true])

    case "syncPlanReminder":
      let title = args["title"] as? String ?? ""
      let status = args["status"] as? String ?? "未开始"
      let notes = args["notes"] as? String
      let reminderId = args["reminderId"] as? String
      let alarmEpochMs = (args["alarmEpochMs"] as? NSNumber)?.int64Value
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

    case "deleteFootprintEvents":
      let title = args["title"] as? String ?? ""
      let targetDayEpochMs = (args["targetDayEpochMs"] as? NSNumber)?.int64Value
      deleteFootprintEvents(
        title: title,
        targetDayEpochMs: targetDayEpochMs,
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
      let alarmEpochMs = (args["alarmEpochMs"] as? NSNumber)?.int64Value
      addPlanReminder(title: title, notes: notes, alarmEpochMs: alarmEpochMs, result: result)

    case "recordFootprint":
      let title = args["title"] as? String ?? ""
      let category = args["category"] as? String ?? "action"
      let notes = args["notes"] as? String
      let timestampEpochMs = (args["timestampEpochMs"] as? NSNumber)?.int64Value
      let mergeOnSameDay = args["mergeOnSameDay"] as? Bool ?? true
      recordFootprint(
        title: title,
        category: category,
        notes: notes,
        timestampEpochMs: timestampEpochMs,
        mergeOnSameDay: mergeOnSameDay,
        result: result
      )

    case "batchRecordCompletedPlans":
      let plans = args["plans"] as? [[String: Any]] ?? []
      batchRecordCompletedPlans(plans: plans, result: result)

    case "batchSync":
      let plans = args["plans"] as? [[String: Any]] ?? []
      batchSync(plans: plans, result: result)

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

  // MARK: - Anchor System-Level Local Notifications (Works Even When App Is Closed)

  private func syncAnchorNotifications(
    anchors: [[String: Any]],
    requestPermissionIfNeeded: Bool,
    result: @escaping FlutterResult
  ) {
    guard #available(iOS 10.0, *) else {
      result(["success": false, "message": "当前 iOS 版本不支持通知调度"])
      return
    }

    let center = UNUserNotificationCenter.current()
    let hasEnabledAnchor = anchors.contains { ($0["isReminderEnabled"] as? Bool) == true }

    center.getNotificationSettings { [weak self] settings in
      guard let self = self else { return }
      let status = settings.authorizationStatus
      var isAuthorized = (status == .authorized)
      if #available(iOS 12.0, *) {
        isAuthorized = isAuthorized || (status == .provisional)
      }
      if #available(iOS 14.0, *) {
        isAuthorized = isAuthorized || (status == .ephemeral)
      }

      if isAuthorized {
        self.scheduleAnchorNotificationsInternal(anchors: anchors, result: result)
        return
      }

      if status == .notDetermined && (requestPermissionIfNeeded || hasEnabledAnchor) {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        center.requestAuthorization(options: authOptions) { [weak self] granted, err in
          guard let self = self else { return }
          if granted {
            self.scheduleAnchorNotificationsInternal(anchors: anchors, result: result)
          } else {
            DispatchQueue.main.async {
              result([
                "success": false,
                "permissionDenied": true,
                "message": err?.localizedDescription ?? "请在 iOS「设置 -> 通知 -> 微行动助手」中开启允许通知"
              ])
            }
          }
        }
        return
      }

      // 若权限已被拒绝或无需请求权限，先清理已挂起的旧通知并如实返回权限状态
      center.getPendingNotificationRequests { requests in
        let ids = requests.map { $0.identifier }
        if !ids.isEmpty {
          center.removePendingNotificationRequests(withIdentifiers: ids)
        }
        DispatchQueue.main.async {
          if status == .denied && (requestPermissionIfNeeded || hasEnabledAnchor) {
            result([
              "success": false,
              "permissionDenied": true,
              "message": "通知权限未开启，请在 iOS「设置 -> 通知 -> 微行动助手」中开启允许通知"
            ])
          } else {
            result([
              "success": true,
              "scheduledCount": 0
            ])
          }
        }
      }
    }
  }

  @available(iOS 10.0, *)
  private func formatAnchorNotificationBody(
    items: [String],
    hasBoundItems: Bool,
    timeStr: String
  ) -> String? {
    if !hasBoundItems {
      return "设定的锚点时间（\(timeStr)）到了"
    }
    if items.isEmpty {
      // 绑定了计划/习惯，且今日已全部完成：当天静默不打扰
      return nil
    }
    return items.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
  }

  @available(iOS 10.0, *)
  private func makeAnchorNotificationRequest(
    identifier: String,
    anchorId: String,
    anchorName: String,
    body: String,
    dateComponents: DateComponents,
    repeats: Bool
  ) -> UNNotificationRequest {
    let content = UNMutableNotificationContent()
    content.title = anchorName
    content.body = body
    content.sound = .default
    content.userInfo = ["anchorId": anchorId]
    if #available(iOS 15.0, *) {
      content.interruptionLevel = .timeSensitive
    }
    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
    return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
  }

  @available(iOS 10.0, *)
  private func scheduleAnchorNotificationsInternal(
    anchors: [[String: Any]],
    result: @escaping FlutterResult
  ) {
    let center = UNUserNotificationCenter.current()
    center.getPendingNotificationRequests { [weak self] existingRequests in
      guard let self = self else { return }

      let oldIds = existingRequests.map { $0.identifier }
      if !oldIds.isEmpty {
        center.removePendingNotificationRequests(withIdentifiers: oldIds)
      }

      let now = Date()
      let cal = Calendar.current
      let sysWeekday = cal.component(.weekday, from: now) // 1=周日, 2=周一 ... 7=周六
      let todayIsoDay = sysWeekday == 1 ? 7 : (sysWeekday - 1) // 1=周一 ... 7=周日

      var primaryRequests: [UNNotificationRequest] = []
      var bridgeRequests: [UNNotificationRequest] = []

      for anchor in anchors {
        guard (anchor["isReminderEnabled"] as? Bool) == true else { continue }
        let anchorId = anchor["id"] as? String ?? ""
        let anchorName = anchor["name"] as? String ?? ""
        guard !anchorId.isEmpty, !anchorName.isEmpty else { continue }

        let timeStr = anchor["time"] as? String ?? "08:00"
        let parts = timeStr.split(separator: ":")
        let hour = parts.count > 0 ? (Int(parts[0]) ?? 8) : 8
        let minute = parts.count > 1 ? (Int(parts[1]) ?? 0) : 0

        let rawDays = (anchor["effectiveDays"] as? [NSNumber])?.map { $0.intValue }
          ?? (anchor["effectiveDays"] as? [Int])
          ?? [1, 2, 3, 4, 5, 6, 7]
        let uniqueDays = Array(Set(rawDays.filter { $0 >= 1 && $0 <= 7 })).sorted()
        let effectiveDays = uniqueDays.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : uniqueDays

        let hasBoundItems = anchor["hasBoundItems"] as? Bool ?? false
        let baselineItems = anchor["baselineItems"] as? [String] ?? []
        let todayRemainingItems = anchor["todayRemainingItems"] as? [String] ?? []

        var todayFireComps = cal.dateComponents([.year, .month, .day], from: now)
        todayFireComps.hour = hour
        todayFireComps.minute = minute
        todayFireComps.second = 0
        let todayFireDate = cal.date(from: todayFireComps) ?? now
        let isTodayUpcoming = todayFireDate > now

        for isoDay in effectiveDays {
          let iosWeekday = (isoDay % 7) + 1 // 1=周日, 2=周一 ... 7=周六
          let needTodaySplit = (isoDay == todayIsoDay) && isTodayUpcoming && (todayRemainingItems != baselineItems)

          if !needTodaySplit {
            if let body = self.formatAnchorNotificationBody(
              items: baselineItems,
              hasBoundItems: hasBoundItems,
              timeStr: timeStr
            ) {
              var comps = DateComponents()
              comps.weekday = iosWeekday
              comps.hour = hour
              comps.minute = minute
              comps.second = 0
              let req = self.makeAnchorNotificationRequest(
                identifier: "anchor_\(anchorId)_w\(isoDay)",
                anchorId: anchorId,
                anchorName: anchorName,
                body: body,
                dateComponents: comps,
                repeats: true
              )
              primaryRequests.append(req)
            }
          } else {
            // 1. 今日尚未到点且部分/全部事项已提前完成：今日按剩余待办单次提醒（若已全完成则今日静默跳过）
            if let todayBody = self.formatAnchorNotificationBody(
              items: todayRemainingItems,
              hasBoundItems: hasBoundItems,
              timeStr: timeStr
            ) {
              let req = self.makeAnchorNotificationRequest(
                identifier: "anchor_\(anchorId)_today",
                anchorId: anchorId,
                anchorName: anchorName,
                body: todayBody,
                dateComponents: todayFireComps,
                repeats: false
              )
              primaryRequests.append(req)
            }

            // 2. 即使彻底关闭 App 多周不打开，未来连续 4 周的同一星期几依然按完整基准清单准时提醒
            if let futureBody = self.formatAnchorNotificationBody(
              items: baselineItems,
              hasBoundItems: hasBoundItems,
              timeStr: timeStr
            ) {
              for weekOffset in 1...4 {
                if let futureDate = cal.date(byAdding: .day, value: weekOffset * 7, to: now) {
                  var futureComps = cal.dateComponents([.year, .month, .day], from: futureDate)
                  futureComps.hour = hour
                  futureComps.minute = minute
                  futureComps.second = 0
                  let req = self.makeAnchorNotificationRequest(
                    identifier: "anchor_\(anchorId)_w\(isoDay)_n\(weekOffset)",
                    anchorId: anchorId,
                    anchorName: anchorName,
                    body: futureBody,
                    dateComponents: futureComps,
                    repeats: false
                  )
                  bridgeRequests.append(req)
                }
              }
            }
          }
        }
      }

      // iOS 单个应用挂起本地通知上限为 64 条，控制在 60 条以内确保高优循环与今日提醒 100% 注册成功
      let maxPendingLimit = 60
      var finalRequests = Array(primaryRequests.prefix(maxPendingLimit))
      if finalRequests.count < maxPendingLimit && !bridgeRequests.isEmpty {
        let remain = maxPendingLimit - finalRequests.count
        finalRequests.append(contentsOf: bridgeRequests.prefix(remain))
      }

      if finalRequests.isEmpty {
        self.cleanupLegacyAnchorSystemDataIfAuthorized()
        DispatchQueue.main.async {
          result([
            "success": true,
            "scheduledCount": 0
          ])
        }
        return
      }

      let group = DispatchGroup()
      var addedCount = 0
      let countLock = NSLock()

      for req in finalRequests {
        group.enter()
        center.add(req) { err in
          if err == nil {
            countLock.lock()
            addedCount += 1
            countLock.unlock()
          }
          group.leave()
        }
      }

      group.notify(queue: .main) { [weak self] in
        self?.cleanupLegacyAnchorSystemDataIfAuthorized()
        result([
          "success": true,
          "scheduledCount": addedCount
        ])
      }
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

  private func isRemindersAuthorized() -> Bool {
    let status = EKEventStore.authorizationStatus(for: .reminder)
    if #available(iOS 17.0, *) {
      return status == .authorized || status == .fullAccess
    }
    return status == .authorized
  }

  private func isCalendarAuthorized() -> Bool {
    let status = EKEventStore.authorizationStatus(for: .event)
    if #available(iOS 17.0, *) {
      return status == .authorized || status == .fullAccess
    }
    return status == .authorized
  }

  // MARK: - Dedicated "微行动" Reminder List (For Ongoing Plans)

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
        return nil
      }
    }

    return nil
  }

  // MARK: - Dedicated "微行动" Event Calendar (森林绿专属日历分组，仅存放已完成的计划与习惯足迹)

  private func getOrCreateMicroActionEventCalendar() -> (calendar: EKCalendar?, errorMessage: String?) {
    let calendars = eventStore.calendars(for: .event)
    if let existing = calendars.first(where: { $0.title == "微行动" && $0.allowsContentModifications }) {
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

    var lastError: String = "无法创建「微行动」专属日历分组"
    for source in candidateSources {
      let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
      newCalendar.title = "微行动"
      // 森林绿配色 (#2D6A4F)
      newCalendar.cgColor = UIColor(red: 45.0 / 255.0, green: 106.0 / 255.0, blue: 79.0 / 255.0, alpha: 1.0).cgColor
      newCalendar.source = source
      do {
        self.markInternalEventStoreWrite()
        try eventStore.saveCalendar(newCalendar, commit: true)
        return (newCalendar, nil)
      } catch {
        lastError = error.localizedDescription
      }
    }

    return (nil, "无法创建「微行动」专属日历分组: \(lastError)")
  }

  // MARK: - Legacy Anchor Calendar & Reminder Cleanup ("微行动锚点" 彻底物理清理)

  private func cleanupLegacyAnchorSystemDataIfAuthorized() {
    if isCalendarAuthorized() {
      ecoQueue.async { [weak self] in
        guard let self = self else { return }
        self.markInternalEventStoreWrite()
        _ = self.removeLegacyAnchorCalendarsAndEventsOnQueue()
      }
    }
    if isRemindersAuthorized() {
      removeLegacyAnchorRemindersIfAuthorized(name: nil) { _ in }
    }
  }

  @discardableResult
  private func removeLegacyAnchorCalendarsAndEventsOnQueue() -> Int {
    guard isCalendarAuthorized() else { return 0 }
    var removedCount = 0

    // 1. 直接移除名为「微行动锚点」的整个旧版日历分组（连根清除其中所有重复锚点日程）
    let allEventCals = eventStore.calendars(for: .event)
    let legacyAnchorCals = allEventCals.filter { $0.title == "微行动锚点" && $0.allowsContentModifications }
    for cal in legacyAnchorCals {
      self.markInternalEventStoreWrite()
      if (try? eventStore.removeCalendar(cal, commit: true)) != nil {
        removedCount += 1
      }
    }

    // 2. 清理更早期版本散落在其他可写日历中带有锚点特征的重复日程
    let remainingWritableCals = eventStore.calendars(for: .event).filter {
      $0.allowsContentModifications && $0.title != "微行动锚点"
    }
    guard !remainingWritableCals.isEmpty else { return removedCount }

    let rangeStart = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    let rangeEnd = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    let pred = eventStore.predicateForEvents(withStart: rangeStart, end: rangeEnd, calendars: remainingWritableCals)
    let events = eventStore.events(matching: pred)

    var processedSeriesIds = Set<String>()
    var eventDeleted = 0
    for ev in events {
      let seriesId = ev.calendarItemIdentifier
      if !seriesId.isEmpty && processedSeriesIds.contains(seriesId) {
        continue
      }
      let evTitle = ev.title ?? ""
      let notes = ev.notes ?? ""
      let isLegacyAnchor = evTitle.contains("[微行动锚点]") ||
                           evTitle.contains("⚓️ [微行动锚点]") ||
                           notes.contains("[微行动锚点]") ||
                           notes.contains("关联微行动清单") ||
                           notes.contains("关联任务与计划") ||
                           notes.contains("来自「微行动助手」的时间锚点")
      if isLegacyAnchor {
        if !seriesId.isEmpty {
          processedSeriesIds.insert(seriesId)
        }
        let span: EKSpan = ev.hasRecurrenceRules ? .futureEvents : .thisEvent
        if (try? eventStore.remove(ev, span: span, commit: false)) != nil {
          eventDeleted += 1
        }
      }
    }
    if eventDeleted > 0 {
      self.markInternalEventStoreWrite()
      try? eventStore.commit()
      removedCount += eventDeleted
    }
    return removedCount
  }

  private func getRelevantAnchorReminderCalendars() -> [EKCalendar] {
    let writable = eventStore.calendars(for: .reminder).filter { $0.allowsContentModifications }
    return writable.filter { $0.title == "微行动锚点" || $0.title == "微行动" }
  }

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

  // MARK: - Record Action Footprint to Dedicated "微行动" Calendar

  private func recordFootprint(
    title: String,
    category: String,
    notes: String?,
    timestampEpochMs: Int64?,
    mergeOnSameDay: Bool,
    result: @escaping FlutterResult
  ) {
    guard !title.isEmpty else {
      result(["success": false, "message": "事项名称不能为空"])
      return
    }
    guard let ms = timestampEpochMs, ms > 0 else {
      result(["success": false, "message": "缺少真实完成时间戳"])
      return
    }

    requestCalendarAccess { [weak self] granted, errMsg in
      guard let self = self else { return }
      guard granted else {
        result([
          "success": false,
          "message": errMsg ?? "请在 iOS「设置 -> 隐私与安全性 -> 日历」中开启微行动助手的日历权限"
        ])
        return
      }

      self.ecoQueue.async { [weak self] in
        guard let self = self else { return }
        self.markInternalEventStoreWrite()

        let calResult = self.getOrCreateMicroActionEventCalendar()
        guard let targetCal = calResult.calendar else {
          DispatchQueue.main.async {
            result([
              "success": false,
              "message": calResult.errorMessage ?? "无法创建「微行动」专属日历分组"
            ])
          }
          return
        }

        let eventDate = Date(timeIntervalSince1970: TimeInterval(ms) / 1000.0)
        let dayStart = Calendar.current.startOfDay(for: eventDate)
        let dayEnd = dayStart.addingTimeInterval(24 * 3600)

        let predicate = self.eventStore.predicateForEvents(
          withStart: dayStart,
          end: dayEnd,
          calendars: [targetCal]
        )
        let existingEvents = self.eventStore.events(matching: predicate)

        if mergeOnSameDay,
           let existing = existingEvents.first(where: { ($0.title ?? "") == title }) {
          // 同一天同一个习惯多次打卡：只保留 1 条记录，更新备注中的打卡次数说明
          if let newNotes = notes, existing.notes != newNotes {
            existing.notes = newNotes
            do {
              self.markInternalEventStoreWrite()
              try self.eventStore.save(existing, span: .thisEvent, commit: true)
            } catch {
              DispatchQueue.main.async {
                result(["success": false, "message": error.localizedDescription])
              }
              return
            }
          }
          DispatchQueue.main.async {
            result(["success": true, "alreadyExists": true, "updated": true])
          }
          return
        }

        let event = EKEvent(eventStore: self.eventStore)
        event.calendar = targetCal
        event.title = title
        event.startDate = eventDate
        event.endDate = eventDate.addingTimeInterval(15 * 60)
        event.notes = notes ?? "来自「微行动助手」的完成记录"

        do {
          self.markInternalEventStoreWrite()
          try self.eventStore.save(event, span: .thisEvent, commit: true)
          DispatchQueue.main.async {
            result(["success": true, "alreadyExists": false])
          }
        } catch {
          DispatchQueue.main.async {
            result(["success": false, "message": error.localizedDescription])
          }
        }
      }
    }
  }

  // MARK: - Delete Footprint Events From Calendar (On Uncheck or Delete Plan/Habit)

  private func deleteFootprintEvents(
    title: String,
    targetDayEpochMs: Int64?,
    result: @escaping FlutterResult
  ) {
    guard !title.isEmpty else {
      result(["success": true, "deletedCount": 0])
      return
    }
    guard isCalendarAuthorized() else {
      result(["success": true, "deletedCount": 0])
      return
    }

    ecoQueue.async { [weak self] in
      guard let self = self else { return }
      self.markInternalEventStoreWrite()

      let deletedCount = self.removeFootprintEventsOnQueue(
        title: title,
        targetDayEpochMs: targetDayEpochMs
      )
      DispatchQueue.main.async {
        result([
          "success": true,
          "deletedCount": deletedCount
        ])
      }
    }
  }

  @discardableResult
  private func removeFootprintEventsOnQueue(title: String, targetDayEpochMs: Int64?) -> Int {
    guard isCalendarAuthorized(), !title.isEmpty else { return 0 }
    let writableCals = eventStore.calendars(for: .event).filter { $0.allowsContentModifications }
    guard !writableCals.isEmpty else { return 0 }

    let rangeStart: Date
    let rangeEnd: Date
    if let ms = targetDayEpochMs, ms > 0 {
      let targetDate = Date(timeIntervalSince1970: TimeInterval(ms) / 1000.0)
      rangeStart = Calendar.current.startOfDay(for: targetDate)
      rangeEnd = rangeStart.addingTimeInterval(24 * 3600)
    } else {
      rangeStart = Calendar.current.date(byAdding: .year, value: -3, to: Date()) ?? Date()
      rangeEnd = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    }

    let predicate = eventStore.predicateForEvents(withStart: rangeStart, end: rangeEnd, calendars: writableCals)
    let events = eventStore.events(matching: predicate)

    var deletedCount = 0
    for ev in events {
      let evTitle = ev.title ?? ""
      let evNotes = ev.notes ?? ""
      let isInMicroActionCal = (ev.calendar.title == "微行动")
      let isMatched: Bool
      if isInMicroActionCal {
        isMatched = (evTitle == title)
      } else {
        // 兼容历史版本写入个人日历的打卡足迹（必须带微行动特征，绝不误删用户同名私人日程）
        isMatched = evTitle == "[微行动] 🌟 梦想达成：\(title)" ||
                    evTitle == "[微行动] ✅ 打卡：\(title)" ||
                    (evTitle == title && (evNotes.contains("微行动") || evNotes.contains("梦想计划达成") || evNotes.contains("累计打卡")))
      }
      if isMatched && !ev.hasRecurrenceRules {
        if (try? eventStore.remove(ev, span: .thisEvent, commit: false)) != nil {
          deletedCount += 1
        }
      }
    }

    if deletedCount > 0 {
      self.markInternalEventStoreWrite()
      try? eventStore.commit()
    }
    return deletedCount
  }

  // MARK: - Batch Backfill Completed Plans & Habit History to Dedicated "微行动" Calendar

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
      guard granted else {
        result(FlutterError(
          code: "PERMISSION_DENIED",
          message: errMsg ?? "请在 iOS「设置 -> 隐私与安全性 -> 日历」中开启日历访问权限",
          details: nil
        ))
        return
      }

      self.ecoQueue.async { [weak self] in
        guard let self = self else { return }
        self.markInternalEventStoreWrite()

        let calResult = self.getOrCreateMicroActionEventCalendar()
        guard let targetCal = calResult.calendar else {
          DispatchQueue.main.async {
            result(FlutterError(
              code: "CREATE_CALENDAR_FAILED",
              message: calResult.errorMessage ?? "无法创建「微行动」专属日历分组",
              details: nil
            ))
          }
          return
        }

        var recordedCount = 0
        var updatedCount = 0
        var skippedCount = 0

        for item in plans {
          guard let title = item["title"] as? String, !title.isEmpty else { continue }
          guard let timeMs = (item["completeTimeEpochMs"] as? NSNumber)?.int64Value, timeMs > 0 else { continue }

          let eventDate = Date(timeIntervalSince1970: TimeInterval(timeMs) / 1000.0)
          let dayStart = Calendar.current.startOfDay(for: eventDate)
          let dayEnd = dayStart.addingTimeInterval(24 * 3600)
          let notes = item["notes"] as? String ?? "来自「微行动助手」的完成记录"

          let predicate = self.eventStore.predicateForEvents(
            withStart: dayStart,
            end: dayEnd,
            calendars: [targetCal]
          )
          let existingEvents = self.eventStore.events(matching: predicate)

          if let existing = existingEvents.first(where: { ($0.title ?? "") == title }) {
            if existing.notes != notes {
              existing.notes = notes
              if (try? self.eventStore.save(existing, span: .thisEvent, commit: false)) != nil {
                updatedCount += 1
              } else {
                skippedCount += 1
              }
            } else {
              skippedCount += 1
            }
            continue
          }

          let event = EKEvent(eventStore: self.eventStore)
          event.calendar = targetCal
          event.title = title
          event.startDate = eventDate
          event.endDate = eventDate.addingTimeInterval(15 * 60)
          event.notes = notes

          if (try? self.eventStore.save(event, span: .thisEvent, commit: false)) != nil {
            recordedCount += 1
          }
        }

        self.markInternalEventStoreWrite()
        try? self.eventStore.commit()

        DispatchQueue.main.async {
          result([
            "success": true,
            "recordedCount": recordedCount,
            "updatedCount": updatedCount,
            "skippedCount": skippedCount
          ])
        }
      }
    }
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
        result(FlutterError(code: "NO_CALENDAR", message: "无法获取系统「微行动」提醒事项列表", details: nil))
        return
      }

      let predicate = self.eventStore.predicateForIncompleteReminders(
        withDueDateStarting: nil,
        ending: nil,
        calendars: [targetCalendar]
      )

      self.eventStore.fetchReminders(matching: predicate) { existingReminders in
        DispatchQueue.main.async {
          self.markInternalEventStoreWrite()
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

  // MARK: - Batch Sync Plans to Reminders

  private func batchSync(
    plans: [[String: Any]],
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
            result(FlutterError(code: "NO_CALENDAR", message: "无法获取系统「微行动」提醒事项列表", details: nil))
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
            self.cleanupLegacyAnchorSystemDataIfAuthorized()

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
        self.markInternalEventStoreWrite()
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
          self.markInternalEventStoreWrite()
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

  // MARK: - Delete Plan From System (Reminders + Calendar Footprints)

  private func deletePlanFromSystem(
    title: String,
    reminderId: String?,
    alsoDeleteCalendarEvents: Bool,
    result: @escaping FlutterResult
  ) {
    var reminderDeleted = false
    var calendarEventsDeleted = 0
    let group = DispatchGroup()

    group.enter()
    requestRemindersAccess { [weak self] granted, _ in
      guard let self = self, granted else {
        group.leave()
        return
      }

      if let id = reminderId, !id.isEmpty,
         let item = self.eventStore.calendarItem(withIdentifier: id) as? EKReminder {
        self.markInternalEventStoreWrite()
        if (try? self.eventStore.remove(item, commit: true)) != nil {
          reminderDeleted = true
        }
        group.leave()
        return
      }

      guard !title.isEmpty else {
        group.leave()
        return
      }

      let reminderCals = self.eventStore.calendars(for: .reminder).filter { $0.allowsContentModifications }
      let predicate = self.eventStore.predicateForReminders(in: reminderCals)
      self.eventStore.fetchReminders(matching: predicate) { reminders in
        self.ecoQueue.async {
          self.markInternalEventStoreWrite()
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

    if alsoDeleteCalendarEvents && !title.isEmpty && isCalendarAuthorized() {
      group.enter()
      ecoQueue.async { [weak self] in
        guard let self = self else {
          group.leave()
          return
        }
        calendarEventsDeleted = self.removeFootprintEventsOnQueue(title: title, targetDayEpochMs: nil)
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

  // MARK: - Legacy Anchor Delete Endpoints (Clean Old System Calendar / Reminders)

  private func deleteAnchorFromSystem(
    name: String,
    result: @escaping FlutterResult
  ) {
    cleanupLegacyAnchorSystemDataIfAuthorized()
    result(["success": true, "deletedReminders": 0, "deletedCalendarEvents": 0])
  }

  private func clearAnchorCalendarEvents(
    anchorNames: [String],
    result: @escaping FlutterResult
  ) {
    ecoQueue.async { [weak self] in
      guard let self = self else { return }
      let deletedCal = self.removeLegacyAnchorCalendarsAndEventsOnQueue()
      self.removeLegacyAnchorRemindersIfAuthorized(name: nil) { deletedRem in
        DispatchQueue.main.async {
          result([
            "success": true,
            "deletedCount": deletedCal + deletedRem
          ])
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

      if let str = String(data: data, encoding: .utf8) {
        stringResult = str
      } else if let str = String(data: data, encoding: .utf16) ?? String(data: data, encoding: .utf16LittleEndian) ?? String(data: data, encoding: .utf16BigEndian) {
        stringResult = str
      } else {
        let gbkEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))
        if let str = String(data: data, encoding: String.Encoding(rawValue: gbkEncoding)) {
          stringResult = str
        } else {
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

  // MARK: - Native Celebration Haptics & Botanical Chime Synthesizer

  private func playCelebrationCue(kind: String, soundEnabled: Bool, progress: Double) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }

      switch kind {
      case "charge_tick":
        if #available(iOS 13.0, *) {
          let style: UIImpactFeedbackGenerator.FeedbackStyle
          if progress < 0.35 {
            style = .soft
          } else if progress < 0.72 {
            style = .light
          } else {
            style = .rigid
          }
          let gen = UIImpactFeedbackGenerator(style: style)
          gen.prepare()
          gen.impactOccurred(intensity: CGFloat(min(1.0, max(0.35, progress))))
        } else {
          let gen = UIImpactFeedbackGenerator(style: .light)
          gen.impactOccurred()
        }

      case "grand":
        let notifyGen = UINotificationFeedbackGenerator()
        notifyGen.prepare()
        notifyGen.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
          let heavyGen = UIImpactFeedbackGenerator(style: .heavy)
          heavyGen.impactOccurred()
        }
        if soundEnabled {
          self.playSynthesizedChime(
            notes: [
              (freq: 523.25, start: 0.00, duration: 0.36, gain: 0.22),
              (freq: 659.25, start: 0.06, duration: 0.36, gain: 0.22),
              (freq: 783.99, start: 0.12, duration: 0.38, gain: 0.24),
              (freq: 1046.50, start: 0.19, duration: 0.42, gain: 0.26)
            ],
            totalDuration: 0.64
          )
        }

      default: // "light"
        let firstGen = UIImpactFeedbackGenerator(style: .light)
        firstGen.prepare()
        firstGen.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.085) {
          let secondGen = UIImpactFeedbackGenerator(style: .medium)
          secondGen.impactOccurred()
        }
        if soundEnabled {
          self.playSynthesizedChime(
            notes: [
              (freq: 659.25, start: 0.00, duration: 0.18, gain: 0.18),
              (freq: 987.77, start: 0.075, duration: 0.24, gain: 0.22)
            ],
            totalDuration: 0.34
          )
        }
      }
    }
  }

  private func playSynthesizedChime(
    notes: [(freq: Double, start: Double, duration: Double, gain: Double)],
    totalDuration: Double
  ) {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.ambient, options: [.mixWithOthers])
      try session.setActive(true)

      let wavData = synthesizeChimeWavData(notes: notes, totalDuration: totalDuration)
      let player = try AVAudioPlayer(data: wavData)
      player.volume = 0.85
      player.prepareToPlay()
      player.play()
      self.celebrationPlayer = player
    } catch {
      // 环境音频不可用时静默忽略，不影响触觉反馈与业务流程
    }
  }

  private func synthesizeChimeWavData(
    notes: [(freq: Double, start: Double, duration: Double, gain: Double)],
    totalDuration: Double
  ) -> Data {
    let sampleRate = 44100
    let sampleCount = max(1, Int(Double(sampleRate) * totalDuration))
    let dataSize = sampleCount * 2
    let fileSize = 36 + dataSize

    var data = Data(capacity: 44 + dataSize)
    data.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
    var chunkSize = UInt32(fileSize).littleEndian
    withUnsafeBytes(of: &chunkSize) { data.append(contentsOf: $0) }
    data.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"
    data.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "

    var subchunk1Size = UInt32(16).littleEndian
    var audioFormat = UInt16(1).littleEndian
    var numChannels = UInt16(1).littleEndian
    var sr = UInt32(sampleRate).littleEndian
    var byteRate = UInt32(sampleRate * 2).littleEndian
    var blockAlign = UInt16(2).littleEndian
    var bitsPerSample = UInt16(16).littleEndian

    withUnsafeBytes(of: &subchunk1Size) { data.append(contentsOf: $0) }
    withUnsafeBytes(of: &audioFormat) { data.append(contentsOf: $0) }
    withUnsafeBytes(of: &numChannels) { data.append(contentsOf: $0) }
    withUnsafeBytes(of: &sr) { data.append(contentsOf: $0) }
    withUnsafeBytes(of: &byteRate) { data.append(contentsOf: $0) }
    withUnsafeBytes(of: &blockAlign) { data.append(contentsOf: $0) }
    withUnsafeBytes(of: &bitsPerSample) { data.append(contentsOf: $0) }

    data.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
    var subchunk2Size = UInt32(dataSize).littleEndian
    withUnsafeBytes(of: &subchunk2Size) { data.append(contentsOf: $0) }

    let twoPi = Double.pi * 2.0
    for i in 0..<sampleCount {
      let t = Double(i) / Double(sampleRate)
      var mixed = 0.0
      for note in notes {
        let localT = t - note.start
        if localT >= 0.0 && localT <= note.duration {
          let attack = min(1.0, localT / 0.008)
          let decay = exp(-localT * (5.2 / max(0.12, note.duration)))
          let env = attack * decay
          let fundamental = sin(twoPi * note.freq * localT)
          let overtone = 0.28 * sin(twoPi * (note.freq * 2.0) * localT)
          mixed += (fundamental + overtone) * env * note.gain
        }
      }
      let clamped = max(-0.95, min(0.95, mixed))
      var pcm = Int16(clamped * 32767.0).littleEndian
      withUnsafeBytes(of: &pcm) { data.append(contentsOf: $0) }
    }

    return data
  }
}
