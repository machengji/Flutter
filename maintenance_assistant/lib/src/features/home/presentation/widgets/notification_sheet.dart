import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../providers/home_provider.dart';
import '../../../../shared/models/notification_model.dart';
import 'package:intl/intl.dart';
import 'success_popup.dart';

class NotificationSheet extends StatefulWidget {
  const NotificationSheet({super.key});

  @override
  State<NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<NotificationSheet> {
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showSuccessOverlay(String description, String type) {
    _removeOverlay();
    
    _overlayEntry = OverlayEntry(
      builder: (context) => SuccessPopup(
        description: description,
        type: type,
        onClose: _removeOverlay,
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: AppDecorations.bottomSheetDecoration,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                  ),
                  child: const AppIcon(
                    type: AppIconType.notification,
                    size: 22,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  '消息提醒',
                  style: AppTextStyles.titleLarge,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.textHint.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const AppIcon(
                      type: AppIconType.close,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Divider(height: 1, color: AppColors.border.withOpacity(0.5)),

          // List
          Expanded(
            child: Consumer<HomeProvider>(
              builder: (context, provider, child) {
                final notifications = provider.notifications;
                
                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const AppIcon(
                            type: AppIconType.notificationOutlined,
                            size: 48,
                            color: AppColors.textHint,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '暂无消息',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '新消息会在这里显示',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _NotificationItem(
                      notification: notification,
                      provider: provider,
                      onTap: () {
                        if (!notification.isRead) {
                          provider.markNotificationAsRead(notification.id);
                        }
                      },
                      onComplete: () => _handleComplete(notification, provider),
                      onDelete: () {
                        provider.deleteNotification(notification.id);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 处理完成操作：完成关联的计划和习惯
  void _handleComplete(NotificationModel notification, HomeProvider provider) {
    HapticFeedback.mediumImpact();
    
    final anchorId = notification.relatedId;
    if (anchorId == null) return;
    
    // 获取锚点
    try {
      final anchor = provider.anchors.firstWhere((a) => a.id == anchorId);
      
      int completedCount = 0;
      String lastCompletedName = '';
      
      // 完成关联的习惯（打卡一次）
      for (final habitId in anchor.habitIds) {
        try {
          final habit = provider.activeHabits.firstWhere((h) => h.id == habitId);
          // 只对进行中的习惯打卡
          if (habit.status == '进行中') {
            provider.checkHabit(habitId);
            completedCount++;
            lastCompletedName = habit.name;
          }
        } catch (_) {
          // 习惯不存在，跳过
        }
      }
      
      // 完成关联的计划（标记为已完成）
      for (final planId in anchor.planIds) {
        try {
          final plan = provider.ongoingPlans.firstWhere((p) => p.id == planId);
          // 只对进行中的计划标记完成
          if (plan.status != '已完成') {
            provider.togglePlanStatus(planId);
            completedCount++;
            lastCompletedName = plan.name;
          }
        } catch (_) {
          // 计划不存在，跳过
        }
      }
      
      // 标记通知任务已完成
      provider.markNotificationAsCompleted(notification.id);
      
      // 显示成功弹框或提示
      if (completedCount > 0) {
        final description = completedCount == 1 
            ? lastCompletedName 
            : '$completedCount 个任务';
        
        // 使用 Overlay 显示成功弹框
        _showSuccessOverlay(description, 'action');
        
        // 刷新彩虹屁
        provider.refreshRainbowFart();
      } else {
        // 没有可完成的任务（但仍点击了完成）
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Text('✅', style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Text('任务已全部完成'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (_) {
      // 锚点不存在
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('锚点已被删除'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final HomeProvider provider;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _NotificationItem({
    required this.notification,
    required this.provider,
    required this.onTap,
    required this.onComplete,
    required this.onDelete,
  });

  /// 检查是否有可完成的任务
  bool get _hasCompletableItems {
    // 如果通知已标记为完成，直接返回 false
    if (notification.isCompleted) return false;
    
    final anchorId = notification.relatedId;
    if (anchorId == null || notification.type != 'anchor') return false;
    
    try {
      final anchor = provider.anchors.firstWhere((a) => a.id == anchorId);
      
      // 检查是否有进行中的习惯
      final hasActiveHabits = anchor.habitIds.any((habitId) {
        try {
          final habit = provider.activeHabits.firstWhere((h) => h.id == habitId);
          return habit.status == '进行中';
        } catch (_) {
          return false;
        }
      });
      
      // 检查是否有未完成的计划
      final hasOngoingPlans = anchor.planIds.any((planId) {
        try {
          final plan = provider.ongoingPlans.firstWhere((p) => p.id == planId);
          return plan.status != '已完成';
        } catch (_) {
          return false;
        }
      });
      
      return hasActiveHabits || hasOngoingPlans;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(notification.timestamp);
    final timeStr = DateFormat('MM-dd HH:mm').format(date);
    final hasCompletable = _hasCompletableItems;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
        ),
        child: const AppIcon(
          type: AppIconType.delete,
          size: 24,
          color: Colors.white,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: notification.isRead ? AppColors.surfaceVariant : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
            border: Border.all(
              color: notification.isRead 
                  ? AppColors.border 
                  : AppColors.primary.withOpacity(0.25),
              width: notification.isRead ? 1 : 1.5,
            ),
            boxShadow: notification.isRead ? null : [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!notification.isRead)
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      notification.title,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    timeStr,
                    style: AppTextStyles.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                notification.body,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              
              // 完成按钮（仅锚点类型通知显示）
              if (notification.type == 'anchor') ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Spacer(),
                    GestureDetector(
                      onTap: hasCompletable ? onComplete : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: hasCompletable ? const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ) : null,
                          color: hasCompletable ? null : AppColors.border,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: hasCompletable ? [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ] : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasCompletable ? Icons.check_circle_outline : Icons.check_circle,
                              size: 16,
                              color: hasCompletable ? Colors.white : AppColors.textHint,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              hasCompletable ? '完成任务' : '已完成',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: hasCompletable ? Colors.white : AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
