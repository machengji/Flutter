import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/services/deepseek_service.dart';

class DetailSheet extends StatefulWidget {
  final String title;
  final String planName;
  final Function(String) onTagSelected;

  const DetailSheet({
    super.key,
    this.title = 'AI 任务诊断与拆解',
    required this.planName,
    required this.onTagSelected,
  });

  @override
  State<DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<DetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DeepSeekService _deepSeekService = DeepSeekService();

  // Tab 1: AI 单任务专项深度诊断
  bool _isLoadingDiagnosis = true;
  Map<String, dynamic>? _diagnosisData;
  String? _diagnosisError;

  // Tab 2: 微习惯拆解标签
  bool _isLoadingTags = true;
  List<String> _tags = [];
  final Set<String> _selectedTags = {};
  String? _tagError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDiagnosis();
    _loadTags();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDiagnosis() async {
    setState(() {
      _isLoadingDiagnosis = true;
      _diagnosisError = null;
    });

    try {
      final res = await _deepSeekService.analyzeSinglePlan(
        planName: widget.planName,
      );
      if (mounted) {
        setState(() {
          _diagnosisData = res;
          _isLoadingDiagnosis = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _diagnosisError = '诊断加载失败，请检查网络后重试';
          _isLoadingDiagnosis = false;
        });
      }
    }
  }

  Future<void> _loadTags() async {
    setState(() {
      _isLoadingTags = true;
      _tagError = null;
    });

    try {
      final tags = await _deepSeekService.getDeepseekBehaviors(widget.planName);
      if (mounted) {
        setState(() {
          _tags = tags;
          _isLoadingTags = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _tagError = '标签获取失败，请重试';
          _isLoadingTags = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: AppDecorations.bottomSheetDecoration,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
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
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(AppDecorations.radiusMedium),
                  ),
                  child: const AppIcon(
                    type: AppIconType.explore,
                    size: 22,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: AppTextStyles.titleLarge),
                      Text(
                        widget.planName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const AppIcon(
                    type: AppIconType.close,
                    size: 20,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Dual Tab Bar
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppTextStyles.labelMedium
                    .copyWith(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: '🎯 AI 攻克诊断'),
                  Tab(text: '🏷️ 拆解微行动'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab View Body
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: AI 专项诊断
                  _buildDiagnosisTabView(),
                  // Tab 2: 标签选择拆解
                  _buildTagsTabView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisTabView() {
    if (_isLoadingDiagnosis) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'AI 正在深度剖析任务阻碍与破局动线...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1.5.seconds),
          ],
        ),
      );
    }

    if (_diagnosisError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 36, color: AppColors.error),
            const SizedBox(height: 12),
            Text(_diagnosisError!, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadDiagnosis,
              icon: const AppIcon(type: AppIconType.refresh, size: 16),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final data = _diagnosisData;
    if (data == null) return const SizedBox();

    final steps = (data['breakthrough_steps'] as List<dynamic>?) ?? [];
    final microBehaviors = (data['micro_behaviors'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 难易度 & 锚点推荐
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    data['difficulty_level'] ?? '中度攻坚',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data['recommended_anchor'] != null
                        ? '⚓️ 推荐时机：${data['recommended_anchor']}'
                        : '💡 随时可开启 5 分钟微行动',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 核心痛点与阻碍诊断
          if (data['diagnosis'] != null) ...[
            Text('🔍 阻碍与心理卡点：', style: AppTextStyles.labelMedium),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: Text(
                data['diagnosis'],
                style: AppTextStyles.bodyMedium.copyWith(
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 3步落地攻克动线
          Text('🚀 3 步破局执行动线：', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          ...steps.map((s) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border.withOpacity(0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        size: 12, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['step'] ?? '',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s['action'] ?? '',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          // 推荐微行动快速添加
          if (microBehaviors.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('✨ 一键添加推荐微习惯为子任务：', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: microBehaviors.map((b) {
                final tag = b.toString();
                final isSelected = _selectedTags.contains(tag);
                return ActionChip(
                  label: Text(tag),
                  avatar: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                  backgroundColor:
                      isSelected ? AppColors.success : AppColors.surface,
                  labelStyle: AppTextStyles.labelSmall.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                  onPressed: isSelected
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          widget.onTagSelected(tag);
                          setState(() => _selectedTags.add(tag));
                        },
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTagsTabView() {
    if (_isLoadingTags) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.secondary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              '正在生成行为标签...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_tagError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 36, color: AppColors.error),
            const SizedBox(height: 12),
            Text(_tagError!, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadTags,
              icon: const AppIcon(type: AppIconType.refresh, size: 16),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_tags.isEmpty) {
      return Center(
        child: Text('暂无可拆解标签', style: AppTextStyles.bodyMedium),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('点击下方标签，可一键分解并添加为当前计划的子任务：',
              style: AppTextStyles.bodySmall),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _tags.asMap().entries.map((entry) {
              final tag = entry.value;
              final isSelected = _selectedTags.contains(tag);

              return GestureDetector(
                onTap: isSelected
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        widget.onTagSelected(tag);
                        setState(() => _selectedTags.add(tag));
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient:
                        isSelected ? null : AppColors.secondaryGradient,
                    color: isSelected
                        ? AppColors.textHint.withOpacity(0.25)
                        : null,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSelected
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.secondary.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(Icons.check, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        tag,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: isSelected
                              ? AppColors.textSecondary
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
