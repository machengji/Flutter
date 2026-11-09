import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  late String _repeatMode; // 'daily', 'workdays', 'weekends', 'custom'
  late Set<int> _selectedDays;
  final FocusNode _focusNode = FocusNode();

  static const List<Map<String, String>> _modeOptions = [
    {'key': 'daily', 'label': '每天'},
    {'key': 'workdays', 'label': '工作日'},
    {'key': 'weekends', 'label': '休息日'},
    {'key': 'custom', 'label': '自定义'},
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
    {'label': '午休 12:30', 'hour': 12, 'minute': 30},
    {'label': '下班 18:30', 'hour': 18, 'minute': 30},
    {'label': '睡前 22:00', 'hour': 22, 'minute': 0},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);

    if (widget.initialTime != null && widget.initialTime!.contains(':')) {
      final parts = widget.initialTime!.split(':');
      _selectedHour = int.tryParse(parts[0]) ?? 8;
      _selectedMinute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    } else {
      _selectedHour = 8;
      _selectedMinute = 0;
    }

    _repeatMode = widget.initialRepeatMode ?? 'daily';
    final initDays = widget.initialCustomDays ?? const [1, 2, 3, 4, 5, 6, 7];
    _selectedDays = initDays.where((d) => d >= 1 && d <= 7).toSet();
    if (_selectedDays.isEmpty) {
      _selectedDays = {1, 2, 3, 4, 5, 6, 7};
    }

    if (widget.autofocusEnabled && widget.initialName == null) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _applyQuickTime(int hour, int minute) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedHour = hour;
      _selectedMinute = minute;
    });
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
      return '每天（周一至周日）';
    }
    if (_repeatMode == 'workdays' ||
        (sorted.length == 5 && _selectedDays.containsAll(const [1, 2, 3, 4, 5]))) {
      return '仅工作日（周一至周五）';
    }
    if (_repeatMode == 'weekends' ||
        (sorted.length == 2 && _selectedDays.containsAll(const [6, 7]))) {
      return '仅休息日（周六、周日）';
    }
    const names = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '每${sorted.map((d) => names[d]).join('、')}';
  }

  Future<void> _pickTimeFromSystem() async {
    HapticFeedback.selectionClick();
    final initial = TimeOfDay(hour: _selectedHour, minute: _selectedMinute);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: '选择锚点触发时间',
      cancelText: '取消',
      confirmText: '确定',
      hourLabelText: '小时',
      minuteLabelText: '分钟',
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('zh', 'CN'),
          child: Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.anchorAccent,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child ?? const SizedBox(),
          ),
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedHour = picked.hour;
        _selectedMinute = picked.minute;
      });
    }
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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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

              // 2. 中文重复日期选择（快捷预设 + 中文周一至周日点选）
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
                          '重复日期',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.anchorAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _currentRepeatSummary,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.anchorAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 快捷模式切换：每天 / 工作日 / 休息日 / 自定义
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
                              child: Container(
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
                    // 中文「周一 ~ 周日」直接点击切换
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
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppColors.anchorAccent.withOpacity(0.18)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: active
                                        ? AppColors.anchorAccent
                                        : AppColors.anchorAccent.withOpacity(0.18),
                                    width: active ? 1.4 : 1.0,
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

              // 3. 中文时间直选与常用时间
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
                          '触发时间',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _pickTimeFromSystem,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.anchorAccent.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '自定义时钟',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.anchorAccent,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const AppIcon(
                                  type: AppIconType.edit,
                                  size: 12,
                                  color: AppColors.anchorAccent,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 大号中文时间点击面板
                    GestureDetector(
                      onTap: _pickTimeFromSystem,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.anchorAccent.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              formattedTime,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppColors.anchorAccent,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.anchorAccent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _selectedHour < 12 ? '上午' : (_selectedHour < 18 ? '下午' : '晚上'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.anchorAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 常用快捷时间胶囊
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
                                  vertical: 6,
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
  }
}
