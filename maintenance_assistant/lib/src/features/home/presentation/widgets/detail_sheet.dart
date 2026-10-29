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
    this.title = 'AI探索行为标签',
    required this.planName,
    required this.onTagSelected,
  });

  @override
  State<DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<DetailSheet> {
  bool _isLoading = true;
  List<String> _tags = [];
  Set<String> _selectedTags = {}; // 已选中的标签
  String? _error;
  final DeepSeekService _deepSeekService = DeepSeekService();

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tags = await _deepSeekService.getDeepseekBehaviors(widget.planName);
      if (mounted) {
        setState(() {
          _tags = tags;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('MISSING_API_KEY')) {
          _showApiKeyDialog();
        } else {
          setState(() {
            _error = '获取失败，请重试';
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const AppIcon(
                type: AppIconType.apiKey,
                size: 20,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            const Text('设置 DeepSeek API Key'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('需要 API Key 才能使用 AI 功能', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: AppDecorations.inputDecoration(
                hintText: 'sk-...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isLoading = false;
                _error = '未设置 API Key';
              });
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _deepSeekService.setApiKey(controller.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadTags();
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
      decoration: AppDecorations.bottomSheetDecoration,
      child: SafeArea(
        top: false,
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
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                  ),
                  child: const AppIcon(
                    type: AppIconType.explore,
                    size: 22,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(widget.title, style: AppTextStyles.titleLarge),
                ),
                // 提示文字
                Text(
                  '点击空白处关闭',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Content
            SizedBox(
              height: 220,
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const CircularProgressIndicator(
                              color: AppColors.secondary,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '正在思考中...',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const AppIcon(
                                  type: AppIconType.close,
                                  size: 32,
                                  color: AppColors.error,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: _loadTags,
                                icon: const AppIcon(
                                  type: AppIconType.refresh,
                                  size: 18,
                                  color: AppColors.secondary,
                                ),
                                label: const Text('重试'),
                              ),
                            ],
                          ),
                        )
                      : _tags.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const AppIcon(
                                    type: AppIconType.explore,
                                    size: 48,
                                    color: AppColors.textHint,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '暂无探索标签',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: _tags.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final tag = entry.value;
                                  final isSelected = _selectedTags.contains(tag);
                                  
                                  return GestureDetector(
                                    onTap: isSelected
                                        ? null // 已选中的不可再点击
                                        : () {
                                            HapticFeedback.selectionClick();
                                            widget.onTagSelected(tag);
                                            setState(() {
                                              _selectedTags.add(tag);
                                            });
                                            // 不关闭弹框，允许继续选择
                                          },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: isSelected 
                                            ? null 
                                            : AppColors.secondaryGradient,
                                        color: isSelected 
                                            ? AppColors.textHint.withOpacity(0.3) 
                                            : null,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: isSelected
                                            ? null
                                            : [
                                                BoxShadow(
                                                  color: AppColors.secondary.withOpacity(0.25),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isSelected) ...[
                                            const AppIcon(
                                              type: AppIconType.check,
                                              size: 14,
                                              color: AppColors.textSecondary,
                                            ),
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
                                    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.2, end: 0),
                                  );
                                }).toList(),
                              ),
                            ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
