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

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

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

  /// 在完成计划或习惯打卡时，将本次行动足迹写入 iOS「日历」
  Future<bool> recordActionFootprintIfNeeded({
    required String title,
    required String category,
    String? notes,
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
        },
      );
      return res?['success'] == true;
    } catch (e) {
      debugPrint('Failed to record iOS calendar footprint: $e');
      return false;
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
}
