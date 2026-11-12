import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_assistant/src/features/home/presentation/providers/home_provider.dart';
import 'package:maintenance_assistant/src/features/home/presentation/widgets/anchor_detail_sheet.dart';
import 'package:maintenance_assistant/src/shared/models/anchor_model.dart';
import 'package:maintenance_assistant/src/shared/models/habit_model.dart';
import 'package:maintenance_assistant/src/shared/models/plan_model.dart';
import 'package:provider/provider.dart';

class FakeHomeProvider extends ChangeNotifier implements HomeProvider {
  List<Plan> _plans = [];
  List<Plan> _ongoingPlans = [];
  List<Habit> _habits = [];
  List<Habit> _activeHabits = [];
  List<Anchor> _anchors = [];
  final List<String> completedPlanIds = [];
  final List<String> checkedHabitIds = [];

  @override
  List<Plan> get plans => _plans;
  @override
  List<Plan> get ongoingPlans => _ongoingPlans;
  @override
  List<Habit> get habits => _habits;
  @override
  List<Habit> get activeHabits => _activeHabits;
  @override
  List<Anchor> get anchors => _anchors;

  set plans(List<Plan> value) => _plans = value;
  set ongoingPlans(List<Plan> value) => _ongoingPlans = value;
  set habits(List<Habit> value) => _habits = value;
  set activeHabits(List<Habit> value) => _activeHabits = value;
  set anchors(List<Anchor> value) => _anchors = value;

  @override
  int getHabitTodayCheckCount(Habit habit) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    return habit.completionHistory.where((ts) => ts >= startOfToday).length;
  }

  @override
  bool isHabitCheckedToday(Habit habit) => getHabitTodayCheckCount(habit) > 0;

  @override
  Future<Map<String, dynamic>> toggleAnchorReminder(String id, bool enabled) async {
    final idx = _anchors.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _anchors[idx].isReminderEnabled = enabled;
      notifyListeners();
    }
    return {'success': true, 'enabled': enabled};
  }

  @override
  Future<void> togglePlanStatus(String id) async {
    completedPlanIds.add(id);
    for (final a in _anchors) {
      a.planIds.remove(id);
    }
    notifyListeners();
  }

  @override
  Future<void> checkHabit(String id) async {
    checkedHabitIds.add(id);
    final idx = _habits.indexWhere((h) => h.id == id);
    if (idx != -1) {
      _habits[idx].totalDays++;
      _habits[idx].completionHistory.add(DateTime.now().millisecondsSinceEpoch);
    }
    notifyListeners();
  }

  @override
  Future<void> bindPlanToAnchor(String anchorId, String planId) async {}

  @override
  Future<void> bindHabitToAnchor(String anchorId, String habitId) async {}

  @override
  Future<void> deleteAnchor(String id) async {}

  @override
  Future<void> unbindPlanFromAnchor(String anchorId, String planId) async {}

  @override
  Future<void> unbindHabitFromAnchor(String anchorId, String habitId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

void main() {
  late FakeHomeProvider fakeProvider;

  setUp(() {
    fakeProvider = FakeHomeProvider();
  });

  Widget createWidgetUnderTest(Anchor anchor) {
    return ChangeNotifierProvider<HomeProvider>.value(
      value: fakeProvider,
      child: MaterialApp(
        home: Scaffold(
          body: AnchorDetailSheet(anchor: anchor),
        ),
      ),
    );
  }

  testWidgets('Should only show active plans in selection sheet', (tester) async {
    final anchor = Anchor(id: '1', name: 'Test Anchor', time: '08:00');
    final activePlan = Plan(id: 'p1', name: 'Active Plan', createTime: 0, status: '未开始');
    final completedPlan = Plan(id: 'p2', name: 'Completed Plan', createTime: 0, status: '已完成');

    fakeProvider.anchors = [anchor];
    fakeProvider.plans = [activePlan, completedPlan];
    fakeProvider.ongoingPlans = [activePlan];
    fakeProvider.habits = [];
    fakeProvider.activeHabits = [];

    await tester.pumpWidget(createWidgetUnderTest(anchor));
    await tester.tap(find.text('添加').first);
    await tester.pumpAndSettle();

    expect(find.text('Active Plan'), findsOneWidget);
    expect(find.text('Completed Plan'), findsNothing);
  });

  testWidgets('Should only show active habits in selection sheet', (tester) async {
    final anchor = Anchor(id: '1', name: 'Test Anchor', time: '08:00');
    final activeHabit = Habit(id: 'h1', name: 'Active Habit', createTime: 0, status: '进行中');
    final stoppedHabit = Habit(id: 'h2', name: 'Stopped Habit', createTime: 0, status: '已停用');

    fakeProvider.anchors = [anchor];
    fakeProvider.plans = [];
    fakeProvider.ongoingPlans = [];
    fakeProvider.habits = [activeHabit, stoppedHabit];
    fakeProvider.activeHabits = [activeHabit];

    await tester.pumpWidget(createWidgetUnderTest(anchor));
    await tester.tap(find.text('添加').last);
    await tester.pumpAndSettle();

    expect(find.text('Active Habit'), findsOneWidget);
    expect(find.text('Stopped Habit'), findsNothing);
  });

  testWidgets('Should support completing plan and checking habit directly in AnchorDetailSheet', (tester) async {
    final plan = Plan(id: 'p1', name: '买牛奶', createTime: 0, status: '进行中');
    final habit = Habit(id: 'h1', name: '晨跑', createTime: 0, status: '进行中');
    final anchor = Anchor(
      id: 'a1',
      name: '晨间锚点',
      time: '07:30',
      planIds: ['p1'],
      habitIds: ['h1'],
    );

    fakeProvider.anchors = [anchor];
    fakeProvider.plans = [plan];
    fakeProvider.ongoingPlans = [plan];
    fakeProvider.habits = [habit];
    fakeProvider.activeHabits = [habit];

    await tester.pumpWidget(createWidgetUnderTest(anchor));
    await tester.pumpAndSettle();

    expect(find.text('买牛奶'), findsOneWidget);
    expect(find.text('晨跑'), findsOneWidget);

    await tester.ensureVisible(find.text('完成'));
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    expect(fakeProvider.completedPlanIds, contains('p1'));

    ScaffoldMessenger.of(tester.element(find.byType(AnchorDetailSheet))).hideCurrentSnackBar();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('打卡'));
    await tester.tap(find.text('打卡'));
    await tester.pumpAndSettle();
    expect(fakeProvider.checkedHabitIds, contains('h1'));
    expect(find.text('已打卡(1)'), findsOneWidget);
  });
}
