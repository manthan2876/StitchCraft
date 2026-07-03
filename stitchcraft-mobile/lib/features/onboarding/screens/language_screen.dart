import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Select Language',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'તમારી ભાષા પસંદ કરો',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.darkGrey,
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
                      true,
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
    final theme = Theme.of(context);

    return NeoCard(
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
        final String? token = prefs.getString('token');

        if (context.mounted) {
          if (isLoggedIn && token != null && token.isNotEmpty) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          } else {
            Navigator.pushNamed(context, '/onboarding');
          }
        }
      },
      color: isSelected ? AppTheme.brandPurple.withValues(alpha: 0.15) : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nativeName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                englishName,
                style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkGrey),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Playing Audio Greeting...')),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.brandPurple,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.volume_up, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
