import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';

class GarmentSpecsScreen extends StatefulWidget {
  const GarmentSpecsScreen({super.key});

  @override
  State<GarmentSpecsScreen> createState() => _GarmentSpecsScreenState();
}

class _GarmentSpecsScreenState extends State<GarmentSpecsScreen> {
  final Map<String, String> _selectedSpecs = {};
  List<String> _itemTypes = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final types = args['item_types'];
    if (types is List) {
      _itemTypes = types.map((e) => e.toString()).toList();
    } else if (types is String) {
      _itemTypes = [types];
    }
    
    // Initialize Defaults if empty
    if (_selectedSpecs.isEmpty) {
      if (_hasItem(['Shirt', 'Kurta'])) {
        _selectedSpecs['Collar'] = 'Spread';
        _selectedSpecs['Cuff'] = 'Single Button';
        _selectedSpecs['Placket'] = 'Conventional';
      }
      if (_hasItem(['Pant', 'Trouser'])) {
        _selectedSpecs['Pleats'] = 'None';
        _selectedSpecs['Pockets'] = 'Slant';
        _selectedSpecs['Fastening'] = 'Button';
      }
      if (_hasItem(['Suit', 'Jacket', 'Blazer'])) {
        _selectedSpecs['Lapel'] = 'Notch';
        _selectedSpecs['Vents'] = 'Double';
        _selectedSpecs['Buttons'] = 'Two Button';
      }
    }
  }

  bool _hasItem(List<String> keywords) {
    return _itemTypes.any((type) => keywords.contains(type));
  }

  @override
  Widget build(BuildContext context) {
    final orderData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Design Specifications')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_hasItem(['Shirt', 'Kurta'])) ...[
              _SectionHeader('Shirt / Kurta Details'),
              _FeatureSelector(
                title: 'Collar Style',
                options: const ['Spread', 'Cutaway', 'Mandarin', 'Button-down', 'Wing'],
                currentValue: _selectedSpecs['Collar'] ?? 'Spread',
                onChanged: (val) => setState(() => _selectedSpecs['Collar'] = val),
              ),
              const SizedBox(height: 16),
              _FeatureSelector(
                title: 'Cuff Style',
                options: const ['Single Button', 'Double Button', 'French', 'Round'],
                currentValue: _selectedSpecs['Cuff'] ?? 'Single Button',
                onChanged: (val) => setState(() => _selectedSpecs['Cuff'] = val),
              ),
              const SizedBox(height: 16),
              _FeatureSelector(
                title: 'Placket',
                options: const ['Conventional', 'French', 'Fly', 'Hidden'],
                currentValue: _selectedSpecs['Placket'] ?? 'Conventional',
                onChanged: (val) => setState(() => _selectedSpecs['Placket'] = val),
              ),
              const SizedBox(height: 32),
            ],

            if (_hasItem(['Pant', 'Trouser'])) ...[
              _SectionHeader('Pant Details'),
              _FeatureSelector(
                title: 'Pleats',
                options: const ['None', 'Single', 'Double'],
                currentValue: _selectedSpecs['Pleats'] ?? 'None',
                onChanged: (val) => setState(() => _selectedSpecs['Pleats'] = val),
              ),
              const SizedBox(height: 16),
              _FeatureSelector(
                title: 'Pockets',
                options: const ['Slant', 'Vertical', 'Western'],
                currentValue: _selectedSpecs['Pockets'] ?? 'Slant',
                onChanged: (val) => setState(() => _selectedSpecs['Pockets'] = val),
              ),
               const SizedBox(height: 32),
            ],

            if (_hasItem(['Suit', 'Jacket', 'Blazer'])) ...[
              _SectionHeader('Jacket Details'),
              _FeatureSelector(
                title: 'Lapel Style',
                options: const ['Notch', 'Peak', 'Shawl'],
                currentValue: _selectedSpecs['Lapel'] ?? 'Notch',
                onChanged: (val) => setState(() => _selectedSpecs['Lapel'] = val),
              ),
              const SizedBox(height: 16),
              _FeatureSelector(
                title: 'Vents',
                options: const ['None', 'Center', 'Double'],
                currentValue: _selectedSpecs['Vents'] ?? 'Double',
                onChanged: (val) => setState(() => _selectedSpecs['Vents'] = val),
              ),
               const SizedBox(height: 32),
            ],

          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
               final refinedData = {
                  ...orderData,
                  'styleAttributes': _selectedSpecs,
               };

               Navigator.pushNamed(context, '/fabric_capture', arguments: refinedData);
            },
            child: const Text('Next: Fabric Details'),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const Divider(),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _FeatureSelector extends StatelessWidget {
  final String title;
  final List<String> options;
  final String currentValue;
  final ValueChanged<String> onChanged;

  const _FeatureSelector({
    required this.title,
    required this.options,
    required this.currentValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          itemCount: options.length,
          itemBuilder: (context, index) {
            final option = options[index];
            final isSelected = currentValue == option;
            return GestureDetector(
              onTap: () => onChanged(option),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300),
                ),
                child: Text(
                  option,
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
