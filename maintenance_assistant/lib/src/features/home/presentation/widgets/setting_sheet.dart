import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/services/deepseek_service.dart';
import '../providers/home_provider.dart';
import 'donate_sheet.dart';

class SettingSheet extends StatelessWidget {
  const SettingSheet({super.key});

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse('https://platform.deepseek.com/api_keys');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  void _showApiKeyDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final currentKey = prefs.getString('deepseek_api_key') ?? '';
    final controller = TextEditingController(text: currentKey);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
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
                  Text('请输入您的 API Key：', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    decoration: AppDecorations.inputDecoration(
                      hintText: 'sk-...',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('如何获取 Key？', style: AppTextStyles.titleSmall),
                  const SizedBox(height: 8),
                  Text(
                    'DeepSeek 暂未开放自动获取 Key 的接口。为了您的账号安全，请前往官网获取：',
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
                      label: const Text('前往 DeepSeek 官网获取'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        side: const BorderSide(color: AppColors.secondary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '步骤：\n'
                    '1. 点击上方按钮打开官网\n'
                    '2. 登录账号 (支持手机号验证码登录)\n'
                    '3. 点击 "Create new API Key"\n'
                    '4. 复制 Key 并粘贴到上方输入框',
                    style: AppTextStyles.bodySmall.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDecorations.radiusSmall),
                      border: Border.all(color: AppColors.warning.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        AppIcon(
                          type: AppIconType.notification,
                          size: 18,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'DeepSeek 免费额度可以用非常久，几年起步！',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (controller.text.isNotEmpty) {
                      await DeepSeekService().setApiKey(controller.text);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('API Key 已保存'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showImportDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final success = await context.read<HomeProvider>().importData(controller.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? '导入成功！' : '导入失败，请检查数据格式'),
                      backgroundColor: success ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              }
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
      SnackBar(
        content: const Text('数据已复制到剪贴板'),
        backgroundColor: AppColors.success,
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
          // Header
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

          // Options
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
            subtitle: '从剪贴板粘贴数据并恢复',
            color: AppColors.warning,
            onTap: () => _showImportDialog(context),
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
          
          // Divider
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),
          
          // 赞赏支持入口
          _SettingItem(
            icon: AppIconType.coffee,
            title: '请作者喝杯咖啡',
            subtitle: '如果微行动对你有帮助，可以支持一下 💝',
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
