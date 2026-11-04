import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';
import 'package:stitchcraft/core/widgets/custom_app_bar.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _authService = AuthService();
  List<dynamic> _items = [];
  bool _isLoading = false;

  final List<String> _categories = [
    'Fabric',
    'Lining',
    'Thread',
    'Accessories',
    'Buttons & Zips',
    'Other',
  ];

  bool _showOnlyLowStock = false;

  Future<void> _quickAdjustStock(Map<String, dynamic> item, double delta, {bool isUndo = false}) async {
    final id = item['_id'] ?? item['id'];
    if (id == null) return;
    final currentQty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
    final newQty = (currentQty + delta).clamp(0.0, double.infinity);
    final unit = item['unit'] ?? 'meters';
    final name = item['itemName'] ?? 'Material';

    setState(() {
      item['quantity'] = newQty;
    });

    try {
      await _localDb.updateRecord('inventory', id.toString(), {
        'quantity': newQty,
        'sync_status': 3,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      final token = await _authService.getToken();
      if (token != null) {
        http.put(
          Uri.parse('${AuthService.baseUrl}/inventory/$id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({'quantity': newQty}),
        );
      }

      if (mounted && !isUndo) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name: $newQty $unit'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Undo',
              textColor: AppTheme.warmAmber,
              onPressed: () => _quickAdjustStock(item, -delta, isUndo: true),
            ),
          ),
        );
      }
    } catch (e) {
      developer.log("Error quick adjusting stock: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      if (token == null) {
        await _loadOfflineFallback();
        return;
      }

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/inventory'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as List;
        setState(() {
          _items = decoded;
        });

        // Cache locally for offline access
        for (final it in decoded) {
          try {
            await LocalDatabaseService().insertRecord('inventory', {
              'id': it['_id'] ?? it['id'] ?? '',
              'name': it['itemName'] ?? '',
              'category': it['itemType'] ?? 'General',
              'quantity': (it['quantity'] as num?)?.toDouble() ?? 0.0,
              'unit_price': (it['costPerUnit'] as num?)?.toDouble() ?? 0.0,
              'low_stock_threshold': (it['minQuantity'] as num?)?.toDouble() ?? 5.0,
              'sync_status': 0,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            });
          } catch (_) {}
        }
      } else {
        await _loadOfflineFallback();
      }
    } catch (e) {
      developer.log("Error loading inventory from network: $e");
      await _loadOfflineFallback();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadOfflineFallback() async {
    try {
      final local = await LocalDatabaseService().getRecords('inventory');
      if (local.isNotEmpty && mounted) {
        setState(() {
          _items = local.map((row) => {
            '_id': row['id'],
            'itemName': row['name'],
            'itemType': row['category'],
            'quantity': row['quantity'],
            'costPerUnit': row['unit_price'],
            'minQuantity': row['low_stock_threshold'],
            'unit': 'meters',
          }).toList();
        });
      }
    } catch (e) {
      developer.log("Offline inventory fallback error: $e");
    }
  }

  Future<void> _showItemForm({Map<String, dynamic>? item}) async {
    final theme = Theme.of(context);
    final isEdit = item != null;
    final nameController = TextEditingController(text: isEdit ? item['itemName'] : '');
    String selectedCategory = isEdit
        ? (item['itemType'] ?? 'Fabric')
        : 'Fabric';
    if (!_categories.contains(selectedCategory)) {
      selectedCategory = 'Other';
    }
    final qtyController = TextEditingController(text: isEdit ? item['quantity'].toString() : '');
    final priceController = TextEditingController(text: isEdit ? item['costPerUnit'].toString() : '');

    await showModalBottomSheet(
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
                        isEdit ? context.loc.edit_material : context.loc.add_material,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: const InputDecoration(labelText: 'Item Name'),
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: const InputDecoration(labelText: 'Unit Price (₹)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandPurple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final qty = double.tryParse(qtyController.text) ?? 0.0;
                        final price = double.tryParse(priceController.text) ?? 0.0;

                        if (name.isNotEmpty) {
                          Navigator.pop(modalCtx);
                          setState(() => _isLoading = true);
                          try {
                            final token = await _authService.getToken();
                            if (token == null) return;

                            final body = json.encode({
                              'itemName': name,
                              'itemType': selectedCategory,
                              'quantity': qty,
                              'unit': isEdit ? (item['unit'] ?? 'meters') : 'meters',
                              'minQuantity': isEdit ? (item['minQuantity'] ?? 5.0) : 5.0,
                              'costPerUnit': price,
                              'purchaseAmount': qty * price,
                              'description': isEdit ? (item['description'] ?? 'Updated from mobile') : 'Added from mobile app',
                            });

                            final response = isEdit
                                ? await http.put(
                                    Uri.parse('${AuthService.baseUrl}/inventory/${item['_id']}'),
                                    headers: {
                                      'Content-Type': 'application/json',
                                      'Authorization': 'Bearer $token',
                                    },
                                    body: body,
                                  )
                                : await http.post(
                                    Uri.parse('${AuthService.baseUrl}/inventory'),
                                    headers: {
                                      'Content-Type': 'application/json',
                                      'Authorization': 'Bearer $token',
                                    },
                                    body: body,
                                  );

                            if (response.statusCode == 200 || response.statusCode == 201) {
                              _loadInventory();
                            } else {
                              developer.log("Failed to save inventory item: ${response.body}");
                              setState(() => _isLoading = false);
                            }
                          } catch (e) {
                            developer.log("Error saving inventory item: $e");
                            setState(() => _isLoading = false);
                          }
                        }
                      },
                      child: Text(
                        isEdit ? context.loc.save : context.loc.add,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    nameController.dispose();
    qtyController.dispose();
    priceController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lowStockItems = _items.where((i) {
      final qty = (i['quantity'] as num?)?.toDouble() ?? 0.0;
      final min = (i['minQuantity'] as num?)?.toDouble() ?? 5.0;
      return qty <= min;
    }).toList();

    final displayedItems = _showOnlyLowStock ? lowStockItems : _items;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(title: context.loc.inventory_stock),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemForm(),
        backgroundColor: AppTheme.brandPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Filter Chips: All vs Low Stock
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text('All (${_items.length})'),
                  selected: !_showOnlyLowStock,
                  onSelected: (val) => setState(() => _showOnlyLowStock = false),
                  selectedColor: AppTheme.brandPurple.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: !_showOnlyLowStock ? AppTheme.brandPurple : null,
                    fontWeight: !_showOnlyLowStock ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Low Stock (${lowStockItems.length})'),
                  selected: _showOnlyLowStock,
                  onSelected: (val) => setState(() => _showOnlyLowStock = true),
                  selectedColor: AppTheme.alertRed.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: _showOnlyLowStock ? AppTheme.alertRed : null,
                    fontWeight: _showOnlyLowStock ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayedItems.isEmpty
                    ? Center(
                        child: Text(
                          _showOnlyLowStock ? 'No low stock items!' : 'No items found.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadInventory,
                        color: AppTheme.brandPurple,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: displayedItems.length,
                          itemBuilder: (context, index) {
                            final item = displayedItems[index];
                            final String name = item['itemName'] ?? 'Material';
                            final String type = item['itemType'] ?? 'General';
                            final double quantity = (item['quantity'] as num?)?.toDouble() ?? 0.0;
                            final double price = (item['costPerUnit'] as num?)?.toDouble() ?? 0.0;
                            final double limit = (item['minQuantity'] as num?)?.toDouble() ?? 5.0;
                            final bool isLowStock = quantity <= limit;
                            final String unit = item['unit'] ?? 'meters';

                            return NeoCard(
                              onTap: () async {
                                final reload = await Navigator.pushNamed(
                                  context,
                                  '/inventory_details',
                                  arguments: item['_id'] ?? item['id'] ?? '',
                                );
                                if (reload == true) {
                                  _loadInventory();
                                }
                              },
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isLowStock
                                          ? AppTheme.alertRed.withValues(alpha: 0.15)
                                          : AppTheme.brandPurple.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.inventory_2_outlined,
                                      color: isLowStock ? AppTheme.alertRed : AppTheme.brandPurple,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '$type • ₹$price/$unit',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: quantity > 0
                                                ? () => _quickAdjustStock(item, -1.0)
                                                : null,
                                            borderRadius: BorderRadius.circular(12),
                                            child: Padding(
                                              padding: const EdgeInsets.all(4),
                                              child: Icon(
                                                Icons.remove_circle_outline,
                                                size: 22,
                                                color: quantity > 0
                                                    ? AppTheme.alertRed
                                                    : AppTheme.disabledColor,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            child: Text(
                                              '$quantity $unit',
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: isLowStock
                                                    ? AppTheme.alertRed
                                                    : theme.colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => _quickAdjustStock(item, 1.0),
                                            borderRadius: BorderRadius.circular(12),
                                            child: const Padding(
                                              padding: EdgeInsets.all(4),
                                              child: Icon(
                                                Icons.add_circle_outline,
                                                size: 22,
                                                color: AppTheme.brandPurple,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (isLowStock)
                                        const Text(
                                          'Low Stock!',
                                          style: TextStyle(
                                            color: AppTheme.alertRed,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
