import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';
import 'package:stitchcraft/core/widgets/custom_app_bar.dart';
import 'package:stitchcraft/features/dashboard/widgets/drawer_menu.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _authService = AuthService();
  List<dynamic> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/inventory'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _items = json.decode(response.body);
        });
      }
    } catch (e) {
      developer.log("Error loading inventory: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }




  Future<void> _showItemForm({Map<String, dynamic>? item}) async {
    final isEdit = item != null;
    final nameController = TextEditingController(text: isEdit ? item['itemName'] : '');
    final typeController = TextEditingController(text: isEdit ? item['itemType'] : 'Fabric');
    final qtyController = TextEditingController(text: isEdit ? item['quantity'].toString() : '');
    final priceController = TextEditingController(text: isEdit ? item['costPerUnit'].toString() : '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? context.loc.edit_material : context.loc.add_material,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Item Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: typeController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Type (Lining, Fabric, Thread, Accessories, Other)'),
              ),
              const SizedBox(height: 16),
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
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
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final type = typeController.text.trim();
                    final qty = double.tryParse(qtyController.text) ?? 0.0;
                    final price = double.tryParse(priceController.text) ?? 0.0;

                    if (name.isNotEmpty && type.isNotEmpty) {
                      Navigator.pop(context);
                      setState(() => _isLoading = true);
                      try {
                        final token = await _authService.getToken();
                        if (token == null) return;

                        final body = json.encode({
                          'itemName': name,
                          'itemType': type,
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
                  child: Text(isEdit ? context.loc.save : context.loc.add),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(title: context.loc.inventory_stock, showDrawerButton: true),
      drawer: const DrawerMenu(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemForm(),
        backgroundColor: AppTheme.brandPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Text(
                    'No items found.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkGrey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final String name = item['itemName'] ?? 'Material';
                    final String type = item['itemType'] ?? 'General';
                    final double quantity = (item['quantity'] as num?)?.toDouble() ?? 0.0;
                    final double price = (item['costPerUnit'] as num?)?.toDouble() ?? 0.0;
                    final double limit = (item['minQuantity'] as num?)?.toDouble() ?? 5.0;
                    final bool isLowStock = quantity <= limit;
                    final String unit = item['unit'] ?? 'meters';

                    return NeoCard(
                      onTap: () async {
                        final reload = await Navigator.pushNamed(context, '/inventory_details', arguments: item['_id'] ?? item['id'] ?? '');
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
                              Icons.inventory,
                              color: isLowStock ? AppTheme.alertRed : AppTheme.brandPurple,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Category: $type • ₹$price/$unit',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkGrey, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$quantity $unit',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isLowStock ? AppTheme.alertRed : Colors.white,
                                ),
                              ),
                              if (isLowStock)
                                const Text(
                                  'Low Stock!',
                                  style: TextStyle(color: AppTheme.alertRed, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
