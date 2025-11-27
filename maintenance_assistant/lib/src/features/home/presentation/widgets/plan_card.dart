import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../shared/models/plan_model.dart';

class PlanCard extends StatelessWidget {
  final Plan plan;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;
  final VoidCallback onPin;
  final VoidCallback onEdit;
  final VoidCallback onDetail;

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
  });

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return '今天';
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return DateFormat('yyyy/MM/dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = plan.status == '已完成';

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF8F9FA)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF007AFF).withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF007AFF).withOpacity(0.08),
                  offset: const Offset(0, 2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                // Checkbox
                GestureDetector(
                  onTap: onToggleStatus,
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted ? const Color(0xFF007AFF) : Colors.white,
                      border: Border.all(
                        color: isCompleted ? const Color(0xFF007AFF) : const Color(0xFFD1D1D6),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
                
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isCompleted
                            ? '完成于 ${_formatDate(plan.completeTime ?? 0)}'
                            : _formatDate(plan.createTime),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF86868B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Chevron
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: 200.ms,
                  child: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFC7C7CC),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

        // Actions
        AnimatedSize(
          duration: 300.ms,
          child: isExpanded
              ? Container(
                  margin: const EdgeInsets.only(top: 0, bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ActionButton(
                        icon: Icons.list,
                        color: const Color(0xFF007AFF),
                        onTap: onDetail,
                      ),
                      _ActionButton(
                        icon: Icons.edit,
                        color: const Color(0xFF007AFF),
                        onTap: onEdit,
                      ),
                      _ActionButton(
                        icon: Icons.push_pin,
                        color: const Color(0xFF007AFF),
                        onTap: onPin,
                      ),
                      _ActionButton(
                        icon: isCompleted ? Icons.refresh : Icons.check,
                        color: isCompleted ? const Color(0xFFFF9500) : const Color(0xFF34C759),
                        onTap: onToggleStatus,
                      ),
                      _ActionButton(
                        icon: Icons.delete,
                        color: const Color(0xFFFF3B30),
                        isDanger: true,
                        onTap: onDelete,
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isDanger;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    this.isDanger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDanger ? const Color(0xFFFFF5F5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDanger ? const Color(0xFFFF3B30).withOpacity(0.2) : const Color(0xFF007AFF).withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: isDanger ? const Color(0xFFFF3B30).withOpacity(0.05) : const Color(0xFF007AFF).withOpacity(0.05),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
