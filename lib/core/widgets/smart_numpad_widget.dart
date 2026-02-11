import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stitchcraft/core/widgets/neo_skeuomorphic_widgets.dart';

class SmartNumpadWidget extends StatelessWidget {
  final Function(String) onKeyPressed;
  final VoidCallback onDelete;
  final VoidCallback onClear;

  const SmartNumpadWidget({
    super.key,
    required this.onKeyPressed,
    required this.onDelete,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeoColors.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Traction Keys (Fractions)
          Row(
            children: [
              _buildNumpadButton('.25', isSpecial: true),
              const SizedBox(width: 12),
              _buildNumpadButton('.5', isSpecial: true),
              const SizedBox(width: 12),
              _buildNumpadButton('.75', isSpecial: true),
            ],
          ),
          const SizedBox(height: 16),
          // Numpad Grid
          _buildRow(['1', '2', '3']),
          const SizedBox(height: 12),
          _buildRow(['4', '5', '6']),
          const SizedBox(height: 12),
          _buildRow(['7', '8', '9']),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildNumpadButton('C', isClear: true),
              const SizedBox(width: 12),
              _buildNumpadButton('0'),
              const SizedBox(width: 12),
              _buildNumpadButton('⌫', isDelete: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      children: keys.expand((key) => [
        _buildNumpadButton(key),
        if (key != keys.last) const SizedBox(width: 12),
      ]).toList(),
    );
  }

  Widget _buildNumpadButton(String key, {bool isSpecial = false, bool isDelete = false, bool isClear = false}) {
    return Expanded(
      child: NeoButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          if (isDelete) {
            onDelete();
          } else if (isClear) {
            onClear();
          } else {
            onKeyPressed(key);
          }
        },
        color: isSpecial 
            ? NeoColors.primary.withValues(alpha: 0.1) 
            : (isDelete || isClear ? Colors.grey.shade200 : NeoColors.surfaceColor),
        child: Text(
          key,
          style: TextStyle(
            fontSize: isSpecial ? 18 : 24,
            fontWeight: FontWeight.bold,
            color: isSpecial ? NeoColors.primary : NeoColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
