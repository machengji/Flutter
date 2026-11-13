import 'dart:convert';
import 'dart:math' as math;
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
import '../../../../shared/models/celebration_model.dart';

class HomeProvider extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();
  final LeanCloudBackupService _cloudBackupService = LeanCloudBackupService();
  
  List<Plan> _plans = [];
  List<Habit> _habits = [];
  List<Anchor> _anchors = [];
  List<NotificationModel> _notifications = [];
  int _notificationsClearedBefore = 0;
  String _rainbowFart = '你今天闪闪发光！';
  String _coldJoke = '';

  List<ShineRecord> _shineRecords = [];
  List<String> _customAffirmations = [];
  String _celebrationStyleMode = CelebrationStyleMode.mixed;
  bool _celebrationSoundEnabled = true;
  int _celebrationEventSeq = 0;
  final math.Random _quoteRandom = math.Random();
  String _lastPickedQuote = '';

  /// 供界面层实时监听并展示轻庆祝胶囊或全屏高光庆祝仪式
  final ValueNotifier<CelebrationPayload?> celebrationNotifier =
      ValueNotifier<CelebrationPayload?>(null);
  
  List<Plan>? _cachedOngoingPlans;
  List<Plan>? _cachedCompletedPlans;
  List<Plan>? _cachedArchivedPlans;
  List<Habit>? _cachedActiveHabits;
  List<Habit>? _cachedStoppedHabits;
  int? _cachedTodayActionCount;
  int? _cachedTodayShineCount;
  int _cachedStartOfToday = 0;
  int _cachedShineStartOfToday = 0;

  void _invalidateDerivedCaches() {
    _cachedOngoingPlans = null;
    _cachedCompletedPlans = null;
    _cachedArchivedPlans = null;
    _cachedActiveHabits = null;
    _cachedStoppedHabits = null;
    _cachedTodayActionCount = null;
    _cachedTodayShineCount = null;
  }

  @override
  void notifyListeners() {
    _invalidateDerivedCaches();
    super.notifyListeners();
  }

  @override
  void dispose() {
    celebrationNotifier.dispose();
    super.dispose();
  }

  List<Plan> get plans => _plans;
  List<Habit> get habits => _habits;
  List<Anchor> get anchors => _anchors;
  List<NotificationModel> get notifications => _notifications.where((n) => !n.isDeleted).toList();
  int get unreadNotificationCount => _notifications.where((n) => !n.isDeleted && !n.isRead && n.timestamp <= DateTime.now().millisecondsSinceEpoch).length;
  String get rainbowFart => _rainbowFart;
  String get coldJoke => _coldJoke;

  List<ShineRecord> get shineRecords => List.unmodifiable(_shineRecords);
  int get totalShineCount => _shineRecords.length;
  List<String> get customAffirmations => List.unmodifiable(_customAffirmations);
  String get celebrationStyleMode => _celebrationStyleMode;
  bool get celebrationSoundEnabled => _celebrationSoundEnabled;
  
  List<Plan> get ongoingPlans => _cachedOngoingPlans ??= _buildSortedOngoingPlans();
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

  /// 统计今日为自己庆祝（发光星籽）的次数
  int get todayShineCount {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    if (_cachedTodayShineCount != null && _cachedShineStartOfToday == startOfToday) {
      return _cachedTodayShineCount!;
    }

    int count = 0;
    for (final record in _shineRecords) {
      if (record.timestamp >= startOfToday) {
        count++;
      }
    }
    _cachedShineStartOfToday = startOfToday;
    _cachedTodayShineCount = count;
    return count;
  }

  bool _isDataLoaded = false;
  bool get isDataLoaded => _isDataLoaded;

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
      _storage.loadShineRecords(),
      _storage.loadCustomAffirmations(),
      _storage.loadCelebrationStyleMode(),
      _storage.loadCelebrationSoundEnabled(),
    ]);
    if (_plans.isEmpty) _plans = results[0] as List<Plan>;
    if (_habits.isEmpty) _habits = results[1] as List<Habit>;
    if (_anchors.isEmpty) _anchors = results[2] as List<Anchor>;
    if (_notifications.isEmpty) {
      _notifications = results[3] as List<NotificationModel>;
    }
    if (_notificationsClearedBefore == 0) {
      _notificationsClearedBefore = results[4] as int;
    }

    final loadedShines = results[5] as List<ShineRecord>;
    if (_shineRecords.isEmpty) {
      _shineRecords = loadedShines;
    } else if (loadedShines.isNotEmpty) {
      final existingIds = _shineRecords.map((r) => r.id).toSet();
      for (final item in loadedShines) {
        if (!existingIds.contains(item.id)) {
          _shineRecords.add(item);
        }
      }
    }

    final loadedAffirmations = results[6] as List<String>;
    if (_customAffirmations.isEmpty) {
      _customAffirmations = loadedAffirmations;
    } else if (loadedAffirmations.isNotEmpty) {
      for (final item in loadedAffirmations) {
        if (!_customAffirmations.contains(item)) {
          _customAffirmations.add(item);
        }
      }
    }

    _celebrationStyleMode = results[7] as String;
    _celebrationSoundEnabled = results[8] as bool;
    _isDataLoaded = true;

    // 首屏数据加载完毕后立即通知 UI 渲染
    notifyListeners();

    // 自动对齐所有时间锚点的系统级定时通知（App 关闭后仍由 iOS 系统按周期触发），并清理旧版「微行动锚点」日历残留
    refreshAnchorNotifications(requestPermissionIfNeeded: false);
    AppleEcoService().cleanupLegacyAnchorSystemData();

    _loadRainbowFart(); // Load in background
    _loadColdJoke();

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

  Future<void> _loadColdJoke() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedJoke = prefs.getString('lastColdJoke');
    if (cachedJoke != null && cachedJoke.isNotEmpty) {
      _coldJoke = cachedJoke;
      notifyListeners();
    } else {
      refreshColdJoke();
    }
  }

  Future<void> refreshColdJoke() async {
    try {
      final response =
          await http.get(Uri.parse('https://60s.viki.moe/v2/dad-joke'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['code'] == 200 && data['data'] is Map) {
          final content = data['data']['content'];
          if (content != null && content is String && content.trim().isNotEmpty) {
            _coldJoke = content.trim();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('lastColdJoke', _coldJoke);
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch cold joke: $e');
    }
  }

  // ==================== 发光庆祝体系（Shine Celebration） ====================

  Future<void> setCelebrationStyleMode(String mode) async {
    final normalized = CelebrationStyleMode.normalize(mode);
    if (_celebrationStyleMode == normalized) return;
    _celebrationStyleMode = normalized;
    await _storage.saveCelebrationStyleMode(normalized);
    notifyListeners();
  }

  Future<void> setCelebrationSoundEnabled(bool enabled) async {
    if (_celebrationSoundEnabled == enabled) return;
    _celebrationSoundEnabled = enabled;
    await _storage.saveCelebrationSoundEnabled(enabled);
    notifyListeners();
  }

  Future<void> addCustomAffirmation(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _customAffirmations.remove(trimmed);
    _customAffirmations.insert(0, trimmed);
    await _storage.saveCustomAffirmations(_customAffirmations);
    notifyListeners();
  }

  Future<void> removeCustomAffirmation(String text) async {
    final removed = _customAffirmations.remove(text);
    if (!removed) return;
    await _storage.saveCustomAffirmations(_customAffirmations);
    notifyListeners();
  }

  String _pickRandomFromPool(List<String> pool) {
    if (pool.isEmpty) return '';
    if (pool.length == 1) {
      _lastPickedQuote = pool.first;
      return pool.first;
    }
    String picked = pool[_quoteRandom.nextInt(pool.length)];
    if (picked == _lastPickedQuote) {
      final alternatives = pool.where((item) => item != _lastPickedQuote).toList();
      if (alternatives.isNotEmpty) {
        picked = alternatives[_quoteRandom.nextInt(alternatives.length)];
      }
    }
    _lastPickedQuote = picked;
    return picked;
  }

  /// 根据当前庆祝风格模式，以彩虹屁为主，穿插冷笑话、真诚肯定语与自定义庆祝语按比例抽取文案
  String _pickNextCelebrationQuote() {
    final rainbowPool = <String>[
      if (_rainbowFart.trim().isNotEmpty) _rainbowFart.trim(),
      ...CelebrationLibrary.playfulQuotes,
    ];
    final coldJokePool = <String>[
      if (_coldJoke.trim().isNotEmpty) _coldJoke.trim(),
      ...CelebrationLibrary.coldJokes,
    ];
    const sincerePool = CelebrationLibrary.sincereAffirmations;

    if (_celebrationStyleMode == CelebrationStyleMode.sincere) {
      if (_customAffirmations.isNotEmpty && _quoteRandom.nextDouble() < 0.35) {
        return _pickRandomFromPool(_customAffirmations);
      }
      return _pickRandomFromPool(sincerePool);
    }

    if (_celebrationStyleMode == CelebrationStyleMode.playful) {
      final roll = _quoteRandom.nextDouble();
      if (_customAffirmations.isNotEmpty) {
        if (roll < 0.10) {
          return _pickRandomFromPool(_customAffirmations);
        } else if (roll < 0.32) {
          refreshColdJoke();
          return _pickRandomFromPool(coldJokePool);
        } else {
          refreshRainbowFart();
          return _pickRandomFromPool(rainbowPool);
        }
      } else {
        if (roll < 0.25) {
          refreshColdJoke();
          return _pickRandomFromPool(coldJokePool);
        } else {
          refreshRainbowFart();
          return _pickRandomFromPool(rainbowPool);
        }
      }
    }

    // mixed 混合模式：主要以彩虹屁为主，穿插冷笑话、真诚肯定语与自定义庆祝语
    final roll = _quoteRandom.nextDouble();
    if (_customAffirmations.isNotEmpty) {
      if (roll < 0.15) {
        return _pickRandomFromPool(_customAffirmations);
      } else if (roll < 0.25) {
        return _pickRandomFromPool(sincerePool);
      } else if (roll < 0.45) {
        refreshColdJoke();
        return _pickRandomFromPool(coldJokePool);
      } else {
        refreshRainbowFart();
        return _pickRandomFromPool(rainbowPool);
      }
    } else {
      if (roll < 0.10) {
        return _pickRandomFromPool(sincerePool);
      } else if (roll < 0.32) {
        refreshColdJoke();
        return _pickRandomFromPool(coldJokePool);
      } else {
        refreshRainbowFart();
        return _pickRandomFromPool(rainbowPool);
      }
    }
  }

  String _pickNextMicroActionPrompt() {
    const prompts = CelebrationLibrary.microActionPrompts;
    return prompts[_quoteRandom.nextInt(prompts.length)];
  }

  Set<String> _snapshotAnchorsWithRemainingToday() {
    final ids = <String>{};
    for (final anchor in _anchors) {
      if (getAnchorTodayRemainingItemNames(anchor).isNotEmpty) {
        ids.add(anchor.id);
      }
    }
    return ids;
  }

  bool _didClearAnyAnchorToday(Set<String> beforePendingIds) {
    if (beforePendingIds.isEmpty) return false;
    for (final anchor in _anchors) {
      if (beforePendingIds.contains(anchor.id) &&
          getAnchorTodayRemainingItemNames(anchor).isEmpty) {
        return true;
      }
    }
    return false;
  }

  Future<CelebrationPayload> _recordAndEmitCelebration({
    required String actionTitle,
    required bool isGrand,
    String? milestoneTag,
    String? prePickedQuote,
    bool emitToHomeOverlay = true,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    _celebrationEventSeq++;
    final quote = prePickedQuote ?? _pickNextCelebrationQuote();
    final microPrompt = _pickNextMicroActionPrompt();

    final record = ShineRecord(
      id: '${nowMs}_$_celebrationEventSeq',
      timestamp: nowMs,
      title: actionTitle,
      isGrand: isGrand,
      colorSeed: _shineRecords.length % 6,
    );
    _shineRecords.insert(0, record);
    await _storage.saveShineRecords(_shineRecords);

    final payload = CelebrationPayload(
      eventId: _celebrationEventSeq,
      actionTitle: actionTitle,
      quote: quote,
      microActionPrompt: microPrompt,
      isGrand: isGrand,
      milestoneTag: milestoneTag,
    );

    AppleEcoService().playCelebrationCue(
      kind: isGrand ? 'grand' : 'light',
      soundEnabled: _celebrationSoundEnabled,
    );

    if (emitToHomeOverlay) {
      celebrationNotifier.value = payload;
    }
    notifyListeners();
    return payload;
  }

  /// 在「发光星籽罐」中随时主动练习为自己庆祝一次（攒下一颗新星籽并触发和弦震感）
  Future<CelebrationPayload> celebrateFreely({
    String title = '为自己鼓掌',
  }) async {
    return _recordAndEmitCelebration(
      actionTitle: title,
      isGrand: true,
      milestoneTag: '夸夸自己',
      emitToHomeOverlay: false,
    );
  }

  /// 播放庆祝蓄力或绽放感官微反馈（遵循当前治愈微音效开关设置）
  Future<void> triggerCelebrationSensory({
    required String kind,
    double progress = 0.5,
  }) async {
    await AppleEcoService().playCelebrationCue(
      kind: kind,
      soundEnabled: _celebrationSoundEnabled,
      progress: progress,
    );
  }

  int _idSequence = 0;

  String _generateUniquePlanId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    var candidate = now.toString();
    while (_plans.any((p) => p.id == candidate)) {
      _idSequence++;
      candidate = '${now}_$_idSequence';
    }
    return candidate;
  }

  /// 获取指定计划的直接父计划（若为顶层计划或父计划不存在则返回 null）
  Plan? getParentPlan(Plan plan) {
    final pid = plan.parentId;
    if (pid == null || pid.isEmpty || pid == plan.id) return null;
    for (final candidate in _plans) {
      if (candidate.id == pid) {
        return candidate;
      }
    }
    return null;
  }

  /// 计算计划在当前有效父子链上的真实分解层级（0=顶层，1=子任务，2=孙任务...，自带防环保护）
  int getEffectiveDecompositionDepth(Plan plan) {
    int depth = 0;
    final visited = <String>{plan.id};
    Plan? current = plan;
    while (current != null) {
      final parent = getParentPlan(current);
      if (parent == null || visited.contains(parent.id)) {
        break;
      }
      visited.add(parent.id);
      depth++;
      current = parent;
    }
    return depth;
  }

  /// 获取某个计划下的直接子任务列表（未完成排在前，已完成排在后，同状态保持录入顺序）
  List<Plan> getDirectSubPlans(String parentId) {
    if (parentId.isEmpty) return const [];
    final pending = <Plan>[];
    final done = <Plan>[];
    for (final p in _plans) {
      if (p.parentId == parentId) {
        if (p.status == '已完成') {
          done.add(p);
        } else {
          pending.add(p);
        }
      }
    }
    return [...pending, ...done];
  }

  /// 获取某个计划直接子任务的完成进度（completed / total）
  ({int completed, int total}) getSubPlanProgress(String parentId) {
    if (parentId.isEmpty) return (completed: 0, total: 0);
    int total = 0;
    int completed = 0;
    for (final p in _plans) {
      if (p.parentId == parentId) {
        total++;
        if (p.status == '已完成') {
          completed++;
        }
      }
    }
    return (completed: completed, total: total);
  }

  /// 收集某个计划下的所有后代子任务 ID（支持无限多级嵌套，带防环保护）
  Set<String> getDescendantIds(String rootId) {
    final descendants = <String>{};
    if (rootId.isEmpty) return descendants;
    final queue = <String>[rootId];
    final visited = <String>{rootId};

    while (queue.isNotEmpty) {
      final currentId = queue.removeAt(0);
      for (final p in _plans) {
        if (p.parentId == currentId && !visited.contains(p.id)) {
          visited.add(p.id);
          descendants.add(p.id);
          queue.add(p.id);
        }
      }
    }
    return descendants;
  }

  /// 判断某个计划下是否仍存在未完成（且未归档）的后代子任务
  bool hasIncompleteDescendants(String planId) {
    final descendantIds = getDescendantIds(planId);
    if (descendantIds.isEmpty) return false;
    for (final p in _plans) {
      if (descendantIds.contains(p.id) &&
          p.status != '已完成' &&
          p.status != '已归档') {
        return true;
      }
    }
    return false;
  }

  /// 构建按可执行优先级自动排序的进行中计划列表：
  /// 0. 最底层未完成叶子子任务（无未完成下级，且层级越深越靠前）
  /// 1. 下属子任务已全部完成的顶层父任务（浮回前方等待确认收尾）
  /// 2. 普通未拆解顶层计划
  /// 3. 下属仍有未完成子任务的父任务/中间父任务（自动退后并显示进度）
  List<Plan> _buildSortedOngoingPlans() {
    final activeList = _plans
        .where((p) => p.status != '已完成' && p.status != '已归档')
        .toList();
    if (activeList.length <= 1) return activeList;

    final originalOrder = <String, int>{};
    final depths = <String, int>{};
    final buckets = <String, int>{};

    for (var i = 0; i < activeList.length; i++) {
      final p = activeList[i];
      originalOrder[p.id] = i;
      final depth = getEffectiveDecompositionDepth(p);
      depths[p.id] = depth;
      final hasPendingChildren = hasIncompleteDescendants(p.id);

      if (hasPendingChildren) {
        buckets[p.id] = 3;
      } else if (depth > 0) {
        buckets[p.id] = 0;
      } else {
        final progress = getSubPlanProgress(p.id);
        buckets[p.id] = progress.total > 0 ? 1 : 2;
      }
    }

    activeList.sort((a, b) {
      final bucketCmp = buckets[a.id]!.compareTo(buckets[b.id]!);
      if (bucketCmp != 0) return bucketCmp;

      // 在叶子子任务层（Bucket 0）与推进中父任务层（Bucket 3），分解层级越深越靠前
      final bucket = buckets[a.id]!;
      if (bucket == 0 || bucket == 3) {
        final depthCmp = depths[b.id]!.compareTo(depths[a.id]!);
        if (depthCmp != 0) return depthCmp;
      }

      return originalOrder[a.id]!.compareTo(originalOrder[b.id]!);
    });

    return activeList;
  }

  // Plan Methods
  Future<void> addPlan(
    String name, {
    String? parentId,
    int decompositionLevel = 0,
    int groupColorIndex = -1,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    if (parentId != null && parentId.isNotEmpty) {
      await addSubPlan(
        parentId,
        trimmed,
        explicitGroupColorIndex: groupColorIndex >= 0 ? groupColorIndex : null,
      );
      return;
    }

    final newPlan = Plan(
      id: _generateUniquePlanId(),
      name: trimmed,
      createTime: DateTime.now().millisecondsSinceEpoch,
      parentId: null,
      decompositionLevel: decompositionLevel,
      groupColorIndex: groupColorIndex,
    );
    _plans.insert(0, newPlan);
    await _storage.savePlans(_plans);
    notifyListeners();

    // 实时同步到 iOS 提醒事项
    _syncSinglePlanToReminders(newPlan);
  }

  /// 在指定父任务下快速创建子任务（支持无限多级向下分解，同批子任务保持录入正序）
  Future<Plan?> addSubPlan(
    String parentId,
    String name, {
    int? explicitGroupColorIndex,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final parentIndex = _plans.indexWhere((p) => p.id == parentId);
    if (parentIndex == -1) return null;

    final parent = _plans[parentIndex];
    final resolvedColorIndex = explicitGroupColorIndex ??
        (parent.groupColorIndex >= 0
            ? parent.groupColorIndex
            : getNextGroupColorIndex());
    if (parent.groupColorIndex < 0) {
      parent.groupColorIndex = resolvedColorIndex;
    }

    final childDepth = getEffectiveDecompositionDepth(parent) + 1;
    final newSubPlan = Plan(
      id: _generateUniquePlanId(),
      name: trimmed,
      createTime: DateTime.now().millisecondsSinceEpoch,
      parentId: parent.id,
      decompositionLevel: childDepth,
      groupColorIndex: resolvedColorIndex,
    );

    // 若已存在同父级的未完成兄弟子任务，紧跟在最后一个未完成兄弟之后，保持拆解步骤正序
    int lastSiblingIndex = -1;
    for (var i = 0; i < _plans.length; i++) {
      final item = _plans[i];
      if (item.parentId == parent.id &&
          item.status != '已完成' &&
          item.status != '已归档') {
        lastSiblingIndex = i;
      }
    }
    if (lastSiblingIndex >= 0) {
      _plans.insert(lastSiblingIndex + 1, newSubPlan);
    } else {
      _plans.insert(0, newSubPlan);
    }

    await _storage.savePlans(_plans);
    notifyListeners();

    _syncSinglePlanToReminders(newSubPlan);
    return newSubPlan;
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
      final oldName = _plans[index].name;
      _plans[index].name = newName;
      await _storage.savePlans(_plans);
      notifyListeners();

      // 实时同步更新到 iOS 提醒事项
      _syncSinglePlanToReminders(_plans[index]);

      if (oldName != newName && _anchors.any((a) => a.planIds.contains(id))) {
        refreshAnchorNotifications();
      }
    }
  }

  Future<void> togglePlanStatus(String id) async {
    final index = _plans.indexWhere((p) => p.id == id);
    if (index != -1) {
      final plan = _plans[index];
      final cascadedPlans = <Plan>[];

      if (plan.status == '已完成') {
        final prevCompleteTime = plan.completeTime;
        plan.status = '未开始';
        plan.completeTime = null;
        // 取消完成时，同步从「微行动」日历中撤回对应的完成记录
        AppleEcoService().deleteFootprintEvents(
          title: plan.name,
          targetDayEpochMs: prevCompleteTime,
        );
        await _storage.savePlans(_plans);
        notifyListeners();
      } else {
        final wasFirstToday = todayActionCount == 0 && todayShineCount == 0;
        final hasSubPlans = getSubPlanProgress(id).total > 0;
        final beforePendingAnchors = _snapshotAnchorsWithRemainingToday();

        final nowMs = DateTime.now().millisecondsSinceEpoch;
        plan.status = '已完成';
        plan.completeTime = nowMs;

        // 级联完成其下所有未完成后代子任务（日历仅记录当前点击任务本身 1 条，防刷屏）
        final descendantIds = getDescendantIds(id);
        for (final p in _plans) {
          if (descendantIds.contains(p.id) && p.status != '已完成') {
            p.status = '已完成';
            p.completeTime = nowMs;
            cascadedPlans.add(p);
          }
        }

        final pickedQuote = _pickNextCelebrationQuote();
        final parent = getParentPlan(plan);
        final footprintNotes = parent != null
            ? '所属目标：${parent.name}\n微行动计划达成\n$pickedQuote'
            : '微行动计划达成\n$pickedQuote';

        AppleEcoService().recordActionFootprintIfNeeded(
          title: plan.name,
          category: 'plan',
          notes: footprintNotes,
          completeTimeEpochMs: plan.completeTime,
          mergeOnSameDay: true,
        );

        // 完成的计划（含被级联完成的后代子任务）自动从锚点待办解绑
        final completedIds = <String>{id, ...cascadedPlans.map((e) => e.id)};
        bool anchorsChanged = false;
        for (var anchor in _anchors) {
          final beforeLen = anchor.planIds.length;
          anchor.planIds.removeWhere((pid) => completedIds.contains(pid));
          if (anchor.planIds.length != beforeLen) {
            anchorsChanged = true;
          }
        }
        if (anchorsChanged) {
          await _storage.saveAnchors(_anchors);
        }

        await _storage.savePlans(_plans);

        final clearedAnchor = _didClearAnyAnchorToday(beforePendingAnchors);
        String? milestoneTag;
        if (hasSubPlans) {
          milestoneTag = '目标达成';
        } else if (clearedAnchor) {
          milestoneTag = '锚点全清';
        } else if (wasFirstToday) {
          milestoneTag = '今日首胜';
        }

        await _recordAndEmitCelebration(
          actionTitle: plan.name,
          isGrand: milestoneTag != null,
          milestoneTag: milestoneTag,
          prePickedQuote: pickedQuote,
        );
      }

      // 刷新锚点定时通知与 iOS 提醒事项状态
      refreshAnchorNotifications();
      _syncSinglePlanToReminders(plan);
      for (final sub in cascadedPlans) {
        _syncSinglePlanToReminders(sub);
      }
    }
  }

  Future<void> deletePlan(String id) async {
    final index = _plans.indexWhere((p) => p.id == id);
    if (index == -1) return;

    // 级联收集当前计划及其所有后代子任务一并清理，不留孤儿任务
    final idsToDelete = <String>{id, ...getDescendantIds(id)};
    final deletedPlans = _plans.where((p) => idsToDelete.contains(p.id)).toList();

    _plans.removeWhere((p) => idsToDelete.contains(p.id));
    await _storage.savePlans(_plans);

    bool anchorsChanged = false;
    for (var anchor in _anchors) {
      final beforeLen = anchor.planIds.length;
      anchor.planIds.removeWhere((pid) => idsToDelete.contains(pid));
      if (anchor.planIds.length != beforeLen) {
        anchorsChanged = true;
      }
    }
    if (anchorsChanged) {
      await _storage.saveAnchors(_anchors);
      refreshAnchorNotifications();
    }

    notifyListeners();

    // 同步从系统提醒事项和「微行动」日历中物理删除
    final eco = AppleEcoService();
    if (eco.isSupported) {
      for (final removed in deletedPlans) {
        if (removed.name.isNotEmpty) {
          eco.deletePlanFromSystem(
            title: removed.name,
            reminderId: removed.reminderId,
            alsoDeleteCalendarEvents: true,
          );
        }
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
      if (_anchors.any((a) => a.planIds.contains(id))) {
        refreshAnchorNotifications();
      }
    }
  }

  /// 移出归档，恢复为进行中重点
  Future<void> unarchivePlan(String id) async {
    final index = _plans.indexWhere((p) => p.id == id);
    if (index != -1) {
      _plans[index].status = '进行中';
      await _storage.savePlans(_plans);
      notifyListeners();
      if (_anchors.any((a) => a.planIds.contains(id))) {
        refreshAnchorNotifications();
      }
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
      if (_anchors.any((a) => a.planIds.contains(id))) {
        refreshAnchorNotifications();
      }
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
      final oldName = _habits[index].name;
      _habits[index].name = newName;
      await _storage.saveHabits(_habits);
      notifyListeners();

      if (oldName != newName && _anchors.any((a) => a.habitIds.contains(id))) {
        refreshAnchorNotifications();
      }
    }
  }

  /// 获取某个习惯今日已打卡的次数
  int getHabitTodayCheckCount(Habit habit) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    int count = 0;
    for (final ts in habit.completionHistory) {
      if (ts >= startOfToday) {
        count++;
      }
    }
    return count;
  }

  bool isHabitCheckedToday(Habit habit) => getHabitTodayCheckCount(habit) > 0;

  Future<void> checkHabit(String id) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      final wasFirstToday = todayActionCount == 0 && todayShineCount == 0;
      final beforePendingAnchors = _snapshotAnchorsWithRemainingToday();

      final habit = _habits[index];
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      habit.totalDays++;
      habit.completionHistory.add(nowMs);
      await _storage.saveHabits(_habits);

      final pickedQuote = _pickNextCelebrationQuote();
      final todayCount = getHabitTodayCheckCount(habit);
      AppleEcoService().recordActionFootprintIfNeeded(
        title: habit.name,
        category: 'habit',
        notes: '今日第 $todayCount 次打卡 · 累计打卡 ${habit.totalDays} 次\n$pickedQuote',
        completeTimeEpochMs: nowMs,
        mergeOnSameDay: true,
      );

      final clearedAnchor = _didClearAnyAnchorToday(beforePendingAnchors);
      String? milestoneTag;
      if (clearedAnchor) {
        milestoneTag = '锚点全清';
      } else if (wasFirstToday) {
        milestoneTag = '今日首胜';
      }

      await _recordAndEmitCelebration(
        actionTitle: habit.name,
        isGrand: milestoneTag != null,
        milestoneTag: milestoneTag,
        prePickedQuote: pickedQuote,
      );

      // 打卡后立即动态刷新锚点通知：今日已打卡的习惯从今日待办中过滤（若全完成则今日静默跳过）
      if (_anchors.any((a) => a.habitIds.contains(id))) {
        refreshAnchorNotifications();
      }
    }
  }

  /// 获取某个锚点在未来新一天的完整基准待办清单（未完成计划 + 进行中习惯）
  List<String> getAnchorBaselineItemNames(Anchor anchor) {
    final List<String> names = [];
    for (final pid in anchor.planIds) {
      final idx = _plans.indexWhere((p) => p.id == pid);
      if (idx != -1) {
        final plan = _plans[idx];
        if (plan.status != '已完成' && plan.status != '已归档') {
          names.add('[计划] ${plan.name}');
        }
      }
    }
    for (final hid in anchor.habitIds) {
      final idx = _habits.indexWhere((h) => h.id == hid);
      if (idx != -1) {
        final habit = _habits[idx];
        if (habit.status != '已停用') {
          names.add('[习惯] ${habit.name}');
        }
      }
    }
    return names;
  }

  /// 获取某个锚点在今日此刻剩余尚未完成的待办清单（未完成计划 + 今日尚未打卡的进行中习惯）
  List<String> getAnchorTodayRemainingItemNames(Anchor anchor) {
    final List<String> names = [];
    for (final pid in anchor.planIds) {
      final idx = _plans.indexWhere((p) => p.id == pid);
      if (idx != -1) {
        final plan = _plans[idx];
        if (plan.status != '已完成' && plan.status != '已归档') {
          names.add('[计划] ${plan.name}');
        }
      }
    }
    for (final hid in anchor.habitIds) {
      final idx = _habits.indexWhere((h) => h.id == hid);
      if (idx != -1) {
        final habit = _habits[idx];
        if (habit.status != '已停用' && !isHabitCheckedToday(habit)) {
          names.add('[习惯] ${habit.name}');
        }
      }
    }
    return names;
  }

  /// 判断某个锚点是否绑定了任何有效存在的计划或习惯
  bool _hasValidBoundItems(Anchor anchor) {
    for (final pid in anchor.planIds) {
      final idx = _plans.indexWhere((p) => p.id == pid);
      if (idx != -1 && _plans[idx].status != '已完成' && _plans[idx].status != '已归档') {
        return true;
      }
    }
    for (final hid in anchor.habitIds) {
      final idx = _habits.indexWhere((h) => h.id == hid);
      if (idx != -1 && _habits[idx].status != '已停用') {
        return true;
      }
    }
    return false;
  }

  /// 同步刷新所有时间锚点的系统级本地定时通知（App 彻底关闭后仍由系统准点提醒）
  Future<Map<String, dynamic>> refreshAnchorNotifications({
    bool requestPermissionIfNeeded = false,
  }) async {
    final eco = AppleEcoService();
    if (eco.isSupported) {
      final payloads = _anchors.map((a) {
        return {
          'id': a.id,
          'name': a.name,
          'time': a.time,
          'isReminderEnabled': a.isReminderEnabled,
          'effectiveDays': a.effectiveDays,
          'hasBoundItems': _hasValidBoundItems(a),
          'baselineItems': getAnchorBaselineItemNames(a),
          'todayRemainingItems': getAnchorTodayRemainingItemNames(a),
        };
      }).toList();
      return eco.syncAnchorNotifications(
        anchors: payloads,
        requestPermissionIfNeeded: requestPermissionIfNeeded,
      );
    }

    // 非 iOS 平台（如 Android）本地通知调度
    try {
      await NotificationService().cancelAllNotifications();
      for (final a in _anchors) {
        if (!a.isReminderEnabled) continue;
        final hasBound = _hasValidBoundItems(a);
        final todayItems = getAnchorTodayRemainingItemNames(a);
        if (hasBound && todayItems.isEmpty) continue;
        final parts = a.time.split(':');
        final hour = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 8) : 8;
        final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
        final body = hasBound ? todayItems.join(' · ') : '设定的锚点时间（${a.time}）到了';
        await NotificationService().scheduleNotification(
          id: a.id.hashCode,
          title: a.name,
          body: body,
          time: TimeOfDay(hour: hour, minute: minute),
        );
      }
    } catch (e) {
      debugPrint('Non-iOS anchor notification sync skipped: $e');
    }
    return {'success': true};
  }

  /// 一键将当前所有进行中计划批量同步到 iOS「微行动」提醒事项列表
  Future<Map<String, dynamic>> batchSyncToAppleEco() async {
    final planPayloads = ongoingPlans
        .map((p) => {
              'id': p.id,
              'name': p.name,
            })
        .toList();
    return AppleEcoService().batchSyncAll(
      plans: planPayloads,
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
      final Set<String> sysCompletedIds = {};
      final Set<String> sysDeletedIds = {};

      for (var plan in _plans) {
        // 如果该计划已经绑定了系统 reminderId
        if (plan.reminderId != null && plan.reminderId!.isNotEmpty) {
          final sysItem = sysMapById[plan.reminderId];
          if (sysItem != null) {
            // 系统端存在该提醒事项
            final isSysCompleted = sysItem['isCompleted'] == true;
            if (isSysCompleted && plan.status != '已完成') {
              // 状态反向同步：系统端打勾完成 -> App 端标记完成并写入「微行动」日历
              plan.status = '已完成';
              plan.completeTime = (sysItem['completionDateEpochMs'] as int?) ?? DateTime.now().millisecondsSinceEpoch;
              final parent = getParentPlan(plan);
              final notes = parent != null
                  ? '所属目标：${parent.name}\n通过 iOS 提醒事项完成计划'
                  : '通过 iOS 提醒事项完成计划';
              eco.recordActionFootprintIfNeeded(
                title: plan.name,
                category: 'plan',
                notes: notes,
                completeTimeEpochMs: plan.completeTime,
                mergeOnSameDay: true,
              );
              for (final anchor in _anchors) {
                anchor.planIds.remove(plan.id);
              }
              sysCompletedIds.add(plan.id);
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
            for (final anchor in _anchors) {
              anchor.planIds.remove(plan.id);
            }
            sysDeletedIds.add(plan.id);
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
              final parent = getParentPlan(plan);
              final notes = parent != null
                  ? '所属目标：${parent.name}\n通过 iOS 提醒事项完成计划'
                  : '通过 iOS 提醒事项完成计划';
              eco.recordActionFootprintIfNeeded(
                title: plan.name,
                category: 'plan',
                notes: notes,
                completeTimeEpochMs: plan.completeTime,
                mergeOnSameDay: true,
              );
              for (final anchor in _anchors) {
                anchor.planIds.remove(plan.id);
              }
              sysCompletedIds.add(plan.id);
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

      // 1b. 若系统端删除了父任务，级联移除其所有后代子任务，避免孤儿子任务
      if (sysDeletedIds.isNotEmpty) {
        final cascadeDeleteIds = <String>{};
        for (final delId in sysDeletedIds) {
          cascadeDeleteIds.addAll(getDescendantIds(delId));
        }
        cascadeDeleteIds.removeAll(sysDeletedIds);
        if (cascadeDeleteIds.isNotEmpty) {
          final orphanPlans = plansToKeep
              .where((p) => cascadeDeleteIds.contains(p.id))
              .toList();
          plansToKeep.removeWhere((p) => cascadeDeleteIds.contains(p.id));
          for (final orphan in orphanPlans) {
            for (final anchor in _anchors) {
              anchor.planIds.remove(orphan.id);
            }
            if (orphan.name.isNotEmpty) {
              await eco.deletePlanFromSystem(
                title: orphan.name,
                reminderId: orphan.reminderId,
                alsoDeleteCalendarEvents: true,
              );
            }
            deletedCount++;
          }
          hasChanges = true;
        }
      }

      // 1c. 若系统端勾选完成了父任务，级联将其未完成后代同步设为已完成（日历仅记父任务1条）
      if (sysCompletedIds.isNotEmpty) {
        final cascadeCompleteIds = <String>{};
        for (final compId in sysCompletedIds) {
          cascadeCompleteIds.addAll(getDescendantIds(compId));
        }
        cascadeCompleteIds.removeAll(sysCompletedIds);
        if (cascadeCompleteIds.isNotEmpty) {
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          for (final p in plansToKeep) {
            if (cascadeCompleteIds.contains(p.id) && p.status != '已完成') {
              p.status = '已完成';
              p.completeTime = nowMs;
              for (final anchor in _anchors) {
                anchor.planIds.remove(p.id);
              }
              await eco.syncPlanToReminder(
                title: p.name,
                status: p.status,
                reminderId: p.reminderId,
              );
              hasChanges = true;
            }
          }
        }
      }

      _plans = plansToKeep;

      // 2. 检测系统端外部新增的提醒事项（例如通过 Siri 录入） -> 反向导入到 App
      final knownReminderIds = _plans.map((p) => p.reminderId).whereType<String>().toSet();
      final knownTitles = _plans.map((p) => p.name).toSet();
      final knownAnchorTitles = _anchors.map((a) => a.name).toSet();

      for (var sysItem in sysReminders) {
        final rId = sysItem['reminderId'] as String;
        final title = sysItem['title'] as String;
        final notes = sysItem['notes'] as String? ?? '';
        if (title.isEmpty) continue;

        // 跳过属于历史「时间锚点」的提醒事项，防止锚点被误导入为普通计划
        if (title.contains('[微行动锚点]') ||
            notes.contains('[微行动锚点]') ||
            notes.contains('关联微行动清单') ||
            knownAnchorTitles.contains(title)) {
          continue;
        }

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
        await _storage.saveAnchors(_anchors);
        refreshAnchorNotifications();
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

  /// 将本地所有具备真实完成时间的「已完成计划 + 习惯打卡历史记录」批量补录至 iOS 系统「微行动」专属日历分组
  Future<Map<String, dynamic>> syncCompletedPlansToCalendar() async {
    final List<Map<String, dynamic>> payloads = [];
    int missingTimestampPlanCount = 0;

    // 1. 收集具备真实完成时间戳的已完成计划（严禁拿创建时间伪造完成时间）
    for (final p in completedPlans) {
      final ts = p.completeTime;
      if (ts != null && ts > 0) {
        payloads.add({
          'title': p.name,
          'completeTimeEpochMs': ts,
          'notes': '微行动计划达成',
        });
      } else {
        missingTimestampPlanCount++;
      }
    }

    // 2. 收集所有习惯的真实打卡历史（同一天同一习惯合并为 1 条记录，备注更新当日次数与累计次数）
    for (final h in _habits) {
      final validHistory = h.completionHistory.where((ts) => ts > 0).toList()..sort();
      if (validHistory.isEmpty) continue;

      final Map<String, List<int>> dayBuckets = {};
      for (final ts in validHistory) {
        final d = DateTime.fromMillisecondsSinceEpoch(ts);
        final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        dayBuckets.putIfAbsent(key, () => []).add(ts);
      }

      int cumulativeCount = 0;
      for (final entry in dayBuckets.entries) {
        final dayList = entry.value;
        cumulativeCount += dayList.length;
        payloads.add({
          'title': h.name,
          'completeTimeEpochMs': dayList.first,
          'notes': '当日打卡 ${dayList.length} 次 · 累计打卡 $cumulativeCount 次',
        });
      }
    }

    if (payloads.isEmpty) {
      final msg = missingTimestampPlanCount > 0
          ? '暂无带真实完成时间的记录可补录（有 $missingTimestampPlanCount 条旧计划未记录完成时间，已如实跳过）'
          : '暂无已完成的计划或习惯打卡记录';
      return {
        'success': true,
        'message': msg,
        'recordedCount': 0,
        'skippedCount': 0,
      };
    }

    final res = await AppleEcoService().batchRecordCompletedPlans(payloads);
    if (res['success'] == true && missingTimestampPlanCount > 0) {
      res['missingTimestampPlanCount'] = missingTimestampPlanCount;
    }
    return res;
  }

  Future<void> toggleHabitStatus(String id) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      final habit = _habits[index];
      habit.status = habit.status == '已停用' ? '进行中' : '已停用';

      if (habit.status == '已停用') {
        bool anchorsChanged = false;
        for (var anchor in _anchors) {
          if (anchor.habitIds.contains(id)) {
            anchor.habitIds.remove(id);
            anchorsChanged = true;
          }
        }
        if (anchorsChanged) {
          await _storage.saveAnchors(_anchors);
        }
      }
      await _storage.saveHabits(_habits);
      notifyListeners();
      refreshAnchorNotifications();
    }
  }

  Future<void> deleteHabit(String id) async {
    final idx = _habits.indexWhere((h) => h.id == id);
    final String? habitTitleToDelete = idx != -1 ? _habits[idx].name : null;

    _habits.removeWhere((h) => h.id == id);
    bool anchorsChanged = false;
    for (var anchor in _anchors) {
      if (anchor.habitIds.contains(id)) {
        anchor.habitIds.remove(id);
        anchorsChanged = true;
      }
    }
    if (anchorsChanged) {
      await _storage.saveAnchors(_anchors);
    }
    await _storage.saveHabits(_habits);
    notifyListeners();
    refreshAnchorNotifications();

    // 删除习惯时同步从「微行动」日历中清理该习惯的打卡足迹记录
    if (habitTitleToDelete != null && habitTitleToDelete.isNotEmpty) {
      AppleEcoService().deleteFootprintEvents(title: habitTitleToDelete);
    }
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
  Future<void> addAnchor(
    String name,
    String time, {
    String repeatMode = 'daily',
    List<int>? customDays,
  }) async {
    final newAnchor = Anchor(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      time: time,
      isReminderEnabled: true,
      repeatMode: repeatMode,
      customDays: customDays,
    );
    _anchors.add(newAnchor);
    _anchors.sort((a, b) => a.time.compareTo(b.time));
    await _storage.saveAnchors(_anchors);
    notifyListeners();

    await refreshAnchorNotifications(requestPermissionIfNeeded: true);
  }

  Future<void> updateAnchor(
    String id,
    String name,
    String time, {
    String? repeatMode,
    List<int>? customDays,
  }) async {
    final index = _anchors.indexWhere((a) => a.id == id);
    if (index != -1) {
      final targetAnchor = _anchors[index];
      targetAnchor.name = name;
      targetAnchor.time = time;
      if (repeatMode != null) {
        targetAnchor.repeatMode = repeatMode;
      }
      if (customDays != null && customDays.isNotEmpty) {
        targetAnchor.customDays = customDays;
      }
      _anchors.sort((a, b) => a.time.compareTo(b.time));
      await _storage.saveAnchors(_anchors);
      notifyListeners();

      await refreshAnchorNotifications(
        requestPermissionIfNeeded: targetAnchor.isReminderEnabled,
      );
    }
  }

  /// 切换单个锚点的定时提醒开启/暂停状态
  Future<Map<String, dynamic>> toggleAnchorReminder(String id, bool enabled) async {
    final index = _anchors.indexWhere((a) => a.id == id);
    if (index == -1) {
      return {'success': false, 'message': '未找到对应锚点'};
    }

    _anchors[index].isReminderEnabled = enabled;
    await _storage.saveAnchors(_anchors);
    notifyListeners();

    final res = await refreshAnchorNotifications(
      requestPermissionIfNeeded: enabled,
    );
    if (enabled && res['permissionDenied'] == true) {
      // 若系统通知权限被拒绝，如实回退开关状态并提示用户开启权限，绝不伪装开启成功
      _anchors[index].isReminderEnabled = false;
      await _storage.saveAnchors(_anchors);
      notifyListeners();
      return {
        'success': false,
        'permissionDenied': true,
        'message': res['message'] ?? '请在系统设置中开启微行动助手的通知权限',
      };
    }
    return {
      'success': true,
      'enabled': _anchors[index].isReminderEnabled,
    };
  }

  Future<void> deleteAnchor(String id) async {
    final index = _anchors.indexWhere((a) => a.id == id);
    if (index != -1) {
      await NotificationService().cancelNotification(id.hashCode);
      _anchors.removeAt(index);
      await _storage.saveAnchors(_anchors);
      notifyListeners();

      await refreshAnchorNotifications();
    }
  }

  /// 清理旧版系统日历中遗留的锚点日程
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
        refreshAnchorNotifications();
      }
    }
  }

  Future<void> unbindPlanFromAnchor(String anchorId, String planId) async {
    final index = _anchors.indexWhere((a) => a.id == anchorId);
    if (index != -1) {
      _anchors[index].planIds.remove(planId);
      await _storage.saveAnchors(_anchors);
      notifyListeners();
      refreshAnchorNotifications();
    }
  }

  Future<void> bindHabitToAnchor(String anchorId, String habitId) async {
    final index = _anchors.indexWhere((a) => a.id == anchorId);
    if (index != -1) {
      if (!_anchors[index].habitIds.contains(habitId)) {
        _anchors[index].habitIds.add(habitId);
        await _storage.saveAnchors(_anchors);
        notifyListeners();
        refreshAnchorNotifications();
      }
    }
  }

  Future<void> unbindHabitFromAnchor(String anchorId, String habitId) async {
    final index = _anchors.indexWhere((a) => a.id == anchorId);
    if (index != -1) {
      _anchors[index].habitIds.remove(habitId);
      await _storage.saveAnchors(_anchors);
      notifyListeners();
      refreshAnchorNotifications();
    }
  }

  // Import/Export Methods
  String exportData() {
    final Map<String, dynamic> data = {
      'schemaVersion': 2,
      'exportedAt': DateTime.now().millisecondsSinceEpoch,
      'plans': _plans.map((p) => p.toJson()).toList(),
      'habits': _habits.map((h) => h.toJson()).toList(),
      'anchors': _anchors.map((a) => a.toJson()).toList(),
      'notifications': _notifications.map((n) => n.toJson()).toList(),
      'notificationsClearedBefore': _notificationsClearedBefore,
      'shineRecords': _shineRecords.map((r) => r.toJson()).toList(),
      'customAffirmations': _customAffirmations,
      'celebrationStyleMode': _celebrationStyleMode,
      'celebrationSoundEnabled': _celebrationSoundEnabled,
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
    final previousShineRecords =
        _shineRecords.map((r) => ShineRecord.fromJson(r.toJson())).toList();
    final previousCustomAffirmations = List<String>.from(_customAffirmations);
    final previousStyleMode = _celebrationStyleMode;
    final previousSoundEnabled = _celebrationSoundEnabled;

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
      final List<ShineRecord> newShineRecords = data.containsKey('shineRecords')
          ? (data['shineRecords'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map(ShineRecord.fromJson)
              .toList()
          : [];
      final List<String> newCustomAffirmations = data.containsKey('customAffirmations')
          ? (data['customAffirmations'] as List<dynamic>)
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList()
          : [];
      final bool hasStyleKey = data.containsKey('celebrationStyleMode');
      final String importedStyleMode = hasStyleKey
          ? CelebrationStyleMode.normalize(data['celebrationStyleMode']?.toString())
          : previousStyleMode;
      final bool hasSoundKey = data.containsKey('celebrationSoundEnabled');
      final bool importedSoundEnabled = hasSoundKey
          ? (data['celebrationSoundEnabled'] == true)
          : previousSoundEnabled;

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
            existing.repeatMode = na.repeatMode;
            existing.customDays = na.customDays;
            existing.isReminderEnabled = na.isReminderEnabled;
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

        // 5. 发光星籽与专属庆祝语合并
        final Map<String, ShineRecord> shineMap = {
          for (final r in _shineRecords) r.id: r,
        };
        for (final nr in newShineRecords) {
          if (nr.id.isNotEmpty) {
            shineMap[nr.id] = nr;
          }
        }
        _shineRecords = shineMap.values.toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        for (final aff in newCustomAffirmations.reversed) {
          if (!_customAffirmations.contains(aff)) {
            _customAffirmations.insert(0, aff);
          }
        }
        if (hasStyleKey) _celebrationStyleMode = importedStyleMode;
        if (hasSoundKey) _celebrationSoundEnabled = importedSoundEnabled;
      } else {
        _plans = newPlans;
        _habits = newHabits;
        _anchors = newAnchors;
        _notifications = newNotifications;
        _notificationsClearedBefore = importedNotificationsClearedBefore;
        _shineRecords = newShineRecords
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _customAffirmations = newCustomAffirmations;
        _celebrationStyleMode =
            hasStyleKey ? importedStyleMode : CelebrationStyleMode.mixed;
        _celebrationSoundEnabled = hasSoundKey ? importedSoundEnabled : true;
      }

      await _storage.savePlans(_plans);
      await _storage.saveHabits(_habits);
      await _storage.saveAnchors(_anchors);
      await _storage.saveNotifications(_notifications);
      await _storage.saveNotificationsClearedBefore(_notificationsClearedBefore);
      await _storage.saveShineRecords(_shineRecords);
      await _storage.saveCustomAffirmations(_customAffirmations);
      await _storage.saveCelebrationStyleMode(_celebrationStyleMode);
      await _storage.saveCelebrationSoundEnabled(_celebrationSoundEnabled);

      // 导入后自动重排锚点系统通知并与系统提醒事项双向对齐
      refreshAnchorNotifications();
      final appleEco = AppleEcoService();
      if (appleEco.isSupported) {
        final isTwoWay = await appleEco.isTwoWaySyncEnabled();
        if (isTwoWay) {
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
      _shineRecords = previousShineRecords;
      _customAffirmations = previousCustomAffirmations;
      _celebrationStyleMode = previousStyleMode;
      _celebrationSoundEnabled = previousSoundEnabled;

      try {
        await _storage.savePlans(_plans);
        await _storage.saveHabits(_habits);
        await _storage.saveAnchors(_anchors);
        await _storage.saveNotifications(_notifications);
        await _storage.saveNotificationsClearedBefore(_notificationsClearedBefore);
        await _storage.saveShineRecords(_shineRecords);
        await _storage.saveCustomAffirmations(_customAffirmations);
        await _storage.saveCelebrationStyleMode(_celebrationStyleMode);
        await _storage.saveCelebrationSoundEnabled(_celebrationSoundEnabled);
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
