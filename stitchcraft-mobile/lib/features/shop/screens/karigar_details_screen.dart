import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class KarigarDetailsScreen extends StatefulWidget {
  const KarigarDetailsScreen({super.key});

  @override
  State<KarigarDetailsScreen> createState() => _KarigarDetailsScreenState();
}

class _KarigarDetailsScreenState extends State<KarigarDetailsScreen> {
  final _authService = AuthService();
  bool _isLoading = false;
  Map<String, dynamic>? _karigar;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_karigar == null) {
      final karigarId = ModalRoute.of(context)!.settings.arguments as String;
      _loadKarigarDetails(karigarId);
    }
  }

  Future<void> _loadKarigarDetails(String karigarId) async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/karigars/$karigarId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _karigar = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load karigar details');
      }
    } catch (e) {
      developer.log("Error loading karigar: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.alertRed),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteKarigar() async {
    if (_karigar == null) return;
    final karigarId = _karigar!['_id'] ?? _karigar!['id'];
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Delete Karigar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this karigar from the database? This cannot be undone.', style: TextStyle(color: Colors.white70)),
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
        Uri.parse('${AuthService.baseUrl}/karigars/$karigarId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Karigar deleted successfully'), backgroundColor: AppTheme.trustGreen),
        );
        nav.pop(true);
      } else {
        throw Exception('Failed to delete karigar');
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.alertRed),
      );
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editKarigar() async {
    if (_karigar == null) return;

    final nameController = TextEditingController(text: _karigar!['name']);
    final phoneController = TextEditingController(text: _karigar!['phone']);
    final specialtyController = TextEditingController(text: _karigar!['specialty']);
    String status = _karigar!['status'] ?? 'Active';

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
                'Edit Karigar Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Full Name'),
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
                controller: specialtyController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Specialty (e.g. Shirts, Pants, Suits)'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                dropdownColor: AppTheme.darkCard,
                // ignore: deprecated_member_use
                value: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'Active', child: Text('Active', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'Inactive', child: Text('Inactive', style: TextStyle(color: Colors.white))),
                ],
                onChanged: (val) {
                  if (val != null) {
                    status = val;
                  }
                },
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
                      if (name.isEmpty) return;

                      final nav = Navigator.of(context);
                      try {
                        final token = await _authService.getToken();
                        final response = await http.put(
                          Uri.parse('${AuthService.baseUrl}/karigars/${_karigar!['_id']}'),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer $token',
                          },
                          body: json.encode({
                            'name': name,
                            'phone': phoneController.text.trim(),
                            'specialty': specialtyController.text.trim(),
                            'status': status,
                          }),
                        );

                        if (response.statusCode == 200) {
                          nav.pop(true);
                        } else {
                          throw Exception('Failed to update karigar');
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

    if (updated == true && mounted) {
      _loadKarigarDetails(_karigar!['_id'] ?? _karigar!['id']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String title = _karigar != null ? _karigar!['name'] ?? 'Karigar' : 'Loading Karigar...';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title),
        actions: _karigar != null
            ? [
                IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _editKarigar),
                IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.alertRed), onPressed: _deleteKarigar),
              ]
            : null,
      ),
      body: _isLoading && _karigar == null
          ? const Center(child: CircularProgressIndicator())
          : _karigar == null
              ? const Center(child: Text('Failed to load karigar details', style: TextStyle(color: Colors.white)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Card
                      NeoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _karigar!['name'] ?? 'Tailoring Staff',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: ((_karigar!['status'] ?? 'Active').toLowerCase() == 'active'
                                            ? AppTheme.trustGreen
                                            : AppTheme.darkGrey)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    (_karigar!['status'] ?? 'Active').toUpperCase(),
                                    style: TextStyle(
                                      color: (_karigar!['status'] ?? 'Active').toLowerCase() == 'active'
                                          ? AppTheme.trustGreen
                                          : AppTheme.darkGrey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white10, height: 24),
                            _infoRow('Phone Number', _karigar!['phone'] ?? 'N/A'),
                            _infoRow('Specialty Type', _karigar!['specialty'] ?? 'All Categories'),
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
