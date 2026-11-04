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

  final List<String> _categories = [
    'Fabric',
    'Lining',
    'Thread',
    'Accessories',
    'Buttons & Zips',
    'Other',
  ];

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.alertRed),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem() async {
    if (_item == null) return;
    final itemId = _item!['_id'] ?? _item!['id'];
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final theme = Theme.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardTheme.color,
        title: Text(
          'Delete Material',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to permanently delete this item from your stock?',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
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
        messenger.showSnackBar(
          const SnackBar(content: Text('Item deleted successfully'), backgroundColor: AppTheme.trustGreen),
        );
        nav.pop(true);
      } else {
        throw Exception('Failed to delete item');
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.alertRed),
      );
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editItem() async {
    if (_item == null) return;
    final theme = Theme.of(context);

    final nameController = TextEditingController(text: _item!['itemName']);
    String selectedCategory = _item!['itemType'] ?? 'Fabric';
    if (!_categories.contains(selectedCategory)) selectedCategory = 'Other';
    final qtyController = TextEditingController(text: _item!['quantity']?.toString());
    final costController = TextEditingController(text: _item!['costPerUnit']?.toString());
    final limitController = TextEditingController(text: _item!['minQuantity']?.toString());
    final unitController = TextEditingController(text: _item!['unit'] ?? 'meters');

    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Material Stock Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(modalCtx, false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: const InputDecoration(labelText: 'Item Name'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    dropdownColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                    decoration: const InputDecoration(labelText: 'Category'),
                    value: selectedCategory,
                    items: _categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(
                          cat,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: const InputDecoration(labelText: 'Quantity'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: unitController,
                          style: TextStyle(color: theme.colorScheme.onSurface),
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
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: const InputDecoration(labelText: 'Cost Per Unit (₹)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: limitController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: theme.colorScheme.onSurface),
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
                        onPressed: () => Navigator.pop(modalCtx, false),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandPurple,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final qty = double.tryParse(qtyController.text) ?? 0.0;
                          if (name.isEmpty) return;

                          final nav = Navigator.of(modalCtx);
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
                                'itemType': selectedCategory,
                                'quantity': qty,
                                'unit': unitController.text.trim(),
                                'costPerUnit': double.tryParse(costController.text) ?? 0.0,
                                'minQuantity': double.tryParse(limitController.text) ?? 5.0,
                              }),
                            );

                            if (response.statusCode == 200) {
                              nav.pop(true);
                            } else {
                              throw Exception('Failed to update stock');
                            }
                          } catch (e) {
                            developer.log("Error saving edit: $e");
                          }
                        },
                        child: const Text('Save Details', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (updated == true && mounted) {
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
              ? Center(
                  child: Text(
                    'Failed to load item',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                )
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
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                            const Divider(height: 24),
                            _infoRow(theme, 'Item Category', _item!['itemType'] ?? 'General'),
                            _infoRow(theme, 'Quantity Available', '$quantity $unit'),
                            _infoRow(theme, 'Cost Per Unit', '₹${_item!['costPerUnit'] ?? 0}/$unit'),
                            _infoRow(theme, 'Min Warning Limit', '$limit $unit'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
