import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/services/database_service.dart';

class OrderRepository {
  final _authService = AuthService();
  final _localDb = LocalDatabaseService();

  Future<List<Map<String, dynamic>>> getOrders({String? status}) async {
    try {
      final token = await _authService.getToken();
      if (token != null) {
        final uri = Uri.parse('${AuthService.baseUrl}/orders').replace(
          queryParameters: {
            if (status != null && status != 'all') 'status': status,
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
      developer.log('OrderRepository.getOrders server note: $e', name: 'OrderRepository');
    }

    // Fallback to local SQLite cache
    final localOrders = await _localDb.getAllOrders();
    if (status != null && status != 'all') {
      return localOrders.where((o) => (o['status']?.toString().toLowerCase()) == status.toLowerCase()).toList();
    }
    return localOrders;
  }

  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      final token = await _authService.getToken();
      if (token != null) {
        final response = await http.get(
          Uri.parse('${AuthService.baseUrl}/orders/$orderId'),
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
      developer.log('OrderRepository.getOrderById server note: $e', name: 'OrderRepository');
    }

    // Fallback to local record
    return await _localDb.getRecordById('orders', orderId);
  }

  /// Create order with durable local outbox write (Phase 2, 6.1 & 6.2)
  Future<String> createOrder(Map<String, dynamic> orderData) async {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getString('shopId') ?? orderData['shop_id']?.toString() ?? '';
    final orderId = orderData['id']?.toString() ?? 'ord_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
    final now = DateTime.now().millisecondsSinceEpoch;

    final entityData = Map<String, dynamic>.from(orderData);
    entityData['id'] = orderId;
    entityData['shop_id'] = shopId;
    entityData['version'] = 1;
    entityData['sync_status'] = 1;
    entityData['updated_at'] = now;

    final payload = Map<String, dynamic>.from(orderData);
    payload['id'] = orderId;
    payload['shopId'] = shopId;
    payload['idempotencyKey'] = 'order_$orderId';

    final mutationId = await _localDb.executeAtomicMutation(
      shopId: shopId,
      entityType: 'orders',
      entityId: orderId,
      operation: 'create',
      entityData: entityData,
      payload: payload,
      clientMutationId: 'order_$orderId',
    );

    DatabaseService.orderSignal.add(null);

    // Opportunistic push if online
    final token = await _authService.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('${AuthService.baseUrl}/orders'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'Idempotency-Key': 'order_$orderId',
          },
          body: json.encode(payload),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200 || response.statusCode == 201) {
          await _localDb.markMutationSuccess(mutationId);
          await _localDb.updateSyncStatus('orders', orderId, 0);
        }
      } catch (e) {
        developer.log('Order create offline, queued in outbox: $e', name: 'OrderRepository');
      }
    }

    return orderId;
  }

