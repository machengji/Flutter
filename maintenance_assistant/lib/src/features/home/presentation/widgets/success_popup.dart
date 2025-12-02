import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    // Get data from provider
    _rainbowFart = context.read<HomeProvider>().rainbowFart;
  }

  void _copyDescription() {
    Clipboard.setData(ClipboardData(text: _rainbowFart));
    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(content: Text('文案已复制'), duration: Duration(seconds: 1)),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Backdrop - 直接显示,无动画
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),
        ),

        // Card - 只保留核心缩放动画
        Center(
          child: RepaintBoundary(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85, // Wider width
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24), // 减少上下边距，更紧凑
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon - 移除浮动动画，减少持续重绘
                  Transform.translate(
                    offset: const Offset(0, -50), // 减少向上偏移
                    child: Container(
                      width: 70, // 略微减小
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('🎉', style: TextStyle(fontSize: 36)),
                      ),
                    ),
                  ),

                  Transform.translate(
                    offset: const Offset(0, -25), // 减少向上偏移
                    child: Column(
                      children: [
                        const Text(
                          '太棒了！',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF9F0A),
                          ),
                        ),
                        const SizedBox(height: 12), // 减少间距
                        
                        // Quote Box
                        GestureDetector(
                          onTap: _copyDescription,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFF5F7), Color(0xFFFFF0F5)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFFB6C1).withOpacity(0.3)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _rainbowFart,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.copy, size: 12, color: Color(0xFF999999)),
                                    SizedBox(width: 4),
                                    Text(
                                      '点此复制',
                                      style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16), // 减少间距

                        // Stats
                        Row(
                          children: [
                            Expanded(
                              child: _StatItem(
                                label: '成就徽章',
                                value: widget.type == 'dream' ? '梦想家 🏅' : '行动派 ⚡',
                                valueColor: const Color(0xFFFF9F0A),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatItem(
                                label: '本次记录',
                                value: widget.description.length > 4 
                                    ? '${widget.description.substring(0, 4)}...' 
                                    : widget.description,
                                valueColor: const Color(0xFF007AFF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              _copyDescription();
                              widget.onClose();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF9A9E),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                              elevation: 4,
                              shadowColor: const Color(0xFFFF9A9E).withOpacity(0.4),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('✌️', style: TextStyle(fontSize: 18)),
                                SizedBox(width: 8),
                                Text(
                                  '收下这份喜悦',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate()
            .fadeIn(duration: 250.ms, curve: Curves.easeOut)
            .slideY(begin: 0.1, end: 0, duration: 250.ms, curve: Curves.easeOut),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF909399)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
