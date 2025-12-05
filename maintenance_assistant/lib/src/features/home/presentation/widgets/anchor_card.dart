import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/models/anchor_model.dart';

class AnchorCard extends StatelessWidget {
  final Anchor anchor;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AnchorCard({
    super.key,
    required this.anchor,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = anchor.planIds.length + anchor.habitIds.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: AppDecorations.anchorCardDecoration,
        child: Row(
          children: [
            // Time Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.anchorAccent.withOpacity(0.12),
                    AppColors.anchorAccent.withOpacity(0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                border: Border.all(
                  color: AppColors.anchorAccent.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
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
            const SizedBox(width: 16),
            
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                    ],
                  ),
                ],
              ),
            ),

            // Edit Button
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.anchorAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppDecorations.radiusSmall),
                ),
                child: const AppIcon(
                  type: AppIconType.edit,
                  size: 20,
                  color: AppColors.anchorAccent,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0),
    );
  }
}
