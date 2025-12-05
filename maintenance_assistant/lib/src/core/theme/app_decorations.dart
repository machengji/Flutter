import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 应用全局装饰样式定义
/// 
/// 包含卡片、按钮、输入框等组件的统一装饰样式
class AppDecorations {
  AppDecorations._();

  // ==================== 圆角 ====================
  /// 小圆角 - 图标、标签
  static const double radiusSmall = 8.0;
  
  /// 中圆角 - 按钮、输入框
  static const double radiusMedium = 12.0;
  
  /// 大圆角 - 卡片、对话框
  static const double radiusLarge = 20.0;
  
  /// 超大圆角 - 底部弹窗、切换器
  static const double radiusXLarge = 28.0;
  
  /// 圆形
  static const double radiusCircle = 999.0;

  // ==================== 间距 ====================
  /// 超小间距
  static const double spacingXSmall = 4.0;
  
  /// 小间距
  static const double spacingSmall = 8.0;
  
  /// 中间距
  static const double spacingMedium = 16.0;
  
  /// 大间距
  static const double spacingLarge = 24.0;
  
  /// 超大间距
  static const double spacingXLarge = 32.0;

  // ==================== 阴影 ====================
  /// 柔和阴影 - 卡片悬浮
  static List<BoxShadow> shadowSoft = [
    BoxShadow(
      color: AppColors.shadowLight,
      offset: const Offset(0, 4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];
  
  /// 中等阴影 - 重要元素
  static List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: AppColors.shadowMedium,
      offset: const Offset(0, 8),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];
  
  /// 按钮阴影
  static List<BoxShadow> shadowButton = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.25),
      offset: const Offset(0, 6),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];
  
  /// 警告阴影
  static List<BoxShadow> shadowError = [
    BoxShadow(
      color: AppColors.error.withOpacity(0.15),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  // ==================== 卡片装饰 ====================
  /// 基础卡片装饰
  static BoxDecoration cardDecoration = BoxDecoration(
    gradient: AppColors.cardGradient,
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(color: AppColors.border.withOpacity(0.5)),
    boxShadow: shadowSoft,
  );
  
  /// 计划卡片装饰
  static BoxDecoration planCardDecoration = BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white, Color(0xFFF5FBF8)],
    ),
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(color: AppColors.primary.withOpacity(0.12)),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withOpacity(0.08),
        offset: const Offset(0, 4),
        blurRadius: 16,
      ),
    ],
  );
  
  /// 习惯卡片装饰
  static BoxDecoration habitCardDecoration = BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white, Color(0xFFF5F9FC)],
    ),
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(color: AppColors.habitAccent.withOpacity(0.12)),
    boxShadow: [
      BoxShadow(
        color: AppColors.habitAccent.withOpacity(0.08),
        offset: const Offset(0, 4),
        blurRadius: 16,
      ),
    ],
  );
  
  /// 锚点卡片装饰
  static BoxDecoration anchorCardDecoration = BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white, Color(0xFFFFFBF5)],
    ),
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(color: AppColors.anchorAccent.withOpacity(0.12)),
    boxShadow: [
      BoxShadow(
        color: AppColors.anchorAccent.withOpacity(0.08),
        offset: const Offset(0, 4),
        blurRadius: 16,
      ),
    ],
  );

  // ==================== 按钮装饰 ====================
  /// 主按钮装饰
  static BoxDecoration primaryButtonDecoration = BoxDecoration(
    gradient: AppColors.primaryGradient,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: shadowButton,
  );
  
  /// 次要按钮装饰
  static BoxDecoration secondaryButtonDecoration = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(radiusMedium),
    border: Border.all(color: AppColors.primary),
  );
  
  /// 操作按钮装饰（卡片内）
  static BoxDecoration actionButtonDecoration = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(radiusMedium),
    border: Border.all(color: AppColors.border),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowLight,
        offset: const Offset(0, 2),
        blurRadius: 6,
      ),
    ],
  );
  
  /// 危险操作按钮装饰
  static BoxDecoration dangerButtonDecoration = BoxDecoration(
    color: AppColors.error.withOpacity(0.05),
    borderRadius: BorderRadius.circular(radiusMedium),
    border: Border.all(color: AppColors.error.withOpacity(0.2)),
  );

  // ==================== 输入框装饰 ====================
  /// 输入框装饰
  static InputDecoration inputDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: AppColors.textHint),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingMedium,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }

  // ==================== 底部弹窗装饰 ====================
  /// 底部弹窗装饰
  static const BoxDecoration bottomSheetDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(radiusXLarge),
    ),
  );
  
  /// 拖拽指示器装饰
  static BoxDecoration dragHandleDecoration = BoxDecoration(
    color: AppColors.border,
    borderRadius: BorderRadius.circular(3),
  );
}
