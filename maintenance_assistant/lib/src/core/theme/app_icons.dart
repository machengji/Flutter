import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 自定义双色调（Duotone）圆润矢量图标组件
///
/// 采用「柔和半透明高光填充 + 圆润饱满线条」的设计语言，适配 iOS 精致视觉风格
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
    final iconColor =
        color ?? Theme.of(context).iconTheme.color ?? Colors.black;

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
  coffee,
  brandLogo,
}

/// 双色调矢量图标绘制器
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
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final duotonePaint = Paint()
      ..color = color.withOpacity(0.18)
      ..style = PaintingStyle.fill;

    final scale = size.width / 24;
    canvas.scale(scale);

    switch (type) {
      case AppIconType.plan:
        _drawPlan(canvas, paint, duotonePaint);
        break;
      case AppIconType.habit:
        _drawHabit(canvas, paint, duotonePaint);
        break;
      case AppIconType.anchor:
        _drawAnchor(canvas, paint, duotonePaint);
        break;
      case AppIconType.add:
        _drawAdd(canvas, paint, duotonePaint);
        break;
      case AppIconType.analytics:
        _drawAnalytics(canvas, paint, fillPaint, duotonePaint);
        break;
      case AppIconType.settings:
        _drawSettings(canvas, paint, duotonePaint);
        break;
      case AppIconType.notification:
        _drawNotification(canvas, paint, fillPaint, duotonePaint,
            hasIndicator: true);
        break;
      case AppIconType.notificationOutlined:
        _drawNotification(canvas, paint, fillPaint, duotonePaint,
            hasIndicator: false);
        break;
      case AppIconType.edit:
        _drawEdit(canvas, paint, duotonePaint);
        break;
      case AppIconType.delete:
        _drawDelete(canvas, paint, duotonePaint);
        break;
      case AppIconType.pin:
        _drawPin(canvas, paint, duotonePaint);
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
        _drawData(canvas, paint, duotonePaint);
        break;
      case AppIconType.explore:
        _drawExplore(canvas, paint, duotonePaint);
        break;
      case AppIconType.upload:
        _drawUpload(canvas, paint, duotonePaint);
        break;
      case AppIconType.download:
        _drawDownload(canvas, paint, duotonePaint);
        break;
      case AppIconType.apiKey:
        _drawApiKey(canvas, paint, fillPaint, duotonePaint);
        break;
      case AppIconType.help:
        _drawHelp(canvas, paint, fillPaint, duotonePaint);
        break;
      case AppIconType.coffee:
        _drawCoffee(canvas, paint, duotonePaint);
        break;
      case AppIconType.brandLogo:
        _drawBrandLogo(canvas, paint, fillPaint);
        break;
    }
  }

  /// 计划图标：圆角卡片底衬 + 灵动完成对勾
  void _drawPlan(Canvas canvas, Paint paint, Paint duotonePaint) {
    final bgRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(3.5, 3.5, 17, 17),
      const Radius.circular(5.5),
    );
    canvas.drawRRect(bgRect, duotonePaint);

    final boxPath = Path()
      ..moveTo(20.5, 12.5)
      ..lineTo(20.5, 16)
      ..quadraticBezierTo(20.5, 20.5, 16, 20.5)
      ..lineTo(8, 20.5)
      ..quadraticBezierTo(3.5, 20.5, 3.5, 16)
      ..lineTo(3.5, 8)
      ..quadraticBezierTo(3.5, 3.5, 8, 3.5)
      ..lineTo(14.5, 3.5);
    canvas.drawPath(boxPath, paint);

    final checkPath = Path()
      ..moveTo(8.5, 12)
      ..lineTo(11.5, 15)
      ..lineTo(20.5, 5.5);
    canvas.drawPath(checkPath, paint);
  }

  /// 习惯图标：双色调圆环时钟 + 顺时针活力弧
  void _drawHabit(Canvas canvas, Paint paint, Paint duotonePaint) {
    canvas.drawCircle(const Offset(12, 12), 8.5, duotonePaint);
    canvas.drawCircle(const Offset(12, 12), 9, paint);

    final handPath = Path()
      ..moveTo(12, 7.2)
      ..lineTo(12, 12)
      ..lineTo(15.5, 14.2);
    canvas.drawPath(handPath, paint);
  }

  /// 锚点图标：精致圆润船锚造型（顶环 + 横梁 + 饱满弧形双锚钩）
  void _drawAnchor(Canvas canvas, Paint paint, Paint duotonePaint) {
    // 柔和中心背景圆
    canvas.drawCircle(const Offset(12, 13), 7.5, duotonePaint);

    // 顶部锚环
    canvas.drawCircle(const Offset(12, 5.2), 2.3, paint);

    // 垂直主干
    canvas.drawLine(const Offset(12, 7.5), const Offset(12, 20.5), paint);

    // 横梁
    canvas.drawLine(const Offset(8.5, 11), const Offset(15.5, 11), paint);

    // 底部弧形锚身
    final arcPath = Path()
      ..moveTo(5, 14)
      ..quadraticBezierTo(5, 20.5, 12, 20.5)
      ..quadraticBezierTo(19, 20.5, 19, 14);
    canvas.drawPath(arcPath, paint);

    // 左右小锚尖
    final leftFluke = Path()
      ..moveTo(3.8, 15.5)
      ..lineTo(5, 13.5)
      ..lineTo(6.8, 15.2);
    canvas.drawPath(leftFluke, paint);

    final rightFluke = Path()
      ..moveTo(17.2, 15.2)
      ..lineTo(19, 13.5)
      ..lineTo(20.2, 15.5);
    canvas.drawPath(rightFluke, paint);
  }

  /// 添加图标：柔和圆底 + 居中加号
  void _drawAdd(Canvas canvas, Paint paint, Paint duotonePaint) {
    canvas.drawCircle(const Offset(12, 12), 9.5, duotonePaint);
    canvas.drawCircle(const Offset(12, 12), 9.5, paint);
    canvas.drawLine(const Offset(12, 8), const Offset(12, 16), paint);
    canvas.drawLine(const Offset(8, 12), const Offset(16, 12), paint);
  }

  /// 数据分析图标：圆角阶梯柱状图 + 跃升趋势曲线
  void _drawAnalytics(
      Canvas canvas, Paint paint, Paint fillPaint, Paint duotonePaint) {
    // 三个圆角柱子（带双色调填充）
    final bar1 = RRect.fromRectAndRadius(
        const Rect.fromLTWH(4, 13.5, 3.6, 6.5), const Radius.circular(1.8));
    final bar2 = RRect.fromRectAndRadius(
        const Rect.fromLTWH(10.2, 9.5, 3.6, 10.5), const Radius.circular(1.8));
    final bar3 = RRect.fromRectAndRadius(
        const Rect.fromLTWH(16.4, 6, 3.6, 14), const Radius.circular(1.8));

    canvas.drawRRect(bar1, duotonePaint);
    canvas.drawRRect(bar2, duotonePaint);
    canvas.drawRRect(bar3, duotonePaint);

    canvas.drawRRect(bar1, paint..strokeWidth = 1.8);
    canvas.drawRRect(bar2, paint);
    canvas.drawRRect(bar3, paint);

    // 顶部上升趋势折线
    final trendPath = Path()
      ..moveTo(5.5, 9.5)
      ..lineTo(10.5, 5.5)
      ..lineTo(13.5, 7)
      ..lineTo(18.5, 3);
    canvas.drawPath(trendPath, paint..strokeWidth = 2.0);
    canvas.drawCircle(const Offset(18.5, 3), 1.6, fillPaint);
  }

  /// 设置图标：圆润八齿齿轮
  void _drawSettings(Canvas canvas, Paint paint, Paint duotonePaint) {
    canvas.drawCircle(const Offset(12, 12), 6.5, duotonePaint);
    canvas.drawCircle(const Offset(12, 12), 3.2, paint);
    canvas.drawCircle(const Offset(12, 12), 7.2, paint);
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final start =
          Offset(12 + 7.2 * math.cos(angle), 12 + 7.2 * math.sin(angle));
      final end =
          Offset(12 + 9.4 * math.cos(angle), 12 + 9.4 * math.sin(angle));
      canvas.drawLine(start, end, paint);
    }
  }

  /// 通知铃铛图标
  void _drawNotification(
      Canvas canvas, Paint paint, Paint fillPaint, Paint duotonePaint,
      {required bool hasIndicator}) {
    final path = Path()
      ..moveTo(18, 9)
      ..cubicTo(18, 5.2, 15.5, 3, 12, 3)
      ..cubicTo(8.5, 3, 6, 5.2, 6, 9)
      ..lineTo(6, 14.2)
      ..quadraticBezierTo(6, 16, 4, 17.2)
      ..lineTo(20, 17.2)
      ..quadraticBezierTo(18, 16, 18, 14.2)
      ..close();
    canvas.drawPath(path, duotonePaint);
    canvas.drawPath(path, paint);

    final bellClapper = Path()
      ..moveTo(9.8, 20)
      ..quadraticBezierTo(12, 21.8, 14.2, 20);
    canvas.drawPath(bellClapper, paint);

    if (hasIndicator) {
      fillPaint.color = const Color(0xFFFF4D4F);
      canvas.drawCircle(const Offset(17.8, 5.2), 3.2, fillPaint);
    }
  }

  /// 编辑图标
  void _drawEdit(Canvas canvas, Paint paint, Paint duotonePaint) {
    final bgRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(3, 4, 16, 17),
      const Radius.circular(4.5),
    );
    canvas.drawRRect(bgRect, duotonePaint);

    final boxPath = Path()
      ..moveTo(11, 4)
      ..lineTo(6.5, 4)
      ..quadraticBezierTo(3, 4, 3, 7.5)
      ..lineTo(3, 17.5)
      ..quadraticBezierTo(3, 21, 6.5, 21)
      ..lineTo(16.5, 21)
      ..quadraticBezierTo(20, 21, 20, 17.5)
      ..lineTo(20, 13);
    canvas.drawPath(boxPath, paint);

    final pencilPath = Path()
      ..moveTo(17.5, 3)
      ..quadraticBezierTo(20.5, 2.5, 21, 5.5)
      ..lineTo(12.2, 14.3)
      ..lineTo(8.5, 15.2)
      ..lineTo(9.4, 11.5)
      ..close();
    canvas.drawPath(pencilPath, paint);
  }

  /// 删除图标
  void _drawDelete(Canvas canvas, Paint paint, Paint duotonePaint) {
    final binRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(5.5, 6.5, 13, 14.5),
      const Radius.circular(3.5),
    );
    canvas.drawRRect(binRRect, duotonePaint);

    canvas.drawLine(const Offset(3.5, 6), const Offset(20.5, 6), paint);

    final handlePath = Path()
      ..moveTo(8.5, 6)
      ..lineTo(8.5, 4.2)
      ..quadraticBezierTo(8.5, 2.8, 10, 2.8)
      ..lineTo(14, 2.8)
      ..quadraticBezierTo(15.5, 2.8, 15.5, 4.2)
      ..lineTo(15.5, 6);
    canvas.drawPath(handlePath, paint);

    final binPath = Path()
      ..moveTo(18.5, 6)
      ..lineTo(18, 18.5)
      ..quadraticBezierTo(17.8, 21, 15.2, 21)
      ..lineTo(8.8, 21)
      ..quadraticBezierTo(6.2, 21, 6, 18.5)
      ..lineTo(5.5, 6);
    canvas.drawPath(binPath, paint);

    canvas.drawLine(const Offset(10, 10.5), const Offset(10, 16.5), paint);
    canvas.drawLine(const Offset(14, 10.5), const Offset(14, 16.5), paint);
  }

  /// 置顶星标图标
  void _drawPin(Canvas canvas, Paint paint, Paint duotonePaint) {
    final path = Path()
      ..moveTo(12, 2.5)
      ..lineTo(14.9, 8.3)
      ..lineTo(21.3, 9.2)
      ..lineTo(16.6, 13.8)
      ..lineTo(17.7, 20.2)
      ..lineTo(12, 17.2)
      ..lineTo(6.3, 20.2)
      ..lineTo(7.4, 13.8)
      ..lineTo(2.7, 9.2)
      ..lineTo(9.1, 8.3)
      ..close();
    canvas.drawPath(path, duotonePaint);
    canvas.drawPath(path, paint);
  }

  /// 勾选对勾图标
  void _drawCheck(Canvas canvas, Paint paint) {
    paint.strokeWidth = 2.6;
    final path = Path()
      ..moveTo(19.5, 6.5)
      ..lineTo(9.5, 16.8)
      ..lineTo(4.5, 11.8);
    canvas.drawPath(path, paint);
  }

  /// 刷新图标
  void _drawRefresh(Canvas canvas, Paint paint) {
    final path = Path()
      ..moveTo(4, 4.5)
      ..lineTo(4, 9.5)
      ..lineTo(9, 9.5);
    canvas.drawPath(path, paint);

    final arcPath = Path()
      ..moveTo(4.5, 14.5)
      ..cubicTo(6, 19.5, 11.5, 21.5, 16.2, 19.2)
      ..cubicTo(20.8, 17, 21.8, 11, 18.8, 6.8)
      ..cubicTo(15.8, 2.8, 9.5, 2.5, 4.5, 8.8);
    canvas.drawPath(arcPath, paint);
  }

  /// 播放图标
  void _drawPlay(Canvas canvas, Paint fillPaint) {
    final path = Path()
      ..moveTo(6, 4)
      ..lineTo(19, 12)
      ..lineTo(6, 20)
      ..close();
    canvas.drawPath(path, fillPaint);
  }

  /// 暂停图标
  void _drawPause(Canvas canvas, Paint fillPaint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(6, 4, 4, 16), const Radius.circular(1.5)),
      fillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(14, 4, 4, 16), const Radius.circular(1.5)),
      fillPaint,
    );
  }

  /// 菜单汉堡图标（高低错落现代感设计）
  void _drawMenu(Canvas canvas, Paint paint) {
    canvas.drawLine(const Offset(4, 6.5), const Offset(20, 6.5), paint);
    canvas.drawLine(const Offset(4, 12), const Offset(16, 12), paint);
    canvas.drawLine(const Offset(4, 17.5), const Offset(20, 17.5), paint);
  }

  /// 关闭图标
  void _drawClose(Canvas canvas, Paint paint) {
    canvas.drawLine(const Offset(17.5, 6.5), const Offset(6.5, 17.5), paint);
    canvas.drawLine(const Offset(6.5, 6.5), const Offset(17.5, 17.5), paint);
  }

  /// 右箭头图标
  void _drawChevronRight(Canvas canvas, Paint paint) {
    final path = Path()
      ..moveTo(9.5, 17.5)
      ..lineTo(15, 12)
      ..lineTo(9.5, 6.5);
    canvas.drawPath(path, paint);
  }

  /// 数据管理图标：精致双层圆柱数据库/数据包图标
  void _drawData(Canvas canvas, Paint paint, Paint duotonePaint) {
    // 顶部椭圆盘填充
    final topOval =
        Rect.fromCenter(center: const Offset(12, 6), width: 15, height: 5.5);
    canvas.drawOval(topOval, duotonePaint);
    canvas.drawOval(topOval, paint);

    // 中间层弧线
    final midArc = Path()
      ..moveTo(4.5, 12)
      ..quadraticBezierTo(12, 15.4, 19.5, 12);
    canvas.drawPath(midArc, paint);

    // 底部与两侧包裹
    final bodyPath = Path()
      ..moveTo(4.5, 6)
      ..lineTo(4.5, 17.5)
      ..quadraticBezierTo(12, 21.2, 19.5, 17.5)
      ..lineTo(19.5, 6);
    canvas.drawPath(bodyPath, paint);
  }

  /// 探索/指南针图标
  void _drawExplore(Canvas canvas, Paint paint, Paint duotonePaint) {
    canvas.drawCircle(const Offset(12, 12), 9, duotonePaint);
    canvas.drawCircle(const Offset(12, 12), 9, paint);

    final diamond = Path()
      ..moveTo(15.8, 8.2)
      ..lineTo(13.6, 13.6)
      ..lineTo(8.2, 15.8)
      ..lineTo(10.4, 10.4)
      ..close();
    canvas.drawPath(diamond, paint..strokeWidth = 1.8);
  }

  /// 导出/上传图标：圆角底托盘 + 向上饱满箭头
  void _drawUpload(Canvas canvas, Paint paint, Paint duotonePaint) {
    final trayRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(3.5, 13.5, 17, 7),
      const Radius.circular(3.5),
    );
    canvas.drawRRect(trayRRect, duotonePaint);

    final boxPath = Path()
      ..moveTo(20.5, 14.5)
      ..lineTo(20.5, 17.5)
      ..quadraticBezierTo(20.5, 20.5, 17.5, 20.5)
      ..lineTo(6.5, 20.5)
      ..quadraticBezierTo(3.5, 20.5, 3.5, 17.5)
      ..lineTo(3.5, 14.5);
    canvas.drawPath(boxPath, paint);

    final arrowPath = Path()
      ..moveTo(16.5, 8)
      ..lineTo(12, 3.5)
      ..lineTo(7.5, 8);
    canvas.drawPath(arrowPath, paint);
    canvas.drawLine(const Offset(12, 3.8), const Offset(12, 15.5), paint);
  }

  /// 导入/下载图标：圆角底托盘 + 向下饱满箭头
  void _drawDownload(Canvas canvas, Paint paint, Paint duotonePaint) {
    final trayRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(3.5, 13.5, 17, 7),
      const Radius.circular(3.5),
    );
    canvas.drawRRect(trayRRect, duotonePaint);

    final boxPath = Path()
      ..moveTo(20.5, 14.5)
      ..lineTo(20.5, 17.5)
      ..quadraticBezierTo(20.5, 20.5, 17.5, 20.5)
      ..lineTo(6.5, 20.5)
      ..quadraticBezierTo(3.5, 20.5, 3.5, 17.5)
      ..lineTo(3.5, 14.5);
    canvas.drawPath(boxPath, paint);

    final arrowPath = Path()
      ..moveTo(7.5, 10.5)
      ..lineTo(12, 15)
      ..lineTo(16.5, 10.5);
    canvas.drawPath(arrowPath, paint);
    canvas.drawLine(const Offset(12, 14.8), const Offset(12, 3.5), paint);
  }

  /// DeepSeek AI / API Key 图标：灵动双子四芒星（Sparkles ✨）
  void _drawApiKey(
      Canvas canvas, Paint paint, Paint fillPaint, Paint duotonePaint) {
    // 主四芒星
    final mainStar = Path()
      ..moveTo(11, 2.5)
      ..quadraticBezierTo(11.3, 8.5, 17, 9.5)
      ..quadraticBezierTo(11.3, 10.5, 11, 16.5)
      ..quadraticBezierTo(10.7, 10.5, 5, 9.5)
      ..quadraticBezierTo(10.7, 8.5, 11, 2.5)
      ..close();
    canvas.drawPath(mainStar, duotonePaint);
    canvas.drawPath(mainStar, paint..strokeWidth = 1.9);

    // 右下副四芒星
    final subStar = Path()
      ..moveTo(18, 13.5)
      ..quadraticBezierTo(18.2, 16.8, 21.2, 17.2)
      ..quadraticBezierTo(18.2, 17.6, 18, 21)
      ..quadraticBezierTo(17.8, 17.6, 14.8, 17.2)
      ..quadraticBezierTo(17.8, 16.8, 18, 13.5)
      ..close();
    canvas.drawPath(subStar, fillPaint);

    // 左上微光圆点
    canvas.drawCircle(const Offset(5.2, 4.5), 1.1, fillPaint);
  }

  /// 使用帮助图标：柔和圆底 + 优雅问号
  void _drawHelp(
      Canvas canvas, Paint paint, Paint fillPaint, Paint duotonePaint) {
    canvas.drawCircle(const Offset(12, 12), 9.2, duotonePaint);
    canvas.drawCircle(const Offset(12, 12), 9.2, paint);

    final questionPath = Path()
      ..moveTo(9.5, 9.2)
      ..cubicTo(9.5, 6.8, 14.5, 6.8, 14.5, 9.5)
      ..cubicTo(14.5, 11.2, 12, 11.8, 12, 13.8);
    canvas.drawPath(questionPath, paint);

    fillPaint.color = paint.color;
    canvas.drawCircle(const Offset(12, 17.2), 1.2, fillPaint);
  }

  /// 咖啡杯图标：圆润杯身 + 柔和咖啡液面 + 飘逸蒸汽
  void _drawCoffee(Canvas canvas, Paint paint, Paint duotonePaint) {
    final cupFill = Path()
      ..moveTo(5.5, 8.5)
      ..lineTo(5.5, 15.5)
      ..quadraticBezierTo(5.5, 20, 10, 20)
      ..lineTo(13, 20)
      ..quadraticBezierTo(17.5, 20, 17.5, 15.5)
      ..lineTo(17.5, 8.5)
      ..close();
    canvas.drawPath(cupFill, duotonePaint);
    canvas.drawPath(cupFill, paint);

    // 杯把
    final handlePath = Path()
      ..moveTo(17.5, 10)
      ..quadraticBezierTo(21.5, 10, 21.5, 13.2)
      ..quadraticBezierTo(21.5, 16.5, 17.5, 16.5);
    canvas.drawPath(handlePath, paint);

    // 蒸汽
    paint.strokeWidth = 1.7;
    final steam1 = Path()
      ..moveTo(9, 5.8)
      ..quadraticBezierTo(8.2, 4, 9.8, 2.5);
    canvas.drawPath(steam1, paint);

    final steam2 = Path()
      ..moveTo(13.5, 5.8)
      ..quadraticBezierTo(12.7, 4, 14.3, 2.5);
    canvas.drawPath(steam2, paint);
  }

  /// 品牌徽标图标（供侧边栏顶部使用：向上生长的双叶与璀璨星芒）
  void _drawBrandLogo(Canvas canvas, Paint paint, Paint fillPaint) {
    // 顶部璀璨四芒星
    final star = Path()
      ..moveTo(12, 2.2)
      ..quadraticBezierTo(12.4, 6.2, 16.2, 6.8)
      ..quadraticBezierTo(12.4, 7.4, 12, 11.4)
      ..quadraticBezierTo(11.6, 7.4, 7.8, 6.8)
      ..quadraticBezierTo(11.6, 6.2, 12, 2.2)
      ..close();
    canvas.drawPath(star, fillPaint);

    // 底部向上舒展的活力双翼/幼苗叶片
    final leftLeaf = Path()
      ..moveTo(12, 20.5)
      ..quadraticBezierTo(5, 19.5, 4.5, 12.5)
      ..quadraticBezierTo(9.5, 12.5, 12, 17.5);
    canvas.drawPath(
      leftLeaf,
      Paint()
        ..color = color.withOpacity(0.85)
        ..style = PaintingStyle.fill,
    );

    final rightLeaf = Path()
      ..moveTo(12, 20.5)
      ..quadraticBezierTo(19, 19.5, 19.5, 12.5)
      ..quadraticBezierTo(14.5, 12.5, 12, 17.5);
    canvas.drawPath(
      rightLeaf,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    // 中心茎干高光
    canvas.drawLine(
      const Offset(12, 12.5),
      const Offset(12, 21),
      paint..strokeWidth = 2.2,
    );
  }

  @override
  bool shouldRepaint(covariant _IconPainter oldDelegate) {
    return type != oldDelegate.type || color != oldDelegate.color;
  }
}
