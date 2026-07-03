import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:http/http.dart' as http;

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _localDb = LocalDatabaseService();
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      var list = await _localDb.getRecords('customers');

      // Fallback: If local database is empty, fetch from remote API to populate
      if (list.isEmpty) {
        final token = await AuthService().getToken();
        if (token != null) {
          final response = await http.get(
            Uri.parse('${AuthService.baseUrl}/customers'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
          if (response.statusCode == 200) {
            final List<dynamic> remoteData = json.decode(response.body);
            for (final rawRecord in remoteData) {
              final Map<String, dynamic> remoteRecord = Map<String, dynamic>.from(rawRecord);
              final String id = remoteRecord['_id'] ?? remoteRecord['id'] ?? '';
              if (id.isEmpty) continue;

              final Map<String, dynamic> sqliteRecord = {
                'id': id,
                'name': remoteRecord['name'] ?? 'Unknown',
                'phone': remoteRecord['phone'] ?? '',
                'email': remoteRecord['email'] ?? '',
                'sync_status': 0,
                'updated_at': DateTime.now().millisecondsSinceEpoch,
              };
              await _localDb.insertRecord('customers', sqliteRecord);
            }
            list = await _localDb.getRecords('customers');
          }
        }
      }

      setState(() {
        _customers = list;
      });
    } catch (e) {
      debugPrint("Error loading customers: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCustomerDetails(Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final String name = customer['name'] ?? 'Walk-in Customer';
        final String phone = customer['phone'] ?? 'N/A';
        final String email = customer['email'] ?? 'N/A';

        return AlertDialog(
          backgroundColor: AppTheme.darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.lightGrey, width: 0.5),
          ),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.brandPurple.withValues(alpha: 0.15),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'C',
                  style: const TextStyle(color: AppTheme.brandPurple, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(Icons.phone_outlined, 'Phone', phone),
              const SizedBox(height: 12),
              _detailRow(Icons.email_outlined, 'Email', email),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppTheme.brandPurple, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.darkGrey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.darkGrey)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Customers'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _customers.isEmpty
              ? Center(
                  child: Text(
                    'No customers registered yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkGrey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _customers.length,
                  itemBuilder: (context, index) {
                    final customer = _customers[index];
                    final String name = customer['name'] ?? 'Walk-in Customer';
                    final String phone = customer['phone'] ?? '';
                    final String email = customer['email'] ?? '';

                    return NeoCard(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(4),
                        onTap: () => _showCustomerDetails(customer),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.brandPurple.withValues(alpha: 0.15),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'C',
                            style: const TextStyle(color: AppTheme.brandPurple, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        subtitle: Text('$phone • $email'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.darkGrey),
                      ),
                    );
                  },
                ),
    );
  }
}
