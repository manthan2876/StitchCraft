import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/localization_service.dart';
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  final _loc = LocalizationService();
  String _selectedLang = 'en';

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    await _loc.loadLanguage();
    setState(() {
      _selectedLang = _loc.currentLanguage;
    });
  }

  Future<void> _changeLanguage(String code) async {
    await _loc.setLanguage(code);
    setState(() {
      _selectedLang = code;
    });

    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final String? token = prefs.getString('token');

    if (mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: Navigator.canPop(context) ? AppBar(title: Text(context.loc.language_settings)) : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                context.loc.select_language,
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
                      'en',
                    ),
                    _buildLanguageCard(
                      context,
                      'ગુજરાતી',
                      'Gujarati',
                      'gu',
                    ),
                    _buildLanguageCard(
                      context,
                      'हिंदी',
                      'Hindi',
                      'hi',
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

  Widget _buildLanguageCard(BuildContext context, String nativeName, String englishName, String code) {
    final theme = Theme.of(context);
    final isSelected = _selectedLang == code;

    return NeoCard(
      onTap: () => _changeLanguage(code),
      color: isSelected ? AppTheme.brandPurple.withValues(alpha: 0.15) : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nativeName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppTheme.brandPurple : Colors.white,
                  ),
                ),
                Text(
                  englishName,
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkGrey),
                ),
              ],
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle, color: AppTheme.brandPurple, size: 28)
          else
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
