import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/models/anchor_model.dart';
import '../../../../shared/models/plan_model.dart';
import '../../../../shared/models/habit_model.dart';
import '../providers/home_provider.dart';

class AnchorDetailSheet extends StatelessWidget {
  final Anchor anchor;

  const AnchorDetailSheet({super.key, required this.anchor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anchor.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      Text(
                        anchor.time,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF86868B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFFF3B30)),
                  onPressed: () {
                    context.read<HomeProvider>().deleteAnchor(anchor.id);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 32),

          // Content
          Expanded(
            child: Consumer<HomeProvider>(
              builder: (context, provider, child) {
                // Refresh anchor data from provider to get latest bindings
                final currentAnchor = provider.anchors.firstWhere(
                  (a) => a.id == anchor.id,
                  orElse: () => anchor,
                );
                
                // Get bound items
                final boundPlans = provider.plans
                    .where((p) => currentAnchor.planIds.contains(p.id))
                    .toList();
                final boundHabits = provider.habits
                    .where((h) => currentAnchor.habitIds.contains(h.id))
                    .toList();

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _buildSectionHeader(context, '关联计划', () {
                      _showAddPlanSheet(context, provider, currentAnchor);
                    }),
                    if (boundPlans.isEmpty)
                      _buildEmptyState('暂无关联计划')
                    else
                      ...boundPlans.map((plan) => _buildPlanItem(context, provider, currentAnchor, plan)),
                    
                    const SizedBox(height: 24),
                    
                    _buildSectionHeader(context, '关联习惯', () {
                      _showAddHabitSheet(context, provider, currentAnchor);
                    }),
                    if (boundHabits.isEmpty)
                      _buildEmptyState('暂无关联习惯')
                    else
                      ...boundHabits.map((habit) => _buildHabitItem(context, provider, currentAnchor, habit)),
                      
                    const SizedBox(height: 40),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 20),
          label: const Text('添加'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF007AFF),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF86868B),
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildPlanItem(BuildContext context, HomeProvider provider, Anchor anchor, Plan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              plan.name,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1D1D1F),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFFF3B30), size: 20),
            onPressed: () {
              provider.unbindPlanFromAnchor(anchor.id, plan.id);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHabitItem(BuildContext context, HomeProvider provider, Anchor anchor, Habit habit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              habit.name,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1D1D1F),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFFF3B30), size: 20),
            onPressed: () {
              provider.unbindHabitFromAnchor(anchor.id, habit.id);
            },
          ),
        ],
      ),
    );
  }

  void _showAddPlanSheet(BuildContext context, HomeProvider provider, Anchor anchor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '选择计划',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: provider.ongoingPlans.length,
                itemBuilder: (context, index) {
                  final plan = provider.ongoingPlans[index];
                  final isBound = anchor.planIds.contains(plan.id);
                  if (isBound) return const SizedBox.shrink();

                  return ListTile(
                    title: Text(plan.name),
                    trailing: const Icon(Icons.add_circle_outline, color: Color(0xFF007AFF)),
                    onTap: () {
                      provider.bindPlanToAnchor(anchor.id, plan.id);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddHabitSheet(BuildContext context, HomeProvider provider, Anchor anchor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '选择习惯',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: provider.activeHabits.length,
                itemBuilder: (context, index) {
                  final habit = provider.activeHabits[index];
                  final isBound = anchor.habitIds.contains(habit.id);
                  if (isBound) return const SizedBox.shrink();

                  return ListTile(
                    title: Text(habit.name),
                    trailing: const Icon(Icons.add_circle_outline, color: Color(0xFF007AFF)),
                    onTap: () {
                      provider.bindHabitToAnchor(anchor.id, habit.id);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
