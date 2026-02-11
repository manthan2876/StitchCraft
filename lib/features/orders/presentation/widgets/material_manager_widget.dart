import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';

class MaterialManagerWidget extends StatefulWidget {
  final bool astarRequired;
  final String? astarSource;
  final double astarCost;
  final Function(bool required, String? source, double cost) onChanged;

  const MaterialManagerWidget({
    super.key,
    required this.astarRequired,
    this.astarSource,
    required this.astarCost,
    required this.onChanged,
  });

  @override
  State<MaterialManagerWidget> createState() => _MaterialManagerWidgetState();
}

class _MaterialManagerWidgetState extends State<MaterialManagerWidget> {
  late bool _astarRequired;
  late String? _astarSource;
  late double _astarCost;

  // Default rate card (should be loaded from settings in production)
  final Map<String, double> _defaultRates = {
    'COTTON': 30.0,
    'CREPE': 50.0,
    'SATIN': 60.0,
    'TAFETTA': 55.0,
  };

  final double _standardConsumption = 0.8; // meters for standard blouse

  @override
  void initState() {
    super.initState();
    _astarRequired = widget.astarRequired;
    _astarSource = widget.astarSource;
    _astarCost = widget.astarCost;
  }

  void _updateAstarRequired(bool value) {
    setState(() {
      _astarRequired = value;
      if (!value) {
        _astarSource = null;
        _astarCost = 0.0;
      }
    });
    widget.onChanged(_astarRequired, _astarSource, _astarCost);
  }

  void _updateAstarSource(String? source) {
    setState(() {
      _astarSource = source;
      if (source == 'SHOP_PROVIDED') {
        // Auto-calculate cost based on default cotton astar
        _astarCost = _defaultRates['COTTON']! * _standardConsumption;
      } else {
        _astarCost = 0.0;
      }
    });
    widget.onChanged(_astarRequired, _astarSource, _astarCost);
  }

  void _updateMaterialType(String materialType) {
    setState(() {
      _astarCost = _defaultRates[materialType]! * _standardConsumption;
    });
    widget.onChanged(_astarRequired, _astarSource, _astarCost);
  }

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
          Row(
            children: [
              Icon(Icons.layers, color: AppTheme.accentColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Astar (Lining) Management',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Astar Required Toggle
          SwitchListTile(
            title: const Text('Astar Required?'),
            subtitle: const Text('Does this garment need lining?'),
            value: _astarRequired,
            onChanged: _updateAstarRequired,
            activeThumbColor: AppTheme.primaryColor,
            contentPadding: EdgeInsets.zero,
          ),

          if (_astarRequired) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Source Selection
            Text(
              'Astar Source',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: _buildSourceCard(
                    'CLIENT_PROVIDED',
                    'Client Provided',
                    'Client brings their own lining',
                    Icons.person,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSourceCard(
                    'SHOP_PROVIDED',
                    'Shop Provided',
                    'We provide the lining',
                    Icons.store,
                    Colors.green,
                  ),
                ),
              ],
            ),

            if (_astarSource == 'SHOP_PROVIDED') ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Material Type Selection
              Text(
                'Material Type',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _defaultRates.keys.map((type) {
                  return ChoiceChip(
                    label: Text('$type (₹${_defaultRates[type]}/m)'),
                    selected: _astarCost == _defaultRates[type]! * _standardConsumption,
                    onSelected: (selected) {
                      if (selected) _updateMaterialType(type);
                    },
                    selectedColor: AppTheme.accentColor.withValues(alpha: 0.3),
                    labelStyle: TextStyle(
                      color: _astarCost == _defaultRates[type]! * _standardConsumption
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary,
                      fontWeight: _astarCost == _defaultRates[type]! * _standardConsumption
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Cost Display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.accentColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Billable Astar Cost',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '₹${_astarCost.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.success,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_standardConsumption}m × ₹${(_astarCost / _standardConsumption).toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSourceCard(
    String value,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isSelected = _astarSource == value;
    
    return InkWell(
      onTap: () => _updateAstarSource(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
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
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected ? color : AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
