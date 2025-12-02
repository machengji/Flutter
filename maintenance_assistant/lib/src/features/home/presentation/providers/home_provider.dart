import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../shared/models/plan_model.dart';
import '../../../../shared/models/habit_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../shared/services/deepseek_service.dart';

class HomeProvider extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();
  
  List<Plan> _plans = [];
  List<Habit> _habits = [];
  String _rainbowFart = '你今天闪闪发光！';
  
  List<Plan> get plans => _plans;
  List<Habit> get habits => _habits;
  String get rainbowFart => _rainbowFart;
  
  List<Plan> get ongoingPlans => _plans.where((p) => p.status != '已完成').toList();
  List<Plan> get completedPlans => _plans.where((p) => p.status == '已完成').toList();
  
  List<Habit> get activeHabits => _habits.where((h) => h.status != '已停用').toList();
  List<Habit> get stoppedHabits => _habits.where((h) => h.status == '已停用').toList();

  HomeProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    _plans = await _storage.loadPlans();
    _habits = await _storage.loadHabits();
    _loadRainbowFart(); // Load in background
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
  Future<void> addPlan(String name) async {
    final newPlan = Plan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createTime: DateTime.now().millisecondsSinceEpoch,
    );
    _plans.insert(0, newPlan);
    await _storage.savePlans(_plans);
    notifyListeners();
  }

  Future<void> updatePlan(String id, String newName) async {
    final index = _plans.indexWhere((p) => p.id == id);
    if (index != -1) {
      _plans[index].name = newName;
      await _storage.savePlans(_plans);
      notifyListeners();
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
        refreshRainbowFart(); // Prepare next rainbow fart
      }
      await _storage.savePlans(_plans);
      notifyListeners();
    }
  }

  Future<void> deletePlan(String id) async {
    _plans.removeWhere((p) => p.id == id);
    await _storage.savePlans(_plans);
    notifyListeners();
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
      refreshRainbowFart(); // Prepare next rainbow fart
      notifyListeners();
    }
  }

  Future<void> toggleHabitStatus(String id) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      final habit = _habits[index];
      habit.status = habit.status == '已停用' ? '进行中' : '已停用';
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

  // Import/Export Methods
  String exportData() {
    final Map<String, dynamic> data = {
      'plans': _plans.map((p) => p.toJson()).toList(),
      'habits': _habits.map((h) => h.toJson()).toList(),
    };
    return jsonEncode(data);
  }

  Future<bool> importData(String jsonString) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      
      if (data.containsKey('plans')) {
        final List<dynamic> plansJson = data['plans'];
        _plans = plansJson.map((json) => Plan.fromJson(json)).toList();
        await _storage.savePlans(_plans);
      }
      
      if (data.containsKey('habits')) {
        final List<dynamic> habitsJson = data['habits'];
        _habits = habitsJson.map((json) => Habit.fromJson(json)).toList();
        await _storage.saveHabits(_habits);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Import failed: $e');
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
}
