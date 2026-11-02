import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/services/sync_service.dart';

class SyncStatusScreen extends StatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  final SyncService _syncService = SyncService();

  bool _isLoading = true;
  bool _isSyncing = false;
  String _syncProgressMessage = '';
  int _totalPending = 0;
  Map<String, int> _pendingByTable = {
    'orders': 0,
    'customers': 0,
    'expenses': 0,
    'inventory': 0,
  };
  List<Map<String, dynamic>> _failedRecords = [];
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _loadSyncDetails();
  }

  Future<void> _loadSyncDetails() async {
    setState(() => _isLoading = true);
    final data = await _syncService.getDetailedSyncBreakdown();
    if (!mounted) return;

    setState(() {
      _totalPending = data['totalPending'] as int? ?? 0;
      _pendingByTable = Map<String, int>.from(data['pendingByTable'] as Map? ?? {});
      _failedRecords = List<Map<String, dynamic>>.from(data['failedRecords'] as List? ?? []);
      _lastSyncTime = data['lastSyncTime'] as DateTime?;
      _isLoading = false;
    });
  }

  Future<void> _handleManualSync() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
      _syncProgressMessage = 'Initializing cloud sync...';
    });

    try {
      await _syncService.syncAll(
        onProgress: (table, current, total) {
          if (mounted) {
            setState(() {
              _syncProgressMessage = 'Syncing $table ($current/$total)...';
            });
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed successfully!'),
            backgroundColor: AppTheme.trustGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync encountered issues: $e'),
            backgroundColor: AppTheme.alertRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _syncProgressMessage = '';
        });
        await _loadSyncDetails();
      }
    }
  }

  String _formatLastSync(DateTime? time) {
    if (time == null) return 'Never synced';
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${time.day}/${time.month}/${time.year} at ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync & Offline Status', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Status',
            onPressed: _isLoading || _isSyncing ? null : _loadSyncDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _totalPending == 0
                          ? AppTheme.trustGreen.withValues(alpha: 0.12)
                          : AppTheme.warmAmber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _totalPending == 0
                            ? AppTheme.trustGreen.withValues(alpha: 0.3)
                            : AppTheme.warmAmber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _totalPending == 0 ? Icons.cloud_done : Icons.cloud_upload,
                          size: 48,
                          color: _totalPending == 0 ? AppTheme.trustGreen : AppTheme.warmAmber,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _totalPending == 0
                              ? 'All Changes Synced'
                              : '$_totalPending Pending Local Changes',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _totalPending == 0 ? AppTheme.trustGreen : AppTheme.warmAmber,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last sync: ${_formatLastSync(_lastSyncTime)}',
                          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.darkGrey),
                        ),
                        if (_isSyncing) ...[
                          const SizedBox(height: 16),
                          const LinearProgressIndicator(),
                          const SizedBox(height: 8),
                          Text(
                            _syncProgressMessage,
                            style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Big Manual Sync Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSyncing ? null : _handleManualSync,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.sync),
                      label: Text(
                        _isSyncing ? 'Syncing...' : 'Sync Now with Cloud',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Pending Items Breakdown
                  Text(
                    'Local Queue Breakdown',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  _buildQueueTile(
                    icon: Icons.content_cut,
                    label: 'Orders',
                    count: _pendingByTable['orders'] ?? 0,
                  ),
                  const SizedBox(height: 8),
                  _buildQueueTile(
                    icon: Icons.people,
                    label: 'Customers',
                    count: _pendingByTable['customers'] ?? 0,
                  ),
                  const SizedBox(height: 8),
                  _buildQueueTile(
                    icon: Icons.receipt_long,
                    label: 'Expenses & Khata',
                    count: _pendingByTable['expenses'] ?? 0,
                  ),
                  const SizedBox(height: 8),
                  _buildQueueTile(
                    icon: Icons.inventory_2,
                    label: 'Inventory Materials',
                    count: _pendingByTable['inventory'] ?? 0,
                  ),

                  // Failed Records Section
                  if (_failedRecords.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.alertRed, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Failed Records (${_failedRecords.length})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.alertRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._failedRecords.map(
                      (rec) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: Border.all(color: AppTheme.alertRed.withValues(alpha: 0.3)),
                        ),
                        child: ListTile(
                          title: Text(
                            rec['title'] ?? 'Record',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text('Table: ${rec['table']} • ID: ${rec['id']}'),
                          trailing: const Text(
                            'Failed',
                            style: TextStyle(
                              color: AppTheme.alertRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildQueueTile({
    required IconData icon,
    required String label,
    required int count,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.lightGrey.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppTheme.brandPurple),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: count > 0
                  ? AppTheme.warmAmber.withValues(alpha: 0.15)
                  : AppTheme.trustGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count > 0 ? '$count pending' : 'Synced',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: count > 0 ? AppTheme.warmAmber : AppTheme.trustGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

