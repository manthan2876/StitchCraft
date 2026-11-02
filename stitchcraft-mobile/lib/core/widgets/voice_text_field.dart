import 'package:flutter/material.dart';
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
  });

  @override
  State<VoiceTextField> createState() => _VoiceTextFieldState();
}

class _VoiceTextFieldState extends State<VoiceTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    Widget? suffixWidget;
    if (widget.isPassword) {
      suffixWidget = IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: AppTheme.navyBlue,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    } else if (widget.onMicTap != null) {
      suffixWidget = GestureDetector(
        onTap: widget.onMicTap,
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.navyBlue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(
              Icons.mic,
              color: AppTheme.navyBlue,
              size: 24,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.navyBlue,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            readOnly: widget.readOnly,
            validator: widget.validator,
            maxLines: widget.isPassword ? 1 : widget.maxLines,
            obscureText: widget.isPassword ? _obscureText : false,
            style: TextStyle(
              fontSize: 18, 
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              suffixIcon: suffixWidget,
            ),
          ),
        ),
      ],
    );
  }
}
