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
    final lastCompleteTime =
        habit.completionHistory.isNotEmpty ? habit.completionHistory.last : 0;

    return RepaintBoundary(
      child: LiquidPressable(
        onTap: onTap,
        child: LiquidGlassContainer(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          opacity: isStopped ? 0.58 : 0.74,
          borderColor: isStopped
              ? Colors.white.withOpacity(0.5)
              : Colors.white.withOpacity(0.92),
          child: Column(
            children: [
              Row(
                children: [
                  // Checkbox / Count - 液态果冻按压
                  LiquidPressable(
                    onTap: isStopped ? null : onCheck,
                    pressedScale: 0.92,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 14),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: (!isStopped && habit.totalDays > 0)
                            ? AppColors.secondaryGradient
                            : null,
                        color: isStopped
                            ? AppColors.textHint.withOpacity(0.12)
                            : (habit.totalDays > 0
                                ? null
                                : Colors.white.withOpacity(0.7)),
                        border: Border.all(
                          color: isStopped
                              ? AppColors.textHint.withOpacity(0.3)
                              : (habit.totalDays > 0
                                  ? AppColors.secondary
                                  : Colors.white.withOpacity(0.9)),
                          width: 1.8,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          if (!isStopped && habit.totalDays > 0)
                            BoxShadow(
                              color: AppColors.secondary.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )
                          else
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                        ],
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
                                color: isStopped
                                    ? AppColors.textHint
                                    : AppColors.textSecondary,
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
                            color: isStopped
                                ? AppColors.textSecondary.withOpacity(0.7)
                                : AppColors.textPrimary,
                            decoration:
                                isStopped ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (!isStopped && habit.totalDays > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.secondary.withOpacity(0.2),
                                    width: 1,
                                  ),
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

              // Actions
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: isExpanded
                    ? Container(
                        padding: const EdgeInsets.only(top: 14, bottom: 4),
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
                              icon: isStopped
                                  ? AppIconType.play
                                  : AppIconType.pause,
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
    return LiquidPressable(
      onTap: onTap,
      pressedScale: 0.90,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: isDanger
              ? AppColors.error.withOpacity(0.09)
              : color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
          border: Border.all(
            color: isDanger
                ? AppColors.error.withOpacity(0.2)
                : color.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.6),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: AppIcon(
          type: icon,
          color: color,
          size: 19,
        ),
      ),
    );
  }
}
