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
  
  List<Plan> get plans => _plans;
  List<Habit> get habits => _habits;
  List<Anchor> get anchors => _anchors;
  List<NotificationModel> get notifications => _notifications.where((n) => !n.isDeleted).toList();
  int get unreadNotificationCount => _notifications.where((n) => !n.isDeleted && !n.isRead && n.timestamp <= DateTime.now().millisecondsSinceEpoch).length;
  String get rainbowFart => _rainbowFart;
  
  List<Plan> get ongoingPlans => _plans.where((p) => p.status != '已完成').toList();
  List<Plan> get completedPlans => _plans.where((p) => p.status == '已完成').toList();
  
  List<Habit> get activeHabits => _habits.where((h) => h.status != '已停用').toList();
  List<Habit> get stoppedHabits => _habits.where((h) => h.status == '已停用').toList();

  /// 统计今日完成的微行动总次数（今日完成的计划数 + 今日习惯打卡次数）
  int get todayActionCount {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

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
    return count;
  }

  HomeProvider() {
    _loadData();
    NotificationService().init().catchError((error, stackTrace) {
      debugPrint('Failed to initialize notification service: $error');
    });
  }

  Future<void> _loadData() async {
    _plans = await _storage.loadPlans();
    _habits = await _storage.loadHabits();
    _anchors = await _storage.loadAnchors();
    _notifications = await _storage.loadNotifications();
    _notificationsClearedBefore = await _storage.loadNotificationsClearedBefore();
    
    // Check for today's anchor notifications
    await _checkAnchorNotifications();

    // Reschedule all anchors to ensure they use the correct channel
    for (var anchor in _anchors) {
      _scheduleAnchorNotification(anchor);
    }
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

    notifyListeners();
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
            _scheduleAnchorNotification(anchor);
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
    if (index != -1) {
      reminderIdToDelete = _plans[index].reminderId;
      _plans.removeAt(index);
      await _storage.savePlans(_plans);
      notifyListeners();
    }

    // 若有关联的系统提醒事项，同步物理删除
    if (reminderIdToDelete != null && reminderIdToDelete.isNotEmpty) {
      final eco = AppleEcoService();
      final isTwoWay = await eco.isTwoWaySyncEnabled();
      if (isTwoWay && eco.isSupported) {
        eco.deletePlanReminder(reminderIdToDelete);
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

  /// 将单个锚点同步到 iOS「提醒事项」与「日历」
  Future<Map<String, dynamic>> syncAnchorToAppleEco(Anchor anchor) async {
    final items = getAnchorBoundItemNames(anchor);
    return AppleEcoService().syncAnchorToSystem(
      name: anchor.name,
      time: anchor.time,
      items: items,
    );
  }

  /// 一键将当前所有进行中计划与所有锚点批量同步到 iOS「提醒事项」与「日历」
  Future<Map<String, dynamic>> batchSyncToAppleEco() async {
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
            _scheduleAnchorNotification(anchor);
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
    _scheduleAnchorNotification(newAnchor);
    notifyListeners();
  }

  Future<void> updateAnchor(String id, String name, String time) async {
    final index = _anchors.indexWhere((a) => a.id == id);
    if (index != -1) {
      _anchors[index].name = name;
      _anchors[index].time = time;
      _anchors.sort((a, b) => a.time.compareTo(b.time));
      await _storage.saveAnchors(_anchors);
      _scheduleAnchorNotification(_anchors[index]);
      notifyListeners();
    }
  }

  Future<void> deleteAnchor(String id) async {
    final index = _anchors.indexWhere((a) => a.id == id);
    if (index != -1) {
      // Cancel notification using hashcode of ID as notification ID
      await NotificationService().cancelNotification(id.hashCode);
      _anchors.removeAt(index);
      await _storage.saveAnchors(_anchors);
      notifyListeners();
    }
  }

  Future<void> bindPlanToAnchor(String anchorId, String planId) async {
    final index = _anchors.indexWhere((a) => a.id == anchorId);
    if (index != -1) {
      if (!_anchors[index].planIds.contains(planId)) {
        _anchors[index].planIds.add(planId);
        await _storage.saveAnchors(_anchors);
        _scheduleAnchorNotification(_anchors[index]);
        notifyListeners();
      }
    }
  }

  Future<void> unbindPlanFromAnchor(String anchorId, String planId) async {
    final index = _anchors.indexWhere((a) => a.id == anchorId);
    if (index != -1) {
      _anchors[index].planIds.remove(planId);
      await _storage.saveAnchors(_anchors);
      _scheduleAnchorNotification(_anchors[index]);
      notifyListeners();
    }
  }

  Future<void> bindHabitToAnchor(String anchorId, String habitId) async {
    final index = _anchors.indexWhere((a) => a.id == anchorId);
    if (index != -1) {
      if (!_anchors[index].habitIds.contains(habitId)) {
        _anchors[index].habitIds.add(habitId);
        await _storage.saveAnchors(_anchors);
        _scheduleAnchorNotification(_anchors[index]);
        notifyListeners();
      }
    }
  }

  Future<void> unbindHabitFromAnchor(String anchorId, String habitId) async {
    final index = _anchors.indexWhere((a) => a.id == anchorId);
    if (index != -1) {
      _anchors[index].habitIds.remove(habitId);
      await _storage.saveAnchors(_anchors);
      _scheduleAnchorNotification(_anchors[index]);
      notifyListeners();
    }
  }

  Future<void> _scheduleAnchorNotification(Anchor anchor) async {
    final timeParts = anchor.time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    // Get linked items details
    final linkedPlans = _plans
        .where((p) => anchor.planIds.contains(p.id))
        .map((p) => p.name)
        .toList();
        
    final linkedHabits = _habits
        .where((h) => anchor.habitIds.contains(h.id))
        .map((h) => h.name)
        .toList();
    
    StringBuffer bodyBuffer = StringBuffer('该去行动了！');
    
    if (linkedPlans.isNotEmpty) {
      bodyBuffer.write('\n📝 计划: ${linkedPlans.join(", ")}');
    }
    
    if (linkedHabits.isNotEmpty) {
      bodyBuffer.write('\n🎯 习惯: ${linkedHabits.join(", ")}');
    }
    
    if (linkedPlans.isEmpty && linkedHabits.isEmpty) {
      bodyBuffer.write(' 别忘了检查你的任务清单！');
    }

    await NotificationService().scheduleNotification(
      id: anchor.id.hashCode,
      title: '锚点提醒: ${anchor.name}',
      body: bodyBuffer.toString(),
      time: TimeOfDay(hour: hour, minute: minute),
    );
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

      for (final anchor in _anchors) {
        _scheduleAnchorNotification(anchor);
      }

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

  Future<Map<String, dynamic>> getAnalysisData({int days = 30}) async {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));

    // Filter Plans
    final recentPlans = _plans.where((p) {
      // Keep plans created recently or completed recently (if we had completeTime)
      // Or just keep all active plans + recently created ones
      // For now, let's keep it simple: all active + recently created
      if (p.status != '已完成') return true;
      final createDate = DateTime.fromMillisecondsSinceEpoch(p.createTime);
      return createDate.isAfter(cutoff);
    }).map((p) => {
      'name': p.name,
      'status': p.status,
    }).toList();

    // Filter Habits
    final recentHabits = _habits.map((h) {
      // Count checks in last 30 days
      final recentChecks = h.completionHistory.where((timestamp) {
        final d = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return d.isAfter(cutoff);
      }).length;

      return {
        'name': h.name,
        'status': h.status,
        'check_count_30d': recentChecks,
        'total_checks': h.completionHistory.length,
      };
    }).toList();

    return {
      'period': 'Last $days days',
      'plans': recentPlans,
      'habits': recentHabits,
    };
  }

  // Analysis State
  final DeepSeekService _deepSeekService = DeepSeekService();
  Map<String, dynamic>? _analysisData;
  bool _isAnalyzing = false;
  static const String _analysisCacheKey = 'cached_analysis_result';

  Map<String, dynamic>? get analysisData => _analysisData;
  bool get isAnalyzing => _isAnalyzing;

  Future<void> loadCachedAnalysis() async {
    if (_analysisData != null) return;

    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString(_analysisCacheKey);

    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        _analysisData = jsonDecode(cachedJson);
        notifyListeners();
      } catch (e) {
        // Cache invalid
      }
    }
  }

  Future<void> startAnalysis({bool force = false}) async {
    if (_isAnalyzing) return;
    
    // If we have data and not forced, just ensure cache is loaded (already done by getter usually, but good to be safe)
    if (!force && _analysisData != null) return;

    // If no data, try load cache first
    if (!force && _analysisData == null) {
      await loadCachedAnalysis();
      if (_analysisData != null) return;
    }

    _isAnalyzing = true;
    notifyListeners();

    try {
      final data = await getAnalysisData();
      final result = await _deepSeekService.analyzeData(data);
      
      _analysisData = result;
      
      // Save cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_analysisCacheKey, jsonEncode(result));
    } catch (e) {
      debugPrint('Analysis failed: $e');
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  // Notification Methods
  /// 公开方法：检查锚点通知，供应用从后台恢复到前台时调用
  Future<void> checkAnchorNotifications() async {
    await _checkAnchorNotifications();
  }

  Future<void> _checkAnchorNotifications() async {
    final now = DateTime.now();
    bool changed = false;

    for (var anchor in _anchors) {
      final timeParts = anchor.time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final todayTrigger = DateTime(now.year, now.month, now.day, hour, minute);
      final todayTriggerTimestamp = todayTrigger.millisecondsSinceEpoch;
      
      // If trigger time has passed today
      if (now.isAfter(todayTrigger) &&
          shouldRestoreMissedNotification(
            triggerTimestamp: todayTriggerTimestamp,
            clearedBeforeTimestamp: _notificationsClearedBefore,
          )) {
          final notificationId = 'anchor_${anchor.id}_$todayTriggerTimestamp';
          
          // Check if we already have a notification for this anchor today (by ID)
          // This includes deleted notifications, so we don't re-generate them
          final hasNotification = _notifications.any((n) => n.id == notificationId);

          if (!hasNotification) {
            // Generate notification content
            final linkedPlans = _plans
                .where((p) => anchor.planIds.contains(p.id))
                .map((p) => p.name)
                .toList();
            final linkedHabits = _habits
                .where((h) => anchor.habitIds.contains(h.id))
                .map((h) => h.name)
                .toList();
            
            StringBuffer bodyBuffer = StringBuffer('该去行动了！');
            if (linkedPlans.isNotEmpty) bodyBuffer.write('\n📝 计划: ${linkedPlans.join(", ")}');
            if (linkedHabits.isNotEmpty) bodyBuffer.write('\n🎯 习惯: ${linkedHabits.join(", ")}');
            if (linkedPlans.isEmpty && linkedHabits.isEmpty) bodyBuffer.write(' 别忘了检查你的任务清单！');

            final newNotification = NotificationModel(
              id: notificationId,
              title: '锚点提醒: ${anchor.name}',
              body: bodyBuffer.toString(),
              timestamp: todayTriggerTimestamp,
              relatedId: anchor.id,
              type: 'anchor',
            );

          _notifications.insert(0, newNotification);
          changed = true;
        }
      }
    }

    if (changed) {
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      await _storage.saveNotifications(_notifications);
      notifyListeners();
    }
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
