import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 应用全局文字样式定义
/// 
/// 遵循 Material Design 3 的 Typography 规范，在 iOS/中文环境下直接绑定 PingFang SC 为主字体，
/// 避免 `.SF Pro Text` 私有字体前缀触发跨字体 Fallback 导致的 CoreText 字形索引 (Glyph ID) 错位。
class AppTextStyles {
  AppTextStyles._();

  /// 全局主字体：直接使用包含完整 ASCII 与简体中文的苹方-简，杜绝中英跨字体 Fallback
  static const String primaryFont = 'PingFang SC';

  /// 精简后的字体回退链（剔除同一 PingFang.ttc 集合内的 TC/HK 子字体，防止 TTC 索引混淆）
  static const List<String> fontFallback = [
    'PingFang SC',
    'Heiti SC',
    'Microsoft YaHei',
    'sans-serif',
  ];

  // ==================== 标题样式 ====================
  /// 大标题 - 页面主标题
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.25,
    letterSpacing: -0.5,
    fontFamilyFallback: fontFallback,
  );
  
  /// 中标题 - 区块标题
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.28,
    letterSpacing: -0.25,
    fontFamilyFallback: fontFallback,
  );
  
  /// 小标题 - 卡片标题
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.33,
    fontFamilyFallback: fontFallback,
  );

  // ==================== 正文标题 ====================
  /// 大字号标题
  static const TextStyle titleLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
    fontFamilyFallback: fontFallback,
  );
  
  /// 中字号标题
  static const TextStyle titleMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.44,
    fontFamilyFallback: fontFallback,
  );
  
  /// 小字号标题
  static const TextStyle titleSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
    fontFamilyFallback: fontFallback,
  );

  // ==================== 正文样式 ====================
  /// 大正文
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
    fontFamilyFallback: fontFallback,
  );
  
  /// 中正文
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
    fontFamilyFallback: fontFallback,
  );
  
  /// 小正文
  static const TextStyle bodySmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.5,
    fontFamilyFallback: fontFallback,
  );

  // ==================== 标签样式 ====================
  /// 大标签
  static const TextStyle labelLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.42,
    letterSpacing: 0.1,
    fontFamilyFallback: fontFallback,
  );
  
  /// 中标签
  static const TextStyle labelMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.33,
    letterSpacing: 0.5,
    fontFamilyFallback: fontFallback,
  );
  
  /// 小标签
  static const TextStyle labelSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textHint,
    height: 1.45,
    letterSpacing: 0.5,
    fontFamilyFallback: fontFallback,
  );

  // ==================== 特殊样式 ====================
  /// 按钮文字
  static const TextStyle button = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    height: 1.5,
    letterSpacing: 0.25,
    fontFamilyFallback: fontFallback,
  );
  
  /// 卡片名称
  static const TextStyle cardTitle = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
    fontFamilyFallback: fontFallback,
  );
  
  /// 卡片描述
  static const TextStyle cardSubtitle = TextStyle(
    fontFamily: primaryFont,
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
    fontFamilyFallback: fontFallback,
  );
  
  /// 徽章文字
  static const TextStyle badge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: AppColors.textOnPrimary,
    height: 1.2,
    fontFamilyFallback: fontFallback,
  );
}
