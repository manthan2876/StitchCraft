import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';

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
  }) async {
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse('${AuthService.baseUrl}/ledger/expenses'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'category': category,
        'amount': amount,
        'description': description ?? '',
        'date': (date ?? DateTime.now()).toUtc().toIso8601String(),
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final remoteId = data['_id'] ?? data['id'];
      if (remoteId != null) {
        await _localDb.insertRecord('expenses', {
          'id': remoteId,
          'category': category,
          'amount': amount,
          'description': description ?? '',
          'date': (date ?? DateTime.now()).millisecondsSinceEpoch,
          'sync_status': 0,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
      }
      return data;
    } else {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to add expense');
    }
  }

  Future<void> deleteExpense(String id) async {
    final token = await _authService.getToken();
    final response = await http.delete(
      Uri.parse('${AuthService.baseUrl}/ledger/expenses/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 204) {
      await _localDb.deleteRecordPermanently('expenses', id);
    } else {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to delete expense');
    }
  }
}

