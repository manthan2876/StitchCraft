import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';

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
      final list = await _localDb.getRecords('customers');
      setState(() {
        _customers = list;
      });
    } catch (e) {
      debugPrint("Error loading customers: $e");
    } finally {
      setState(() => _isLoading = false);
    }
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
