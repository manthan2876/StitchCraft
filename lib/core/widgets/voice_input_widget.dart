import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stitchcraft/core/widgets/neo_skeuomorphic_widgets.dart';

class VoiceInputWidget extends StatefulWidget {
  final Function(String) onResult;

  const VoiceInputWidget({super.key, required this.onResult});

  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget> with SingleTickerProviderStateMixin {
  bool _isListening = false;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isListening)
          SizedBox(
            height: 60,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(15, (index) {
                    final height = 10 + 40 * (0.5 + 0.5 * (index % 3 == 0 ? _waveController.value : (1 - _waveController.value)));
                    return Container(
                      width: 4,
                      height: height,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: NeoColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        GestureDetector(
          onLongPressStart: (_) {
            HapticFeedback.heavyImpact();
            setState(() => _isListening = true);
          },
          onLongPressEnd: (_) {
            HapticFeedback.mediumImpact();
            setState(() => _isListening = false);
            // Simulate voice result
            widget.onResult("38.5");
          },
          child: NeoButton(
            width: 80,
            height: 80,
            color: _isListening ? NeoColors.primary : NeoColors.surfaceColor,
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              size: 40,
              color: _isListening ? Colors.white : NeoColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isListening ? "Listening..." : "Hold to Talk (Bol Kar Likho)",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _isListening ? NeoColors.primary : NeoColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
