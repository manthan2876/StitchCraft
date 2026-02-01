import 'package:flutter/material.dart';
import 'package:stitchcraft/theme/app_theme.dart';
import '../../models/customer_model.dart';

class MeasurementSelectorScreen extends StatelessWidget {
  const MeasurementSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customer = ModalRoute.of(context)?.settings.arguments as Customer?;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Select Template')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _TemplateCard(
              title: 'Men',
              icon: Icons.man,
              onTap: () => Navigator.pushNamed(context, '/visual_measurement', arguments: {'customer': customer, 'category': 'Men'}),
            ),
            const SizedBox(height: 16),
            _TemplateCard(
              title: 'Women',
              icon: Icons.woman,
              onTap: () => Navigator.pushNamed(context, '/visual_measurement', arguments: {'customer': customer, 'category': 'Women'}),
            ),

          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _TemplateCard({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 24),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
