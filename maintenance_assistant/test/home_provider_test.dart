import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maintenance_assistant/src/features/home/presentation/providers/home_provider.dart';
import 'package:maintenance_assistant/src/shared/models/celebration_model.dart';

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

  test('Multi-level sub-plans auto-promote leaf actions, keep sibling order, and cascade on complete/delete', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = HomeProvider();
    await Future.delayed(const Duration(milliseconds: 20));

    // 1. 创建两个顶层目标：独立目标 与 待拆解大目标
    await provider.addPlan('普通独立任务');
    await provider.addPlan('准备马拉松');
    final rootGoal = provider.ongoingPlans.firstWhere((p) => p.name == '准备马拉松');

    // 2. 在「准备马拉松」下连续添加两个子任务（应保持 1 -> 2 正序，且自动排在最前面，父任务自动退后）
    final sub1 = await provider.addSubPlan(rootGoal.id, '买跑鞋');
    final sub2 = await provider.addSubPlan(rootGoal.id, '制定训练表');
    expect(sub1, isNotNull);
    expect(sub2, isNotNull);

    // 验证排序：[买跑鞋, 制定训练表, 普通独立任务, 准备马拉松]
    expect(
      provider.ongoingPlans.map((p) => p.name).toList(),
      ['买跑鞋', '制定训练表', '普通独立任务', '准备马拉松'],
    );
    expect(provider.getSubPlanProgress(rootGoal.id), (completed: 0, total: 2));

    // 3. 继续对「买跑鞋」做二级拆解（孙任务层级更深，应排在 1 级子任务前面）
    final grandSub = await provider.addSubPlan(sub1!.id, '测足弓选尺码');
    expect(grandSub, isNotNull);
    expect(provider.getEffectiveDecompositionDepth(grandSub!), 2);

    // 此时「买跑鞋」因有未完成下级退入推进中父层，2级孙任务「测足弓选尺码」排第一，1级叶子「制定训练表」排第二
    expect(
      provider.ongoingPlans.map((p) => p.name).toList(),
      ['测足弓选尺码', '制定训练表', '普通独立任务', '买跑鞋', '准备马拉松'],
    );

    // 4. 完成孙任务「测足弓选尺码」-> 1级父任务「买跑鞋」下属已清空，重新成为可执行叶子排回最前（不自动完成）
    await provider.togglePlanStatus(grandSub.id);
    expect(provider.plans.firstWhere((p) => p.id == sub1.id).status, '未开始');
    expect(
      provider.ongoingPlans.map((p) => p.name).toList(),
      ['买跑鞋', '制定训练表', '普通独立任务', '准备马拉松'],
    );

    // 5. 完成全部直接子任务后，顶层父任务「准备马拉松」不自动完成，但自动浮到普通独立任务之前等待收尾确认
    await provider.togglePlanStatus(sub1.id);
    await provider.togglePlanStatus(sub2!.id);
    expect(provider.plans.firstWhere((p) => p.id == rootGoal.id).status, '未开始');
    expect(provider.getSubPlanProgress(rootGoal.id), (completed: 2, total: 2));
    expect(
      provider.ongoingPlans.map((p) => p.name).toList(),
      ['准备马拉松', '普通独立任务'],
    );

    // 6. 测试直接勾选父任务完成 -> 级联完成所有未完成后代并解绑锚点
    final sub3 = await provider.addSubPlan(rootGoal.id, '报名参赛');
    final grandSub3 = await provider.addSubPlan(sub3!.id, '上传体检报告');
    await provider.addAnchor('晚间复盘', '21:00');
    final anchor = provider.anchors.first;
    await provider.bindPlanToAnchor(anchor.id, grandSub3!.id);
    expect(anchor.planIds.contains(grandSub3.id), true);

    await provider.togglePlanStatus(rootGoal.id);
    expect(provider.plans.firstWhere((p) => p.id == rootGoal.id).status, '已完成');
    expect(provider.plans.firstWhere((p) => p.id == sub3.id).status, '已完成');
    expect(provider.plans.firstWhere((p) => p.id == grandSub3.id).status, '已完成');
    expect(anchor.planIds.contains(grandSub3.id), false);

    // 7. 测试直接删除父任务 -> 级联删除整棵子树，不留孤儿任务
    await provider.deletePlan(rootGoal.id);
    expect(provider.plans.map((p) => p.name).toList(), ['普通独立任务']);
  });

  test('Shine celebration dual-mode milestones (first win, light daily, goal achieved, anchor cleared)', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = HomeProvider();
    await Future.delayed(const Duration(milliseconds: 50));

    await provider.addHabit('喝温水');
    final habitWater = provider.habits.first;

    // 1. 当日首次完成微行动 -> 高光全屏庆祝「今日首胜」
    await provider.checkHabit(habitWater.id);
    final firstEvent = provider.celebrationNotifier.value;
    expect(firstEvent, isNotNull);
    expect(firstEvent!.isGrand, true);
    expect(firstEvent.milestoneTag, '今日首胜');
    expect(provider.todayShineCount, 1);

    // 2. 随后普通打卡 -> 日常无阻断轻庆祝（isGrand == false）
    await provider.checkHabit(habitWater.id);
    final secondEvent = provider.celebrationNotifier.value;
    expect(secondEvent, isNotNull);
    expect(secondEvent!.isGrand, false);
    expect(secondEvent.milestoneTag, isNull);
    expect(provider.todayShineCount, 2);

    // 3. 大目标分解：完成单个子任务为轻庆祝，完成带子任务的父任务为「目标达成」高光庆祝
    await provider.addPlan('整理书房');
    final parentGoal = provider.plans.firstWhere((p) => p.name == '整理书房');
    final subTask = await provider.addSubPlan(parentGoal.id, '清空书桌杂物');
    expect(subTask, isNotNull);

    await provider.togglePlanStatus(subTask!.id);
    expect(provider.celebrationNotifier.value!.isGrand, false);

    await provider.togglePlanStatus(parentGoal.id);
    expect(provider.celebrationNotifier.value!.isGrand, true);
    expect(provider.celebrationNotifier.value!.milestoneTag, '目标达成');

    // 4. 时间锚点清空：完成第一项时仍有剩余为轻庆祝，清空最后一项时触发「锚点全清」高光庆祝
    await provider.addPlan('准备明日衣物');
    final anchorPlan = provider.plans.firstWhere((p) => p.name == '准备明日衣物');
    await provider.addHabit('睡前拉伸');
    final anchorHabit = provider.habits.firstWhere((h) => h.name == '睡前拉伸');
    await provider.addAnchor('睡前仪式', '22:30');
    final nightAnchor = provider.anchors.firstWhere((a) => a.name == '睡前仪式');

    await provider.bindPlanToAnchor(nightAnchor.id, anchorPlan.id);
    await provider.bindHabitToAnchor(nightAnchor.id, anchorHabit.id);

    await provider.togglePlanStatus(anchorPlan.id);
    expect(provider.celebrationNotifier.value!.isGrand, false);

    await provider.checkHabit(anchorHabit.id);
    expect(provider.celebrationNotifier.value!.isGrand, true);
    expect(provider.celebrationNotifier.value!.milestoneTag, '锚点全清');
  });

  test('Shine jar free celebration, custom affirmations priority, style modes, and backup/restore', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = HomeProvider();
    await Future.delayed(const Duration(milliseconds: 50));

    await provider.addCustomAffirmation('奖励自己一杯热拿铁');
    await provider.setCelebrationStyleMode(CelebrationStyleMode.sincere);
    await provider.setCelebrationSoundEnabled(false);

    // 真随机比例盲盒抽取：在自定义庆祝语与真诚肯定语间随机抽取，且自由练习不污染首页浮层通知器
    final freePayload = await provider.celebrateFreely();
    expect(
      freePayload.quote == '奖励自己一杯热拿铁' ||
          CelebrationLibrary.sincereAffirmations.contains(freePayload.quote),
      true,
    );
    expect(freePayload.milestoneTag, '夸夸自己');
    expect(provider.celebrationNotifier.value, isNull);
    expect(provider.totalShineCount, 1);

    // 连续多次随机抽样验证自定义庆祝语确实会按比例命中
    bool hitCustom = freePayload.quote == '奖励自己一杯热拿铁';
    for (int i = 0; i < 30 && !hitCustom; i++) {
      final sample = await provider.celebrateFreely();
      if (sample.quote == '奖励自己一杯热拿铁') {
        hitCustom = true;
      }
    }
    expect(hitCustom, true);

    final exported = provider.exportData();

    SharedPreferences.setMockInitialValues({});
    final restoredProvider = HomeProvider();
    await Future.delayed(const Duration(milliseconds: 50));
    final ok = await restoredProvider.importData(exported);

    expect(ok, true);
    expect(restoredProvider.totalShineCount, greaterThanOrEqualTo(1));
    expect(restoredProvider.customAffirmations, ['奖励自己一杯热拿铁']);
    expect(restoredProvider.celebrationStyleMode, CelebrationStyleMode.sincere);
    expect(restoredProvider.celebrationSoundEnabled, false);
  });
}



