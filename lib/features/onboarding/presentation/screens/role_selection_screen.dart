import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Select Role'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RoleCard(
              title: 'Admin',
              icon: Icons.admin_panel_settings_outlined,
              onTap: () => Navigator.pushReplacementNamed(context, '/home'), // Go to Admin Dashboard
            ),
            const SizedBox(height: 24),
            _RoleCard(
              title: 'Staff / Karigar',
              icon: Icons.badge_outlined,
              onTap: () => Navigator.pushReplacementNamed(context, '/staff_dashboard'), // Go to Staff Dashboard
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleCard({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
             BoxShadow(
               color: Colors.black.withValues(alpha: 0.05),
               blurRadius: 10,
               offset: const Offset(0, 4),
             )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
