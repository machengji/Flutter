import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/models/habit_model.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onCheck;
  final VoidCallback onDelete;
  final VoidCallback onPin;
  final VoidCallback onToggleStatus;
  final VoidCallback onDetail;
  final VoidCallback onEdit;

  const HabitCard({
    super.key,
    required this.habit,
    required this.isExpanded,
    required this.onTap,
    required this.onCheck,
    required this.onDelete,
    required this.onPin,
    required this.onToggleStatus,
    required this.onDetail,
    required this.onEdit,
  });

  String _formatDate(int timestamp) {
    if (timestamp == 0) return '从未';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return '今天';
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return DateFormat('yyyy/MM/dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isStopped = habit.status == '已停用';
    final lastCompleteTime = habit.completionHistory.isNotEmpty ? habit.completionHistory.last : 0;

    return RepaintBoundary(
      child: Container(
        decoration: AppDecorations.habitCardDecoration,
        child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Checkbox / Count
                  GestureDetector(
                    onTap: isStopped ? null : onCheck,
                    child: Container(
                      margin: const EdgeInsets.only(right: 14),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: (!isStopped && habit.totalDays > 0) 
                            ? AppColors.secondaryGradient 
                            : null,
                        color: isStopped 
                            ? AppColors.textHint.withOpacity(0.1) 
                            : (habit.totalDays > 0 ? null : AppColors.surface),
                        border: Border.all(
                          color: isStopped 
                              ? AppColors.textHint.withOpacity(0.3)
                              : (habit.totalDays > 0 ? AppColors.secondary : AppColors.border),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: habit.totalDays > 0
                            ? Text(
                                '${habit.totalDays}',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : AppIcon(
                                type: AppIconType.check,
                                size: 20,
                                color: isStopped ? AppColors.textHint : AppColors.textSecondary,
                              ),
                      ),
                    ),
                  ),
                  
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: AppTextStyles.cardTitle.copyWith(
                            color: isStopped ? AppColors.textSecondary : AppColors.textPrimary,
                            decoration: isStopped ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (!isStopped && habit.totalDays > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '已坚持 ${habit.totalDays} 天',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              isStopped
                                  ? '已停用'
                                  : '最近: ${_formatDate(lastCompleteTime)}',
                              style: AppTextStyles.cardSubtitle,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Chevron
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const AppIcon(
                      type: AppIconType.chevronRight,
                      size: 20,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Actions
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Container(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ActionButton(
                          icon: AppIconType.edit,
                          color: AppColors.habitAccent,
                          onTap: onEdit,
                        ),
                        _ActionButton(
                          icon: AppIconType.explore,
                          color: AppColors.habitAccent,
                          onTap: onDetail,
                        ),
                        _ActionButton(
                          icon: AppIconType.pin,
                          color: AppColors.warning,
                          onTap: onPin,
                        ),
                        _ActionButton(
                          icon: isStopped ? AppIconType.play : AppIconType.pause,
                          color: AppColors.warning,
                          onTap: onToggleStatus,
                        ),
                        _ActionButton(
                          icon: AppIconType.delete,
                          color: AppColors.error,
                          isDanger: true,
                          onTap: onDelete,
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final AppIconType icon;
  final Color color;
  final bool isDanger;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    this.isDanger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDanger 
              ? AppColors.error.withOpacity(0.08) 
              : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
          border: Border.all(
            color: isDanger 
                ? AppColors.error.withOpacity(0.15) 
                : color.withOpacity(0.15),
          ),
        ),
        child: AppIcon(
          type: icon,
          color: color,
          size: 20,
        ),
      ),
    );
  }
}
