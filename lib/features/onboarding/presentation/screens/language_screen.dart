import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLanguage = 'English';

  final List<Map<String, String>> _languages = [
    {'name': 'Arabic', 'flag': '🇸🇦'},
    {'name': 'English', 'flag': '🇺🇸'},
    {'name': 'Urdu', 'flag': '🇵🇰'},
    {'name': 'Hindi', 'flag': '🇮🇳'},
    {'name': 'Srilanka', 'flag': '🇱🇰'},
    {'name': 'Italian', 'flag': '🇮🇹'},
    {'name': 'Australian', 'flag': '🇦🇺'},
    {'name': 'Turkish', 'flag': '🇹🇷'},
    {'name': 'Bangladesh', 'flag': '🇧🇩'},
  ];

  Future<void> _continue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenLanguage', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Text(
                'Choose Language',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Find a language',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _languages.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final lang = _languages[index];
                    final isSelected = lang['name'] == _selectedLanguage;
                    
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedLanguage = lang['name']!;
                        });
                      },
                      child: Container(
                        color: isSelected ? const Color(0xFFE3F2FD) : Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                        child: Row(
                          children: [
                            Text(
                              lang['flag']!,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                lang['name']!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_outline,
                                color: AppTheme.primaryColor,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _continue,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Get Started'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
