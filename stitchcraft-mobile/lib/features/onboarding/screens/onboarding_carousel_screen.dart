import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/primary_button.dart';

class OnboardingCarouselScreen extends StatefulWidget {
  const OnboardingCarouselScreen({super.key});

  @override
  State<OnboardingCarouselScreen> createState() => _OnboardingCarouselScreenState();
}

class _OnboardingCarouselScreenState extends State<OnboardingCarouselScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'ડિજિટલ માપ (Digital Measurements)',
      'subtitle': 'Save customer measurements digitally. No more lost notebooks!',
      'icon': 'ruler',
    },
    {
      'title': 'ઉધાર ટ્રેક (Track Credit)',
      'subtitle': 'Know exactly who owes you money. Send WhatsApp reminders.',
      'icon': 'notebook',
    },
    {
      'title': 'સ્ટાઇલ કેટલોગ (Style Catalog)',
      'subtitle': 'Show latest designs to customers and grow your business.',
      'icon': 'shirt',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text(
                    'SKIP (છોડો)',
                    style: TextStyle(
                      color: AppTheme.darkGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            
            // Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return _buildPage(
                    _onboardingData[index]['title']!,
                    _onboardingData[index]['subtitle']!,
                    index,
                  );
                },
              ),
            ),
            
            // Progressive Progress Bar (starts at 33% / 1 of 3)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentPage + 1) / _onboardingData.length,
                  backgroundColor: AppTheme.lightGrey,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.brandPurple),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Next Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: PrimaryButton(
                text: _currentPage == _onboardingData.length - 1 ? 'START (શરૂ કરો)' : 'NEXT (આગળ)',
                onPressed: () {
                  if (_currentPage < _onboardingData.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(String title, String subtitle, int index) {
    final theme = Theme.of(context);
    IconData iconData;
    switch (index) {
      case 0:
        iconData = Icons.straighten;
        break;
      case 1:
        iconData = Icons.book;
        break;
      case 2:
        iconData = Icons.checkroom;
        break;
      default:
        iconData = Icons.circle;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? const Color(0xFF1A2231),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              iconData,
              size: 80,
              color: AppTheme.brandPurple,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.darkGrey,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
