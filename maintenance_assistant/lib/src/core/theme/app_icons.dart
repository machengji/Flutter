import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 自定义 SVG 图标组件
/// 
/// 使用 CustomPaint 渲染 SVG 路径，支持颜色和尺寸自定义
class AppIcon extends StatelessWidget {
  /// 图标类型
  final AppIconType type;
  
  /// 图标尺寸
  final double size;
  
  /// 图标颜色
  final Color? color;

  const AppIcon({
    super.key,
    required this.type,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).iconTheme.color ?? Colors.black;
    
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _IconPainter(
          type: type,
          color: iconColor,
        ),
      ),
    );
  }
}

/// 图标类型枚举
enum AppIconType {
  plan,
  habit,
  anchor,
  add,
  analytics,
  settings,
  notification,
  notificationOutlined,
  edit,
  delete,
  pin,
  check,
  refresh,
  play,
  pause,
  menu,
  close,
  chevronRight,
  data,
  explore,
  upload,
  download,
  apiKey,
  help,
}

/// 图标绘制器
class _IconPainter extends CustomPainter {
  final AppIconType type;
  final Color color;

  _IconPainter({
    required this.type,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final scale = size.width / 24;
    canvas.scale(scale);

    switch (type) {
      case AppIconType.plan:
        _drawPlan(canvas, paint);
        break;
      case AppIconType.habit:
        _drawHabit(canvas, paint);
        break;
      case AppIconType.anchor:
        _drawAnchor(canvas, paint);
        break;
      case AppIconType.add:
        _drawAdd(canvas, paint);
        break;
      case AppIconType.analytics:
        _drawAnalytics(canvas, paint, fillPaint);
        break;
      case AppIconType.settings:
        _drawSettings(canvas, paint);
        break;
      case AppIconType.notification:
        _drawNotification(canvas, paint, fillPaint, hasIndicator: true);
        break;
      case AppIconType.notificationOutlined:
        _drawNotification(canvas, paint, fillPaint, hasIndicator: false);
        break;
      case AppIconType.edit:
        _drawEdit(canvas, paint);
        break;
      case AppIconType.delete:
        _drawDelete(canvas, paint);
        break;
      case AppIconType.pin:
        _drawPin(canvas, paint);
        break;
      case AppIconType.check:
        _drawCheck(canvas, paint);
        break;
      case AppIconType.refresh:
        _drawRefresh(canvas, paint);
        break;
      case AppIconType.play:
        _drawPlay(canvas, fillPaint);
        break;
      case AppIconType.pause:
        _drawPause(canvas, fillPaint);
        break;
      case AppIconType.menu:
        _drawMenu(canvas, paint);
        break;
      case AppIconType.close:
        _drawClose(canvas, paint);
        break;
      case AppIconType.chevronRight:
        _drawChevronRight(canvas, paint);
        break;
      case AppIconType.data:
        _drawData(canvas, paint);
        break;
      case AppIconType.explore:
        _drawExplore(canvas, paint);
        break;
      case AppIconType.upload:
        _drawUpload(canvas, paint);
        break;
      case AppIconType.download:
        _drawDownload(canvas, paint);
        break;
      case AppIconType.apiKey:
        _drawApiKey(canvas, paint, fillPaint);
        break;
      case AppIconType.help:
        _drawHelp(canvas, paint, fillPaint);
        break;
    }
  }

  void _drawPlan(Canvas canvas, Paint paint) {
    final path = Path()
      ..moveTo(9, 11)
      ..lineTo(12, 14)
      ..lineTo(22, 4);
    canvas.drawPath(path, paint);

    final boxPath = Path()
      ..moveTo(21, 12)
      ..lineTo(21, 19)
      ..quadraticBezierTo(21, 21, 19, 21)
      ..lineTo(5, 21)
      ..quadraticBezierTo(3, 21, 3, 19)
      ..lineTo(3, 5)
      ..quadraticBezierTo(3, 3, 5, 3)
      ..lineTo(16, 3);
    canvas.drawPath(boxPath, paint);
  }

  void _drawHabit(Canvas canvas, Paint paint) {
    canvas.drawCircle(const Offset(12, 12), 10, paint);
    final path = Path()
      ..moveTo(12, 6)
      ..lineTo(12, 12)
      ..lineTo(16, 14);
    canvas.drawPath(path, paint);
  }

  void _drawAnchor(Canvas canvas, Paint paint) {
    canvas.drawLine(const Offset(12, 2), const Offset(12, 6), paint);
    canvas.drawLine(const Offset(12, 18), const Offset(12, 22), paint);
    canvas.drawCircle(const Offset(12, 12), 4, paint);
  }

  void _drawAdd(Canvas canvas, Paint paint) {
    canvas.drawCircle(const Offset(12, 12), 10, paint);
    canvas.drawLine(const Offset(12, 8), const Offset(12, 16), paint);
    canvas.drawLine(const Offset(8, 12), const Offset(16, 12), paint);
  }

  void _drawAnalytics(Canvas canvas, Paint paint, Paint fillPaint) {
    canvas.drawLine(const Offset(18, 20), const Offset(18, 10), paint);
    canvas.drawLine(const Offset(12, 20), const Offset(12, 4), paint);
    canvas.drawLine(const Offset(6, 20), const Offset(6, 14), paint);
    
    fillPaint.color = fillPaint.color.withOpacity(0.3);
    canvas.drawCircle(const Offset(18, 7), 2, fillPaint);
    canvas.drawCircle(const Offset(6, 11), 2, fillPaint);
  }

  void _drawSettings(Canvas canvas, Paint paint) {
    canvas.drawCircle(const Offset(12, 12), 3, paint);
    // 简化的齿轮效果
    for (int i = 0; i < 4; i++) {
      final angle = i * 3.14159 / 2;
      final start = Offset(12 + 5 * _cos(angle), 12 + 5 * _sin(angle));
      final end = Offset(12 + 8 * _cos(angle), 12 + 8 * _sin(angle));
      canvas.drawLine(start, end, paint);
    }
  }

  double _cos(double angle) => angle == 0 ? 1 : (angle == 1.5707963267948966 ? 0 : (angle == 3.141592653589793 ? -1 : 0));
  double _sin(double angle) => angle == 0 ? 0 : (angle == 1.5707963267948966 ? 1 : (angle == 3.141592653589793 ? 0 : -1));

  void _drawNotification(Canvas canvas, Paint paint, Paint fillPaint, {required bool hasIndicator}) {
    final path = Path()
      ..moveTo(18, 8)
      ..quadraticBezierTo(18, 4, 12, 2)
      ..quadraticBezierTo(6, 4, 6, 8)
      ..lineTo(6, 15)
      ..lineTo(3, 17)
      ..lineTo(21, 17)
      ..lineTo(18, 15)
      ..close();
    canvas.drawPath(path, paint);

    final bellPath = Path()
      ..moveTo(10.27, 21)
      ..quadraticBezierTo(12, 22, 13.73, 21);
    canvas.drawPath(bellPath, paint);

    if (hasIndicator) {
      fillPaint.color = const Color(0xFFE74C3C);
      canvas.drawCircle(const Offset(18, 5), 3, fillPaint);
    }
  }

  void _drawEdit(Canvas canvas, Paint paint) {
    final boxPath = Path()
      ..moveTo(11, 4)
      ..lineTo(4, 4)
      ..quadraticBezierTo(2, 4, 2, 6)
      ..lineTo(2, 20)
      ..quadraticBezierTo(2, 22, 4, 22)
      ..lineTo(18, 22)
      ..quadraticBezierTo(20, 22, 20, 20)
      ..lineTo(20, 13);
    canvas.drawPath(boxPath, paint);

    final pencilPath = Path()
      ..moveTo(18.5, 2.5)
      ..quadraticBezierTo(22, 2, 21.5, 5.5)
      ..lineTo(12, 15)
      ..lineTo(8, 16)
      ..lineTo(9, 12)
      ..close();
    canvas.drawPath(pencilPath, paint);
  }

  void _drawDelete(Canvas canvas, Paint paint) {
    canvas.drawLine(const Offset(3, 6), const Offset(21, 6), paint);
    
    final path = Path()
      ..moveTo(8, 6)
      ..lineTo(8, 4)
      ..quadraticBezierTo(8, 2, 10, 2)
      ..lineTo(14, 2)
      ..quadraticBezierTo(16, 2, 16, 4)
      ..lineTo(16, 6);
    canvas.drawPath(path, paint);

    final binPath = Path()
      ..moveTo(19, 6)
      ..lineTo(19, 20)
      ..quadraticBezierTo(19, 22, 17, 22)
      ..lineTo(7, 22)
      ..quadraticBezierTo(5, 22, 5, 20)
      ..lineTo(5, 6);
    canvas.drawPath(binPath, paint);

    canvas.drawLine(const Offset(10, 11), const Offset(10, 17), paint);
    canvas.drawLine(const Offset(14, 11), const Offset(14, 17), paint);
  }

  void _drawPin(Canvas canvas, Paint paint) {
    final path = Path()
      ..moveTo(12, 2)
      ..lineTo(15.09, 8.26)
      ..lineTo(22, 9.27)
      ..lineTo(17, 14.14)
      ..lineTo(18.18, 21.02)
      ..lineTo(12, 17.77)
      ..lineTo(5.82, 21.02)
      ..lineTo(7, 14.14)
      ..lineTo(2, 9.27)
      ..lineTo(8.91, 8.26)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawCheck(Canvas canvas, Paint paint) {
    paint.strokeWidth = 2.5;
    final path = Path()
      ..moveTo(20, 6)
      ..lineTo(9, 17)
      ..lineTo(4, 12);
    canvas.drawPath(path, paint);
  }

  void _drawRefresh(Canvas canvas, Paint paint) {
    final path = Path()
      ..moveTo(1, 4)
      ..lineTo(1, 10)
      ..lineTo(7, 10);
    canvas.drawPath(path, paint);

    final arcPath = Path()
      ..moveTo(3.51, 15)
      ..quadraticBezierTo(6, 21, 12.5, 21)
      ..quadraticBezierTo(21, 21, 21, 12)
      ..quadraticBezierTo(21, 3, 12, 3)
      ..quadraticBezierTo(6, 3, 5.64, 5.51);
    canvas.drawPath(arcPath, paint);
  }

  void _drawPlay(Canvas canvas, Paint fillPaint) {
    final path = Path()
      ..moveTo(5, 3)
      ..lineTo(19, 12)
      ..lineTo(5, 21)
      ..close();
    canvas.drawPath(path, fillPaint);
  }

  void _drawPause(Canvas canvas, Paint fillPaint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(6, 4, 4, 16), const Radius.circular(1)),
      fillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(14, 4, 4, 16), const Radius.circular(1)),
      fillPaint,
    );
  }

  void _drawMenu(Canvas canvas, Paint paint) {
    canvas.drawLine(const Offset(3, 6), const Offset(21, 6), paint);
    canvas.drawLine(const Offset(3, 12), const Offset(21, 12), paint);
    canvas.drawLine(const Offset(3, 18), const Offset(21, 18), paint);
  }

  void _drawClose(Canvas canvas, Paint paint) {
    canvas.drawLine(const Offset(18, 6), const Offset(6, 18), paint);
    canvas.drawLine(const Offset(6, 6), const Offset(18, 18), paint);
  }

  void _drawChevronRight(Canvas canvas, Paint paint) {
    final path = Path()
      ..moveTo(9, 18)
      ..lineTo(15, 12)
      ..lineTo(9, 6);
    canvas.drawPath(path, paint);
  }

  void _drawData(Canvas canvas, Paint paint) {
    // 四角
    final corners = [
      [4.0, 4.0], [4.0, 8.0], [8.0, 4.0],
      [4.0, 16.0], [4.0, 20.0], [8.0, 20.0],
      [16.0, 20.0], [20.0, 20.0], [20.0, 16.0],
      [20.0, 8.0], [20.0, 4.0], [16.0, 4.0],
    ];
    
    for (int i = 0; i < 12; i += 3) {
      final path = Path()
        ..moveTo(corners[i][0], corners[i][1])
        ..lineTo(corners[i+1][0], corners[i+1][1])
        ..lineTo(corners[i+2][0], corners[i+2][1]);
      canvas.drawPath(path, paint);
    }
    
    canvas.drawLine(const Offset(8, 12), const Offset(16, 12), paint);
    canvas.drawLine(const Offset(12, 8), const Offset(12, 16), paint);
  }

  void _drawExplore(Canvas canvas, Paint paint) {
    canvas.drawCircle(const Offset(11, 11), 8, paint);
    canvas.drawLine(const Offset(21, 21), const Offset(16.65, 16.65), paint);
    
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;
    paint.color = paint.color.withOpacity(0.4);
    canvas.drawCircle(const Offset(11, 11), 3, paint);
  }

  void _drawUpload(Canvas canvas, Paint paint) {
    final boxPath = Path()
      ..moveTo(21, 15)
      ..lineTo(21, 19)
      ..quadraticBezierTo(21, 21, 19, 21)
      ..lineTo(5, 21)
      ..quadraticBezierTo(3, 21, 3, 19)
      ..lineTo(3, 15);
    canvas.drawPath(boxPath, paint);

    final arrowPath = Path()
      ..moveTo(17, 8)
      ..lineTo(12, 3)
      ..lineTo(7, 8);
    canvas.drawPath(arrowPath, paint);
    canvas.drawLine(const Offset(12, 3), const Offset(12, 15), paint);
  }

  void _drawDownload(Canvas canvas, Paint paint) {
    final boxPath = Path()
      ..moveTo(21, 15)
      ..lineTo(21, 19)
      ..quadraticBezierTo(21, 21, 19, 21)
      ..lineTo(5, 21)
      ..quadraticBezierTo(3, 21, 3, 19)
      ..lineTo(3, 15);
    canvas.drawPath(boxPath, paint);

    final arrowPath = Path()
      ..moveTo(7, 10)
      ..lineTo(12, 15)
      ..lineTo(17, 10);
    canvas.drawPath(arrowPath, paint);
    canvas.drawLine(const Offset(12, 15), const Offset(12, 3), paint);
  }

  void _drawApiKey(Canvas canvas, Paint paint, Paint fillPaint) {
    final keyPath = Path()
      ..moveTo(21, 2)
      ..lineTo(15, 8)
      ..lineTo(18, 8)
      ..quadraticBezierTo(18, 12, 14, 17)
      ..quadraticBezierTo(10, 21, 5.5, 20.5)
      ..quadraticBezierTo(6.5, 17, 10, 14.5)
      ..quadraticBezierTo(5, 14.5, 5.5, 10)
      ..lineTo(2, 10)
      ..lineTo(8, 2);
    canvas.drawPath(keyPath, paint);
    
    fillPaint.color = fillPaint.color.withOpacity(0.3);
    canvas.drawCircle(const Offset(17, 7), 2, fillPaint);
  }

  void _drawHelp(Canvas canvas, Paint paint, Paint fillPaint) {
    // 问号圆圈
    canvas.drawCircle(const Offset(12, 12), 10, paint);
    
    // 问号
    final questionPath = Path()
      ..moveTo(9, 9)
      ..quadraticBezierTo(9, 5, 12, 5)
      ..quadraticBezierTo(16, 5, 16, 9)
      ..quadraticBezierTo(16, 11, 13, 12)
      ..lineTo(12, 13)
      ..lineTo(12, 15);
    canvas.drawPath(questionPath, paint);
    
    // 句号
    fillPaint.color = paint.color;
    canvas.drawCircle(const Offset(12, 18), 1.2, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _IconPainter oldDelegate) {
    return type != oldDelegate.type || color != oldDelegate.color;
  }
}
