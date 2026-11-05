import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/localization_service.dart';
import 'package:stitchcraft/core/services/auth_service.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  final _loc = LocalizationService();
  String _selectedLang = 'en';
  bool _isChanging = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    await _loc.loadLanguage();
    if (mounted) {
      setState(() {
        _selectedLang = _loc.currentLanguage;
      });
    }
  }

  String _getTitle() {
    switch (_selectedLang) {
      case 'gu':
        return 'ભાષા સેટિંગ્સ';
      case 'hi':
        return 'भाषा सेटिंग्स';
      case 'en':
      default:
        return 'Language Settings';
    }
  }

  String _getHeading() {
    switch (_selectedLang) {
      case 'gu':
        return 'તમારી ભાષા પસંદ કરો';
      case 'hi':
        return 'अपनी भाषा चुनें';
      case 'en':
      default:
        return 'Select Language';
    }
  }

  String _getContinueText() {
    switch (_selectedLang) {
      case 'gu':
        return 'આગળ વધો';
      case 'hi':
        return 'आगे बढ़ें';
      case 'en':
      default:
        return 'Continue';
    }
  }

  String _getLanguageUpdatedText(String code) {
    switch (code) {
      case 'gu':
        return 'ભાષા ગુજરાતીમાં બદલાઈ ગઈ છે';
      case 'hi':
        return 'भाषा बदलकर हिंदी कर दी गई है';
      case 'en':
      default:
        return 'Language changed to English';
    }
  }

  Future<void> _changeLanguage(String code) async {
    if (_isChanging) return;
    setState(() {
      _selectedLang = code;
      _isChanging = true;
    });

    try {
      await _loc.setLanguage(code);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_selected_language', true);

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getLanguageUpdatedText(code)),
          duration: const Duration(seconds: 2),
          backgroundColor: AppTheme.brandPurple,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // If opened from inside the app (e.g. Settings or Drawer), smoothly pop back after user sees checkmark
      if (Navigator.canPop(context)) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChanging = false;
        });
      }
    }
  }

  Future<void> _proceedFromOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_selected_language', true);
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final String? token = await AuthService().getToken();

    if (!mounted) return;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: Navigator.canPop(context)
          ? AppBar(
              title: Text(_getTitle()),
              leading: IconButton(
                icon: const BackButtonIcon(),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                _getHeading(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'English • ગુજરાતી • हिंदी',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.brandPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _buildLanguageCard(context, 'English', 'English', 'en'),
                    _buildLanguageCard(context, 'ગુજરાતી', 'Gujarati', 'gu'),
                    _buildLanguageCard(context, 'हिंदी', 'Hindi', 'hi'),
                  ],
                ),
              ),
              if (!Navigator.canPop(context)) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandPurple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isChanging ? null : _proceedFromOnboarding,
                    child: Text(
                      _getContinueText(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard(
    BuildContext context,
    String nativeName,
    String englishName,
    String code,
  ) {
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
                    color: isSelected
                        ? AppTheme.brandPurple
                        : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  englishName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.darkGrey,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check_circle,
              color: AppTheme.brandPurple,
              size: 28,
            )
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
