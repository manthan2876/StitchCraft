import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';

class ShopsTab extends StatelessWidget {
  final List<dynamic> shops;
  final String? activeShopId;
  final ValueChanged<String> onSwitchShop;
  final Function(String name, String phone, String address) onAddShop;
  final Function(String id, String name, String phone, String address) onEditShop;
  final Function(String id) onDeleteShop;

  const ShopsTab({
    super.key,
    required this.shops,
    required this.activeShopId,
    required this.onSwitchShop,
    required this.onAddShop,
    required this.onEditShop,
    required this.onDeleteShop,
  });

  void _showShopDialog(BuildContext context, {Map<String, dynamic>? shop}) {
    final nameController = TextEditingController(text: shop != null ? shop['shopName'] : '');
    final phoneController = TextEditingController(text: shop != null ? shop['phone'] : '');
    final addressController = TextEditingController(text: shop != null ? shop['address'] : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkCard,
          title: Text(
            shop == null ? 'Register New Shop' : 'Edit Shop Details',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Shop Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Shop Address'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.darkGrey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandPurple),
              onPressed: () {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                final address = addressController.text.trim();
                if (name.isEmpty) return;

                Navigator.pop(context);
                if (shop == null) {
                  onAddShop(name, phone, address);
                } else {
                  onEditShop(shop['_id'] ?? shop['id'], name, phone, address);
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              itemCount: shops.length,
              itemBuilder: (context, index) {
                final shop = shops[index];
                final bool isActive = shop['_id'] == activeShopId;

                return NeoCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.brandPurple.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.storefront, color: AppTheme.brandPurple, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shop['shopName'] ?? 'Shop',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              shop['address'] ?? 'No Address linked',
                              style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkGrey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Edit button
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppTheme.darkGrey, size: 20),
                            onPressed: () => _showShopDialog(context, shop: shop),
                          ),
                          // Delete button (disabled for active shop context safety)
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: isActive ? Colors.white24 : AppTheme.alertRed, size: 20),
                            onPressed: isActive
                                ? null
                                : () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: AppTheme.darkCard,
                                        title: const Text('Delete Shop', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        content: Text('Are you sure you want to permanently delete "${shop['shopName']}"?'),
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
                                    if (confirm == true) {
                                      onDeleteShop(shop['_id'] ?? shop['id']);
                                    }
                                  },
                          ),
                        ],
                      ),
                      if (isActive)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.check_circle, color: AppTheme.trustGreen),
                        )
                      else
                        TextButton(
                          onPressed: () => onSwitchShop(shop['_id']),
                          child: const Text('Switch'),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandPurple),
                onPressed: () => _showShopDialog(context),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Register New Shop', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
