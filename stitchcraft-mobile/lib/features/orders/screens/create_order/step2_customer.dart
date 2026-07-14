import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/widgets/primary_button.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class CustomerSelectionScreen extends StatefulWidget {
  const CustomerSelectionScreen({super.key});

  @override
  State<CustomerSelectionScreen> createState() => _CustomerSelectionScreenState();
}

class _CustomerSelectionScreenState extends State<CustomerSelectionScreen> {
  final _authService = AuthService();
  bool _isLoading = false;
  List<dynamic> _customers = [];
  List<dynamic> _filteredCustomers = [];
  final _searchController = TextEditingController();

  Map<String, dynamic>? _wizardData;
  Map<String, dynamic>? _selectedCustomer;

  final _newCustNameController = TextEditingController();
  final _newCustPhoneController = TextEditingController();
  bool _isNewCustomer = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_wizardData == null) {
      _wizardData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _loadCustomers();
    }
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/customers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          _customers = data;
          _filteredCustomers = data;
        });
      }
    } catch (e) {
      developer.log("Error loading customers: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterCustomers(String query) {
    setState(() {
      _filteredCustomers = _customers.where((c) {
        final name = (c['name'] ?? '').toString().toLowerCase();
        final phone = (c['phone'] ?? '').toString();
        return name.contains(query.toLowerCase()) || phone.contains(query);
      }).toList();
    });
  }

  void _onNext() {
    if (_wizardData == null) return;

    if (_isNewCustomer) {
      final newName = _newCustNameController.text.trim();
      final newPhone = _newCustPhoneController.text.trim();
      if (newName.isEmpty || newPhone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter name and phone for the new customer'), backgroundColor: AppTheme.alertRed),
        );
        return;
      }
      _wizardData!['newCustomer'] = {'name': newName, 'phone': newPhone};
      _wizardData!.remove('customer');
    } else {
      if (_selectedCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an existing customer or toggle to register a new one'), backgroundColor: AppTheme.alertRed),
        );
        return;
      }
      _wizardData!['customer'] = _selectedCustomer;
      _wizardData!.remove('newCustomer');
    }

    Navigator.pushNamed(context, '/create_order_step3', arguments: _wizardData);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Customer Selection'),
      ),
      body: Column(
        children: [
          // Segmented button for Existing vs New Customer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_isNewCustomer ? AppTheme.brandPurple : theme.cardColor,
                    ),
                    onPressed: () => setState(() => _isNewCustomer = false),
                    child: Text('Existing Customer', style: TextStyle(color: !_isNewCustomer ? Colors.white : AppTheme.darkGrey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isNewCustomer ? AppTheme.brandPurple : theme.cardColor,
                    ),
                    onPressed: () => setState(() => _isNewCustomer = true),
                    child: Text('New Customer', style: TextStyle(color: _isNewCustomer ? Colors.white : AppTheme.darkGrey)),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: !_isNewCustomer
                ? Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterCustomers,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: const InputDecoration(
                            labelText: 'Search Customer...',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                itemCount: _filteredCustomers.length,
                                itemBuilder: (context, index) {
                                  final c = _filteredCustomers[index];
                                  final bool isSelected = _selectedCustomer?['_id'] == c['_id'];

                                  return NeoCard(
                                    onTap: () {
                                      setState(() {
                                        _selectedCustomer = c;
                                      });
                                    },
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: isSelected ? AppTheme.brandPurple : AppTheme.darkCard,
                                        child: Icon(Icons.person, color: isSelected ? Colors.white : AppTheme.brandPurple),
                                      ),
                                      title: Text(
                                        c['name'] ?? 'Guest Customer',
                                        style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        c['phone'] ?? '',
                                        style: const TextStyle(color: AppTheme.darkGrey),
                                      ),
                                      trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.trustGreen) : null,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Register Customer Details',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _newCustNameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Customer Full Name'),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _newCustPhoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Mobile Phone Number'),
                        ),
                      ],
                    ),
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: PrimaryButton(
              text: 'Next: Measurements',
              onPressed: _onNext,
            ),
          ),
        ],
      ),
    );
  }
}
