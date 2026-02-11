import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';

class MeasurementVisualScreen extends StatefulWidget {
  final String? customerId;
  final String? orderId;
  final String itemType;

  const MeasurementVisualScreen({
    super.key,
    this.customerId,
    this.orderId,
    this.itemType = 'Shirt', // Default, should be passed
  });

  @override
  State<MeasurementVisualScreen> createState() => _MeasurementVisualScreenState();
}

class _MeasurementVisualScreenState extends State<MeasurementVisualScreen> {
  // Measurement Data
  final Map<String, double> _measurements = {};
  final Map<String, double> _fits = {}; // -1.0 (Tight) to 1.0 (Loose)
  String _selectedPart = 'Length'; // Default selection

  // Body Parts Definition (Name, Top%, Left%)
  final List<Map<String, dynamic>> _bodyParts = [
    {'id': 'Neck', 'top': 0.12, 'left': 0.50},
    {'id': 'Shoulder', 'top': 0.18, 'left': 0.50},
    {'id': 'Chest', 'top': 0.25, 'left': 0.50},
    {'id': 'Waist', 'top': 0.38, 'left': 0.50},
    {'id': 'Hips', 'top': 0.45, 'left': 0.50},
    {'id': 'Sleeve', 'top': 0.25, 'left': 0.80},
    {'id': 'Length', 'top': 0.55, 'left': 0.15}, 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('${widget.itemType} Measurements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            tooltip: 'AI Estimate (Demo)',
            onPressed: () {
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AI Estimation requires camera permission (Demo Only)')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              HapticFeedback.mediumImpact();
              _saveMeasurements();
            },
          )
        ],
      ),
      body: Column(
        children: [
          // 1. Visual Interface (Top Half)
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Placeholder Silhouette (Replace with SVG asset if available)
                  Opacity(
                    opacity: 0.1,
                    child: Icon(Icons.man, size: 300, color: AppTheme.primaryColor),
                  ),
                  // Interactive Dots
                  ..._bodyParts.map((part) => _buildBodyPoint(part)),
                ],
              ),
            ),
          ),
          
          // 2. Adaptive Input (Bottom Half)
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedPart.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Value Display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_measurements[_selectedPart]?.toStringAsFixed(1) ?? "0.0"}"',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      // Fit Preference
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                           Text(
                            _getFitLabel(_fits[_selectedPart] ?? 0),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentColor),
                          ),
                          SizedBox(
                            width: 150,
                            child: Slider(
                              value: _fits[_selectedPart] ?? 0,
                              min: -1.0,
                              max: 1.0,
                              divisions: 4,
                              activeColor: AppTheme.accentColor,
                              onChanged: (val) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _fits[_selectedPart] = val;
                                });
                              },
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  
                  const Spacer(),
                  // Custom Numeric Keypad
                  _buildNumericKeypad(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyPoint(Map<String, dynamic> part) {
    // Positioning logic (simplified for demo, assumes 300x400 area approx)
    final isSelected = _selectedPart == part['id'];
    return LayoutBuilder(
      builder: (context, constraints) {
        return Positioned(
          top: constraints.maxHeight * part['top'],
          left: constraints.maxWidth * part['left'] - 24, // Center align
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedPart = part['id'];
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 8, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Text(
                part['id'],
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildNumericKeypad() {
    return Column(
      children: [
        Row(
          children: [
             _key('1'), _key('2'), _key('3'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
             _key('4'), _key('5'), _key('6'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
             _key('7'), _key('8'), _key('9'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
             _key('.', flex: 1), 
             _key('0', flex: 1), 
             _actionKey(Icons.backspace_outlined, () => _handleBackspace()),
          ],
        ),
      ],
    );
  }

  Widget _key(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleInput(label),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 56, // Large touch target
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionKey(IconData icon, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
             height: 56,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
             alignment: Alignment.center,
             child: Icon(icon, color: AppTheme.textPrimary),
          ),
        ),
      ),
    );
  }

  void _handleInput(String value) {
    HapticFeedback.lightImpact();
    setState(() {
      double current = _measurements[_selectedPart] ?? 0.0;
      String currentStr = current == 0.0 ? '' : current.toString();
      
      // Handle decimal
      if (currentStr.endsWith('.0') && !currentStr.contains('.')) {
         currentStr = currentStr.substring(0, currentStr.length - 2); 
      }
      if (value == '.' && currentStr.contains('.')) return;

      String newStr = currentStr + value;
      _measurements[_selectedPart] = double.tryParse(newStr) ?? 0.0;
    });
  }

  void _handleBackspace() {
    HapticFeedback.lightImpact();
    setState(() {
      double current = _measurements[_selectedPart] ?? 0.0;
      String currentStr = current.toString();
      if (currentStr.endsWith('.0')) currentStr = currentStr.substring(0, currentStr.length - 2);
      
      if (currentStr.isEmpty) return;
      
      String newStr = currentStr.substring(0, currentStr.length - 1);
      _measurements[_selectedPart] = newStr.isEmpty ? 0.0 : (double.tryParse(newStr) ?? 0.0);
    });
  }

  String _getFitLabel(double val) {
    if (val < -0.5) return 'Tight';
    if (val > 0.5) return 'Loose';
    return 'Regular';
  }

  void _saveMeasurements() {
    // Return measurements map to previous screen or save to DB
    Navigator.pop(context, {
      'measurements': _measurements,
      'fits': _fits
    });
  }
}
