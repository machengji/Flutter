import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/models/plan_model.dart';

import 'package:flutter/services.dart';

class PlanCard extends StatefulWidget {
  final Plan plan;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;
  final VoidCallback onPin;
  final VoidCallback onEdit;
  final VoidCallback onDetail;
  final VoidCallback? onAddToReminders;
  final VoidCallback? onShare;
  final VoidCallback? onArchive;
  final String? parentPlanName;
  final int subCompletedCount;
  final int subTotalCount;
  final List<Plan> directSubPlans;
  final ValueChanged<String>? onAddSubPlan;
  final ValueChanged<String>? onToggleSubPlan;
  final ValueChanged<String>? onDeleteSubPlan;
  final ValueChanged<String>? onTapSubPlan;

  const PlanCard({
    super.key,
    required this.plan,
    required this.isExpanded,
    required this.onTap,
    required this.onToggleStatus,
    required this.onDelete,
    required this.onPin,
    required this.onEdit,
    required this.onDetail,
    this.onAddToReminders,
    this.onShare,
    this.onArchive,
    this.parentPlanName,
    this.subCompletedCount = 0,
    this.subTotalCount = 0,
    this.directSubPlans = const [],
    this.onAddSubPlan,
    this.onToggleSubPlan,
    this.onDeleteSubPlan,
    this.onTapSubPlan,
  });

  static final DateFormat _dateFormatter = DateFormat('yyyy/MM/dd');

