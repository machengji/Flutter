import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/theme.dart';

class AddAnchorModal extends StatefulWidget {
  final Function(String name, String time) onAdd;
  final String? initialName;
  final String? initialTime;

  const AddAnchorModal({
    super.key,
    required this.onAdd,
    this.initialName,
    this.initialTime,
  });

  @override
  State<AddAnchorModal> createState() => _AddAnchorModalState();
}

class _AddAnchorModalState extends State<AddAnchorModal> {
  late TextEditingController _nameController;
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

    // Auto focus after animation
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
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
    if (_nameController.text.isNotEmpty) {
      final hour = _selectedTime.hour.toString().padLeft(2, '0');
      final minute = _selectedTime.minute.toString().padLeft(2, '0');
      widget.onAdd(_nameController.text, '$hour:$minute');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialName != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDecorations.radiusLarge),
          border: Border.all(color: AppColors.anchorAccent.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: AppColors.anchorAccent.withOpacity(0.1),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.anchorAccent.withOpacity(0.1),
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
              ],
            ),
            const SizedBox(height: 28),
            
            // Name Input
            TextField(
              controller: _nameController,
              focusNode: _focusNode,
              decoration: AppDecorations.inputDecoration(
                hintText: '锚点名称 (例如: 起床后)',
              ),
              style: AppTextStyles.bodyLarge,
              onSubmitted: (_) => _handleSubmit(),
            ),
            const SizedBox(height: 18),

            // Time Picker
            GestureDetector(
              onTap: () => _selectTime(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.anchorAccent.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                  border: Border.all(color: AppColors.anchorAccent.withOpacity(0.15)),
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
                            AppColors.anchorAccent.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
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

            // Add Button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.anchorAccent, AppColors.anchorAccent.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.anchorAccent.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                  ),
                ),
                child: Text(
                  isEditing ? '保存' : '添加',
                  style: AppTextStyles.button,
                ),
              ),
            ),
          ],
        ),
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
    );
  }
}
