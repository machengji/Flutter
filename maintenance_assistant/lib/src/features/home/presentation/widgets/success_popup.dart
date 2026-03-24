import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme.dart';
import '../providers/home_provider.dart';

class SuccessPopup extends StatefulWidget {
  final String description;
  final String type;
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
  static const String _referenceAssetPath =
      'assets/images/success_popup_reference.png';

  late String _rainbowFart;

  bool get _isDream => widget.type == 'dream';
  Color get _bg => const Color(0xFF0B7776);
  Color get _peach => const Color(0xFFF5B9AB);
  Color get _accent => const Color(0xFFFF4735);
  Color get _dark => const Color(0xFF620033);
  Color get _cream => const Color(0xFFF4EFD8);

  String get _title => _isDream
      ? '\u68A6\u60F3\u5B8C\u6210\u5566'
      : '\u884C\u52A8\u5B8C\u6210\u5566';
  String get _subtitle => _isDream
      ? '\u4F60\u628A\u4E00\u4E2A\u5FF5\u5934\uFF0C\u8BA4\u771F\u505A\u6210\u4E86\u73B0\u5B9E\u3002'
      : '\u4F60\u53C8\u5B8C\u6210\u4E86\u4E00\u6B21\u884C\u52A8\uFF0C\u8282\u594F\u6B63\u5728\u6162\u6162\u53D8\u5F3A\u3002';
  String get _badge =>
      _isDream ? '\u68A6\u60F3\u91CC\u7A0B\u7891' : '\u884C\u52A8\u5E86\u795D';

  String get _summary {
    if (widget.description.trim().isEmpty) {
      return _isDream
          ? '\u8FD9\u6B21\u5B8C\u6210\uFF0C\u4E5F\u503C\u5F97\u88AB\u597D\u597D\u8BB0\u4F4F\u3002'
          : '\u6BCF\u4E00\u6B21\u5C0F\u5C0F\u6253\u5361\uFF0C\u90FD\u4F1A\u6162\u6162\u5806\u51FA\u5927\u53D8\u5316\u3002';
    }
    return widget.description;
  }

