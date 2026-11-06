import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/services/deepseek_service.dart';
import 'ai_config_dialog.dart';

class DetailSheet extends StatefulWidget {
  final String title;
  final String planName;
  final Function(String) onTagSelected;

  const DetailSheet({
    super.key,
    this.title = '任务攻克与拆解',
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

  // Tab 1: 任务专项攻克方案
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
        final rawMsg = e.toString().replaceFirst('Exception: ', '').trim();
        setState(() {
          _diagnosisError = rawMsg;
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
        final rawMsg = e.toString().replaceFirst('Exception: ', '').trim();
        setState(() {
          _tagError = rawMsg;
          _isLoadingTags = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
            // 顶部拖拽把手
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: AppDecorations.dragHandleDecoration,
              ),
            ),
            const SizedBox(height: 16),

            // Header 标题栏：去掉突兀的 AI 图标，使用原生计划目标图标
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const AppIcon(
                    type: AppIconType.plan,
                    size: 22,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title.contains('AI') ? '任务攻克与拆解' : widget.title,
                        style: AppTextStyles.titleLarge,
                      ),
                      const SizedBox(height: 2),
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

            // iOS 规范胶囊分段控制器：彻底去掉怪异的彩色块和 emoji，还原纯正精致质感
            Container(
              height: 42,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(
                    height: 36,
                    text: '攻克方案',
                  ),
                  Tab(
                    height: 36,
                    text: '拆解微行动',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab View Body
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: 攻克方案
                  _buildDiagnosisTabView(),
                  // Tab 2: 拆解微行动
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
              '正在深度剖析任务阻碍与破局动线...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1.5.seconds),
          ],
        ),
      );
    }

    if (_diagnosisError != null) {
      final isKeyMissing = _diagnosisError!.contains('未配置智谱 API Key');
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 36, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                _diagnosisError!,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      showZhipuApiKeyDialog(
                        context,
                        onSaved: () {
                          _loadDiagnosis();
                          _loadTags();
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D6A4F),
                      foregroundColor: Colors.white,
                    ),
                    icon: const AppIcon(
                      type: AppIconType.apiKey,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(isKeyMissing ? '配置免费 Key' : '修改 Key'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _loadDiagnosis,
                    icon: const AppIcon(type: AppIconType.refresh, size: 16),
                    label: const Text('重试'),
                  ),
                ],
              ),
            ],
          ),
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
          // 难易度 & 启动时机参数条
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withOpacity(0.6)),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    data['difficulty_level'] ?? '中度攻坚',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    data['recommended_anchor'] != null
                        ? '建议启动：${data['recommended_anchor']}'
                        : '建议启动：随时开启 5 分钟微行动',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // 核心痛点与阻碍诊断
          if (data['diagnosis'] != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 3.5,
                  height: 13,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '阻碍与卡点分析',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withOpacity(0.6)),
              ),
              child: Text(
                data['diagnosis'],
                style: AppTextStyles.bodyMedium.copyWith(
                  height: 1.55,
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
          ],

          // 3 步破局执行动线
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 3.5,
                height: 13,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '三步破局执行路线',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...steps.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final s = entry.value;
            final stepTitle = s['step']?.toString() ?? '第$idx步';
            final actionDesc = s['action']?.toString() ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withOpacity(0.6)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$idx',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stepTitle,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          actionDesc,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.5,
                            fontSize: 13,
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
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 3.5,
                  height: 13,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '推荐微行动（点击添加为子任务）',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: microBehaviors.map((b) {
                final tag = b.toString();
                final isSelected = _selectedTags.contains(tag);
                return GestureDetector(
                  onTap: isSelected
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          widget.onTagSelected(tag);
                          setState(() => _selectedTags.add(tag));
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.2),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(Icons.check, size: 13, color: Colors.white),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          tag,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isSelected ? Colors.white : AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
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
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              '正在生成可执行微习惯标签...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_tagError != null) {
      final isKeyMissing = _tagError!.contains('未配置智谱 API Key');
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 36, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                _tagError!,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      showZhipuApiKeyDialog(
                        context,
                        onSaved: () {
                          _loadDiagnosis();
                          _loadTags();
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D6A4F),
                      foregroundColor: Colors.white,
                    ),
                    icon: const AppIcon(
                      type: AppIconType.apiKey,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(isKeyMissing ? '配置免费 Key' : '修改 Key'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _loadTags,
                    icon: const AppIcon(type: AppIconType.refresh, size: 16),
                    label: const Text('重试'),
                  ),
                ],
              ),
            ],
          ),
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
          Text(
            '点击下方标签，可一键将其添加为当前计划的子任务：',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              final isSelected = _selectedTags.contains(tag);

              return GestureDetector(
                onTap: isSelected
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        widget.onTagSelected(tag);
                        setState(() => _selectedTags.add(tag));
                      },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border.withOpacity(0.6),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(Icons.check, size: 13, color: Colors.white),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        tag,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
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
