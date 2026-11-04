import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/theme.dart';

class AddModal extends StatefulWidget {
  final String title;
  final String placeholder;
  final String? initialValue;
  final Function(String) onConfirm;
  final bool autofocusEnabled;
  final bool enableEntranceAnimation;

  const AddModal({
    super.key,
    required this.title,
    required this.placeholder,
    this.initialValue,
    required this.onConfirm,
    this.autofocusEnabled = true,
    this.enableEntranceAnimation = true,
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

    if (widget.autofocusEnabled) {
      Future.delayed(const Duration(milliseconds: 220), () {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onConfirm(text);
    Navigator.of(context).pop();
  }

  AppIconType get _iconType {
    if (widget.title.contains('习惯')) {
      return AppIconType.habit;
    }
    return AppIconType.plan;
  }

  @override
  Widget build(BuildContext context) {
    final dialogChild = RepaintBoundary(
      child: LiquidGlassContainer(
        padding: const EdgeInsets.all(28),
        radius: AppDecorations.radiusLarge,
        blur: 24.0,
        opacity: 0.88,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppDecorations.radiusSmall),
                      ),
                      child: AppIcon(
                        type: _iconType,
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
                LiquidPressable(
                  onTap: () => Navigator.of(context).pop(),
                  pressedScale: 0.90,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.textHint.withOpacity(0.12),
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
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: LiquidPressable(
                    onTap: () => Navigator.of(context).pop(),
                    pressedScale: 0.96,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.85),
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '取消',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LiquidPressable(
                    onTap: _submit,
                    pressedScale: 0.96,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                        boxShadow: AppDecorations.shadowButton,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 1.2,
                        ),
                      ),
                      alignment: Alignment.center,
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
      ),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      child: widget.enableEntranceAnimation
          ? dialogChild.animate().scale(
              duration: 220.ms,
              curve: Curves.easeOutCubic,
            )
          : dialogChild,
    );
  }
}
