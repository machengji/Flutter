import 'package:flutter/material.dart';
import 'add_modal.dart';
import 'app_drawer.dart';

class ShaderWarmupWidget extends StatefulWidget {
  final VoidCallback onWarmupComplete;

  const ShaderWarmupWidget({super.key, required this.onWarmupComplete});

  @override
  State<ShaderWarmupWidget> createState() => _ShaderWarmupWidgetState();
}

class _ShaderWarmupWidgetState extends State<ShaderWarmupWidget> {
  @override
  void initState() {
    super.initState();
    // Delay to ensure the frame is rendered and shaders are compiled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          widget.onWarmupComplete();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Render components off-screen or transparently to force shader compilation
    return Opacity(
      opacity: 0.001,
      child: IgnorePointer(
        child: Stack(
          children: [
            // Warmup AppDrawer (Sidebar)
            const Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 300, // Typical drawer width
              child: AppDrawer(),
            ),
            
            // Warmup AddModal (Dialog with shadows and blurs)
            Center(
              child: AddModal(
                title: 'Warmup', 
                placeholder: 'Warmup', 
                onConfirm: (_) {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
