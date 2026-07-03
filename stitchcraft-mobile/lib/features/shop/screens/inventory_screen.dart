import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:uuid/uuid.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _localDb = LocalDatabaseService();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);
    try {
      final list = await _localDb.getRecords('inventory');
      setState(() => _items = list);
    } catch (e) {
      debugPrint("Error loading inventory: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddItemModal() async {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final qtyController = TextEditingController();
    final priceController = TextEditingController();

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
                'Add Stock Item',
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
                controller: categoryController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Category (Fabric, Thread, Button)'),
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
                    final cat = categoryController.text.trim();
                    final qty = double.tryParse(qtyController.text) ?? 0.0;
                    final price = double.tryParse(priceController.text) ?? 0.0;

                    if (name.isNotEmpty && cat.isNotEmpty && qty > 0) {
                      final newItem = {
                        'id': const Uuid().v4(),
                        'name': name,
                        'category': cat,
                        'quantity': qty,
                        'unit_price': price,
                        'low_stock_threshold': 5.0,
                        'sync_status': 1,
                        'updated_at': DateTime.now().millisecondsSinceEpoch,
                      };

                      await _localDb.insertRecord('inventory', newItem);
                      Navigator.pop(context);
                      _loadInventory();
                    }
                  },
                  child: const Text('Add Material'),
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
      appBar: AppBar(
        title: const Text('Inventory Stock'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemModal,
        backgroundColor: AppTheme.brandPurple,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final double quantity = (item['quantity'] as num?)?.toDouble() ?? 0.0;
                final double limit = (item['low_stock_threshold'] as num?)?.toDouble() ?? 5.0;
                final bool isLowStock = quantity <= limit;

                return NeoCard(
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
                              item['name'] ?? 'Material',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Category: ${item['category'] ?? 'General'} • ₹${item['unit_price']}/unit',
                              style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkGrey, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$quantity units',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isLowStock ? AppTheme.alertRed : Colors.white,
                            ),
                          ),
                          if (isLowStock)
                            Text(
                              'Low Stock!',
                              style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.alertRed),
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
