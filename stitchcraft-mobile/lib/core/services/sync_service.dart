import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class SyncService {
  final _localDb = LocalDatabaseService();
  FirebaseFirestore get _firestore => FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'stitchcraft',
  );

  /// Get sync status including pending items count
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      int totalPending = 0;
      
      final tables = ['customers', 'orders', 'measurements', 'expenses'];
      for (final table in tables) {
        final unsynced = await _localDb.getUnsyncedRecords(table);
        totalPending += unsynced.length;
      }

      return {
        'pendingCount': totalPending,
        'lastSyncTime': await _getLastSyncTime(),
      };
    } catch (e) {
      developer.log('Error getting sync status: $e', name: 'SyncService');
      return {
        'pendingCount': 0,
        'lastSyncTime': null,
      };
    }
  }

  Future<DateTime?> _getLastSyncTime() async {
    // TODO: Store last sync time in shared preferences
    return null;
  }

  /// Compress image before upload to save bandwidth
  Future<File?> compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70, // 70% quality for good balance
        minWidth: 1024,
        minHeight: 1024,
      );

      if (result != null) {
        developer.log('Image compressed: ${file.lengthSync()} -> ${File(result.path).lengthSync()} bytes', 
          name: 'SyncService');
        return File(result.path);
      }
      return null;
    } catch (e) {
      developer.log('Image compression failed: $e', name: 'SyncService');
      return file; // Return original if compression fails
    }
  }

  /// Sync all tables with progress callback
  Future<void> syncAll({Function(String table, int current, int total)? onProgress}) async {
    developer.log('Starting full sync...', name: 'SyncService');
    
    final tables = ['customers', 'orders', 'measurements', 'expenses'];
    
    for (int i = 0; i < tables.length; i++) {
      final table = tables[i];
      onProgress?.call(table, i + 1, tables.length);
      await syncTable(table);
    }
    
    // Update last sync time
    // TODO: Save to shared preferences
    
    developer.log('Sync complete.', name: 'SyncService');
  }

  Future<void> syncTable(String table) async {
    try {
      final unsynced = await _localDb.getUnsyncedRecords(table);
      if (unsynced.isEmpty) {
        developer.log('No unsynced records for $table', name: 'SyncService');
        return;
      }

      developer.log('Syncing ${unsynced.length} records for $table', name: 'SyncService');

      for (final record in unsynced) {
        final id = record['id'] as String;
        final syncStatus = record['sync_status'] as int;

        if (syncStatus == 1) { // New or Updated
          // Remove sync_status before uploading to Firestore
          final cleanRecord = Map<String, dynamic>.from(record);
          cleanRecord.remove('sync_status');
          
          await _firestore.collection(table).doc(id).set(cleanRecord);
          await _localDb.updateSyncStatus(table, id, 0); 
          
          developer.log('Synced record $id to $table', name: 'SyncService');
        } else if (syncStatus == 2) { // Deleted
          await _firestore.collection(table).doc(id).delete();
          // Optionally physically delete from local DB
          developer.log('Deleted record $id from $table', name: 'SyncService');
        }
      }
    } catch (e) {
      developer.log('Sync error for $table: $e', name: 'SyncService');
      rethrow; // Propagate error to UI
    }
  }
}
