import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';

class FabricDigitalTwin extends StatelessWidget {
  const FabricDigitalTwin({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Fabric Digital Twin', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_a_photo_outlined),
                onPressed: () {
                   // Hook up camera later
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera not connected')));
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
            ),
            alignment: Alignment.center,
            child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: const [
                 Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.grey),
                 SizedBox(height: 8),
                 Text('No fabric photo uploaded', style: TextStyle(color: Colors.grey)),
               ],
            ),
          ),
        ],
      ),
    );
  }
}
