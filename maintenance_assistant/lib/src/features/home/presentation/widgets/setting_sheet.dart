import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/services/deepseek_service.dart';
import '../providers/home_provider.dart';
import 'donate_sheet.dart';

class SettingSheet extends StatelessWidget {
  const SettingSheet({super.key});

  Future<void> _launchUrl() async {
    final url = Uri.parse('https://platform.deepseek.com/api_keys');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _showApiKeyDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final currentKey = prefs.getString('deepseek_api_key') ?? '';
    final controller = TextEditingController(text: currentKey);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const AppIcon(
                type: AppIconType.apiKey,
                size: 20,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            const Text('配置 DeepSeek Key'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('请输入你的 API Key：', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: AppDecorations.inputDecoration(
                hintText: 'sk-...',
              ),
            ),
            const SizedBox(height: 24),
            Text('获取方式', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            Text(
              'DeepSeek 暂未开放自动获取 Key 的接口，请前往官网创建后再粘贴回来。',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _launchUrl,
                icon: const AppIcon(
                  type: AppIconType.explore,
                  size: 16,
                  color: AppColors.secondary,
                ),
                label: const Text('前往 DeepSeek 官网'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(color: AppColors.secondary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;

              await DeepSeekService().setApiKey(controller.text);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('API Key 已保存'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const AppIcon(
                type: AppIconType.download,
                size: 20,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            const Text('导入数据'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('请粘贴导出的 JSON 数据：', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: AppDecorations.inputDecoration(
                hintText: '{"plans": [...], "habits": [...]}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;

              final success = await context.read<HomeProvider>().importData(controller.text);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              if (context.mounted) {
                Navigator.pop(context);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? '导入成功' : '导入失败，请检查数据格式'),
                  backgroundColor: success ? AppColors.success : AppColors.error,
                ),
              );
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  void _handleExport(BuildContext context) {
    final jsonString = context.read<HomeProvider>().exportData();
    Clipboard.setData(ClipboardData(text: jsonString));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('数据已复制到剪贴板'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _handleCloudBackup(BuildContext context) async {
    final provider = context.read<HomeProvider>();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);

    try {
      final result = await provider.backupToCloud();
      final syncKey = result['syncKey']?.toString() ?? '';
      messenger.showSnackBar(
        SnackBar(
          content: Text('云端备份成功，同步码：$syncKey'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('云端备份失败：$e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showCloudRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusLarge),
        ),
        title: const Text('恢复云端数据'),
        content: const Text('会用 LeanCloud 中的备份覆盖当前本地数据，确定继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = context.read<HomeProvider>();
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogContext);
              Navigator.pop(context);

              try {
                final success = await provider.restoreFromCloud();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(success ? '云端恢复成功' : '没有找到可恢复的云端备份'),
                    backgroundColor: success ? AppColors.success : AppColors.warning,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('云端恢复失败：$e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('恢复'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCloudSyncKeyDialog(BuildContext context) async {
    final provider = context.read<HomeProvider>();
    final currentKey = await provider.getCloudSyncKey();
    final controller = TextEditingController(text: currentKey);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusLarge),
        ),
        title: const Text('同步码设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前同步码：', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: AppDecorations.inputDecoration(
                hintText: '输入或粘贴同步码',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '重装或换设备后，填回这个同步码就可以恢复同一份云端备份。',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: controller.text.trim()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('同步码已复制'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('复制'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await provider.setCloudSyncKey(controller.text);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('同步码已保存'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('保存同步码失败：$e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: AppDecorations.bottomSheetDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: AppDecorations.dragHandleDecoration,
            ),
          ),
          const SizedBox(height: 24),
          Text('数据管理', style: AppTextStyles.titleLarge),
          const SizedBox(height: 28),
          _SettingItem(
            icon: AppIconType.upload,
            title: '导出数据',
            subtitle: '将当前数据复制到剪贴板',
            color: AppColors.info,
            onTap: () => _handleExport(context),
          ),
          const SizedBox(height: 16),
          _SettingItem(
            icon: AppIconType.download,
            title: '导入数据',
            subtitle: '从 JSON 恢复本地数据',
            color: AppColors.warning,
            onTap: () => _showImportDialog(context),
          ),
          const SizedBox(height: 16),
          _SettingItem(
            icon: AppIconType.upload,
            title: '云端备份',
            subtitle: '把当前全部数据保存到 LeanCloud',
            color: AppColors.success,
            onTap: () => _handleCloudBackup(context),
          ),
          const SizedBox(height: 16),
          _SettingItem(
            icon: AppIconType.download,
            title: '云端恢复',
            subtitle: '从 LeanCloud 恢复当前同步码对应的数据',
            color: AppColors.info,
            onTap: () => _showCloudRestoreDialog(context),
          ),
          const SizedBox(height: 16),
          _SettingItem(
            icon: AppIconType.apiKey,
            title: '同步码设置',
            subtitle: '查看、复制或修改当前云同步码',
            color: AppColors.primary,
            onTap: () => _showCloudSyncKeyDialog(context),
          ),
          const SizedBox(height: 16),
          _SettingItem(
            icon: AppIconType.apiKey,
            title: 'DeepSeek 设置',
            subtitle: '配置 API Key 以使用 AI 功能',
            color: AppColors.secondary,
            onTap: () => _showApiKeyDialog(context),
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),
          _SettingItem(
            icon: AppIconType.coffee,
            title: '请作者喝杯咖啡',
            subtitle: '如果这个应用帮到了你，可以支持一下',
            color: const Color(0xFFFF6B35),
            onTap: () => _showDonateSheet(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showDonateSheet(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const DonateSheet(),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final AppIconType icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SettingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
              ),
              child: AppIcon(type: icon, color: color, size: 24),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleSmall),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const AppIcon(
              type: AppIconType.chevronRight,
              color: AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack);
  }
}
