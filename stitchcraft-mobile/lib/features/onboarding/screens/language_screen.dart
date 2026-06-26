import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Select Language',
                style: AppTheme.masterjiTheme.textTheme.headlineMedium,
              ),
              Text(
                'તમારી ભાષા પસંદ કરો',
                style: AppTheme.masterjiTheme.textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _buildLanguageCard(
                      context,
                      'English',
                      'English',
                      true, // Active for demo
                    ),
                    _buildLanguageCard(
                      context,
                      'ગુજરાતી',
                      'Gujarati',
                      false,
                    ),
                    _buildLanguageCard(
                      context,
                      'हिंदी',
                      'Hindi',
                      false,
                    ),
                    _buildLanguageCard(
                      context,
                      'தமிழ்',
                      'Tamil',
                      false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard(BuildContext context, String nativeName, String englishName, bool isSelected) {
    return NeoCard(
      onTap: () {
        // Navigate to Onboarding
        Navigator.pushNamed(context, '/onboarding');
      },
      color: isSelected ? AppTheme.marigold.withValues(alpha: 0.1) : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nativeName,
                style: AppTheme.masterjiTheme.textTheme.headlineMedium?.copyWith(
                  fontSize: 22,
                ),
              ),
              Text(
                englishName,
                style: AppTheme.masterjiTheme.textTheme.bodyMedium,
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              // Play Audio
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Playing Audio Greeting...')),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.marigold,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.volume_up, color: AppTheme.navyBlue),
            ),
          ),
        ],
      ),
    );
  }
}
