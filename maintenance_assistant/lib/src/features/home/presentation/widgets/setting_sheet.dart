import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/apple_eco_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/utils/backup_file_service.dart';
import '../providers/home_provider.dart';

class SettingSheet extends StatefulWidget {
  const SettingSheet({super.key});

  @override
  State<SettingSheet> createState() => _SettingSheetState();
}

class _SettingSheetState extends State<SettingSheet> {
  bool _autoFootprint = true;
  bool _twoWaySync = true;
  bool _syncAnchorToCalendar = false;
  bool _isSyncing = false;
  bool _isTwoWaySyncing = false;
  bool _isSyncingCalendar = false;
  bool _isCleaningCalendar = false;

  @override
  void initState() {
    super.initState();
    _loadAppleEcoSettings();
  }

  Future<void> _loadAppleEcoSettings() async {
    final eco = AppleEcoService();
    final footprint = await eco.isAutoFootprintEnabled();
    final twoWay = await eco.isTwoWaySyncEnabled();
    final anchorCal = await eco.isSyncAnchorToCalendarEnabled();
    if (mounted) {
      setState(() {
        _autoFootprint = footprint;
        _twoWaySync = twoWay;
        _syncAnchorToCalendar = anchorCal;
      });
    }
  }

  Future<void> _toggleTwoWaySync(bool value) async {
    HapticFeedback.selectionClick();
    setState(() => _twoWaySync = value);
    await AppleEcoService().setTwoWaySyncEnabled(value);
    if (value && mounted) {
      context.read<HomeProvider>().syncWithReminders();
    }
  }

  Future<void> _toggleAutoFootprint(bool value) async {
    HapticFeedback.selectionClick();
    setState(() => _autoFootprint = value);
    await AppleEcoService().setAutoFootprintEnabled(value);
  }

  Future<void> _toggleSyncAnchorToCalendar(bool value) async {
    HapticFeedback.selectionClick();
    setState(() => _syncAnchorToCalendar = value);
    await AppleEcoService().setSyncAnchorToCalendarEnabled(value);
  }

