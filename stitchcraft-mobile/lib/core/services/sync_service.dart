import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/config/api_config.dart';
import 'dart:developer' as developer;

class SyncService {
  final _localDb = LocalDatabaseService();

  static String get baseUrl => ApiConfig.baseUrl;

  Future<String?> _getToken() async {
    return AuthService().getToken();
  }

  Future<String?> _getShopId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('shopId');
  }

  /// Get sync status including pending items count
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      int totalPending = 0;
      final tables = ['customers', 'orders', 'expenses', 'inventory'];
      for (final table in tables) {
        final unsynced = await _localDb.getUnsyncedRecords(table);
        totalPending += unsynced.length;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString('lastSyncTime');
      final lastSyncTime = lastSyncStr != null
          ? DateTime.tryParse(lastSyncStr)
          : null;

      return {'pendingCount': totalPending, 'lastSyncTime': lastSyncTime};
    } catch (e) {
      developer.log('Error getting sync status: $e', name: 'SyncService');
      return {'pendingCount': 0, 'lastSyncTime': null};
    }
  }

  /// Get detailed breakdown of pending items and failed records for the sync status screen
  Future<Map<String, dynamic>> getDetailedSyncBreakdown() async {
    try {
      final tables = ['orders', 'customers', 'expenses', 'inventory'];
      final Map<String, int> pendingByTable = {};
      final List<Map<String, dynamic>> failedRecords = [];
      int totalPending = 0;

      for (final table in tables) {
        final unsynced = await _localDb.getUnsyncedRecords(table);
        pendingByTable[table] = unsynced.length;
        totalPending += unsynced.length;
        for (final rec in unsynced) {
          if (rec['sync_status'] == 2) {
            failedRecords.add({
              'table': table,
              'id': rec['id']?.toString() ?? '',
              'title':
                  rec['customerName']?.toString() ??
                  rec['name']?.toString() ??
                  rec['category']?.toString() ??
                  rec['id']?.toString() ??
                  'Record',
            });
          }
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString('lastSyncTime');
      final lastSyncTime = lastSyncStr != null
          ? DateTime.tryParse(lastSyncStr)
          : null;

      return {
        'totalPending': totalPending,
        'pendingByTable': pendingByTable,
        'failedRecords': failedRecords,
        'lastSyncTime': lastSyncTime,
      };
    } catch (e) {
      developer.log(
        'Error getting detailed sync breakdown: $e',
        name: 'SyncService',
      );
      return {
        'totalPending': 0,
        'pendingByTable': {
          'orders': 0,
          'customers': 0,
          'expenses': 0,
          'inventory': 0,
        },
        'failedRecords': <Map<String, dynamic>>[],
        'lastSyncTime': null,
      };
    }
  }

  /// Sync all tables with progress callback
  Future<void> syncAll({
    Function(String table, int current, int total)? onProgress,
  }) async {
    developer.log('Starting full REST sync...', name: 'SyncService');

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      developer.log('Sync skipped: No auth token found.', name: 'SyncService');
      return;
    }

    final tables = ['customers', 'orders', 'expenses', 'inventory'];

    var failedTables = 0;
    for (int i = 0; i < tables.length; i++) {
      final table = tables[i];
      onProgress?.call(table, i + 1, tables.length);
      try {
        await syncTable(table, token);
      } catch (e) {
        failedTables++;
        developer.log('Failed to sync table $table: $e', name: 'SyncService');
      }
    }

    if (failedTables > 0) {
      throw StateError('$failedTables table(s) failed to sync');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastSyncTime', DateTime.now().toIso8601String());

    developer.log('Sync complete.', name: 'SyncService');
  }

  Future<void> syncTable(String table, String token) async {
    final shopId = await _getShopId();
    if (shopId == null || shopId.isEmpty) {
      developer.log(
        'Sync skipped for $table: No active shopId session found.',
        name: 'SyncService',
      );
      return;
    }

    // 1. PUSH local changes to Server
    final unsynced = await _localDb.getUnsyncedRecords(table);
    if (unsynced.isNotEmpty) {
      developer.log(
        'Pushing ${unsynced.length} unsynced records for $table',
        name: 'SyncService',
      );
      for (final record in unsynced) {
        final id = record['id'] as String;
        final syncStatus = record['sync_status'] as int;
        final endpoint = table == 'expenses' ? 'ledger/expenses' : table;

        if (syncStatus == 2) {
          final deleteResponse = await http.delete(
            Uri.parse('$baseUrl/$endpoint/$id'),
            headers: {'Authorization': 'Bearer $token'},
          );
          if (deleteResponse.statusCode != 200 &&
              deleteResponse.statusCode != 204 &&
              deleteResponse.statusCode != 404) {
            throw StateError(
              'Failed to delete $table record $id: ${deleteResponse.statusCode}',
            );
          }
          await _localDb.deleteRecordPermanently(table, id);
          continue;
        }

        if (syncStatus == 1) {
          final payload = Map<String, dynamic>.from(record);
          payload.remove('sync_status');
          payload['shopId'] = shopId;

          // Mapping customizations for Node Express backend
          // Embed measurements snapshot into order if available
          if (table == 'orders') {
            // Read measurements for order
            final measurements = await _localDb.getRecords(
              'measurements',
              where: 'order_id = ?',
              whereArgs: [id],
            );
            if (measurements.isNotEmpty) {
              final firstMeasure = measurements.first;
              final measurementsJson =
                  firstMeasure['measurements_json'] as String?;
              final Map<String, dynamic> parsedMeasurements =
                  measurementsJson != null ? json.decode(measurementsJson) : {};

              final apparelType =
                  record['apparelType'] ??
                  record['item_types']?.toString().split(',').first ??
                  'Shirt';
              payload['measurementsSnapshot'] = {
                apparelType.toString().toLowerCase().contains('pant')
                        ? 'pant'
                        : 'shirt':
                    parsedMeasurements,
              };
            }
            // Format order keys for Mongoose validation rules
            if (record['customer_name'] != null) {
              payload['customerName'] = record['customer_name'];
            }
            if (record['apparelType'] != null || record['item_types'] != null) {
              payload['apparelType'] =
                  record['apparelType'] ??
                  record['item_types']?.toString().split(',').first ??
                  'Shirt';
            }
            if (record['due_date'] != null) {
              payload['deliveryDate'] = DateTime.fromMillisecondsSinceEpoch(
                record['due_date'],
              ).toUtc().toIso8601String();
            }
            if (record['total_amount'] != null) {
              payload['price'] = record['total_amount'];
            }
            if (record['description'] != null) {
              payload['fabric'] = record['description'];
            }
          }

          if (table == 'inventory') {
            payload['itemName'] = record['name'] ?? 'Inventory Item';
            payload['itemType'] = record['category'] ?? 'accessories';
            payload['quantity'] = record['quantity'] ?? 0;
            payload['costPerUnit'] = record['unit_price'] ?? 0;
            payload['minQuantity'] = record['low_stock_threshold'] ?? 10;
          }

          final headers = {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          };

          http.Response response;

          response = await http.post(
            Uri.parse('$baseUrl/$endpoint'),
            headers: headers,
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
            developer.log(
              'Successfully pushed $id to server for $table',
              name: 'SyncService',
            );
          } else {
            throw StateError(
              'Failed to push $table record $id: ${response.statusCode}',
            );
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
      final decoded = json.decode(response.body);
      if (decoded is! List) {
        throw const FormatException('Sync response must be a JSON array');
      }
      final remoteData = decoded;
      developer.log(
        'Pulled ${remoteData.length} records from server for $table',
        name: 'SyncService',
      );

      for (final rawRecord in remoteData) {
        if (rawRecord is! Map) {
          throw const FormatException('Sync record must be a JSON object');
        }
        final Map<String, dynamic> remoteRecord = Map<String, dynamic>.from(
          rawRecord,
        );
        final String id = remoteRecord['_id'] ?? remoteRecord['id'] ?? '';
        if (id.isEmpty) continue;

        // Map backend schema parameters to local SQLite table schemas
        final Map<String, dynamic> sqliteRecord = {'id': id, 'sync_status': 0};

        if (table == 'customers') {
          sqliteRecord['name'] = remoteRecord['name'] ?? 'Unknown';
          sqliteRecord['phone'] = remoteRecord['phone'] ?? '';
          sqliteRecord['email'] = remoteRecord['email'] ?? '';
          sqliteRecord['updated_at'] = DateTime.now().millisecondsSinceEpoch;
        } else if (table == 'orders') {
          sqliteRecord['customer_id'] = remoteRecord['customer'] is Map
              ? remoteRecord['customer']['_id']
              : remoteRecord['customer'] ?? '';
          sqliteRecord['customer_name'] =
              remoteRecord['customerName'] ?? 'Walk-in Customer';
          sqliteRecord['order_date'] = remoteRecord['date'] != null
              ? DateTime.parse(
                  remoteRecord['date'].toString(),
                ).millisecondsSinceEpoch
              : DateTime.now().millisecondsSinceEpoch;
          sqliteRecord['due_date'] = remoteRecord['deliveryDate'] != null
              ? DateTime.parse(
                  remoteRecord['deliveryDate'].toString(),
                ).millisecondsSinceEpoch
              : DateTime.now().millisecondsSinceEpoch;
          sqliteRecord['status'] = remoteRecord['status'] ?? 'Incoming';
          sqliteRecord['total_amount'] =
              (remoteRecord['price'] as num?)?.toDouble() ?? 0.0;
          sqliteRecord['description'] = remoteRecord['fabric'] ?? '';
          sqliteRecord['fabric_photo_url'] =
              remoteRecord['fabricImageUrl'] ?? '';
          sqliteRecord['updated_at'] = DateTime.now().millisecondsSinceEpoch;
        } else if (table == 'expenses') {
          sqliteRecord['category'] = remoteRecord['category'] ?? 'General';
          sqliteRecord['amount'] =
              (remoteRecord['amount'] as num?)?.toDouble() ?? 0.0;
          sqliteRecord['description'] = remoteRecord['description'] ?? '';
          sqliteRecord['date'] = remoteRecord['date'] != null
              ? DateTime.parse(
                  remoteRecord['date'].toString(),
                ).millisecondsSinceEpoch
              : DateTime.now().millisecondsSinceEpoch;
          sqliteRecord['updated_at'] = DateTime.now().millisecondsSinceEpoch;
        } else if (table == 'inventory') {
          sqliteRecord['name'] = remoteRecord['itemName'] ?? 'Inventory Item';
          sqliteRecord['category'] = remoteRecord['itemType'] ?? 'accessories';
          sqliteRecord['quantity'] =
              (remoteRecord['quantity'] as num?)?.toDouble() ?? 0.0;
          sqliteRecord['unit_price'] =
              (remoteRecord['costPerUnit'] as num?)?.toDouble() ?? 0.0;
          sqliteRecord['low_stock_threshold'] =
              (remoteRecord['minQuantity'] as num?)?.toDouble() ?? 10.0;
          sqliteRecord['updated_at'] = DateTime.now().millisecondsSinceEpoch;
        }

        await _localDb.insertRecord(table, sqliteRecord);
        if (table == 'orders') DatabaseService.orderSignal.add(null);
        if (table == 'customers') DatabaseService.customerSignal.add(null);
        if (table == 'expenses') DatabaseService.expenseSignal.add(null);
      }
    } else {
      throw StateError('Failed to pull $table records: ${response.statusCode}');
    }
  }
}
