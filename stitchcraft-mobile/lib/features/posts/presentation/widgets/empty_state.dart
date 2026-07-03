import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, color: AppTheme.bronzeTint, size: 80),
          const SizedBox(height: 16),
          Text(
            'કોઈ ડેટા મળ્યો નથી.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
