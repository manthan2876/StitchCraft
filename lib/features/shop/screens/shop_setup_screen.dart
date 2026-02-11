import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/primary_button.dart';
import 'package:stitchcraft/core/widgets/voice_text_field.dart';

class ShopSetupScreen extends StatefulWidget {
  const ShopSetupScreen({super.key});

  @override
  State<ShopSetupScreen> createState() => _ShopSetupScreenState();
}

class _ShopSetupScreenState extends State<ShopSetupScreen> {
  final TextEditingController _shopNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Shop')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Profile Photo
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening Camera...')),
                );
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.navyBlue, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 40,
                  color: AppTheme.navyBlue,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add Profile Photo',
              style: AppTheme.masterjiTheme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            
            // Shop Name
            VoiceTextField(
              label: 'Shop Name (દુકાનનું નામ)',
              controller: _shopNameController,
              hint: 'Masterji Tailors',
              onMicTap: () {},
            ),
            
            const SizedBox(height: 48),
            PrimaryButton(
              text: 'Complete Setup',
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
          ],
        ),
      ),
    );
  }
}
