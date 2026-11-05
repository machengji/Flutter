import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maintenance_assistant/src/features/home/presentation/providers/home_provider.dart';
import 'package:maintenance_assistant/src/shared/models/plan_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('HomeProvider exportData and importData work correctly', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = HomeProvider();
    
    // Add some data
    await provider.addPlan('Test Plan');
    final originalPlan = provider.plans.first;
    
    // Export
    final jsonString = provider.exportData();
    final Map<String, dynamic> exportedData = jsonDecode(jsonString);
    
    expect(exportedData['plans'], isNotEmpty);
    expect(exportedData['plans'][0]['name'], 'Test Plan');
    
    // Clear data (simulate fresh install)
    await provider.deletePlan(originalPlan.id);
    expect(provider.plans, isEmpty);
    
    // Import
    final success = await provider.importData(jsonString);
    expect(success, true);
    expect(provider.plans, isNotEmpty);
    expect(provider.plans.first.name, 'Test Plan');
    expect(provider.plans.first.id, originalPlan.id);
  });

  test('HomeProvider importData merges without losing existing items and handles BOM', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = HomeProvider();

    // 1. 本地先创建独有任务 Local Only Plan
    await provider.addPlan('Local Only Plan');
    expect(provider.plans.length, 1);
    final localPlanId = provider.plans.first.id;

    // 2. 模拟从外部导入 JSON（包含 BOM 头 \uFEFF，且包含一个新任务 Imported Plan）
    final jsonWithBom = '\uFEFF{"plans":[{"id":"imported-1","name":"Imported Plan","status":"notStarted","subtasks":[]}],"habits":[]}';
    final success = await provider.importData(jsonWithBom);

    expect(success, true);
    // 两个任务都应该保留（Local Only Plan 不被覆盖抹除，Imported Plan 成功加入）
    expect(provider.plans.length, 2);
    expect(provider.plans.any((p) => p.id == localPlanId), true);
    expect(provider.plans.any((p) => p.name == 'Imported Plan'), true);
  });

  test('HomeProvider importData with user actual dataset', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = HomeProvider();

    final file = File(r'C:\Users\Administrator\Downloads\weixing_ios_import.json');
    if (await file.exists()) {
      final content = await file.readAsString();
      final success = await provider.importData(content);
      expect(success, true);
      expect(provider.plans.length, 528);
      expect(provider.habits.length, 28);
      expect(provider.anchors.length, 9);
      expect(provider.notifications.length, 267);
    }
  });
}
