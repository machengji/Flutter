import 'package:flutter/material.dart';
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
import '../widgets/notification_sheet.dart';
import '../widgets/welcome_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _currentView = 'plans'; // 'plans' or 'habits'
  String? _expandedCardId;
  String? _expandedHabitId;
  String? _expandedHabitSource; // 'active' or 'completed'
  
  // Success Popup State
  bool _showSuccessPopup = false;
  String _successDescription = '';
  String _successType = 'action';

  void _switchView(String view) {
    setState(() {
      _currentView = view;
      _expandedCardId = null;
      _expandedHabitId = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkFirstTimeUse();
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DetailSheet(
        planName: plan.name,
        onTagSelected: (tag) {
          context.read<HomeProvider>().addPlan(tag);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          const ImmersiveBackground(),
          
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    children: [
                      // Menu Button
                      GestureDetector(
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.9),
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
                      const SizedBox(width: 16),
                      Text(
                        '微行动',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      
                      // Notification Button
                      Consumer<HomeProvider>(
                        builder: (context, provider, child) {
                          final unreadCount = provider.unreadNotificationCount;
                          return GestureDetector(
                            onTap: () {
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
                                    color: AppColors.surface.withOpacity(0.9),
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
                        slivers: [
                          if (_currentView == 'plans') ..._buildPlansSlivers(provider),
                          if (_currentView == 'habits') ..._buildHabitsSlivers(provider),
                          if (_currentView == 'anchors') ..._buildAnchorsSlivers(provider),
                          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
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
            bottom: 40,
            child: _LiquidGlassContainer(
              padding: const EdgeInsets.all(4),
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

          // FAB
          Positioned(
            right: 24,
            bottom: 40,
            child: GestureDetector(
              onTap: _showAddModal,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppDecorations.shadowButton,
                ),
                child: const Center(
                  child: AppIcon(
                    type: AppIconType.add,
                    size: 28,
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
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
                  onTap: () => setState(() {
                    _expandedCardId = _expandedCardId == plan.id ? null : plan.id;
                  }),
                  onToggleStatus: () {
                    provider.togglePlanStatus(plan.id);
                    _triggerSuccess(plan.name, 'dream');
                  },
                  onDelete: () => provider.deletePlan(plan.id),
                  onPin: () => provider.pinPlan(plan.id),
                  onEdit: () => _showEditModal(plan),
                  onDetail: () => _showDetailSheet(plan),
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
                  onTap: () => setState(() {
                    _expandedCardId = _expandedCardId == plan.id ? null : plan.id;
                  }),
                  onToggleStatus: () => provider.togglePlanStatus(plan.id),
                  onDelete: () => provider.deletePlan(plan.id),
                  onPin: () => provider.pinPlan(plan.id),
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
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
                  onTap: () => setState(() {
                    if (_expandedHabitId == habit.id && _expandedHabitSource == 'active') {
                      _expandedHabitId = null;
                      _expandedHabitSource = null;
                    } else {
                      _expandedHabitId = habit.id;
                      _expandedHabitSource = 'active';
                    }
                  }),
                  onCheck: () {
                    provider.checkHabit(habit.id);
                    _triggerSuccess(habit.name, 'action');
                  },
                  onToggleStatus: () => provider.toggleHabitStatus(habit.id),
                  onDelete: () => provider.deleteHabit(habit.id),
                  onPin: () => provider.pinHabit(habit.id),
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
                  onTap: () => setState(() {
                    if (_expandedHabitId == habit.id && _expandedHabitSource == 'stopped') {
                      _expandedHabitId = null;
                      _expandedHabitSource = null;
                    } else {
                      _expandedHabitId = habit.id;
                      _expandedHabitSource = 'stopped';
                    }
                  }),
                  onCheck: () {}, // Disabled for stopped
                  onToggleStatus: () => provider.toggleHabitStatus(habit.id),
                  onDelete: () => provider.deleteHabit(habit.id),
                  onPin: () => provider.pinHabit(habit.id),
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
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList.builder(
            itemCount: anchors.length,
            itemBuilder: (context, index) {
              final anchor = anchors[index];
              return AnchorCard(
                anchor: anchor,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => AnchorDetailSheet(anchor: anchor),
                  );
                },
                onEdit: () {
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
                onDelete: () => provider.deleteAnchor(anchor.id),
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
      ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: -5, duration: 3.seconds),
    );
  }
}

class _SwitchButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 300.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isActive ? AppColors.primaryGradient : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              type: icon,
              size: 18,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Stack(
          children: [
            // 1. Base Layer
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            
            // 2. Dispersion / Iridescence
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      AppColors.primary.withOpacity(0.05),
                      AppColors.secondary.withOpacity(0.05),
                      Colors.white.withOpacity(0.15),
                    ],
                    stops: const [0.0, 0.4, 0.6, 1.0],
                  ),
                ),
              ),
            ),

            // 3. Specular Highlight
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: RadialGradient(
                    center: const Alignment(-0.8, -0.8),
                    radius: 1.2,
                    colors: [
                      Colors.white.withOpacity(0.4),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5],
                  ),
                ),
              ),
            ),

            // 4. Content & Border
            Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CustomPaint(
                foregroundPainter: _GradientBorderPainter(
                  radius: 30,
                  strokeWidth: 1.2,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.6),
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.3),
                    ],
                    stops: const [0.0, 0.2, 0.8, 1.0],
                  ),
                ),
                child: child,
              ),
            ),
          ],
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
