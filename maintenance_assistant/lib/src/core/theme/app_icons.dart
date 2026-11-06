import 'package:flutter/material.dart';

/// 森系同色阶柔光层叠（Soft Tonal Duotone Botanical）图标类型枚举
/// 无黑边、半透明后景柔光层 + 温润同色系主体 + 内部穿透叶脉，与卡片及页面背景自然交融
enum AppIconType {
  plan,
  habit,
  anchor,
  add,
  explore,
  edit,
  pin,
  archive,
  delete,
  notification,
  notificationOutlined,
  check,
  refresh,
  share,
  analytics,
  data,
  apiKey,
  help,
  coffee,
  play,
  pause,
  menu,
  settings,
  upload,
  download,
  close,
  chevronRight,
  brandLogo,
}

/// 兼容旧代码的语义化图标映射
class AppIcons {
  AppIcons._();
  static const AppIconType plan = AppIconType.plan;
  static const AppIconType habit = AppIconType.habit;
  static const AppIconType anchor = AppIconType.anchor;
  static const AppIconType add = AppIconType.add;
  static const AppIconType explore = AppIconType.explore;
  static const AppIconType edit = AppIconType.edit;
  static const AppIconType pin = AppIconType.pin;
  static const AppIconType archive = AppIconType.archive;
  static const AppIconType delete = AppIconType.delete;
  static const AppIconType notification = AppIconType.notification;
  static const AppIconType notificationOutlined = AppIconType.notificationOutlined;
  static const AppIconType check = AppIconType.check;
  static const AppIconType refresh = AppIconType.refresh;
  static const AppIconType share = AppIconType.share;
  static const AppIconType analytics = AppIconType.analytics;
  static const AppIconType data = AppIconType.data;
  static const AppIconType apiKey = AppIconType.apiKey;
  static const AppIconType help = AppIconType.help;
  static const AppIconType coffee = AppIconType.coffee;
  static const AppIconType play = AppIconType.play;
  static const AppIconType pause = AppIconType.pause;
  static const AppIconType menu = AppIconType.menu;
  static const AppIconType settings = AppIconType.settings;
  static const AppIconType upload = AppIconType.upload;
  static const AppIconType download = AppIconType.download;
  static const AppIconType close = AppIconType.close;
  static const AppIconType chevronRight = AppIconType.chevronRight;
  static const AppIconType brandLogo = AppIconType.brandLogo;
}

/// 森系同色阶柔光层叠矢量图标组件
/// 自动根据传入的 [color] 或默认森系色阶生成“28%柔光底衬 + 95%温润主体 + 穿透式叶脉”三阶同色系过渡
class AppIcon extends StatelessWidget {
  final AppIconType type;
  final double size;
  final Color? color;

  const AppIcon({
    super.key,
    required this.type,
    this.size = 22.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        isComplex: true,
        willChange: false,
        size: Size.square(size),
        painter: _TonalBotanicalPainter(
          type: type,
          overrideColor: color,
        ),
      ),
    );
  }
}

class _TonalBotanicalPainter extends CustomPainter {
  final AppIconType type;
  final Color? overrideColor;

  const _TonalBotanicalPainter({
    required this.type,
    this.overrideColor,
  });