  @override
  State<PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<PlanCard> {
  late final TextEditingController _subController;
  late final FocusNode _subFocusNode;
  bool _hasDraft = false;

  @override
  void initState() {
    super.initState();
    _subController = TextEditingController();
    _subFocusNode = FocusNode();
    _subController.addListener(_handleDraftChanged);
  }

  void _handleDraftChanged() {
    final nextHasDraft = _subController.text.trim().isNotEmpty;
    if (nextHasDraft != _hasDraft && mounted) {
      setState(() {
        _hasDraft = nextHasDraft;
      });
    }
  }

  @override
  void didUpdateWidget(covariant PlanCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpanded && !widget.isExpanded) {
      _subFocusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _subController.removeListener(_handleDraftChanged);
    _subController.dispose();
    _subFocusNode.dispose();
    super.dispose();
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return '今天';
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return PlanCard._dateFormatter.format(date);
  }

  void _submitSubPlan() {
    final trimmed = _subController.text.trim();
    if (trimmed.isEmpty) {
      _subFocusNode.unfocus();
      return;
    }
    if (widget.onAddSubPlan != null) {
      HapticFeedback.selectionClick();
      widget.onAddSubPlan!(trimmed);
      _subController.clear();
      _subFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final isCompleted = plan.status == '已完成';
    final isArchived = plan.status == '已归档';
    final hasSubProgress = widget.subTotalCount > 0;
    final allSubsDone =
        hasSubProgress && widget.subCompletedCount >= widget.subTotalCount;
    final hasParentTag =
        widget.parentPlanName != null && widget.parentPlanName!.isNotEmpty;
    final showSubInput = !isCompleted && widget.onAddSubPlan != null;
    final showSubList = widget.directSubPlans.isNotEmpty;

    return RepaintBoundary(
      child: Container(
        decoration: AppDecorations.planCardDecoration,
        child: Column(
          children: [
            GestureDetector(
              onTap: widget.onTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Row(
                  children: [
                    // 森系新芽打卡框
                    GestureDetector(
                      onTap: widget.onToggleStatus,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.only(right: 12),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: isCompleted ? AppColors.primaryGradient : null,
                          color: isCompleted
                              ? null
                              : (isArchived
                                  ? AppColors.surfaceVariant
                                  : AppColors.primary.withOpacity(0.05)),
                          border: Border.all(
                            color: isCompleted
                                ? AppColors.primary
                                : (isArchived
                                    ? AppColors.textSecondary.withOpacity(0.25)
                                    : AppColors.primary.withOpacity(0.24)),
                            width: 1.6,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: isCompleted
                              ? const AppIcon(
                                  type: AppIconType.check,
                                  size: 22,
                                  color: Colors.white,
                                )
                              : (isArchived
                                  ? const AppIcon(
                                      type: AppIconType.archive,
                                      size: 20,
                                      color: AppColors.textHint,
                                    )
                                  : AppIcon(
                                      type: AppIconType.plan,
                                      size: 20,
                                      color: AppColors.primary.withOpacity(0.38),
                                    )),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  plan.name,
                                  style: AppTextStyles.cardTitle.copyWith(
                                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                                    color: isCompleted
                                        ? AppColors.textSecondary
                                        : (isArchived ? AppColors.textSecondary : AppColors.textPrimary),
                                  ),
                                ),
                              ),
                              if (hasSubProgress)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: allSubsDone
                                        ? AppColors.primary.withOpacity(0.14)
                                        : AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: allSubsDone
                                          ? AppColors.primary.withOpacity(0.3)
                                          : AppColors.textHint.withOpacity(0.22),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    '${widget.subCompletedCount}/${widget.subTotalCount}',
                                    style: AppTextStyles.badge.copyWith(
                                      fontSize: 10.5,
                                      color: allSubsDone
                                          ? AppColors.primaryDark
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              if (isArchived)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.warning.withOpacity(0.22),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const AppIcon(
                                        type: AppIconType.archive,
                                        size: 11,
                                        color: AppColors.warning,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '暂非重点',
                                        style: AppTextStyles.badge.copyWith(
                                          fontSize: 10,
                                          color: AppColors.warning,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                isCompleted
                                    ? '完成于 ${_formatDate(plan.completeTime ?? 0)}'
                                    : _formatDate(plan.createTime),
                                style: AppTextStyles.cardSubtitle,
                              ),
                              if (plan.groupColorIndex >= 0 && plan.decompositionLevel > 0) ...[
                                const SizedBox(width: 8),
                                ...List.generate(
                                  plan.decompositionLevel.clamp(1, 5),
                                  (index) {
                                    final colorIndex =
                                        plan.groupColorIndex % AppColors.groupColors.length;
                                    final baseColor = AppColors.groupColors[colorIndex];
                                    return Container(
                                      margin: const EdgeInsets.only(right: 4),
                                      width: 6.5,
                                      height: 6.5,
                                      decoration: BoxDecoration(
                                        color: baseColor.withOpacity(0.88 - (index * 0.1)),
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  },
                                ),
                              ],
                              if (hasParentTag) ...[
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      widget.parentPlanName!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.cardSubtitle.copyWith(
                                        fontSize: 11,
                                        color: AppColors.primaryDark.withOpacity(0.85),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: widget.isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const AppIcon(
                        type: AppIconType.chevronRight,
                        size: 20,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: widget.isExpanded
                  ? Container(
                      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF4F0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFDCE8E0).withOpacity(0.7),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showSubList) ...[
                            ...widget.directSubPlans.map((sub) {
                              final subDone = sub.status == '已完成';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.76),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.10),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: widget.onToggleSubPlan != null
                                            ? () => widget.onToggleSubPlan!(sub.id)
                                            : null,
                                        behavior: HitTestBehavior.opaque,
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          margin: const EdgeInsets.only(right: 9),
                                          decoration: BoxDecoration(
                                            gradient: subDone ? AppColors.primaryGradient : null,
                                            color: subDone
                                                ? null
                                                : AppColors.primary.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: subDone
                                                  ? AppColors.primary
                                                  : AppColors.primary.withOpacity(0.32),
                                              width: 1.3,
                                            ),
                                          ),
                                          child: subDone
                                              ? const Center(
                                                  child: AppIcon(
                                                    type: AppIconType.check,
                                                    size: 12,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : null,
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: widget.onTapSubPlan != null
                                              ? () => widget.onTapSubPlan!(sub.id)
                                              : null,
                                          behavior: HitTestBehavior.opaque,
                                          child: Text(
                                            sub.name,
                                            style: AppTextStyles.bodyMedium.copyWith(
                                              fontSize: 13.5,
                                              decoration: subDone
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              color: subDone
                                                  ? AppColors.textHint
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (widget.onDeleteSubPlan != null)
                                        GestureDetector(
                                          onTap: () => widget.onDeleteSubPlan!(sub.id),
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
                          if (showSubInput) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.92),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.18),
                                  width: 0.9,
                                ),
                              ),
                              child: Row(
                                children: [
                                  AppIcon(
                                    type: AppIconType.add,
                                    size: 16,
                                    color: AppColors.primary.withOpacity(0.75),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _subController,
                                      focusNode: _subFocusNode,
                                      textInputAction: TextInputAction.done,
                                      onEditingComplete: () {},
                                      onSubmitted: (_) => _submitSubPlan(),
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontSize: 13.5,
                                        color: AppColors.textPrimary,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '添加子任务',
                                        hintStyle: AppTextStyles.bodySmall.copyWith(
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
                                      onTap: _submitSubPlan,
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        margin: const EdgeInsets.only(left: 6),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: AppIcon(
                                            type: AppIconType.check,
                                            size: 13,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _ActionButton(
                                icon: AppIconType.explore,
                                color: const Color(0xFF2D6A4F),
                                onTap: widget.onDetail,
                              ),
                              if (!isCompleted && widget.onAddToReminders != null)
                                _ActionButton(
                                  icon: AppIconType.notification,
                                  color: const Color(0xFF4A7862),
                                  onTap: widget.onAddToReminders!,
                                ),
                              if (isCompleted && widget.onShare != null)
                                _ActionButton(
                                  icon: AppIconType.share,
                                  color: const Color(0xFF2D6A4F),
                                  onTap: widget.onShare!,
                                ),
                              _ActionButton(
                                icon: AppIconType.edit,
                                color: const Color(0xFF5A6D62),
                                onTap: widget.onEdit,
                              ),
                              _ActionButton(
                                icon: AppIconType.pin,
                                color: const Color(0xFFB57632),
                                onTap: widget.onPin,
                              ),
                              if (widget.onArchive != null)
                                _ActionButton(
                                  icon: AppIconType.archive,
                                  color: isArchived
                                      ? const Color(0xFF2D6A4F)
                                      : const Color(0xFF6E5D4F),
                                  isHighlighted: isArchived,
                                  onTap: widget.onArchive!,
                                ),
                              _ActionButton(
                                icon: isCompleted ? AppIconType.refresh : AppIconType.check,
                                color: const Color(0xFF2D6A4F),
                                onTap: widget.onToggleStatus,
                              ),
                              _ActionButton(
                                icon: AppIconType.delete,
                                color: const Color(0xFFB55A52),
                                isDanger: true,
                                onTap: widget.onDelete,
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final AppIconType icon;
  final Color color;
  final bool isDanger;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    this.isDanger = false,
    this.isHighlighted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isDanger ? const Color(0xFFB55A52) : color;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isHighlighted
              ? effectiveColor.withOpacity(0.14)
              : (isDanger
                  ? effectiveColor.withOpacity(0.08)
                  : Colors.white.withOpacity(0.72)),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: effectiveColor.withOpacity(isHighlighted ? 0.25 : 0.12),
            width: 0.9,
          ),
        ),
        child: Center(
          child: AppIcon(
            type: icon,
            color: effectiveColor,
            size: 19,
          ),
        ),
      ),
    );
  }
}
