import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';

class InventoryRepository {
  final _authService = AuthService();
  final _localDb = LocalDatabaseService();

  Future<List<Map<String, dynamic>>> getInventoryItems() async {
    try {
      final token = await _authService.getToken();
      if (token != null) {
        final response = await http.get(
          Uri.parse('${AuthService.baseUrl}/inventory'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data is List) {
            return data.cast<Map<String, dynamic>>();
          }
        }
      }
    } catch (e) {
      developer.log('InventoryRepository.getInventoryItems server note: $e', name: 'InventoryRepository');
    }

    return await _localDb.getAllInventory();
  }

  Future<Map<String, dynamic>> addInventoryItem(Map<String, dynamic> itemData) async {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getString('shopId') ?? '';
    final id = itemData['id']?.toString() ?? 'inv_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
    final now = DateTime.now().millisecondsSinceEpoch;

    final entityData = {
      'id': id,
      'name': itemData['itemName'] ?? itemData['name'] ?? 'Item',
      'category': itemData['itemType'] ?? itemData['category'] ?? 'General',
      'quantity': (itemData['quantity'] as num?)?.toDouble() ?? 0.0,
      'unit_price': (itemData['costPerUnit'] as num?)?.toDouble() ?? 0.0,
      'low_stock_threshold': (itemData['minQuantity'] as num?)?.toDouble() ?? 5.0,
      'shop_id': shopId,
      'version': 1,
      'sync_status': 1,
      'updated_at': now,
    };

    final payload = Map<String, dynamic>.from(itemData);
    payload['id'] = id;
    payload['shopId'] = shopId;
    final idemKey = 'inv_$id';
    payload['idempotencyKey'] = idemKey;

    final mutationId = await _localDb.executeAtomicMutation(
      shopId: shopId,
      entityType: 'inventory',
      entityId: id,
      operation: 'create',
      entityData: entityData,
      payload: payload,
      clientMutationId: idemKey,
    );

    // Opportunistic push if online
    final token = await _authService.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('${AuthService.baseUrl}/inventory'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'Idempotency-Key': idemKey,
          },
          body: json.encode(payload),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200 || response.statusCode == 201) {
          final serverData = json.decode(response.body) as Map<String, dynamic>;
          await _localDb.markMutationSuccess(mutationId);
          await _localDb.updateSyncStatus('inventory', id, 0);
          return serverData;
        }
      } catch (e) {
        developer.log('Inventory create offline, queued in outbox: $e', name: 'InventoryRepository');
      }
    }

    return entityData;
  }

  Future<void> updateInventoryItem(
    String id,
    Map<String, dynamic> itemData, {
    int? baseVersion,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getString('shopId') ?? '';
    final existing = await _localDb.getRecordById('inventory', id);
    final currentVersion = baseVersion ?? (existing?['version'] as int?) ?? 1;

    final entityData = Map<String, dynamic>.from(existing ?? {});
    if (itemData['itemName'] != null) entityData['name'] = itemData['itemName'];
    if (itemData['name'] != null) entityData['name'] = itemData['name'];
    if (itemData['quantity'] != null) entityData['quantity'] = (itemData['quantity'] as num?)?.toDouble() ?? 0.0;
    if (itemData['costPerUnit'] != null) entityData['unit_price'] = (itemData['costPerUnit'] as num?)?.toDouble() ?? 0.0;
    if (itemData['unit_price'] != null) entityData['unit_price'] = (itemData['unit_price'] as num?)?.toDouble() ?? 0.0;
    entityData['id'] = id;
    entityData['version'] = currentVersion + 1;
    entityData['updated_at'] = DateTime.now().millisecondsSinceEpoch;

    final payload = Map<String, dynamic>.from(itemData);
    payload['base_version'] = currentVersion;
    payload['shopId'] = shopId;
    final idemKey = 'mut_inv_upd_${id}_${DateTime.now().millisecondsSinceEpoch}';
    payload['clientMutationId'] = idemKey;

    final mutationId = await _localDb.executeAtomicMutation(
      shopId: shopId,
      entityType: 'inventory',
      entityId: id,
      operation: 'update',
      entityData: entityData,
      payload: payload,
      baseVersion: currentVersion,
      clientMutationId: idemKey,
    );

    // Opportunistic push
    final token = await _authService.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final response = await http.put(
          Uri.parse('${AuthService.baseUrl}/inventory/$id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'Idempotency-Key': idemKey,
          },
          body: json.encode(payload),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          await _localDb.markMutationSuccess(mutationId);
          await _localDb.updateSyncStatus('inventory', id, 0);
        } else if (response.statusCode == 409) {
          await _localDb.markMutationConflict(mutationId, 'Conflict: concurrent modification');
        }
      } catch (e) {
        developer.log('Inventory update offline, queued in outbox: $e', name: 'InventoryRepository');
      }
    }
  }

  Future<void> deleteInventoryItem(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getString('shopId') ?? '';
    final mutationKey = 'mut_inv_del_${id}_${DateTime.now().millisecondsSinceEpoch}';

    final mutationId = await _localDb.executeAtomicMutation(
      shopId: shopId,
      entityType: 'inventory',
      entityId: id,
      operation: 'delete',
      entityData: {'id': id, 'sync_status': 2},
      payload: {'id': id, 'shopId': shopId},
      clientMutationId: mutationKey,
    );

    final token = await _authService.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final response = await http.delete(
          Uri.parse('${AuthService.baseUrl}/inventory/$id'),
          headers: {
            'Authorization': 'Bearer $token',
            'Idempotency-Key': mutationKey,
          },
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200 || response.statusCode == 204) {
          await _localDb.markMutationSuccess(mutationId);
        }
      } catch (e) {
        developer.log('Inventory delete offline, queued in outbox: $e', name: 'InventoryRepository');
      }
    }
  }
}
