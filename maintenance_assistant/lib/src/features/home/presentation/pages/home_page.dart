import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/theme.dart';
import '../providers/home_provider.dart';
import '../widgets/immersive_background.dart';
import '../widgets/plan_card.dart';
import '../widgets/habit_card.dart';
import '../widgets/add_modal.dart';
import '../widgets/detail_sheet.dart';
import '../widgets/success_popup.dart';
import '../widgets/app_drawer.dart';
import '../widgets/anchor_card.dart';
import '../widgets/add_anchor_modal.dart';
import '../widgets/anchor_detail_sheet.dart';
import '../../../../shared/models/plan_model.dart';
import '../../../../shared/models/habit_model.dart';
import '../../../../shared/models/anchor_model.dart';
import '../../../../core/services/apple_eco_service.dart';
import '../widgets/notification_sheet.dart';
import '../widgets/welcome_sheet.dart';
import '../widgets/shader_warmup_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _currentView = 'plans'; // 'plans' or 'habits'
  String? _expandedCardId;
  String? _expandedHabitId;
  String? _expandedHabitSource; // 'active' or 'completed'
  
  // Success Popup State
  bool _showSuccessPopup = false;
  String _successDescription = '';
  String _successType = 'action';
  
  // Shader 预热状态
  bool _isWarmingUp = true;

  void _switchView(String view) {
    if (_currentView != view) {
      HapticFeedback.selectionClick();
    }
    setState(() {
      _currentView = view;
      _expandedCardId = null;
      _expandedHabitId = null;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkFirstTimeUse();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 当应用从后台恢复到前台时，检查锚点通知
    if (state == AppLifecycleState.resumed) {
      context.read<HomeProvider>().checkAnchorNotifications();
    }
  }

  Future<void> _checkFirstTimeUse() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;
    
    if (!hasSeenWelcome && mounted) {
      // 延迟显示，等待页面加载完成
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          isDismissible: false,
          enableDrag: false,
          builder: (context) => const WelcomeSheet(),
        );
        await prefs.setBool('has_seen_welcome', true);
      }
    }
  }

  void _showAddModal() {
    HapticFeedback.lightImpact();
    if (_currentView == 'anchors') {
      showDialog(
        context: context,
        builder: (context) => AddAnchorModal(
          onAdd: (name, time) {
            context.read<HomeProvider>().addAnchor(name, time);
          },
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddModal(
        title: _currentView == 'plans' ? '新计划' : '新习惯',
        placeholder: _currentView == 'plans' ? '输入你的梦想...' : '输入你的习惯...',
        onConfirm: (text) {
          final provider = context.read<HomeProvider>();
          if (_currentView == 'plans') {
            provider.addPlan(text);
          } else {
            provider.addHabit(text);
          }
        },
      ),
    );
  }

  void _triggerSuccess(String description, String type) {
    HapticFeedback.mediumImpact();
    // 延迟显示弹框,让列表收缩动画先完成,避免动画冲突
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _showSuccessPopup = true;
          _successDescription = description;
          _successType = type;
        });
      }
    });
  }

  void _showEditModal(Plan plan) {
    showDialog(
      context: context,
      builder: (context) => AddModal(
        title: '编辑计划',
        placeholder: '输入你的梦想...',
        initialValue: plan.name,
        onConfirm: (text) {
          context.read<HomeProvider>().updatePlan(plan.id, text);
          setState(() => _expandedCardId = null);
        },
      ),
    );
  }

  void _showDetailSheet(Plan plan) {
    // 计算新的分解层级 = 父计划层级 + 1
    final newDecompositionLevel = plan.decompositionLevel + 1;
    
    // 获取或继承分组颜色索引：
    // - 如果父计划已有颜色索引（>= 0），则继承
    // - 如果父计划没有颜色索引（-1），说明是第一次分解，获取新索引
    final provider = context.read<HomeProvider>();
    final groupColorIndex = plan.groupColorIndex >= 0 
        ? plan.groupColorIndex 
        : provider.getNextGroupColorIndex();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DetailSheet(
        planName: plan.name,
        onTagSelected: (tag) {
          context.read<HomeProvider>().addPlan(
            tag,
            parentId: plan.id,
            decompositionLevel: newDecompositionLevel,
            groupColorIndex: groupColorIndex,
          );
          setState(() => _expandedCardId = null);
        },
      ),
    );
  }

  void _showEditHabitModal(Habit habit) {
    showDialog(
      context: context,
      builder: (context) => AddModal(
        title: '编辑习惯',
        placeholder: '输入你的习惯...',
        initialValue: habit.name,
        onConfirm: (text) {
          context.read<HomeProvider>().updateHabit(habit.id, text);
          setState(() => _expandedHabitId = null);
        },
      ),
    );
  }

  void _showHabitDetailSheet(Habit habit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DetailSheet(
        planName: habit.name,
        onTagSelected: (tag) {
          context.read<HomeProvider>().addHabit(tag);
          setState(() => _expandedHabitId = null);
        },
      ),
    );
  }

  Future<void> _addPlanReminderNow(Plan plan, {int? alarmEpochMs}) async {
    HapticFeedback.mediumImpact();
    final res = await AppleEcoService().addPlanToReminders(
      title: plan.name,
      notes: '来自「微行动助手」的梦想计划',
      alarmEpochMs: alarmEpochMs,
    );
    if (!mounted) return;
    setState(() => _expandedCardId = null);
    final success = res['success'] == true;
    final listName = res['listName'] ?? '微行动';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '已将「${plan.name}」加入 iOS 提醒事项『$listName』列表 ✨'
              : (res['message']?.toString() ?? '写入提醒事项失败'),
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  void _showAddPlanReminderSheet(Plan plan) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        decoration: AppDecorations.bottomSheetDecoration,
        child: SafeArea(
          top: false,
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
                      type: AppIconType.notification,
                      size: 22,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('加入 iOS 提醒事项', style: AppTextStyles.titleLarge),
                        const SizedBox(height: 2),
                        Text(
                          '自动归入专属「微行动」提醒列表',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.pop(sheetContext);
                  _addPlanReminderNow(plan);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppDecorations.radiusLarge),
                    border: Border.all(color: AppColors.primary.withOpacity(0.16)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const AppIcon(
                          type: AppIconType.check,
                          color: AppColors.primaryDark,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('直接加入「微行动」提醒列表', style: AppTextStyles.titleSmall),
                            const SizedBox(height: 2),
                            Text('不设特定闹钟，随时在系统提醒事项中查看勾选', style: AppTextStyles.bodySmall),
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
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final now = TimeOfDay.now();
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: (now.hour + 1) % 24,
                      minute: 0,
                    ),
                    helpText: '选择提醒时间',
                  );
                  if (picked == null || !mounted) return;
                  final current = DateTime.now();
                  var targetDate = DateTime(
                    current.year,
                    current.month,
                    current.day,
                    picked.hour,
                    picked.minute,
                  );
                  if (targetDate.isBefore(current)) {
                    targetDate = targetDate.add(const Duration(days: 1));
                  }
                  await _addPlanReminderNow(
                    plan,
                    alarmEpochMs: targetDate.millisecondsSinceEpoch,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppDecorations.radiusLarge),
                    border: Border.all(color: AppColors.info.withOpacity(0.16)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const AppIcon(
                          type: AppIconType.notification,
                          color: AppColors.info,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('设置提醒时间后加入', style: AppTextStyles.titleSmall),
                            const SizedBox(height: 2),
                            Text('到点触发 iOS 系统级提醒事项推送', style: AppTextStyles.bodySmall),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSyncAnchor(Anchor anchor) async {
    HapticFeedback.mediumImpact();
    final res = await context.read<HomeProvider>().syncAnchorToAppleEco(anchor);
    if (!mounted) return;
    final success = res['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '已将锚点「${anchor.name} (${anchor.time})」同步至 iOS 日历与『微行动』提醒事项 ✨'
              : (res['message']?.toString() ?? '同步锚点失败'),
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bottomBarOffset = 24.0 + (bottomInset > 0 ? bottomInset * 0.5 : 12.0);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          const ImmersiveBackground(),
          
          // Shader 预热组件（在后台以极低透明度渲染）
          if (_isWarmingUp)
            ShaderWarmupWidget(
              onWarmupComplete: () {
                if (mounted) {
                  setState(() => _isWarmingUp = false);
                }
              },
            ),
          
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      // Menu Button
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _scaffoldKey.currentState?.openDrawer();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.92),
                            shape: BoxShape.circle,
                            boxShadow: AppDecorations.shadowSoft,
                          ),
                          child: const AppIcon(
                            type: AppIconType.menu,
                            size: 22,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        '微行动',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 今日行动计数激励微胶囊
                      Consumer<HomeProvider>(
                        builder: (context, provider, child) {
                          final todayCount = provider.todayActionCount;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: todayCount > 0
                                  ? AppColors.primary.withOpacity(0.12)
                                  : AppColors.surface.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: todayCount > 0
                                    ? AppColors.primary.withOpacity(0.28)
                                    : AppColors.textHint.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppIcon(
                                  type: todayCount > 0
                                      ? AppIconType.explore
                                      : AppIconType.brandLogo,
                                  size: 13,
                                  color: todayCount > 0
                                      ? AppColors.primaryDark
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  todayCount > 0
                                      ? '今日已行动 $todayCount 次'
                                      : '今日待微行动',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: todayCount > 0
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: todayCount > 0
                                        ? AppColors.primaryDark
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      
                      // Notification Button
                      Consumer<HomeProvider>(
                        builder: (context, provider, child) {
                          final unreadCount = provider.unreadNotificationCount;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                builder: (context) => const NotificationSheet(),
                              );
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface.withOpacity(0.92),
                                    shape: BoxShape.circle,
                                    boxShadow: AppDecorations.shadowSoft,
                                  ),
                                  child: const AppIcon(
                                    type: AppIconType.notificationOutlined,
                                    size: 22,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 18,
                                        minHeight: 18,
                                      ),
                                      child: Text(
                                        unreadCount > 99 ? '99+' : '$unreadCount',
                                        style: AppTextStyles.badge,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Content
                Expanded(
                  child: Consumer<HomeProvider>(
                    builder: (context, provider, child) {
                      return CustomScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        cacheExtent: 500, // 增加缓存区域提高滚动流畅度
                        slivers: [
                          if (_currentView == 'plans') ..._buildPlansSlivers(provider),
                          if (_currentView == 'habits') ..._buildHabitsSlivers(provider),
                          if (_currentView == 'anchors') ..._buildAnchorsSlivers(provider),
                          const SliverPadding(padding: EdgeInsets.only(bottom: 130)),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // View Switcher
          Positioned(
            left: 24,
            bottom: bottomBarOffset,
            child: RepaintBoundary(
              child: _LiquidGlassContainer(
                padding: const EdgeInsets.all(5),
                child: Row(
                  children: [
                    _SwitchButton(
                      text: '计划',
                      icon: AppIconType.plan,
                      isActive: _currentView == 'plans',
                      onTap: () => _switchView('plans'),
                    ),
                    _SwitchButton(
                      text: '习惯',
                      icon: AppIconType.habit,
                      isActive: _currentView == 'habits',
                      onTap: () => _switchView('habits'),
                    ),
                    _SwitchButton(
                      text: '锚点',
                      icon: AppIconType.anchor,
                      isActive: _currentView == 'anchors',
                      onTap: () => _switchView('anchors'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // FAB
          Positioned(
            right: 24,
            bottom: bottomBarOffset,
            child: RepaintBoundary(
              child: GestureDetector(
                onTap: _showAddModal,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: AppDecorations.shadowButton,
                  ),
                  child: const Center(
                    child: AppIcon(
                      type: AppIconType.add,
                      size: 26,
                      color: Colors.white,
                    ),
                  ),
                ).animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                ).scale(
                  duration: 2.seconds,
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                ),
              ),
            ),
          ),

          // Success Popup
          if (_showSuccessPopup)
            SuccessPopup(
              description: _successDescription,
              type: _successType,
              onClose: () => setState(() => _showSuccessPopup = false),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildPlansSlivers(HomeProvider provider) {
    final ongoing = provider.ongoingPlans;
    final completed = provider.completedPlans;

    return [
      // Ongoing
      if (ongoing.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList.builder(
            itemCount: ongoing.length,
            itemBuilder: (context, index) {
              final plan = ongoing[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PlanCard(
                  plan: plan,
                  isExpanded: _expandedCardId == plan.id,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _expandedCardId = _expandedCardId == plan.id ? null : plan.id;
                    });
                  },
                  onToggleStatus: () {
                    provider.togglePlanStatus(plan.id);
                    _triggerSuccess(plan.name, 'dream');
                  },
                  onDelete: () {
                    HapticFeedback.lightImpact();
                    provider.deletePlan(plan.id);
                  },
                  onPin: () {
                    HapticFeedback.selectionClick();
                    provider.pinPlan(plan.id);
                  },
                  onEdit: () => _showEditModal(plan),
                  onDetail: () => _showDetailSheet(plan),
                  onAddToReminders: () => _showAddPlanReminderSheet(plan),
                ),
              );
            },
          ),
        ),
      ],

      // Empty State
      if (ongoing.isEmpty)
        SliverToBoxAdapter(
          child: _buildEmptyState(AppIconType.plan, '开始你的第一个梦想', '点击下方按钮添加新计划'),
        ),

      // Completed
      if (completed.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Text(
                  '已完成',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${completed.length}',
                    style: AppTextStyles.badge,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList.builder(
            itemCount: completed.length,
            itemBuilder: (context, index) {
              final plan = completed[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PlanCard(
                  plan: plan,
                  isExpanded: _expandedCardId == plan.id,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _expandedCardId = _expandedCardId == plan.id ? null : plan.id;
                    });
                  },
                  onToggleStatus: () {
                    HapticFeedback.lightImpact();
                    provider.togglePlanStatus(plan.id);
                  },
                  onDelete: () {
                    HapticFeedback.lightImpact();
                    provider.deletePlan(plan.id);
                  },
                  onPin: () {
                    HapticFeedback.selectionClick();
                    provider.pinPlan(plan.id);
                  },
                  onEdit: () {},
                  onDetail: () {},
                ),
              );
            },
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildHabitsSlivers(HomeProvider provider) {
    final active = provider.activeHabits;
    final stopped = provider.stoppedHabits;

    return [
      // Active
      if (active.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList.builder(
            itemCount: active.length,
            itemBuilder: (context, index) {
              final habit = active[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: HabitCard(
                  habit: habit,
                  isExpanded: _expandedHabitId == habit.id && _expandedHabitSource == 'active',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (_expandedHabitId == habit.id && _expandedHabitSource == 'active') {
                        _expandedHabitId = null;
                        _expandedHabitSource = null;
                      } else {
                        _expandedHabitId = habit.id;
                        _expandedHabitSource = 'active';
                      }
                    });
                  },
                  onCheck: () {
                    provider.checkHabit(habit.id);
                    _triggerSuccess(habit.name, 'action');
                  },
                  onToggleStatus: () {
                    HapticFeedback.lightImpact();
                    provider.toggleHabitStatus(habit.id);
                  },
                  onDelete: () {
                    HapticFeedback.lightImpact();
                    provider.deleteHabit(habit.id);
                  },
                  onPin: () {
                    HapticFeedback.selectionClick();
                    provider.pinHabit(habit.id);
                  },
                  onEdit: () => _showEditHabitModal(habit),
                  onDetail: () => _showHabitDetailSheet(habit),
                ),
              );
            },
          ),
        ),
      ],

      // Empty State
      if (active.isEmpty)
        SliverToBoxAdapter(
          child: _buildEmptyState(AppIconType.habit, '开始你的第一个习惯', '点击下方按钮添加新习惯'),
        ),

      // Stopped
      if (stopped.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: Text(
              '已停用',
              style: AppTextStyles.titleMedium,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList.builder(
            itemCount: stopped.length,
            itemBuilder: (context, index) {
              final habit = stopped[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: HabitCard(
                  habit: habit,
                  isExpanded: _expandedHabitId == habit.id && _expandedHabitSource == 'stopped',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (_expandedHabitId == habit.id && _expandedHabitSource == 'stopped') {
                        _expandedHabitId = null;
                        _expandedHabitSource = null;
                      } else {
                        _expandedHabitId = habit.id;
                        _expandedHabitSource = 'stopped';
                      }
                    });
                  },
                  onCheck: () {}, // Disabled for stopped
                  onToggleStatus: () {
                    HapticFeedback.lightImpact();
                    provider.toggleHabitStatus(habit.id);
                  },
                  onDelete: () {
                    HapticFeedback.lightImpact();
                    provider.deleteHabit(habit.id);
                  },
                  onPin: () {
                    HapticFeedback.selectionClick();
                    provider.pinHabit(habit.id);
                  },
                  onEdit: () => _showEditHabitModal(habit),
                  onDetail: () => _showHabitDetailSheet(habit),
                ),
              );
            },
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildAnchorsSlivers(HomeProvider provider) {
    final anchors = provider.anchors;

    return [
      if (anchors.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList.builder(
            itemCount: anchors.length,
            itemBuilder: (context, index) {
              final anchor = anchors[index];
              return AnchorCard(
                anchor: anchor,
                onTap: () {
                  HapticFeedback.selectionClick();
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => AnchorDetailSheet(anchor: anchor),
                  );
                },
                onSyncAppleEco: () => _handleSyncAnchor(anchor),
                onEdit: () {
                  HapticFeedback.lightImpact();
                  showDialog(
                    context: context,
                    builder: (context) => AddAnchorModal(
                      initialName: anchor.name,
                      initialTime: anchor.time,
                      onAdd: (name, time) {
                        provider.updateAnchor(anchor.id, name, time);
                      },
                    ),
                  );
                },
                onDelete: () {
                  HapticFeedback.lightImpact();
                  provider.deleteAnchor(anchor.id);
                },
              );
            },
          ),
        ),
      ],

      if (anchors.isEmpty)
        SliverToBoxAdapter(
          child: _buildEmptyState(
            AppIconType.anchor, 
            '添加你的第一个锚点', 
            '锚点是生活中一定会发生的事情\n(例如: 起床后, 吃饭前)',
          ),
        ),
    ];
  }

  Widget _buildEmptyState(AppIconType iconType, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.only(top: 100),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AppIcon(
                type: iconType,
                size: 40,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: -5, duration: 6.seconds),
    );
  }
}

class _SwitchButton extends StatefulWidget {
  final String text;
  final AppIconType icon;
  final bool isActive;
  final VoidCallback onTap;

  const _SwitchButton({
    required this.text,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_SwitchButton> createState() => _SwitchButtonState();
}

class _SwitchButtonState extends State<_SwitchButton>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _rippleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _wobbleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    // 按压动画控制器
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    // 涟漪/水珠动画控制器
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeOutCubic,
      ),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: Curves.easeOutQuart,
      ),
    );

    _wobbleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.96), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.02), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.02, end: 0.98), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.98, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pressController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _pressController.forward();
    // 触发轻触觉反馈
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _pressController.reverse();
    _rippleController.forward(from: 0.0);
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pressController, _rippleController]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value * _wobbleAnimation.value,
            child: Stack(
              children: [
                // 液态水珠背景层
                if (widget.isActive)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: CustomPaint(
                        painter: _LiquidDropletPainter(
                          rippleProgress: _rippleAnimation.value,
                          isPressed: _isPressed,
                        ),
                      ),
                    ),
                  ),
                // 基础容器
                AnimatedContainer(
                  duration: 250.ms,
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: widget.isActive ? AppColors.primaryGradient : null,
                    color: widget.isActive ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: widget.isActive && _isPressed
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon(
                        type: widget.icon,
                        size: 18,
                        color: widget.isActive ? Colors.white : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.text,
                        style: TextStyle(
                          color: widget.isActive ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // 液态玻璃高光层 - 顶部高光
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _LiquidGlassHighlightPainter(
                          isPressed: _isPressed,
                          rippleProgress: _rippleAnimation.value,
                          isActive: widget.isActive,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 液态水珠背景绘制器 - 模拟水珠内部的流动效果
class _LiquidDropletPainter extends CustomPainter {
  final double rippleProgress;
  final bool isPressed;

  _LiquidDropletPainter({
    required this.rippleProgress,
    required this.isPressed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isPressed && rippleProgress == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    
    // 多个水珠气泡效果
    final bubbles = [
      _Bubble(Offset(size.width * 0.2, size.height * 0.3), size.height * 0.25),
      _Bubble(Offset(size.width * 0.7, size.height * 0.6), size.height * 0.2),
      _Bubble(Offset(size.width * 0.5, size.height * 0.8), size.height * 0.15),
    ];

    for (var bubble in bubbles) {
      final bubbleOffset = isPressed 
          ? Offset(
              bubble.center.dx + (center.dx - bubble.center.dx) * 0.1,
              bubble.center.dy + (size.height * 0.05),
            )
          : bubble.center;
      
      final bubbleRadius = bubble.radius * (1 + rippleProgress * 0.3);
      
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.2 * (1 - rippleProgress * 0.5)),
            Colors.white.withOpacity(0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(
          Rect.fromCircle(center: bubbleOffset, radius: bubbleRadius),
        );

      canvas.drawCircle(bubbleOffset, bubbleRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidDropletPainter oldDelegate) {
    return rippleProgress != oldDelegate.rippleProgress || 
           isPressed != oldDelegate.isPressed;
  }
}

class _Bubble {
  final Offset center;
  final double radius;
  _Bubble(this.center, this.radius);
}

/// 液态玻璃高光绘制器 - 顶部弧形高光和涟漪效果
class _LiquidGlassHighlightPainter extends CustomPainter {
  final bool isPressed;
  final double rippleProgress;
  final bool isActive;

  _LiquidGlassHighlightPainter({
    required this.isPressed,
    required this.rippleProgress,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 顶部弧形高光
    final highlightPath = Path()
      ..moveTo(0, size.height * 0.4)
      ..quadraticBezierTo(
        size.width * 0.5, 
        isPressed ? size.height * 0.15 : -size.height * 0.1,
        size.width, 
        size.height * 0.4,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(isActive ? 0.35 : 0.2),
          Colors.white.withOpacity(isActive ? 0.1 : 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.5));

    canvas.drawPath(highlightPath, highlightPaint);

    // 涟漪效果
    if (rippleProgress > 0 && rippleProgress < 1) {
      final rippleRadius = size.width * rippleProgress;
      final ripplePaint = Paint()
        ..color = Colors.white.withOpacity(0.3 * (1 - rippleProgress))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * (1 - rippleProgress);

      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        rippleRadius,
        ripplePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassHighlightPainter oldDelegate) {
    return isPressed != oldDelegate.isPressed ||
           rippleProgress != oldDelegate.rippleProgress ||
           isActive != oldDelegate.isActive;
  }
}


class _LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _LiquidGlassContainer({
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Stack(
            children: [
              // 1. Base Frosted Layer (iOS 磨砂奶油白底色)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.76),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              
              // 2. Dispersion / Subtle Teal-Amber Iridescence
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.45),
                        AppColors.primary.withOpacity(0.06),
                        AppColors.secondary.withOpacity(0.05),
                        Colors.white.withOpacity(0.35),
                      ],
                      stops: const [0.0, 0.4, 0.65, 1.0],
                    ),
                  ),
                ),
              ),

              // 3. Top-left Specular Highlight
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: RadialGradient(
                      center: const Alignment(-0.8, -0.85),
                      radius: 1.2,
                      colors: [
                        Colors.white.withOpacity(0.65),
                        Colors.white.withOpacity(0.0),
                      ],
                      stops: const [0.0, 0.6],
                    ),
                  ),
                ),
              ),

              // 4. Content & Crisp Specular Border
              Container(
                padding: padding,
                child: CustomPaint(
                  foregroundPainter: _GradientBorderPainter(
                    radius: 30,
                    strokeWidth: 1.2,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.95),
                        Colors.white.withOpacity(0.4),
                        AppColors.primary.withOpacity(0.15),
                        Colors.white.withOpacity(0.75),
                      ],
                      stops: const [0.0, 0.3, 0.75, 1.0],
                    ),
                  ),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double radius;
  final double strokeWidth;
  final Gradient gradient;

  _GradientBorderPainter({
    required this.radius,
    required this.strokeWidth,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter old) {
    return radius != old.radius || strokeWidth != old.strokeWidth;
  }
}
