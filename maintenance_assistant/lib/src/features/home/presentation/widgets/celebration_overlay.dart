import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/models/celebration_model.dart';

/// 绘制四角微光星芒的通用路径辅助方法
Path buildFourPointStarPath(Offset center, double outerRadius, double innerRadius) {
  final path = Path();
  for (int i = 0; i < 8; i++) {
    final radius = i.isEven ? outerRadius : innerRadius;
    final angle = (i * math.pi / 4) - math.pi / 2;
    final pt = Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );
    if (i == 0) {
      path.moveTo(pt.dx, pt.dy);
    } else {
      path.lineTo(pt.dx, pt.dy);
    }
  }
  path.close();
  return path;
}

/// 0.6 秒圆环蓄力发光按钮（供高光庆祝卡与发光星籽罐抽屉共用）
class ChargeToShineButton extends StatefulWidget {
  final String label;
  final String completedLabel;
  final bool allowQuickTapClose;
  final ValueChanged<double>? onChargeTick;
  final VoidCallback onCharged;
  final VoidCallback? onQuickTap;
  final Color accentColor;
  final Color textColor;

  const ChargeToShineButton({
    super.key,
    required this.label,
    this.completedLabel = '已为自己喝彩',
    this.allowQuickTapClose = false,
    this.onChargeTick,
    required this.onCharged,
    this.onQuickTap,
    this.accentColor = const Color(0xFFE9C46A),
    this.textColor = const Color(0xFF173829),
  });

  @override
  State<ChargeToShineButton> createState() => _ChargeToShineButtonState();
}

