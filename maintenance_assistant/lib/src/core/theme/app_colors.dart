import 'package:flutter/material.dart';

/// 应用全局颜色定义 - 森系植物园与自然生机色系 (Botanical & Woodland Palette)
/// 
/// 设计理念：温润、自然、护眼、生机盎然，将森林苔藓、晨露溪流、琥珀松果与花草色彩融为一体
class AppColors {
  AppColors._();

  // ==================== 主色调（森林新芽与苔藓绿） ====================
  /// 主色 - 森林新芽绿（温润不刺眼）
  static const Color primary = Color(0xFF2E8B57);
  
  /// 主色变体
  static const Color primaryLight = Color(0xFF52B788);
  static const Color primaryDark = Color(0xFF1B5E3A);
  
  /// 次要色 - 溪流鼠尾草青
  static const Color secondary = Color(0xFF2A9D8F);
  static const Color secondaryLight = Color(0xFF56C2B4);
  static const Color secondaryDark = Color(0xFF1D7268);

  // ==================== 功能色（自然果实与花卉色） ====================
  /// 成功色 - 翠叶绿
  static const Color success = Color(0xFF2E8B57);
  
  /// 警告/强调色 - 向日葵琥珀金
  static const Color warning = Color(0xFFE08E35);
  static const Color accent = Color(0xFFE08E35);
  
  /// 错误色 - 秋日山茶陶土红（柔和不刺眼）
  static const Color error = Color(0xFFD65A4F);
  
  /// 信息色 - 晨露鸢尾蓝
  static const Color info = Color(0xFF4A86B8);

  // ==================== 中性色（晨雾宣纸与温润苔石） ====================
  /// 背景色 - 极浅晨雾绿白
  static const Color background = Color(0xFFF4F8F5);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFFE9F1EC);
  
  /// 表面色 - 卡片等
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F7F3);
  
  /// 文字颜色 - 深林松墨色
  static const Color textPrimary = Color(0xFF1F3328);
  static const Color textSecondary = Color(0xFF5C7265);
  static const Color textHint = Color(0xFF9EB0A5);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  /// 边框和分割线 - 柔和叶脉灰绿
  static const Color border = Color(0xFFDCE7E0);
  static const Color divider = Color(0xFFEBF2ED);

  // ==================== 渐变色 ====================
  /// 主渐变 - 森林晨光渐变
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF40916C), Color(0xFF2D6A4F)],
  );
  
  /// 次要渐变 - 溪流青碧渐变
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF38A3A5), Color(0xFF227C7D)],
  );
  
  /// 背景渐变 - 柔和晨雾森林
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEAF4EE), Color(0xFFF5F9F6)],
  );
  
  /// 卡片渐变 - 温润玉石质感
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF6FBF8)],
  );

  // ==================== 阴影色 ====================
  /// 柔和阴影色 - 基于森林主色的自然弥散阴影
  static Color shadowLight = const Color(0xFF1B4332).withOpacity(0.06);
  static Color shadowMedium = const Color(0xFF1B4332).withOpacity(0.11);
  static Color shadowDark = const Color(0xFF1F3328).withOpacity(0.08);

  // ==================== 语义化颜色获取 ====================
  /// 计划卡片色（新芽嫩绿）
  static const Color planCard = Color(0xFFE8F5EE);
  static const Color planAccent = Color(0xFF2E8B57);
  
  /// 习惯卡片色（溪流鸢尾）
  static const Color habitCard = Color(0xFFE8F3F6);
  static const Color habitAccent = Color(0xFF3A8699);
  
  /// 锚点卡片色（暖阳松果）
  static const Color anchorCard = Color(0xFFFCF3E6);
  static const Color anchorAccent = Color(0xFFD9822B);

  // ==================== 分组标签色（自然花卉与矿石色系） ====================
  /// 用于标识同源拆解出来的子计划/微行动
  static const List<Color> groupColors = [
    Color(0xFF7E6B9F),  // 薰衣草紫
    Color(0xFF4A86B8),  // 矢车菊蓝
    Color(0xFFD46A84),  // 山茶粉
    Color(0xFFE08E35),  // 金盏花橙
    Color(0xFF2A9D8F),  // 湖水青
    Color(0xFF6A994E),  // 橄榄嫩绿
    Color(0xFFC86D51),  // 枫叶赤褐
    Color(0xFF607D8B),  // 远山黛蓝
  ];
}
