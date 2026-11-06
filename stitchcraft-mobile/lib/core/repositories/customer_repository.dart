import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:stitchcraft/core/utils/phone_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerRepository {
  final _authService = AuthService();
  final _localDb = LocalDatabaseService();

  Future<List<Map<String, dynamic>>> getCustomers({String? search}) async {
    try {
      final token = await _authService.getToken();
      if (token != null) {
        final uri = Uri.parse('${AuthService.baseUrl}/customers').replace(
          queryParameters: {
            if (search != null && search.isNotEmpty) 'search': search,
          },
        );
        final response = await http.get(
          uri,
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
      developer.log('CustomerRepository.getCustomers server note: $e', name: 'CustomerRepository');
    }

    // Fallback to local SQLite cache
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getString('shopId');
    final localList = await _localDb.getAllCustomers(shopId: shopId);
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      return localList.where((c) {
        final name = (c['name'] ?? '').toString().toLowerCase();
        final phone = (c['phone'] ?? '').toString();
        return name.contains(q) || phone.contains(q);
      }).toList();
    }
    return localList;
  }

  Future<Map<String, dynamic>?> getCustomerProfile(String customerId) async {
    try {
      final token = await _authService.getToken();
      if (token != null) {
        final response = await http.get(
          Uri.parse('${AuthService.baseUrl}/customers/$customerId/profile'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          return json.decode(response.body) as Map<String, dynamic>;
        }
      }
    } catch (e) {
      developer.log('CustomerRepository.getCustomerProfile server note: $e', name: 'CustomerRepository');
    }

    return await _localDb.getRecordById('customers', customerId);
  }

  /// Create customer with durable local outbox write (Phase 2, 6.1 & 6.2)
  Future<Map<String, dynamic>> createCustomer({
    required String name,
    required String phone,
    String? email,
    String? address,
    Map<String, dynamic>? measurements,
    String? customerId,
  }) async {
    final cleanPhone = PhoneUtils.sanitizePhoneNumber(phone);
    if (cleanPhone.length < 10) {
      throw ArgumentError('Please enter a valid 10-digit mobile number.');
    }

    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getString('shopId') ?? '';
    final id = customerId ?? 'cust_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
    final now = DateTime.now().millisecondsSinceEpoch;

    final entityData = {
      'id': id,
      'name': name.trim(),
      'phone': cleanPhone,
      'email': email?.trim() ?? '',
      'shop_id': shopId,
      'version': 1,
      'sync_status': 1,
      'updated_at': now,
    };

    final payload = {
      'id': id,
      'name': name.trim(),
      'phone': cleanPhone,
      if (email != null && email.isNotEmpty) 'email': email.trim(),
      if (address != null && address.isNotEmpty) 'address': address.trim(),
      'measurements': ?measurements,
      'shopId': shopId,
      'idempotencyKey': 'cust_$id',
    };

    // Atomic write to customer table and mutation_outbox
    final mutationId = await _localDb.executeAtomicMutation(
      shopId: shopId,
      entityType: 'customers',
      entityId: id,
      operation: 'create',
      entityData: entityData,
      payload: payload,
      clientMutationId: 'cust_$id',
    );

    DatabaseService.customerSignal.add(null);

    // Opportunistic background push if network is available
    final token = await _authService.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('${AuthService.baseUrl}/customers'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'Idempotency-Key': 'cust_$id',
          },
          body: json.encode(payload),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200 || response.statusCode == 201) {
          final serverData = json.decode(response.body) as Map<String, dynamic>;
          await _localDb.markMutationSuccess(mutationId);
          await _localDb.updateSyncStatus('customers', id, 0);
          return serverData;
        }
      } catch (e) {
        developer.log('Opportunistic push skipped, enqueued in outbox: $e', name: 'CustomerRepository');
      }
    }

    return entityData;
  }

  /// Update customer profile with optimistic versioning (Phase 2, 6.3)
  Future<void> updateCustomer(
    String id,
    Map<String, dynamic> updates, {
    int? baseVersion,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getString('shopId') ?? '';
    final existing = await _localDb.getRecordById('customers', id);
    final currentVersion = baseVersion ?? (existing?['version'] as int?) ?? 1;

    final entityData = Map<String, dynamic>.from(existing ?? {});
    entityData.addAll(updates);
    entityData['id'] = id;
    entityData['version'] = currentVersion + 1;
    entityData['updated_at'] = DateTime.now().millisecondsSinceEpoch;

    final payload = Map<String, dynamic>.from(updates);
    payload['base_version'] = currentVersion;
    payload['shopId'] = shopId;
    payload['clientMutationId'] = 'mut_cust_upd_${id}_${DateTime.now().millisecondsSinceEpoch}';

    final mutationId = await _localDb.executeAtomicMutation(
      shopId: shopId,
      entityType: 'customers',
      entityId: id,
      operation: 'update',
      entityData: entityData,
      payload: payload,
      baseVersion: currentVersion,
      clientMutationId: payload['clientMutationId'] as String,
    );

    DatabaseService.customerSignal.add(null);

    // Opportunistic online push
    final token = await _authService.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final response = await http.put(
          Uri.parse('${AuthService.baseUrl}/customers/$id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'Idempotency-Key': payload['clientMutationId'].toString(),
          },
          body: json.encode(payload),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          await _localDb.markMutationSuccess(mutationId);
          await _localDb.updateSyncStatus('customers', id, 0);
        } else if (response.statusCode == 409) {
          await _localDb.markMutationConflict(mutationId, 'Conflict: concurrent modification');
        }
      } catch (e) {
        developer.log('Customer update offline, enqueued in outbox: $e', name: 'CustomerRepository');
      }
    }
  }

  /// Soft delete customer via durable outbox
  Future<void> deleteCustomer(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getString('shopId') ?? '';
    final mutationKey = 'mut_cust_del_${id}_${DateTime.now().millisecondsSinceEpoch}';

    final mutationId = await _localDb.executeAtomicMutation(
      shopId: shopId,
      entityType: 'customers',
      entityId: id,
      operation: 'delete',
      entityData: {'id': id, 'sync_status': 2},
      payload: {'id': id, 'shopId': shopId},
      clientMutationId: mutationKey,
    );

    DatabaseService.customerSignal.add(null);

    final token = await _authService.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final response = await http.delete(
          Uri.parse('${AuthService.baseUrl}/customers/$id'),
          headers: {
            'Authorization': 'Bearer $token',
            'Idempotency-Key': mutationKey,
          },
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200 || response.statusCode == 204) {
          await _localDb.markMutationSuccess(mutationId);
        }
      } catch (e) {
        developer.log('Customer delete queued in outbox: $e', name: 'CustomerRepository');
      }
    }
  }
}
