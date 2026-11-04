import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';

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

  Future<Map<String, dynamic>> updateOrderStatus(String orderId, String newStatus) async {
    final token = await _authService.getToken();
    final response = await http.put(
      Uri.parse('${AuthService.baseUrl}/orders/$orderId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'status': newStatus}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      await _localDb.updateRecord('orders', orderId, {
        'status': newStatus,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to update order status');
    }
  }

  Future<void> recordPayment(String orderId, double amount, String method) async {
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse('${AuthService.baseUrl}/orders/$orderId/payments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'amount': amount,
        'paymentType': method,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to record payment');
    }
  }

  Future<void> addOrderNote(String orderId, String noteText) async {
    final token = await _authService.getToken();
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

