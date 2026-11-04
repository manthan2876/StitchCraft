import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/services/sync_service.dart';
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';

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
  String? _syncError;

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
      _pendingByTable = Map<String, int>.from(
        data['pendingByTable'] as Map? ?? {},
      );
      _failedRecords = List<Map<String, dynamic>>.from(
        data['failedRecords'] as List? ?? [],
      );
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
        setState(() => _syncError = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.loc.sync_success),
            backgroundColor: AppTheme.trustGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _syncError =
              'Some changes could not be uploaded. Your local data is safe.',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Some changes could not be uploaded.'),
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

  String _formatLastSync(BuildContext context, DateTime? time) {
    if (time == null) return context.loc.never_synced;
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return context.loc.just_now;
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
        title: Text(
          context.loc.sync_offline_status,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: context.loc.refresh_status,
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
                          : AppTheme.safetyOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _totalPending == 0
                            ? AppTheme.trustGreen.withValues(alpha: 0.3)
                            : AppTheme.safetyOrange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _totalPending == 0
                              ? Icons.cloud_done
                              : Icons.cloud_upload,
                          size: 48,
                          color: _totalPending == 0
                              ? AppTheme.trustGreen
                              : AppTheme.safetyOrange,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _syncError != null
                              ? _syncError!
                              : _totalPending == 0
                              ? context.loc.all_changes_synced
                              : '$_totalPending ${context.loc.pending_local_changes}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _totalPending == 0
                                ? AppTheme.trustGreen
                                : AppTheme.safetyOrange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${context.loc.last_sync}: ${_formatLastSync(context, _lastSyncTime)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.darkGrey,
                          ),
                        ),
                        if (_isSyncing) ...[
                          const SizedBox(height: 16),
                          const LinearProgressIndicator(),
                          const SizedBox(height: 8),
                          Text(
                            _syncProgressMessage,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.sync),
                      label: Text(
                        _isSyncing
                            ? context.loc.syncing
                            : context.loc.sync_now_cloud,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Pending Items Breakdown
                  Text(
                    context.loc.local_queue_breakdown,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildQueueTile(
                    icon: Icons.content_cut,
                    label: context.loc.orders,
                    count: _pendingByTable['orders'] ?? 0,
                  ),
                  const SizedBox(height: 8),
                  _buildQueueTile(
                    icon: Icons.people,
                    label: context.loc.customers,
                    count: _pendingByTable['customers'] ?? 0,
                  ),
                  const SizedBox(height: 8),
                  _buildQueueTile(
                    icon: Icons.receipt_long,
                    label: context.loc.expenses_khata,
                    count: _pendingByTable['expenses'] ?? 0,
                  ),
                  const SizedBox(height: 8),
                  _buildQueueTile(
                    icon: Icons.inventory_2,
                    label: context.loc.inventory_materials,
                    count: _pendingByTable['inventory'] ?? 0,
                  ),

                  // Failed Records Section
                  if (_failedRecords.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.alertRed,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${context.loc.failed_records} (${_failedRecords.length})',
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
                          side: BorderSide(
                            color: AppTheme.alertRed.withValues(alpha: 0.3),
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            rec['title'] ?? 'Record',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'Table: ${rec['table']} • ID: ${rec['id']}',
                          ),
                          trailing: Text(
                            context.loc.failed,
                            style: const TextStyle(
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
                  ? AppTheme.safetyOrange.withValues(alpha: 0.15)
                  : AppTheme.trustGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count > 0 ? '$count ${context.loc.pending}' : context.loc.synced,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: count > 0 ? AppTheme.safetyOrange : AppTheme.trustGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
