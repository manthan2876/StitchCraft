import 'package:flutter/material.dart';

class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialButton(
          label: 'G',
          color: Colors.white,
          textColor: Colors.red, // Google Red ish
          assetName: null, 
          // If you have SVG assets, use them here. For now using text/icon placeholders.
        ),
        const SizedBox(width: 16),
        _buildSocialButton(
          label: 'f',
          color: Colors.white,
          textColor: const Color(0xFF1877F2), // Facebook Blue
          assetName: null,
        ),
        const SizedBox(width: 16),
        _buildSocialButton(
          label: '',
          color: Colors.white,
          textColor: Colors.black,
          assetName: null,
        ),
        const SizedBox(width: 16),
        _buildSocialButton(
          label: '🐦', 
          color: Colors.white,
          textColor: const Color(0xFF1DA1F2), // Twitter Blue
          assetName: null,
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String label,
    required Color color,
    required Color textColor,
    String? assetName,
  }) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Social Auth Logic
          },
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
