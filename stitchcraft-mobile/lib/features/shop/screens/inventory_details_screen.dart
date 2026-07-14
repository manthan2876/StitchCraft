import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class InventoryDetailsScreen extends StatefulWidget {
  const InventoryDetailsScreen({super.key});

  @override
  State<InventoryDetailsScreen> createState() => _InventoryDetailsScreenState();
}

class _InventoryDetailsScreenState extends State<InventoryDetailsScreen> {
  final _authService = AuthService();
  bool _isLoading = false;
  Map<String, dynamic>? _item;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_item == null) {
      final itemId = ModalRoute.of(context)!.settings.arguments as String;
      _loadItemDetails(itemId);
    }
  }

  Future<void> _loadItemDetails(String itemId) async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/inventory/$itemId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _item = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load inventory item details');
      }
    } catch (e) {
      developer.log("Error loading inventory item: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.alertRed),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem() async {
    if (_item == null) return;
    final itemId = _item!['_id'] ?? _item!['id'];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Delete Material', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to permanently delete this item from your stock?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.darkGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.alertRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/inventory/$itemId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully'), backgroundColor: AppTheme.trustGreen),
        );
        Navigator.pop(context, true); // Pop details screen and reload list
      } else {
        throw Exception('Failed to delete item');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.alertRed),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editItem() async {
    if (_item == null) return;

    final nameController = TextEditingController(text: _item!['itemName']);
    final typeController = TextEditingController(text: _item!['itemType']);
    final qtyController = TextEditingController(text: _item!['quantity']?.toString());
    final costController = TextEditingController(text: _item!['costPerUnit']?.toString());
    final limitController = TextEditingController(text: _item!['minQuantity']?.toString());
    final unitController = TextEditingController(text: _item!['unit'] ?? 'meters');

    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Material Stock Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Item Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: typeController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Type (Lining, Fabric, Thread, Accessories, Other)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Quantity'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: unitController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Unit (e.g. meters)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: costController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Cost Per Unit (₹)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: limitController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Alert Threshold'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel', style: TextStyle(color: AppTheme.darkGrey)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandPurple),
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final qty = double.tryParse(qtyController.text) ?? 0.0;
                      if (name.isEmpty) return;

                      try {
                        final token = await _authService.getToken();
                        final response = await http.put(
                          Uri.parse('${AuthService.baseUrl}/inventory/${_item!['_id']}'),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer $token',
                          },
                          body: json.encode({
                            'itemName': name,
                            'itemType': typeController.text.trim(),
                            'quantity': qty,
                            'unit': unitController.text.trim(),
                            'costPerUnit': double.tryParse(costController.text) ?? 0.0,
                            'minQuantity': double.tryParse(limitController.text) ?? 5.0,
                          }),
                        );

                        if (response.statusCode == 200) {
                          Navigator.pop(context, true);
                        } else {
                          throw Exception('Failed to update stock');
                        }
                      } catch (e) {
                        developer.log("Error saving edit: $e");
                      }
                    },
                    child: const Text('Save Details', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (updated == true) {
      _loadItemDetails(_item!['_id'] ?? _item!['id']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String title = _item != null ? _item!['itemName'] ?? 'Material' : 'Loading Stock Item...';

    final double quantity = (_item?['quantity'] as num?)?.toDouble() ?? 0.0;
    final double limit = (_item?['minQuantity'] as num?)?.toDouble() ?? 5.0;
    final bool isLowStock = quantity <= limit;
    final String unit = _item?['unit'] ?? 'meters';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title),
        actions: _item != null
            ? [
                IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _editItem),
                IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.alertRed), onPressed: _deleteItem),
              ]
            : null,
      ),
      body: _isLoading && _item == null
          ? const Center(child: CircularProgressIndicator())
          : _item == null
              ? const Center(child: Text('Failed to load item', style: TextStyle(color: Colors.white)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Inventory specs NeoCard
                      NeoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _item!['itemName'] ?? 'Material',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isLowStock ? AppTheme.alertRed : AppTheme.trustGreen).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isLowStock ? 'LOW STOCK' : 'IN STOCK',
                                    style: TextStyle(
                                      color: isLowStock ? AppTheme.alertRed : AppTheme.trustGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white10, height: 24),
                            _infoRow('Item Category', _item!['itemType'] ?? 'General'),
                            _infoRow('Quantity Available', '$quantity $unit'),
                            _infoRow('Cost Per Unit', '₹${_item!['costPerUnit'] ?? 0}/$unit'),
                            _infoRow('Min Warning Limit', '$limit $unit'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.darkGrey)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
