import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/theme.dart';
import 'setting_sheet.dart';
import 'analysis_sheet.dart';
import 'help_sheet.dart';
import 'donate_sheet.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _showSettingSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.pop(context); // Close drawer first
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SettingSheet(),
    );
  }

  void _showAnalysisSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.pop(context); // Close drawer first
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const AnalysisSheet(),
    );
  }

  void _showDeepSeekDialog(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.pop(context); // Close drawer first
    SettingSheet.showApiKeyDialog(context);
  }

  void _showHelpSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.pop(context); // Close drawer first
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const HelpSheet(),
    );
  }

  void _showDonateSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.pop(context); // Close drawer first
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const DonateSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: RepaintBoundary(
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 68, 28, 28),
              decoration: BoxDecoration(
                gradient: AppColors.backgroundGradient,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border.withOpacity(0.5),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RepaintBoundary(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: AppDecorations.shadowButton,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.65),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: AppIcon(
                          type: AppIconType.brandLogo,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '微行动',
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const AppIcon(
                        type: AppIconType.apiKey,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '让微小改变自然发生',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                children: [
                  _DrawerItem(
                    icon: AppIconType.data,
                    label: '数据管理',
                    subtitle: '导入与导出你的本地数据',
                    color: AppColors.info,
                    onTap: () => _showSettingSheet(context),
                  ),
                  const SizedBox(height: 12),
                  _DrawerItem(
                    icon: AppIconType.analytics,
                    label: '数据分析',
                    subtitle: '查看你的进步轨迹',
                    color: AppColors.primary,
                    onTap: () => _showAnalysisSheet(context),
                  ),
                  const SizedBox(height: 12),
                  _DrawerItem(
                    icon: AppIconType.apiKey,
                    label: 'DeepSeek 设置',
                    subtitle: '配置 API Key 开启 AI 拆解',
                    color: AppColors.secondary,
                    onTap: () => _showDeepSeekDialog(context),
                  ),
                  const SizedBox(height: 12),
                  _DrawerItem(
                    icon: AppIconType.help,
                    label: '使用帮助',
                    subtitle: '了解福格微习惯行为模型',
                    color: AppColors.success,
                    onTap: () => _showHelpSheet(context),
                  ),
                  const SizedBox(height: 20),

                  // 分割线
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Divider(color: AppColors.border.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 14),

                  // 赞赏支持
                  _DrawerItem(
                    icon: AppIconType.coffee,
                    label: '请作者喝杯咖啡',
                    subtitle: '支持开发者持续更新 ☕',
                    color: const Color(0xFFFF6B35),
                    onTap: () => _showDonateSheet(context),
                  ),
                ],
              ),
            ),

            // Footer
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16, top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'iOS Edition • v1.1.0',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final AppIconType icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppIcon(
                type: icon,
                size: 22,
                color: color,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const AppIcon(
              type: AppIconType.chevronRight,
              size: 18,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
