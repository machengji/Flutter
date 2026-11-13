import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/models/celebration_model.dart';
import '../providers/home_provider.dart';
import 'celebration_overlay.dart';

class ShineJarSheet extends StatefulWidget {
  const ShineJarSheet({super.key});

  @override
  State<ShineJarSheet> createState() => _ShineJarSheetState();
}

class _ShineJarSheetState extends State<ShineJarSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final TextEditingController _affirmationController;
  late final FocusNode _affirmationFocusNode;
  bool _hasDraft = false;
  int _burstId = 0;
  CelebrationPayload? _lastFreeCelebration;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    _affirmationController = TextEditingController();
    _affirmationFocusNode = FocusNode();
    _affirmationController.addListener(_onDraftChanged);
  }

  void _onDraftChanged() {
    final next = _affirmationController.text.trim().isNotEmpty;
    if (next != _hasDraft && mounted) {
      setState(() => _hasDraft = next);
    }
  }

  @override
  void dispose() {
    _affirmationController.removeListener(_onDraftChanged);
    _affirmationController.dispose();
    _affirmationFocusNode.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _shakeJar(HomeProvider provider) {
    provider.triggerCelebrationSensory(kind: 'light', progress: 0.6);
    _bounceController.forward(from: 0.0);
  }

  Future<void> _handleFreeCelebrate(HomeProvider provider) async {
    final payload = await provider.celebrateFreely();
    if (!mounted) return;
    setState(() {
      _lastFreeCelebration = payload;
      _burstId++;
    });
    _bounceController.forward(from: 0.0);
  }

  void _submitCustomAffirmation(HomeProvider provider) {
    final trimmed = _affirmationController.text.trim();
    if (trimmed.isEmpty) {
      _affirmationFocusNode.unfocus();
      return;
    }
    HapticFeedback.selectionClick();
    provider.addCustomAffirmation(trimmed);
    _affirmationController.clear();
    _affirmationFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        decoration: AppDecorations.bottomSheetDecoration,
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 14),
                    width: 44,
                    height: 5,
                    decoration: AppDecorations.dragHandleDecoration,
                  ),
                ),
                Flexible(
                  child: Consumer<HomeProvider>(
                    builder: (context, provider, _) {
                      final records = provider.shineRecords;
                      final todayCount = provider.todayShineCount;
                      final totalCount = provider.totalShineCount;
                      final customList = provider.customAffirmations;

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 标题与今日/累计统计
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '发光星籽罐',
                                  style: AppTextStyles.titleLarge.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.22),
                                    ),
                                  ),
                                  child: Text(
                                    '今日 $todayCount · 累计 $totalCount',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // 森系发光星籽玻璃罐（轻触微光跃动）
                            GestureDetector(
                              onTap: () => _shakeJar(provider),
                              child: Container(
                                height: 196,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF18392B),
                                      Color(0xFF24523D),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(26),
                                  border: Border.all(
                                    color: const Color(0xFFE9C46A).withOpacity(0.28),
                                  ),
                                ),
                                child: AnimatedBuilder(
                                  animation: _bounceController,
                                  builder: (context, _) {
                                    return CustomPaint(
                                      painter: _ShineJarPainter(
                                        records: records,
                                        bounceProgress: _bounceController.value,
                                      ),
                                      child: const SizedBox.expand(),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // 若刚完成一次自由练习庆祝，展示当次肯定语与微动作
                            if (_lastFreeCelebration != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.18),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      _lastFreeCelebration!.quote,
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _lastFreeCelebration!.microActionPrompt,
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.primaryDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // 「随时夸夸自己」0.6 秒蓄力练习按钮
                            ChargeToShineButton(
                              label: '按住 0.6 秒夸夸自己',
                              completedLabel: '星籽 +1',
                              allowQuickTapClose: false,
                              accentColor: const Color(0xFF2D6A4F),
                              textColor: Colors.white,
                              onChargeTick: (progress) {
                                provider.triggerCelebrationSensory(
                                  kind: 'charge_tick',
                                  progress: progress,
                                );
                              },
                              onCharged: () => _handleFreeCelebrate(provider),
                            ),
                            const SizedBox(height: 22),

                            // 庆祝偏好设置区
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.border.withOpacity(0.55),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '庆祝微音效',
                                        style: AppTextStyles.titleSmall,
                                      ),
                                      CupertinoSwitch(
                                        value: provider.celebrationSoundEnabled,
                                        activeColor: AppColors.primary,
                                        onChanged: (val) {
                                          HapticFeedback.selectionClick();
                                          provider
                                              .setCelebrationSoundEnabled(val);
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _StyleModeChip(
                                        label:
                                            '彩虹屁 ${provider.celebrationRainbowRatio}%',
                                        selected:
                                            provider.celebrationRainbowRatio >=
                                                50,
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          provider.setCelebrationRainbowRatio(
                                              100);
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      _StyleModeChip(
                                        label:
                                            '冷笑话 ${provider.celebrationColdJokeRatio}%',
                                        selected:
                                            provider.celebrationRainbowRatio <
                                                50,
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          provider.setCelebrationRainbowRatio(
                                              0);
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '自定义比例（点上方按钮可一键全选）',
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        '${provider.celebrationRainbowRatio}% / ${provider.celebrationColdJokeRatio}%',
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 4,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 8,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                        overlayRadius: 14,
                                      ),
                                      activeTrackColor: AppColors.primary,
                                      inactiveTrackColor:
                                          AppColors.primary.withOpacity(0.18),
                                      thumbColor: AppColors.primary,
                                    ),
                                    child: Slider(
                                      value: provider.celebrationRainbowRatio
                                          .toDouble(),
                                      min: 0,
                                      max: 100,
                                      divisions: 20,
                                      onChanged: (val) {
                                        provider.setCelebrationRainbowRatio(
                                          val.round(),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 自定义专属庆祝语 / 小奖励管理
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.22),
                                ),
                              ),
                              child: Row(
                                children: [
                                  AppIcon(
                                    type: AppIconType.add,
                                    size: 16,
                                    color: AppColors.primary.withOpacity(0.8),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _affirmationController,
                                      focusNode: _affirmationFocusNode,
                                      textInputAction: TextInputAction.done,
                                      onEditingComplete: () {},
                                      onSubmitted: (_) =>
                                          _submitCustomAffirmation(provider),
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontSize: 13.5,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '添加专属庆祝语或小奖励',
                                        hintStyle:
                                            AppTextStyles.bodySmall.copyWith(
                                          fontSize: 13,
                                          color: AppColors.textHint,
                                        ),
                                        isDense: true,
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                  if (_hasDraft)
                                    GestureDetector(
                                      onTap: () =>
                                          _submitCustomAffirmation(provider),
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        width: 26,
                                        height: 26,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: AppIcon(
                                            type: AppIconType.check,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            if (customList.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              ...customList.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item,
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(fontSize: 13.5),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            provider
                                                .removeCustomAffirmation(item);
                                          },
                                          behavior: HitTestBehavior.opaque,
                                          child: const Padding(
                                            padding: EdgeInsets.only(left: 8),
                                            child: AppIcon(
                                              type: AppIconType.close,
                                              size: 15,
                                              color: AppColors.textHint,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned.fill(
              child: StarburstParticleLayer(
                burstId: _burstId,
                isGrand: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyleModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StyleModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.border.withOpacity(0.7),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShineJarPainter extends CustomPainter {
  final List<ShineRecord> records;
  final double bounceProgress;

  const _ShineJarPainter({
    required this.records,
    required this.bounceProgress,
  });

  static const List<Color> _seedColors = [
    Color(0xFFFFD166),
    Color(0xFFE9C46A),
    Color(0xFF95D5B2),
    Color(0xFFF4A261),
    Color(0xFF74C69D),
    Color(0xFFFFF3B0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final jarWidth = math.min(size.width * 0.44, 152.0);
    final jarTop = 34.0;
    final jarBottom = size.height - 20.0;
    final jarHeight = jarBottom - jarTop;
    final jarRect = Rect.fromLTWH(
      cx - jarWidth / 2,
      jarTop,
      jarWidth,
      jarHeight,
    );

    // 背景柔和光晕
    final bgGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE9C46A).withOpacity(0.18),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(cx, jarTop + jarHeight * 0.6),
        radius: jarWidth * 0.9,
      ));
    canvas.drawCircle(
      Offset(cx, jarTop + jarHeight * 0.6),
      jarWidth * 0.9,
      bgGlow,
    );

    // 软木瓶塞与瓶口颈部
    final corkRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, jarTop - 7),
        width: jarWidth * 0.52,
        height: 12,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      corkRect,
      Paint()..color = const Color(0xFFC89B6E),
    );

    final neckRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, jarTop),
        width: jarWidth * 0.64,
        height: 8,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      neckRect,
      Paint()..color = Colors.white.withOpacity(0.24),
    );

    // 罐体圆角轮廓
    final bodyRRect = RRect.fromRectAndCorners(
      jarRect,
      topLeft: const Radius.circular(22),
      topRight: const Radius.circular(22),
      bottomLeft: const Radius.circular(28),
      bottomRight: const Radius.circular(28),
    );

    // 罐内玻璃底色
    canvas.drawRRect(
      bodyRRect,
      Paint()..color = Colors.white.withOpacity(0.08),
    );

    canvas.save();
    canvas.clipRRect(bodyRRect);

    // 若累计星籽较多，底部形成一层温润金色星沙微光底衬
    if (records.length > 24) {
      final sandRatio = ((records.length - 24) / 160.0).clamp(0.06, 0.36);
      final sandRect = Rect.fromLTWH(
        jarRect.left,
        jarRect.bottom - jarHeight * sandRatio,
        jarWidth,
        jarHeight * sandRatio,
      );
      final sandPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFE9C46A).withOpacity(0.12),
            const Color(0xFFE9C46A).withOpacity(0.38),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(sandRect);
      canvas.drawRect(sandRect, sandPaint);
    }

    // 绘制罐内星籽（最多绘制最近 72 颗保持通透精致，每颗位置由固定哈希决定）
    final visibleCount = math.min(records.length, 72);
    final jumpWave = math.sin(bounceProgress * math.pi);

    for (int i = 0; i < visibleCount; i++) {
      final item = records[visibleCount - 1 - i];
      final hash = item.id.hashCode.abs();
      final colCount = 6;
      final row = i ~/ colCount;
      final col = i % colCount;

      final jitterX = ((hash % 100) / 100.0 - 0.5) * 12.0;
      final jitterY = (((hash ~/ 100) % 100) / 100.0 - 0.5) * 7.0;

      final usableWidth = jarWidth - 28.0;
      final x = jarRect.left +
          14.0 +
          (col + 0.5) * (usableWidth / colCount) +
          jitterX;
      final baseBottom = jarRect.bottom - 14.0 - row * 10.5 + jitterY;
      final jumpOffset =
          jumpWave * (8.0 + (hash % 14)) * (1.0 - (row * 0.04).clamp(0.0, 0.5));
      final y = (baseBottom - jumpOffset).clamp(jarRect.top + 14.0, jarRect.bottom - 10.0);

      final center = Offset(x, y);
      final color = _seedColors[item.colorSeed.abs() % _seedColors.length];
      final radius = item.isGrand ? 6.6 : 5.0;

      final glow = Paint()
        ..color = color.withOpacity(0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(center, radius * 1.3, glow);

      final starPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawPath(
        buildFourPointStarPath(center, radius, radius * 0.40),
        starPaint,
      );
    }

    canvas.restore();

    // 罐体玻璃描边与左侧弧形高光折射条
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..color = Colors.white.withOpacity(0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final highlightPath = Path()
      ..moveTo(jarRect.left + 11, jarRect.top + 22)
      ..lineTo(jarRect.left + 11, jarRect.bottom - 26);
    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = Colors.white.withOpacity(0.22)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.2,
    );
  }

  @override
  bool shouldRepaint(covariant _ShineJarPainter oldDelegate) {
    return oldDelegate.records.length != records.length ||
        oldDelegate.bounceProgress != bounceProgress;
  }
}
