import 'package:flutter/material.dart';

/// Neo-Skeuomorphic design system with tactile, physical UI elements
class NeoColors {
  // High contrast mode for low-light shops
  static const backgroundColor = Color(0xFFF5F5F0); // Off-white
  static const surfaceColor = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1A1A1A); // Deep charcoal
  static const textSecondary = Color(0xFF666666);
  
  // Accent colors
  static const primary = Color(0xFF6366F1); // Indigo
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  
  // Severity colors for Khata
  static const debtGreen = Color(0xFF10B981); // <7 days
  static const debtOrange = Color(0xFFF59E0B); // 7-30 days
  static const debtRed = Color(0xFFEF4444); // 30+ days
}

/// Neo-Skeuomorphic elevated button with depression effect
class NeoButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? color;
  final double? width;
  final double? height;
  final EdgeInsets? padding;

  const NeoButton({
    super.key,
    required this.child,
    this.onPressed,
    this.color,
    this.width,
    this.height,
    this.padding,
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? NeoColors.primary;
    
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.width,
        height: widget.height,
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isPressed
              ? [
                  // Depressed state - minimal shadow
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [
                  // Elevated state - prominent shadow
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        transform: Matrix4.translationValues(0, _isPressed ? 4 : 0, 0),
        child: Center(child: widget.child),
      ),
    );
  }
}

/// Neo-Skeuomorphic card with realistic shadows
class NeoCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final Color? borderColor;

  const NeoCard({
    super.key,
    required this.child,
    this.color,
    this.padding,
    this.onTap,
    this.width,
    this.height,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? NeoColors.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: borderColor != null ? Border.all(color: borderColor!) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Chunky toggle switch with physical appearance
class NeoToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;

  const NeoToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: NeoColors.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Container(
            width: 60,
            height: 32,
            decoration: BoxDecoration(
              color: value ? NeoColors.success : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  left: value ? 28 : 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Neo-Skeuomorphic slider with haptic detents
class NeoSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final String? leftLabel;
  final String? centerLabel;
  final String? rightLabel;
  final int divisions;

  const NeoSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.leftLabel,
    this.centerLabel,
    this.rightLabel,
    this.divisions = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 8,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 16,
              elevation: 4,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            activeTrackColor: NeoColors.primary,
            inactiveTrackColor: Colors.grey.shade300,
            thumbColor: Colors.white,
            overlayColor: NeoColors.primary.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: value,
            onChanged: onChanged,
            divisions: divisions,
            min: 0,
            max: divisions.toDouble(),
          ),
        ),
        if (leftLabel != null || centerLabel != null || rightLabel != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (leftLabel != null)
                  Text(
                    leftLabel!,
                    style: TextStyle(
                      fontSize: 12,
                      color: value == 0 ? NeoColors.primary : NeoColors.textSecondary,
                      fontWeight: value == 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                if (centerLabel != null)
                  Text(
                    centerLabel!,
                    style: TextStyle(
                      fontSize: 12,
                      color: value == 1 ? NeoColors.primary : NeoColors.textSecondary,
                      fontWeight: value == 1 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                if (rightLabel != null)
                  Text(
                    rightLabel!,
                    style: TextStyle(
                      fontSize: 12,
                      color: value == 2 ? NeoColors.primary : NeoColors.textSecondary,
                      fontWeight: value == 2 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
