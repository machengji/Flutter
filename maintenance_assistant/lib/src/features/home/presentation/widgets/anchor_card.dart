import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/models/anchor_model.dart';

class AnchorCard extends StatelessWidget {
  final Anchor anchor;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onLinkCalendar;
  final VoidCallback? onUnlinkCalendar;

  const AnchorCard({
    super.key,
    required this.anchor,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onLinkCalendar,
    this.onUnlinkCalendar,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = anchor.planIds.length + anchor.habitIds.length;
    final isSynced = anchor.isCalendarSynced;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: AppDecorations.anchorCardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Time Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.anchorAccent.withOpacity(0.12),
                          AppColors.anchorAccent.withOpacity(0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        AppDecorations.radiusMedium,
                      ),
                      border: Border.all(
                        color: AppColors.anchorAccent.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppIcon(
                          type: AppIconType.anchor,
                          size: 16,
                          color: AppColors.anchorAccent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          anchor.time,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.anchorAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name & Badges
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          anchor.name,
                          style: AppTextStyles.cardTitle,
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.anchorAccent.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                anchor.repeatLabel,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.anchorAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: itemCount > 0
                                    ? AppColors.primary.withOpacity(0.1)
                                    : AppColors.textHint.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$itemCount 个关联项',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: itemCount > 0
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: isSynced
                                    ? const Color(0xFF2D6A4F).withOpacity(0.12)
                                    : AppColors.textHint.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isSynced ? '已关联日历' : '未关联日历',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isSynced
                                      ? const Color(0xFF2D6A4F)
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Edit Button
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppColors.anchorAccent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(
                          AppDecorations.radiusSmall,
                        ),
                      ),
                      child: const AppIcon(
                        type: AppIconType.edit,
                        size: 18,
                        color: AppColors.anchorAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Delete Button
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(
                          AppDecorations.radiusSmall,
                        ),
                      ),
                      child: const AppIcon(
                        type: AppIconType.delete,
                        size: 18,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 底部内嵌微凹苔藓浅槽操作栏：关联日历 / 取消日历
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF2EC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFDCE7DD),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _AnchorCalendarActionBtn(
                        icon: AppIconType.anchor,
                        label: isSynced ? '更新日历' : '关联日历',
                        color: const Color(0xFF2D6A4F),
                        isHighlighted: isSynced,
                        onTap: onLinkCalendar,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 18,
                      color: const Color(0xFFD5E2D7),
                    ),
                    Expanded(
                      child: _AnchorCalendarActionBtn(
                        icon: AppIconType.close,
                        label: '取消日历',
                        color: const Color(0xFFB57632),
                        onTap: onUnlinkCalendar,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnchorCalendarActionBtn extends StatelessWidget {
  final AppIconType icon;
  final String label;
  final Color color;
  final bool isHighlighted;
  final VoidCallback? onTap;

  const _AnchorCalendarActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    this.isHighlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        decoration: BoxDecoration(
          color: isHighlighted
              ? Colors.white.withOpacity(0.75)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(
              type: icon,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

