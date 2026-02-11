import 'package:flutter/material.dart';
import 'package:stitchcraft/core/models/repair_job_model.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class RepairServiceCard extends StatelessWidget {
  final RepairJob repairJob;
  final VoidCallback onTap;
  final VoidCallback onComplete;

  const RepairServiceCard({
    super.key,
    required this.repairJob,
    required this.onTap,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = repairJob.status == 'completed';
    final statusColor = isCompleted ? AppTheme.success : AppTheme.warning;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Service Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getServiceColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getServiceIcon(),
                      color: _getServiceColor(),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Service Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          repairJob.serviceDisplayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          repairJob.customerName,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${repairJob.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isCompleted ? 'DONE' : 'PENDING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (repairJob.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  repairJob.notes,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),
              Row(
                children: [
                  // Complexity Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getComplexityColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _getComplexityColor()),
                    ),
                    child: Text(
                      repairJob.complexity,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getComplexityColor(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Date
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM yyyy').format(repairJob.createdDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),

                  const Spacer(),

                  // Complete Button
                  if (!isCompleted)
                    ElevatedButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getServiceIcon() {
    switch (repairJob.serviceType) {
      case 'ZIPPER':
        return Icons.vertical_align_center;
      case 'HEM':
        return Icons.straighten;
      case 'PICO':
        return Icons.border_outer;
      case 'FITTING':
        return Icons.accessibility_new;
      case 'PATCH':
        return Icons.crop_square;
      default:
        return Icons.build;
    }
  }

  Color _getServiceColor() {
    switch (repairJob.serviceType) {
      case 'ZIPPER':
        return Colors.blue;
      case 'HEM':
        return Colors.green;
      case 'PICO':
        return Colors.purple;
      case 'FITTING':
        return Colors.orange;
      case 'PATCH':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getComplexityColor() {
    switch (repairJob.complexity) {
      case 'SIMPLE':
        return Colors.green;
      case 'MEDIUM':
        return Colors.orange;
      case 'COMPLEX':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
