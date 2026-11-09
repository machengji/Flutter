import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/theme.dart';

class AddAnchorModal extends StatefulWidget {
  final Function(
    String name,
    String time,
    String repeatMode,
    List<int> customDays,
  ) onAdd;
  final String? initialName;
  final String? initialTime;
  final String? initialRepeatMode;
  final List<int>? initialCustomDays;
  final bool autofocusEnabled;
  final bool enableEntranceAnimation;

  const AddAnchorModal({
    super.key,
    required this.onAdd,
    this.initialName,
    this.initialTime,
    this.initialRepeatMode,
    this.initialCustomDays,
    this.autofocusEnabled = true,
    this.enableEntranceAnimation = true,
  });

  @override
  State<AddAnchorModal> createState() => _AddAnchorModalState();
}

class _AddAnchorModalState extends State<AddAnchorModal> {
  late final TextEditingController _nameController;
  late int _selectedHour;
  late int _selectedMinute;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late String _repeatMode; // 'daily', 'workdays', 'weekends', 'custom'
  late Set<int> _selectedDays;
  final FocusNode _focusNode = FocusNode();

  static const List<Map<String, String>> _modeOptions = [
    {'key': 'daily', 'label': '每天', 'desc': '周一至周日'},
    {'key': 'workdays', 'label': '工作日', 'desc': '周一至周五'},
    {'key': 'weekends', 'label': '休息日', 'desc': '周六、周日'},
    {'key': 'custom', 'label': '自定义星期', 'desc': '按周自由勾选'},
  ];

  static const List<Map<String, dynamic>> _weekDays = [
    {'day': 1, 'label': '周一'},
    {'day': 2, 'label': '周二'},
    {'day': 3, 'label': '周三'},
    {'day': 4, 'label': '周四'},
    {'day': 5, 'label': '周五'},
    {'day': 6, 'label': '周六'},
    {'day': 7, 'label': '周日'},
  ];

  static const List<Map<String, dynamic>> _quickTimes = [
    {'label': '早起 07:30', 'hour': 7, 'minute': 30},
    {'label': '上班 09:00', 'hour': 9, 'minute': 0},
    {'label': '午间 12:30', 'hour': 12, 'minute': 30},
    {'label': '下班 18:30', 'hour': 18, 'minute': 30},
    {'label': '睡前 22:00', 'hour': 22, 'minute': 0},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);

    if (widget.initialTime != null) {
      final parts = widget.initialTime!.split(':');
      _selectedHour = int.tryParse(parts[0]) ?? 8;
      _selectedMinute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    } else {
      _selectedHour = 8;
      _selectedMinute = 0;
    }

    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(initialItem: _selectedMinute);

    _repeatMode = widget.initialRepeatMode ?? 'daily';
    final initDays = widget.initialCustomDays ?? const [1, 2, 3, 4, 5, 6, 7];
    _selectedDays = initDays.where((d) => d >= 1 && d <= 7).toSet();
    if (_selectedDays.isEmpty) {
      _selectedDays = {1, 2, 3, 4, 5, 6, 7};
    }

