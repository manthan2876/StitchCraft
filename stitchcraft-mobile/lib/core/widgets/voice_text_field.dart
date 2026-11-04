import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:stitchcraft/core/theme/app_theme.dart';

class VoiceTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final VoidCallback? onMicTap;
  final bool readOnly;
  final String? Function(String?)? validator;
  final int? maxLines;
  final bool isPassword;
  final ValueChanged<String>? onChanged;

  const VoiceTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.onMicTap,
    this.readOnly = false,
    this.validator,
    this.maxLines = 1,
    this.isPassword = false,
    this.onChanged,
  });

  @override
  State<VoiceTextField> createState() => _VoiceTextFieldState();
}

class _VoiceTextFieldState extends State<VoiceTextField> {
  late bool _obscureText;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  Future<void> _handleMicPress() async {
    if (widget.onMicTap != null) {
      widget.onMicTap!();
      return;
    }

    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    try {
      final currentLocale = Localizations.maybeLocaleOf(context)?.toString() ?? 'en_IN';
      String speechLocale = 'en_IN';
      if (currentLocale.startsWith('hi')) {
        speechLocale = 'hi_IN';
      } else if (currentLocale.startsWith('gu')) {
        speechLocale = 'gu_IN';
      }

      final available = await _speech.initialize(
        onError: (val) {
          if (mounted) {
            setState(() => _isListening = false);
          }
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );

      if (available) {
        if (mounted) setState(() => _isListening = true);
        await _speech.listen(
          localeId: speechLocale,
          onResult: (result) {
            if (mounted) {
              setState(() {
                widget.controller.text = result.recognizedWords;
                if (widget.onChanged != null) {
                  widget.onChanged!(result.recognizedWords);
                }
              });
            }
          },
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speech recognition not available or microphone permission denied'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget? suffixWidget;

    if (widget.isPassword) {
      suffixWidget = IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    } else {
      suffixWidget = GestureDetector(
        onTap: _handleMicPress,
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isListening
                ? AppTheme.alertRed.withValues(alpha: 0.15)
                : AppTheme.brandPurple.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? AppTheme.alertRed : AppTheme.brandPurple,
              size: 22,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            widget.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            readOnly: widget.readOnly,
            validator: widget.validator,
            maxLines: widget.isPassword ? 1 : widget.maxLines,
            obscureText: widget.isPassword ? _obscureText : false,
            onChanged: widget.onChanged,
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 15,
              ),
              suffixIcon: suffixWidget,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
