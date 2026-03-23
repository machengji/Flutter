import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

/// 沉浸式背景组件 - 自然绿色系渐变
class ImmersiveBackground extends StatelessWidget {
  const ImmersiveBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF0F9F4), // 极浅薄荷绿
                  Color(0xFFF5FAF7), // 淡绿白
                  Color(0xFFFAFCFB), // 近白
                  Color(0xFFF8F9FA), // 背景色
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // 装饰圆 - 右上角
                Positioned(
                  top: -80,
                  right: -60,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.08),
                          AppColors.primary.withOpacity(0.02),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // 装饰圆 - 左下角
                Positioned(
                  bottom: -100,
                  left: -80,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.secondary.withOpacity(0.06),
                          AppColors.secondary.withOpacity(0.02),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // 装饰圆 - 中间偏右 (使用固定值避免重建)
                Positioned(
                  top: constraints.maxHeight * 0.4,
                  right: -40,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.warning.withOpacity(0.05),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 1.0],
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
