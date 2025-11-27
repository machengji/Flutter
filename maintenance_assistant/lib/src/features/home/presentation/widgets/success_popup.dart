import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  String _rainbowFart = '你今天闪闪发光！';
  final String _defaultFart = '你今天闪闪发光！';

  @override
  void initState() {
    super.initState();
    _loadRainbowFart();
  }

  Future<void> _loadRainbowFart() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedFart = prefs.getString('lastRainbowFart');
    
    if (cachedFart != null && cachedFart.isNotEmpty) {
      setState(() {
        _rainbowFart = cachedFart;
      });
    }

    // Fetch new one for next time (or immediate update if default)
    _fetchNewRainbowFart(prefs);
  }

  Future<void> _fetchNewRainbowFart(SharedPreferences prefs) async {
    try {
      final response = await http.get(Uri.parse('https://api.shadiao.pro/chp'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['data']['text'];
        if (text != null && text is String && text.isNotEmpty) {
          await prefs.setString('lastRainbowFart', text);
          
          // If currently showing default, update immediately
          if (_rainbowFart == _defaultFart && mounted) {
            setState(() {
              _rainbowFart = text;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch rainbow fart: $e');
    }
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
        // Backdrop
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ).animate().fadeIn(duration: 300.ms),
          ),
        ),

        // Fireworks (Simple Particles)
        ...List.generate(15, (index) => _FireworkParticle(delay: index * 100)),

        // Card
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85, // Wider width
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
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
                // Icon
                Transform.translate(
                  offset: const Offset(0, -60),
                  child: Container(
                    width: 80,
                    height: 80,
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
                      child: Text('🎉', style: TextStyle(fontSize: 40)),
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: -10, duration: 2.seconds),

                Transform.translate(
                  offset: const Offset(0, -30),
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
                      const SizedBox(height: 20),
                      
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
                      const SizedBox(height: 24),

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
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
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

class _FireworkParticle extends StatelessWidget {
  final int delay;

  const _FireworkParticle({required this.delay});

  @override
  Widget build(BuildContext context) {
    final random = Random();
    final left = random.nextDouble() * MediaQuery.of(context).size.width;
    final top = random.nextDouble() * MediaQuery.of(context).size.height / 2;
    final color = HSLColor.fromAHSL(1, random.nextDouble() * 360, 0.8, 0.6).toColor();
    final size = random.nextDouble() * 8 + 4;

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: size * 2,
            ),
          ],
        ),
      ).animate(
        onPlay: (controller) => controller.repeat(),
      ).scale(
        duration: 1.seconds,
        begin: const Offset(0, 0),
        end: const Offset(1, 1),
        delay: delay.ms,
      ).fadeOut(
        duration: 1.seconds,
        delay: delay.ms,
      ),
    );
  }
}
