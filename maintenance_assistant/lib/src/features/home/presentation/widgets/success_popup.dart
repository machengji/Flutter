import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme.dart';
import '../providers/home_provider.dart';

class SuccessPopup extends StatefulWidget {
  final String description;
  final String type; // 'dream' or 'action'
  final VoidCallback onClose;

  const SuccessPopup({
    super.key,
    required this.description,
    this.type = 'action',
    required this.onClose,
  });

  @override
  State<SuccessPopup> createState() => _SuccessPopupState();
}

class _SuccessPopupState extends State<SuccessPopup> {
  late String _rainbowFart;

  bool get _isDream => widget.type == 'dream';

  Color get _accentColor => _isDream ? AppColors.secondary : AppColors.primary;

  Color get _accentColorSoft => _accentColor.withOpacity(0.10);

  LinearGradient get _buttonGradient => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          _accentColor,
          _isDream ? AppColors.info : AppColors.primaryLight,
        ],
      );

  String get _title => _isDream ? '梦想推进了一步' : '完成得很漂亮';

  String get _subtitle => _isDream ? '你的目标正在成形' : '你的行动正在积累价值';

  String get _badgeText => _isDream ? '梦想进度' : '行动完成';

  String get _summaryText {
    if (widget.description.trim().isEmpty) {
      return _isDream ? '继续保持这个节奏' : '今天又完成了一次兑现';
    }
    return widget.description;
  }

  @override
  void initState() {
    super.initState();
    _rainbowFart = context.read<HomeProvider>().rainbowFart;
  }

  void _copyDescription() {
    Clipboard.setData(ClipboardData(text: _rainbowFart));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('鼓励文案已复制'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(
                color: Colors.black.withOpacity(0.32),
              ),
            ),
          ),
          Center(
            child: RepaintBoundary(
              child: Container(
                width: screenWidth * 0.86,
                constraints: const BoxConstraints(maxWidth: 388),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _accentColor.withOpacity(0.14)),
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withOpacity(0.12),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _accentColorSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _badgeText,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: _accentColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _title,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _subtitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FBFA),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _accentColor.withOpacity(0.10)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _rainbowFart,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                height: 1.6,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _copyDescription,
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 13,
                                    color: _accentColor,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '点此复制',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: _accentColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _StatItem(
                              label: _isDream ? '达成类型' : '完成徽章',
                              value: _isDream ? '梦想推进' : '行动兑现',
                              color: _accentColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatItem(
                              label: '本次记录',
                              value: _summaryText.length > 6
                                  ? '${_summaryText.substring(0, 6)}...'
                                  : _summaryText,
                              color: AppColors.textPrimary,
                              backgroundColor: const Color(0xFFF7F6F3),
                              textColor: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _buttonGradient,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _accentColor.withOpacity(0.24),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: widget.onClose,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              '收下这份喜悦',
                              style: AppTextStyles.button.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 220.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.96, 0.96),
                  end: const Offset(1, 1),
                  duration: 220.ms,
                  curve: Curves.easeOutCubic,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color? backgroundColor;
  final Color? textColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedBackground = backgroundColor ?? color.withOpacity(0.08);
    final resolvedTextColor = textColor ?? color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: resolvedBackground,
        borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: resolvedTextColor.withOpacity(0.78),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(
              color: resolvedTextColor,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
