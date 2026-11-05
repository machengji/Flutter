import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/models/plan_model.dart';
import '../providers/home_provider.dart';

/// 侧边栏专属：已归档任务（暂非未来重点）专区弹窗
class ArchiveSheet extends StatelessWidget {
  const ArchiveSheet({super.key});

  String _formatDate(int timestamp) {
    if (timestamp <= 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy/MM/dd').format(date);
  }

  void _restorePlan(BuildContext context, HomeProvider provider, Plan plan) {
    HapticFeedback.mediumImpact();
    provider.unarchivePlan(plan.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已将「${plan.name}」恢复为进行中重点'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmDeletePlan(BuildContext context, HomeProvider provider, Plan plan) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusLarge),
        ),
        title: const Text('删除任务'),
        content: Text('确定要彻底删除已归档的「${plan.name}」吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              provider.deletePlan(plan.id);
            },
            child: const Text('彻底删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: AppDecorations.bottomSheetDecoration,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部拖拽把手
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 12),
              child: Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: AppDecorations.dragHandleDecoration,
                ),
              ),
            ),

            // Header 标题栏
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const AppIcon(
                      type: AppIconType.archive,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('已归档任务', style: AppTextStyles.titleLarge),
                            const SizedBox(width: 8),
                            Consumer<HomeProvider>(
                              builder: (context, provider, _) {
                                final count = provider.archivedPlans.length;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: AppTextStyles.badge.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '未来不在重点上，可随时一键恢复到进行中',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textHint),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.border),

            // 任务列表 / 空状态
            Expanded(
              child: Consumer<HomeProvider>(
                builder: (context, provider, _) {
                  final archived = provider.archivedPlans;

                  if (archived.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.border.withOpacity(0.4),
                                ),
                              ),
                              child: const AppIcon(
                                type: AppIconType.archive,
                                size: 40,
                                color: AppColors.textHint,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              '暂无已归档任务',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '在主页长按或展开进行中的计划卡片，点击归档按钮即可移入此处，远离核心视线，专注于当下重点。',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textHint,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    itemCount: archived.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final plan = archived[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppDecorations.radiusMedium),
                          border: Border.all(
                            color: AppColors.border.withOpacity(0.6),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // 左侧档案盒图标
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.textSecondary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const AppIcon(
                                type: AppIconType.archive,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // 中间标题与创建时间
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plan.name,
                                    style: AppTextStyles.cardTitle.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '创建于 ${_formatDate(plan.createTime)} · 暂非重点',
                                    style: AppTextStyles.cardSubtitle.copyWith(
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),

                            // 恢复重点按钮
                            GestureDetector(
                              onTap: () =>
                                  _restorePlan(context, provider, plan),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.25),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const AppIcon(
                                      type: AppIconType.refresh,
                                      size: 13,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '恢复重点',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // 彻底删除按钮
                            GestureDetector(
                              onTap: () =>
                                  _confirmDeletePlan(context, provider, plan),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const AppIcon(
                                  type: AppIconType.delete,
                                  size: 15,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
