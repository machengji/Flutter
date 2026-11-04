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
    // We just want to ensure the structure isn't a simple ListView anymore.
    expect(find.byType(ListView), findsNothing);
    
    // Add a plan to verify rendering
    final context = tester.element(find.byType(HomePage));
    // Use runAsync to handle potential timer issues if needed, but pumpAndSettle should usually work
    // for simple animations.
    await context.read<HomeProvider>().addPlan('Test Plan');
    
    // Pump a few frames to let the list update, ignoring the infinite animation
    await tester.pump();
    await tester.pump();
    
    expect(find.text('Test Plan'), findsOneWidget);
  });
}
