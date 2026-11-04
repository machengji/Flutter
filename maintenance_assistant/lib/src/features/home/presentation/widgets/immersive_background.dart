import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

/// 苹果 VisionOS / iOS 18 风格的沉浸式自然生机流光背景
class ImmersiveBackground extends StatefulWidget {
  const ImmersiveBackground({super.key});

  @override
  State<ImmersiveBackground> createState() => _ImmersiveBackgroundState();
}

class _ImmersiveBackgroundState extends State<ImmersiveBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    // 12秒超缓流体呼吸周期，仅在 GPU 层驱动极微小偏移，完全不占用主线程资源
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFEDF8F2), // 晨露浅薄荷
                  Color(0xFFF3F8F9), // 冰海微蓝白
                  Color(0xFFF7FAF8), // 清透近白
                  Color(0xFFF2F7F4), // 底层柔润青白
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
            child: AnimatedBuilder(
              animation: _ambientController,
              builder: (context, child) {
                final t = _ambientController.value;
                // 计算平缓的有机飘动位移
                final offsetX1 = math.sin(t * math.pi) * 24;
                final offsetY1 = math.cos(t * math.pi) * 20;
                final offsetX2 = -math.cos(t * math.pi) * 22;
                final offsetY2 = math.sin(t * math.pi) * 18;

                return Stack(
                  children: [
                    // 流光光斑 1：顶部薄荷翠绿（生机动机）
                    Positioned(
                      top: -60 + offsetY1,
                      right: -40 + offsetX1,
                      child: Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.22),
                              AppColors.primary.withOpacity(0.08),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // 流光光斑 2：中左冰晶海水蓝（理智与平静，为卡片提供折射底色）
                    Positioned(
                      top: height * 0.35 + offsetY2,
                      left: -80 + offsetX2,
                      child: Container(
                        width: 360,
                        height: 360,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF3498DB).withOpacity(0.18),
                              const Color(0xFF1ABC9C).withOpacity(0.08),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // 流光光斑 3：右下晨曦暖翠光（习惯与提示）
                    Positioned(
                      bottom: -80 - offsetY1,
                      right: -60 - offsetX2,
                      child: Container(
                        width: 340,
                        height: 340,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.secondary.withOpacity(0.20),
                              const Color(0xFF2ECC71).withOpacity(0.06),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // 居中极弱高光，提升全局立体景深
                    Positioned(
                      top: height * 0.18,
                      left: width * 0.25,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.6),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
