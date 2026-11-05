import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maintenance_assistant/src/features/home/presentation/providers/home_provider.dart';
import 'package:maintenance_assistant/src/features/home/presentation/widgets/archive_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ArchiveSheet displays empty state and can restore plan', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final provider = HomeProvider();

    // 1. 无归档任务时的渲染
    await tester.pumpWidget(
      ChangeNotifierProvider<HomeProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(
            body: ArchiveSheet(),
          ),
        ),
      ),
    );

    expect(find.text('暂无已归档任务'), findsOneWidget);

    // 2. 添加并归档一个任务
    await provider.addPlan('待恢复的长尾任务');
    final plan = provider.ongoingPlans.first;
    await provider.archivePlan(plan.id);

    await tester.pump();
    expect(find.text('待恢复的长尾任务'), findsOneWidget);
    expect(find.text('恢复重点'), findsOneWidget);

    // 3. 点击“恢复重点”
    await tester.tap(find.text('恢复重点'));
    await tester.pump();

    // 此时归档列表重新变为空
    expect(provider.archivedPlans, isEmpty);
    expect(provider.ongoingPlans.any((p) => p.name == '待恢复的长尾任务'), true);
    expect(find.text('暂无已归档任务'), findsOneWidget);
  });
}
