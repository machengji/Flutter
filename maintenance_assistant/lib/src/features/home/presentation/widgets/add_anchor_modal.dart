import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/theme.dart';

class AddAnchorModal extends StatefulWidget {
  final Function(String name, String time) onAdd;
  final String? initialName;
  final String? initialTime;
  final bool autofocusEnabled;
  final bool enableEntranceAnimation;

  const AddAnchorModal({
    super.key,
    required this.onAdd,
    this.initialName,
    this.initialTime,
    this.autofocusEnabled = true,
    this.enableEntranceAnimation = true,
  });

  @override
  State<AddAnchorModal> createState() => _AddAnchorModalState();
}

class _AddAnchorModalState extends State<AddAnchorModal> {
  late final TextEditingController _nameController;
  late TimeOfDay _selectedTime;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);

    if (widget.initialTime != null) {
      final parts = widget.initialTime!.split(':');
      _selectedTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } else {
      _selectedTime = const TimeOfDay(hour: 8, minute: 0);
    }

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
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.anchorAccent,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _handleSubmit() {
    final text = _nameController.text.trim();
    if (text.isEmpty) return;

    final hour = _selectedTime.hour.toString().padLeft(2, '0');
    final minute = _selectedTime.minute.toString().padLeft(2, '0');
    widget.onAdd(text, '$hour:$minute');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialName != null;

    final dialogChild = RepaintBoundary(
      child: LiquidGlassContainer(
        padding: const EdgeInsets.all(28),
        radius: AppDecorations.radiusLarge,
        blur: 24.0,
        opacity: 0.88,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.anchorAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                  ),
                  child: const AppIcon(
                    type: AppIconType.anchor,
                    size: 22,
                    color: AppColors.anchorAccent,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  isEditing ? '编辑锚点' : '添加新锚点',
                  style: AppTextStyles.titleLarge,
                ),
                const Spacer(),
                LiquidPressable(
                  onTap: () => Navigator.pop(context),
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
              controller: _nameController,
              focusNode: _focusNode,
              decoration: AppDecorations.inputDecoration(
                hintText: '锚点名称，例如：起床后',
              ),
              style: AppTextStyles.bodyLarge,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleSubmit(),
            ),
            const SizedBox(height: 18),
            LiquidPressable(
              onTap: () => _selectTime(context),
              pressedScale: 0.98,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                  border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const AppIcon(
                          type: AppIconType.habit,
                          size: 20,
                          color: AppColors.anchorAccent,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '选择时间',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.anchorAccent,
                            AppColors.anchorAccent.withOpacity(0.85),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.anchorAccent.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            LiquidPressable(
              onTap: _handleSubmit,
              pressedScale: 0.96,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.anchorAccent, AppColors.anchorAccent.withOpacity(0.85)],
                  ),
                  borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.anchorAccent.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  isEditing ? '保存' : '添加',
                  style: AppTextStyles.button,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: widget.enableEntranceAnimation
          ? dialogChild.animate().scale(
              duration: 220.ms,
              curve: Curves.easeOutCubic,
            )
          : dialogChild,
    );
  }
}
