import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/plan_model.dart';
import '../../shared/models/habit_model.dart';

class LocalStorageService {
  static const String _plansKey = 'plans';
  static const String _habitsKey = 'habits';

  Future<void> savePlans(List<Plan> plans) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(plans.map((p) => p.toJson()).toList());
    await prefs.setString(_plansKey, jsonString);
  }

  Future<List<Plan>> loadPlans() async {
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(habits.map((h) => h.toJson()).toList());
    await prefs.setString(_habitsKey, jsonString);
  }

  Future<List<Habit>> loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_habitsKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Habit.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}
