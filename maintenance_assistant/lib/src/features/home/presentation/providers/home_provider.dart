import 'package:flutter/material.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../shared/models/plan_model.dart';
import '../../../../shared/models/habit_model.dart';

class HomeProvider extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();
  
  List<Plan> _plans = [];
  List<Habit> _habits = [];
  
  List<Plan> get plans => _plans;
  List<Habit> get habits => _habits;
  
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
    notifyListeners();
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

  Future<void> checkHabit(String id) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      final habit = _habits[index];
      habit.totalDays++;
      habit.completionHistory.add(DateTime.now().millisecondsSinceEpoch);
      await _storage.saveHabits(_habits);
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
}
