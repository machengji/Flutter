import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// iOS 原生「提醒事项 (Reminders)」与「日历 (Calendar)」生态桥接服务
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

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// 初始化/设置系统提醒事项变化事件监听
  void setupEventListener({VoidCallback? onStoreChanged}) {
    _onStoreChangedListener = onStoreChanged;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onEventStoreChanged') {
        _onStoreChangedListener?.call();
      }
    });
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
  /// 返回系统分配的唯一标识 reminderId (calendarItemIdentifier)
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

  /// 将时间锚点（含关联的计划/习惯清单）同步到 iOS「提醒事项」与「日历」
  Future<Map<String, dynamic>> syncAnchorToSystem({
    required String name,
    required String time,
    required List<String> items,
  }) async {
    if (!isSupported) {
      return {
        'success': false,
        'message': '当前设备非 iOS 平台，仅在 iPhone/iPad 上支持同步系统日历与提醒事项',
      };
    }

    try {
      final res = await _channel.invokeMethod<Map<Object?, Object?>>(
        'syncAnchor',
        {
          'name': name,
          'time': time,
          'items': items,
        },
      );
      return {
        'success': res?['success'] == true,
        'syncedToReminder': res?['syncedToReminder'] == true,
        'syncedToCalendar': res?['syncedToCalendar'] == true,
      };
    } on PlatformException catch (e) {
      return {
        'success': false,
        'message': e.message ?? '同步锚点失败，请检查系统日历与提醒事项权限',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '同步锚点异常: $e',
      };
    }
  }

  /// 在完成计划或习惯打卡时，将本次行动足迹写入 iOS「日历」日程
  /// 支持传入精准的完成时间戳 completeTimeEpochMs，自动根据完成日期入历并去重
  Future<bool> recordActionFootprintIfNeeded({
    required String title,
    required String category,
    String? notes,
    int? completeTimeEpochMs,
  }) async {
    if (!isSupported) return false;
    final enabled = await isAutoFootprintEnabled();
    if (!enabled) return false;

    try {
      final res = await _channel.invokeMethod<Map<Object?, Object?>>(
        'recordFootprint',
        {
          'title': title,
          'category': category,
          'notes': notes,
          'timestampEpochMs': completeTimeEpochMs,
        },
      );
      return res?['success'] == true;
    } catch (e) {
      debugPrint('Failed to record iOS calendar footprint: $e');
      return false;
    }
  }

  /// 批量将已完成计划补录到 iOS 系统「日历」日程（自动根据真实完成时间入历并去重）
  Future<Map<String, dynamic>> batchRecordCompletedPlans(
    List<Map<String, dynamic>> plans,
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
        {'plans': plans},
      );
      return {
        'success': res?['success'] == true,
        'recordedCount': (res?['recordedCount'] as num?)?.toInt() ?? 0,
        'skippedCount': (res?['skippedCount'] as num?)?.toInt() ?? 0,
      };
    } on PlatformException catch (e) {
      return {
        'success': false,
        'message': e.message ?? '批量补录已完成日程失败，请检查系统日历权限',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '批量补录已完成日程异常: $e',
      };
    }
  }

  /// 一键批量将所有未完成计划与所有锚点同步到 iOS「提醒事项」与「日历」
  Future<Map<String, dynamic>> batchSyncAll({
    required List<Map<String, dynamic>> plans,
    required List<Map<String, dynamic>> anchors,
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
          'anchors': anchors,
        },
      );
      return {
        'success': res?['success'] == true,
        'syncedPlans': (res?['syncedPlans'] as num?)?.toInt() ?? 0,
        'syncedAnchors': (res?['syncedAnchors'] as num?)?.toInt() ?? 0,
        'listName': res?['listName']?.toString() ?? '微行动',
      };
    } on PlatformException catch (e) {
      return {
        'success': false,
        'message': e.message ?? '批量同步失败，请检查系统日历与提醒事项权限',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '批量同步异常: $e',
      };
    }
  }

  /// 呼出系统分享面板，将指定路径的文件导出（支持另存为“文件”、隔空投送、微信传输等）
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

  /// 呼出 iOS 系统原生分享面板分享纯文本（已完成战报、成就喜报、AI分析总结等）
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
}

