import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

class HelpSheet extends StatelessWidget {
  const HelpSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const AppIcon(
                    type: AppIconType.help,
                    size: 24,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '使用帮助',
                        style: AppTextStyles.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '基于福格行为模型设计',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const AppIcon(
                    type: AppIconType.close,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(color: AppColors.border),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 行为模型介绍
                  _buildSection(
                    emoji: '🧠',
                    title: '福格行为模型',
                    content: '行为 = 动机 + 能力 + 提示\n\n当动机(M)、能力(A)和提示(P)同时出现时，行为就会发生。这个简单而强大的公式是微行动的核心设计理念。',
                    color: AppColors.primary,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 三要素
                  _buildSection(
                    emoji: '🎯',
                    title: '三大核心要素',
                    color: AppColors.secondary,
                    child: Column(
                      children: [
                        _buildElementCard(
                          icon: '💪',
                          title: '动机 (Motivation)',
                          description: '你为什么要做这件事？明确的目标让你更有动力坚持下去。',
                          color: AppColors.success,
                        ),
                        const SizedBox(height: 12),
                        _buildElementCard(
                          icon: '🔧',
                          title: '能力 (Ability)',
                          description: '行为越简单，越容易执行。我们通过AI分解帮你把大任务拆成小步骤。',
                          color: AppColors.warning,
                        ),
                        const SizedBox(height: 12),
                        _buildElementCard(
                          icon: '⏰',
                          title: '提示 (Prompt)',
                          description: '锚点就是你的提示器。把新行为绑定到已有的习惯上，触发时机更清晰。',
                          color: AppColors.info,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 功能说明
                  _buildSection(
                    emoji: '📋',
                    title: '功能模块',
                    color: AppColors.habitAccent,
                    child: Column(
                      children: [
                        _buildFeatureCard(
                          icon: AppIconType.plan,
                          title: '计划',
                          description: '记录你的梦想和目标。支持AI分解，把看似遥远的目标拆解成可执行的小步骤。',
                          color: AppColors.planAccent,
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureCard(
                          icon: AppIconType.habit,
                          title: '习惯',
                          description: '追踪你的日常习惯。每次打卡都是一次小胜利，持续积累成就感。',
                          color: AppColors.habitAccent,
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureCard(
                          icon: AppIconType.anchor,
                          title: '锚点',
                          description: '设置时间锚点（如"起床后"、"午饭前"），将计划和习惯关联到固定时刻，提供行为提示。',
                          color: AppColors.anchorAccent,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 使用技巧
                  _buildSection(
                    emoji: '💡',
                    title: '使用技巧',
                    color: AppColors.warning,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTip('1️⃣', '从最小的行为开始，比如"看一页书"而不是"每天读30分钟"'),
                        const SizedBox(height: 8),
                        _buildTip('2️⃣', '把新习惯绑定到现有的锚点上，利用已有的行为触发新行为'),
                        const SizedBox(height: 8),
                        _buildTip('3️⃣', '每完成一个小目标就庆祝一下，正向反馈能增强动机'),
                        const SizedBox(height: 8),
                        _buildTip('4️⃣', '遇到困难时使用AI分解功能，把任务拆得更细更简单'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 底部口号
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppDecorations.shadowButton,
                      ),
                      child: const Text(
                        '✨ 微小的行动，巨大的改变 ✨',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String emoji,
    required String title,
    String? content,
    required Color color,
    Widget? child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (content != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.15)),
            ),
            child: Text(
              content,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),
          ),
        if (child != null) child,
      ],
    );
  }

  Widget _buildElementCard({
    required String icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required AppIconType icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: AppIcon(
              type: icon,
              size: 22,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(number, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
