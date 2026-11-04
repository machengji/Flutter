import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/theme.dart';
import '../providers/home_provider.dart';

class AnalysisSheet extends StatefulWidget {
  const AnalysisSheet({super.key});

  @override
  State<AnalysisSheet> createState() => _AnalysisSheetState();
}

class _AnalysisSheetState extends State<AnalysisSheet> {
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().startAnalysis();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        final isLoading = provider.isAnalyzing;
        final data = provider.analysisData;

        return Container(
          padding: const EdgeInsets.all(28),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: AppDecorations.bottomSheetDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: AppDecorations.dragHandleDecoration,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                        ),
                        child: const AppIcon(
                          type: AppIconType.analytics,
                          size: 24,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        '智能数据分析',
                        style: AppTextStyles.titleLarge,
                      ),
                    ],
                  ),
                  if (!isLoading)
                    GestureDetector(
                      onTap: () => provider.startAnalysis(force: true),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.textHint.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppDecorations.radiusSmall),
                        ),
                        child: const AppIcon(
                          type: AppIconType.refresh,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),

              // Content
              Expanded(
                child: isLoading
                    ? _buildLoadingState()
                    : data == null
                        ? _buildEmptyState()
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPlanPieChart(data['plan_stats']),
                                const SizedBox(height: 36),
                                _buildRadarChart(data['life_dimensions']),
                                const SizedBox(height: 36),
                                _buildHabitBarChart(data['habit_rank']),
                                const SizedBox(height: 36),
                                Divider(color: AppColors.border.withOpacity(0.5)),
                                const SizedBox(height: 20),
                                _buildSummary(data['summary']),
                                const SizedBox(height: 40),
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
    
    final values = keys.map((k) => (dimensions[k] as num? ?? 0).toDouble()).toList();

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
              titleTextStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary),
              getTitle: (index, angle) {
                if (index >= categories.length) return const RadarChartTitle(text: '');
                return RadarChartTitle(text: categories[index]);
              },
              tickCount: 1,
              ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 10),
              tickBorderData: const BorderSide(color: Colors.transparent),
              gridBorderData: BorderSide(color: AppColors.border.withOpacity(0.3), width: 1),
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
            'AI 正在深度分析您的数据...',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1.5.seconds),
          const SizedBox(height: 10),
          Text(
            '生成个性化建议与图表',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanPieChart(Map<String, dynamic>? stats) {
    if (stats == null) return const SizedBox();
    final completed = stats['completed'] as int? ?? 0;
    final ongoing = stats['ongoing'] as int? ?? 0;
    final total = completed + ongoing;

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
          height: 200,
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
                          _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
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
                        title: '${((completed / total) * 100).toStringAsFixed(0)}%',
                        radius: _touchedIndex == 0 ? 60 : 50,
                        titleStyle: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      PieChartSectionData(
                        color: AppColors.info,
                        value: ongoing.toDouble(),
                        title: '${((ongoing / total) * 100).toStringAsFixed(0)}%',
                        radius: _touchedIndex == 1 ? 60 : 50,
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
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, int count) {
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
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
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

    // Take top 5
    final topHabits = habits.take(5).toList();
    int maxCount = 0;
    for (var h in topHabits) {
      if (h['count'] > maxCount) maxCount = h['count'] as int;
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
              '习惯坚持排行 (Top 5)',
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
              maxY: maxCount.toDouble() * 1.2,
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
                          text: '${rod.toY.toInt()} 次',
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
                      if (value.toInt() >= topHabits.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          topHabits[value.toInt()]['name'].toString().length > 4
                              ? '${topHabits[value.toInt()]['name'].toString().substring(0, 3)}...'
                              : topHabits[value.toInt()]['name'],
                          style: AppTextStyles.labelSmall,
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: topHabits.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: (entry.value['count'] as int).toDouble(),
                      gradient: AppColors.secondaryGradient,
                      width: 18,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
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

  Widget _buildSummary(String? summary) {
    if (summary == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('💡', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Text(
              'AI 智能建议',
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
                AppColors.secondary.withOpacity(0.04),
                AppColors.primary.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
            border: Border.all(color: AppColors.secondary.withOpacity(0.1)),
          ),
          child: Text(
            summary,
            style: AppTextStyles.bodyLarge.copyWith(
              height: 1.7,
              color: AppColors.textPrimary,
            ),
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }
}