class _ChargeToShineButtonState extends State<ChargeToShineButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _lastTickStage = 0;
  int _tapDownEpochMs = 0;
  bool _completedOnce = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )
      ..addListener(_handleProgress)
      ..addStatusListener(_handleStatus);
  }

  void _handleProgress() {
    final v = _controller.value;
    int stage = 0;
    if (v >= 0.85) {
      stage = 4;
    } else if (v >= 0.62) {
      stage = 3;
    } else if (v >= 0.38) {
      stage = 2;
    } else if (v >= 0.15) {
      stage = 1;
    }
    if (stage > _lastTickStage && _controller.status == AnimationStatus.forward) {
      _lastTickStage = stage;
      widget.onChargeTick?.call(v);
    }
    if (mounted) setState(() {});
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_completedOnce) {
      _completedOnce = true;
      widget.onCharged();
      // 若用于发光罐抽屉可重复练习，短暂高光后自动复位以便继续练习
      if (!widget.allowQuickTapClose) {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) {
            setState(() {
              _completedOnce = false;
              _lastTickStage = 0;
            });
            _controller.value = 0.0;
          }
        });
      }
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (_completedOnce) return;
    _tapDownEpochMs = DateTime.now().millisecondsSinceEpoch;
    _lastTickStage = 0;
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (_completedOnce) return;
    final heldMs = DateTime.now().millisecondsSinceEpoch - _tapDownEpochMs;
    if (widget.allowQuickTapClose && heldMs < 220 && _controller.value < 0.38) {
      _controller.stop();
      _controller.value = 0.0;
      widget.onQuickTap?.call();
      return;
    }
    if (_controller.status != AnimationStatus.completed) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (_completedOnce) return;
    if (_controller.status != AnimationStatus.completed) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleProgress);
    _controller.removeStatusListener(_handleStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _controller.value;
    final scale = 1.0 + (progress * 0.035);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: Transform.scale(
        scale: scale,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(27),
            color: widget.accentColor.withOpacity(0.18),
            border: Border.all(
              color: widget.accentColor.withOpacity(0.55),
              width: 1.4,
            ),
            boxShadow: progress > 0.05
                ? [
                    BoxShadow(
                      color: widget.accentColor.withOpacity(0.28 * progress),
                      blurRadius: 18 * progress,
                      spreadRadius: 2 * progress,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 蓄力充能进度层
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: _completedOnce ? 1.0 : progress.clamp(0.0, 1.0),
                    heightFactor: 1.0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.accentColor,
                            Color.lerp(widget.accentColor, Colors.white, 0.28)!,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // 默认柔和底衬（未按压时也清晰可辨）
                if (!_completedOnce && progress == 0)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: widget.accentColor.withOpacity(0.88),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CustomPaint(
                          painter: _MiniStarRingPainter(
                            progress: _completedOnce ? 1.0 : progress,
                            color: widget.textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          _completedOnce ? widget.completedLabel : widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: (!_completedOnce && progress > 0 && progress < 0.45)
                                ? Colors.white
                                : widget.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStarRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _MiniStarRingPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ringPaint = Paint()
      ..color = color.withOpacity(0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(center, size.width * 0.44, ringPaint);

    if (progress > 0) {
      final arcPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: size.width * 0.44),
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        arcPaint,
      );
    }

    final starPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(
      buildFourPointStarPath(center, size.width * 0.28, size.width * 0.11),
      starPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniStarRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// 屏内无阻断星光粒子绽放层（IgnorePointer 不拦截任何触控）
class StarburstParticleLayer extends StatefulWidget {
  final int burstId;
  final bool isGrand;

  const StarburstParticleLayer({
    super.key,
    required this.burstId,
    this.isGrand = false,
  });

  @override
  State<StarburstParticleLayer> createState() => _StarburstParticleLayerState();
}

class _StarburstParticleLayerState extends State<StarburstParticleLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<_StarParticle> _particles = const [];

  static const List<Color> _palette = [
    Color(0xFFE9C46A),
    Color(0xFFF4A261),
    Color(0xFF52B788),
    Color(0xFF95D5B2),
    Color(0xFFFFF8E7),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    );
    if (widget.burstId > 0) {
      _spawnAndPlay();
    }
  }

  @override
  void didUpdateWidget(covariant StarburstParticleLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.burstId != oldWidget.burstId && widget.burstId > 0) {
      _spawnAndPlay();
    }
  }

  void _spawnAndPlay() {
    final rnd = math.Random(widget.burstId * 9973);
    final count = widget.isGrand ? 42 : 22;
    _particles = List.generate(count, (i) {
      final angle = (i / count) * math.pi * 2 + (rnd.nextDouble() - 0.5) * 0.35;
      final speed = (widget.isGrand ? 130.0 : 85.0) + rnd.nextDouble() * 145.0;
      return _StarParticle(
        angle: angle,
        distance: speed,
        size: (widget.isGrand ? 5.5 : 4.2) + rnd.nextDouble() * 4.8,
        color: _palette[i % _palette.length],
        isStar: i % 3 != 0,
        rotationSpeed: (rnd.nextDouble() - 0.5) * 4.0,
      );
    });
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (!_controller.isAnimating && _controller.value == 0.0 ||
              _controller.value >= 1.0) {
            return const SizedBox.shrink();
          }
          return CustomPaint(
            size: Size.infinite,
            painter: _StarburstPainter(
              progress: _controller.value,
              particles: _particles,
              isGrand: widget.isGrand,
            ),
          );
        },
      ),
    );
  }
}

class _StarParticle {
  final double angle;
  final double distance;
  final double size;
  final Color color;
  final bool isStar;
  final double rotationSpeed;

  const _StarParticle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
    required this.isStar,
    required this.rotationSpeed,
  });
}

class _StarburstPainter extends CustomPainter {
  final double progress;
  final List<_StarParticle> particles;
  final bool isGrand;

