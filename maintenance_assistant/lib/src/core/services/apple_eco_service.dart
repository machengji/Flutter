import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// iOS 原生「时效性通知 (UserNotifications)」、「提醒事项 (Reminders)」与「微行动专属日历 (Calendar)」桥接服务
class AppleEcoService {
  static final AppleEcoService _instance = AppleEcoService._internal();
  factory AppleEcoService() => _instance;
  AppleEcoService._internal();

  static const MethodChannel _channel = MethodChannel(
    'com.maintenance.assistant/apple_eco',
  );

  static const String _prefKeyAutoFootprint = 'auto_sync_ios_footprint';
  static const String _prefKeyTwoWaySync = 'two_way_sync_ios_reminders';

  VoidCallback? _onStoreChangedListener;
  ValueChanged<String>? _onAnchorNotificationTappedListener;
  bool _handlerInstalled = false;

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  void _ensureMethodCallHandler() {
    if (_handlerInstalled) return;
    _handlerInstalled = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onEventStoreChanged') {
        _onStoreChangedListener?.call();
      } else if (call.method == 'onAnchorNotificationTapped') {
        final args = call.arguments as Map<Object?, Object?>?;
        final anchorId = args?['anchorId']?.toString() ?? '';
        if (anchorId.isNotEmpty) {
          _onAnchorNotificationTappedListener?.call(anchorId);
        }
      }
    });
  }

  /// 设置系统提醒事项变化监听与锚点通知点击监听
  void setupEventListener({
    VoidCallback? onStoreChanged,
    ValueChanged<String>? onAnchorNotificationTapped,
  }) {
    if (onStoreChanged != null) {
      _onStoreChangedListener = onStoreChanged;
    }
    if (onAnchorNotificationTapped != null) {
      _onAnchorNotificationTappedListener = onAnchorNotificationTapped;
    }
    _ensureMethodCallHandler();
  }

  /// 绑定锚点通知点击跳转回调（支持热唤醒实时回调）
  void setAnchorNotificationTapListener(ValueChanged<String>? listener) {
    _onAnchorNotificationTappedListener = listener;
    _ensureMethodCallHandler();
  }

  /// 拉取并消费冷启动（App 完全关闭时点击通知启动）记录的待打开锚点 ID
  Future<String?> consumePendingOpenedAnchor() async {
    if (!isSupported) return null;
    try {
      final anchorId = await _channel.invokeMethod<String>(
        'consumePendingOpenedAnchor',
      );
      if (anchorId != null && anchorId.isNotEmpty) {
        return anchorId;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to consume pending opened anchor: $e');
      return null;
    }
  }

  /// 同步调度所有锚点的 iOS 系统级本地定时通知（App 彻底关闭后依然由 iOS 系统准点触发）
  Future<Map<String, dynamic>> syncAnchorNotifications({
    required List<Map<String, dynamic>> anchors,
    bool requestPermissionIfNeeded = false,
  }) async {
    if (!isSupported) {
      return {
        'success': true,
        'scheduledCount': 0,
      };
    }

    try {
      final res = await _channel.invokeMethod<Map<Object?, Object?>>(
        'syncAnchorNotifications',
        {
          'anchors': anchors,
          'requestPermissionIfNeeded': requestPermissionIfNeeded,
        },
      );
      return {
        'success': res?['success'] == true,
        'permissionDenied': res?['permissionDenied'] == true,
        'scheduledCount': (res?['scheduledCount'] as num?)?.toInt() ?? 0,
        'message': res?['message']?.toString(),
      };
    } on PlatformException catch (e) {
      return {
        'success': false,
        'message': e.message ?? '同步锚点提醒通知失败，请检查系统通知权限',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '同步锚点提醒通知异常: $e',
      };
    }
  }

  /// 静默清理历史遗留的「微行动锚点」系统日历分组及提醒事项残留
  Future<void> cleanupLegacyAnchorSystemData() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('cleanupLegacyAnchorSystemData');
    } catch (e) {
      debugPrint('Failed to cleanup legacy anchor system data: $e');
    }
  }

  /// 读取是否开启「与 iOS 提醒事项双向实时同步」（默认开启）
  Future<bool> isTwoWaySyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyTwoWaySync) ?? true;
  }

  /// 设置是否开启「与 iOS 提醒事项双向实时同步」
  Future<void> setTwoWaySyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyTwoWaySync, enabled);
  }

  /// 读取是否开启「打卡完成时自动写入 iOS 日历足迹」（默认开启）
  Future<bool> isAutoFootprintEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyAutoFootprint) ?? true;
  }

  /// 设置是否开启「打卡完成时自动写入 iOS 日历足迹」
  Future<void> setAutoFootprintEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyAutoFootprint, enabled);
  }

  /// 双向同步：将单个计划同步到系统提醒事项（创建或更新其状态、标题、完成状态）
  Future<String?> syncPlanToReminder({
    required String title,
    required String status,
    String? notes,
    String? reminderId,
    int? alarmEpochMs,
  }) async {
    if (!isSupported) return null;

    try {
      final res = await _channel.invokeMethod<Map<Object?, Object?>>(
        'syncPlanReminder',
        {
          'title': title,
          'status': status,
          'notes': notes,
          'reminderId': reminderId,
          'alarmEpochMs': alarmEpochMs,
        },
      );
      if (res?['success'] == true) {
        return res?['reminderId']?.toString();
      }
      return null;
    } catch (e) {
      debugPrint('Failed to sync plan to reminder: $e');
      return null;
    }
  }

  /// 从 iOS 提醒事项中删除指定条目
  Future<bool> deletePlanReminder(String reminderId) async {
    if (!isSupported || reminderId.isEmpty) return false;

    try {
      final res = await _channel.invokeMethod<Map<Object?, Object?>>(
        'deletePlanReminder',
        {'reminderId': reminderId},
      );
      return res?['success'] == true;
    } catch (e) {
      debugPrint('Failed to delete plan reminder: $e');
      return false;
    }
  }

  /// 从 iOS 系统中完整删除计划（同时删除提醒事项条目以及「微行动」日历中的关联完成记录）
  Future<Map<String, dynamic>> deletePlanFromSystem({
    required String title,
    String? reminderId,
    bool alsoDeleteCalendarEvents = true,
  }) async {
    if (!isSupported) {
      return {'success': true, 'reminderDeleted': false, 'calendarEventsDeleted': 0};
    }

    try {
      final res = await _channel.invokeMethod<Map<Object?, Object?>>(
        'deletePlanFromSystem',
        {
          'title': title,
          'reminderId': reminderId,
          'alsoDeleteCalendarEvents': alsoDeleteCalendarEvents,
        },
      );
      return {
        'success': res?['success'] == true,
        'reminderDeleted': res?['reminderDeleted'] == true,
        'calendarEventsDeleted': (res?['calendarEventsDeleted'] as num?)?.toInt() ?? 0,
      };
    } catch (e) {
      debugPrint('Failed to delete plan from iOS system: $e');
      return {'success': false, 'reminderDeleted': false, 'calendarEventsDeleted': 0};
    }
  }

  /// 从「微行动」专属日历中撤回/删除指定事项的完成足迹记录（用于计划取消完成、删除计划或删除习惯）
  Future<Map<String, dynamic>> deleteFootprintEvents({
    required String title,
    int? targetDayEpochMs,
  }) async {
    if (!isSupported || title.isEmpty) {
      return {'success': true, 'deletedCount': 0};
    }

    try {
      final res = await _channel.invokeMethod<Map<Object?, Object?>>(
        'deleteFootprintEvents',
        {
          'title': title,
          'targetDayEpochMs': targetDayEpochMs,
        },
      );
      return {
        'success': res?['success'] == true,
        'deletedCount': (res?['deletedCount'] as num?)?.toInt() ?? 0,
      };
    } catch (e) {
      debugPrint('Failed to delete footprint events: $e');
      return {'success': false, 'deletedCount': 0};
    }
  }

  /// 清理旧版系统锚点日历与提醒事项
  Future<Map<String, dynamic>> clearAllAnchorCalendarEvents({
    List<String> anchorNames = const [],
  }) async {
    if (!isSupported) {
      return {'success': false, 'message': '仅在 iOS 平台支持日历清理'};
    }

    try {
      final res = await _channel.invokeMethod<Map<Object?, Object?>>(
        'clearAnchorCalendarEvents',
        {'anchorNames': anchorNames},
      );
      return {
        'success': res?['success'] == true,
        'deletedCount': (res?['deletedCount'] as num?)?.toInt() ?? 0,
      };
    } on PlatformException catch (e) {
      return {
        'success': false,
        'message': e.message ?? '清理历史锚点日历失败',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '清理历史锚点日历异常: $e',
      };
    }
  }

  /// 获取系统「微行动」列表下的所有提醒事项（包含已完成与未完成）
  Future<List<Map<String, dynamic>>> fetchAllReminders() async {
    if (!isSupported) return [];

    try {
      final res = await _channel.invokeMethod<Map<Object?, Object?>>(
        'fetchAllReminders',
      );
      if (res?['success'] == true) {
        final list = res?['reminders'] as List<Object?>? ?? [];
        return list.map((item) {
          final map = item as Map<Object?, Object?>;
          return {
            'reminderId': map['reminderId']?.toString() ?? '',
            'title': map['title']?.toString() ?? '',
            'isCompleted': map['isCompleted'] == true,
            'notes': map['notes']?.toString(),
            'completionDateEpochMs': (map['completionDateEpochMs'] as num?)?.toInt(),
            'creationDateEpochMs': (map['creationDateEpochMs'] as num?)?.toInt(),
          };
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Failed to fetch all reminders: $e');
      return [];
    }
  }

  /// 将单个计划添加到 iOS「提醒事项」（自动归入「微行动」专属列表）
  Future<Map<String, dynamic>> addPlanToReminders({
    required String title,
    String? notes,
    int? alarmEpochMs,
  }) async {
    if (!isSupported) {
      return {
        'success': false,
        'message': '当前设备非 iOS 平台，仅在 iPhone/iPad 上支持写入系统提醒事项',
      };
    }

    try {
      final res = await _channel.invokeMethod<Map<Object?, Object?>>(
        'addPlanReminder',
        {
          'title': title,
          'notes': notes,
          'alarmEpochMs': alarmEpochMs,
        },
      );
      return {
        'success': res?['success'] == true,
        'listName': res?['listName']?.toString() ?? '微行动',
        'updated': res?['updated'] == true,
      };
    } on PlatformException catch (e) {
      return {
        'success': false,
        'message': e.message ?? '写入提醒事项失败，请检查系统权限',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '写入提醒事项异常: $e',
      };
    }
  }

  /// 在完成计划或习惯打卡时，将本次行动足迹写入 iOS「微行动」专属日历分组（纯名称无前缀，15分钟无闹钟）
  Future<Map<String, dynamic>> recordActionFootprintIfNeeded({
    required String title,
    required String category,
    String? notes,
    required int? completeTimeEpochMs,
    bool mergeOnSameDay = true,
  }) async {
    if (!isSupported) return {'success': false};
    final enabled = await isAutoFootprintEnabled();
    if (!enabled) return {'success': false, 'disabled': true};
    if (completeTimeEpochMs == null || completeTimeEpochMs <= 0) {
      return {'success': false, 'message': '缺少真实完成时间戳'};
    }

    try {
      final res = await _channel.invokeMethod<Map<Object?, Object?>>(
        'recordFootprint',
        {
          'title': title,
          'category': category,
          'notes': notes,
          'timestampEpochMs': completeTimeEpochMs,
          'mergeOnSameDay': mergeOnSameDay,
        },
      );
      return {
        'success': res?['success'] == true,
        'message': res?['message']?.toString(),
      };
    } catch (e) {
      debugPrint('Failed to record iOS calendar footprint: $e');
      return {'success': false, 'message': '$e'};
    }
  }

  /// 批量将已完成计划与习惯打卡历史记录补录到 iOS 系统「微行动」专属日历分组
  Future<Map<String, dynamic>> batchRecordCompletedPlans(
    List<Map<String, dynamic>> items,
  ) async {
    if (!isSupported) {
      return {
        'success': false,
        'message': '当前设备非 iOS 平台，仅在 iPhone/iPad 上支持写入系统日历',
      };
    }

    try {
      final res = await _channel.invokeMethod<Map<Object?, Object?>>(
        'batchRecordCompletedPlans',
        {'plans': items},
      );
      return {
        'success': res?['success'] == true,
        'recordedCount': (res?['recordedCount'] as num?)?.toInt() ?? 0,
        'skippedCount': (res?['skippedCount'] as num?)?.toInt() ?? 0,
      };
    } on PlatformException catch (e) {
      return {
        'success': false,
        'message': e.message ?? '批量补录已完成记录失败，请检查系统日历权限',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '批量补录已完成记录异常: $e',
      };
    }
  }

  /// 一键批量将所有未完成计划同步到 iOS「微行动」提醒事项列表
  Future<Map<String, dynamic>> batchSyncAll({
    required List<Map<String, dynamic>> plans,
  }) async {
    if (!isSupported) {
      return {
        'success': false,
        'message': '当前设备非 iOS 平台，请在 iPhone 上使用一键同步功能',
      };
    }

    try {
      final res = await _channel.invokeMethod<Map<Object?, Object?>>(
        'batchSync',
        {
          'plans': plans,
        },
      );
      return {
        'success': res?['success'] == true,
        'syncedPlans': (res?['syncedPlans'] as num?)?.toInt() ?? 0,
        'listName': res?['listName']?.toString() ?? '微行动',
      };
    } on PlatformException catch (e) {
      return {
        'success': false,
        'message': e.message ?? '批量同步失败，请检查系统提醒事项权限',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '批量同步异常: $e',
      };
    }
  }

  /// 呼出系统分享面板，将指定路径的文件导出
  Future<bool> shareFile(String filePath) async {
    if (!isSupported) return false;
    try {
      final res = await _channel.invokeMethod<bool>(
        'shareFile',
        {'filePath': filePath},
      );
      return res ?? false;
    } catch (e) {
      debugPrint('AppleEcoService.shareFile error: $e');
      return false;
    }
  }

  /// 唤起 iOS 系统的“文件”选择器选择 .json 备份文件并读取内容
  Future<String?> pickJsonFile() async {
    if (!isSupported) return null;
    try {
      final content = await _channel.invokeMethod<String>('pickJsonFile');
      return content;
    } catch (e) {
      debugPrint('AppleEcoService.pickJsonFile error: $e');
      return null;
    }
  }

  /// 呼出 iOS 系统原生分享面板分享纯文本
  Future<bool> shareText(String text) async {
    try {
      if (isSupported) {
        final res = await _channel.invokeMethod<bool>(
          'shareText',
          {'text': text},
        );
        if (res == true) return true;
      }
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } catch (e) {
      debugPrint('AppleEcoService.shareText error: $e');
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    }
  }

  /// 触发庆祝多感官微反馈（iOS 原生渐进触觉节奏 + 环境混音风铃微音效；其他平台使用标准触觉）
  Future<void> playCelebrationCue({
    String kind = 'light',
    bool soundEnabled = true,
    double progress = 0.5,
  }) async {
    if (isSupported) {
      try {
        await _channel.invokeMethod('playCelebrationCue', {
          'kind': kind,
          'soundEnabled': soundEnabled,
          'progress': progress,
        });
        return;
      } catch (e) {
        debugPrint('AppleEcoService.playCelebrationCue error: $e');
      }
    }

    try {
      if (kind == 'charge_tick') {
        await HapticFeedback.selectionClick();
      } else if (kind == 'grand') {
        await HapticFeedback.heavyImpact();
      } else {
        await HapticFeedback.mediumImpact();
      }
    } catch (_) {}
  }
}
