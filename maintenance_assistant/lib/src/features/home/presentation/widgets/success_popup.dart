import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../providers/home_provider.dart';

class SuccessPopup extends StatefulWidget {
  final String description;
  final String type; // 'dream' or 'action'
  final VoidCallback onClose;

  const SuccessPopup({
    super.key,
    required this.description,
    this.type = 'action',
    required this.onClose,
  });

  @override
  State<SuccessPopup> createState() => _SuccessPopupState();
}

class _SuccessPopupState extends State<SuccessPopup> {
  late String _rainbowFart;

  @override
  void initState() {
    super.initState();
    // Get data from provider
    _rainbowFart = context.read<HomeProvider>().rainbowFart;
  }

  void _copyDescription() {
    Clipboard.setData(ClipboardData(text: _rainbowFart));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Backdrop
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          ),

          // Card
          Center(
            child: RepaintBoundary(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                constraints: const BoxConstraints(maxWidth: 400),
                margin: const EdgeInsets.only(top: 40), // 给顶部图标留空间
                clipBehavior: Clip.none,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDecorations.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 主体内容
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 50, 28, 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '太棒了！',
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Quote Box
                          GestureDetector(
                            onTap: _copyDescription,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withOpacity(0.06),
                                    AppColors.secondary.withOpacity(0.04),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.15),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _rainbowFart,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const AppIcon(
                                        type: AppIconType.edit,
                                        size: 12,
                                        color: AppColors.textHint,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '点此复制',
                                        style: AppTextStyles.labelSmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Stats
                          Row(
                            children: [
                              Expanded(
                                child: _StatItem(
                                  label: '成就徽章',
                                  value: widget.type == 'dream' ? '梦想家 🏅' : '行动派 ⚡',
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatItem(
                                  label: '本次记录',
                                  value: widget.description.length > 4 
                                      ? '${widget.description.substring(0, 4)}...' 
                                      : widget.description,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Button
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: AppDecorations.shadowButton,
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  _copyDescription();
                                  widget.onClose();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('✌️', style: TextStyle(fontSize: 18)),
                                    const SizedBox(width: 8),
                                    Text(
                                      '收下这份喜悦',
                                      style: AppTextStyles.button,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // 顶部图标（使用 Positioned 而不是 Transform）
                    Positioned(
                      top: -40,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: AppDecorations.shadowButton,
                          ),
                          child: const Center(
                            child: Text('🎉', style: TextStyle(fontSize: 40)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate()
              .fadeIn(duration: 250.ms, curve: Curves.easeOut)
              .slideY(begin: 0.1, end: 0, duration: 250.ms, curve: Curves.easeOut),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
