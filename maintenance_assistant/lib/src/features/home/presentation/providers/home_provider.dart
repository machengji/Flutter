import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../shared/models/plan_model.dart';
import '../../../../shared/models/habit_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../shared/services/deepseek_service.dart';
import '../../../../shared/services/leancloud_backup_service.dart';
import '../../../../shared/models/anchor_model.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/apple_eco_service.dart';
import '../../../../shared/models/notification_model.dart';

class HomeProvider extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();
  final LeanCloudBackupService _cloudBackupService = LeanCloudBackupService();
  
  List<Plan> _plans = [];
  List<Habit> _habits = [];
  List<Anchor> _anchors = [];
  List<NotificationModel> _notifications = [];
  int _notificationsClearedBefore = 0;
  String _rainbowFart = '你今天闪闪发光！';
  
  List<Plan>? _cachedOngoingPlans;
  List<Plan>? _cachedCompletedPlans;
  List<Plan>? _cachedArchivedPlans;
  List<Habit>? _cachedActiveHabits;
  List<Habit>? _cachedStoppedHabits;
  int? _cachedTodayActionCount;
  int _cachedStartOfToday = 0;

  void _invalidateDerivedCaches() {
    _cachedOngoingPlans = null;
    _cachedCompletedPlans = null;
    _cachedArchivedPlans = null;
    _cachedActiveHabits = null;
    _cachedStoppedHabits = null;
    _cachedTodayActionCount = null;
  }

  @override
  void notifyListeners() {
    _invalidateDerivedCaches();
    super.notifyListeners();
  }

  List<Plan> get plans => _plans;
  List<Habit> get habits => _habits;
  List<Anchor> get anchors => _anchors;
  List<NotificationModel> get notifications => _notifications.where((n) => !n.isDeleted).toList();
  int get unreadNotificationCount => _notifications.where((n) => !n.isDeleted && !n.isRead && n.timestamp <= DateTime.now().millisecondsSinceEpoch).length;
  String get rainbowFart => _rainbowFart;
  
  List<Plan> get ongoingPlans =>
      _cachedOngoingPlans ??= _plans.where((p) => p.status != '已完成' && p.status != '已归档').toList();
  List<Plan> get completedPlans =>
      _cachedCompletedPlans ??= _plans.where((p) => p.status == '已完成').toList();
  List<Plan> get archivedPlans =>
      _cachedArchivedPlans ??= _plans.where((p) => p.status == '已归档').toList();
  
  List<Habit> get activeHabits =>
      _cachedActiveHabits ??= _habits.where((h) => h.status != '已停用').toList();
  List<Habit> get stoppedHabits =>
      _cachedStoppedHabits ??= _habits.where((h) => h.status == '已停用').toList();

  /// 统计今日完成的微行动总次数（今日完成的计划数 + 今日习惯打卡次数）
  int get todayActionCount {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    if (_cachedTodayActionCount != null && _cachedStartOfToday == startOfToday) {
      return _cachedTodayActionCount!;
    }

    int count = 0;
    for (final plan in _plans) {
      if (plan.status == '已完成' &&
          plan.completeTime != null &&
          plan.completeTime! >= startOfToday) {
        count++;
      }
    }
    for (final habit in _habits) {
      for (final ts in habit.completionHistory) {
        if (ts >= startOfToday) {
          count++;
        }
      }
    }
    _cachedStartOfToday = startOfToday;
    _cachedTodayActionCount = count;
    return count;
  }

  HomeProvider() {
    _loadData();
    NotificationService().init().catchError((error, stackTrace) {
      debugPrint('Failed to initialize notification service: $error');
    });
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _storage.loadPlans(),
      _storage.loadHabits(),
      _storage.loadAnchors(),
      _storage.loadNotifications(),
      _storage.loadNotificationsClearedBefore(),
    ]);
    _plans = results[0] as List<Plan>;
    _habits = results[1] as List<Habit>;
    _anchors = results[2] as List<Anchor>;
    _notifications = results[3] as List<NotificationModel>;
    _notificationsClearedBefore = results[4] as int;

    // 首屏数据加载完毕后立即通知 UI 渲染
    notifyListeners();

    // 彻底停用并清除 App 自身的所有本地定时通知，提醒完全交由 iOS 系统日历处理
    await NotificationService().cancelAllNotifications();

    _loadRainbowFart(); // Load in background

    // 初始化 iOS 提醒事项双向变更原生监听 (方案 B: EKEventStoreChanged 自动对齐)
    AppleEcoService().setupEventListener(
      onStoreChanged: () {
        debugPrint('[AppleEco] Received onEventStoreChanged notification from iOS');
        syncWithReminders();
      },
    );

    // 启动时自动做一次双向对齐
    syncWithReminders();
  }

  Future<void> _loadRainbowFart() async {
    // Try to load from cache first
    final prefs = await SharedPreferences.getInstance();
    final cachedFart = prefs.getString('lastRainbowFart');
    if (cachedFart != null && cachedFart.isNotEmpty) {
      _rainbowFart = cachedFart;
      notifyListeners();
    } else {
      // If no cache, fetch new one
      refreshRainbowFart();
    }
  }

  Future<void> refreshRainbowFart() async {
    try {
      final response = await http.get(Uri.parse('https://api.shadiao.pro/chp'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['data']['text'];
        if (text != null && text is String && text.isNotEmpty) {
          _rainbowFart = text;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('lastRainbowFart', text);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch rainbow fart: $e');
    }
  }

  // Plan Methods
  Future<void> addPlan(String name, {String? parentId, int decompositionLevel = 0, int groupColorIndex = -1}) async {
    final newPlan = Plan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createTime: DateTime.now().millisecondsSinceEpoch,
      parentId: parentId,
      decompositionLevel: decompositionLevel,
      groupColorIndex: groupColorIndex,
    );
    _plans.insert(0, newPlan);
    await _storage.savePlans(_plans);
    notifyListeners();

    // 实时同步到 iOS 提醒事项
    _syncSinglePlanToReminders(newPlan);
  }

  /// 获取下一个可用的分组颜色索引
  /// 用于同一个计划分解出来的所有子计划
  int getNextGroupColorIndex() {
    // 找出当前已使用的最大颜色索引
    int maxIndex = -1;
    for (var plan in _plans) {
      if (plan.groupColorIndex > maxIndex) {
        maxIndex = plan.groupColorIndex;
      }
    }
    // 返回下一个索引（会在显示时对颜色数组长度取模）
    return maxIndex + 1;
  }

  /// 获取指定计划的分组颜色索引
  int getGroupColorIndex(String planId) {
    final plan = _plans.firstWhere(
      (p) => p.id == planId,
      orElse: () => Plan(id: '', name: '', createTime: 0),
    );
    return plan.groupColorIndex;
  }

  /// 获取指定计划的分解层级
  int getDecompositionLevel(String planId) {
    final plan = _plans.firstWhere(
      (p) => p.id == planId,
      orElse: () => Plan(id: '', name: '', createTime: 0),
    );
    return plan.decompositionLevel;
  }

  Future<void> updatePlan(String id, String newName) async {
    final index = _plans.indexWhere((p) => p.id == id);
    if (index != -1) {
      _plans[index].name = newName;
      await _storage.savePlans(_plans);
      notifyListeners();

      // 实时同步更新到 iOS 提醒事项
      _syncSinglePlanToReminders(_plans[index]);
    }
  }

  Future<void> togglePlanStatus(String id) async {
    final index = _plans.indexWhere((p) => p.id == id);
    if (index != -1) {
      final plan = _plans[index];
      if (plan.status == '已完成') {
        plan.status = '未开始';
        plan.completeTime = null;
      } else {
        plan.status = '已完成';
        plan.completeTime = DateTime.now().millisecondsSinceEpoch;
        AppleEcoService().recordActionFootprintIfNeeded(
          title: plan.name,
          category: 'dream',
          notes: '梦想计划达成！$_rainbowFart',
          completeTimeEpochMs: plan.completeTime,
        );
        refreshRainbowFart(); // Prepare next rainbow fart

        // Remove from anchors
        bool anchorsChanged = false;
        for (var anchor in _anchors) {
          if (anchor.planIds.contains(id)) {
            anchor.planIds.remove(id);
            anchorsChanged = true;
            if (anchor.isCalendarSynced) {
              syncAnchorToAppleEco(anchor, syncToCalendar: true);
            }
          }
        }
        if (anchorsChanged) {
          await _storage.saveAnchors(_anchors);
        }
      }
      await _storage.savePlans(_plans);
      notifyListeners();

      // 实时同步更新完成状态到 iOS 提醒事项
      _syncSinglePlanToReminders(plan);
    }
  }

  Future<void> deletePlan(String id) async {
    final index = _plans.indexWhere((p) => p.id == id);
    String? reminderIdToDelete;
    String? planTitleToDelete;
    if (index != -1) {
      reminderIdToDelete = _plans[index].reminderId;
      planTitleToDelete = _plans[index].name;
      _plans.removeAt(index);
      await _storage.savePlans(_plans);
      notifyListeners();
    }

    // 若在 iOS 生态中，无论是否有 reminderId，均同步从提醒事项和日历中物理删除
    if (planTitleToDelete != null && planTitleToDelete.isNotEmpty) {
      final eco = AppleEcoService();
      if (eco.isSupported) {
        eco.deletePlanFromSystem(
          title: planTitleToDelete,
          reminderId: reminderIdToDelete,
          alsoDeleteCalendarEvents: true,
        );
      }
    }
  }

  Future<void> pinPlan(String id) async {
    final index = _plans.indexWhere((p) => p.id == id);
    if (index != -1) {
      final plan = _plans.removeAt(index);
      _plans.insert(0, plan);
      await _storage.savePlans(_plans);
      notifyListeners();
    }
  }

  /// 将计划归档（标记为非未来重点）
  Future<void> archivePlan(String id) async {
    final index = _plans.indexWhere((p) => p.id == id);
    if (index != -1) {
      _plans[index].status = '已归档';
      await _storage.savePlans(_plans);
      notifyListeners();
    }
  }

  /// 移出归档，恢复为进行中重点
  Future<void> unarchivePlan(String id) async {
    final index = _plans.indexWhere((p) => p.id == id);
    if (index != -1) {
      _plans[index].status = '进行中';
      await _storage.savePlans(_plans);
      notifyListeners();
    }
  }

  /// 切换归档状态
  Future<void> toggleArchivePlan(String id) async {
    final index = _plans.indexWhere((p) => p.id == id);
    if (index != -1) {
      if (_plans[index].status == '已归档') {
        _plans[index].status = '进行中';
      } else {
        _plans[index].status = '已归档';
      }
      await _storage.savePlans(_plans);
      notifyListeners();
    }
  }

  // Habit Methods
  Future<void> addHabit(String name) async {
    final newHabit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createTime: DateTime.now().millisecondsSinceEpoch,
    );
    _habits.insert(0, newHabit);
    await _storage.saveHabits(_habits);
    notifyListeners();
  }

  Future<void> updateHabit(String id, String newName) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      _habits[index].name = newName;
      await _storage.saveHabits(_habits);
      notifyListeners();
    }
  }

  Future<void> checkHabit(String id) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      final habit = _habits[index];
      habit.totalDays++;
      habit.completionHistory.add(DateTime.now().millisecondsSinceEpoch);
      await _storage.saveHabits(_habits);
      AppleEcoService().recordActionFootprintIfNeeded(
        title: habit.name,
        category: 'action',
        notes: '已累计打卡 ${habit.totalDays} 次！$_rainbowFart',
      );
      refreshRainbowFart(); // Prepare next rainbow fart
      notifyListeners();
    }
  }

  /// 获取某个锚点关联的所有计划名称与习惯名称
  List<String> getAnchorBoundItemNames(Anchor anchor) {
    final List<String> names = [];
    for (final pid in anchor.planIds) {
      final idx = _plans.indexWhere((p) => p.id == pid);
      if (idx != -1) {
        names.add('[计划] ${_plans[idx].name}');
      }
    }
    for (final hid in anchor.habitIds) {
      final idx = _habits.indexWhere((h) => h.id == hid);
      if (idx != -1) {
        names.add('[习惯] ${_habits[idx].name}');
      }
    }
    return names;
  }

  /// 将单个锚点同步到 iOS「提醒事项」（若开启开关也会同步至「日历」）
  Future<Map<String, dynamic>> syncAnchorToAppleEco(Anchor anchor, {bool? syncToCalendar}) async {
    final items = getAnchorBoundItemNames(anchor);
    return AppleEcoService().syncAnchorToSystem(
      name: anchor.name,
      time: anchor.time,
      items: items,
      syncToCalendar: syncToCalendar,
    );
  }

  /// 一键将当前所有进行中计划与所有锚点批量同步到 iOS「提醒事项」（若开启开关也会同步至「日历」）
  Future<Map<String, dynamic>> batchSyncToAppleEco({bool? syncAnchorToCalendar}) async {
    final planPayloads = ongoingPlans
        .map((p) => {
              'id': p.id,
              'name': p.name,
            })
        .toList();
    final anchorPayloads = _anchors
        .map((a) => {
              'id': a.id,
              'name': a.name,
              'time': a.time,
              'items': getAnchorBoundItemNames(a),
            })
        .toList();
    return AppleEcoService().batchSyncAll(
      plans: planPayloads,
      anchors: anchorPayloads,
      syncAnchorToCalendar: syncAnchorToCalendar,
    );
  }

  bool _isSyncingReminders = false;
  bool get isSyncingReminders => _isSyncingReminders;

  /// 单个计划实时同步至 iOS 提醒事项
  Future<void> _syncSinglePlanToReminders(Plan plan) async {
    final eco = AppleEcoService();
    if (!eco.isSupported) return;
    final isTwoWay = await eco.isTwoWaySyncEnabled();
    if (!isTwoWay) return;

    final reminderId = await eco.syncPlanToReminder(
      title: plan.name,
      status: plan.status,
      reminderId: plan.reminderId,
    );
    if (reminderId != null && reminderId != plan.reminderId) {
      plan.reminderId = reminderId;
      await _storage.savePlans(_plans);
    }
  }

  /// 全量双向对齐（方案 B）：
  /// 1. 将系统端勾选的完成状态回写到 App 并记录打卡；
  /// 2. 将系统端外部新增（如 Siri 录入）的待办事项导入为 App 计划；
  /// 3. 系统端删除的事项同步在 App 端移除；
  /// 4. App 端新创建或状态变更项同步更新至系统提醒事项。
  Future<Map<String, dynamic>> syncWithReminders({bool isManual = false}) async {
    final eco = AppleEcoService();
    if (!eco.isSupported) {
      return {'success': false, 'message': '仅在 iOS 平台支持提醒事项双向同步'};
    }

    final isTwoWay = await eco.isTwoWaySyncEnabled();
    if (!isTwoWay && !isManual) {
      return {'success': false, 'message': '未开启双向同步'};
    }

    if (_isSyncingReminders) {
      return {'success': false, 'message': '正在同步中'};
    }

    _isSyncingReminders = true;
    if (isManual) notifyListeners();

    try {
      final sysReminders = await eco.fetchAllReminders();
      final Map<String, Map<String, dynamic>> sysMapById = {};
      final Map<String, Map<String, dynamic>> sysMapByTitle = {};

      for (var r in sysReminders) {
        final rId = r['reminderId'] as String;
        final title = r['title'] as String;
        if (rId.isNotEmpty) {
          sysMapById[rId] = r;
        }
        if (title.isNotEmpty) {
          sysMapByTitle[title] = r;
        }
      }

      bool hasChanges = false;
      int importedCount = 0;
      int completedFromSysCount = 0;
      int deletedCount = 0;

      // 1. 检查现存的 App Plans
      final List<Plan> plansToKeep = [];
      for (var plan in _plans) {
        // 如果该计划已经绑定了系统 reminderId
        if (plan.reminderId != null && plan.reminderId!.isNotEmpty) {
          final sysItem = sysMapById[plan.reminderId];
          if (sysItem != null) {
            // 系统端存在该提醒事项
            final isSysCompleted = sysItem['isCompleted'] == true;
            if (isSysCompleted && plan.status != '已完成') {
              // 状态反向同步：系统端打勾完成 -> App 端标记完成
              plan.status = '已完成';
              plan.completeTime = (sysItem['completionDateEpochMs'] as int?) ?? DateTime.now().millisecondsSinceEpoch;
              eco.recordActionFootprintIfNeeded(
                title: plan.name,
                category: 'dream',
                notes: '通过 iOS 提醒事项打卡完成！',
                completeTimeEpochMs: plan.completeTime,
              );
              completedFromSysCount++;
              hasChanges = true;
            } else if (!isSysCompleted && plan.status == '已完成') {
              // App 端完成但系统端未完成 -> 补齐系统端状态
              await eco.syncPlanToReminder(
                title: plan.name,
                status: plan.status,
                reminderId: plan.reminderId,
              );
            }
            plansToKeep.add(plan);
          } else {
            // 系统端已找不到该 reminderId -> 用户在系统端删除了该提醒事项
            deletedCount++;
            hasChanges = true;
            // plansToKeep 不添加该 plan，在 App 同步移除
          }
        } else {
          // 未绑定 reminderId 的 Plan：尝试通过标题匹配已有提醒，或推送到系统端建档
          final sysItem = sysMapByTitle[plan.name];
          if (sysItem != null) {
            plan.reminderId = sysItem['reminderId'] as String?;
            if (sysItem['isCompleted'] == true && plan.status != '已完成') {
              plan.status = '已完成';
              plan.completeTime = (sysItem['completionDateEpochMs'] as int?) ?? DateTime.now().millisecondsSinceEpoch;
              completedFromSysCount++;
            }
            hasChanges = true;
          } else {
            // 写入系统并获得 reminderId
            final newReminderId = await eco.syncPlanToReminder(
              title: plan.name,
              status: plan.status,
            );
            if (newReminderId != null) {
              plan.reminderId = newReminderId;
              hasChanges = true;
            }
          }
          plansToKeep.add(plan);
        }
      }

      _plans = plansToKeep;

      // 2. 检测系统端外部新增的提醒事项（例如通过 Siri 录入） -> 反向导入到 App
      final knownReminderIds = _plans.map((p) => p.reminderId).whereType<String>().toSet();
      final knownTitles = _plans.map((p) => p.name).toSet();

      for (var sysItem in sysReminders) {
        final rId = sysItem['reminderId'] as String;
        final title = sysItem['title'] as String;
        if (title.isEmpty) continue;

        // 如果系统事项的 reminderId 和标题都不在 App 的计划中
        if (!knownReminderIds.contains(rId) && !knownTitles.contains(title)) {
          final isCompleted = sysItem['isCompleted'] == true;
          final newPlan = Plan(
            id: '${DateTime.now().millisecondsSinceEpoch}_$importedCount',
            name: title,
            status: isCompleted ? '已完成' : '未开始',
            createTime: (sysItem['creationDateEpochMs'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
            completeTime: isCompleted ? ((sysItem['completionDateEpochMs'] as int?) ?? DateTime.now().millisecondsSinceEpoch) : null,
            reminderId: rId,
          );
          _plans.insert(0, newPlan);
          knownReminderIds.add(rId);
          knownTitles.add(title);
          importedCount++;
          hasChanges = true;
        }
      }

      if (hasChanges) {
        await _storage.savePlans(_plans);
      }

      return {
        'success': true,
        'imported': importedCount,
        'completed': completedFromSysCount,
        'deleted': deletedCount,
        'total': _plans.length,
      };
    } catch (e) {
      debugPrint('Error during two-way sync with reminders: $e');
      return {'success': false, 'message': '同步异常: $e'};
    } finally {
      _isSyncingReminders = false;
      notifyListeners();
    }
  }

  /// 将本地所有已完成计划批量补录到 iOS 系统「日历」日程（自动根据真实完成时间入历并去重）
  Future<Map<String, dynamic>> syncCompletedPlansToCalendar() async {
    final completed = completedPlans;
    if (completed.isEmpty) {
      return {
        'success': true,
        'message': '暂无已完成的计划',
        'recordedCount': 0,
        'skippedCount': 0,
      };
    }

    final payloads = completed.map((p) => {
      'title': p.name,
      'completeTimeEpochMs': p.completeTime ?? p.createTime,
      'notes': '已完成微行动计划：${p.name}',
    }).toList();

    return AppleEcoService().batchRecordCompletedPlans(payloads);
  }

  Future<void> toggleHabitStatus(String id) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      final habit = _habits[index];
      habit.status = habit.status == '已停用' ? '进行中' : '已停用';

      // Remove from anchors if stopped
      if (habit.status == '已停用') {
        bool anchorsChanged = false;
        for (var anchor in _anchors) {
          if (anchor.habitIds.contains(id)) {
            anchor.habitIds.remove(id);
            anchorsChanged = true;
            if (anchor.isCalendarSynced) {
              syncAnchorToAppleEco(anchor, syncToCalendar: true);
            }
          }
        }
        if (anchorsChanged) {
          await _storage.saveAnchors(_anchors);
        }
      }
      await _storage.saveHabits(_habits);
      notifyListeners();
    }
  }

  Future<void> deleteHabit(String id) async {
    _habits.removeWhere((h) => h.id == id);
    await _storage.saveHabits(_habits);
    notifyListeners();
  }

  Future<void> pinHabit(String id) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      final habit = _habits.removeAt(index);
      _habits.insert(0, habit);
      await _storage.saveHabits(_habits);
      notifyListeners();
    }
  }

  // Anchor Methods
  Future<void> addAnchor(String name, String time) async {
    final newAnchor = Anchor(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      time: time,
    );
    _anchors.add(newAnchor);
    _anchors.sort((a, b) => a.time.compareTo(b.time)); // Sort by time
    await _storage.saveAnchors(_anchors);
    notifyListeners();
  }

  Future<void> updateAnchor(String id, String name, String time) async {
    final index = _anchors.indexWhere((a) => a.id == id);
    if (index != -1) {
      final oldName = _anchors[index].name;
      final targetAnchor = _anchors[index];
      targetAnchor.name = name;
      targetAnchor.time = time;
      _anchors.sort((a, b) => a.time.compareTo(b.time));
      await _storage.saveAnchors(_anchors);
      notifyListeners();

      if (targetAnchor.isCalendarSynced) {
        final eco = AppleEcoService();
        if (eco.isSupported) {
          if (oldName != name) {
            await eco.deleteAnchorFromSystem(oldName);
          }
          await syncAnchorToAppleEco(targetAnchor, syncToCalendar: true);
        }
      }
    }
  }

  Future<void> deleteAnchor(String id) async {
    final index = _anchors.indexWhere((a) => a.id == id);
    if (index != -1) {
      final anchorToDelete = _anchors[index];
      await NotificationService().cancelNotification(id.hashCode);
      _anchors.removeAt(index);
      await _storage.saveAnchors(_anchors);
      notifyListeners();

      // 同步在 iOS 系统日历（及历史遗留提醒事项）中物理删除该锚点
      final eco = AppleEcoService();
      if (eco.isSupported) {
        eco.deleteAnchorFromSystem(anchorToDelete.name);
      }
    }
  }

  /// 将单个锚点关联至 iOS 系统日历（创建每日重复日历日程）
  Future<Map<String, dynamic>> linkAnchorToCalendar(Anchor anchor) async {
    final res = await syncAnchorToAppleEco(anchor, syncToCalendar: true);
    if (res['success'] == true) {
      final index = _anchors.indexWhere((a) => a.id == anchor.id);
      if (index != -1) {
        _anchors[index].isCalendarSynced = true;
        await _storage.saveAnchors(_anchors);
        notifyListeners();
      }
    }
    return res;
  }

  /// 取消单个锚点在 iOS 系统日历中的关联日程
  Future<Map<String, dynamic>> unlinkAnchorFromCalendar(Anchor anchor) async {
    final eco = AppleEcoService();
    if (!eco.isSupported) {
      return {
        'success': false,
        'message': '当前设备非 iOS 平台，仅在 iPhone/iPad 上支持取消系统日历关联',
      };
    }

    final res = await eco.deleteAnchorFromSystem(anchor.name);
    final index = _anchors.indexWhere((a) => a.id == anchor.id);
    if (index != -1) {
      _anchors[index].isCalendarSynced = false;
      await _storage.saveAnchors(_anchors);
      notifyListeners();
    }
    return res;
  }

  /// 一键将所有锚点关联至 iOS 系统日历
  Future<Map<String, dynamic>> linkAllAnchorsToCalendar() async {
    final eco = AppleEcoService();
    if (!eco.isSupported) {
      return {
        'success': false,
        'message': '当前设备非 iOS 平台，仅在 iPhone/iPad 上支持关联系统日历',
      };
    }

    int syncedCount = 0;
    for (final anchor in _anchors) {
      final res = await syncAnchorToAppleEco(anchor, syncToCalendar: true);
      if (res['success'] == true) {
        anchor.isCalendarSynced = true;
        syncedCount++;
      }
    }
    await _storage.saveAnchors(_anchors);
    notifyListeners();
    return {
      'success': true,
      'syncedCount': syncedCount,
    };
  }

  /// 一键取消并清空系统日历中所有锚点的日程
  Future<Map<String, dynamic>> clearAllAnchorCalendarEvents() async {
    final anchorNames = _anchors.map((a) => a.name).toList();
    final res = await AppleEcoService().clearAllAnchorCalendarEvents(
      anchorNames: anchorNames,
    );
    if (res['success'] == true) {
      for (final anchor in _anchors) {
        anchor.isCalendarSynced = false;
      }
      await _storage.saveAnchors(_anchors);
      notifyListeners();
    }
    return res;
  }

  Future<void> bindPlanToAnchor(String anchorId, String planId) async {
    final index = _anchors.indexWhere((a) => a.id == anchorId);
    if (index != -1) {
      if (!_anchors[index].planIds.contains(planId)) {
        _anchors[index].planIds.add(planId);
        await _storage.saveAnchors(_anchors);
        notifyListeners();
        if (_anchors[index].isCalendarSynced) {
          syncAnchorToAppleEco(_anchors[index], syncToCalendar: true);
        }
      }
    }
  }

  Future<void> unbindPlanFromAnchor(String anchorId, String planId) async {
    final index = _anchors.indexWhere((a) => a.id == anchorId);
    if (index != -1) {
      _anchors[index].planIds.remove(planId);
      await _storage.saveAnchors(_anchors);
      notifyListeners();
      if (_anchors[index].isCalendarSynced) {
        syncAnchorToAppleEco(_anchors[index], syncToCalendar: true);
      }
    }
  }

  Future<void> bindHabitToAnchor(String anchorId, String habitId) async {
    final index = _anchors.indexWhere((a) => a.id == anchorId);
    if (index != -1) {
      if (!_anchors[index].habitIds.contains(habitId)) {
        _anchors[index].habitIds.add(habitId);
        await _storage.saveAnchors(_anchors);
        notifyListeners();
        if (_anchors[index].isCalendarSynced) {
          syncAnchorToAppleEco(_anchors[index], syncToCalendar: true);
        }
      }
    }
  }

  Future<void> unbindHabitFromAnchor(String anchorId, String habitId) async {
    final index = _anchors.indexWhere((a) => a.id == anchorId);
    if (index != -1) {
      _anchors[index].habitIds.remove(habitId);
      await _storage.saveAnchors(_anchors);
      notifyListeners();
      if (_anchors[index].isCalendarSynced) {
        syncAnchorToAppleEco(_anchors[index], syncToCalendar: true);
      }
    }
  }

  // Import/Export Methods
  String exportData() {
    final Map<String, dynamic> data = {
      'schemaVersion': 1,
      'exportedAt': DateTime.now().millisecondsSinceEpoch,
      'plans': _plans.map((p) => p.toJson()).toList(),
      'habits': _habits.map((h) => h.toJson()).toList(),
      'anchors': _anchors.map((a) => a.toJson()).toList(),
      'notifications': _notifications.map((n) => n.toJson()).toList(),
      'notificationsClearedBefore': _notificationsClearedBefore,
    };
    return jsonEncode(data);
  }

  Future<bool> importData(String jsonString, {bool mergeWithExisting = true}) async {
    final previousPlans = _plans.map((p) => Plan.fromJson(p.toJson())).toList();
    final previousHabits = _habits.map((h) => Habit.fromJson(h.toJson())).toList();
    final previousAnchors = _anchors.map((a) => Anchor.fromJson(a.toJson())).toList();
    final previousNotifications =
        _notifications.map((n) => NotificationModel.fromJson(n.toJson())).toList();
    final previousNotificationsClearedBefore = _notificationsClearedBefore;

    try {
      // 1. 清除开头的 UTF-8 BOM 乱码标记并去除前后无效空白
      var cleanJson = jsonString.trim();
      if (cleanJson.startsWith('\uFEFF')) {
        cleanJson = cleanJson.substring(1).trim();
      }

      final Map<String, dynamic> data = jsonDecode(cleanJson);

      final List<Plan> newPlans = data.containsKey('plans')
          ? (data['plans'] as List<dynamic>).map((json) => Plan.fromJson(json)).toList()
          : [];
      final List<Habit> newHabits = data.containsKey('habits')
          ? (data['habits'] as List<dynamic>).map((json) => Habit.fromJson(json)).toList()
          : [];
      final List<Anchor> newAnchors = data.containsKey('anchors')
          ? (data['anchors'] as List<dynamic>).map((json) => Anchor.fromJson(json)).toList()
          : [];
      final List<NotificationModel> newNotifications = data.containsKey('notifications')
          ? (data['notifications'] as List<dynamic>)
              .map((json) => NotificationModel.fromJson(json))
              .toList()
          : [];
      final importedNotificationsClearedBefore =
          (data['notificationsClearedBefore'] as num?)?.toInt() ??
              previousNotificationsClearedBefore;

      if (mergeWithExisting) {
        // ========== 智能无损合并模式：绝对不抹除本地既有数据 ==========
        // 1. 计划 (Plans) 合并
        final Map<String, Plan> planMap = {for (final p in _plans) p.id: p};
        for (final np in newPlans) {
          if (!planMap.containsKey(np.id)) {
            planMap[np.id] = np;
          } else {
            final existing = planMap[np.id]!;
            if (existing.name == np.name) {
              // 名称一致，视为同一条计划：保留本地已有的提醒事项关联标识符并同步属性
              if (existing.reminderId != null && existing.reminderId!.isNotEmpty) {
                np.reminderId = existing.reminderId;
              }
              planMap[np.id] = np;
            } else {
              // 名称不同，属于历史时间戳碰撞的不同计划：严禁覆盖，重命名唯一ID无损保存
              var uniqueId = '${np.id}_imported';
              int suffix = 1;
              while (planMap.containsKey(uniqueId)) {
                uniqueId = '${np.id}_imported_$suffix';
                suffix++;
              }
              final nonConflictingPlan = Plan(
                id: uniqueId,
                name: np.name,
                status: np.status,
                createTime: np.createTime,
                completeTime: np.completeTime,
                aiTags: np.aiTags,
                isExplored: np.isExplored,
                parentId: np.parentId,
                decompositionLevel: np.decompositionLevel,
                groupColorIndex: np.groupColorIndex,
                reminderId: np.reminderId,
              );
              planMap[uniqueId] = nonConflictingPlan;
            }
          }
        }
        _plans = planMap.values.toList();
        _plans.sort((a, b) => b.createTime.compareTo(a.createTime));

        // 2. 习惯 (Habits) 合并
        final Map<String, Habit> habitMap = {for (final h in _habits) h.id: h};
        for (final nh in newHabits) {
          if (!habitMap.containsKey(nh.id)) {
            habitMap[nh.id] = nh;
          } else {
            final existing = habitMap[nh.id]!;
            final combinedHistory = <int>{
              ...existing.completionHistory,
              ...nh.completionHistory,
            }.toList()..sort();
            existing.completionHistory = combinedHistory;
            existing.totalDays = combinedHistory.length > existing.totalDays
                ? combinedHistory.length
                : existing.totalDays;
            if (nh.name.isNotEmpty) existing.name = nh.name;
          }
        }
        _habits = habitMap.values.toList();
        _habits.sort((a, b) => b.createTime.compareTo(a.createTime));

        // 3. 锚点 (Anchors) 合并
        final Map<String, Anchor> anchorMap = {for (final a in _anchors) a.id: a};
        for (final na in newAnchors) {
          if (!anchorMap.containsKey(na.id)) {
            anchorMap[na.id] = na;
          } else {
            final existing = anchorMap[na.id]!;
            final combinedPlans = <String>{...existing.planIds, ...na.planIds}.toList();
            final combinedHabits = <String>{...existing.habitIds, ...na.habitIds}.toList();
            existing.planIds = combinedPlans;
            existing.habitIds = combinedHabits;
            existing.time = na.time;
            existing.isCalendarSynced = existing.isCalendarSynced || na.isCalendarSynced;
          }
        }
        _anchors = anchorMap.values.toList();

        // 4. 通知 (Notifications) 合并
        final Map<String, NotificationModel> notifMap = {for (final n in _notifications) n.id: n};
        for (final nn in newNotifications) {
          notifMap[nn.id] = nn;
        }
        _notifications = notifMap.values.toList();
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _notificationsClearedBefore = importedNotificationsClearedBefore > _notificationsClearedBefore
            ? importedNotificationsClearedBefore
            : _notificationsClearedBefore;
      } else {
        _plans = newPlans;
        _habits = newHabits;
        _anchors = newAnchors;
        _notifications = newNotifications;
        _notificationsClearedBefore = importedNotificationsClearedBefore;
      }

      await _storage.savePlans(_plans);
      await _storage.saveHabits(_habits);
      await _storage.saveAnchors(_anchors);
      await _storage.saveNotifications(_notifications);
      await _storage.saveNotificationsClearedBefore(_notificationsClearedBefore);

      // ========== 导入后自动与系统提醒事项双向对齐 ==========
      final appleEco = AppleEcoService();
      if (appleEco.isSupported) {
        final isTwoWay = await appleEco.isTwoWaySyncEnabled();
        if (isTwoWay) {
          // 异步触发双向对齐并自动把未同步的新计划同步到苹果「微行动」列表
          syncWithReminders(isManual: false);
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Import failed: $e');
      _plans = previousPlans;
      _habits = previousHabits;
      _anchors = previousAnchors;
      _notifications = previousNotifications;
      _notificationsClearedBefore = previousNotificationsClearedBefore;

      try {
        await _storage.savePlans(_plans);
        await _storage.saveHabits(_habits);
        await _storage.saveAnchors(_anchors);
        await _storage.saveNotifications(_notifications);
        await _storage.saveNotificationsClearedBefore(_notificationsClearedBefore);
      } catch (rollbackError) {
        debugPrint('Rollback failed: $rollbackError');
      }

      notifyListeners();
      return false;
    }
  }

  // Analysis & Sharing Methods
  Future<Map<String, dynamic>> getAnalysisData({bool allData = true, int days = 30}) async {
    final totalPlans = _plans.length;
    final completedPlans = _plans.where((p) => p.status == '已完成').toList();
    final ongoingPlans = _plans.where((p) => p.status != '已完成').toList();

    // 按完成时间从新到旧排序
    completedPlans.sort((a, b) => (b.completeTime ?? 0).compareTo(a.completeTime ?? 0));

    final totalHabits = _habits.length;
    final totalHabitChecks =
        _habits.fold<int>(0, (sum, h) => sum + h.completionHistory.length);

    // 习惯坚持榜按总打卡次数降序
    final sortedHabits = List<Habit>.from(_habits)
      ..sort((a, b) => b.completionHistory.length.compareTo(a.completionHistory.length));

    final habitRank = sortedHabits.take(8).map((h) {
      final cutoff = DateTime.now().subtract(Duration(days: days));
      final recentChecks = h.completionHistory.where((timestamp) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp).isAfter(cutoff);
      }).length;

      return {
        'name': h.name,
        'status': h.status,
        'total_checks': h.completionHistory.length,
        'recent_30d_checks': recentChecks,
        'total_days': h.totalDays,
      };
    }).toList();

    final anchorSummary = _anchors.map((a) => {
      'name': a.name,
      'time': a.time,
      'linked_plans_count': a.planIds.length,
      'linked_habits_count': a.habitIds.length,
    }).toList();

    return {
      'scope': allData ? 'all_data' : 'last_${days}_days',
      'scope_description': allData ? '全量历史数据' : '近$days天数据',
      'plans_overview': {
        'total': totalPlans,
        'completed': completedPlans.length,
        'ongoing': ongoingPlans.length,
        'not_started': _plans.where((p) => p.status == '未开始').length,
        'completion_rate': totalPlans > 0
            ? '${((completedPlans.length / totalPlans) * 100).toStringAsFixed(1)}%'
            : '0%',
      },
      'completed_milestones_samples': completedPlans
          .take(20)
          .map((p) => {
                'name': p.name,
                'completed_at': p.completeTime != null
                    ? DateTime.fromMillisecondsSinceEpoch(p.completeTime!).toIso8601String().substring(0, 10)
                    : '已达成',
              })
          .toList(),
      'ongoing_focus_samples': ongoingPlans
          .take(15)
          .map((p) => {
                'name': p.name,
                'status': p.status,
                'level': p.decompositionLevel,
              })
          .toList(),
      'habits_overview': {
        'total_habits': totalHabits,
        'total_checks': totalHabitChecks,
        'rank': habitRank,
      },
      'anchors_overview': anchorSummary,
    };
  }

  // Analysis State
  final DeepSeekService _deepSeekService = DeepSeekService();
  Map<String, dynamic>? _analysisData;
  bool _isAnalyzing = false;
  bool _isAllDataScope = true; // 默认分析全部数据
  static const String _analysisCacheKeyAll = 'cached_analysis_result_all';
  static const String _analysisCacheKey30d = 'cached_analysis_result_30d';

  final Map<String, Map<String, dynamic>> _singleTaskAnalysisCache = {};
  final Set<String> _analyzingTaskIds = {};

  Map<String, dynamic>? get analysisData => _analysisData;
  bool get isAnalyzing => _isAnalyzing;
  bool get isAllDataScope => _isAllDataScope;
  bool isTaskAnalyzing(String taskId) => _analyzingTaskIds.contains(taskId);
  Map<String, dynamic>? getTaskAnalysis(String taskId) => _singleTaskAnalysisCache[taskId];

  Future<void> loadCachedAnalysis() async {
    if (_analysisData != null) return;
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _isAllDataScope ? _analysisCacheKeyAll : _analysisCacheKey30d;
    final cachedJson = prefs.getString(cacheKey);

    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        _analysisData = jsonDecode(cachedJson);
        notifyListeners();
      } catch (e) {
        // Cache invalid
      }
    }
  }

  Future<void> setAnalysisScope(bool allData) async {
    if (_isAllDataScope == allData && _analysisData != null) return;
    _isAllDataScope = allData;
    _analysisData = null;
    notifyListeners();
    await startAnalysis(force: false, allData: allData);
  }

  Future<void> startAnalysis({bool force = false, bool? allData}) async {
    if (_isAnalyzing) return;
    final scopeAll = allData ?? _isAllDataScope;
    _isAllDataScope = scopeAll;

    if (!force && _analysisData != null) return;

    if (!force && _analysisData == null) {
      await loadCachedAnalysis();
      if (_analysisData != null) return;
    }

    _isAnalyzing = true;
    notifyListeners();

    try {
      final data = await getAnalysisData(allData: scopeAll, days: 30);
      final result = await _deepSeekService.analyzeData(data);

      _analysisData = result;

      // Save cache
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = scopeAll ? _analysisCacheKeyAll : _analysisCacheKey30d;
      await prefs.setString(cacheKey, jsonEncode(result));
    } catch (e) {
      debugPrint('Analysis failed: $e');
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  /// 针对当前进入的具体任务进行深度 AI 专项剖析（难度、卡点、3步攻克路线、推荐锚点与微习惯）
  Future<Map<String, dynamic>?> analyzeSingleTask(Plan plan, {bool force = false}) async {
    if (!force && _singleTaskAnalysisCache.containsKey(plan.id)) {
      return _singleTaskAnalysisCache[plan.id];
    }

    _analyzingTaskIds.add(plan.id);
    notifyListeners();

    try {
      final result = await _deepSeekService.analyzeSinglePlan(
        planName: plan.name,
        status: plan.status,
        subtasks: plan.aiTags,
      );
      _singleTaskAnalysisCache[plan.id] = result;
      return result;
    } catch (e) {
      debugPrint('Single task analysis failed: $e');
      return null;
    } finally {
      _analyzingTaskIds.remove(plan.id);
      notifyListeners();
    }
  }

  /// 生成已完成任务全景战报分享文案
  String generateCompletedShareText() {
    final completed = _plans.where((p) => p.status == '已完成').toList();
    completed.sort((a, b) => (b.completeTime ?? 0).compareTo(a.completeTime ?? 0));

    final totalChecks = _habits.fold<int>(0, (sum, h) => sum + h.completionHistory.length);
    final topHabits = List<Habit>.from(_habits)
      ..sort((a, b) => b.completionHistory.length.compareTo(a.completionHistory.length));
    final bestHabitName = topHabits.isNotEmpty && topHabits.first.completionHistory.isNotEmpty
        ? ' 最强坚持习惯：【${topHabits.first.name}】(${topHabits.first.completionHistory.length}次打卡)\n'
        : '';

    final recentSamples = completed.take(6).map((p) => ' • ${p.name}').join('\n');

    return '''【微行动 · 我的成长与成就战报】 累计已达成梦想与计划：${completed.length} 项 习惯打卡总沉淀：$totalChecks 次
$bestHabitName 近期已达成的微行动亮点：
$recentSamples

用微小的行动，汇聚人生的巨大质变。
—— 来自「微行动助手」
'''.trim();
  }

  /// 生成单个已完成计划的成就捷报分享文案
  String generateSinglePlanShareText(Plan plan) {
    return '''【微行动 · 成就捷报】
我刚刚完成了一项重要计划：「${plan.name}」

把宏大目标拆解为微行动，每一步都算数！
—— 来自「微行动助手」
'''.trim();
  }

  /// 一键唤起 iOS 原生分享面板分享已完成全景战报
  Future<bool> shareCompletedMilestones() async {
    final text = generateCompletedShareText();
    return await AppleEcoService().shareText(text);
  }

  /// 一键唤起 iOS 原生分享面板分享单个已完成计划
  Future<bool> shareSinglePlan(Plan plan) async {
    final text = generateSinglePlanShareText(plan);
    return await AppleEcoService().shareText(text);
  }

  // Notification Methods (App 自身消息提醒已移除，提醒完全由 iOS 系统日历负责)
  Future<void> checkAnchorNotifications() async {
    // 锚点不再生成 App 站内消息提醒
  }

  Future<void> markNotificationAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      await _storage.saveNotifications(_notifications);
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isDeleted = true;
      await _storage.saveNotifications(_notifications);
      notifyListeners();
    }
  }

  /// 清空所有通知历史
  Future<void> clearAllNotifications() async {
    _notificationsClearedBefore = DateTime.now().millisecondsSinceEpoch;
    _notifications.clear();
    await _storage.saveNotifications(_notifications);
    await _storage.saveNotificationsClearedBefore(_notificationsClearedBefore);
    notifyListeners();
  }

  /// 标记通知的任务已完成
  Future<void> markNotificationAsCompleted(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isCompleted = true;
      _notifications[index].isRead = true;
      await _storage.saveNotifications(_notifications);
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> backupToCloud() async {
    final dataJson = exportData();
    return _cloudBackupService.saveBackup(dataJson: dataJson);
  }

  Future<bool> restoreFromCloud({String? syncKey}) async {
    final dataJson = await _cloudBackupService.loadBackupJson(syncKey: syncKey);
    if (dataJson == null || dataJson.isEmpty) {
      return false;
    }
    return importData(dataJson);
  }

  Future<String> getCloudSyncKey() async {
    return _cloudBackupService.getSyncKey();
  }

  Future<void> setCloudSyncKey(String syncKey) async {
    await _cloudBackupService.setSyncKey(syncKey);
  }

  static bool shouldRestoreMissedNotification({
    required int triggerTimestamp,
    required int clearedBeforeTimestamp,
  }) {
    return triggerTimestamp > clearedBeforeTimestamp;
  }
}
