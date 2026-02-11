import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';

class StatusTimeline extends StatelessWidget {
  final String currentStatus;
  final Function(String) onStatusChanged;

  const StatusTimeline({
    super.key,
    required this.currentStatus,
    required this.onStatusChanged,
  });

  static const List<String> _stages = [
    'Pending',
    'Cutting',
    'Stitching',
    'Ready',
    'Delivered',
  ];

  @override
  Widget build(BuildContext context) {
    int currentIndex = _stages.indexOf(currentStatus);
    if (currentIndex == -1) currentIndex = 0; // Default or custom

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order Status', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _stages.length,
            separatorBuilder: (context, index) => Container(
              width: 40,
              height: 2,
              color: index < currentIndex ? AppTheme.primaryColor : Colors.grey.shade300,
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),
            itemBuilder: (context, index) {
              final stage = _stages[index];
              final isCompleted = index <= currentIndex;
              final isCurrent = index == currentIndex;

              return GestureDetector(
                onTap: () => onStatusChanged(stage),
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompleted ? AppTheme.primaryColor : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCompleted ? AppTheme.primaryColor : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stage,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? AppTheme.primaryColor : Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
