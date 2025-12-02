import 'package:flutter/material.dart';
import 'setting_sheet.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _showSettingSheet(BuildContext context) {
    Navigator.pop(context); // Close drawer first
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SettingSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: RepaintBoundary(
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RepaintBoundary(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        // Removed shadow for performance
                      ),
                      child: const Center(
                        child: Text('🚀', style: TextStyle(fontSize: 32)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '微行动',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '让改变发生',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF86868B),
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _DrawerItem(
                    icon: Icons.import_export,
                    label: '数据管理',
                    onTap: () => _showSettingSheet(context),
                  ),
                  // Add more items here if needed
                  // _DrawerItem(icon: Icons.info_outline, label: '关于', onTap: () {}),
                ],
              ),
            ),
            
            // Footer
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'v1.0.0',
                style: TextStyle(color: Colors.black.withOpacity(0.2), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1D1D1F), size: 22),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1D1D1F),
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      horizontalTitleGap: 12,
    );
  }
}