  @override
  void initState() {
    super.initState();
    _rainbowFart = context.read<HomeProvider>().rainbowFart;
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _rainbowFart));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            '\u5F69\u8679\u5C41\u5DF2\u590D\u5236\u5230\u526A\u8D34\u677F'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;
    final width = math.min(media.width * 0.9, 420.0);
    final height = math.min(media.height * 0.80, 700.0);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(color: Colors.black.withOpacity(0.34)),
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
                        color: Colors.black.withOpacity(0.24),
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
                        final contentTop = (c.maxHeight * 0.40).floorToDouble();
                        const artOverlap = 12.0;
                        return Stack(
                          children: [
                            Positioned.fill(child: ColoredBox(color: _bg)),
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: artHeight + artOverlap,
                              child: _PosterArt(
                                assetPath: _referenceAssetPath,
                                painter: _ReferencePainter(
                                  peach: _peach,
                                  accent: _accent,
                                  dark: _dark,
                                  cream: _cream,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              top: artHeight - 44,
                              height: 108,
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        _bg.withOpacity(0.24),
                                        _bg.withOpacity(0.74),
                                        _bg,
                                      ],
                                      stops: const [0.0, 0.42, 0.80, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 18,
                              right: 18,
                              child: GestureDetector(
                                onTap: widget.onClose,
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: _cream.withOpacity(0.96),
                                    shape: BoxShape.circle,
                                  ),
                                  child:
                                      Icon(Icons.close_rounded, color: _dark),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 22,
                              right: 22,
                              top: contentTop,
                              bottom: 14,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: _PopupContent(
                                  badge: _badge,
                                  title: _title,
                                  subtitle: _subtitle,
                                  rainbowFart: _rainbowFart,
                                  summary: _summary,
                                  isDream: _isDream,
                                  cream: _cream,
                                  accent: _accent,
                                  dark: _dark,
                                  onCopy: _copy,
                                  onClose: widget.onClose,
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
            ).animate().fadeIn(duration: 220.ms, curve: Curves.easeOut).scale(
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

class _PopupContent extends StatelessWidget {
  final String badge;
  final String title;
  final String subtitle;
  final String rainbowFart;
  final String summary;
  final bool isDream;
  final Color cream;
  final Color accent;
  final Color dark;
  final VoidCallback onCopy;
  final VoidCallback onClose;

  const _PopupContent({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.rainbowFart,
    required this.summary,
    required this.isDream,
    required this.cream,
    required this.accent,
    required this.dark,
    required this.onCopy,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: cream.withOpacity(0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: cream.withOpacity(0.16)),
          ),
          child: Text(
            badge,
            style: AppTextStyles.labelMedium.copyWith(
              color: cream,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: AppTextStyles.headlineSmall.copyWith(
            color: cream,
            fontSize: 21,
            fontWeight: FontWeight.w800,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: cream.withOpacity(0.82),
            height: 1.32,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          decoration: BoxDecoration(
            color: cream.withOpacity(0.97),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              Text(
                rainbowFart,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: dark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onCopy,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.copy_rounded, size: 14, color: dark),
                    const SizedBox(width: 6),
                    Text(
                      '\u590D\u5236\u5F69\u8679\u5C41',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: dark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MetaPill(
                label: '\u5B8C\u6210\u7C7B\u578B',
                value: isDream
                    ? '\u68A6\u60F3\u8FBE\u6210'
                    : '\u884C\u52A8\u6253\u5361',
                bg: Colors.white.withOpacity(0.10),
                labelColor: cream.withOpacity(0.74),
                valueColor: cream,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetaPill(
                label: '\u672C\u6B21\u8BB0\u5F55',
                value: summary.length > 7
                    ? '${summary.substring(0, 7)}...'
                    : summary,
                bg: dark.withOpacity(0.22),
                labelColor: cream.withOpacity(0.68),
                valueColor: cream,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _OutlineBtn(
                label: '\u590D\u5236\u6587\u6848',
                icon: Icons.auto_awesome_rounded,
                onTap: onCopy,
                color: cream,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FillBtn(
                label: '\u7EE7\u7EED\u524D\u8FDB',
                onTap: onClose,
                bg: accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PosterArt extends StatelessWidget {
  final String assetPath;
  final CustomPainter painter;

  const _PosterArt({
    required this.assetPath,
    required this.painter,
  });

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF0B7776);

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: bgColor),
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          bottom: -18,
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) {
              return CustomPaint(
                painter: painter,
              );
            },
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x1A0B7776),
                    Color(0x660B7776),
                    bgColor,
                  ],
                  stops: [0.0, 0.70, 0.88, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final String value;
  final Color bg;
  final Color labelColor;
  final Color valueColor;

  const _MetaPill({
    required this.label,
    required this.value,
    required this.bg,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Text(label,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelLarge.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FillBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color bg;

  const _FillBtn({
    required this.label,
    required this.onTap,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: Text(label,
            style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _OutlineBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: color),
        label: Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.46)),
          backgroundColor: Colors.white.withOpacity(0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
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
    final accentFill = Paint()..color = accent;
    final darkFill = Paint()..color = dark;
    final accentLine = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.shortestSide * 0.010;
    final darkLine = Paint()
      ..color = dark
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.shortestSide * 0.008;
    final orbit = Paint()
      ..color = cream
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.shortestSide * 0.020;

    final backOrbit = Path()
      ..moveTo(size.width * 0.70, size.height * 0.28)
      ..quadraticBezierTo(size.width * 0.90, size.height * 0.18,
          size.width * 0.92, size.height * 0.44)
      ..quadraticBezierTo(size.width * 0.92, size.height * 0.64,
          size.width * 0.82, size.height * 0.82);
    canvas.drawPath(backOrbit, orbit);

    _capsule(canvas, Offset(size.width * 0.23, size.height * 0.18),
        Size(size.width * 0.31, size.height * 0.56), -0.44, peachFill);
    _capsule(canvas, Offset(size.width * 0.74, size.height * 0.48),
        Size(size.width * 0.26, size.height * 0.33), 0.38, peachFill);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width * 0.47, size.height * 0.40),
            width: size.width * 0.34,
            height: size.height * 0.30),
        peachFill);

    final hair = Path()
      ..moveTo(size.width * 0.38, size.height * 0.34)
      ..quadraticBezierTo(size.width * 0.42, size.height * 0.21,
          size.width * 0.57, size.height * 0.24)
      ..quadraticBezierTo(size.width * 0.68, size.height * 0.12,
          size.width * 0.74, size.height * 0.18)
      ..quadraticBezierTo(size.width * 0.73, size.height * 0.32,
          size.width * 0.61, size.height * 0.44)
      ..quadraticBezierTo(size.width * 0.56, size.height * 0.57,
          size.width * 0.63, size.height * 0.69)
      ..quadraticBezierTo(size.width * 0.53, size.height * 0.64,
          size.width * 0.42, size.height * 0.54)
      ..quadraticBezierTo(size.width * 0.31, size.height * 0.44,
          size.width * 0.38, size.height * 0.34);
    canvas.drawPath(hair, darkFill);

    _capsule(canvas, Offset(size.width * 0.57, size.height * 0.61),
        Size(size.width * 0.22, size.height * 0.09), 0.62, peachFill);
    _capsule(canvas, Offset(size.width * 0.39, size.height * 0.49),
        Size(size.width * 0.15, size.height * 0.23), 0.42, peachFill);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(size.width * 0.50, size.height * 0.63),
            width: size.width * 0.18,
            height: size.height * 0.08),
        Radius.circular(size.width * 0.03),
      ),
      darkFill,
    );
    final stripe = Paint()
      ..color = cream
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.shortestSide * 0.012;
    canvas.drawLine(Offset(size.width * 0.46, size.height * 0.61),
        Offset(size.width * 0.46, size.height * 0.66), stripe);
    canvas.drawLine(Offset(size.width * 0.50, size.height * 0.61),
        Offset(size.width * 0.50, size.height * 0.66), stripe);

    _shoe(canvas, Offset(size.width * 0.71, size.height * 0.91),
        Size(size.width * 0.38, size.height * 0.16), 0.28, accent);
    _capsule(canvas, Offset(size.width * 0.56, size.height * 0.82),
        Size(size.width * 0.17, size.height * 0.11), 0.85, accentFill);

    _face(canvas, size, dark, accent);
    _palm(canvas, Offset(size.width * 0.22, size.height * 0.16),
        size.shortestSide * 0.31, accent, false);
    _palm(canvas, Offset(size.width * 0.75, size.height * 0.47),
        size.shortestSide * 0.20, accent, true);
    canvas.drawLine(Offset(size.width * 0.36, size.height * 0.64),
        Offset(size.width * 0.29, size.height * 0.73), darkLine);
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(size.width * 0.43, size.height * 0.54),
            width: size.width * 0.19,
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
