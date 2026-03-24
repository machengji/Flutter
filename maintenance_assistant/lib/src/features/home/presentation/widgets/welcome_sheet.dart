import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/services/deepseek_service.dart';

class WelcomeSheet extends StatefulWidget {
  const WelcomeSheet({super.key});

  @override
  State<WelcomeSheet> createState() => _WelcomeSheetState();
}

class _WelcomeSheetState extends State<WelcomeSheet> {
  final PageController _pageController = PageController();
  final TextEditingController _apiKeyController = TextEditingController();

  int _currentPage = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl() async {
    final url = Uri.parse('https://platform.deepseek.com/api_keys');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _saveApiKey() async {
    if (_apiKeyController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    await DeepSeekService().setApiKey(_apiKeyController.text.trim());
    setState(() => _isLoading = false);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('设置完成，现在可以开始使用 AI 辅助了'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _skipApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_welcome', true);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已跳过，之后可以在设置里继续配置 API Key'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _buildWelcomePage(),
                _buildApiKeyPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: AppDecorations.shadowButton,
            ),
            child: const Center(
              child: AppIcon(
                type: AppIconType.habit,
                size: 46,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '欢迎使用 微行动',
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '基于福格行为模型，让改变更容易开始。',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.secondary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                const Text(
                  '福格行为模型',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '行为 = 动机 + 能力 + 提示',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'B = M × A × P',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildElementRow(
            const AppIcon(
                type: AppIconType.plan, size: 28, color: AppColors.primary),
            '动机',
            '明确的目标，会让你更想开始。',
          ),
          const SizedBox(height: 12),
          _buildElementRow(
            const AppIcon(
                type: AppIconType.analytics,
                size: 28,
                color: AppColors.secondary),
            '能力',
            'AI 帮你拆解任务，降低执行难度。',
          ),
          const SizedBox(height: 12),
          _buildElementRow(
            const AppIcon(
                type: AppIconType.anchor, size: 28, color: AppColors.warning),
            '提示',
            '把行动绑到具体情境里，更容易坚持。',
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('继续',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(width: 8),
                  AppIcon(
                      type: AppIconType.chevronRight,
                      size: 20,
                      color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildElementRow(Widget icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(width: 28, height: 28, child: Center(child: icon)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleSmall),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: AppIcon(
                type: AppIconType.apiKey,
                size: 40,
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '配置 AI 能力',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '设置 DeepSeek API Key，解锁 AI 拆解和分析功能。',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _apiKeyController,
            decoration: AppDecorations.inputDecoration(
              hintText: 'sk-...',
            ).copyWith(
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12),
                child: AppIcon(
                  type: AppIconType.apiKey,
                  size: 20,
                  color: AppColors.textHint,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _launchUrl,
              icon: const AppIcon(
                type: AppIconType.explore,
                size: 18,
                color: AppColors.secondary,
              ),
              label: const Text('前往 DeepSeek 官网获取 Key'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                side: const BorderSide(color: AppColors.secondary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppIcon(
                      type: AppIconType.help,
                      size: 18,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '如何获取',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '1. 点击上方按钮打开官网\n'
                  '2. 登录你的 DeepSeek 账号\n'
                  '3. 创建新的 API Key\n'
                  '4. 复制后粘贴到输入框中',
                  style: AppTextStyles.bodySmall.copyWith(
                    height: 1.8,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.success.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const AppIcon(
                  type: AppIconType.analytics,
                  size: 18,
                  color: AppColors.success,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '配置完成后，就可以体验 AI 拆解任务和生成建议。',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveApiKey,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      '保存并开始',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _skipApiKey,
            child: const Text(
              '暂时跳过，稍后再设置',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
