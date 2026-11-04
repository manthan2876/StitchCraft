import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
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
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse('${AuthService.baseUrl}/inventory'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(itemData),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final remoteId = data['_id'] ?? data['id'];
      if (remoteId != null) {
        await _localDb.insertRecord('inventory', {
          'id': remoteId,
          'name': itemData['itemName'] ?? itemData['name'],
          'category': itemData['itemType'] ?? itemData['category'],
          'quantity': itemData['quantity'] ?? 0.0,
          'unit_price': itemData['costPerUnit'] ?? 0.0,
          'low_stock_threshold': itemData['minQuantity'] ?? 5.0,
          'sync_status': 0,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
      }
      return data;
    } else {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to add inventory item');
    }
  }

  Future<void> updateInventoryItem(String id, Map<String, dynamic> itemData) async {
    final token = await _authService.getToken();
    final response = await http.put(
      Uri.parse('${AuthService.baseUrl}/inventory/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(itemData),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      await _localDb.updateRecord('inventory', id, {
        if (itemData['itemName'] != null) 'name': itemData['itemName'],
        if (itemData['quantity'] != null) 'quantity': itemData['quantity'],
        if (itemData['costPerUnit'] != null) 'unit_price': itemData['costPerUnit'],
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
    } else {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to update inventory item');
    }
  }

  Future<void> deleteInventoryItem(String id) async {
    final token = await _authService.getToken();
    final response = await http.delete(
      Uri.parse('${AuthService.baseUrl}/inventory/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 204) {
      await _localDb.deleteRecordPermanently('inventory', id);
    } else {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to delete inventory item');
    }
  }
}

