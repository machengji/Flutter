import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/models/celebration_model.dart';
import '../providers/home_provider.dart';
import 'celebration_overlay.dart';

class SuccessPopup extends StatefulWidget {
  final CelebrationPayload payload;
  final VoidCallback onClose;
  final VoidCallback? onChargedComplete;

  const SuccessPopup({
    super.key,
    required this.payload,
    required this.onClose,
    this.onChargedComplete,
  });

  @override
  State<SuccessPopup> createState() => _SuccessPopupState();
}

class _SuccessPopupState extends State<SuccessPopup> {
  static const Color _forestDeep = Color(0xFF163527);
  static const Color _forestMid = Color(0xFF23533D);
  static const Color _cream = Color(0xFFFAF6EC);
  static const Color _gold = Color(0xFFE9C46A);
  static const Color _inkDark = Color(0xFF1B3A2B);

  double _chargeVisual = 0.0;
  int _innerBurstId = 0;

  void _copyQuote() {
    Clipboard.setData(ClipboardData(text: widget.payload.quote));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制庆祝语'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _handleCharged() {
    final provider = context.read<HomeProvider>();
    provider.triggerCelebrationSensory(kind: 'grand', progress: 1.0);
    setState(() {
      _chargeVisual = 1.0;
      _innerBurstId++;
    });
    Future.delayed(const Duration(milliseconds: 380), () {
      if (!mounted) return;
      if (widget.onChargedComplete != null) {
        widget.onChargedComplete!();
      } else {
        widget.onClose();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;
    final width = math.min(media.width * 0.88, 390.0);
    final badgeText = widget.payload.milestoneTag ?? '发光时刻';

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(color: Colors.black.withOpacity(0.42)),
            ),
          ),
          Positioned.fill(
            child: StarburstParticleLayer(
              burstId: _innerBurstId,
              isGrand: true,
            ),
          ),
          Center(
            child: RepaintBoundary(
              child: Container(
                width: width,
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_forestDeep, _forestMid],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: _gold.withOpacity(0.35),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.28),
                      blurRadius: 36,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 顶部：里程碑微标 + 关闭钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _gold.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: _gold.withOpacity(0.34),
                              width: 0.9,
                            ),
                          ),
                          child: Text(
                            badgeText,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: _gold,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            widget.onClose();
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: AppIcon(
                                type: AppIconType.close,
                                size: 16,
                                color: _cream.withOpacity(0.85),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 中上：森系星芽流光徽章
                    AnimatedScale(
                      scale: 1.0 + (_chargeVisual * 0.14),
                      duration: const Duration(milliseconds: 140),
                      child: SizedBox(
                        width: 84,
                        height: 84,
                        child: CustomPaint(
                          painter: _GlowingStarEmblemPainter(
                            glowBoost: _chargeVisual,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 本次完成事项名称
                    Text(
                      widget.payload.actionTitle,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: _cream,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 温暖引语卡（轻点可复制）
                    GestureDetector(
                      onTap: _copyQuote,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: _cream,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Text(
                          widget.payload.quote,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: _inkDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 15.5,
                            height: 1.42,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 1 秒身体微庆祝动作提示胶囊
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _gold.withOpacity(0.24),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        widget.payload.microActionPrompt,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _gold,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 0.6 秒圆环蓄力发光按钮（轻点也可秒收）
                    SizedBox(
                      width: double.infinity,
                      child: ChargeToShineButton(
                        label: '按住 0.6 秒为自己鼓掌',
                        completedLabel: '为你闪耀',
                        allowQuickTapClose: true,
                        accentColor: _gold,
                        textColor: _forestDeep,
                        onChargeTick: (progress) {
                          setState(() => _chargeVisual = progress);
                          context.read<HomeProvider>().triggerCelebrationSensory(
                                kind: 'charge_tick',
                                progress: progress,
                              );
                        },
                        onCharged: _handleCharged,
                        onQuickTap: () {
                          if (widget.onChargedComplete != null) {
                            widget.onChargedComplete!();
                          } else {
                            widget.onClose();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 200.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.94, 0.94),
                  end: const Offset(1, 1),
                  duration: 240.ms,
                  curve: Curves.easeOutBack,
                ),
          ),
        ],
      ),
    );
  }
}

class _GlowingStarEmblemPainter extends CustomPainter {
  final double glowBoost;

  const _GlowingStarEmblemPainter({this.glowBoost = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width * 0.44;

    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE9C46A).withOpacity(0.36 + 0.25 * glowBoost),
          const Color(0xFF52B788).withOpacity(0.14),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.52));
    canvas.drawCircle(center, size.width * 0.50, haloPaint);

    final ringPaint = Paint()
      ..color = const Color(0xFFE9C46A).withOpacity(0.35 + 0.4 * glowBoost)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, outerRadius * 0.86, ringPaint);

    final starPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFE599), Color(0xFFE9C46A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius * 0.56));
    canvas.drawPath(
      buildFourPointStarPath(center, outerRadius * 0.58, outerRadius * 0.22),
      starPaint,
    );

    // 四周点缀 3 颗微光小星点
    final dotPaint = Paint()..color = const Color(0xFF95D5B2).withOpacity(0.85);
    canvas.drawCircle(
      Offset(center.dx - outerRadius * 0.62, center.dy - outerRadius * 0.42),
      2.6,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + outerRadius * 0.66, center.dy - outerRadius * 0.28),
      2.2,
      dotPaint..color = const Color(0xFFE9C46A).withOpacity(0.85),
    );
    canvas.drawCircle(
      Offset(center.dx + outerRadius * 0.45, center.dy + outerRadius * 0.58),
      2.4,
      dotPaint..color = const Color(0xFF95D5B2).withOpacity(0.75),
    );
  }

  @override
  bool shouldRepaint(covariant _GlowingStarEmblemPainter oldDelegate) {
    return oldDelegate.glowBoost != glowBoost;
  }
}
