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
  static const String _referenceAssetPath =
      'assets/images/success_popup_reference.png';

  // 对齐插画原图底色 #006768，消除拼接色差
  static const Color _bg = Color(0xFF006768);
  static const Color _peach = Color(0xFFF5B9AB);
  static const Color _accent = Color(0xFFFF4735);
  static const Color _dark = Color(0xFF620033);
  static const Color _cream = Color(0xFFF4EFD8);
  static const Color _gold = Color(0xFFFFE08A);

  int _innerBurstId = 0;

  void _copyQuoteOnly() {
    Clipboard.setData(ClipboardData(text: widget.payload.quote));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('庆祝文案已复制到剪贴板'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _completeWithCopy({required bool withChargeDelay}) {
    Clipboard.setData(ClipboardData(text: widget.payload.quote));
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('已复制文案并收进星光罐'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 1),
      ),
    );

    if (!withChargeDelay) {
      HapticFeedback.lightImpact();
      if (widget.onChargedComplete != null) {
        widget.onChargedComplete!();
      } else {
        widget.onClose();
      }
      return;
    }

    context
        .read<HomeProvider>()
        .triggerCelebrationSensory(kind: 'grand', progress: 1.0);
    setState(() => _innerBurstId++);
    Future.delayed(const Duration(milliseconds: 360), () {
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
    final width = math.min(media.width * 0.9, 420.0);
    final height = math.min(media.height * 0.78, 680.0);
    final badgeText = widget.payload.milestoneTag ?? '行动庆祝';

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(color: Colors.black.withOpacity(0.40)),
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
              child: SizedBox(
                width: width,
                height: height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(38),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.28),
                        blurRadius: 40,
                        offset: const Offset(0, 22),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(38),
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final artHeight = (c.maxHeight * 0.62).ceilToDouble();
                        final contentTop = (c.maxHeight * 0.44).floorToDouble();
                        return Stack(
                          children: [
                            const Positioned.fill(child: ColoredBox(color: _bg)),
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: artHeight,
                              child: const _PosterArt(
                                assetPath: _referenceAssetPath,
                                bgColor: _bg,
                                painter: _ReferencePainter(
                                  peach: _peach,
                                  accent: _accent,
                                  dark: _dark,
                                  cream: _cream,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 18,
                              right: 18,
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  widget.onClose();
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _cream.withOpacity(0.95),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: _dark,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 22,
                              right: 22,
                              top: contentTop,
                              bottom: 20,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 1. 轻量微标 + 本次完成事项名
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _cream.withOpacity(0.16),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                          color: _cream.withOpacity(0.24),
                                        ),
                                      ),
                                      child: Text(
                                        badgeText,
                                        style: AppTextStyles.labelMedium.copyWith(
                                          color: _gold,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      widget.payload.actionTitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.headlineSmall.copyWith(
                                        color: _cream,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 14),

                                    // 2. 奶油色庆祝语大卡片（轻点也可单复制）
                                    GestureDetector(
                                      onTap: _copyQuoteOnly,
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 18,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _cream.withOpacity(0.97),
                                          borderRadius: BorderRadius.circular(26),
                                        ),
                                        child: Text(
                                          widget.payload.quote,
                                          textAlign: TextAlign.center,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.bodyLarge.copyWith(
                                            color: _dark,
                                            fontWeight: FontWeight.w700,
                                            height: 1.42,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),

                                    // 3. 底部蓄力成功按钮（蓄满或轻点自动复制文案并收进星光罐）
                                    SizedBox(
                                      width: double.infinity,
                                      child: ChargeToShineButton(
                                        label: '按住 0.6 秒为自己鼓掌',
                                        completedLabel: '已复制并收进星光罐',
                                        allowQuickTapClose: true,
                                        accentColor: _accent,
                                        textColor: _cream,
                                        onChargeTick: (progress) {
                                          context
                                              .read<HomeProvider>()
                                              .triggerCelebrationSensory(
                                                kind: 'charge_tick',
                                                progress: progress,
                                              );
                                        },
                                        onCharged: () =>
                                            _completeWithCopy(withChargeDelay: true),
                                        onQuickTap: () =>
                                            _completeWithCopy(withChargeDelay: false),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 220.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.95, 0.95),
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

class _PosterArt extends StatelessWidget {
  final String assetPath;
  final Color bgColor;
  final CustomPainter painter;

  const _PosterArt({
    required this.assetPath,
    required this.bgColor,
    required this.painter,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: bgColor),
        Positioned.fill(
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) {
              return CustomPaint(painter: painter);
            },
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 120,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    bgColor.withOpacity(0.0),
                    bgColor.withOpacity(0.22),
                    bgColor.withOpacity(0.68),
                    bgColor.withOpacity(0.94),
                    bgColor,
                  ],
                  stops: const [0.0, 0.30, 0.65, 0.88, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReferencePainter extends CustomPainter {
  final Color peach;
  final Color accent;
  final Color dark;
  final Color cream;

  const _ReferencePainter({
    required this.peach,
    required this.accent,
    required this.dark,
    required this.cream,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final peachFill = Paint()..color = peach;
    final darkFill = Paint()..color = dark;
    final accentFill = Paint()..color = accent;
    final bgFill = Paint()..color = const Color(0xFF006768);
    final creamLine = Paint()
      ..color = cream
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.shortestSide * 0.011;
    final accentLine = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.shortestSide * 0.010;
    final orbit = Paint()
      ..color = cream
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.shortestSide * 0.016;

    final backOrbit = Path()
      ..moveTo(size.width * 0.14, size.height * 0.50)
      ..quadraticBezierTo(size.width * 0.44, size.height * 0.18,
          size.width * 0.84, size.height * 0.30);
    canvas.drawPath(backOrbit, orbit);

    _capsule(canvas, Offset(size.width * 0.25, size.height * 0.32),
        Size(size.width * 0.26, size.height * 0.38), -0.45, peachFill);
    canvas.drawCircle(Offset(size.width * 0.21, size.height * 0.18),
        size.width * 0.12, peachFill);
    canvas.drawCircle(Offset(size.width * 0.19, size.height * 0.18),
        size.width * 0.09, peachFill);

    final armJoint = Path()
      ..moveTo(size.width * 0.31, size.height * 0.47)
      ..lineTo(size.width * 0.38, size.height * 0.40)
      ..lineTo(size.width * 0.46, size.height * 0.50)
      ..lineTo(size.width * 0.37, size.height * 0.56)
      ..close();
    canvas.drawPath(armJoint, accentFill);

    _capsule(canvas, Offset(size.width * 0.65, size.height * 0.55),
        Size(size.width * 0.22, size.height * 0.20), 0.72, peachFill);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.56),
        size.width * 0.14, peachFill);

    final leg = Path()
      ..moveTo(size.width * 0.56, size.height * 0.72)
      ..quadraticBezierTo(size.width * 0.72, size.height * 0.68,
          size.width * 0.90, size.height * 0.73)
      ..quadraticBezierTo(size.width * 0.94, size.height * 0.86,
          size.width * 0.84, size.height * 0.92)
      ..quadraticBezierTo(size.width * 0.72, size.height * 0.95,
          size.width * 0.64, size.height * 0.86)
      ..close();
    canvas.drawPath(leg, accentFill);
    _shoe(canvas, Offset(size.width * 0.76, size.height * 0.86),
        Size(size.width * 0.28, size.height * 0.12), -0.30, accent);

    final torso = Path()
      ..moveTo(size.width * 0.41, size.height * 0.53)
      ..lineTo(size.width * 0.56, size.height * 0.54)
      ..lineTo(size.width * 0.61, size.height * 0.69)
      ..lineTo(size.width * 0.46, size.height * 0.73)
      ..close();
    canvas.drawPath(torso, peachFill);

    final waist = Path()
      ..moveTo(size.width * 0.44, size.height * 0.63)
      ..lineTo(size.width * 0.58, size.height * 0.63)
      ..lineTo(size.width * 0.60, size.height * 0.70)
      ..lineTo(size.width * 0.45, size.height * 0.70)
      ..close();
    canvas.drawPath(waist, bgFill);
    for (int i = 0; i < 4; i++) {
      final x = size.width * (0.47 + i * 0.032);
      canvas.drawLine(Offset(x, size.height * 0.635),
          Offset(x + 2, size.height * 0.695), creamLine);
    }

    final shorts = Path()
      ..moveTo(size.width * 0.45, size.height * 0.69)
      ..lineTo(size.width * 0.60, size.height * 0.69)
      ..quadraticBezierTo(size.width * 0.63, size.height * 0.78,
          size.width * 0.53, size.height * 0.81)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.78,
          size.width * 0.45, size.height * 0.69);
    canvas.drawPath(shorts, darkFill);

    canvas.save();
    canvas.translate(size.width * 0.48, size.height * 0.39);
    canvas.rotate(-0.18);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset.zero,
            width: size.width * 0.31,
            height: size.height * 0.25),
        peachFill);
    canvas.restore();

    final hair = Path()
      ..moveTo(size.width * 0.37, size.height * 0.37)
      ..quadraticBezierTo(size.width * 0.38, size.height * 0.26,
          size.width * 0.49, size.height * 0.23)
      ..lineTo(size.width * 0.57, size.height * 0.13)
      ..quadraticBezierTo(size.width * 0.60, size.height * 0.24,
          size.width * 0.64, size.height * 0.27)
      ..lineTo(size.width * 0.70, size.height * 0.30)
      ..lineTo(size.width * 0.63, size.height * 0.36)
      ..quadraticBezierTo(size.width * 0.59, size.height * 0.31,
          size.width * 0.54, size.height * 0.30)
      ..quadraticBezierTo(size.width * 0.48, size.height * 0.31,
          size.width * 0.45, size.height * 0.26)
      ..quadraticBezierTo(size.width * 0.42, size.height * 0.32,
          size.width * 0.37, size.height * 0.37);
    canvas.drawPath(hair, darkFill);
    canvas.drawCircle(Offset(size.width * 0.59, size.height * 0.39),
        size.width * 0.042, peachFill);

    _face(canvas, size, dark, accent);
    _palm(canvas, Offset(size.width * 0.23, size.height * 0.20),
        size.width * 0.21, accent, false);
    _palm(canvas, Offset(size.width * 0.77, size.height * 0.57),
        size.width * 0.19, accent, true);

    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(size.width * 0.32, size.height * 0.42),
            width: size.width * 0.13,
            height: size.height * 0.14),
        4.18,
        1.56,
        false,
        accentLine);
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(size.width * 0.69, size.height * 0.56),
            width: size.width * 0.16,
            height: size.height * 0.19),
        math.pi * 0.93,
        math.pi * 0.68,
        false,
        accentLine);
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(size.width * 0.54, size.height * 0.22),
            width: size.width * 0.16,
            height: size.height * 0.06),
        5.15,
        0.78,
        false,
        Paint()
          ..color = cream
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = size.shortestSide * 0.012);

    final frontOrbit = Path()
      ..moveTo(size.width * 0.12, size.height * 0.56)
      ..quadraticBezierTo(size.width * 0.04, size.height * 0.41,
          size.width * 0.18, size.height * 0.32)
      ..quadraticBezierTo(size.width * 0.52, size.height * 0.14,
          size.width * 0.90, size.height * 0.38)
      ..quadraticBezierTo(size.width * 1.02, size.height * 0.47,
          size.width * 0.86, size.height * 0.69)
      ..quadraticBezierTo(size.width * 0.50, size.height * 0.97,
          size.width * 0.24, size.height * 0.84)
      ..quadraticBezierTo(size.width * 0.10, size.height * 0.77,
          size.width * 0.18, size.height * 0.56);
    final lowOrbit = Path()
      ..moveTo(size.width * 0.18, size.height * 0.94)
      ..quadraticBezierTo(size.width * 0.28, size.height * 0.60,
          size.width * 0.54, size.height * 0.57)
      ..quadraticBezierTo(size.width * 0.86, size.height * 0.52,
          size.width * 1.02, size.height * 0.67);
    canvas.drawPath(frontOrbit, orbit);
    canvas.drawPath(lowOrbit, orbit);

    _flower(canvas, Offset(size.width * 0.74, size.height * 0.24),
        size.width * 0.046, accent, dark);
    canvas.drawCircle(Offset(size.width * 0.86, size.height * 0.26),
        size.width * 0.024, darkFill);
    _spark(canvas, Offset(size.width * 0.16, size.height * 0.60),
        size.width * 0.055, cream);
    _ring(canvas, Offset(size.width * 0.20, size.height * 0.83),
        size.width * 0.040, accent);
    canvas.drawCircle(Offset(size.width * 0.24, size.height * 0.88),
        size.width * 0.034, accentFill);
    canvas.drawCircle(Offset(size.width * 0.31, size.height * 0.91),
        size.width * 0.014, darkFill);
    _flower(canvas, Offset(size.width * 0.48, size.height * 0.98),
        size.width * 0.055, cream, accent);
  }

  void _capsule(Canvas canvas, Offset c, Size s, double r, Paint paint) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(r);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: s.width, height: s.height),
        Radius.circular(s.shortestSide / 2),
      ),
      paint,
    );
    canvas.restore();
  }

  void _shoe(Canvas canvas, Offset c, Size s, double r, Color color) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(r);
    final p = Path()
      ..moveTo(-s.width * 0.52, -s.height * 0.12)
      ..quadraticBezierTo(
          -s.width * 0.14, -s.height * 0.42, s.width * 0.38, -s.height * 0.30)
      ..quadraticBezierTo(
          s.width * 0.60, -s.height * 0.16, s.width * 0.50, s.height * 0.14)
      ..quadraticBezierTo(
          s.width * 0.28, s.height * 0.40, -s.width * 0.24, s.height * 0.32)
      ..quadraticBezierTo(
          -s.width * 0.58, s.height * 0.18, -s.width * 0.52, -s.height * 0.12);
    canvas.drawPath(p, Paint()..color = color);
    canvas.restore();
  }

  void _face(Canvas canvas, Size size, Color dark, Color accent) {
    final line = Paint()
      ..color = dark
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.shortestSide * 0.008;
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(size.width * 0.48, size.height * 0.43),
            width: size.width * 0.18,
            height: size.height * 0.10),
        0.18,
        math.pi - 0.36,
        false,
        line);
    canvas.drawCircle(Offset(size.width * 0.44, size.height * 0.43),
        size.width * 0.016, Paint()..color = dark);
    canvas.drawCircle(Offset(size.width * 0.54, size.height * 0.43),
        size.width * 0.016, Paint()..color = dark);
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(size.width * 0.45, size.height * 0.35),
            width: size.width * 0.06,
            height: size.height * 0.05),
        math.pi,
        math.pi * 0.75,
        false,
        line);
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(size.width * 0.56, size.height * 0.35),
            width: size.width * 0.06,
            height: size.height * 0.05),
        0.28,
        math.pi * 0.75,
        false,
        line);
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(size.width * 0.50, size.height * 0.45),
            width: size.width * 0.05,
            height: size.height * 0.04),
        math.pi,
        math.pi,
        false,
        line);
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(size.width * 0.48, size.height * 0.30),
            width: size.width * 0.18,
            height: size.height * 0.11),
        0.68,
        1.95,
        false,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = size.shortestSide * 0.009);
  }

  void _palm(
      Canvas canvas, Offset c, double scale, Color color, bool mirrored) {
    final path = Path()
      ..moveTo(-0.48, -0.36)
      ..quadraticBezierTo(-0.63, -0.10, -0.46, 0.14)
      ..quadraticBezierTo(-0.18, 0.37, 0.02, 0.10)
      ..quadraticBezierTo(0.20, -0.06, 0.24, -0.28)
      ..quadraticBezierTo(0.12, -0.50, -0.06, -0.62)
      ..moveTo(-0.20, -0.54)
      ..quadraticBezierTo(-0.03, -0.34, 0.08, -0.04)
      ..moveTo(0.02, -0.48)
      ..quadraticBezierTo(0.17, -0.24, 0.10, 0.00)
      ..moveTo(-0.50, -0.06)
      ..quadraticBezierTo(-0.60, 0.02, -0.54, 0.18)
      ..moveTo(0.10, 0.08)
      ..quadraticBezierTo(0.02, 0.22, -0.04, 0.18);
    final m = Matrix4.identity()
      ..translate(c.dx, c.dy)
      ..scale(mirrored ? -scale : scale, scale);
    canvas.drawPath(
        path.transform(m.storage),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = scale * 0.095);
  }

  void _flower(Canvas canvas, Offset c, double r, Color petal, Color core) {
    final petalPaint = Paint()..color = petal;
    for (int i = 0; i < 6; i++) {
      final a = math.pi * 2 / 6 * i;
      canvas.drawCircle(
          Offset(c.dx + math.cos(a) * r * 0.92, c.dy + math.sin(a) * r * 0.92),
          r * 0.60,
          petalPaint);
    }
    canvas.drawCircle(c, r * 0.42, Paint()..color = core);
  }

  void _spark(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = r * 0.18;
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), p);
    canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), p);
    canvas.drawLine(Offset(c.dx - r * 0.65, c.dy - r * 0.65),
        Offset(c.dx + r * 0.65, c.dy + r * 0.65), p);
    canvas.drawLine(Offset(c.dx - r * 0.65, c.dy + r * 0.65),
        Offset(c.dx + r * 0.65, c.dy - r * 0.65), p);
  }

  void _ring(Canvas canvas, Offset c, double r, Color color) {
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.40);
  }

  @override
  bool shouldRepaint(covariant _ReferencePainter oldDelegate) {
    return peach != oldDelegate.peach ||
        accent != oldDelegate.accent ||
        dark != oldDelegate.dark ||
        cream != oldDelegate.cream;
  }
}
