import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ImmersiveBackground extends StatelessWidget {
  const ImmersiveBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF2F2F7),
                Color(0xFFE5E5EA),
              ],
            ),
          ),
        ),
        
        // Orb 1 (Top Left - Blue)
        Positioned(
          top: -150,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF007AFF).withOpacity(0.08),
                  const Color(0xFF007AFF).withOpacity(0.04),
                  Colors.transparent,
                ],
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .move(duration: 12.seconds, begin: const Offset(0, 0), end: const Offset(20, -40)),
        ),

        // Orb 2 (Top Right - Purple)
        Positioned(
          top: 150,
          right: -75,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF5856D6).withOpacity(0.06),
                  const Color(0xFF5856D6).withOpacity(0.03),
                  Colors.transparent,
                ],
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .move(duration: 10.seconds, begin: const Offset(0, 0), end: const Offset(-10, 20)),
        ),

        // Orb 3 (Bottom Center - Green)
        Positioned(
          bottom: -125,
          left: MediaQuery.of(context).size.width / 2 - 125,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF34C759).withOpacity(0.05),
                  const Color(0xFF34C759).withOpacity(0.02),
                  Colors.transparent,
                ],
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .move(duration: 15.seconds, begin: const Offset(0, 0), end: const Offset(0, -30)),
        ),

        // Light Rays (Subtle overlay)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.3, -0.8),
                radius: 1.5,
                colors: [
                  Colors.white.withOpacity(0.4),
                  Colors.transparent,
                ],
                stops: const [0, 0.4],
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scale(duration: 20.seconds, begin: const Offset(1, 1), end: const Offset(1.05, 1.05)),
        ),
      ],
    );
  }
}
