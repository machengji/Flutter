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

      // 验证全量数据分析
      final analysisData = await provider.getAnalysisData(allData: true);
      expect(analysisData['scope'], 'all_data');
      expect(analysisData['plans_overview']['total'], 528);
      expect(analysisData['habits_overview']['total_habits'], 28);
      expect(analysisData['anchors_overview'].length, 9);

      // 验证分享文案生成
      final shareAll = provider.generateCompletedShareText();
      expect(shareAll.contains('微行动 · 我的成长与成就战报'), true);
      expect(shareAll.contains('累计已达成梦想与计划'), true);

      final shareSingle = provider.generateSinglePlanShareText(provider.plans.first);
      expect(shareSingle.contains('微行动 · 成就捷报'), true);
      expect(shareSingle.contains(provider.plans.first.name), true);
    }
  });

  test('HomeProvider archive, unarchive and toggleArchive work as expected', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = HomeProvider();

    await provider.addPlan('聚焦任务');
    await provider.addPlan('长尾待定任务');
    expect(provider.ongoingPlans.length, 2);
    expect(provider.archivedPlans.length, 0);

    final archiveTargetId = provider.ongoingPlans.firstWhere((p) => p.name == '长尾待定任务').id;

    // 1. 归档
    await provider.archivePlan(archiveTargetId);
    expect(provider.ongoingPlans.length, 1);
    expect(provider.ongoingPlans.first.name, '聚焦任务');
    expect(provider.archivedPlans.length, 1);
    expect(provider.archivedPlans.first.name, '长尾待定任务');

    // 2. 切换归档（从已归档切换回进行中）
    await provider.toggleArchivePlan(archiveTargetId);
    expect(provider.ongoingPlans.length, 2);
    expect(provider.archivedPlans.length, 0);

    // 3. 再次切换（从进行中归档）
    await provider.toggleArchivePlan(archiveTargetId);
    expect(provider.ongoingPlans.length, 1);
    expect(provider.archivedPlans.length, 1);

    // 4. 显式取消归档
    await provider.unarchivePlan(archiveTargetId);
    expect(provider.ongoingPlans.length, 2);
    expect(provider.archivedPlans.length, 0);
  });

  test('HomeProvider deletePlan, deleteAnchor and calendar cleanup handle eco logic gracefully', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = HomeProvider();

    // 1. 添加并删除计划
    await provider.addPlan('即将被删除的计划');
    expect(provider.plans.any((p) => p.name == '即将被删除的计划'), true);
    final planId = provider.plans.firstWhere((p) => p.name == '即将被删除的计划').id;
    await provider.deletePlan(planId);
    expect(provider.plans.any((p) => p.id == planId), false);

    // 2. 添加并删除锚点
    await provider.addAnchor('下午休息', '14:30');
    expect(provider.anchors.any((a) => a.name == '下午休息'), true);
    final anchorId = provider.anchors.firstWhere((a) => a.name == '下午休息').id;
    await provider.deleteAnchor(anchorId);
    expect(provider.anchors.any((a) => a.id == anchorId), false);

    // 3. 一键清理日历锚点
    final cleanResult = await provider.clearAllAnchorCalendarEvents();
    expect(cleanResult, isNotNull);
  });

  test('Anchor reminder state persists, filters today checked habits, and calendar backfill skips missing timestamps', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = HomeProvider();
    await Future.delayed(const Duration(milliseconds: 20));

    await provider.addAnchor('早起喝水', '07:30');
    final anchor = provider.anchors.firstWhere((a) => a.name == '早起喝水');
    expect(anchor.isReminderEnabled, true);

    await provider.addPlan('整理书桌');
    await provider.addHabit('喝温水');
    final plan = provider.plans.firstWhere((p) => p.name == '整理书桌');
    final habit = provider.habits.firstWhere((h) => h.name == '喝温水');

    await provider.bindPlanToAnchor(anchor.id, plan.id);
    await provider.bindHabitToAnchor(anchor.id, habit.id);

    expect(provider.getAnchorBaselineItemNames(anchor), ['[计划] 整理书桌', '[习惯] 喝温水']);
    expect(provider.getAnchorTodayRemainingItemNames(anchor), ['[计划] 整理书桌', '[习惯] 喝温水']);

    // 今日打卡习惯后，今日待办提醒过滤掉已打卡习惯，但跨日基准清单仍保留该习惯
    await provider.checkHabit(habit.id);
    expect(provider.getHabitTodayCheckCount(habit), 1);
    expect(provider.getAnchorTodayRemainingItemNames(anchor), ['[计划] 整理书桌']);
    expect(provider.getAnchorBaselineItemNames(anchor), ['[计划] 整理书桌', '[习惯] 喝温水']);

    // 暂停提醒并验证导出导入持久化保留
    await provider.toggleAnchorReminder(anchor.id, false);
    expect(anchor.isReminderEnabled, false);

    final exported = provider.exportData();
    await provider.deleteAnchor(anchor.id);
    expect(provider.anchors.isEmpty, true);

    await provider.importData(exported, mergeWithExisting: false);
    expect(provider.anchors.first.isReminderEnabled, false);

    // 验证历史旧计划若缺失真实 completeTime，绝不伪造时间戳，如实提示跳过
    final provider2 = HomeProvider();
    await Future.delayed(const Duration(milliseconds: 20));
    await provider2.importData(
      jsonEncode({
        'plans': [
          {
            'id': 'legacy_p1',
            'name': '无完成时间的历史计划',
            'status': '已完成',
            'createTime': 1700000000000,
          }
        ],
        'habits': [],
      }),
      mergeWithExisting: false,
    );
    final backfillRes = await provider2.syncCompletedPlansToCalendar();
    expect(backfillRes['success'], true);
    expect(backfillRes['recordedCount'], 0);
    expect((backfillRes['message'] as String).contains('未记录完成时间'), true);
  });
}


