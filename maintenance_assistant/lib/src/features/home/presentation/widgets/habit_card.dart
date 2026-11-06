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

  static final DateFormat _dateFormatter = DateFormat('yyyy/MM/dd');

  String _formatDate(int timestamp) {
    if (timestamp == 0) return '从未';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return '今天';
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return _dateFormatter.format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isStopped = habit.status == '已停用';
    final lastCompleteTime =
        habit.completionHistory.isNotEmpty ? habit.completionHistory.last : 0;

    return RepaintBoundary(
      child: Container(
        decoration: AppDecorations.habitCardDecoration,
        child: Column(
          children: [
            GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    // 彩蝶蜕变打卡框
                    GestureDetector(
                      onTap: isStopped ? null : onCheck,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.only(right: 14),
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: (!isStopped && habit.totalDays > 0)
                              ? AppColors.secondaryGradient
                              : null,
                          color: isStopped
                              ? AppColors.textHint.withOpacity(0.1)
                              : (habit.totalDays > 0
                                  ? null
                                  : AppColors.secondary.withOpacity(0.06)),
                          border: Border.all(
                            color: isStopped
                                ? AppColors.textHint.withOpacity(0.28)
                                : (habit.totalDays > 0
                                    ? AppColors.secondary
                                    : AppColors.secondary.withOpacity(0.28)),
                            width: 1.6,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: habit.totalDays > 0
                              ? Text(
                                  '${habit.totalDays}',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: isStopped
                                        ? AppColors.textSecondary
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : AppIcon(
                                  type: AppIconType.habit,
                                  size: 22,
                                  color: isStopped
                                      ? AppColors.textHint
                                      : AppColors.secondary.withOpacity(0.55),
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
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              decoration:
                                  isStopped ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              if (!isStopped && habit.totalDays > 0) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withOpacity(0.11),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const AppIcon(
                                        type: AppIconType.habit,
                                        size: 11,
                                        color: AppColors.secondaryDark,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '已蜕变 ${habit.totalDays} 次',
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: AppColors.secondaryDark,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                isStopped
                                    ? '休眠中'
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
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? Container(
                      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF4F4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFD9E7E8).withOpacity(0.75),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ActionButton(
                            icon: AppIconType.edit,
                            color: const Color(0xFF2F6F73),
                            onTap: onEdit,
                          ),
                          _ActionButton(
                            icon: AppIconType.explore,
                            color: const Color(0xFF2D6A4F),
                            onTap: onDetail,
                          ),
                          _ActionButton(
                            icon: AppIconType.pin,
                            color: const Color(0xFFB57632),
                            onTap: onPin,
                          ),
                          _ActionButton(
                            icon: isStopped ? AppIconType.play : AppIconType.pause,
                            color: isStopped
                                ? const Color(0xFF2D6A4F)
                                : const Color(0xFF6E5D4F),
                            onTap: onToggleStatus,
                          ),
                          _ActionButton(
                            icon: AppIconType.delete,
                            color: const Color(0xFFB55A52),
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
  final bool isHighlighted;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    this.isDanger = false,
    this.isHighlighted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isDanger ? const Color(0xFFB55A52) : color;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isHighlighted
              ? effectiveColor.withOpacity(0.14)
              : (isDanger
                  ? effectiveColor.withOpacity(0.08)
                  : Colors.white.withOpacity(0.75)),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: effectiveColor.withOpacity(isHighlighted ? 0.25 : 0.12),
            width: 0.9,
          ),
        ),
        child: Center(
          child: AppIcon(
            type: icon,
            color: effectiveColor,
            size: 19,
          ),
        ),
      ),
    );
  }
}
