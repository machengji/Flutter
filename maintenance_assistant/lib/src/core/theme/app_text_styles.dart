import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 应用全局文字样式定义
/// 
/// 遵循 Material Design 3 的 Typography 规范，针对 iOS/中文环境优化字体回退链
class AppTextStyles {
  AppTextStyles._();

  /// 严谨的中文优先字体回退链，杜绝 iOS 字形纹理映射错乱
  static const List<String> fontFallback = [
    'PingFang SC',
    'PingFang TC',
    'PingFang HK',
    'Heiti SC',
    'Microsoft YaHei',
    'sans-serif',
  ];

  // ==================== 标题样式 ====================
  /// 大标题 - 页面主标题
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.25,
    letterSpacing: -0.5,
    fontFamilyFallback: fontFallback,
  );
  
  /// 中标题 - 区块标题
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.28,
    letterSpacing: -0.25,
    fontFamilyFallback: fontFallback,
  );
  
  /// 小标题 - 卡片标题
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.33,
    fontFamilyFallback: fontFallback,
  );

  // ==================== 正文标题 ====================
  /// 大字号标题
  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
    fontFamilyFallback: fontFallback,
  );
  
  /// 中字号标题
  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.44,
    fontFamilyFallback: fontFallback,
  );
  
  /// 小字号标题
  static const TextStyle titleSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
    fontFamilyFallback: fontFallback,
  );

  // ==================== 正文样式 ====================
  /// 大正文
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
    fontFamilyFallback: fontFallback,
  );
  
  /// 中正文
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
    fontFamilyFallback: fontFallback,
  );
  
  /// 小正文
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.5,
    fontFamilyFallback: fontFallback,
  );

  // ==================== 标签样式 ====================
  /// 大标签
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.42,
    letterSpacing: 0.1,
    fontFamilyFallback: fontFallback,
  );
  
  /// 中标签
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.33,
    letterSpacing: 0.5,
    fontFamilyFallback: fontFallback,
  );
  
  /// 小标签
  static const TextStyle labelSmall = TextStyle(
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
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    height: 1.5,
    letterSpacing: 0.25,
    fontFamilyFallback: fontFallback,
  );
  
  /// 卡片名称
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
    fontFamilyFallback: fontFallback,
  );
  
  /// 卡片描述
  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
    fontFamilyFallback: fontFallback,
  );
  
  /// 徽章文字
  static const TextStyle badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: AppColors.textOnPrimary,
    height: 1.2,
    fontFamilyFallback: fontFallback,
  );
}
