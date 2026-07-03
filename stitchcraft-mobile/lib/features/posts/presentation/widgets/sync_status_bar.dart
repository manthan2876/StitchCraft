import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';

class SyncStatusBar extends StatelessWidget {
  final VoidCallback onRefresh;

  const SyncStatusBar({
    super.key,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: const Border(top: BorderSide(color: AppTheme.lightGrey, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.trustGreen, size: 20),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'ડેટા સુરક્ષિત છે',
                    style: TextStyle(
                      color: AppTheme.trustGreen,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('રીફ્રેશ'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: AppTheme.deepBronze,
            ),
          ),
        ],
      ),
    );
  }
}
