import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/config/api_config.dart';
import 'dart:developer' as developer;

class SyncService {
  final _localDb = LocalDatabaseService();
  final _authService = AuthService();

  static String get baseUrl => ApiConfig.baseUrl;

  Future<String?> _getToken() async {
    return _authService.getToken();
  }

  Future<String?> _getShopId() async {
    final prefs = await SharedPreferences.getInstance();
    var shopId = prefs.getString('shopId');
    if (shopId != null && shopId.isNotEmpty) {
      return shopId;
    }

    // Attempt retrieval from cached user profile
    final userId = prefs.getString('userId');
    if (userId != null) {
      final user = await _localDb.getRecordById('users', userId);
      if (user != null && user['shop_id'] != null) {
        shopId = user['shop_id'].toString();
        await prefs.setString('shopId', shopId);
        return shopId;
      }
    }
    return null;
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
          if (rec['sync_status'] == 2 || rec['sync_status'] == 4) {
            final isValidationError = rec['sync_status'] == 4;
            failedRecords.add({
              'table': table,
              'id': rec['id']?.toString() ?? '',
              'title': isValidationError
                  ? 'Invalid Data: ${rec['name'] ?? rec['customer_name'] ?? rec['id']}'
                  : (rec['customerName']?.toString() ??
                      rec['name']?.toString() ??
                      rec['category']?.toString() ??
                      rec['id']?.toString() ??
                      'Pending Delete'),
            });
          }
        }
      }

      final failedMutations = await _localDb.getFailedMutations();
      for (final mut in failedMutations) {
        failedRecords.add({
          'table': mut['table_name'] ?? 'mutation_outbox',
          'id': mut['id']?.toString() ?? '',
          'title': mut['conflict_state'] == 'conflict'
              ? 'Conflict: ${mut['action']} on ${mut['table_name']}'
              : 'Failed: ${mut['last_error'] ?? mut['action']}',
        });
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

  /// Process queued mutations with exponential backoff and idempotency (Phase 2, 6.4)
  Future<void> processMutationOutbox(String token) async {
    final pending = await _localDb.getPendingMutations();
    if (pending.isEmpty) return;

    developer.log('Processing ${pending.length} outbox mutations grouped by dependency...', name: 'SyncService');

    for (final mutation in pending) {
      final mutationId = (mutation['client_mutation_id'] ?? mutation['id']).toString();
      final table = (mutation['entity_type'] ?? mutation['table_name'] ?? '').toString();
      final action = (mutation['operation'] ?? mutation['action'] ?? '').toString();
      final recordId = (mutation['entity_id'] ?? mutation['record_id'] ?? '').toString();
      final idempotencyKey = (mutation['client_mutation_id'] ?? mutation['idempotency_key'] ?? mutationId).toString();
      final Map<String, dynamic> payload = json.decode(mutation['payload'] as String);

      if (mutation['base_version'] != null && payload['base_version'] == null) {
        payload['base_version'] = mutation['base_version'];
      }

      final endpoint = table == 'expenses' ? 'ledger/expenses' : table;
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Idempotency-Key': idempotencyKey,
      };

      // Mark in-flight processing for restart-safety
      await _localDb.markMutationProcessing(mutationId);

      try {
        if (action == 'payment') {
          final res = await http.post(
            Uri.parse('$baseUrl/orders/$recordId/payments'),
            headers: headers,
            body: json.encode(payload),
          ).timeout(const Duration(seconds: 15));

          if (res.statusCode == 200 || res.statusCode == 201) {
            await _localDb.markMutationSuccess(mutationId);
          } else if (res.statusCode == 409) {
            await _localDb.markMutationConflict(mutationId, 'Payment conflict: ${res.body}');
          } else if (res.statusCode >= 400 && res.statusCode < 500) {
            await _localDb.markMutationFailure(mutationId, 'Validation error: ${res.body}', terminal: true);
          } else {
            await _localDb.markMutationFailure(mutationId, 'Server error: ${res.statusCode}');
          }
        } else if (action == 'delete') {
          final res = await http.delete(
            Uri.parse('$baseUrl/$endpoint/$recordId'),
            headers: headers,
          ).timeout(const Duration(seconds: 15));

          if (res.statusCode == 200 || res.statusCode == 204 || res.statusCode == 404) {
            await _localDb.markMutationSuccess(mutationId);
            await _localDb.deleteRecordPermanently(table, recordId);
          } else {
            await _localDb.markMutationFailure(mutationId, 'Delete failed: ${res.statusCode}');
          }
        } else if (action == 'update') {
          final res = await http.put(
            Uri.parse('$baseUrl/$endpoint/$recordId'),
            headers: headers,
            body: json.encode(payload),
          ).timeout(const Duration(seconds: 15));

          if (res.statusCode == 200) {
            await _localDb.markMutationSuccess(mutationId);
            await _localDb.updateSyncStatus(table, recordId, 0);
          } else if (res.statusCode == 409) {
            await _localDb.markMutationConflict(mutationId, 'Conflict: concurrent modification detected');
          } else if (res.statusCode >= 400 && res.statusCode < 500) {
            await _localDb.markMutationFailure(mutationId, 'Validation error: ${res.body}', terminal: true);
          } else {
            await _localDb.markMutationFailure(mutationId, 'Server error: ${res.statusCode}');
          }
        } else {
          // create
          final res = await http.post(
            Uri.parse('$baseUrl/$endpoint'),
            headers: headers,
            body: json.encode(payload),
          ).timeout(const Duration(seconds: 15));

          if (res.statusCode == 200 || res.statusCode == 201) {
            await _localDb.markMutationSuccess(mutationId);
            await _localDb.updateSyncStatus(table, recordId, 0);
          } else if (res.statusCode == 409) {
            await _localDb.markMutationConflict(mutationId, 'Duplicate/conflict: record already exists');
          } else if (res.statusCode >= 400 && res.statusCode < 500) {
            await _localDb.markMutationFailure(mutationId, 'Validation error: ${res.body}', terminal: true);
          } else {
            await _localDb.markMutationFailure(mutationId, 'Server error: ${res.statusCode}');
          }
        }
      } catch (e) {
        developer.log('Outbox execution error for $mutationId: $e', name: 'SyncService');
        await _localDb.markMutationFailure(mutationId, e.toString());
      }
    }
  }

  /// Sync all tables with progress callback
  Future<void> syncAll({
    Function(String table, int current, int total)? onProgress,
  }) async {
    developer.log('Starting full REST sync...', name: 'SyncService');

    final initialToken = await _getToken();
    if (initialToken == null || initialToken.isEmpty) {
      throw StateError('Please sign in to sync your shop data.');
    }
    String token = initialToken;

    // 1. Recover in-flight mutations from potential crash (restart-safe - Phase 2, 6.4)
    try {
      await _localDb.recoverInFlightMutations();
    } catch (recoverErr) {
      developer.log('Warning: error recovering in-flight mutations: $recoverErr', name: 'SyncService');
    }

    // 2. Process queued mutations in durable outbox first (Phase 2, 6.4)
    try {
      await processMutationOutbox(token);
    } catch (outboxErr) {
      developer.log('Warning: error processing mutation outbox: $outboxErr', name: 'SyncService');
    }

    final tables = ['customers', 'orders', 'expenses', 'inventory'];
    final List<String> errors = [];

    for (int i = 0; i < tables.length; i++) {
      final table = tables[i];
      onProgress?.call(table, i + 1, tables.length);
      try {
        await syncTable(table, token);
      } catch (e) {
        // If 401 encountered, attempt a token refresh and retry this table once
        if (e.toString().contains('401') || e.toString().contains('Session expired')) {
          developer.log('Token expired during sync. Attempting session refresh...', name: 'SyncService');
          final refreshed = await _authService.refreshToken();
          if (refreshed != null && refreshed.isNotEmpty) {
            token = refreshed;
            try {
              await syncTable(table, token);
              continue; // Succeeded after refresh
            } catch (retryError) {
              errors.add('$table: $retryError');
              developer.log('Retry failed for $table: $retryError', name: 'SyncService');
              continue;
            }
          }
        }

        errors.add('$table: $e');
        developer.log('Failed to sync table $table: $e', name: 'SyncService');
      }
    }

    if (errors.isNotEmpty) {
      // Pick the most helpful human-readable error
      if (errors.any((e) => e.contains('Session expired') || e.contains('401'))) {
        throw StateError('Session expired. Please sign in again.');
      }
      if (errors.any((e) => e.contains('Could not reach server') || e.contains('SocketException') || e.contains('TimeoutException'))) {
        throw StateError('Unable to connect to server. Check your internet connection.');
      }
      final first = errors.first
          .replaceFirst('Bad state: ', '')
          .replaceFirst('StateError: ', '');
      throw StateError(first);
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
          try {
            final deleteResponse = await http.delete(
              Uri.parse('$baseUrl/$endpoint/$id'),
              headers: {'Authorization': 'Bearer $token'},
            ).timeout(const Duration(seconds: 15));

            if (deleteResponse.statusCode == 200 ||
                deleteResponse.statusCode == 204 ||
                deleteResponse.statusCode == 404) {
              await _localDb.deleteRecordPermanently(table, id);
            }
          } catch (e) {
            developer.log('Delete sync error for $id: $e', name: 'SyncService');
          }
          continue;
        }

        if (syncStatus == 1 || syncStatus == 3) {
          final payload = Map<String, dynamic>.from(record);
          payload.remove('sync_status');
          payload['shopId'] = shopId;

          // Mapping customizations for Node Express backend schema validation
          if (table == 'customers') {
            final rawName = (record['name'] ?? '').toString().trim();
            final rawPhone = (record['phone'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
            if (rawPhone.length < 10) {
              developer.log('Skipping customer $id: invalid phone number ($rawPhone)', name: 'SyncService');
              await _localDb.updateRecord(table, id, {
                'sync_status': 4, // 4 = validation error
                'updated_at': DateTime.now().millisecondsSinceEpoch,
              });
              continue;
            }
            payload['name'] = rawName.isNotEmpty ? rawName : 'Customer';
            payload['phone'] = rawPhone;
            payload['email'] = record['email'] ?? '';
            payload['idempotencyKey'] = 'cust_$id';
          }

          if (table == 'orders') {
            final measurements = await _localDb.getRecords(
              'measurements',
              where: 'order_id = ?',
              whereArgs: [id],
            );
            if (measurements.isNotEmpty) {
              final firstMeasure = measurements.first;
              final measurementsJson = firstMeasure['measurements_json'] as String?;
              final Map<String, dynamic> parsedMeasurements =
                  measurementsJson != null ? json.decode(measurementsJson) : {};

              final apparelType = record['apparelType'] ??
                  record['item_types']?.toString().split(',').first ??
                  'Shirt';
              payload['measurementsSnapshot'] = {
                apparelType.toString().toLowerCase().contains('pant')
                    ? 'pant'
                    : 'shirt': parsedMeasurements,
              };
            }

            payload['customerName'] = record['customer_name'] ?? 'Customer';
            payload['customerId'] = record['customer_id'];
            payload['apparelType'] = record['apparelType'] ??
                record['item_types']?.toString().split(',').first ??
                'Shirt';

            final dueDateVal = record['due_date'];
            if (dueDateVal is int) {
              payload['deliveryDate'] = DateTime.fromMillisecondsSinceEpoch(dueDateVal).toUtc().toIso8601String();
            } else if (dueDateVal != null) {
              payload['deliveryDate'] = DateTime.tryParse(dueDateVal.toString())?.toUtc().toIso8601String() ??
                  DateTime.now().add(const Duration(days: 7)).toUtc().toIso8601String();
            } else {
              payload['deliveryDate'] = DateTime.now().add(const Duration(days: 7)).toUtc().toIso8601String();
            }

            payload['price'] = (record['total_amount'] as num?)?.toDouble() ?? 0.0;
            payload['advancePaid'] = (record['advance_amount'] as num?)?.toDouble() ?? 0.0;
            payload['fabric'] = record['description'] ?? 'Customer Provided';
            payload['fabricImageUrl'] = record['fabric_photo_url'] ?? '';
            payload['status'] = record['status'] ?? 'Incoming';
            payload['needsAster'] = record['astar_required'] == 1;
            payload['asterSellingPrice'] = (record['astar_cost'] as num?)?.toDouble() ?? 0.0;
            payload['idempotencyKey'] = 'order_$id';
          }

          if (table == 'inventory') {
            payload['itemName'] = record['name'] ?? 'Material Item';
            final rawCat = (record['category'] ?? 'Fabric').toString();
            String cat = 'Fabric';
            if (rawCat.toLowerCase().contains('lining')) {
              cat = 'Lining';
            } else if (rawCat.toLowerCase().contains('thread')) {
              cat = 'Thread';
            } else if (rawCat.toLowerCase().contains('access') ||
                rawCat.toLowerCase().contains('button') ||
                rawCat.toLowerCase().contains('zip')) {
              cat = 'Accessories';
            } else if (rawCat.toLowerCase().contains('fabric')) {
              cat = 'Fabric';
            } else {
              cat = 'Other';
            }
            payload['itemType'] = cat;
            payload['quantity'] = (record['quantity'] as num?)?.toDouble() ?? 0.0;
            payload['costPerUnit'] = (record['unit_price'] as num?)?.toDouble() ?? 0.0;
            payload['minQuantity'] = (record['low_stock_threshold'] as num?)?.toDouble() ?? 5.0;
            payload['unit'] = record['unit'] ?? 'meters';
          }

          if (table == 'expenses') {
            payload['category'] = record['category'] ?? 'General';
            payload['amount'] = (record['amount'] as num?)?.toDouble() ?? 0.0;
            payload['description'] = record['description'] ?? '';
            final dateVal = record['date'];
            if (dateVal is int) {
              payload['date'] = DateTime.fromMillisecondsSinceEpoch(dateVal).toUtc().toIso8601String();
            } else if (dateVal != null) {
              payload['date'] = DateTime.tryParse(dateVal.toString())?.toUtc().toIso8601String() ??
                  DateTime.now().toUtc().toIso8601String();
            } else {
              payload['date'] = DateTime.now().toUtc().toIso8601String();
            }
          }

          final headers = {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            if (payload['idempotencyKey'] != null)
              'Idempotency-Key': payload['idempotencyKey'].toString(),
          };

          try {
            if (syncStatus == 3) {
              // PUT update
              final response = await http.put(
                Uri.parse('$baseUrl/$endpoint/$id'),
                headers: headers,
                body: json.encode(payload),
              ).timeout(const Duration(seconds: 15));

              if (response.statusCode == 200) {
                await _localDb.updateSyncStatus(table, id, 0);
                developer.log('Successfully updated $id on server for $table', name: 'SyncService');
              } else if (response.statusCode == 404) {
                // If not found on server, fallback to POST create
                final postResp = await http.post(
                  Uri.parse('$baseUrl/$endpoint'),
                  headers: headers,
                  body: json.encode(payload),
                ).timeout(const Duration(seconds: 15));

                if (postResp.statusCode == 200 || postResp.statusCode == 201) {
                  final respData = json.decode(postResp.body);
                  final serverId = respData['_id'] ?? respData['id'];
                  if (serverId != null && serverId != id) {
                    await _localDb.updateRecordId(table, id, serverId);
                  } else {
                    await _localDb.updateSyncStatus(table, id, 0);
                  }
                }
              } else if (response.statusCode == 401) {
                throw StateError('Session expired. Please sign in again.');
              }
            } else {
              // POST create (syncStatus == 1)
              final response = await http.post(
                Uri.parse('$baseUrl/$endpoint'),
                headers: headers,
                body: json.encode(payload),
              ).timeout(const Duration(seconds: 15));

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
              } else if (response.statusCode == 401) {
                throw StateError('Session expired. Please sign in again.');
              } else {
                developer.log(
                  'Failed to push $table record $id: ${response.statusCode} - ${response.body}',
                  name: 'SyncService',
                );
              }
            }
          } on SocketException catch (_) {
            throw StateError('Could not reach server. Please check your internet connection.');
          } catch (e) {
            if (e is StateError) rethrow;
            developer.log('Push error for $table $id: $e', name: 'SyncService');
          }
        }
      }
    }

    // 2. PULL remote changes from Server
    String getEndpoint = table;
    if (table == 'expenses') {
      getEndpoint = 'ledger/expenses';
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$getEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      developer.log('Pull $table status: ${response.statusCode}', name: 'SyncService');

      if (response.statusCode == 401) {
        throw StateError('Session expired. Please sign in again.');
      }

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        final List<dynamic> remoteData;
        if (decoded is List) {
          remoteData = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          remoteData = decoded['data'] as List;
        } else if (decoded is Map && decoded[table] is List) {
          remoteData = decoded[table] as List;
        } else {
          remoteData = [];
        }

        developer.log(
          'Pulled ${remoteData.length} records from server for $table',
          name: 'SyncService',
        );

        for (final rawRecord in remoteData) {
          if (rawRecord is! Map) continue;
          final Map<String, dynamic> remoteRecord = Map<String, dynamic>.from(rawRecord);
          final String id = (remoteRecord['_id'] ?? remoteRecord['id'] ?? '').toString();
          if (id.isEmpty) continue;

          // Safe pull rule (Phase 2, 6.4): Never overwrite a local record with pending mutations!
          final hasPending = await _localDb.hasPendingMutation(table, id);
          if (hasPending) {
            developer.log('Preserving pending local mutation for $table $id; remote pull overwrite skipped.', name: 'SyncService');
            continue;
          }

          final existingLocal = await _localDb.getRecordById(table, id);
          if (existingLocal != null &&
              (existingLocal['sync_status'] == 1 ||
                  existingLocal['sync_status'] == 2 ||
                  existingLocal['sync_status'] == 3)) {
            developer.log('Preserving unsynced local record for $table $id; remote pull overwrite skipped.', name: 'SyncService');
            continue;
          }

          final Map<String, dynamic> sqliteRecord = {
            'id': id,
            'sync_status': 0,
            'version': (remoteRecord['version'] as num?)?.toInt() ?? 1,
          };

          if (table == 'customers') {
            sqliteRecord['name'] = remoteRecord['name'] ?? 'Customer';
            sqliteRecord['phone'] = remoteRecord['phone'] ?? '';
            sqliteRecord['email'] = remoteRecord['email'] ?? '';
            sqliteRecord['shop_id'] = remoteRecord['shopId'] ?? remoteRecord['shop_id'] ?? shopId;
            sqliteRecord['updated_at'] = DateTime.now().millisecondsSinceEpoch;
          } else if (table == 'orders') {
            sqliteRecord['customer_id'] = remoteRecord['customer'] is Map
                ? (remoteRecord['customer']['_id'] ?? '')
                : (remoteRecord['customer'] ?? '');
            sqliteRecord['customer_name'] =
                remoteRecord['customerName'] ?? 'Walk-in Customer';

            final dynamic rawDate = remoteRecord['date'] ??
                remoteRecord['createdAt'] ??
                remoteRecord['order_date'] ??
                (remoteRecord['payment'] is Map ? remoteRecord['payment']['createdAt'] : null);
            int orderDateMs = DateTime.now().millisecondsSinceEpoch;
            if (rawDate is int) {
              orderDateMs = rawDate;
            } else if (rawDate != null) {
              final parsed = DateTime.tryParse(rawDate.toString());
              if (parsed != null) orderDateMs = parsed.millisecondsSinceEpoch;
            }
            sqliteRecord['order_date'] = orderDateMs;

            final rawDue = remoteRecord['deliveryDate'];
            sqliteRecord['due_date'] = rawDue != null
                ? (DateTime.tryParse(rawDue.toString())?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch)
                : DateTime.now().millisecondsSinceEpoch;

            sqliteRecord['status'] = remoteRecord['status'] ?? 'Incoming';
            sqliteRecord['total_amount'] = (remoteRecord['price'] as num?)?.toDouble() ?? 0.0;
            
            final bool isPartnerJob = remoteRecord['isPartnerJob'] == true ||
                remoteRecord['isOutsourcedToMe'] == true ||
                (remoteRecord['delegatedToShopId'] != null &&
                    remoteRecord['delegatedToShopId'].toString() == shopId &&
                    remoteRecord['shopId'] != null &&
                    remoteRecord['shopId'].toString() != shopId);

            if (isPartnerJob) {
              // Partner tailors must never inherit another tailor's customer advance
              sqliteRecord['advance_amount'] = 0.0;
            } else {
              final double paid = (remoteRecord['payment'] is Map
                      ? (remoteRecord['payment']['paidAmount'] as num?)?.toDouble()
                      : null) ??
                  (remoteRecord['advancePaid'] as num?)?.toDouble() ??
                  (remoteRecord['advance_amount'] as num?)?.toDouble() ??
                  0.0;
              sqliteRecord['advance_amount'] = paid;
            }

            sqliteRecord['payment_method'] = (remoteRecord['payment'] is Map
                    ? remoteRecord['payment']['paymentType']
                    : null) ??
                remoteRecord['paymentMethod'] ??
                'Cash';
            sqliteRecord['description'] = remoteRecord['fabric'] ?? '';
            sqliteRecord['fabric_photo_url'] = remoteRecord['fabricImageUrl'] ?? '';
            sqliteRecord['delegated_to_shop_id'] = remoteRecord['delegatedToShopId'] ?? remoteRecord['delegated_to_shop_id'];
            sqliteRecord['delegated_to_shop_name'] = remoteRecord['delegatedToShopName'] ?? remoteRecord['delegated_to_shop_name'];
            sqliteRecord['delegated_to_phone'] = remoteRecord['delegatedToPhone'] ?? remoteRecord['delegated_to_phone'];
            sqliteRecord['delegation_status'] = remoteRecord['delegationStatus'] ?? remoteRecord['delegation_status'] ?? 'none';
            sqliteRecord['origin_shop_name'] = remoteRecord['originShopName'] ?? remoteRecord['origin_shop_name'];
            sqliteRecord['origin_phone'] = remoteRecord['originPhone'] ?? remoteRecord['origin_phone'];
            sqliteRecord['delegated_notes'] = remoteRecord['delegatedNotes'] ?? remoteRecord['delegated_notes'];
            sqliteRecord['delegated_cost'] = (remoteRecord['delegatedCost'] as num?)?.toDouble() ??
                (remoteRecord['delegated_cost'] as num?)?.toDouble() ??
                0.0;
            sqliteRecord['shop_id'] = remoteRecord['shopId'] ?? remoteRecord['shop_id'] ?? shopId;
            sqliteRecord['updated_at'] = DateTime.now().millisecondsSinceEpoch;
          } else if (table == 'expenses') {
            sqliteRecord['category'] = remoteRecord['category'] ?? 'General';
            sqliteRecord['amount'] = (remoteRecord['amount'] as num?)?.toDouble() ?? 0.0;
            sqliteRecord['description'] = remoteRecord['description'] ?? '';
            sqliteRecord['shop_id'] = remoteRecord['shopId'] ?? remoteRecord['shop_id'] ?? shopId;

            final rawDate = remoteRecord['date'] ?? remoteRecord['createdAt'];
            sqliteRecord['date'] = rawDate != null
                ? (DateTime.tryParse(rawDate.toString())?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch)
                : DateTime.now().millisecondsSinceEpoch;

            sqliteRecord['updated_at'] = DateTime.now().millisecondsSinceEpoch;
          } else if (table == 'inventory') {
            sqliteRecord['name'] = remoteRecord['itemName'] ?? 'Inventory Item';
            sqliteRecord['category'] = remoteRecord['itemType'] ?? 'Accessories';
            sqliteRecord['quantity'] = (remoteRecord['quantity'] as num?)?.toDouble() ?? 0.0;
            sqliteRecord['unit_price'] = (remoteRecord['costPerUnit'] as num?)?.toDouble() ?? 0.0;
            sqliteRecord['low_stock_threshold'] = (remoteRecord['minQuantity'] as num?)?.toDouble() ?? 5.0;
            sqliteRecord['shop_id'] = remoteRecord['shopId'] ?? remoteRecord['shop_id'] ?? shopId;
            sqliteRecord['updated_at'] = DateTime.now().millisecondsSinceEpoch;
          }

          await _localDb.insertRecord(table, sqliteRecord, fromRepository: true);
          if (table == 'orders') DatabaseService.orderSignal.add(null);
          if (table == 'customers') DatabaseService.customerSignal.add(null);
          if (table == 'expenses') DatabaseService.expenseSignal.add(null);
        }
      } else {
        throw StateError('Failed to pull $table records: HTTP ${response.statusCode}');
      }
    } on SocketException catch (_) {
      throw StateError('Could not reach server. Please check your internet connection.');
    } catch (e) {
      if (e is StateError) rethrow;
      developer.log('Pull error for $table: $e', name: 'SyncService');
      throw StateError('Could not sync $table: $e');
    }
  }
}