  /// Update order with optimistic concurrency versioning (Phase 2, 6.3)
  Future<void> updateOrder(
    String orderId,
    Map<String, dynamic> updates, {
    int? baseVersion,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getString('shopId') ?? '';
    final existing = await _localDb.getRecordById('orders', orderId);
    final currentVersion = baseVersion ?? (existing?['version'] as int?) ?? 1;

    final entityData = Map<String, dynamic>.from(existing ?? {});
    entityData.addAll(updates);
    entityData['id'] = orderId;
    entityData['version'] = currentVersion + 1;
    entityData['updated_at'] = DateTime.now().millisecondsSinceEpoch;

    final payload = Map<String, dynamic>.from(updates);
    payload['base_version'] = currentVersion;
    payload['shopId'] = shopId;
    final idemKey = 'mut_ord_upd_${orderId}_${DateTime.now().millisecondsSinceEpoch}';
    payload['clientMutationId'] = idemKey;

    final mutationId = await _localDb.executeAtomicMutation(
      shopId: shopId,
      entityType: 'orders',
      entityId: orderId,
      operation: 'update',
      entityData: entityData,
      payload: payload,
      baseVersion: currentVersion,
      clientMutationId: idemKey,
    );

    DatabaseService.orderSignal.add(null);

    // Opportunistic push
    final token = await _authService.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final response = await http.put(
          Uri.parse('${AuthService.baseUrl}/orders/$orderId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'Idempotency-Key': idemKey,
          },
          body: json.encode(payload),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          await _localDb.markMutationSuccess(mutationId);
          await _localDb.updateSyncStatus('orders', orderId, 0);
        } else if (response.statusCode == 409) {
          await _localDb.markMutationConflict(mutationId, 'Conflict: concurrent modification');
        }
      } catch (e) {
        developer.log('Order update offline, queued in outbox: $e', name: 'OrderRepository');
      }
    }
  }

  /// Update order status with delivery credit audit support (Phase 1, 5.3 & Phase 2, 6.3)
  Future<Map<String, dynamic>> updateOrderStatus(
    String orderId,
    String newStatus, {
    int? baseVersion,
    bool allowCredit = false,
    String? creditReason,
  }) async {
    final updates = <String, dynamic>{
      'status': newStatus,
      if (allowCredit) 'allowCredit': true,
      if (creditReason != null && creditReason.isNotEmpty) 'creditReason': creditReason,
    };

    await updateOrder(orderId, updates, baseVersion: baseVersion);
    final updated = await _localDb.getRecordById('orders', orderId);
    return updated ?? {'id': orderId, 'status': newStatus};
  }

  /// Record order payment atomically into order_payments & mutation outbox
  Future<void> recordPayment(
    String orderId,
    double amount,
    String method, {
    String? clientMutationId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getString('shopId') ?? '';
    final normalizedMethod = method.toLowerCase() == 'online' || method.toLowerCase() == 'upi'
        ? 'UPI'
        : (method.toLowerCase() == 'cash' ? 'Cash' : method);

    final now = DateTime.now().millisecondsSinceEpoch;
    final idemKey = clientMutationId ?? 'pay_${orderId}_$now';

    final paymentPayload = {
      'amount': amount,
      'paymentType': normalizedMethod,
      'idempotencyKey': idemKey,
      'shopId': shopId,
    };

    final paymentEntity = {
      'id': 'pay_loc_$now',
      'order_id': orderId,
      'amount': amount,
      'payment_method': normalizedMethod,
      'date': now,
      'shop_id': shopId,
      'sync_status': 1,
      'updated_at': now,
    };

    // Atomic transaction: record payment and outbox row
    final mutationId = await _localDb.executeAtomicMutation(
      shopId: shopId,
      entityType: 'orders',
      entityId: orderId,
      operation: 'payment',
      entityData: paymentEntity,
      payload: paymentPayload,
      clientMutationId: idemKey,
    );

    // Update advance_amount on local order
    final existingOrder = await _localDb.getRecordById('orders', orderId);
    if (existingOrder != null) {
      final currentPaid = (existingOrder['advance_amount'] as num?)?.toDouble() ?? 0.0;
      await _localDb.updateRecord(
        'orders',
        orderId,
        {'advance_amount': currentPaid + amount, 'updated_at': now},
        fromRepository: true,
      );
    }

    DatabaseService.orderSignal.add(null);

    // Opportunistic push
    final token = await _authService.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('${AuthService.baseUrl}/orders/$orderId/payments'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'Idempotency-Key': idemKey,
          },
          body: json.encode(paymentPayload),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200 || response.statusCode == 201) {
          await _localDb.markMutationSuccess(mutationId);
          await _localDb.updateSyncStatus('order_payments', paymentEntity['id'] as String, 0);
        } else if (response.statusCode == 409) {
          await _localDb.markMutationConflict(mutationId, 'Payment conflict: duplicate transaction');
        }
      } catch (e) {
        developer.log('Payment offline, queued in outbox: $e', name: 'OrderRepository');
      }
    }
  }

  Future<void> addOrderNote(String orderId, String noteText) async {
    final token = await _authService.getToken();
    if (token == null || token.isEmpty) return;

    final response = await http.post(
      Uri.parse('${AuthService.baseUrl}/orders/$orderId/notes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'text': noteText}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to add note');
    }
  }
}
