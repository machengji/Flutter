import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_assistant/src/features/home/presentation/providers/home_provider.dart';
import 'package:maintenance_assistant/src/features/home/presentation/widgets/anchor_detail_sheet.dart';
import 'package:maintenance_assistant/src/shared/models/anchor_model.dart';
import 'package:maintenance_assistant/src/shared/models/habit_model.dart';
import 'package:maintenance_assistant/src/shared/models/plan_model.dart';
import 'package:maintenance_assistant/src/shared/models/notification_model.dart';
import 'package:provider/provider.dart';

class FakeHomeProvider extends ChangeNotifier implements HomeProvider {
  List<Plan> _plans = [];
  List<Plan> _ongoingPlans = [];
  List<Habit> _habits = [];
  List<Habit> _activeHabits = [];
  List<Anchor> _anchors = [];

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

  // Setters for test setup
  set plans(List<Plan> value) => _plans = value;
  set ongoingPlans(List<Plan> value) => _ongoingPlans = value;
  set habits(List<Habit> value) => _habits = value;
  set activeHabits(List<Habit> value) => _activeHabits = value;
  set anchors(List<Anchor> value) => _anchors = value;

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
    // Return null or default values for other methods
    return null;
  }
}

void main() {
  late FakeHomeProvider fakeProvider;

  setUp(() {
    fakeProvider = FakeHomeProvider();
  });

  Widget createWidgetUnderTest(Anchor anchor) {
    return MaterialApp(
      home: ChangeNotifierProvider<HomeProvider>.value(
        value: fakeProvider,
        child: Scaffold(
          body: AnchorDetailSheet(anchor: anchor),
        ),
      ),
    );
  }

  testWidgets('Should only show active plans in selection sheet', (tester) async {
    // Arrange
    final anchor = Anchor(id: '1', name: 'Test Anchor', time: '08:00');
    final activePlan = Plan(id: 'p1', name: 'Active Plan', createTime: 0, status: '未开始');
    final completedPlan = Plan(id: 'p2', name: 'Completed Plan', createTime: 0, status: '已完成');

    fakeProvider.anchors = [anchor];
    fakeProvider.plans = [activePlan, completedPlan];
    fakeProvider.ongoingPlans = [activePlan]; // Only active plan
    fakeProvider.habits = [];
    fakeProvider.activeHabits = [];

    // Act
    await tester.pumpWidget(createWidgetUnderTest(anchor));
    await tester.tap(find.text('添加').first); // Click first 'Add' button (for Plans)
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Active Plan'), findsOneWidget);
    expect(find.text('Completed Plan'), findsNothing);
  });

  testWidgets('Should only show active habits in selection sheet', (tester) async {
    // Arrange
    final anchor = Anchor(id: '1', name: 'Test Anchor', time: '08:00');
    final activeHabit = Habit(id: 'h1', name: 'Active Habit', createTime: 0, status: '进行中');
    final stoppedHabit = Habit(id: 'h2', name: 'Stopped Habit', createTime: 0, status: '已停用');

    fakeProvider.anchors = [anchor];
    fakeProvider.plans = [];
    fakeProvider.ongoingPlans = [];
    fakeProvider.habits = [activeHabit, stoppedHabit];
    fakeProvider.activeHabits = [activeHabit]; // Only active habit

    // Act
    await tester.pumpWidget(createWidgetUnderTest(anchor));
    await tester.tap(find.text('添加').last); // Click second 'Add' button (for Habits)
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Active Habit'), findsOneWidget);
    expect(find.text('Stopped Habit'), findsNothing);
  });
}
