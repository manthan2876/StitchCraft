import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';

class GarmentSelectorGrid extends StatelessWidget {
  final String? selectedType;
  final Function(String) onSelected;

  const GarmentSelectorGrid({
    super.key,
    required this.selectedType,
    required this.onSelected,
  });

  final List<Map<String, dynamic>> _garments = const [
    {'label': 'Shirt', 'icon': Icons.checkroom}, // Placeholder icons
    {'label': 'Pant', 'icon': Icons.accessibility_new},
    {'label': 'Suit', 'icon': Icons.business_center},
    {'label': 'Kurta', 'icon': Icons.face},
    {'label': 'Safari', 'icon': Icons.directions_bus},
    {'label': 'Other', 'icon': Icons.more_horiz},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: _garments.length,
      itemBuilder: (context, index) {
        final item = _garments[index];
        final isSelected = selectedType == item['label'];
        
        return GestureDetector(
          onTap: () => onSelected(item['label']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ] : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item['icon'],
                    color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['label'],
                    style: TextStyle(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        );
      },
    );
  }
}
