import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/app.dart';
import 'src/core/theme/app_text_styles.dart';

/// 在首帧渲染与任何异步任务启动前，单线程同步锁定 PingFang SC 各字重字形表 (cmap/CTFontRef)，
/// 防止 iOS 冷启动并发排版时发生跨字体 Fallback 缓存污染。
void _prelockPrimaryChineseFontTable() {
  const sampleText = '微行动今日计划习惯时间锚点今天昨天已完成0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  const weights = <FontWeight>[
    FontWeight.normal,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.bold,
  ];
  for (final weight in weights) {
    final painter = TextPainter(
      text: TextSpan(
        text: sampleText,
        style: TextStyle(
          fontFamily: AppTextStyles.primaryFont,
          fontFamilyFallback: AppTextStyles.fontFallback,
          fontSize: 16,
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.dispose();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _prelockPrimaryChineseFontTable();

  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  runApp(const MaintenanceApp());
}