  Color _defaultToneColor(AppIconType t) {
    switch (t) {
      case AppIconType.plan:
        return const Color(0xFF2D6A4F);
      case AppIconType.habit:
        return const Color(0xFF2F6F73);
      case AppIconType.anchor:
        return const Color(0xFFB57632);
      case AppIconType.add:
        return const Color(0xFF2D6A4F);
      case AppIconType.explore:
        return const Color(0xFF2D6A4F);
      case AppIconType.edit:
        return const Color(0xFF6E5D4F);
      case AppIconType.pin:
        return const Color(0xFFB57632);
      case AppIconType.archive:
        return const Color(0xFF6E5D4F);
      case AppIconType.delete:
        return const Color(0xFFB55A52);
      case AppIconType.notification:
        return const Color(0xFFB57632);
      case AppIconType.notificationOutlined:
        return const Color(0xFF6E5D4F);
      case AppIconType.check:
        return const Color(0xFF2D6A4F);
      case AppIconType.refresh:
        return const Color(0xFF2F6F73);
      case AppIconType.share:
        return const Color(0xFF2F6F73);
      case AppIconType.analytics:
        return const Color(0xFF2D6A4F);
      case AppIconType.data:
        return const Color(0xFFB57632);
      case AppIconType.apiKey:
        return const Color(0xFFB57632);
      case AppIconType.help:
        return const Color(0xFF2F6F73);
      case AppIconType.coffee:
        return const Color(0xFF2D6A4F);
      case AppIconType.play:
        return const Color(0xFF2D6A4F);
      case AppIconType.pause:
        return const Color(0xFF6E5D4F);
      case AppIconType.menu:
        return const Color(0xFF2D6A4F);
      case AppIconType.settings:
        return const Color(0xFF6E5D4F);
      case AppIconType.upload:
        return const Color(0xFF2F6F73);
      case AppIconType.download:
        return const Color(0xFF2D6A4F);
      case AppIconType.close:
        return const Color(0xFF6E5D4F);
      case AppIconType.chevronRight:
        return const Color(0xFF2D6A4F);
      case AppIconType.brandLogo:
        return const Color(0xFF2D6A4F);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 24.0;
    final Color baseColor = overrideColor ?? _defaultToneColor(type);
    final bool isWhite = baseColor.value == 0xFFFFFFFF;
    final double alphaScale = baseColor.opacity;
    final Color solidColor = baseColor.withOpacity((0.95 * alphaScale).clamp(0.0, 1.0));
    final Color softColor = baseColor.withOpacity(((isWhite ? 0.32 : 0.28) * alphaScale).clamp(0.0, 1.0));
    final Color cutoutColor = isWhite
        ? const Color(0xFF2D6A4F).withOpacity(0.45)
        : const Color(0xFFFAFDFB).withOpacity((0.92 * alphaScale).clamp(0.0, 1.0));

    final Paint softFill = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..color = softColor;

    final Paint solidFill = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..color = solidColor;

    final Paint primaryStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..color = solidColor;

    final Paint cutoutStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..color = cutoutColor;

    switch (type) {
      case AppIconType.plan:
        final p1 = Path()
          ..moveTo(12.000 * s, 13.000 * s)
          ..cubicTo(12.000 * s, 9.500 * s, 15.200 * s, 6.500 * s, 19.500 * s, 6.500 * s)
          ..cubicTo(19.500 * s, 10.800 * s, 16.500 * s, 13.500 * s, 12.000 * s, 13.000 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(6.000 * s, 20.000 * s)
          ..cubicTo(8.000 * s, 18.500 * s, 16.000 * s, 18.500 * s, 18.000 * s, 20.000 * s)
          ..cubicTo(15.000 * s, 21.000 * s, 9.000 * s, 21.000 * s, 6.000 * s, 20.000 * s)
          ..close();
        canvas.drawPath(p2, softFill);
        final p3 = Path()
          ..moveTo(12.000 * s, 14.500 * s)
          ..cubicTo(12.000 * s, 10.000 * s, 8.200 * s, 6.500 * s, 3.800 * s, 6.500 * s)
          ..cubicTo(3.800 * s, 11.000 * s, 7.200 * s, 14.500 * s, 12.000 * s, 14.500 * s)
          ..close();
        canvas.drawPath(p3, solidFill);
        final p4 = Path()
          ..moveTo(12.000 * s, 20.000 * s)
          ..lineTo(12.000 * s, 10.000 * s);
        canvas.drawPath(p4, primaryStroke);
        final p5 = Path()
          ..moveTo(7.500 * s, 19.800 * s)
          ..cubicTo(9.800 * s, 19.000 * s, 14.200 * s, 19.000 * s, 16.500 * s, 19.800 * s);
        canvas.drawPath(p5, primaryStroke);
        final p6 = Path()
          ..moveTo(6.500 * s, 9.000 * s)
          ..cubicTo(8.500 * s, 10.200 * s, 10.200 * s, 12.000 * s, 11.500 * s, 14.000 * s);
        canvas.drawPath(p6, cutoutStroke);
        break;
      case AppIconType.habit:
        final p1 = Path()
          ..moveTo(12.000 * s, 12.000 * s)
          ..cubicTo(14.500 * s, 6.500 * s, 20.500 * s, 5.000 * s, 21.000 * s, 9.500 * s)
          ..cubicTo(21.400 * s, 13.000 * s, 16.500 * s, 15.000 * s, 12.000 * s, 12.000 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(12.000 * s, 12.500 * s)
          ..cubicTo(15.000 * s, 14.500 * s, 19.500 * s, 18.500 * s, 16.500 * s, 20.500 * s)
          ..cubicTo(14.000 * s, 22.000 * s, 12.200 * s, 17.000 * s, 12.000 * s, 12.500 * s)
          ..close();
        canvas.drawPath(p2, softFill);
        final p3 = Path()
          ..moveTo(12.000 * s, 12.000 * s)
          ..cubicTo(9.500 * s, 6.500 * s, 3.500 * s, 5.000 * s, 3.000 * s, 9.500 * s)
          ..cubicTo(2.600 * s, 13.000 * s, 7.500 * s, 15.000 * s, 12.000 * s, 12.000 * s)
          ..close();
        canvas.drawPath(p3, solidFill);
        final p4 = Path()
          ..moveTo(12.000 * s, 12.500 * s)
          ..cubicTo(9.000 * s, 14.500 * s, 4.500 * s, 18.500 * s, 7.500 * s, 20.500 * s)
          ..cubicTo(10.000 * s, 22.000 * s, 11.800 * s, 17.000 * s, 12.000 * s, 12.500 * s)
          ..close();
        canvas.drawPath(p4, solidFill);
        final p5 = Path()
          ..moveTo(12.000 * s, 7.500 * s)
          ..lineTo(12.000 * s, 18.500 * s);
        canvas.drawPath(p5, primaryStroke);
        final p6 = Path()
          ..moveTo(12.000 * s, 8.500 * s)
          ..cubicTo(10.800 * s, 6.500 * s, 9.500 * s, 5.500 * s, 8.200 * s, 5.200 * s);
        canvas.drawPath(p6, primaryStroke);
        final p7 = Path()
          ..moveTo(12.000 * s, 8.500 * s)
          ..cubicTo(13.200 * s, 6.500 * s, 14.500 * s, 5.500 * s, 15.800 * s, 5.200 * s);
        canvas.drawPath(p7, primaryStroke);
        final p8 = Path()
          ..moveTo(6.500 * s, 9.500 * s)
          ..cubicTo(8.000 * s, 10.200 * s, 9.800 * s, 11.000 * s, 11.200 * s, 11.800 * s);
        canvas.drawPath(p8, cutoutStroke);
        break;
      case AppIconType.anchor:
        final p1 = Path()
          ..moveTo(9.000 * s, 12.500 * s)
          ..cubicTo(11.500 * s, 9.500 * s, 16.000 * s, 9.500 * s, 17.500 * s, 12.500 * s)
          ..cubicTo(15.500 * s, 15.500 * s, 11.000 * s, 15.500 * s, 9.000 * s, 12.500 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(4.500 * s, 15.500 * s)
          ..lineTo(8.500 * s, 13.500 * s)
          ..lineTo(7.500 * s, 17.500 * s)
          ..lineTo(4.500 * s, 15.500 * s)
          ..close();
        canvas.drawPath(p2, softFill);
        final p3 = Path()
          ..moveTo(7.500 * s, 13.500 * s)
          ..cubicTo(7.500 * s, 9.500 * s, 10.800 * s, 6.500 * s, 14.800 * s, 6.500 * s)
          ..cubicTo(17.200 * s, 6.500 * s, 19.000 * s, 8.000 * s, 19.500 * s, 10.000 * s)
          ..cubicTo(18.000 * s, 13.800 * s, 14.200 * s, 16.000 * s, 10.000 * s, 15.500 * s)
          ..cubicTo(8.500 * s, 15.300 * s, 7.500 * s, 14.500 * s, 7.500 * s, 13.500 * s)
          ..close();
        canvas.drawPath(p3, solidFill);
        final p4 = Path()
          ..moveTo(19.200 * s, 9.200 * s)
          ..lineTo(21.500 * s, 8.500 * s);
        canvas.drawPath(p4, primaryStroke);
        final p5 = Path()
          ..moveTo(4.000 * s, 19.200 * s)
          ..cubicTo(8.500 * s, 18.200 * s, 15.500 * s, 18.200 * s, 20.500 * s, 19.500 * s);
        canvas.drawPath(p5, primaryStroke);
        final p6 = Path()
          ..moveTo(11.500 * s, 15.500 * s)
          ..lineTo(10.500 * s, 18.500 * s);
        canvas.drawPath(p6, primaryStroke);
        final p7 = Path()
          ..moveTo(14.500 * s, 15.200 * s)
          ..lineTo(14.000 * s, 18.500 * s);
        canvas.drawPath(p7, primaryStroke);
        final p8 = Path()
          ..moveTo(11.000 * s, 11.500 * s)
          ..cubicTo(12.800 * s, 10.800 * s, 14.800 * s, 11.200 * s, 16.000 * s, 12.500 * s);
        canvas.drawPath(p8, cutoutStroke);
        final p9 = Path()
          ..moveTo(16.200 * s, 8.800 * s)
          ..lineTo(16.300 * s, 8.800 * s);
        canvas.drawPath(p9, cutoutStroke);
        break;
      case AppIconType.add:
        final p1 = Path()
          ..moveTo(12.000 * s, 3.500 * s)
          ..cubicTo(14.800 * s, 3.500 * s, 16.500 * s, 6.200 * s, 15.200 * s, 9.200 * s)
          ..cubicTo(17.800 * s, 10.500 * s, 18.500 * s, 13.800 * s, 16.200 * s, 16.000 * s)
          ..cubicTo(14.000 * s, 18.200 * s, 10.000 * s, 18.200 * s, 7.800 * s, 16.000 * s)
          ..cubicTo(5.500 * s, 13.800 * s, 6.200 * s, 10.500 * s, 8.800 * s, 9.200 * s)
          ..cubicTo(7.500 * s, 6.200 * s, 9.200 * s, 3.500 * s, 12.000 * s, 3.500 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(12.000 * s, 6.200 * s)
          ..cubicTo(13.800 * s, 6.200 * s, 15.000 * s, 8.000 * s, 14.200 * s, 10.200 * s)
          ..cubicTo(16.200 * s, 11.000 * s, 16.500 * s, 13.500 * s, 14.800 * s, 15.000 * s)
          ..cubicTo(13.200 * s, 16.500 * s, 10.800 * s, 16.500 * s, 9.200 * s, 15.000 * s)
          ..cubicTo(7.500 * s, 13.500 * s, 7.800 * s, 11.000 * s, 9.800 * s, 10.200 * s)
          ..cubicTo(9.000 * s, 8.000 * s, 10.200 * s, 6.200 * s, 12.000 * s, 6.200 * s)
          ..close();
        canvas.drawPath(p2, solidFill);
        final p3 = Path()
          ..moveTo(12.000 * s, 16.500 * s)
          ..lineTo(12.000 * s, 20.500 * s);
        canvas.drawPath(p3, primaryStroke);
        final p4 = Path()
          ..moveTo(9.500 * s, 19.000 * s)
          ..cubicTo(10.800 * s, 18.200 * s, 13.200 * s, 18.200 * s, 14.500 * s, 19.000 * s);
        canvas.drawPath(p4, primaryStroke);
        final p5 = Path()
          ..moveTo(12.000 * s, 9.800 * s)
          ..lineTo(12.000 * s, 13.800 * s);
        canvas.drawPath(p5, cutoutStroke);
        final p6 = Path()
          ..moveTo(10.000 * s, 11.800 * s)
          ..lineTo(14.000 * s, 11.800 * s);
        canvas.drawPath(p6, cutoutStroke);
        break;
      case AppIconType.explore:
        final p1 = Path()
          ..moveTo(12.000 * s, 11.500 * s)
          ..cubicTo(12.000 * s, 7.500 * s, 15.200 * s, 4.500 * s, 19.000 * s, 4.500 * s)
          ..cubicTo(19.000 * s, 8.200 * s, 16.000 * s, 11.500 * s, 12.000 * s, 11.500 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(12.000 * s, 12.500 * s)
          ..cubicTo(12.000 * s, 16.500 * s, 8.800 * s, 19.500 * s, 5.000 * s, 19.500 * s)
          ..cubicTo(5.000 * s, 15.800 * s, 8.000 * s, 12.500 * s, 12.000 * s, 12.500 * s)
          ..close();
        canvas.drawPath(p2, softFill);
        final p3 = Path()
          ..moveTo(12.000 * s, 11.500 * s)
          ..cubicTo(12.000 * s, 7.500 * s, 8.800 * s, 4.500 * s, 5.000 * s, 4.500 * s)
          ..cubicTo(5.000 * s, 8.200 * s, 8.000 * s, 11.500 * s, 12.000 * s, 11.500 * s)
          ..close();
        canvas.drawPath(p3, solidFill);
        final p4 = Path()
          ..moveTo(12.000 * s, 12.500 * s)
          ..cubicTo(12.000 * s, 16.500 * s, 15.200 * s, 19.500 * s, 19.000 * s, 19.500 * s)
          ..cubicTo(19.000 * s, 15.800 * s, 16.000 * s, 12.500 * s, 12.000 * s, 12.500 * s)
          ..close();
        canvas.drawPath(p4, solidFill);
        final p5 = Path()
          ..moveTo(12.000 * s, 4.000 * s)
          ..lineTo(12.000 * s, 20.000 * s);
        canvas.drawPath(p5, primaryStroke);
        final p6 = Path()
          ..moveTo(4.000 * s, 12.000 * s)
          ..lineTo(20.000 * s, 12.000 * s);
        canvas.drawPath(p6, primaryStroke);
        final p7 = Path()
          ..moveTo(7.500 * s, 7.500 * s)
          ..lineTo(10.500 * s, 10.500 * s);
        canvas.drawPath(p7, cutoutStroke);
        final p8 = Path()
          ..moveTo(13.500 * s, 13.500 * s)
          ..lineTo(16.500 * s, 16.500 * s);
        canvas.drawPath(p8, cutoutStroke);
        break;
      case AppIconType.edit:
        final p1 = Path()
          ..moveTo(18.500 * s, 4.500 * s)
          ..cubicTo(20.500 * s, 7.500 * s, 18.500 * s, 13.500 * s, 12.500 * s, 16.500 * s)
          ..lineTo(8.500 * s, 12.500 * s)
          ..cubicTo(11.500 * s, 6.500 * s, 15.500 * s, 3.500 * s, 18.500 * s, 4.500 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(18.500 * s, 4.500 * s)
          ..cubicTo(14.500 * s, 4.200 * s, 9.500 * s, 7.800 * s, 7.800 * s, 13.800 * s)
          ..lineTo(11.200 * s, 16.200 * s)
          ..cubicTo(15.500 * s, 13.500 * s, 18.200 * s, 8.500 * s, 18.500 * s, 4.500 * s)
          ..close();
        canvas.drawPath(p2, solidFill);
        final p3 = Path()
          ..moveTo(18.500 * s, 4.500 * s)
          ..lineTo(5.500 * s, 19.500 * s);
        canvas.drawPath(p3, primaryStroke);
        final p4 = Path()
          ..moveTo(5.500 * s, 19.500 * s)
          ..lineTo(10.500 * s, 19.500 * s);
        canvas.drawPath(p4, primaryStroke);
        final p5 = Path()
          ..moveTo(15.500 * s, 8.000 * s)
          ..lineTo(10.500 * s, 13.000 * s);
        canvas.drawPath(p5, cutoutStroke);
        break;
      case AppIconType.pin:
        final p1 = Path()
          ..moveTo(12.000 * s, 16.500 * s)
          ..cubicTo(7.000 * s, 16.500 * s, 3.500 * s, 13.000 * s, 3.500 * s, 8.500 * s)
          ..cubicTo(7.200 * s, 8.500 * s, 10.200 * s, 11.500 * s, 12.000 * s, 16.500 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(12.000 * s, 16.500 * s)
          ..cubicTo(17.000 * s, 16.500 * s, 20.500 * s, 13.000 * s, 20.500 * s, 8.500 * s)
          ..cubicTo(16.800 * s, 8.500 * s, 13.800 * s, 11.500 * s, 12.000 * s, 16.500 * s)
          ..close();
        canvas.drawPath(p2, softFill);
        final p3 = Path()
          ..moveTo(12.000 * s, 4.500 * s)
          ..cubicTo(15.200 * s, 8.200 * s, 15.800 * s, 13.200 * s, 12.000 * s, 16.800 * s)
          ..cubicTo(8.200 * s, 13.200 * s, 8.800 * s, 8.200 * s, 12.000 * s, 4.500 * s)
          ..close();
        canvas.drawPath(p3, solidFill);
        final p4 = Path()
          ..moveTo(6.500 * s, 19.500 * s)
          ..cubicTo(9.500 * s, 18.500 * s, 14.500 * s, 18.500 * s, 17.500 * s, 19.500 * s);
        canvas.drawPath(p4, primaryStroke);
        final p5 = Path()
          ..moveTo(12.000 * s, 8.500 * s)
          ..lineTo(12.000 * s, 14.500 * s);
        canvas.drawPath(p5, cutoutStroke);
        break;
      case AppIconType.archive:
        final p1 = Path()
          ..moveTo(6.500 * s, 11.500 * s)
          ..lineTo(17.500 * s, 11.500 * s)
          ..lineTo(17.500 * s, 14.500 * s)
          ..cubicTo(17.500 * s, 17.800 * s, 15.000 * s, 20.200 * s, 12.000 * s, 20.200 * s)
          ..cubicTo(9.000 * s, 20.200 * s, 6.500 * s, 17.800 * s, 6.500 * s, 14.500 * s)
          ..lineTo(6.500 * s, 11.500 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(5.200 * s, 10.500 * s)
          ..cubicTo(5.200 * s, 7.500 * s, 8.200 * s, 5.500 * s, 12.000 * s, 5.500 * s)
          ..cubicTo(15.800 * s, 5.500 * s, 18.800 * s, 7.500 * s, 18.800 * s, 10.500 * s)
          ..cubicTo(18.800 * s, 11.300 * s, 18.200 * s, 11.800 * s, 17.200 * s, 11.800 * s)
          ..lineTo(6.800 * s, 11.800 * s)
          ..cubicTo(5.800 * s, 11.800 * s, 5.200 * s, 11.300 * s, 5.200 * s, 10.500 * s)
          ..close();
        canvas.drawPath(p2, solidFill);
        final p3 = Path()
          ..moveTo(12.000 * s, 5.500 * s)
          ..cubicTo(12.000 * s, 4.000 * s, 13.000 * s, 3.000 * s, 14.200 * s, 3.000 * s);
        canvas.drawPath(p3, primaryStroke);
        final p4 = Path()
          ..moveTo(7.000 * s, 11.800 * s)
          ..lineTo(7.000 * s, 14.500 * s)
          ..cubicTo(7.000 * s, 17.500 * s, 9.200 * s, 19.800 * s, 12.000 * s, 19.800 * s)
          ..cubicTo(14.800 * s, 19.800 * s, 17.000 * s, 17.500 * s, 17.000 * s, 14.500 * s)
          ..lineTo(17.000 * s, 11.800 * s);
        canvas.drawPath(p4, primaryStroke);
        final p5 = Path()
          ..moveTo(8.500 * s, 9.200 * s)
          ..lineTo(15.500 * s, 9.200 * s);
        canvas.drawPath(p5, cutoutStroke);
        break;
      case AppIconType.delete:
        final p1 = Path()
          ..moveTo(13.500 * s, 5.500 * s)
          ..cubicTo(18.500 * s, 6.500 * s, 20.500 * s, 11.500 * s, 17.500 * s, 15.500 * s)
          ..cubicTo(14.500 * s, 14.500 * s, 11.500 * s, 13.500 * s, 9.500 * s, 11.500 * s)
          ..cubicTo(10.500 * s, 8.000 * s, 11.800 * s, 6.000 * s, 13.500 * s, 5.500 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(11.500 * s, 4.800 * s)
          ..cubicTo(6.500 * s, 5.500 * s, 4.000 * s, 10.500 * s, 7.000 * s, 14.800 * s)
          ..cubicTo(10.200 * s, 16.500 * s, 14.800 * s, 16.200 * s, 17.500 * s, 13.500 * s)
          ..cubicTo(18.500 * s, 9.500 * s, 16.200 * s, 6.800 * s, 13.500 * s, 7.500 * s)
          ..cubicTo(13.200 * s, 5.800 * s, 12.500 * s, 4.600 * s, 11.500 * s, 4.800 * s)
          ..close();
        canvas.drawPath(p2, solidFill);
        final p3 = Path()
          ..moveTo(11.800 * s, 15.200 * s)
          ..cubicTo(11.200 * s, 17.500 * s, 9.800 * s, 19.200 * s, 7.800 * s, 20.200 * s);
        canvas.drawPath(p3, primaryStroke);
        final p4 = Path()
          ..moveTo(9.500 * s, 10.500 * s)
          ..lineTo(11.800 * s, 14.200 * s);
        canvas.drawPath(p4, cutoutStroke);
        final p5 = Path()
          ..moveTo(13.500 * s, 10.200 * s)
          ..lineTo(12.200 * s, 14.200 * s);
        canvas.drawPath(p5, cutoutStroke);
        break;
      case AppIconType.notification:
        final p1 = Path()
          ..moveTo(6.500 * s, 14.500 * s)
          ..cubicTo(6.500 * s, 10.000 * s, 9.000 * s, 7.500 * s, 12.000 * s, 7.500 * s)
          ..cubicTo(15.000 * s, 7.500 * s, 17.500 * s, 10.000 * s, 17.500 * s, 14.500 * s)
          ..cubicTo(15.500 * s, 15.800 * s, 8.500 * s, 15.800 * s, 6.500 * s, 14.500 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(7.200 * s, 14.800 * s)
          ..cubicTo(7.200 * s, 10.500 * s, 9.300 * s, 8.000 * s, 12.000 * s, 8.000 * s)
          ..cubicTo(14.700 * s, 8.000 * s, 16.800 * s, 10.500 * s, 16.800 * s, 14.800 * s)
          ..cubicTo(15.200 * s, 13.800 * s, 13.800 * s, 14.800 * s, 12.000 * s, 15.500 * s)
          ..cubicTo(10.200 * s, 14.800 * s, 8.800 * s, 13.800 * s, 7.200 * s, 14.800 * s)
          ..close();
        canvas.drawPath(p2, solidFill);
        final p3 = Path()
          ..moveTo(12.000 * s, 18.800 * s)
          ..cubicTo(13.100 * s, 18.800 * s, 14.000 * s, 17.900 * s, 14.000 * s, 16.800 * s)
          ..lineTo(10.000 * s, 16.800 * s)
          ..cubicTo(10.000 * s, 17.900 * s, 10.900 * s, 18.800 * s, 12.000 * s, 18.800 * s)
          ..close();
        canvas.drawPath(p3, solidFill);
        final p4 = Path()
          ..moveTo(12.000 * s, 8.000 * s)
          ..lineTo(12.000 * s, 4.500 * s)
          ..cubicTo(12.000 * s, 4.500 * s, 14.500 * s, 3.800 * s, 16.500 * s, 5.200 * s);
        canvas.drawPath(p4, primaryStroke);
        final p5 = Path()
          ..moveTo(12.000 * s, 10.200 * s)
          ..lineTo(12.000 * s, 13.200 * s);
        canvas.drawPath(p5, cutoutStroke);
        break;
      case AppIconType.notificationOutlined:
        final p1 = Path()
          ..moveTo(7.500 * s, 14.500 * s)
          ..cubicTo(7.500 * s, 10.500 * s, 9.500 * s, 8.200 * s, 12.000 * s, 8.200 * s)
          ..cubicTo(14.500 * s, 8.200 * s, 16.500 * s, 10.500 * s, 16.500 * s, 14.500 * s)
          ..lineTo(7.500 * s, 14.500 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(7.200 * s, 14.800 * s)
          ..cubicTo(7.200 * s, 10.500 * s, 9.300 * s, 8.000 * s, 12.000 * s, 8.000 * s)
          ..cubicTo(14.700 * s, 8.000 * s, 16.800 * s, 10.500 * s, 16.800 * s, 14.800 * s)
          ..cubicTo(15.200 * s, 13.800 * s, 13.800 * s, 14.800 * s, 12.000 * s, 15.500 * s)
          ..cubicTo(10.200 * s, 14.800 * s, 8.800 * s, 13.800 * s, 7.200 * s, 14.800 * s)
          ..close();
        canvas.drawPath(p2, primaryStroke);
        final p3 = Path()
          ..moveTo(10.500 * s, 17.200 * s)
          ..cubicTo(11.000 * s, 18.000 * s, 13.000 * s, 18.000 * s, 13.500 * s, 17.200 * s);
        canvas.drawPath(p3, primaryStroke);
        final p4 = Path()
          ..moveTo(12.000 * s, 8.000 * s)
          ..lineTo(12.000 * s, 4.500 * s)
          ..cubicTo(12.000 * s, 4.500 * s, 14.500 * s, 3.800 * s, 16.200 * s, 5.000 * s);
        canvas.drawPath(p4, primaryStroke);
        break;
      case AppIconType.check:
        final p1 = Path()
          ..moveTo(5.500 * s, 12.500 * s)
          ..cubicTo(5.500 * s, 8.000 * s, 9.500 * s, 4.500 * s, 15.500 * s, 4.500 * s)
          ..cubicTo(16.500 * s, 10.500 * s, 13.000 * s, 16.500 * s, 7.500 * s, 17.500 * s)
          ..cubicTo(6.000 * s, 16.000 * s, 5.500 * s, 14.200 * s, 5.500 * s, 12.500 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(6.500 * s, 12.500 * s)
          ..lineTo(10.200 * s, 16.200 * s)
          ..lineTo(17.800 * s, 7.800 * s);
        canvas.drawPath(p2, primaryStroke);
        break;
      case AppIconType.refresh:
        final p1 = Path()
          ..moveTo(12.000 * s, 4.500 * s)
          ..cubicTo(15.500 * s, 4.500 * s, 18.200 * s, 6.800 * s, 19.000 * s, 10.000 * s)
          ..cubicTo(16.500 * s, 10.500 * s, 14.000 * s, 9.000 * s, 12.000 * s, 4.500 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(12.000 * s, 19.500 * s)
          ..cubicTo(8.500 * s, 19.500 * s, 5.800 * s, 17.200 * s, 5.000 * s, 14.000 * s)
          ..cubicTo(7.500 * s, 13.500 * s, 10.000 * s, 15.000 * s, 12.000 * s, 19.500 * s)
          ..close();
        canvas.drawPath(p2, softFill);
        final p3 = Path()
          ..moveTo(5.500 * s, 10.500 * s)
          ..cubicTo(6.200 * s, 7.000 * s, 9.200 * s, 4.500 * s, 13.000 * s, 4.500 * s)
          ..cubicTo(16.200 * s, 4.500 * s, 18.800 * s, 6.500 * s, 19.500 * s, 9.500 * s);
        canvas.drawPath(p3, primaryStroke);
        final p4 = Path()
          ..moveTo(18.500 * s, 13.500 * s)
          ..cubicTo(17.800 * s, 17.000 * s, 14.800 * s, 19.500 * s, 11.000 * s, 19.500 * s)
          ..cubicTo(7.800 * s, 19.500 * s, 5.200 * s, 17.500 * s, 4.500 * s, 14.500 * s);
        canvas.drawPath(p4, primaryStroke);
        final p5 = Path()
          ..moveTo(16.500 * s, 9.800 * s)
          ..lineTo(19.600 * s, 9.800 * s)
          ..lineTo(19.600 * s, 6.800 * s);
        canvas.drawPath(p5, primaryStroke);
        final p6 = Path()
          ..moveTo(7.500 * s, 14.200 * s)
          ..lineTo(4.400 * s, 14.200 * s)
          ..lineTo(4.400 * s, 17.200 * s);
        canvas.drawPath(p6, primaryStroke);
        break;
      case AppIconType.share:
        final p1 = Path()
          ..moveTo(7.500 * s, 10.500 * s)
          ..cubicTo(9.500 * s, 6.500 * s, 14.000 * s, 5.500 * s, 16.500 * s, 8.500 * s)
          ..cubicTo(14.000 * s, 11.500 * s, 10.000 * s, 12.500 * s, 7.500 * s, 10.500 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(4.500 * s, 13.500 * s)
          ..cubicTo(8.500 * s, 13.500 * s, 11.500 * s, 10.500 * s, 13.500 * s, 6.500 * s)
          ..cubicTo(15.500 * s, 9.500 * s, 18.500 * s, 11.000 * s, 20.500 * s, 11.000 * s)
          ..cubicTo(18.500 * s, 15.500 * s, 13.500 * s, 18.500 * s, 8.500 * s, 17.500 * s)
          ..cubicTo(6.500 * s, 17.000 * s, 5.200 * s, 15.500 * s, 4.500 * s, 13.500 * s)
          ..close();
        canvas.drawPath(p2, solidFill);
        final p3 = Path()
          ..moveTo(18.500 * s, 9.500 * s)
          ..lineTo(21.000 * s, 8.000 * s);
        canvas.drawPath(p3, primaryStroke);
        final p4 = Path()
          ..moveTo(9.500 * s, 14.200 * s)
          ..cubicTo(12.000 * s, 14.500 * s, 14.500 * s, 13.500 * s, 16.200 * s, 11.800 * s);
        canvas.drawPath(p4, cutoutStroke);
        break;
      case AppIconType.analytics:
        final p1 = Path()
          ..moveTo(12.000 * s, 3.500 * s)
          ..cubicTo(16.500 * s, 3.500 * s, 19.500 * s, 7.000 * s, 19.500 * s, 11.000 * s)
          ..cubicTo(19.500 * s, 14.800 * s, 16.500 * s, 17.200 * s, 12.000 * s, 17.200 * s)
          ..cubicTo(7.500 * s, 17.200 * s, 4.500 * s, 14.800 * s, 4.500 * s, 11.000 * s)
          ..cubicTo(4.500 * s, 7.000 * s, 7.500 * s, 3.500 * s, 12.000 * s, 3.500 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(12.000 * s, 6.000 * s)
          ..cubicTo(15.200 * s, 6.000 * s, 17.200 * s, 8.500 * s, 17.200 * s, 11.500 * s)
          ..cubicTo(17.200 * s, 14.200 * s, 15.000 * s, 16.000 * s, 12.000 * s, 16.000 * s)
          ..cubicTo(9.000 * s, 16.000 * s, 6.800 * s, 14.200 * s, 6.800 * s, 11.500 * s)
          ..cubicTo(6.800 * s, 8.500 * s, 8.800 * s, 6.000 * s, 12.000 * s, 6.000 * s)
          ..close();
        canvas.drawPath(p2, solidFill);
        final p3 = Path()
          ..moveTo(12.000 * s, 12.000 * s)
          ..lineTo(12.000 * s, 20.500 * s);
        canvas.drawPath(p3, primaryStroke);
        final p4 = Path()
          ..moveTo(12.000 * s, 14.500 * s)
          ..lineTo(14.500 * s, 12.500 * s);
        canvas.drawPath(p4, primaryStroke);
        final p5 = Path()
          ..moveTo(12.000 * s, 15.500 * s)
          ..lineTo(9.500 * s, 13.500 * s);
        canvas.drawPath(p5, primaryStroke);
        final p6 = Path()
          ..moveTo(8.500 * s, 20.500 * s)
          ..lineTo(15.500 * s, 20.500 * s);
        canvas.drawPath(p6, primaryStroke);
        final p7 = Path()
          ..moveTo(12.000 * s, 8.500 * s)
          ..lineTo(12.000 * s, 15.000 * s);
        canvas.drawPath(p7, cutoutStroke);
        final p8 = Path()
          ..moveTo(12.000 * s, 12.500 * s)
          ..lineTo(14.200 * s, 10.800 * s);
        canvas.drawPath(p8, cutoutStroke);
        final p9 = Path()
          ..moveTo(12.000 * s, 13.500 * s)
          ..lineTo(9.800 * s, 11.800 * s);
        canvas.drawPath(p9, cutoutStroke);
        break;
      case AppIconType.data:
        final p1 = Path()
          ..moveTo(12.000 * s, 3.500 * s)
          ..lineTo(19.000 * s, 7.500 * s)
          ..lineTo(19.000 * s, 16.500 * s)
          ..lineTo(12.000 * s, 20.500 * s)
          ..lineTo(5.000 * s, 16.500 * s)
          ..lineTo(5.000 * s, 7.500 * s)
          ..lineTo(12.000 * s, 3.500 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(12.000 * s, 7.000 * s)
          ..lineTo(16.200 * s, 9.500 * s)
          ..lineTo(16.200 * s, 14.500 * s)
          ..lineTo(12.000 * s, 17.000 * s)
          ..lineTo(7.800 * s, 14.500 * s)
          ..lineTo(7.800 * s, 9.500 * s)
          ..lineTo(12.000 * s, 7.000 * s)
          ..close();
        canvas.drawPath(p2, solidFill);
        final p3 = Path()
          ..moveTo(12.000 * s, 3.800 * s)
          ..lineTo(18.800 * s, 7.800 * s)
          ..lineTo(18.800 * s, 16.200 * s)
          ..lineTo(12.000 * s, 20.200 * s)
          ..lineTo(5.200 * s, 16.200 * s)
          ..lineTo(5.200 * s, 7.800 * s)
          ..lineTo(12.000 * s, 3.800 * s)
          ..close();
        canvas.drawPath(p3, primaryStroke);
        final p4 = Path()
          ..moveTo(12.000 * s, 9.500 * s)
          ..lineTo(12.000 * s, 14.500 * s);
        canvas.drawPath(p4, cutoutStroke);
        final p5 = Path()
          ..moveTo(9.800 * s, 11.000 * s)
          ..lineTo(12.000 * s, 12.500 * s)
          ..lineTo(14.200 * s, 11.000 * s);
        canvas.drawPath(p5, cutoutStroke);
        break;
      case AppIconType.apiKey:
        final p1 = Path()
          ..moveTo(12.000 * s, 11.500 * s)
          ..cubicTo(14.800 * s, 11.500 * s, 17.000 * s, 13.800 * s, 17.000 * s, 16.500 * s)
          ..cubicTo(17.000 * s, 19.000 * s, 14.800 * s, 20.500 * s, 12.000 * s, 20.500 * s)
          ..cubicTo(9.200 * s, 20.500 * s, 7.000 * s, 19.000 * s, 7.000 * s, 16.500 * s)
          ..cubicTo(7.000 * s, 13.800 * s, 9.200 * s, 11.500 * s, 12.000 * s, 11.500 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(12.000 * s, 13.500 * s)
          ..cubicTo(13.800 * s, 13.500 * s, 15.200 * s, 14.800 * s, 15.200 * s, 16.800 * s)
          ..cubicTo(15.200 * s, 18.500 * s, 13.800 * s, 19.800 * s, 12.000 * s, 19.800 * s)
          ..cubicTo(10.200 * s, 19.800 * s, 8.800 * s, 18.500 * s, 8.800 * s, 16.800 * s)
          ..cubicTo(8.800 * s, 14.800 * s, 10.200 * s, 13.500 * s, 12.000 * s, 13.500 * s)
          ..close();
        canvas.drawPath(p2, solidFill);
        final p3 = Path()
          ..moveTo(10.000 * s, 13.500 * s)
          ..cubicTo(8.500 * s, 11.000 * s, 5.500 * s, 9.500 * s, 5.000 * s, 5.500 * s);
        canvas.drawPath(p3, primaryStroke);
        final p4 = Path()
          ..moveTo(7.200 * s, 9.800 * s)
          ..lineTo(4.500 * s, 8.500 * s);
        canvas.drawPath(p4, primaryStroke);
        final p5 = Path()
          ..moveTo(8.500 * s, 11.200 * s)
          ..lineTo(8.200 * s, 7.500 * s);
        canvas.drawPath(p5, primaryStroke);
        final p6 = Path()
          ..moveTo(14.000 * s, 13.500 * s)
          ..cubicTo(15.500 * s, 11.000 * s, 18.500 * s, 9.500 * s, 19.000 * s, 5.500 * s);
        canvas.drawPath(p6, primaryStroke);
        final p7 = Path()
          ..moveTo(16.800 * s, 9.800 * s)
          ..lineTo(19.500 * s, 8.500 * s);
        canvas.drawPath(p7, primaryStroke);
        final p8 = Path()
          ..moveTo(15.500 * s, 11.200 * s)
          ..lineTo(15.800 * s, 7.500 * s);
        canvas.drawPath(p8, primaryStroke);
        final p9 = Path()
          ..moveTo(12.000 * s, 15.500 * s)
          ..lineTo(12.000 * s, 17.800 * s);
        canvas.drawPath(p9, cutoutStroke);
        break;
      case AppIconType.help:
        final p1 = Path()
          ..moveTo(6.500 * s, 9.500 * s)
          ..cubicTo(6.500 * s, 6.000 * s, 9.000 * s, 4.500 * s, 12.000 * s, 4.500 * s)
          ..cubicTo(15.000 * s, 4.500 * s, 17.500 * s, 6.000 * s, 17.500 * s, 9.500 * s)
          ..lineTo(17.500 * s, 16.500 * s)
          ..cubicTo(17.500 * s, 19.000 * s, 15.000 * s, 20.500 * s, 12.000 * s, 20.500 * s)
          ..cubicTo(9.000 * s, 20.500 * s, 6.500 * s, 19.000 * s, 6.500 * s, 16.500 * s)
          ..lineTo(6.500 * s, 9.500 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(8.000 * s, 14.000 * s)
          ..cubicTo(8.000 * s, 11.800 * s, 9.800 * s, 10.500 * s, 12.000 * s, 10.500 * s)
          ..cubicTo(14.200 * s, 10.500 * s, 16.000 * s, 11.800 * s, 16.000 * s, 14.000 * s)
          ..lineTo(16.000 * s, 16.800 * s)
          ..cubicTo(16.000 * s, 18.500 * s, 14.200 * s, 19.800 * s, 12.000 * s, 19.800 * s)
          ..cubicTo(9.800 * s, 19.800 * s, 8.000 * s, 18.500 * s, 8.000 * s, 16.800 * s)
          ..lineTo(8.000 * s, 14.000 * s)
          ..close();
        canvas.drawPath(p2, solidFill);
        final p3 = Path()
          ..moveTo(6.800 * s, 5.500 * s)
          ..lineTo(9.200 * s, 7.200 * s);
        canvas.drawPath(p3, primaryStroke);
        final p4 = Path()
          ..moveTo(17.200 * s, 5.500 * s)
          ..lineTo(14.800 * s, 7.200 * s);
        canvas.drawPath(p4, primaryStroke);
        final p5 = Path()
          ..moveTo(9.500 * s, 9.500 * s)
          ..lineTo(9.600 * s, 9.500 * s);
        canvas.drawPath(p5, primaryStroke);
        final p6 = Path()
          ..moveTo(14.500 * s, 9.500 * s)
          ..lineTo(14.600 * s, 9.500 * s);
        canvas.drawPath(p6, primaryStroke);
        final p7 = Path()
          ..moveTo(12.000 * s, 11.200 * s)
          ..lineTo(11.200 * s, 12.500 * s)
          ..lineTo(12.800 * s, 12.500 * s)
          ..lineTo(12.000 * s, 11.200 * s)
          ..close();
        canvas.drawPath(p7, cutoutStroke);
        final p8 = Path()
          ..moveTo(10.200 * s, 15.500 * s)
          ..cubicTo(11.200 * s, 16.200 * s, 12.800 * s, 16.200 * s, 13.800 * s, 15.500 * s);
        canvas.drawPath(p8, cutoutStroke);
        break;
      case AppIconType.coffee:
        final p1 = Path()
          ..moveTo(5.500 * s, 9.500 * s)
          ..lineTo(16.500 * s, 9.500 * s)
          ..lineTo(16.500 * s, 14.500 * s)
          ..cubicTo(16.500 * s, 17.800 * s, 14.000 * s, 20.000 * s, 11.000 * s, 20.000 * s)
          ..cubicTo(8.000 * s, 20.000 * s, 5.500 * s, 17.800 * s, 5.500 * s, 14.500 * s)
          ..lineTo(5.500 * s, 9.500 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(7.000 * s, 11.500 * s)
          ..lineTo(15.000 * s, 11.500 * s)
          ..lineTo(15.000 * s, 14.500 * s)
          ..cubicTo(15.000 * s, 16.800 * s, 13.200 * s, 18.500 * s, 11.000 * s, 18.500 * s)
          ..cubicTo(8.800 * s, 18.500 * s, 7.000 * s, 16.800 * s, 7.000 * s, 14.500 * s)
          ..lineTo(7.000 * s, 11.500 * s)
          ..close();
        canvas.drawPath(p2, solidFill);
        final p3 = Path()
          ..moveTo(11.000 * s, 4.000 * s)
          ..cubicTo(13.200 * s, 4.000 * s, 14.500 * s, 5.800 * s, 13.500 * s, 8.000 * s)
          ..cubicTo(11.500 * s, 8.000 * s, 10.000 * s, 6.200 * s, 11.000 * s, 4.000 * s)
          ..close();
        canvas.drawPath(p3, solidFill);
        final p4 = Path()
          ..moveTo(16.500 * s, 10.800 * s)
          ..lineTo(18.000 * s, 10.800 * s)
          ..cubicTo(19.200 * s, 10.800 * s, 20.000 * s, 11.800 * s, 20.000 * s, 13.000 * s)
          ..cubicTo(20.000 * s, 14.200 * s, 19.200 * s, 15.200 * s, 18.000 * s, 15.200 * s)
          ..lineTo(16.500 * s, 15.200 * s);
        canvas.drawPath(p4, primaryStroke);
        final p5 = Path()
          ..moveTo(5.500 * s, 9.500 * s)
          ..lineTo(16.500 * s, 9.500 * s);
        canvas.drawPath(p5, primaryStroke);
        final p6 = Path()
          ..moveTo(9.500 * s, 14.500 * s)
          ..cubicTo(10.500 * s, 15.200 * s, 11.500 * s, 15.200 * s, 12.500 * s, 14.500 * s);
        canvas.drawPath(p6, cutoutStroke);
        break;
      case AppIconType.play:
        final p1 = Path()
          ..moveTo(6.500 * s, 5.500 * s)
          ..lineTo(18.500 * s, 12.000 * s)
          ..lineTo(6.500 * s, 18.500 * s)
          ..lineTo(6.500 * s, 5.500 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(8.500 * s, 7.800 * s)
          ..lineTo(16.500 * s, 12.000 * s)
          ..lineTo(8.500 * s, 16.200 * s)
          ..lineTo(8.500 * s, 7.800 * s)
          ..close();
        canvas.drawPath(p2, solidFill);
        final p3 = Path()
          ..moveTo(10.000 * s, 12.000 * s)
          ..lineTo(13.500 * s, 12.000 * s);
        canvas.drawPath(p3, cutoutStroke);
        break;
      case AppIconType.pause:
        final p1 = Path()
          ..moveTo(6.500 * s, 5.500 * s)
          ..lineTo(10.500 * s, 5.500 * s)
          ..lineTo(10.500 * s, 18.500 * s)
          ..lineTo(6.500 * s, 18.500 * s)
          ..lineTo(6.500 * s, 5.500 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(13.500 * s, 5.500 * s)
          ..lineTo(17.500 * s, 5.500 * s)
          ..lineTo(17.500 * s, 18.500 * s)
          ..lineTo(13.500 * s, 18.500 * s)
          ..lineTo(13.500 * s, 5.500 * s)
          ..close();
        canvas.drawPath(p2, softFill);
        final p3 = Path()
          ..moveTo(7.500 * s, 6.500 * s)
          ..lineTo(9.500 * s, 6.500 * s)
          ..lineTo(9.500 * s, 17.500 * s)
          ..lineTo(7.500 * s, 17.500 * s)
          ..lineTo(7.500 * s, 6.500 * s)
          ..close();
        canvas.drawPath(p3, solidFill);
        final p4 = Path()
          ..moveTo(14.500 * s, 6.500 * s)
          ..lineTo(16.500 * s, 6.500 * s)
          ..lineTo(16.500 * s, 17.500 * s)
          ..lineTo(14.500 * s, 17.500 * s)
          ..lineTo(14.500 * s, 6.500 * s)
          ..close();
        canvas.drawPath(p4, solidFill);
        final p5 = Path()
          ..moveTo(7.200 * s, 12.000 * s)
          ..lineTo(9.800 * s, 12.000 * s);
        canvas.drawPath(p5, cutoutStroke);
        final p6 = Path()
          ..moveTo(14.200 * s, 12.000 * s)
          ..lineTo(16.800 * s, 12.000 * s);
        canvas.drawPath(p6, cutoutStroke);
        break;
      case AppIconType.menu:
        final p1 = Path()
          ..moveTo(6.000 * s, 7.500 * s)
          ..cubicTo(8.500 * s, 5.500 * s, 12.500 * s, 5.500 * s, 15.000 * s, 7.500 * s)
          ..cubicTo(12.500 * s, 9.200 * s, 8.500 * s, 9.200 * s, 6.000 * s, 7.500 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(9.000 * s, 16.500 * s)
          ..cubicTo(11.500 * s, 14.800 * s, 15.500 * s, 14.800 * s, 18.000 * s, 16.500 * s)
          ..cubicTo(15.500 * s, 18.200 * s, 11.500 * s, 18.200 * s, 9.000 * s, 16.500 * s)
          ..close();
        canvas.drawPath(p2, softFill);
        final p3 = Path()
          ..moveTo(5.000 * s, 7.500 * s)
          ..lineTo(19.000 * s, 7.500 * s);
        canvas.drawPath(p3, primaryStroke);
        final p4 = Path()
          ..moveTo(7.500 * s, 12.000 * s)
          ..lineTo(19.000 * s, 12.000 * s);
        canvas.drawPath(p4, primaryStroke);
        final p5 = Path()
          ..moveTo(5.000 * s, 16.500 * s)
          ..lineTo(16.500 * s, 16.500 * s);
        canvas.drawPath(p5, primaryStroke);
        break;
      case AppIconType.settings:
        final p1 = Path()
          ..moveTo(12.000 * s, 4.500 * s)
          ..cubicTo(16.100 * s, 4.500 * s, 19.500 * s, 7.900 * s, 19.500 * s, 12.000 * s)
          ..cubicTo(19.500 * s, 16.100 * s, 16.100 * s, 19.500 * s, 12.000 * s, 19.500 * s)
          ..cubicTo(7.900 * s, 19.500 * s, 4.500 * s, 16.100 * s, 4.500 * s, 12.000 * s)
          ..cubicTo(4.500 * s, 7.900 * s, 7.900 * s, 4.500 * s, 12.000 * s, 4.500 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(12.000 * s, 7.500 * s)
          ..cubicTo(14.500 * s, 7.500 * s, 16.500 * s, 9.500 * s, 16.500 * s, 12.000 * s)
          ..cubicTo(16.500 * s, 14.500 * s, 14.500 * s, 16.500 * s, 12.000 * s, 16.500 * s)
          ..cubicTo(9.500 * s, 16.500 * s, 7.500 * s, 14.500 * s, 7.500 * s, 12.000 * s)
          ..cubicTo(7.500 * s, 9.500 * s, 9.500 * s, 7.500 * s, 12.000 * s, 7.500 * s)
          ..close();
        canvas.drawPath(p2, solidFill);
        final p3 = Path()
          ..moveTo(12.000 * s, 3.500 * s)
          ..lineTo(12.000 * s, 5.500 * s);
        canvas.drawPath(p3, primaryStroke);
        final p4 = Path()
          ..moveTo(12.000 * s, 18.500 * s)
          ..lineTo(12.000 * s, 20.500 * s);
        canvas.drawPath(p4, primaryStroke);
        final p5 = Path()
          ..moveTo(3.500 * s, 12.000 * s)
          ..lineTo(5.500 * s, 12.000 * s);
        canvas.drawPath(p5, primaryStroke);
        final p6 = Path()
          ..moveTo(18.500 * s, 12.000 * s)
          ..lineTo(20.500 * s, 12.000 * s);
        canvas.drawPath(p6, primaryStroke);
        final p7 = Path()
          ..moveTo(6.000 * s, 6.000 * s)
          ..lineTo(7.500 * s, 7.500 * s);
        canvas.drawPath(p7, primaryStroke);
        final p8 = Path()
          ..moveTo(16.500 * s, 16.500 * s)
          ..lineTo(18.000 * s, 18.000 * s);
        canvas.drawPath(p8, primaryStroke);
        final p9 = Path()
          ..moveTo(18.000 * s, 6.000 * s)
          ..lineTo(16.500 * s, 7.500 * s);
        canvas.drawPath(p9, primaryStroke);
        final p10 = Path()
          ..moveTo(7.500 * s, 16.500 * s)
          ..lineTo(6.000 * s, 18.000 * s);
        canvas.drawPath(p10, primaryStroke);
        final p11 = Path()
          ..moveTo(12.000 * s, 10.200 * s)
          ..cubicTo(13.000 * s, 10.200 * s, 13.800 * s, 11.000 * s, 13.800 * s, 12.000 * s)
          ..cubicTo(13.800 * s, 13.000 * s, 13.000 * s, 13.800 * s, 12.000 * s, 13.800 * s)
          ..cubicTo(11.000 * s, 13.800 * s, 10.200 * s, 13.000 * s, 10.200 * s, 12.000 * s)
          ..cubicTo(10.200 * s, 11.000 * s, 11.000 * s, 10.200 * s, 12.000 * s, 10.200 * s)
          ..close();
        canvas.drawPath(p11, cutoutStroke);
        break;
      case AppIconType.upload:
        final p1 = Path()
          ..moveTo(6.500 * s, 13.500 * s)
          ..cubicTo(6.500 * s, 9.500 * s, 9.000 * s, 6.500 * s, 12.000 * s, 6.500 * s)
          ..cubicTo(15.000 * s, 6.500 * s, 17.500 * s, 9.500 * s, 17.500 * s, 13.500 * s)
          ..lineTo(6.500 * s, 13.500 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(12.000 * s, 16.500 * s)
          ..lineTo(12.000 * s, 6.500 * s);
        canvas.drawPath(p2, primaryStroke);
        final p3 = Path()
          ..moveTo(8.200 * s, 10.200 * s)
          ..lineTo(12.000 * s, 6.500 * s)
          ..lineTo(15.800 * s, 10.200 * s);
        canvas.drawPath(p3, primaryStroke);
        final p4 = Path()
          ..moveTo(6.000 * s, 19.200 * s)
          ..lineTo(18.000 * s, 19.200 * s);
        canvas.drawPath(p4, primaryStroke);
        break;
      case AppIconType.download:
        final p1 = Path()
          ..moveTo(6.500 * s, 9.500 * s)
          ..cubicTo(6.500 * s, 13.500 * s, 9.000 * s, 16.500 * s, 12.000 * s, 16.500 * s)
          ..cubicTo(15.000 * s, 16.500 * s, 17.500 * s, 13.500 * s, 17.500 * s, 9.500 * s)
          ..lineTo(6.500 * s, 9.500 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(12.000 * s, 6.500 * s)
          ..lineTo(12.000 * s, 16.500 * s);
        canvas.drawPath(p2, primaryStroke);
        final p3 = Path()
          ..moveTo(8.200 * s, 12.800 * s)
          ..lineTo(12.000 * s, 16.500 * s)
          ..lineTo(15.800 * s, 12.800 * s);
        canvas.drawPath(p3, primaryStroke);
        final p4 = Path()
          ..moveTo(6.000 * s, 19.200 * s)
          ..lineTo(18.000 * s, 19.200 * s);
        canvas.drawPath(p4, primaryStroke);
        break;
      case AppIconType.close:
        final p1 = Path()
          ..moveTo(12.000 * s, 6.500 * s)
          ..cubicTo(15.000 * s, 6.500 * s, 17.500 * s, 9.000 * s, 17.500 * s, 12.000 * s)
          ..cubicTo(17.500 * s, 15.000 * s, 15.000 * s, 17.500 * s, 12.000 * s, 17.500 * s)
          ..cubicTo(9.000 * s, 17.500 * s, 6.500 * s, 15.000 * s, 6.500 * s, 12.000 * s)
          ..cubicTo(6.500 * s, 9.000 * s, 9.000 * s, 6.500 * s, 12.000 * s, 6.500 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(8.000 * s, 8.000 * s)
          ..lineTo(16.000 * s, 16.000 * s);
        canvas.drawPath(p2, primaryStroke);
        final p3 = Path()
          ..moveTo(16.000 * s, 8.000 * s)
          ..lineTo(8.000 * s, 16.000 * s);
        canvas.drawPath(p3, primaryStroke);
        break;
      case AppIconType.chevronRight:
        final p1 = Path()
          ..moveTo(8.500 * s, 7.500 * s)
          ..lineTo(14.500 * s, 12.000 * s)
          ..lineTo(8.500 * s, 16.500 * s)
          ..lineTo(8.500 * s, 7.500 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(9.500 * s, 6.500 * s)
          ..lineTo(15.000 * s, 12.000 * s)
          ..lineTo(9.500 * s, 17.500 * s);
        canvas.drawPath(p2, primaryStroke);
        break;
      case AppIconType.brandLogo:
        final p1 = Path()
          ..moveTo(12.000 * s, 13.500 * s)
          ..cubicTo(12.000 * s, 8.800 * s, 15.800 * s, 5.200 * s, 20.500 * s, 5.200 * s)
          ..cubicTo(20.500 * s, 9.800 * s, 17.200 * s, 13.500 * s, 12.000 * s, 13.500 * s)
          ..close();
        canvas.drawPath(p1, softFill);
        final p2 = Path()
          ..moveTo(5.000 * s, 19.500 * s)
          ..cubicTo(8.500 * s, 17.800 * s, 15.500 * s, 17.800 * s, 19.000 * s, 19.500 * s)
          ..cubicTo(15.500 * s, 21.000 * s, 8.500 * s, 21.000 * s, 5.000 * s, 19.500 * s)
          ..close();
        canvas.drawPath(p2, softFill);
        final p3 = Path()
          ..moveTo(12.000 * s, 15.000 * s)
          ..cubicTo(12.000 * s, 9.500 * s, 7.800 * s, 5.200 * s, 3.200 * s, 5.200 * s)
          ..cubicTo(3.200 * s, 10.500 * s, 7.000 * s, 15.000 * s, 12.000 * s, 15.000 * s)
          ..close();
        canvas.drawPath(p3, solidFill);
        final p4 = Path()
          ..moveTo(12.000 * s, 20.000 * s)
          ..lineTo(12.000 * s, 9.500 * s);
        canvas.drawPath(p4, primaryStroke);
        final p5 = Path()
          ..moveTo(6.500 * s, 19.500 * s)
          ..cubicTo(9.500 * s, 18.500 * s, 14.500 * s, 18.500 * s, 17.500 * s, 19.500 * s);
        canvas.drawPath(p5, primaryStroke);
        final p6 = Path()
          ..moveTo(6.200 * s, 8.200 * s)
          ..cubicTo(8.200 * s, 9.800 * s, 10.000 * s, 11.800 * s, 11.200 * s, 14.200 * s);
        canvas.drawPath(p6, cutoutStroke);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _TonalBotanicalPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.overrideColor != overrideColor;
  }
}
