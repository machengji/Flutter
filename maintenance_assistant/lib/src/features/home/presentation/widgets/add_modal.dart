import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/theme.dart';

class AddModal extends StatefulWidget {
  final String title;
  final String placeholder;
  final String? initialValue;
  final Function(String) onConfirm;

  const AddModal({
    super.key,
    required this.title,
    required this.placeholder,
    this.initialValue,
    required this.onConfirm,
  });

  @override
  State<AddModal> createState() => _AddModalState();
}

class _AddModalState extends State<AddModal> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    
    // 动画完成后自动聚焦,弹出键盘
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onConfirm(_controller.text.trim());
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: RepaintBoundary(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDecorations.radiusLarge),
            border: Border.all(color: AppColors.primary.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppDecorations.radiusSmall),
                        ),
                        child: AppIcon(
                          type: widget.title.contains('计划') 
                              ? AppIconType.plan 
                              : AppIconType.habit,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.title,
                        style: AppTextStyles.titleLarge,
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.textHint.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const AppIcon(
                        type: AppIconType.close,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: AppDecorations.inputDecoration(
                  hintText: widget.placeholder,
                ),
                style: AppTextStyles.bodyLarge,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 28),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                        ),
                      ),
                      child: Text(
                        '取消',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                        boxShadow: AppDecorations.shadowButton,
                      ),
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                          ),
                        ),
                        child: Text(
                          widget.initialValue != null ? '保存' : '添加',
                          style: AppTextStyles.button,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().scale(
          duration: 350.ms,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }
}
