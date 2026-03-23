import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/theme.dart';
import 'add_anchor_modal.dart';
import 'add_modal.dart';
import 'app_drawer.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) {
          widget.onWarmupComplete();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.001,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: Stack(
            children: [
              const Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 300,
                child: AppDrawer(),
              ),
              Positioned(
                left: 40,
                right: 40,
                top: 80,
                child: AddModal(
                  title: '新计划',
                  placeholder: '输入你的梦想...',
                  onConfirm: (_) {},
                  autofocusEnabled: false,
                  enableEntranceAnimation: false,
                ),
              ),
              Positioned(
                left: 40,
                right: 40,
                top: 360,
                child: AddAnchorModal(
                  onAdd: (_, __) {},
                  autofocusEnabled: false,
                  enableEntranceAnimation: false,
                ),
              ),
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
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: AppDecorations.shadowButton,
                          ),
                          child: const Center(
                            child: Text('OK', style: TextStyle(fontSize: 26, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Warmup Text',
                          style: AppTextStyles.headlineSmall,
                        ),
                        const SizedBox(height: 16),
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
                  )
                      .animate()
                      .fadeIn(duration: 250.ms)
                      .slideY(begin: 0.1, end: 0, duration: 250.ms),
                ),
              ),
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
            ],
          ),
        ),
      ),
    );
  }
}
