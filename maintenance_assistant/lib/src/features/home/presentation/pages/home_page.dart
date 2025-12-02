import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/home_provider.dart';
import '../widgets/immersive_background.dart';
import '../widgets/plan_card.dart';
import '../widgets/habit_card.dart';
import '../widgets/add_modal.dart';
import '../widgets/detail_sheet.dart';
import '../widgets/setting_sheet.dart';
import '../widgets/success_popup.dart';
import '../widgets/app_drawer.dart';
import '../../../../shared/models/plan_model.dart';
import '../../../../shared/models/habit_model.dart';

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

  void _showAddModal() {
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
    setState(() {
      _showSuccessPopup = true;
      _successDescription = description;
      _successType = type;
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
          // Add tag as a new plan
          context.read<HomeProvider>().addPlan(tag);
          // SnackBar removed as requested
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
          // Add tag as a new habit
          context.read<HomeProvider>().addHabit(tag);
          // SnackBar removed as requested
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
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      // Menu Button
                      GestureDetector(
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.menu, color: Color(0xFF1D1D1F)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        '微行动',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                
                  // Content
                Expanded(
                  child: Consumer<HomeProvider>(
                    builder: (context, provider, child) {
                      return CustomScrollView(
                        slivers: [
                          if (_currentView == 'plans') ..._buildPlansSlivers(provider),
                          if (_currentView == 'habits') ..._buildHabitsSlivers(provider),
                          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
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
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _SwitchButton(
                    text: '计划',
                    isActive: _currentView == 'plans',
                    onTap: () => _switchView('plans'),
                  ),
                  _SwitchButton(
                    text: '习惯',
                    isActive: _currentView == 'habits',
                    onTap: () => _switchView('habits'),
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007AFF), Color(0xFF0056CC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF007AFF).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
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
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.builder(
            itemCount: ongoing.length,
            itemBuilder: (context, index) {
              final plan = ongoing[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
          child: _buildEmptyState('✨', '开始你的第一个梦想', '点击下方按钮添加新计划'),
        ),

      // Completed
      if (completed.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                const Text(
                  '已完成',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${completed.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.builder(
            itemCount: completed.length,
            itemBuilder: (context, index) {
              final plan = completed[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.builder(
            itemCount: active.length,
            itemBuilder: (context, index) {
              final habit = active[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
          child: _buildEmptyState('🎯', '开始你的第一个习惯', '点击下方按钮添加新习惯'),
        ),

      // Stopped
      if (stopped.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: const Text(
              '已停用',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.builder(
            itemCount: stopped.length,
            itemBuilder: (context, index) {
              final habit = stopped[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
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

  Widget _buildEmptyState(String icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.only(top: 100),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF86868B),
            ),
          ),
        ],
      ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: -5, duration: 3.seconds),
    );
  }
}

class _SwitchButton extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onTap;

  const _SwitchButton({
    required this.text,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 300.ms,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF007AFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF86868B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
