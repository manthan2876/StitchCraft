import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';

class GarmentTypeSelector extends StatelessWidget {
  final String? selectedType; // MEN, WOMEN, CHILDREN
  final Function(String) onTypeChanged;

  const GarmentTypeSelector({
    super.key,
    this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Garment Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTypeCard('MEN', 'Men', Icons.man, Colors.blue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTypeCard('WOMEN', 'Women', Icons.woman, Colors.pink),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTypeCard('CHILDREN', 'Children', Icons.child_care, Colors.orange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(String type, String label, IconData icon, Color color) {
    final isSelected = selectedType == type;

    return InkWell(
      onTap: () => onTypeChanged(type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSelected ? color : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
