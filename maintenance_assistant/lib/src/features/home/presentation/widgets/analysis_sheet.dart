import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/models/plan_model.dart';
import '../providers/home_provider.dart';

class AnalysisSheet extends StatefulWidget {
  final Plan? initialFocusPlan;

  const AnalysisSheet({super.key, this.initialFocusPlan});

  @override
  State<AnalysisSheet> createState() => _AnalysisSheetState();
}

class _AnalysisSheetState extends State<AnalysisSheet> {
  int _touchedIndex = -1;
  Plan? _selectedOngoingPlan;

  @override
  void initState() {
    super.initState();
    _selectedOngoingPlan = widget.initialFocusPlan;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<HomeProvider>();
      provider.startAnalysis();
      if (_selectedOngoingPlan != null) {
        provider.analyzeSingleTask(_selectedOngoingPlan!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        final isLoading = provider.isAnalyzing;
        final data = provider.analysisData;
        final isAllScope = provider.isAllDataScope;
        final totalPlans = provider.plans.length;
        final completedPlans =
            provider.plans.where((p) => p.status == '已完成').toList();
        completedPlans.sort(
            (a, b) => (b.completeTime ?? 0).compareTo(a.completeTime ?? 0));
        final ongoingPlans =
            provider.plans.where((p) => p.status != '已完成').toList();

        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.92,
          ),
          decoration: AppDecorations.bottomSheetDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: AppDecorations.dragHandleDecoration,
                ),
              ),
              const SizedBox(height: 18),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.12),
                          borderRadius:
                              BorderRadius.circular(AppDecorations.radiusMedium),
                        ),
                        child: const AppIcon(
                          type: AppIconType.analytics,
                          size: 22,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI 深度数据分析', style: AppTextStyles.titleLarge),
                          Text(
                            isAllScope ? '全量 $totalPlans 项数据沉淀' : '聚焦近 30 天表现',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!isLoading)
                    Row(
                      children: [
                        IconButton(
                          tooltip: '分享已完成成就战报',
                          onPressed: completedPlans.isEmpty
                              ? null
                              : () async {
                                  HapticFeedback.mediumImpact();
                                  final ok = await provider
                                      .shareCompletedMilestones();
                                  if (context.mounted && ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('已唤起分享或复制成就战报 ✨'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                },
                          icon: const AppIcon(
                            type: AppIconType.share,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        IconButton(
                          tooltip: '重新深度分析',
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            provider.startAnalysis(force: true);
                          },
                          icon: const AppIcon(
                            type: AppIconType.refresh,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Scope Selector Tab: 全部数据 vs 近30天
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border.withOpacity(0.6)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildScopeButton(
                        label: '全部数据 ($totalPlans 项)',
                        isSelected: isAllScope,
                        onTap: () {
                          if (!isAllScope) {
                            HapticFeedback.selectionClick();
                            provider.setAnalysisScope(true);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: _buildScopeButton(
                        label: '近 30 天表现',
                        isSelected: !isAllScope,
                        onTap: () {
                          if (isAllScope) {
                            HapticFeedback.selectionClick();
                            provider.setAnalysisScope(false);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Content Body
              Expanded(
                child: isLoading
                    ? _buildLoadingState()
                    : data == null
                        ? _buildEmptyState()
                        : SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1. 已完成任务里程碑成就战报与一键分享卡片
                                _buildCompletedMilestonesShareCard(
                                  context: context,
                                  provider: provider,
                                  completedPlans: completedPlans,
                                  milestoneSummary:
                                      data['completed_milestones_summary'],
                                ),
                                const SizedBox(height: 28),

                                // 2. 计划全景概览 (饼图 + 统计)
                                _buildPlanPieChart(
                                  stats: data['plan_stats'],
                                  realTotal: totalPlans,
                                  realCompleted: completedPlans.length,
                                  realOngoing: ongoingPlans.length,
                                ),
                                const SizedBox(height: 32),

                                // 3. 生命六要素平衡雷达图
                                _buildRadarChart(data['life_dimensions']),
                                const SizedBox(height: 32),

                                // 4. 习惯坚持排行榜
                                _buildHabitBarChart(data['habit_rank']),
                                const SizedBox(height: 32),

                                // 5. 正在进行的任务 · AI 专项攻克诊断区
                                _buildOngoingTasksDiagnosisSection(
                                  context: context,
                                  provider: provider,
                                  ongoingPlans: ongoingPlans,
                                ),
                                const SizedBox(height: 32),

                                // 6. AI 宏观分析与突破建议
                                _buildSummary(
                                  summary: data['summary'],
                                  recommendation: data['focus_recommendation'],
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScopeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  /// 已完成任务里程碑成就战报与一键分享卡片
  Widget _buildCompletedMilestonesShareCard({
    required BuildContext context,
    required HomeProvider provider,
    required List<Plan> completedPlans,
    String? milestoneSummary,
  }) {
    final count = completedPlans.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.success.withOpacity(0.12),
            AppColors.primary.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDecorations.radiusLarge),
        border: Border.all(color: AppColors.success.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🏆', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 10),
                  Text('已完成成就战报', style: AppTextStyles.titleMedium),
                ],
              ),
              ElevatedButton.icon(
                onPressed: count == 0
                    ? null
                    : () async {
                        HapticFeedback.mediumImpact();
                        final ok = await provider.shareCompletedMilestones();
                        if (context.mounted && ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('已完成战报分享成功 ✨'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                icon: const AppIcon(
                  type: AppIconType.share,
                  size: 16,
                  color: Colors.white,
                ),
                label: const Text('分享战报'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: AppTextStyles.labelMedium,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '累计已达成 $count 项梦想与行动！${milestoneSummary != null && milestoneSummary.isNotEmpty ? "「$milestoneSummary」" : "持续的微小习惯正在沉淀非凡力量。"}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          if (completedPlans.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: completedPlans.take(8).length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final p = completedPlans[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      await provider.shareSinglePlan(p);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.success.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle,
                              size: 14, color: AppColors.success),
                          const SizedBox(width: 6),
                          Text(
                            p.name.length > 8
                                ? '${p.name.substring(0, 7)}…'
                                : p.name,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const AppIcon(
                            type: AppIconType.share,
                            size: 12,
                            color: AppColors.textHint,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 正在进行的任务 · AI 专项攻克诊断区
  Widget _buildOngoingTasksDiagnosisSection({
    required BuildContext context,
    required HomeProvider provider,
    required List<Plan> ongoingPlans,
  }) {
    if (ongoingPlans.isEmpty) return const SizedBox();

    _selectedOngoingPlan ??= ongoingPlans.first;
    final currentPlan = _selectedOngoingPlan!;
    final isAnalyzingTask = provider.isTaskAnalyzing(currentPlan.id);
    final taskDiagnosis = provider.getTaskAnalysis(currentPlan.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Text('聚焦任务 · AI 专项攻克诊断', style: AppTextStyles.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '点击选择你当前正在执行的任务，获取定制攻克动线：',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 14),

        // 任务水平选择列表
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: ongoingPlans.take(12).length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final p = ongoingPlans[index];
              final isSelected = p.id == currentPlan.id;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedOngoingPlan = p);
                  provider.analyzeSingleTask(p);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border.withOpacity(0.6),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      p.name.length > 8 ? '${p.name.substring(0, 7)}…' : p.name,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // 任务专项诊断详情卡片
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
            border: Border.all(color: AppColors.primary.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isAnalyzingTask
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('AI 正在深度剖析「${currentPlan.name}」的破局路径…',
                            style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                )
              : taskDiagnosis == null
                  ? Center(
                      child: TextButton.icon(
                        onPressed: () => provider.analyzeSingleTask(currentPlan),
                        icon: const AppIcon(
                            type: AppIconType.explore, size: 18),
                        label: Text('点击生成「${currentPlan.name}」的攻克诊断'),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                currentPlan.name,
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                taskDiagnosis['difficulty_level'] ?? '中度攻坚',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (taskDiagnosis['diagnosis'] != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            '💡 核心卡点：${taskDiagnosis['diagnosis']}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                        if (taskDiagnosis['recommended_anchor'] != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('⚓️', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '推荐时间锚点：${taskDiagnosis['recommended_anchor']}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.info,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Text('🚀 3 步破局路线：', style: AppTextStyles.labelMedium),
                        const SizedBox(height: 8),
                        ...((taskDiagnosis['breakthrough_steps']
                                    as List<dynamic>?) ??
                                [])
                            .map((step) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      text: '${step['step']}：',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '${step['action']}',
                                          style:
                                              AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const AppIcon(
              type: AppIconType.analytics,
              size: 48,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '暂无数据',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '添加一些计划和习惯后再来分析吧',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildRadarChart(Map<String, dynamic>? dimensions) {
    if (dimensions == null) return const SizedBox();

    final categories = ['健康', '家庭', '事业', '财富', '社交', '成长'];
    final keys = ['health', 'family', 'career', 'wealth', 'social', 'growth'];

    final values =
        keys.map((k) => (dimensions[k] as num? ?? 0).toDouble()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🕸️', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Text(
              '生命六要素平衡分析',
              style: AppTextStyles.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 250,
          child: RadarChart(
            RadarChartData(
              radarTouchData: RadarTouchData(enabled: false),
              dataSets: [
                RadarDataSet(
                  fillColor: AppColors.secondary.withOpacity(0.2),
                  borderColor: AppColors.secondary,
                  entryRadius: 3,
                  dataEntries: values.map((v) => RadarEntry(value: v)).toList(),
                  borderWidth: 2,
                ),
              ],
              radarBackgroundColor: Colors.transparent,
              borderData: FlBorderData(show: false),
              radarBorderData: const BorderSide(color: Colors.transparent),
              titlePositionPercentageOffset: 0.2,
              titleTextStyle: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.textPrimary),
              getTitle: (index, angle) {
                if (index >= categories.length) {
                  return const RadarChartTitle(text: '');
                }
                return RadarChartTitle(text: categories[index]);
              },
              tickCount: 1,
              ticksTextStyle:
                  const TextStyle(color: Colors.transparent, fontSize: 10),
              tickBorderData: const BorderSide(color: Colors.transparent),
              gridBorderData:
                  BorderSide(color: AppColors.border.withOpacity(0.3), width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: AppColors.secondary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'AI 正在深度分析您的全量数据...',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1.5.seconds),
          const SizedBox(height: 10),
          Text(
            '提炼生命六要素与成长破局路径',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanPieChart({
    required Map<String, dynamic>? stats,
    required int realTotal,
    required int realCompleted,
    required int realOngoing,
  }) {
    final completed =
        (stats?['completed'] as int?) ?? realCompleted;
    final ongoing =
        (stats?['ongoing'] as int?) ?? realOngoing;
    final total = completed + ongoing > 0 ? completed + ongoing : realTotal;

    if (total == 0) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('📊', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Text(
              '计划完成概览',
              style: AppTextStyles.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 190,
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(
                        color: AppColors.success,
                        value: completed.toDouble(),
                        title:
                            '${((completed / total) * 100).toStringAsFixed(0)}%',
                        radius: _touchedIndex == 0 ? 58 : 48,
                        titleStyle: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      PieChartSectionData(
                        color: AppColors.info,
                        value: ongoing.toDouble(),
                        title:
                            '${((ongoing / total) * 100).toStringAsFixed(0)}%',
                        radius: _touchedIndex == 1 ? 58 : 48,
                        titleStyle: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendItem(AppColors.success, '已完成', completed),
                  const SizedBox(height: 14),
                  _buildLegendItem(AppColors.info, '进行中', ongoing),
                  const SizedBox(height: 14),
                  _buildLegendItem(
                    AppColors.secondary,
                    '完成率',
                    null,
                    customText:
                        '${((completed / total) * 100).toStringAsFixed(1)}%',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, int? count,
      {String? customText}) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            customText ?? '$count',
            style: AppTextStyles.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHabitBarChart(List<dynamic>? habits) {
    if (habits == null || habits.isEmpty) return const SizedBox();

    final topHabits = habits.take(6).toList();
    int maxCount = 0;
    for (var h in topHabits) {
      final c = (h['total_checks'] ?? h['count'] ?? 0) as int;
      if (c > maxCount) maxCount = c;
    }
    if (maxCount == 0) maxCount = 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Text(
              '习惯坚持排行榜 (Top ${topHabits.length})',
              style: AppTextStyles.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxCount.toDouble() * 1.25,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => AppColors.textPrimary,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${topHabits[groupIndex]['name']}\n',
                      AppTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: '${rod.toY.toInt()} 次打卡',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value.toInt() >= topHabits.length) {
                        return const SizedBox();
                      }
                      final name =
                          topHabits[value.toInt()]['name'].toString();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          name.length > 4
                              ? '${name.substring(0, 3)}…'
                              : name,
                          style: AppTextStyles.labelSmall,
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: topHabits.asMap().entries.map((entry) {
                final count =
                    (entry.value['total_checks'] ?? entry.value['count'] ?? 0)
                        as int;
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: count.toDouble(),
                      gradient: AppColors.secondaryGradient,
                      width: 18,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary({String? summary, String? recommendation}) {
    if (summary == null && recommendation == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('💡', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Text(
              'AI 智能洞察与突破建议',
              style: AppTextStyles.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondary.withOpacity(0.05),
                AppColors.primary.withOpacity(0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
            border: Border.all(color: AppColors.secondary.withOpacity(0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (summary != null)
                Text(
                  summary,
                  style: AppTextStyles.bodyLarge.copyWith(
                    height: 1.7,
                    color: AppColors.textPrimary,
                  ),
                ),
              if (recommendation != null && recommendation.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🚀', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          recommendation,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }
}
