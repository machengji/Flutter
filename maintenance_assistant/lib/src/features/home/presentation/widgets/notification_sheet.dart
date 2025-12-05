import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../providers/home_provider.dart';
import '../../../../shared/models/notification_model.dart';
import 'package:intl/intl.dart';

class NotificationSheet extends StatelessWidget {
  const NotificationSheet({super.key});

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
                      onTap: () {
                        if (!notification.isRead) {
                          provider.markNotificationAsRead(notification.id);
                        }
                      },
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
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(notification.timestamp);
    final timeStr = DateFormat('MM-dd HH:mm').format(date);

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
            ],
          ),
        ),
      ),
    );
  }
}
