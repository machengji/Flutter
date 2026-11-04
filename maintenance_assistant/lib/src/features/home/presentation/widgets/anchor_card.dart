import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/models/anchor_model.dart';

class AnchorCard extends StatelessWidget {
  final Anchor anchor;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSyncAppleEco;

  const AnchorCard({
    super.key,
    required this.anchor,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onSyncAppleEco,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = anchor.planIds.length + anchor.habitIds.length;

    return RepaintBoundary(
      child: LiquidPressable(
        onTap: onTap,
        child: LiquidGlassContainer(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          opacity: 0.74,
          borderColor: Colors.white.withOpacity(0.92),
          child: Row(
            children: [
              // Time Badge - 液态透光时钟徽章
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.anchorAccent.withOpacity(0.16),
                      AppColors.anchorAccent.withOpacity(0.06),
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(AppDecorations.radiusMedium),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.8),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.anchorAccent.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
              const SizedBox(width: 14),

              // Name & Count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anchor.name,
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: itemCount > 0
                                ? AppColors.primary.withOpacity(0.12)
                                : Colors.black.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: itemCount > 0
                                  ? AppColors.primary.withOpacity(0.2)
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '$itemCount 个关联项',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: itemCount > 0
                                  ? AppColors.primary
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

              if (onSyncAppleEco != null) ...[
                LiquidPressable(
                  onTap: onSyncAppleEco,
                  pressedScale: 0.90,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppDecorations.radiusSmall),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.8),
                        width: 1,
                      ),
                    ),
                    child: const AppIcon(
                      type: AppIconType.notification,
                      size: 19,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Edit Button
              LiquidPressable(
                onTap: onEdit,
                pressedScale: 0.90,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.anchorAccent.withOpacity(0.09),
                    borderRadius:
                        BorderRadius.circular(AppDecorations.radiusSmall),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.8),
                      width: 1,
                    ),
                  ),
                  child: const AppIcon(
                    type: AppIconType.edit,
                    size: 19,
                    color: AppColors.anchorAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
