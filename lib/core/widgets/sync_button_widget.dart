import 'package:flutter/material.dart';
import 'package:stitchcraft/core/services/sync_service.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';

class SyncButtonWidget extends StatefulWidget {
  const SyncButtonWidget({super.key});

  @override
  State<SyncButtonWidget> createState() => _SyncButtonWidgetState();
}

class _SyncButtonWidgetState extends State<SyncButtonWidget> {
  final SyncService _syncService = SyncService();
  bool _isSyncing = false;
  int _pendingCount = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    final status = await _syncService.getSyncStatus();
    if (mounted) {
      setState(() {
        _pendingCount = status['pendingCount'] as int;
      });
    }
  }

  Future<void> _performSync() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
      _errorMessage = null;
    });

    try {
      await _syncService.syncAll();
      await _loadSyncStatus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Data synced successfully!'),
              ],
            ),
            backgroundColor: AppTheme.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Sync failed: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _performSync,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _isSyncing ? null : _performSync,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _getBorderColor()),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isSyncing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Icon(
                _getIcon(),
                size: 16,
                color: _getIconColor(),
              ),
            const SizedBox(width: 6),
            Text(
              _getLabel(),
              style: TextStyle(
                color: _getTextColor(),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (_errorMessage != null) {
      return AppTheme.error.withValues(alpha: 0.1);
    }
    if (_pendingCount > 0) {
      return AppTheme.warning.withValues(alpha: 0.1);
    }
    return Colors.green.withValues(alpha: 0.1);
  }

  Color _getBorderColor() {
    if (_errorMessage != null) return AppTheme.error;
    if (_pendingCount > 0) return AppTheme.warning;
    return Colors.green;
  }

  IconData _getIcon() {
    if (_errorMessage != null) return Icons.cloud_off;
    if (_pendingCount > 0) return Icons.cloud_upload;
    return Icons.cloud_done;
  }

  Color _getIconColor() {
    if (_errorMessage != null) return AppTheme.error;
    if (_pendingCount > 0) return AppTheme.warning;
    return Colors.green;
  }

  Color _getTextColor() {
    if (_errorMessage != null) return AppTheme.error;
    if (_pendingCount > 0) return AppTheme.warning;
    return Colors.green;
  }

  String _getLabel() {
    if (_isSyncing) return 'SYNCING...';
    if (_errorMessage != null) return 'SYNC FAILED';
    if (_pendingCount > 0) return '$_pendingCount PENDING';
    return 'SYNCED';
  }
}
