import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
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
      decoration: AppDecorations.bottomSheetDecoration,
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 48,
              height: 5,
              decoration: AppDecorations.dragHandleDecoration,
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.anchorAccent.withOpacity(0.12),
                        AppColors.anchorAccent.withOpacity(0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                    border: Border.all(color: AppColors.anchorAccent.withOpacity(0.2)),
                  ),
                  child: Text(
                    anchor.time,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.anchorAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anchor.name,
                        style: AppTextStyles.titleLarge,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    context.read<HomeProvider>().deleteAnchor(anchor.id);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppDecorations.radiusSmall),
                    ),
                    child: const AppIcon(
                      type: AppIconType.delete,
                      size: 20,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: AppColors.border.withOpacity(0.5), height: 1),

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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  children: [
                    _buildSectionHeader(context, '关联计划', AppColors.primary, () {
                      _showAddPlanSheet(context, provider, currentAnchor);
                    }),
                    const SizedBox(height: 12),
                    if (boundPlans.isEmpty)
                      _buildEmptyState('暂无关联计划')
                    else
                      ...boundPlans.map((plan) => _buildPlanItem(context, provider, currentAnchor, plan)),
                    
                    const SizedBox(height: 28),
                    
                    _buildSectionHeader(context, '关联习惯', AppColors.habitAccent, () {
                      _showAddHabitSheet(context, provider, currentAnchor);
                    }),
                    const SizedBox(height: 12),
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

  Widget _buildSectionHeader(BuildContext context, String title, Color color, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: AppTextStyles.titleMedium,
            ),
          ],
        ),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(type: AppIconType.add, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  '添加',
                  style: AppTextStyles.labelLarge.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          const AppIcon(
            type: AppIconType.anchor,
            size: 32,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanItem(BuildContext context, HomeProvider provider, Anchor anchor, Plan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const AppIcon(
              type: AppIconType.plan,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              plan.name,
              style: AppTextStyles.bodyLarge,
            ),
          ),
          GestureDetector(
            onTap: () => provider.unbindPlanFromAnchor(anchor.id, plan.id),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const AppIcon(
                type: AppIconType.close,
                size: 16,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitItem(BuildContext context, HomeProvider provider, Anchor anchor, Habit habit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.habitAccent.withOpacity(0.04),
        borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
        border: Border.all(color: AppColors.habitAccent.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.habitAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const AppIcon(
              type: AppIconType.habit,
              size: 18,
              color: AppColors.habitAccent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              habit.name,
              style: AppTextStyles.bodyLarge,
            ),
          ),
          GestureDetector(
            onTap: () => provider.unbindHabitFromAnchor(anchor.id, habit.id),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const AppIcon(
                type: AppIconType.close,
                size: 16,
                color: AppColors.error,
              ),
            ),
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
        decoration: AppDecorations.bottomSheetDecoration,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const AppIcon(
                      type: AppIconType.plan,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('选择计划', style: AppTextStyles.titleMedium),
                ],
              ),
            ),
            Divider(color: AppColors.border.withOpacity(0.5), height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.ongoingPlans.length,
                itemBuilder: (context, index) {
                  final plan = provider.ongoingPlans[index];
                  final isBound = anchor.planIds.contains(plan.id);
                  if (isBound) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                      border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(plan.name, style: AppTextStyles.bodyLarge),
                      trailing: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const AppIcon(
                          type: AppIconType.add,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      onTap: () {
                        provider.bindPlanToAnchor(anchor.id, plan.id);
                        Navigator.pop(context);
                      },
                    ),
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
        decoration: AppDecorations.bottomSheetDecoration,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.habitAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const AppIcon(
                      type: AppIconType.habit,
                      size: 20,
                      color: AppColors.habitAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('选择习惯', style: AppTextStyles.titleMedium),
                ],
              ),
            ),
            Divider(color: AppColors.border.withOpacity(0.5), height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.activeHabits.length,
                itemBuilder: (context, index) {
                  final habit = provider.activeHabits[index];
                  final isBound = anchor.habitIds.contains(habit.id);
                  if (isBound) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.habitAccent.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                      border: Border.all(color: AppColors.habitAccent.withOpacity(0.1)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(habit.name, style: AppTextStyles.bodyLarge),
                      trailing: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.habitAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const AppIcon(
                          type: AppIconType.add,
                          size: 18,
                          color: AppColors.habitAccent,
                        ),
                      ),
                      onTap: () {
                        provider.bindHabitToAnchor(anchor.id, habit.id);
                        Navigator.pop(context);
                      },
                    ),
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
