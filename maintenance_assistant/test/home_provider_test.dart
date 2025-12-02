import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maintenance_assistant/src/features/home/presentation/providers/home_provider.dart';
import 'package:maintenance_assistant/src/shared/models/plan_model.dart';

void main() {
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
}
