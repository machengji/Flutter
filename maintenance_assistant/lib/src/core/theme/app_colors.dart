import 'package:flutter/material.dart';

/// 应用全局颜色定义 - 自然绿色系
/// 
/// 设计理念：清新、健康、生机勃勃，适合习惯培养和自我提升类应用
class AppColors {
  AppColors._();

  // ==================== 主色调 ====================
  /// 主色 - 薄荷绿
  static const Color primary = Color(0xFF2ECC71);
  
  /// 主色变体
  static const Color primaryLight = Color(0xFF58D68D);
  static const Color primaryDark = Color(0xFF27AE60);
  
  /// 次要色 - 翡翠绿
  static const Color secondary = Color(0xFF1ABC9C);
  static const Color secondaryLight = Color(0xFF48C9B0);
  static const Color secondaryDark = Color(0xFF16A085);

  // ==================== 功能色 ====================
  /// 成功色 - 叶绿
  static const Color success = Color(0xFF27AE60);
  
  /// 警告色 - 琥珀黄
  static const Color warning = Color(0xFFF39C12);
  
  /// 错误色 - 珊瑚红
  static const Color error = Color(0xFFE74C3C);
  
  /// 信息色 - 天蓝
  static const Color info = Color(0xFF3498DB);

  // ==================== 中性色 ====================
  /// 背景色
  static const Color background = Color(0xFFF8FAF9);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFFF0F4F3);
  
  /// 表面色 - 卡片等
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F9F7);
  
  /// 文字颜色
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textHint = Color(0xFFBDC3C7);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  /// 边框和分割线
  static const Color border = Color(0xFFE8EDE9);
  static const Color divider = Color(0xFFF2F4F3);

  // ==================== 渐变色 ====================
  /// 主渐变 - 森林绿渐变
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
  );
  
  /// 次要渐变 - 翡翠渐变
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1ABC9C), Color(0xFF16A085)],
  );
  
  /// 背景渐变 - 柔和白绿
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF0F9F4), Color(0xFFF8FAF9)],
  );
  
  /// 卡片渐变 - 玻璃质感
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAF9)],
  );

  // ==================== 阴影色 ====================
  /// 柔和阴影色 - 基于主色的低透明度
  static Color shadowLight = const Color(0xFF2ECC71).withOpacity(0.08);
  static Color shadowMedium = const Color(0xFF2ECC71).withOpacity(0.12);
  static Color shadowDark = const Color(0xFF2C3E50).withOpacity(0.08);

  // ==================== 语义化颜色获取 ====================
  /// 计划卡片色
  static const Color planCard = Color(0xFFE8F8F0);
  static const Color planAccent = Color(0xFF2ECC71);
  
  /// 习惯卡片色
  static const Color habitCard = Color(0xFFE3F2FD);
  static const Color habitAccent = Color(0xFF3498DB);
  
  /// 锚点卡片色
  static const Color anchorCard = Color(0xFFFFF3E0);
  static const Color anchorAccent = Color(0xFFF39C12);

  // ==================== 分组标签色 ====================
  /// 用于标识 AI 分解出来的同源计划/习惯
  static const List<Color> groupColors = [
    Color(0xFF9B59B6),  // 紫色
    Color(0xFF3498DB),  // 蓝色
    Color(0xFFE91E63),  // 粉色
    Color(0xFFFF9800),  // 橙色
    Color(0xFF00BCD4),  // 青色
    Color(0xFF8BC34A),  // 浅绿
    Color(0xFFFF5722),  // 深橙
    Color(0xFF607D8B),  // 蓝灰
  ];
}
