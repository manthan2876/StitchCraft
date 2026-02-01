import 'package:flutter/material.dart';
import 'package:stitchcraft/theme/app_theme.dart';

class GarmentSpecsScreen extends StatelessWidget {
  const GarmentSpecsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Customize Garment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _FeatureSelector(title: 'Collar Style', options: const ['Spread', 'Cutaway', 'Mandarin', 'Button-down']),
            const SizedBox(height: 24),
            _FeatureSelector(title: 'Cuff Style', options: const ['Single Button', 'Double Button', 'French', 'Straight']),
            const SizedBox(height: 24),
            _FeatureSelector(title: 'Placket', options: const ['Conventional', 'French', 'Fly', 'Hidden']),
            const SizedBox(height: 48),
             SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                   // Pass specs + previous order data to Fabric Capture
                   final specs = {'collar': 'Spread', 'cuff': 'Single Button'}; // Dummy for now, should collect real state if StatefulWidget
                   final fullData = {...orderData, ...specs};
                   Navigator.pushNamed(context, '/fabric_capture', arguments: fullData);
                },
                child: const Text('Next: Fabric Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureSelector extends StatefulWidget {
  final String title;
  final List<String> options;
  const _FeatureSelector({required this.title, required this.options});

  @override
  State<_FeatureSelector> createState() => _FeatureSelectorState();
}

class _FeatureSelectorState extends State<_FeatureSelector> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: widget.options.length,
          itemBuilder: (context, index) {
            final isSelected = _selectedIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedIndex = index),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300),
                ),
                child: Text(
                  widget.options[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
