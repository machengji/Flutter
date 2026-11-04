import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/models/plan_model.dart';

class PlanCard extends StatelessWidget {
  final Plan plan;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;
  final VoidCallback onPin;
  final VoidCallback onEdit;
  final VoidCallback onDetail;
  final VoidCallback? onAddToReminders;

  const PlanCard({
    super.key,
    required this.plan,
    required this.isExpanded,
    required this.onTap,
    required this.onToggleStatus,
    required this.onDelete,
    required this.onPin,
    required this.onEdit,
    required this.onDetail,
    this.onAddToReminders,
  });

  String _formatDate(int timestamp) {
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
    final isCompleted = plan.status == '已完成';

    return RepaintBoundary(
      child: LiquidPressable(
        onTap: onTap,
        child: LiquidGlassContainer(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          opacity: isCompleted ? 0.58 : 0.74,
          borderColor: isCompleted
              ? Colors.white.withOpacity(0.6)
              : Colors.white.withOpacity(0.92),
          child: Column(
            children: [
              Row(
                children: [
                  // 勾选按钮 - 液态果冻按压
                  LiquidPressable(
                    onTap: onToggleStatus,
                    pressedScale: 0.92,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 12),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: isCompleted ? AppColors.primaryGradient : null,
                        color: isCompleted
                            ? null
                            : Colors.white.withOpacity(0.65),
                        border: Border.all(
                          color: isCompleted
                              ? AppColors.primary
                              : Colors.white.withOpacity(0.9),
                          width: 1.8,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          if (isCompleted)
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.35),
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
                      child: isCompleted
                          ? const Center(
                              child: AppIcon(
                                type: AppIconType.check,
                                size: 24,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: AppTextStyles.cardTitle.copyWith(
                            decoration:
                                isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted
                                ? AppColors.textSecondary.withOpacity(0.7)
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              isCompleted
                                  ? '完成于 ${_formatDate(plan.completeTime ?? 0)}'
                                  : _formatDate(plan.createTime),
                              style: AppTextStyles.cardSubtitle,
                            ),
                            if (plan.groupColorIndex >= 0) ...[
                              const SizedBox(width: 8),
                              ...List.generate(
                                plan.decompositionLevel.clamp(1, 5),
                                (index) {
                                  final colorIndex = plan.groupColorIndex %
                                      AppColors.groupColors.length;
                                  final baseColor =
                                      AppColors.groupColors[colorIndex];
                                  return Container(
                                    margin: const EdgeInsets.only(right: 4),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: baseColor
                                          .withOpacity(0.9 - (index * 0.1)),
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
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
                              icon: AppIconType.explore,
                              color: AppColors.primary,
                              onTap: onDetail,
                            ),
                            if (!isCompleted && onAddToReminders != null)
                              _ActionButton(
                                icon: AppIconType.notification,
                                color: AppColors.info,
                                onTap: onAddToReminders!,
                              ),
                            _ActionButton(
                              icon: AppIconType.edit,
                              color: AppColors.primary,
                              onTap: onEdit,
                            ),
                            _ActionButton(
                              icon: AppIconType.pin,
                              color: AppColors.warning,
                              onTap: onPin,
                            ),
                            _ActionButton(
                              icon: isCompleted
                                  ? AppIconType.refresh
                                  : AppIconType.check,
                              color: isCompleted
                                  ? AppColors.warning
                                  : AppColors.success,
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
