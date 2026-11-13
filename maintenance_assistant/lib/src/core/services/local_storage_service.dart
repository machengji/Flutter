import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/plan_model.dart';
import '../../shared/models/habit_model.dart';
import '../../shared/models/anchor_model.dart';
import '../../shared/models/notification_model.dart';
import '../../shared/models/celebration_model.dart';

class LocalStorageService {
  static const String _plansKey = 'plans';
  static const String _habitsKey = 'habits';
  static const String _anchorsKey = 'anchors';
  static const String _notificationsKey = 'notifications';
  static const String _notificationsClearedBeforeKey = 'notifications_cleared_before';
  static const String _shineRecordsKey = 'shine_records';
  static const String _customAffirmationsKey = 'custom_affirmations';
  static const String _celebrationStyleModeKey = 'celebration_style_mode';
  static const String _celebrationSoundEnabledKey = 'celebration_sound_enabled';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> savePlans(List<Plan> plans) async {
    final prefs = await _preferences;
    final String jsonString = jsonEncode(plans.map((p) => p.toJson()).toList());
    await prefs.setString(_plansKey, jsonString);
  }

  Future<List<Plan>> loadPlans() async {
    final prefs = await _preferences;
    final String? jsonString = prefs.getString(_plansKey);
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Plan.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await _preferences;
    final String jsonString = jsonEncode(habits.map((h) => h.toJson()).toList());
    await prefs.setString(_habitsKey, jsonString);
  }

  Future<List<Habit>> loadHabits() async {
    final prefs = await _preferences;
    final String? jsonString = prefs.getString(_habitsKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Habit.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveAnchors(List<Anchor> anchors) async {
    final prefs = await _preferences;
    final String jsonString = jsonEncode(anchors.map((a) => a.toJson()).toList());
    await prefs.setString(_anchorsKey, jsonString);
  }

  Future<List<Anchor>> loadAnchors() async {
    final prefs = await _preferences;
    final String? jsonString = prefs.getString(_anchorsKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Anchor.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveNotifications(List<NotificationModel> notifications) async {
    final prefs = await _preferences;
    final String jsonString = jsonEncode(notifications.map((n) => n.toJson()).toList());
    await prefs.setString(_notificationsKey, jsonString);
  }

  Future<List<NotificationModel>> loadNotifications() async {
    final prefs = await _preferences;
    final String? jsonString = prefs.getString(_notificationsKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveNotificationsClearedBefore(int timestamp) async {
    final prefs = await _preferences;
    await prefs.setInt(_notificationsClearedBeforeKey, timestamp);
  }

  Future<int> loadNotificationsClearedBefore() async {
    final prefs = await _preferences;
    return prefs.getInt(_notificationsClearedBeforeKey) ?? 0;
  }

  Future<void> saveShineRecords(List<ShineRecord> records) async {
    final prefs = await _preferences;
    final String jsonString = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_shineRecordsKey, jsonString);
  }

  Future<List<ShineRecord>> loadShineRecords() async {
    final prefs = await _preferences;
    final String? jsonString = prefs.getString(_shineRecordsKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .whereType<Map<String, dynamic>>()
          .map(ShineRecord.fromJson)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveCustomAffirmations(List<String> items) async {
    final prefs = await _preferences;
    await prefs.setStringList(_customAffirmationsKey, items);
  }

  Future<List<String>> loadCustomAffirmations() async {
    final prefs = await _preferences;
    return prefs.getStringList(_customAffirmationsKey) ?? [];
  }

  Future<void> saveCelebrationStyleMode(String mode) async {
    final prefs = await _preferences;
    await prefs.setString(
      _celebrationStyleModeKey,
      CelebrationStyleMode.normalize(mode),
    );
  }

  Future<String> loadCelebrationStyleMode() async {
    final prefs = await _preferences;
    return CelebrationStyleMode.normalize(
      prefs.getString(_celebrationStyleModeKey),
    );
  }

  Future<void> saveCelebrationSoundEnabled(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(_celebrationSoundEnabledKey, enabled);
  }

  Future<bool> loadCelebrationSoundEnabled() async {
    final prefs = await _preferences;
    return prefs.getBool(_celebrationSoundEnabledKey) ?? true;
  }
}
