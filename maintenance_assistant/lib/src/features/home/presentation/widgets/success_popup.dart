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

  // 橙红色系
  static const Color _primaryOrange = Color(0xFFFF6B35);
  static const Color _secondaryOrange = Color(0xFFFF9A56);
  static const Color _lightOrange = Color(0xFFFFF3EE);

  @override
  void initState() {
    super.initState();
    _rainbowFart = context.read<HomeProvider>().rainbowFart;
  }

  void _copyDescription() {
    Clipboard.setData(ClipboardData(text: _rainbowFart));
    HapticFeedback.lightImpact();
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
                margin: const EdgeInsets.only(top: 40),
                clipBehavior: Clip.none,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDecorations.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryOrange.withOpacity(0.15),
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
                      padding: const EdgeInsets.fromLTRB(24, 50, 24, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '太棒了！',
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: _primaryOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 26,
                            ),
                          ),
                          const SizedBox(height: 14),
                          
                          // Quote Box
                          GestureDetector(
                            onTap: _copyDescription,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _lightOrange,
                                borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                                border: Border.all(
                                  color: _secondaryOrange.withOpacity(0.3),
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
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.copy_rounded,
                                        size: 12,
                                        color: _secondaryOrange,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '点此复制',
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: _secondaryOrange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Stats
                          Row(
                            children: [
                              Expanded(
                                child: _StatItem(
                                  label: '成就徽章',
                                  value: widget.type == 'dream' ? '梦想家 🏅' : '行动派 ⚡',
                                  color: _primaryOrange,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatItem(
                                  label: '本次记录',
                                  value: widget.description.length > 4 
                                      ? '${widget.description.substring(0, 4)}...' 
                                      : widget.description,
                                  color: _secondaryOrange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Button
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_primaryOrange, _secondaryOrange],
                                ),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryOrange.withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  _copyDescription();
                                  widget.onClose();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('✌️', style: TextStyle(fontSize: 18)),
                                    const SizedBox(width: 8),
                                    Text(
                                      '收下这份喜悦',
                                      style: AppTextStyles.button.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // 顶部图标（带抖动动画）
                    Positioned(
                      top: -40,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [_primaryOrange, _secondaryOrange],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _primaryOrange.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('🎉', style: TextStyle(fontSize: 40)),
                          ),
                        )
                        // 抖动动画
                        .animate(
                          onPlay: (controller) => controller.repeat(),
                        )
                        .shake(
                          duration: 500.ms,
                          delay: 300.ms,
                          hz: 3,
                          rotation: 0.05,
                        )
                        .then(delay: 2000.ms), // 每隔一段时间抖动一次
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
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
