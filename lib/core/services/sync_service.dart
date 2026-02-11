import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'dart:developer' as developer;

class SyncService {
  final _localDb = LocalDatabaseService();
  FirebaseFirestore get _firestore => FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'stitchcraft',
  );

  Future<void> syncAll() async {
    developer.log('Starting full sync...', name: 'SyncService');
    await syncTable('customers');
    await syncTable('orders');
    await syncTable('measurements');
    developer.log('Sync complete.', name: 'SyncService');
  }

  Future<void> syncTable(String table) async {
    try {
      final unsynced = await _localDb.getUnsyncedRecords(table);
      if (unsynced.isEmpty) return;

      for (final record in unsynced) {
        final id = record['id'] as String;
        final syncStatus = record['sync_status'] as int;

        if (syncStatus == 1) { // New or Updated
          await _firestore.collection(table).doc(id).set(record..remove('sync_status'));
          await _localDb.updateSyncStatus(table, id, 0); 
        } else if (syncStatus == 2) { // Deleted
          await _firestore.collection(table).doc(id).delete();
          // Final removal from local DB (could be a physical delete now)
        }
      }
    } catch (e) {
      developer.log('Sync error for $table: $e', name: 'SyncService');
    }
  }
}