    if (widget.autofocusEnabled && widget.initialName == null) {
      Future.delayed(const Duration(milliseconds: 220), () {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _applyQuickTime(int hour, int minute) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedHour = hour;
      _selectedMinute = minute;
    });
    if (_hourController.hasClients) {
      _hourController.animateToItem(
        hour,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
    if (_minuteController.hasClients) {
      _minuteController.animateToItem(
        minute,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _syncModeFromSelectedDays() {
    if (_selectedDays.length == 7) {
      _repeatMode = 'daily';
    } else if (_selectedDays.length == 5 &&
        _selectedDays.containsAll(const [1, 2, 3, 4, 5])) {
      _repeatMode = 'workdays';
    } else if (_selectedDays.length == 2 &&
        _selectedDays.containsAll(const [6, 7])) {
      _repeatMode = 'weekends';
    } else {
      _repeatMode = 'custom';
    }
  }

  String get _currentRepeatSummary {
    final sorted = _selectedDays.toList()..sort();
    if (_repeatMode == 'daily' || sorted.length == 7) {
      return '每天（周一至周日）显示并提醒';
    }
    if (_repeatMode == 'workdays' ||
        (sorted.length == 5 && _selectedDays.containsAll(const [1, 2, 3, 4, 5]))) {
      return '仅工作日（周一至周五）在日历显示';
    }
    if (_repeatMode == 'weekends' ||
        (sorted.length == 2 && _selectedDays.containsAll(const [6, 7]))) {
      return '仅休息日（周六、周日）在日历显示';
    }
    const names = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '每${sorted.map((d) => names[d]).join('、')}在日历显示';
  }

  void _handleSubmit() {
    final text = _nameController.text.trim();
    if (text.isEmpty) return;

    final hour = _selectedHour.toString().padLeft(2, '0');
    final minute = _selectedMinute.toString().padLeft(2, '0');
    final sortedDays = _selectedDays.toList()..sort();
    widget.onAdd(
      text,
      '$hour:$minute',
      _repeatMode,
      sortedDays.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : sortedDays,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialName != null;
    final formattedTime =
        '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}';

    final dialogChild = RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDecorations.radiusLarge),
          border: Border.all(color: AppColors.anchorAccent.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: AppColors.anchorAccent.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 顶部标题栏
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.anchorAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                    ),
                    child: const AppIcon(
                      type: AppIconType.anchor,
                      size: 20,
                      color: AppColors.anchorAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing ? '编辑时间锚点' : '添加时间锚点',
                      style: AppTextStyles.titleLarge,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.textHint.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const AppIcon(
                        type: AppIconType.close,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 1. 锚点名称输入框
              TextField(
                controller: _nameController,
                focusNode: _focusNode,
                decoration: AppDecorations.inputDecoration(
                  hintText: '输入锚点名称（如：早起后、上班前、周末复盘）',
                ),
                style: AppTextStyles.bodyLarge,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleSubmit(),
              ),
              const SizedBox(height: 16),

              // 2. 中文重复日期选择面板（直接展示快捷预设 + 中文周一至周日点选）
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.anchorAccent.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                  border: Border.all(color: AppColors.anchorAccent.withOpacity(0.14)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const AppIcon(
                          type: AppIconType.plan,
                          size: 16,
                          color: AppColors.anchorAccent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '重复日期选择',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _currentRepeatSummary,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.anchorAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // 快捷预设按钮：每天 / 工作日 / 休息日 / 自定义星期
                    Row(
                      children: _modeOptions.map((opt) {
                        final key = opt['key']!;
                        final label = opt['label']!;
                        final isSelected = _repeatMode == key;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.5),
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _repeatMode = key;
                                  if (key == 'daily') {
                                    _selectedDays = {1, 2, 3, 4, 5, 6, 7};
                                  } else if (key == 'workdays') {
                                    _selectedDays = {1, 2, 3, 4, 5};
                                  } else if (key == 'weekends') {
                                    _selectedDays = {6, 7};
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.anchorAccent
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.anchorAccent
                                        : AppColors.anchorAccent.withOpacity(0.22),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    // 始终展示中文「周一 ~ 周日」直接点击切换按钮，无需二次展开
                    Row(
                      children: _weekDays.map((item) {
                        final day = item['day'] as int;
                        final label = item['label'] as String;
                        final active = _selectedDays.contains(day);
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  if (active && _selectedDays.length > 1) {
                                    _selectedDays.remove(day);
                                  } else {
                                    _selectedDays.add(day);
                                  }
                                  _syncModeFromSelectedDays();
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppColors.anchorAccent.withOpacity(0.16)
                                      : Colors.white.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: active
                                        ? AppColors.anchorAccent
                                        : AppColors.anchorAccent.withOpacity(0.18),
                                    width: active ? 1.3 : 1.0,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                    color: active
                                        ? AppColors.anchorAccent
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. 纯中文直滑时间滚轮（24小时制「XX时 XX分」+ 常用时间一键点选）
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.anchorAccent.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                  border: Border.all(color: AppColors.anchorAccent.withOpacity(0.14)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const AppIcon(
                          type: AppIconType.habit,
                          size: 16,
                          color: AppColors.anchorAccent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '触发时间（中文滚轮直选）',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.anchorAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            formattedTime,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // 常用时间一键点选胶囊
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _quickTimes.map((qt) {
                          final h = qt['hour'] as int;
                          final m = qt['minute'] as int;
                          final label = qt['label'] as String;
                          final isCurrent = _selectedHour == h && _selectedMinute == m;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () => _applyQuickTime(h, m),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? AppColors.anchorAccent
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isCurrent
                                        ? AppColors.anchorAccent
                                        : AppColors.anchorAccent.withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                    color: isCurrent ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 内嵌中文「时 / 分」双滚轮，上下滑动即选，无需二次弹窗
                    Container(
                      height: 116,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.anchorAccent.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: CupertinoPicker(
                              scrollController: _hourController,
                              itemExtent: 34,
                              magnification: 1.08,
                              useMagnifier: true,
                              onSelectedItemChanged: (index) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedHour = index;
                                });
                              },
                              children: List.generate(24, (h) {
                                return Center(
                                  child: Text(
                                    '${h.toString().padLeft(2, '0')} 时',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: _selectedHour == h
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: _selectedHour == h
                                          ? AppColors.anchorAccent
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const Text(
                            ':',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.anchorAccent,
                            ),
                          ),
                          Expanded(
                            child: CupertinoPicker(
                              scrollController: _minuteController,
                              itemExtent: 34,
                              magnification: 1.08,
                              useMagnifier: true,
                              onSelectedItemChanged: (index) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedMinute = index;
                                });
                              },
                              children: List.generate(60, (m) {
                                return Center(
                                  child: Text(
                                    '${m.toString().padLeft(2, '0')} 分',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: _selectedMinute == m
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: _selectedMinute == m
                                          ? AppColors.anchorAccent
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 4. 确认提交按钮
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.anchorAccent, AppColors.anchorAccent.withOpacity(0.85)],
                  ),
                  borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.anchorAccent.withOpacity(0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                    ),
                  ),
                  child: Text(
                    isEditing ? '保存修改' : '确认添加锚点',
                    style: AppTextStyles.button,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: widget.enableEntranceAnimation
          ? dialogChild.animate().scale(
              duration: 220.ms,
              curve: Curves.easeOutCubic,
            )
          : dialogChild,
    );
  }
}
