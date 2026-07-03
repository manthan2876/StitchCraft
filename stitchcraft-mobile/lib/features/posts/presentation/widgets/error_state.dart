import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';

class ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const ErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: AppTheme.safetyOrange, size: 80),
            const SizedBox(height: 24),
            Text(
              'ડેટા મેળવવામાં ભૂલ આવી છે!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.safetyOrange,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'ERROR: $error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRetry,
                child: const Text('ફરી પ્રયાસ કરો (Retry)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
