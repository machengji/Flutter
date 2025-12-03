import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../shared/models/habit_model.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onCheck;
  final VoidCallback onDelete;
  final VoidCallback onPin;
  final VoidCallback onToggleStatus;
  final VoidCallback onDetail;
  final VoidCallback onEdit;

  const HabitCard({
    super.key,
    required this.habit,
    required this.isExpanded,
    required this.onTap,
    required this.onCheck,
    required this.onDelete,
    required this.onPin,
    required this.onToggleStatus,
    required this.onDetail,
    required this.onEdit,
  });

  String _formatDate(int timestamp) {
    if (timestamp == 0) return '从未';
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
    final isStopped = habit.status == '已停用';
    final lastCompleteTime = habit.completionHistory.isNotEmpty ? habit.completionHistory.last : 0;

    return Container(
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
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Checkbox / Count
                  GestureDetector(
                    onTap: isStopped ? null : onCheck,
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isStopped 
                            ? const Color(0xFF8E8E93).withOpacity(0.1) 
                            : (habit.totalDays > 0 ? const Color(0xFF34C759) : Colors.white),
                        border: Border.all(
                          color: isStopped 
                              ? const Color(0xFF8E8E93).withOpacity(0.3)
                              : (habit.totalDays > 0 ? const Color(0xFF34C759) : const Color(0xFFD1D1D6)),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: habit.totalDays > 0
                            ? Text(
                                '${habit.totalDays}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isStopped ? const Color(0xFF8E8E93) : const Color(0xFF1D1D1F),
                            decoration: isStopped ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isStopped
                              ? '已停用'
                              : '最近完成: ${_formatDate(lastCompleteTime)}',
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
          ),

          // Actions
          AnimatedSize(
            duration: 300.ms,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Container(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ActionButton(
                          icon: Icons.edit,
                          color: const Color(0xFF007AFF),
                          onTap: onEdit,
                        ),
                        _ActionButton(
                          icon: Icons.list,
                          color: const Color(0xFF007AFF),
                          onTap: onDetail,
                        ),
                        _ActionButton(
                          icon: Icons.push_pin,
                          color: const Color(0xFF007AFF),
                          onTap: onPin,
                        ),
                        _ActionButton(
                          icon: isStopped ? Icons.play_arrow : Icons.pause,
                          color: const Color(0xFFFF9500),
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
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
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
