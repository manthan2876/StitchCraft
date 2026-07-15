import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'dart:developer' as developer;

class SyncService {
  final _localDb = LocalDatabaseService();

  static String get baseUrl {
    // Point directly to production Render backend server
    return 'https://stitchcraft-backend.onrender.com/api';
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> _getShopId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('shopId');
  }

  /// Get sync status including pending items count
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      int totalPending = 0;
      final tables = ['customers', 'orders', 'expenses'];
      for (final table in tables) {
        final unsynced = await _localDb.getUnsyncedRecords(table);
        totalPending += unsynced.length;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString('lastSyncTime');
      final lastSyncTime = lastSyncStr != null ? DateTime.tryParse(lastSyncStr) : null;

      return {
        'pendingCount': totalPending,
        'lastSyncTime': lastSyncTime,
      };
    } catch (e) {
      developer.log('Error getting sync status: $e', name: 'SyncService');
      return {
        'pendingCount': 0,
        'lastSyncTime': null,
      };
    }
  }

  /// Sync all tables with progress callback
  Future<void> syncAll({Function(String table, int current, int total)? onProgress}) async {
    developer.log('Starting full REST sync...', name: 'SyncService');
    
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      developer.log('Sync skipped: No auth token found.', name: 'SyncService');
      return;
    }

    final tables = ['customers', 'orders', 'expenses'];
    
    for (int i = 0; i < tables.length; i++) {
      final table = tables[i];
      onProgress?.call(table, i + 1, tables.length);
      try {
        await syncTable(table, token);
      } catch (e) {
        developer.log('Failed to sync table $table: $e', name: 'SyncService');
      }
    }
    
    // Update last sync time
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastSyncTime', DateTime.now().toIso8601String());
    
    developer.log('Sync complete.', name: 'SyncService');
  }

  Future<void> syncTable(String table, String token) async {
    final shopId = await _getShopId();
    if (shopId == null || shopId.isEmpty) {
      developer.log('Sync skipped for $table: No active shopId session found.', name: 'SyncService');
      return;
    }

    // 1. PUSH local changes to Server
    final unsynced = await _localDb.getUnsyncedRecords(table);
    if (unsynced.isNotEmpty) {
      developer.log('Pushing ${unsynced.length} unsynced records for $table', name: 'SyncService');
      for (final record in unsynced) {
        final id = record['id'] as String;
        final syncStatus = record['sync_status'] as int;

        if (syncStatus == 1) { // New / Updated
          final payload = Map<String, dynamic>.from(record);
          payload.remove('sync_status');
          payload['shopId'] = shopId;

          // Mapping customizations for Node Express backend
          String endpoint = table;
          if (table == 'expenses') {
            endpoint = 'ledger/expenses';
          }

          // Embed measurements snapshot into order if available
          if (table == 'orders') {
            // Read measurements for order
            final measurements = await _localDb.getRecords('measurements', where: 'order_id = ?', whereArgs: [id]);
            if (measurements.isNotEmpty) {
              final firstMeasure = measurements.first;
              final measurementsJson = firstMeasure['measurements_json'] as String?;
              final Map<String, dynamic> parsedMeasurements = measurementsJson != null 
                  ? json.decode(measurementsJson) 
                  : {};
              
              final apparelType = record['apparelType'] ?? record['item_types']?.toString().split(',').first ?? 'Shirt';
              payload['measurementsSnapshot'] = {
                apparelType.toString().toLowerCase().contains('pant') ? 'pant' : 'shirt': parsedMeasurements,
              };
            }
            // Format order keys for Mongoose validation rules
            payload['customerName'] = record['customer_name'] ?? 'Walk-in Customer';
            payload['apparelType'] = record['apparelType'] ?? 'Shirt';
            payload['deliveryDate'] = record['due_date'] != null 
                ? DateTime.fromMillisecondsSinceEpoch(record['due_date']).toUtc().toIso8601String()
                : DateTime.now().add(const Duration(days: 7)).toUtc().toIso8601String();
            payload['price'] = record['total_amount'] ?? 100.0;
            payload['fabric'] = record['description'] ?? 'Standard Cotton';
          }

          final response = await http.post(
            Uri.parse('$baseUrl/$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(payload),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final responseData = json.decode(response.body);
            final serverId = responseData['_id'] ?? responseData['id'];
            if (serverId != null && serverId != id) {
              await _localDb.updateRecordId(table, id, serverId);
            } else {
              await _localDb.updateSyncStatus(table, id, 0);
            }
            developer.log('Successfully pushed $id to server for $table', name: 'SyncService');
          } else {
            developer.log('Failed to push $id: ${response.statusCode} - ${response.body}', name: 'SyncService');
          }
        }
      }
    }

    // 2. PULL remote changes from Server
    String getEndpoint = table;
    if (table == 'expenses') {
      getEndpoint = 'ledger/expenses';
    }

    final response = await http.get(
      Uri.parse('$baseUrl/$getEndpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    developer.log('Response Status: ${response.statusCode}');
    developer.log('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> remoteData = json.decode(response.body);
      developer.log('Pulled ${remoteData.length} records from server for $table', name: 'SyncService');

      // 2a. Prune local database of orphaned records deleted on the server
      final localRecords = await _localDb.getRecords(table);
      final remoteIds = remoteData.map<String>((rawRecord) {
        final Map<String, dynamic> remoteRecord = Map<String, dynamic>.from(rawRecord);
        return (remoteRecord['_id'] ?? remoteRecord['id'] ?? '').toString();
      }).toSet();

      for (final localRec in localRecords) {
        final id = localRec['id'] as String;
        final syncStatus = localRec['sync_status'] as int;
        if (syncStatus == 0 && !remoteIds.contains(id)) {
          developer.log('Deleting orphaned local record $id from table $table', name: 'SyncService');
          await _localDb.deleteRecordPermanently(table, id);
        }
      }

      // 2b. Insert or replace remote records
      for (final rawRecord in remoteData) {
        final Map<String, dynamic> remoteRecord = Map<String, dynamic>.from(rawRecord);
        final String id = remoteRecord['_id'] ?? remoteRecord['id'] ?? '';
        if (id.isEmpty) continue;

        // Map backend schema parameters to local SQLite table schemas
        final Map<String, dynamic> sqliteRecord = {
          'id': id,
          'sync_status': 0,
        };

        if (table == 'customers') {
          sqliteRecord['name'] = remoteRecord['name'] ?? 'Unknown';
          sqliteRecord['phone'] = remoteRecord['phone'] ?? '';
          sqliteRecord['email'] = remoteRecord['email'] ?? '';
          sqliteRecord['updated_at'] = DateTime.now().millisecondsSinceEpoch;
        } else if (table == 'orders') {
          sqliteRecord['customer_id'] = remoteRecord['customer'] is Map ? remoteRecord['customer']['_id'] : remoteRecord['customer'] ?? '';
          sqliteRecord['customer_name'] = remoteRecord['customerName'] ?? 'Walk-in Customer';
          sqliteRecord['order_date'] = remoteRecord['date'] != null 
              ? DateTime.parse(remoteRecord['date'].toString()).millisecondsSinceEpoch
              : DateTime.now().millisecondsSinceEpoch;
          sqliteRecord['due_date'] = remoteRecord['deliveryDate'] != null 
              ? DateTime.parse(remoteRecord['deliveryDate'].toString()).millisecondsSinceEpoch
              : DateTime.now().millisecondsSinceEpoch;
          sqliteRecord['status'] = remoteRecord['status'] ?? 'Incoming';
          sqliteRecord['total_amount'] = (remoteRecord['price'] as num?)?.toDouble() ?? 0.0;
          sqliteRecord['description'] = remoteRecord['fabric'] ?? '';
          sqliteRecord['fabric_photo_url'] = remoteRecord['fabricImageUrl'] ?? '';
          sqliteRecord['updated_at'] = DateTime.now().millisecondsSinceEpoch;
        } else if (table == 'expenses') {
          sqliteRecord['category'] = remoteRecord['category'] ?? 'General';
          sqliteRecord['amount'] = (remoteRecord['amount'] as num?)?.toDouble() ?? 0.0;
          sqliteRecord['description'] = remoteRecord['description'] ?? '';
          sqliteRecord['date'] = remoteRecord['date'] != null 
              ? DateTime.parse(remoteRecord['date'].toString()).millisecondsSinceEpoch
              : DateTime.now().millisecondsSinceEpoch;
          sqliteRecord['updated_at'] = DateTime.now().millisecondsSinceEpoch;
        }

        await _localDb.insertRecord(table, sqliteRecord);
        if (table == 'orders') DatabaseService.orderSignal.add(null);
        if (table == 'customers') DatabaseService.customerSignal.add(null);
        if (table == 'expenses') DatabaseService.expenseSignal.add(null);
      }
    } else {
      developer.log('Failed to pull records for $table: ${response.statusCode} - ${response.body}', name: 'SyncService');
    }
  }
}
