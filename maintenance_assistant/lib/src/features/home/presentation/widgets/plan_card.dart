import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

    return Container(
      decoration: AppDecorations.planCardDecoration,
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Checkbox
                  GestureDetector(
                    onTap: onToggleStatus,
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: isCompleted ? AppColors.primaryGradient : null,
                        color: isCompleted ? null : AppColors.surface,
                        border: Border.all(
                          color: isCompleted ? AppColors.primary : AppColors.border,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(14),
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
                  
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: AppTextStyles.cardTitle.copyWith(
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isCompleted
                              ? '完成于 ${_formatDate(plan.completeTime ?? 0)}'
                              : _formatDate(plan.createTime),
                          style: AppTextStyles.cardSubtitle,
                        ),
                      ],
                    ),
                  ),

                  // Chevron
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: 200.ms,
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
            duration: 300.ms,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Container(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ActionButton(
                          icon: AppIconType.explore,
                          color: AppColors.primary,
                          onTap: onDetail,
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
                          icon: isCompleted ? AppIconType.refresh : AppIconType.check,
                          color: isCompleted ? AppColors.warning : AppColors.success,
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
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
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