  const _StarburstPainter({
    required this.progress,
    required this.particles,
    required this.isGrand,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(
      size.width * 0.5,
      size.height * (isGrand ? 0.44 : 0.28),
    );
    final eased = Curves.easeOutCubic.transform(progress);
    final opacity = (1.0 - Curves.easeInQuad.transform(progress)).clamp(0.0, 1.0);

    for (final p in particles) {
      final dx = origin.dx + math.cos(p.angle) * p.distance * eased;
      final dy = origin.dy +
          math.sin(p.angle) * p.distance * eased +
          (42.0 * progress * progress);
      final pos = Offset(dx, dy);
      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      final currentSize = p.size * (1.0 - progress * 0.35);
      if (p.isStar) {
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(p.rotationSpeed * progress);
        canvas.drawPath(
          buildFourPointStarPath(Offset.zero, currentSize, currentSize * 0.38),
          paint,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(pos, currentSize * 0.55, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StarburstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// 日常微行动 2.5 秒无阻断灵动庆祝胶囊（不点自动化作星籽入罐，点按立即展开深度高光庆祝）
class MicroCelebrationCapsule extends StatefulWidget {
  final CelebrationPayload payload;
  final VoidCallback onAutoCollect;
  final VoidCallback onTapExpandGrand;

  const MicroCelebrationCapsule({
    super.key,
    required this.payload,
    required this.onAutoCollect,
    required this.onTapExpandGrand,
  });

  @override
  State<MicroCelebrationCapsule> createState() =>
      _MicroCelebrationCapsuleState();
}

class _MicroCelebrationCapsuleState extends State<MicroCelebrationCapsule>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          widget.onAutoCollect();
        }
      });
    _timerController.forward();
  }

  @override
  void didUpdateWidget(covariant MicroCelebrationCapsule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.payload.eventId != widget.payload.eventId) {
      _timerController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 66, 20, 0),
        child: GestureDetector(
          onTap: () {
            _timerController.stop();
            widget.onTapExpandGrand();
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE9C46A).withOpacity(0.45),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B4332).withOpacity(0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9C46A).withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CustomPaint(
                      size: const Size.square(18),
                      painter: const _SingleGoldStarPainter(),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.payload.quote,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: const Color(0xFFFAF6EC),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.payload.microActionPrompt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: const Color(0xFFE9C46A).withOpacity(0.92),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedBuilder(
                  animation: _timerController,
                  builder: (context, _) {
                    return SizedBox(
                      width: 30,
                      height: 30,
                      child: CustomPaint(
                        painter: _MiniStarRingPainter(
                          progress: 1.0 - _timerController.value,
                          color: const Color(0xFFE9C46A),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SingleGoldStarPainter extends CustomPainter {
  const _SingleGoldStarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFFE9C46A)
      ..style = PaintingStyle.fill;
    canvas.drawPath(
      buildFourPointStarPath(center, size.width * 0.48, size.width * 0.18),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 星籽沿弧线飞入顶部「发光星籽罐」胶囊的飞行动画层
class FlyingStarSeedOverlay extends StatefulWidget {
  final int flightId;
  final Offset startOffset;
  final Offset targetOffset;
  final VoidCallback onLanded;

  const FlyingStarSeedOverlay({
    super.key,
    required this.flightId,
    required this.startOffset,
    required this.targetOffset,
    required this.onLanded,
  });

  @override
  State<FlyingStarSeedOverlay> createState() => _FlyingStarSeedOverlayState();
}

class _FlyingStarSeedOverlayState extends State<FlyingStarSeedOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          widget.onLanded();
        }
      });
    if (widget.flightId > 0) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant FlyingStarSeedOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flightId != oldWidget.flightId && widget.flightId > 0) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (!_controller.isAnimating) {
            return const SizedBox.shrink();
          }
          final t = Curves.easeInOutCubic.transform(_controller.value);
          final p0 = widget.startOffset;
          final p2 = widget.targetOffset;
          final control = Offset(
            (p0.dx + p2.dx) * 0.5 - 36,
            math.min(p0.dy, p2.dy) - 64,
          );
          final oneMinusT = 1.0 - t;
          final current = Offset(
            oneMinusT * oneMinusT * p0.dx +
                2 * oneMinusT * t * control.dx +
                t * t * p2.dx,
            oneMinusT * oneMinusT * p0.dy +
                2 * oneMinusT * t * control.dy +
                t * t * p2.dy,
          );
          final scale = 1.15 - 0.45 * t;

          return CustomPaint(
            size: Size.infinite,
            painter: _FlyingSeedPainter(
              position: current,
              scale: scale,
            ),
          );
        },
      ),
    );
  }
}

class _FlyingSeedPainter extends CustomPainter {
  final Offset position;
  final double scale;

  const _FlyingSeedPainter({
    required this.position,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = const Color(0xFFE9C46A).withOpacity(0.38)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(position, 13 * scale, glowPaint);

    final starPaint = Paint()
      ..color = const Color(0xFFFFD166)
      ..style = PaintingStyle.fill;
    canvas.drawPath(
      buildFourPointStarPath(position, 10 * scale, 4 * scale),
      starPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FlyingSeedPainter oldDelegate) {
    return oldDelegate.position != position || oldDelegate.scale != scale;
  }
}
