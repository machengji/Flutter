import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// 应用全局装饰样式定义（融合苹果 VisionOS / iOS 18 液态玻璃规范）
class AppDecorations {
  AppDecorations._();

  // ==================== 圆角 ====================
  /// 小圆角 - 图标、标签
  static const double radiusSmall = 8.0;
  
  /// 中圆角 - 按钮、输入框
  static const double radiusMedium = 14.0;
  
  /// 大圆角 - 卡片、对话框
  static const double radiusLarge = 22.0;
  
  /// 超大圆角 - 底部弹窗、切换器
  static const double radiusXLarge = 30.0;
  
  /// 圆形
  static const double radiusCircle = 999.0;

  // ==================== 间距 ====================
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  // ==================== 苹果液态玻璃阴影体系 ====================
  /// 柔和液态景深阴影
  static List<BoxShadow> shadowSoft = [
    BoxShadow(
      color: const Color(0xFF1B382B).withOpacity(0.06),
      offset: const Offset(0, 8),
      blurRadius: 24,
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Colors.white.withOpacity(0.8),
      offset: const Offset(0, -1),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];
  
  /// 中等阴影 - 浮动控制岛
  static List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: const Color(0xFF0A2E1D).withOpacity(0.09),
      offset: const Offset(0, 12),
      blurRadius: 32,
      spreadRadius: -6,
    ),
  ];
  
  /// 按钮阴影
  static List<BoxShadow> shadowButton = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.3),
      offset: const Offset(0, 6),
      blurRadius: 18,
      spreadRadius: -2,
    ),
  ];

  // ==================== 核心液态玻璃卡片装饰 ====================
  /// 计划卡片液态玻璃装饰
  static BoxDecoration planCardDecoration = BoxDecoration(
    color: Colors.white.withOpacity(0.72),
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(
      color: Colors.white.withOpacity(0.9),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withOpacity(0.08),
        offset: const Offset(0, 10),
        blurRadius: 24,
        spreadRadius: -4,
      ),
      BoxShadow(
        color: Colors.white.withOpacity(0.8),
        offset: const Offset(0, 1),
        blurRadius: 2,
        spreadRadius: 0,
      ),
    ],
  );
  
  /// 习惯卡片液态玻璃装饰
  static BoxDecoration habitCardDecoration = BoxDecoration(
    color: Colors.white.withOpacity(0.72),
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(
      color: Colors.white.withOpacity(0.9),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.habitAccent.withOpacity(0.08),
        offset: const Offset(0, 10),
        blurRadius: 24,
        spreadRadius: -4,
      ),
      BoxShadow(
        color: Colors.white.withOpacity(0.8),
        offset: const Offset(0, 1),
        blurRadius: 2,
        spreadRadius: 0,
      ),
    ],
  );
  
  /// 锚点卡片液态玻璃装饰
  static BoxDecoration anchorCardDecoration = BoxDecoration(
    color: Colors.white.withOpacity(0.72),
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(
      color: Colors.white.withOpacity(0.9),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.anchorAccent.withOpacity(0.08),
        offset: const Offset(0, 10),
        blurRadius: 24,
        spreadRadius: -4,
      ),
      BoxShadow(
        color: Colors.white.withOpacity(0.8),
        offset: const Offset(0, 1),
        blurRadius: 2,
        spreadRadius: 0,
      ),
    ],
  );

  // ==================== 按钮与输入框 ====================
  /// 主按钮装饰
  static BoxDecoration primaryButtonDecoration = BoxDecoration(
    gradient: AppColors.primaryGradient,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: shadowButton,
    border: Border.all(
      color: Colors.white.withOpacity(0.35),
      width: 1.2,
    ),
  );
  
  /// 次要按钮装饰
  static BoxDecoration secondaryButtonDecoration = BoxDecoration(
    color: Colors.white.withOpacity(0.65),
    borderRadius: BorderRadius.circular(radiusMedium),
    border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.2),
  );
  
  /// 操作按钮装饰（卡片内玻璃微晶按钮）
  static BoxDecoration actionButtonDecoration = BoxDecoration(
    color: Colors.white.withOpacity(0.85),
    borderRadius: BorderRadius.circular(radiusMedium),
    border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        offset: const Offset(0, 2),
        blurRadius: 8,
      ),
    ],
  );

  /// 危险操作按钮装饰
  static BoxDecoration dangerButtonDecoration = BoxDecoration(
    color: AppColors.error.withOpacity(0.08),
    borderRadius: BorderRadius.circular(radiusMedium),
    border: Border.all(color: AppColors.error.withOpacity(0.25), width: 1),
  );

  /// 输入框装饰
  static InputDecoration inputDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.textHint),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.85),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingMedium,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.9), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.85), width: 1.2),
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
  /// 底部弹窗液态玻璃装饰
  static BoxDecoration bottomSheetDecoration = BoxDecoration(
    color: Colors.white.withOpacity(0.88),
    borderRadius: const BorderRadius.vertical(
      top: Radius.circular(radiusXLarge),
    ),
    border: Border(
      top: BorderSide(
        color: Colors.white.withOpacity(0.95),
        width: 1.5,
      ),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.12),
        offset: const Offset(0, -6),
        blurRadius: 30,
        spreadRadius: -2,
      ),
    ],
  );
  
  /// 拖拽指示器装饰
  static BoxDecoration dragHandleDecoration = BoxDecoration(
    color: Colors.black.withOpacity(0.16),
    borderRadius: BorderRadius.circular(3),
  );
}

/// 苹果 VisionOS / iOS 18 标准液态高透厚玻璃容器
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final Color? tintColor;
  final double opacity;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadows;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.radius = AppDecorations.radiusLarge,
    this.padding,
    this.margin,
    this.blur = 18.0,
    this.tintColor,
    this.opacity = 0.72,
    this.borderColor,
    this.borderWidth = 1.5,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTintColor = tintColor ?? Colors.white;
    final effectiveBorderColor = borderColor ?? Colors.white.withOpacity(0.85);

    Widget result = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                effectiveTintColor.withOpacity(opacity),
                effectiveTintColor.withOpacity((opacity * 0.75).clamp(0.0, 1.0)),
              ],
              stops: const [0.0, 1.0],
            ),
            border: Border.all(
              color: effectiveBorderColor,
              width: borderWidth,
            ),
          ),
          child: child,
        ),
      ),
    );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadows ?? AppDecorations.shadowSoft,
      ),
      child: result,
    );
  }
}

/// 支持手指轻触 0.985 细腻微缩放与触感振动的液态交互组件
class LiquidPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final HitTestBehavior behavior;

  const LiquidPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.985,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<LiquidPressable> createState() => _LiquidPressableState();
}

class _LiquidPressableState extends State<LiquidPressable> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.pressedScale).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null || widget.onLongPress != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap != null
          ? () {
              HapticFeedback.selectionClick();
              widget.onTap?.call();
            }
          : null,
      onLongPress: widget.onLongPress != null
          ? () {
              HapticFeedback.mediumImpact();
              widget.onLongPress?.call();
            }
          : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// 苹果 VisionOS / iOS 18 标准液态磨砂玻璃底部面板包装
class LiquidGlassSheet extends StatelessWidget {
  final Widget child;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final double topRadius;

  const LiquidGlassSheet({
    super.key,
    required this.child,
    this.constraints,
    this.padding,
    this.blur = 20.0,
    this.topRadius = AppDecorations.radiusXLarge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: constraints,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            offset: const Offset(0, -6),
            blurRadius: 30,
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.92),
                  Colors.white.withOpacity(0.85),
                ],
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.95),
                  width: 1.5,
                ),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
