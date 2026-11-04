import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/models/user_model.dart';
import 'package:stitchcraft/core/widgets/custom_app_bar.dart';

class ShopSettingsScreen extends StatefulWidget {
  const ShopSettingsScreen({super.key});

  @override
  State<ShopSettingsScreen> createState() => _ShopSettingsScreenState();
}

class _ShopSettingsScreenState extends State<ShopSettingsScreen> {
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isSaving = false;
  UserRole _userRole = UserRole.staff;
  String? _shopId;
  Map<String, dynamic>? _shopData;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadShopSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadShopSettings() async {
    setState(() => _isLoading = true);
    try {
      final role = await _authService.getUserRoleEnum();
      final prefs = await SharedPreferences.getInstance();
      final shopId = prefs.getString('shopId');

      if (mounted) {
        setState(() {
          _userRole = role;
          _shopId = shopId;
        });
      }

      if (shopId != null && shopId.isNotEmpty) {
        final token = await _authService.getToken();
        final response = await http.get(
          Uri.parse('${AuthService.baseUrl}/shops/$shopId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (mounted) {
            setState(() {
              _shopData = data;
              _nameController.text = data['shopName'] ?? data['name'] ?? '';
              _phoneController.text = data['phone'] ?? '';
              _addressController.text = data['address'] ?? '';
            });
          }
        }
      }
    } catch (e) {
      developer.log("Error loading shop settings: $e", name: 'ShopSettingsScreen');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveShopDetails() async {
    if (!_userRole.canManageShop) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission denied: Only Owners and Managers can edit shop settings.'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shop name cannot be empty.'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final token = await _authService.getToken();
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/shops/$_shopId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'shopName': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shop settings updated successfully!'),
            backgroundColor: AppTheme.trustGreen,
          ),
        );
      } else {
        throw Exception(json.decode(response.body)['message'] ?? 'Failed to update shop');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.alertRed),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmDeleteShop() async {
    if (!_userRole.isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only the primary shop owner can delete this business.'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Shop?'),
        content: Text(
          'Warning: This action will permanently remove "${_nameController.text}" and unlink its inventory, karigars, and orders.\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.alertRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/shops/$_shopId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 204) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('shopId');
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/shop_setup', (route) => false);
      } else {
        throw Exception(json.decode(response.body)['message'] ?? 'Failed to delete shop');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting shop: $e'), backgroundColor: AppTheme.alertRed),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Shop Settings'),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.brandPurple)),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Shop Settings'),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppTheme.brandPurple,
                        child: Icon(Icons.storefront, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _shopData?['shopName'] ?? _nameController.text,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Role: ${_userRole.name.toUpperCase()}',
                              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.brandPurple),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    enabled: _userRole.canManageShop,
                    decoration: const InputDecoration(
                      labelText: 'Business Name',
                      prefixIcon: Icon(Icons.business),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    enabled: _userRole.canManageShop,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Contact Phone Number',
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _addressController,
                    enabled: _userRole.canManageShop,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Workshop / Store Address',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_userRole.canManageShop)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _isSaving ? null : _saveShopDetails,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Save Shop Details', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.sync, color: AppTheme.brandPurple),
              title: const Text('Sync Status & Offline Storage'),
              subtitle: const Text('Inspect pending sync queue and local SQLite state'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/sync_status'),
            ),
          ),
          const SizedBox(height: 20),
          if (_userRole.isOwner) ...[
            Text(
              'Danger Zone',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.alertRed,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: AppTheme.alertRed.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: AppTheme.alertRed.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: AppTheme.alertRed),
                title: const Text(
                  'Delete This Shop',
                  style: TextStyle(color: AppTheme.alertRed, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Permanently erase this workshop and all linked records'),
                onTap: _confirmDeleteShop,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

