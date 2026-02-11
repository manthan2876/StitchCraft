import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stitchcraft/core/widgets/neo_skeuomorphic_widgets.dart';

class StyleGridSelector extends StatefulWidget {
  final List<String> options;
  final String? selectedOption;
  final Function(String) onSelected;
  final String title;

  const StyleGridSelector({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.onSelected,
    required this.title,
  });

  @override
  State<StyleGridSelector> createState() => _StyleGridSelectorState();
}

class _StyleGridSelectorState extends State<StyleGridSelector> with SingleTickerProviderStateMixin {
  String? _lastSelected;
  late AnimationController _stampController;

  @override
  void initState() {
    super.initState();
    _stampController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _stampController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: widget.options.length,
          itemBuilder: (context, index) {
            final option = widget.options[index];
            final isSelected = widget.selectedOption == option;

            return GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.onSelected(option);
                setState(() => _lastSelected = option);
                _stampController.forward(from: 0);
              },
              child: Stack(
                children: [
                  NeoCard(
                    padding: const EdgeInsets.all(8),
                    color: isSelected ? NeoColors.primary.withValues(alpha: 0.05) : Colors.white,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getIconForOption(option),
                            color: isSelected ? NeoColors.primary : NeoColors.textSecondary,
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            option,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? NeoColors.primary : NeoColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isSelected && _lastSelected == option)
                    Positioned.fill(
                      child: ScaleTransition(
                        scale: Tween(begin: 1.5, end: 1.0).animate(CurvedAnimation(
                          parent: _stampController,
                          curve: Curves.bounceOut,
                        )),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              border: Border.all(color: NeoColors.success.withValues(alpha: 0.5), width: 3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Transform.rotate(
                              angle: -0.2,
                              child: Text(
                                "SELECTED",
                                style: TextStyle(
                                  color: NeoColors.success.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  IconData _getIconForOption(String option) {
    switch (option.toLowerCase()) {
      case 'regular': return Icons.check_circle_outline;
      case 'chinese': return Icons.panorama_fish_eye;
      case 'double': return Icons.filter_2;
      case 'single': return Icons.filter_1;
      case 'round': return Icons.circle_outlined;
      case 'square': return Icons.square_outlined;
      case 'pointed': return Icons.change_history;
      default: return Icons.style;
    }
  }
}
