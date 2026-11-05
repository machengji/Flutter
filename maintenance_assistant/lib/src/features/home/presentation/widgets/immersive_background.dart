import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

/// 沉浸式背景组件 - 森系晨雾与自然光影 (Botanical Mist Background)
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
                  Color(0xFFE8F3EC), // 晨露苔藓浅绿
                  Color(0xFFF1F7F3), // 森林薄雾白绿
                  Color(0xFFF6FAF7), // 温润宣纸绿白
                  Color(0xFFF4F8F5), // 自然基底色
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // 顶部晨光树影弥散圆 - 右上角
                Positioned(
                  top: -70,
                  right: -50,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.09),
                          AppColors.primaryLight.withOpacity(0.03),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
                // 溪流青碧弥散圆 - 左下角
                Positioned(
                  bottom: -90,
                  left: -70,
                  child: Container(
                    width: 290,
                    height: 290,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.secondary.withOpacity(0.08),
                          AppColors.secondary.withOpacity(0.02),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
                // 暖阳松果微光 - 中间偏右
                Positioned(
                  top: constraints.maxHeight * 0.38,
                  right: -35,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.warning.withOpacity(0.06),
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
