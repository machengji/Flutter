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
  final VoidCallback? onShare;
  final VoidCallback? onArchive;

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
    this.onShare,
    this.onArchive,
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
    final isArchived = plan.status == '已归档';

    return RepaintBoundary(
      child: Container(
        decoration: AppDecorations.planCardDecoration,
        child: Column(
          children: [
            GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Row(
                  children: [
                    // 森系新芽打卡框
                    GestureDetector(
                      onTap: onToggleStatus,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.only(right: 12),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: isCompleted ? AppColors.primaryGradient : null,
                          color: isCompleted
                              ? null
                              : (isArchived
                                  ? AppColors.surfaceVariant
                                  : AppColors.primary.withOpacity(0.05)),
                          border: Border.all(
                            color: isCompleted
                                ? AppColors.primary
                                : (isArchived
                                    ? AppColors.textSecondary.withOpacity(0.25)
                                    : AppColors.primary.withOpacity(0.24)),
                            width: 1.6,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: isCompleted
                              ? const AppIcon(
                                  type: AppIconType.check,
                                  size: 22,
                                  color: Colors.white,
                                )
                              : (isArchived
                                  ? const AppIcon(
                                      type: AppIconType.archive,
                                      size: 20,
                                      color: AppColors.textHint,
                                    )
                                  : AppIcon(
                                      type: AppIconType.plan,
                                      size: 20,
                                      color: AppColors.primary.withOpacity(0.38),
                                    )),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  plan.name,
                                  style: AppTextStyles.cardTitle.copyWith(
                                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                                    color: isCompleted
                                        ? AppColors.textSecondary
                                        : (isArchived ? AppColors.textSecondary : AppColors.textPrimary),
                                  ),
                                ),
                              ),
                              if (isArchived)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.warning.withOpacity(0.22),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const AppIcon(
                                        type: AppIconType.archive,
                                        size: 11,
                                        color: AppColors.warning,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '暂非重点',
                                        style: AppTextStyles.badge.copyWith(
                                          fontSize: 10,
                                          color: AppColors.warning,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
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
                                    final colorIndex =
                                        plan.groupColorIndex % AppColors.groupColors.length;
                                    final baseColor = AppColors.groupColors[colorIndex];
                                    return Container(
                                      margin: const EdgeInsets.only(right: 4),
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: baseColor.withOpacity(0.88 - (index * 0.1)),
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
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? Container(
                      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF4F0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFDCE8E0).withOpacity(0.7),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ActionButton(
                            icon: AppIconType.explore,
                            color: const Color(0xFF2D6A4F),
                            onTap: onDetail,
                          ),
                          if (!isCompleted && onAddToReminders != null)
                            _ActionButton(
                              icon: AppIconType.notification,
                              color: const Color(0xFF4A7862),
                              onTap: onAddToReminders!,
                            ),
                          if (isCompleted && onShare != null)
                            _ActionButton(
                              icon: AppIconType.share,
                              color: const Color(0xFF2D6A4F),
                              onTap: onShare!,
                            ),
                          _ActionButton(
                            icon: AppIconType.edit,
                            color: const Color(0xFF5A6D62),
                            onTap: onEdit,
                          ),
                          _ActionButton(
                            icon: AppIconType.pin,
                            color: const Color(0xFFB57632),
                            onTap: onPin,
                          ),
                          if (onArchive != null)
                            _ActionButton(
                              icon: AppIconType.archive,
                              color: isArchived
                                  ? const Color(0xFF2D6A4F)
                                  : const Color(0xFF6E5D4F),
                              isHighlighted: isArchived,
                              onTap: onArchive!,
                            ),
                          _ActionButton(
                            icon: isCompleted ? AppIconType.refresh : AppIconType.check,
                            color: const Color(0xFF2D6A4F),
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isHighlighted
              ? effectiveColor.withOpacity(0.14)
              : (isDanger
                  ? effectiveColor.withOpacity(0.08)
                  : Colors.white.withOpacity(0.72)),
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
