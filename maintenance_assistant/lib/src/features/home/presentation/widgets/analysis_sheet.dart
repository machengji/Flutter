import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
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
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B4EFF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.analytics_rounded, color: Color(0xFF6B4EFF), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '智能数据分析',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                    ],
                  ),
                  if (!isLoading)
                    IconButton(
                      onPressed: () => provider.startAnalysis(force: true),
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xFF86868B)),
                      tooltip: '重新生成',
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Content
              Expanded(
                child: isLoading
                    ? _buildLoadingState()
                    : data == null
                        ? const Center(child: Text('暂无数据'))
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPlanPieChart(data['plan_stats']),
                                const SizedBox(height: 32),
                                _buildHabitBarChart(data['habit_rank']),
                                const SizedBox(height: 32),
                                const Divider(),
                                const SizedBox(height: 16),
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF6B4EFF)),
          const SizedBox(height: 24),
          Text(
            'AI 正在深度分析您的数据...',
            style: TextStyle(
              color: Colors.black.withOpacity(0.6),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1.5.seconds),
          const SizedBox(height: 8),
          Text(
            '生成个性化建议与图表',
            style: TextStyle(
              color: Colors.black.withOpacity(0.4),
              fontSize: 14,
            ),
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
        const Text(
          '📊 计划完成概览',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        color: const Color(0xFF4CD964),
                        value: completed.toDouble(),
                        title: '${((completed / total) * 100).toStringAsFixed(0)}%',
                        radius: _touchedIndex == 0 ? 60 : 50,
                        titleStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        color: const Color(0xFF007AFF),
                        value: ongoing.toDouble(),
                        title: '${((ongoing / total) * 100).toStringAsFixed(0)}%',
                        radius: _touchedIndex == 1 ? 60 : 50,
                        titleStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                  _buildLegendItem(const Color(0xFF4CD964), '已完成', completed),
                  const SizedBox(height: 12),
                  _buildLegendItem(const Color(0xFF007AFF), '进行中', ongoing),
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
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1D1D1F)),
        ),
        const SizedBox(width: 8),
        Text(
          '($count)',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1D1D1F)),
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
        const Text(
          '🔥 习惯坚持排行 (Top 5)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  getTooltipColor: (group) => Colors.blueGrey,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${topHabits[groupIndex]['name']}\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: '${rod.toY.toInt()} 次',
                          style: const TextStyle(
                            color: Colors.yellow,
                            fontSize: 12,
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
                          style: const TextStyle(
                            color: Color(0xFF86868B),
                            fontSize: 12,
                          ),
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
                      color: const Color(0xFF6B4EFF),
                      width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
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
        const Text(
          '💡 AI 智能建议',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Text(
            summary,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Color(0xFF424245),
            ),
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }
}
