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
      'icon': 'ruler', // Placeholder for logic
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
    return Scaffold(
      backgroundColor: AppTheme.cream,
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
                  child: Text(
                    'SKIP (છોડો)',
                    style: AppTheme.masterjiTheme.textTheme.labelLarge?.copyWith(
                       color: Colors.grey,
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
            
            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingData.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? AppTheme.marigold : Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
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

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              iconData,
              size: 80,
              color: AppTheme.navyBlue,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTheme.masterjiTheme.textTheme.displayLarge?.copyWith(
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTheme.masterjiTheme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
