import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/theme.dart';
import 'app_drawer.dart';

/// Shader 预热组件
/// 
/// 在应用启动时以极低透明度渲染关键组件，
/// 强制 Flutter 预编译这些组件使用的 shader，
/// 避免首次显示时的卡顿
class ShaderWarmupWidget extends StatefulWidget {
  final VoidCallback onWarmupComplete;

  const ShaderWarmupWidget({super.key, required this.onWarmupComplete});

  @override
  State<ShaderWarmupWidget> createState() => _ShaderWarmupWidgetState();
}

class _ShaderWarmupWidgetState extends State<ShaderWarmupWidget> {
  @override
  void initState() {
    super.initState();
    // 延迟确保帧渲染完成，shader 编译完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          widget.onWarmupComplete();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // 以极低透明度渲染组件，强制 shader 编译
    // 使用 IgnorePointer 确保不会接收任何交互
    return Opacity(
      opacity: 0.001,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: Stack(
            children: [
              // 预热 AppDrawer（侧边栏）
              const Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 300,
                child: AppDrawer(),
              ),
              
              // 预热对话框样式（不使用 AddModal 避免键盘弹出）
              Positioned(
                left: 50,
                right: 50,
                top: 100,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDecorations.radiusLarge),
                    border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.1),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppDecorations.radiusSmall),
                            ),
                            child: const AppIcon(
                              type: AppIconType.plan,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('预热', style: AppTextStyles.titleLarge),
                        ],
                      ),
                      const SizedBox(height: 28),
                      // 输入框样式（不是真正的 TextField，避免键盘弹出）
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'Placeholder',
                          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textHint),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // 按钮行
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              alignment: Alignment.center,
                              child: Text(
                                '取消',
                                style: AppTextStyles.button.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                                boxShadow: AppDecorations.shadowButton,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              alignment: Alignment.center,
                              child: Text('添加', style: AppTextStyles.button),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().scale(
                  duration: 350.ms,
                  curve: Curves.easeOutCubic,
                ),
              ),
              
              // 预热 SuccessPopup（成功弹框）
              Positioned(
                left: 50,
                right: 50,
                bottom: 100,
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    padding: const EdgeInsets.all(28),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 渐变圆形图标
                        Container(
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
                        const SizedBox(height: 20),
                        Text(
                          'Warmup Text',
                          style: AppTextStyles.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        // 渐变容器
                        Container(
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
                          child: const Text('Warmup content'),
                        ),
                        const SizedBox(height: 16),
                        // 渐变按钮
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: AppDecorations.shadowButton,
                          ),
                          child: Text('Warmup Button', style: AppTextStyles.button),
                        ),
                      ],
                    ),
                  ).animate()
                    .fadeIn(duration: 250.ms)
                    .slideY(begin: 0.1, end: 0, duration: 250.ms),
                ),
              ),
              
              // 预热底部弹窗装饰
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 400,
                child: Container(
                  decoration: AppDecorations.bottomSheetDecoration,
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 48,
                        height: 5,
                        decoration: AppDecorations.dragHandleDecoration,
                      ),
                    ],
                  ),
                ),
              ),
              
              // 预热绿色完成按钮
              Positioned(
                right: 20,
                top: 50,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        '完成任务',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
