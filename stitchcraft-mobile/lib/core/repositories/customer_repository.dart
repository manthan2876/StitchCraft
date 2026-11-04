import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/utils/phone_utils.dart';

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
    final localList = await _localDb.getAllCustomers();
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
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          return json.decode(response.body) as Map<String, dynamic>;
        }
      }
    } catch (e) {
      developer.log('CustomerRepository.getCustomerProfile server note: $e', name: 'CustomerRepository');
    }

    return await _localDb.getRecordById('customers', customerId);
  }

  Future<Map<String, dynamic>> createCustomer({
    required String name,
    required String phone,
    String? email,
    String? address,
    Map<String, dynamic>? measurements,
  }) async {
    final cleanPhone = PhoneUtils.sanitizePhoneNumber(phone);
    if (cleanPhone.length < 10) {
      throw ArgumentError('Please enter a valid 10-digit mobile number.');
    }

    final token = await _authService.getToken();
    final idempotencyKey = 'cust_repo_${DateTime.now().millisecondsSinceEpoch}';

    final response = await http.post(
      Uri.parse('${AuthService.baseUrl}/customers'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Idempotency-Key': idempotencyKey,
      },
      body: json.encode({
        'name': name.trim(),
        'phone': cleanPhone,
        if (email != null && email.isNotEmpty) 'email': email.trim(),
        if (address != null && address.isNotEmpty) 'address': address.trim(),
        'measurements': ?measurements,
        'idempotencyKey': idempotencyKey,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final remoteId = data['_id'] ?? data['id'];
      if (remoteId != null) {
        await _localDb.insertRecord('customers', {
          'id': remoteId,
          'name': name.trim(),
          'phone': cleanPhone,
          'email': email ?? '',
          'sync_status': 0,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
      }
      return data;
    } else {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to create customer');
    }
  }
}

