import 'package:flutter/material.dart';
import 'package:stitchcraft/core/models/repair_job_model.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/features/repairs/presentation/widgets/repair_service_card.dart';
import 'package:stitchcraft/features/repairs/presentation/screens/add_repair_job_screen.dart';

class RepairsScreen extends StatefulWidget {
  const RepairsScreen({super.key});

  @override
  State<RepairsScreen> createState() => _RepairsScreenState();
}

class _RepairsScreenState extends State<RepairsScreen> {
  final DatabaseService _dbService = DatabaseService();
  String _filterStatus = 'all'; // all, pending, completed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repairs & Alterations'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Jobs')),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(value: 'completed', child: Text('Completed')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Service Menu
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surfaceColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Service Menu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.0,
                  children: [
                    _buildQuickServiceCard(
                      'ZIPPER',
                      'Chain\nBadlai',
                      Icons.vertical_align_center,
                      Colors.blue,
                    ),
                    _buildQuickServiceCard(
                      'HEM',
                      'Turpai\n(Hem)',
                      Icons.straighten,
                      Colors.green,
                    ),
                    _buildQuickServiceCard(
                      'PICO',
                      'Fall-Pico',
                      Icons.border_outer,
                      Colors.purple,
                    ),
                    _buildQuickServiceCard(
                      'FITTING',
                      'Fitting',
                      Icons.accessibility_new,
                      Colors.orange,
                    ),
                    _buildQuickServiceCard(
                      'PATCH',
                      'Patch\nWork',
                      Icons.crop_square,
                      Colors.red,
                    ),
                    _buildQuickServiceCard(
                      'OTHER',
                      'Other',
                      Icons.more_horiz,
                      Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Repair Jobs List
          Expanded(
            child: StreamBuilder<List<RepairJob>>(
              stream: _dbService.getRepairJobsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final jobs = snapshot.data ?? [];
                final filteredJobs = _filterStatus == 'all'
                    ? jobs
                    : jobs.where((j) => j.status == _filterStatus).toList();

                if (filteredJobs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.build_circle_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No repair jobs found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap a service above to create one',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredJobs.length,
                  itemBuilder: (context, index) {
                    return RepairServiceCard(
                      repairJob: filteredJobs[index],
                      onTap: () => _viewRepairJob(filteredJobs[index]),
                      onComplete: () => _completeRepairJob(filteredJobs[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickServiceCard(
    String serviceType,
    String label,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () => _createRepairJob(serviceType),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createRepairJob(String serviceType) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRepairJobScreen(serviceType: serviceType),
      ),
    );

    if (result == true) {
      setState(() {}); // Refresh list
    }
  }

  void _viewRepairJob(RepairJob job) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRepairJobScreen(
          serviceType: job.serviceType,
          existingJob: job,
        ),
      ),
    );

    if (result == true) {
      setState(() {}); // Refresh list
    }
  }

  Future<void> _completeRepairJob(RepairJob job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Repair Job?'),
        content: Text(
          'Mark "${job.serviceDisplayName}" for ${job.customerName} as completed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final updatedJob = job.copyWith(
        status: 'completed',
        completedDate: DateTime.now(),
      );
      await _dbService.updateRepairJob(updatedJob);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Repair job marked as completed!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }
}
