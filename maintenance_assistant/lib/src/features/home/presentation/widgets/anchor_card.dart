import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/models/anchor_model.dart';

class AnchorCard extends StatelessWidget {
  final Anchor anchor;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool>? onToggleReminder;

  const AnchorCard({
    super.key,
    required this.anchor,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onToggleReminder,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = anchor.planIds.length + anchor.habitIds.length;
    final isReminderOn = anchor.isReminderEnabled;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
                                color: isReminderOn
                                    ? const Color(0xFF2D6A4F).withOpacity(0.12)
                                    : AppColors.textHint.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isReminderOn ? '提醒开启' : '已暂停',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isReminderOn
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

              // 底部定时提醒开关栏
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isReminderOn
                      ? const Color(0xFFEBF2EC)
                      : AppColors.surfaceVariant.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isReminderOn
                        ? const Color(0xFFDCE7DD)
                        : AppColors.border.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    AppIcon(
                      type: AppIconType.notification,
                      size: 15,
                      color: isReminderOn
                          ? const Color(0xFF2D6A4F)
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isReminderOn
                            ? (itemCount > 0
                                ? '到点推送未完成待办提醒（点击直达打卡）'
                                : '到点自动发出时间提醒')
                            : '定时提醒已暂停',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isReminderOn
                              ? const Color(0xFF2D6A4F)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 28,
                      child: Transform.scale(
                        scale: 0.82,
                        alignment: Alignment.centerRight,
                        child: CupertinoSwitch(
                          value: isReminderOn,
                          activeColor: const Color(0xFF2D6A4F),
                          onChanged: onToggleReminder,
                        ),
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

