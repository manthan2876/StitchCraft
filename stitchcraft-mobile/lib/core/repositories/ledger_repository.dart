import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/services/database_service.dart';

class LedgerRepository {
  final _authService = AuthService();
  final _localDb = LocalDatabaseService();

  Future<List<Map<String, dynamic>>> getExpenses() async {
    try {
      final token = await _authService.getToken();
      if (token != null) {
        final response = await http.get(
          Uri.parse('${AuthService.baseUrl}/ledger/expenses'),
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
      developer.log('LedgerRepository.getExpenses server note: $e', name: 'LedgerRepository');
    }

    return await _localDb.getAllExpenses();
  }

  Future<Map<String, dynamic>> addExpense({
    required String category,
    required double amount,
    String? description,
    DateTime? date,
    String? expenseId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getString('shopId') ?? '';
    final id = expenseId ?? 'exp_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
    final effectiveDate = date ?? DateTime.now();
    final now = DateTime.now().millisecondsSinceEpoch;

    final entityData = {
      'id': id,
      'category': category,
      'amount': amount,
      'description': description ?? '',
      'date': effectiveDate.millisecondsSinceEpoch,
      'type': 'expense',
      'shop_id': shopId,
      'version': 1,
      'sync_status': 1,
      'updated_at': now,
    };

    final payload = {
      'id': id,
      'category': category,
      'amount': amount,
      'description': description ?? '',
      'date': effectiveDate.toUtc().toIso8601String(),
      'shopId': shopId,
      'idempotencyKey': 'exp_$id',
    };

    final mutationId = await _localDb.executeAtomicMutation(
      shopId: shopId,
      entityType: 'expenses',
      entityId: id,
      operation: 'create',
      entityData: entityData,
      payload: payload,
      clientMutationId: 'exp_$id',
    );

    DatabaseService.expenseSignal.add(null);

    // Opportunistic push if online
    final token = await _authService.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('${AuthService.baseUrl}/ledger/expenses'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'Idempotency-Key': 'exp_$id',
          },
          body: json.encode(payload),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200 || response.statusCode == 201) {
          final serverData = json.decode(response.body) as Map<String, dynamic>;
          await _localDb.markMutationSuccess(mutationId);
          await _localDb.updateSyncStatus('expenses', id, 0);
          return serverData;
        }
      } catch (e) {
        developer.log('Expense create offline, queued in outbox: $e', name: 'LedgerRepository');
      }
    }

    return entityData;
  }

  Future<void> updateExpense(
    String id,
    Map<String, dynamic> updates, {
    int? baseVersion,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getString('shopId') ?? '';
    final existing = await _localDb.getRecordById('expenses', id);
    final currentVersion = baseVersion ?? (existing?['version'] as int?) ?? 1;

    final entityData = Map<String, dynamic>.from(existing ?? {});
    entityData.addAll(updates);
    entityData['id'] = id;
    entityData['version'] = currentVersion + 1;
    entityData['updated_at'] = DateTime.now().millisecondsSinceEpoch;

    final payload = Map<String, dynamic>.from(updates);
    payload['base_version'] = currentVersion;
    payload['shopId'] = shopId;
    final idemKey = 'mut_exp_upd_${id}_${DateTime.now().millisecondsSinceEpoch}';
    payload['clientMutationId'] = idemKey;

    final mutationId = await _localDb.executeAtomicMutation(
      shopId: shopId,
      entityType: 'expenses',
      entityId: id,
      operation: 'update',
      entityData: entityData,
      payload: payload,
      baseVersion: currentVersion,
      clientMutationId: idemKey,
    );

    DatabaseService.expenseSignal.add(null);

    final token = await _authService.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final response = await http.put(
          Uri.parse('${AuthService.baseUrl}/ledger/expenses/$id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'Idempotency-Key': idemKey,
          },
          body: json.encode(payload),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          await _localDb.markMutationSuccess(mutationId);
          await _localDb.updateSyncStatus('expenses', id, 0);
        } else if (response.statusCode == 409) {
          await _localDb.markMutationConflict(mutationId, 'Conflict: concurrent modification');
        }
      } catch (e) {
        developer.log('Expense update offline, queued in outbox: $e', name: 'LedgerRepository');
      }
    }
  }

  Future<void> deleteExpense(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getString('shopId') ?? '';
    final mutationKey = 'mut_exp_del_${id}_${DateTime.now().millisecondsSinceEpoch}';

    final mutationId = await _localDb.executeAtomicMutation(
      shopId: shopId,
      entityType: 'expenses',
      entityId: id,
      operation: 'delete',
      entityData: {'id': id, 'sync_status': 2},
      payload: {'id': id, 'shopId': shopId},
      clientMutationId: mutationKey,
    );

    DatabaseService.expenseSignal.add(null);

    final token = await _authService.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final response = await http.delete(
          Uri.parse('${AuthService.baseUrl}/ledger/expenses/$id'),
          headers: {
            'Authorization': 'Bearer $token',
            'Idempotency-Key': mutationKey,
          },
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200 || response.statusCode == 204) {
          await _localDb.markMutationSuccess(mutationId);
        }
      } catch (e) {
        developer.log('Expense delete offline, queued in outbox: $e', name: 'LedgerRepository');
      }
    }
  }
}
