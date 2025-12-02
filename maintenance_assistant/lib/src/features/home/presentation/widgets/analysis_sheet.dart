import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../shared/services/deepseek_service.dart';
import '../providers/home_provider.dart';

class AnalysisSheet extends StatefulWidget {
  const AnalysisSheet({super.key});

  @override
  State<AnalysisSheet> createState() => _AnalysisSheetState();
}

class _AnalysisSheetState extends State<AnalysisSheet> {
  final DeepSeekService _deepSeekService = DeepSeekService();
  Map<String, dynamic>? _analysisData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  Future<void> _startAnalysis() async {
    final data = await context.read<HomeProvider>().getAnalysisData();
    final result = await _deepSeekService.analyzeData(data);
    if (mounted) {
      setState(() {
        _analysisData = result;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B4EFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics, color: Color(0xFF6B4EFF)),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI 数据分析',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFF6B4EFF),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'DeepSeek 正在分析最近30天的数据...',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.5),
                            fontSize: 14,
                          ),
                        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1.5.seconds),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Charts Section
                        if (_analysisData != null) ...[
                          _buildHabitChart(_analysisData!['habit_rank']),
                          const SizedBox(height: 24),
                          _buildPlanStats(_analysisData!['plan_stats']),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                        ],

                        // Summary Text
                        Text(
                          _analysisData?['summary'] ?? '无数据',
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Color(0xFF1D1D1F),
                          ),
                        ).animate().fadeIn(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitChart(List<dynamic>? habits) {
    if (habits == null || habits.isEmpty) return const SizedBox();

    // Find max for scaling
    int maxCount = 1;
    for (var h in habits) {
      if (h['count'] > maxCount) maxCount = h['count'];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🔥 习惯坚持排行 (30天)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...habits.map((h) {
          final double percentage = (h['count'] as int) / maxCount;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    h['name'],
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          Container(
                            height: 24,
                            width: constraints.maxWidth * percentage,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6B4EFF), Color(0xFF9775FA)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ).animate().slideX(begin: -1, end: 0, duration: 800.ms, curve: Curves.easeOutQuart),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${h['count']}次',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPlanStats(Map<String, dynamic>? stats) {
    if (stats == null) return const SizedBox();

    final total = stats['total'] as int? ?? 1;
    final completed = stats['completed'] as int? ?? 0;
    final ongoing = stats['ongoing'] as int? ?? 0;
    final double completionRate = total == 0 ? 0 : completed / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📅 计划完成率', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  '${(completionRate * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF007AFF)),
                ),
                Text(
                  '进行中: $ongoing  已完成: $completed',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: completionRate,
              strokeWidth: 8,
              backgroundColor: Colors.grey[200],
              color: const Color(0xFF007AFF),
            ),
          ),
        ],
      ),
    );
  }
}
