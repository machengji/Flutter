import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 应用全局文字样式定义
/// 
/// 遵循 Material Design 3 的 Typography 规范，针对中文优化
class AppTextStyles {
  AppTextStyles._();

  // ==================== 标题样式 ====================
  /// 大标题 - 页面主标题
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.25,
    letterSpacing: -0.5,
  );
  
  /// 中标题 - 区块标题
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.28,
    letterSpacing: -0.25,
  );
  
  /// 小标题 - 卡片标题
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.33,
  );

  // ==================== 正文标题 ====================
  /// 大字号标题
  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  /// 中字号标题
  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.44,
  );
  
  /// 小字号标题
  static const TextStyle titleSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // ==================== 正文样式 ====================
  /// 大正文
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  /// 中正文
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  /// 小正文
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // ==================== 标签样式 ====================
  /// 大标签
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.42,
    letterSpacing: 0.1,
  );
  
  /// 中标签
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.33,
    letterSpacing: 0.5,
  );
  
  /// 小标签
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textHint,
    height: 1.45,
    letterSpacing: 0.5,
  );

  // ==================== 特殊样式 ====================
  /// 按钮文字
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    height: 1.5,
    letterSpacing: 0.25,
  );
  
  /// 卡片名称
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  /// 卡片描述
  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  
  /// 徽章文字
  static const TextStyle badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: AppColors.textOnPrimary,
    height: 1.2,
  );
}
