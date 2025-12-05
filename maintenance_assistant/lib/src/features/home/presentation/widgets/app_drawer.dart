import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import 'setting_sheet.dart';
import 'analysis_sheet.dart';
import 'help_sheet.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _showSettingSheet(BuildContext context) {
    Navigator.pop(context); // Close drawer first
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SettingSheet(),
    );
  }

  void _showAnalysisSheet(BuildContext context) {
    Navigator.pop(context); // Close drawer first
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const AnalysisSheet(),
    );
  }

  void _showHelpSheet(BuildContext context) {
    Navigator.pop(context); // Close drawer first
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const HelpSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: RepaintBoundary(
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 70, 28, 32),
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
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: AppDecorations.shadowButton,
                      ),
                      child: const Center(
                        child: Text('🚀', style: TextStyle(fontSize: 36)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '微行动',
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '让改变发生 ✨',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                children: [
                  _DrawerItem(
                    icon: AppIconType.data,
                    label: '数据管理',
                    subtitle: '导入导出你的数据',
                    color: AppColors.info,
                    onTap: () => _showSettingSheet(context),
                  ),
                  const SizedBox(height: 12),
                  _DrawerItem(
                    icon: AppIconType.analytics,
                    label: '数据分析',
                    subtitle: '查看你的进步轨迹',
                    color: AppColors.secondary,
                    onTap: () => _showAnalysisSheet(context),
                  ),
                  const SizedBox(height: 12),
                  _DrawerItem(
                    icon: AppIconType.help,
                    label: '使用帮助',
                    subtitle: '了解福格行为模型',
                    color: AppColors.success,
                    onTap: () => _showHelpSheet(context),
                  ),
                ],
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'v1.0.0',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppDecorations.radiusSmall),
              ),
              child: AppIcon(
                type: icon,
                size: 22,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
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
            AppIcon(
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
