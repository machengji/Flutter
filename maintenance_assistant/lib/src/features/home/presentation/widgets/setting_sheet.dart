import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/apple_eco_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/services/deepseek_service.dart';
import '../providers/home_provider.dart';

class SettingSheet extends StatefulWidget {
  const SettingSheet({super.key});

  static Future<void> _launchDeepSeekUrl() async {
    final url = Uri.parse('https://platform.deepseek.com/api_keys');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  /// 供侧边栏调用的 DeepSeek API Key 配置弹窗
  static Future<void> showApiKeyDialog(BuildContext context) async {
    HapticFeedback.selectionClick();
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
                color: AppColors.secondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const AppIcon(
                type: AppIconType.apiKey,
                size: 20,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            const Text('DeepSeek AI 设置'),
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
            const SizedBox(height: 20),
            Text('获取方式', style: AppTextStyles.titleSmall),
            const SizedBox(height: 6),
            Text(
              '前往 DeepSeek 开放平台创建 API Key 后粘贴到上方即可开启智能微习惯拆解。',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _launchDeepSeekUrl,
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
              if (controller.text.trim().isEmpty) return;

              HapticFeedback.lightImpact();
              await DeepSeekService().setApiKey(controller.text.trim());
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('API Key 已保存 ✨'),
                    backgroundColor: AppColors.success,
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
  State<SettingSheet> createState() => _SettingSheetState();
}

class _SettingSheetState extends State<SettingSheet> {
  bool _autoFootprint = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadAutoFootprintState();
  }

  Future<void> _loadAutoFootprintState() async {
    final enabled = await AppleEcoService().isAutoFootprintEnabled();
    if (mounted) {
      setState(() => _autoFootprint = enabled);
    }
  }

  Future<void> _toggleAutoFootprint(bool value) async {
    HapticFeedback.selectionClick();
    setState(() => _autoFootprint = value);
    await AppleEcoService().setAutoFootprintEnabled(value);
  }

  Future<void> _handleBatchSync() async {
    if (_isSyncing) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSyncing = true);

    final provider = context.read<HomeProvider>();
    final res = await provider.batchSyncToAppleEco();

    if (!mounted) return;
    setState(() => _isSyncing = false);

    final success = res['success'] == true;
    final syncedPlans = res['syncedPlans'] ?? 0;
    final syncedAnchors = res['syncedAnchors'] ?? 0;
    final listName = res['listName'] ?? '微行动';
    final msg = success
        ? '已同步 $syncedPlans 个计划至「$listName」提醒列表，$syncedAnchors 个锚点至系统日历 ✨'
        : (res['message']?.toString() ?? '同步失败，请检查系统日历与提醒事项权限');

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? AppColors.success : AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    HapticFeedback.selectionClick();
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
                color: AppColors.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('请粘贴导出的 JSON 备份数据：', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 14),
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
              if (controller.text.trim().isEmpty) return;

              final success = await context
                  .read<HomeProvider>()
                  .importData(controller.text.trim());
              if (success) {
                HapticFeedback.mediumImpact();
              } else {
                HapticFeedback.heavyImpact();
              }
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '数据导入成功 ✨' : '导入失败，请检查 JSON 数据格式'),
                    backgroundColor:
                        success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  void _handleExport(BuildContext context) {
    HapticFeedback.lightImpact();
    final jsonString = context.read<HomeProvider>().exportData();
    Clipboard.setData(ClipboardData(text: jsonString));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('全部数据已复制到剪贴板 ✨'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.bottomSheetDecoration,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: AppDecorations.dragHandleDecoration,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const AppIcon(
                      type: AppIconType.data,
                      color: AppColors.info,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('数据管理', style: AppTextStyles.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        '本地备份恢复与 iOS 系统日历/提醒事项联动',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SettingItem(
                icon: AppIconType.upload,
                title: '导出数据',
                subtitle: '将当前全部数据复制到剪贴板',
                color: AppColors.info,
                onTap: () => _handleExport(context),
              ),
              const SizedBox(height: 12),
              _SettingItem(
                icon: AppIconType.download,
                title: '导入数据',
                subtitle: '从 JSON 备份恢复本地数据',
                color: AppColors.warning,
                onTap: () => _showImportDialog(context),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  'iOS 提醒事项与日历联动',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppDecorations.radiusLarge),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.14),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const AppIcon(
                        type: AppIconType.check,
                        color: AppColors.primaryDark,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('打卡足迹自动记入 iOS 日历', style: AppTextStyles.titleSmall),
                          const SizedBox(height: 2),
                          Text(
                            '完成计划或习惯时自动在苹果日历生成时间轴记录',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    CupertinoSwitch(
                      value: _autoFootprint,
                      activeColor: AppColors.primary,
                      onChanged: _toggleAutoFootprint,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SettingItem(
                icon: AppIconType.notification,
                title: _isSyncing ? '正在同步至 iOS 系统...' : '一键同步至提醒事项与日历',
                subtitle: '将进行中计划加入专属「微行动」提醒列表，锚点写入日历',
                color: AppColors.primaryDark,
                onTap: _handleBatchSync,
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDecorations.radiusLarge),
          border: Border.all(
            color: color.withOpacity(0.14),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: AppIcon(type: icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleSmall),
                  const SizedBox(height: 3),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const AppIcon(
              type: AppIconType.chevronRight,
              color: AppColors.textHint,
              size: 18,
            ),
          ],
        ),
      ).animate().fadeIn(duration: 180.ms).slideX(begin: 0.04, end: 0),
    );
  }
}
