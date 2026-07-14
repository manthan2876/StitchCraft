import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class MachineDetailsScreen extends StatefulWidget {
  const MachineDetailsScreen({super.key});

  @override
  State<MachineDetailsScreen> createState() => _MachineDetailsScreenState();
}

class _MachineDetailsScreenState extends State<MachineDetailsScreen> {
  final _authService = AuthService();
  bool _isLoading = false;
  Map<String, dynamic>? _machine;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_machine == null) {
      final machineId = ModalRoute.of(context)!.settings.arguments as String;
      _loadMachineDetails(machineId);
    }
  }

  Future<void> _loadMachineDetails(String machineId) async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/machines/$machineId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _machine = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load machine details');
      }
    } catch (e) {
      developer.log("Error loading machine: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.alertRed),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMachine() async {
    if (_machine == null) return;
    final machineId = _machine!['_id'] ?? _machine!['id'];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Delete Machine', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to permanently remove this machine from the shop registry?', style: TextStyle(color: Colors.white70)),
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
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      final token = await _authService.getToken();
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/machines/$machineId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Machine deleted successfully'), backgroundColor: AppTheme.trustGreen),
        );
        nav.pop(true);
      } else {
        throw Exception('Failed to delete machine');
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.alertRed),
      );
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editMachine() async {
    if (_machine == null) return;

    final nameController = TextEditingController(text: _machine!['name']);
    final typeController = TextEditingController(text: _machine!['type']);
    final serialController = TextEditingController(text: _machine!['serialNumber']);
    String status = _machine!['status'] ?? 'Active';

    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Machine Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Machine Label/Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: typeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Machine Type'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: serialController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Serial Number'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    dropdownColor: AppTheme.darkCard,
                    // ignore: deprecated_member_use
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'Active', child: Text('Active', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Inactive', child: Text('Inactive', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => status = val);
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
                          final innerNav = Navigator.of(context);
                          try {
                            final token = await _authService.getToken();
                            final response = await http.put(
                              Uri.parse('${AuthService.baseUrl}/machines/${_machine!['_id']}'),
                              headers: {
                                'Content-Type': 'application/json',
                                'Authorization': 'Bearer $token',
                              },
                              body: json.encode({
                                'name': name,
                                'type': typeController.text.trim(),
                                'serialNumber': serialController.text.trim(),
                                'status': status,
                              }),
                            );

                            if (response.statusCode == 200) {
                              innerNav.pop(true);
                            } else {
                              throw Exception('Failed to update machine');
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
      },
    );

    if (updated == true && mounted) {
      _loadMachineDetails(_machine!['_id'] ?? _machine!['id']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String title = _machine != null ? _machine!['name'] ?? 'Machine' : 'Loading Machine...';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title),
        actions: _machine != null
            ? [
                IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _editMachine),
                IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.alertRed), onPressed: _deleteMachine),
              ]
            : null,
      ),
      body: _isLoading && _machine == null
          ? const Center(child: CircularProgressIndicator())
          : _machine == null
              ? const Center(child: Text('Failed to load machine', style: TextStyle(color: Colors.white)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Machine specs card
                      NeoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _machine!['name'] ?? 'Sewing Machine',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(_machine!['status'] ?? 'Active').withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    (_machine!['status'] ?? 'Active').toUpperCase(),
                                    style: TextStyle(
                                      color: _getStatusColor(_machine!['status'] ?? 'Active'),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white10, height: 24),
                            _infoRow('Machine Type', _machine!['type'] ?? 'N/A'),
                            _infoRow('Serial Number', _machine!['serialNumber'] ?? 'N/A'),
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

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('active')) {
      return AppTheme.trustGreen;
    } else if (s.contains('maintenance')) {
      return AppTheme.safetyOrange;
    }
    return AppTheme.darkGrey;
  }
}