  Future<void> _handleClearAnchorCalendarEvents() async {
    if (_isCleaningCalendar) return;
    HapticFeedback.heavyImpact();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const AppIcon(
                type: AppIconType.delete,
                size: 20,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            const Text('清理日历中的锚点日程'),
          ],
        ),
        content: Text(
          '是否确定从系统日历中清理所有由「微行动」创建的时间锚点日程？\n\n这会彻底清除铺满日历的重复锚点事件，已打卡的足迹与 App 内的锚点不受影响。',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('立即清理'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isCleaningCalendar = true);
    final provider = context.read<HomeProvider>();
    final res = await provider.clearAllAnchorCalendarEvents();

    if (!mounted) return;
    setState(() => _isCleaningCalendar = false);

    final success = res['success'] == true;
    final count = res['deletedCount'] ?? 0;
    final msg = success
        ? '已成功从系统日历清理 $count 个锚点日程，日历已恢复清爽'
        : (res['message']?.toString() ?? '清理失败，请检查系统日历权限');

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? AppColors.success : AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleTwoWaySync() async {
    if (_isTwoWaySyncing) return;
    HapticFeedback.mediumImpact();
    setState(() => _isTwoWaySyncing = true);

    final provider = context.read<HomeProvider>();
    final res = await provider.syncWithReminders(isManual: true);

    if (!mounted) return;
    setState(() => _isTwoWaySyncing = false);

    final success = res['success'] == true;
    final imported = res['imported'] ?? 0;
    final completed = res['completed'] ?? 0;
    final deleted = res['deleted'] ?? 0;
    final msg = success
        ? '双向对齐完成：导入 $imported 项，同步打卡 $completed 项，移除 $deleted 项'
        : (res['message']?.toString() ?? '双向对齐失败，请检查系统提醒事项权限');

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? AppColors.success : AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleSyncCompletedToCalendar() async {
    if (_isSyncingCalendar) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSyncingCalendar = true);

    final provider = context.read<HomeProvider>();
    final res = await provider.syncCompletedPlansToCalendar();

    if (!mounted) return;
    setState(() => _isSyncingCalendar = false);

    final success = res['success'] == true;
    final recorded = res['recordedCount'] ?? 0;
    final skipped = res['skippedCount'] ?? 0;
    final msg = success
        ? (res['message']?.toString() ?? '已将 $recorded 个已完成任务补录至系统日历日程（$skipped 个已存在）')
        : (res['message']?.toString() ?? '补录失败，请检查系统日历权限');

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? AppColors.success : AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleBatchSync() async {
    if (_isSyncing) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSyncing = true);

    final provider = context.read<HomeProvider>();
    final res = await provider.batchSyncToAppleEco(
      syncAnchorToCalendar: _syncAnchorToCalendar,
    );

    if (!mounted) return;
    setState(() => _isSyncing = false);

    final success = res['success'] == true;
    final syncedPlans = res['syncedPlans'] ?? 0;
    final syncedAnchors = res['syncedAnchors'] ?? 0;
    final listName = res['listName'] ?? '微行动';
    final anchorDest = _syncAnchorToCalendar ? '与系统日历' : '';
    final msg = success
        ? '已同步 $syncedPlans 个计划至「$listName」提醒列表，$syncedAnchors 个锚点至系统提醒事项$anchorDest'
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

  Future<void> _handleExportFile(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final jsonString = context.read<HomeProvider>().exportData();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = '微行动备份_$timestamp.json';

    final success = await BackupFileService.exportBackupFile(jsonString, fileName);
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '备份文件已成功生成并调起分享' : '已将备份数据复制到剪贴板'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _handleImportFile(BuildContext context) async {
    HapticFeedback.selectionClick();
    final jsonString = await BackupFileService.pickBackupFile();
    if (jsonString == null || jsonString.trim().isEmpty) {
      return; // 用户取消了文件选择
    }

    if (!context.mounted) return;
    final success = await context.read<HomeProvider>().importData(jsonString.trim());
    if (success) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }

    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '数据合并恢复成功，已自动对齐提醒事项' : '导入失败，请检查是否为有效的微行动备份文件'),
        backgroundColor: success ? AppColors.success : AppColors.error,
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
            const Text('导入数据文本'),
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
                    content: Text(success ? '数据合并恢复成功，已自动对齐提醒事项' : '导入失败，请检查 JSON 数据格式'),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('数据管理', style: AppTextStyles.titleLarge),
                        const SizedBox(height: 2),
                        Text(
                          '本地备份恢复与 iOS 系统日历/提醒事项联动',
                          style: AppTextStyles.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SettingItem(
                      icon: AppIconType.upload,
                      title: '导出备份文件 (.json)',
                      subtitle: '生成 JSON 备份文件，支持保存至“文件”或分享',
                      color: AppColors.info,
                      onTap: () => _handleExportFile(context),
                    ),
                    const SizedBox(height: 12),
                    _SettingItem(
                      icon: AppIconType.download,
                      title: '从文件恢复数据',
                      subtitle: '选择 .json 备份文件一键恢复本地数据',
                      color: AppColors.warning,
                      onTap: () => _handleImportFile(context),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: TextButton(
                        onPressed: () => _showImportDialog(context),
                        child: Text(
                          '或手动粘贴文本备份',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textHint,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
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
                              type: AppIconType.notification,
                              color: AppColors.primaryDark,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('与 iOS 提醒事项双向实时对齐', style: AppTextStyles.titleSmall),
                                const SizedBox(height: 2),
                                Text(
                                  '实时双向同步完成打卡，支持 Siri / 系统提醒外部新增自动导入',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          CupertinoSwitch(
                            value: _twoWaySync,
                            activeColor: AppColors.primary,
                            onChanged: _toggleTwoWaySync,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
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
                              type: AppIconType.anchor,
                              color: AppColors.primaryDark,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('时间锚点同步至系统日历', style: AppTextStyles.titleSmall),
                                const SizedBox(height: 2),
                                Text(
                                  '开启后锚点将每日写入日历；关闭后仅在 App 与提醒事项生效，避免日历刷屏',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          CupertinoSwitch(
                            value: _syncAnchorToCalendar,
                            activeColor: AppColors.primary,
                            onChanged: _toggleSyncAnchorToCalendar,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SettingItem(
                      icon: AppIconType.refresh,
                      title: _isTwoWaySyncing ? '正在与系统提醒事项双向对齐...' : '立即双向对齐同步',
                      subtitle: '一键拉取系统勾选打卡、自动导入外部新增项并同步清理',
                      color: AppColors.primaryDark,
                      onTap: _handleTwoWaySync,
                    ),
                    const SizedBox(height: 12),
                    _SettingItem(
                      icon: AppIconType.notification,
                      title: _isSyncing ? '正在同步至 iOS 系统...' : '一键同步至系统提醒${_syncAnchorToCalendar ? "与日历" : ""}',
                      subtitle: _syncAnchorToCalendar
                          ? '将进行中计划加入提醒列表，锚点写入系统日历'
                          : '将进行中计划加入专属「微行动」提醒列表，锚点同步至系统提醒事项',
                      color: AppColors.primaryDark,
                      onTap: _handleBatchSync,
                    ),
                    const SizedBox(height: 12),
                    _SettingItem(
                      icon: AppIconType.check,
                      title: _isSyncingCalendar ? '正在补录已完成任务至日历...' : '补录已完成任务至日历日程',
                      subtitle: '自动按任务真实完成时间写入系统日历，智能去重防重复',
                      color: AppColors.primaryDark,
                      onTap: _handleSyncCompletedToCalendar,
                    ),
                    const SizedBox(height: 12),
                    _SettingItem(
                      icon: AppIconType.delete,
                      title: _isCleaningCalendar ? '正在从日历清理锚点日程...' : '一键清理日历中的锚点日程',
                      subtitle: '彻底清除日历中被铺满的重复锚点日程，还系统日历清爽空间',
                      color: AppColors.error,
                      onTap: _handleClearAnchorCalendarEvents,
                    ),
                    const SizedBox(height: 16),
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
