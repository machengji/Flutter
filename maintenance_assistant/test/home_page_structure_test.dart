import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:maintenance_assistant/src/features/home/presentation/pages/home_page.dart';
import 'package:maintenance_assistant/src/features/home/presentation/providers/home_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('HomePage uses CustomScrollView and Slivers', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => HomeProvider(),
          child: const HomePage(),
        ),
      ),
    );
    
    // Disable animations for testing
    // Animate.restartOnHotReload = false; // This might not be enough

    // Verify CustomScrollView exists
    expect(find.byType(CustomScrollView), findsOneWidget);

    // Verify SliverList exists (indicating lazy loading structure)
    // Note: Since we have multiple sections, we might find multiple SliverLists or SliverPaddings
    // We just want to ensure the main content structure isn't a simple ListView anymore.
    expect(find.descendant(of: find.byType(CustomScrollView), matching: find.byType(ListView)), findsNothing);
    
    // Add a plan to verify rendering
    final context = tester.element(find.byType(HomePage));
    // Use runAsync to handle potential timer issues if needed, but pumpAndSettle should usually work
    // for simple animations.
    await context.read<HomeProvider>().addPlan('Test Plan');
    
    // Pump past the 900ms warmup and 500ms welcome timers
    await tester.pump(const Duration(milliseconds: 1000));
    
    expect(find.text('Test Plan'), findsOneWidget);
  });

  testWidgets('PlanCard inline sub-plan input adds sub-plans continuously and promotes them to top', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'has_seen_welcome': true});

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => HomeProvider(),
          child: const HomePage(),
        ),
      ),
    );

    final context = tester.element(find.byType(HomePage));
    final provider = context.read<HomeProvider>();
    await provider.addPlan('年度体检');
    await tester.pump(const Duration(milliseconds: 500));

    // 点击卡片展开原地子任务输入框
    await tester.tap(find.text('年度体检'));
    await tester.pump(const Duration(milliseconds: 350));

    final subInput = find.byType(TextField);
    expect(subInput, findsOneWidget);

    // 连续回车录入两条子任务
    await tester.enterText(subInput, '预约医院');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 200));

    await tester.enterText(subInput, '前一晚空腹');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 350));

    // 验证数据层顺序：两条子任务排在父任务之前，且父任务显示 0/2 进度微标
    expect(
      provider.ongoingPlans.map((p) => p.name).toList(),
      ['预约医院', '前一晚空腹', '年度体检'],
    );
    expect(find.text('0/2'), findsOneWidget);
  });
}
