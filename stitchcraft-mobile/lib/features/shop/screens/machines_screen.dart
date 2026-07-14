import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';

class MachinesScreen extends StatefulWidget {
  const MachinesScreen({super.key});

  @override
  State<MachinesScreen> createState() => _MachinesScreenState();
}

class _MachinesScreenState extends State<MachinesScreen> {
  final _authService = AuthService();
  List<dynamic> _machines = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMachines();
  }

  Future<void> _loadMachines() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/machines'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _machines = json.decode(response.body);
        });
      }
    } catch (e) {
      developer.log("Error loading machines: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMachine(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Delete Machine', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to remove this Machine? All history will remain scoped to the shop.', style: TextStyle(color: AppTheme.darkGrey)),
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
        Uri.parse('${AuthService.baseUrl}/machines/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Machine deleted successfully'), backgroundColor: AppTheme.trustGreen),
        );
        _loadMachines();
      } else {
        throw Exception(json.decode(response.body)['message'] ?? 'Failed to delete');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.alertRed),
      );
      setState(() => _isLoading = false);
    }
  }

  void _showMachineForm({Map<String, dynamic>? machine}) {
    final isEdit = machine != null;
    final nameController = TextEditingController(text: isEdit ? machine['name'] : '');
    final typeController = TextEditingController(text: isEdit ? machine['type'] : 'Single Needle');
    final serialController = TextEditingController(text: isEdit ? machine['serialNumber'] : '');
    String status = isEdit ? (machine['status'] ?? 'Active') : 'Active';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? context.loc.edit_machine : context.loc.add_machine,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Machine Label/Name (e.g. Machine #3)',
                      labelStyle: TextStyle(color: AppTheme.darkGrey),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.brandPurple)),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: typeController,
                    decoration: const InputDecoration(
                      labelText: 'Machine Type (e.g. Overlock, Buttonhole)',
                      labelStyle: TextStyle(color: AppTheme.darkGrey),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.brandPurple)),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: serialController,
                    decoration: const InputDecoration(
                      labelText: 'Serial Number',
                      labelStyle: TextStyle(color: AppTheme.darkGrey),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.brandPurple)),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Operating Status', style: TextStyle(color: AppTheme.darkGrey)),
                      DropdownButton<String>(
                        dropdownColor: AppTheme.darkCard,
                        value: status,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        items: const [
                          DropdownMenuItem(value: 'Active', child: Text('Active')),
                          DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance')),
                          DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              status = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: AppTheme.darkGrey)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandPurple),
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final type = typeController.text.trim();
                          final serialNumber = serialController.text.trim();

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Name cannot be empty'), backgroundColor: AppTheme.alertRed),
                            );
                            return;
                          }

                          Navigator.pop(context);
                          setState(() => _isLoading = true);

                          try {
                            final token = await _authService.getToken();
                            final body = json.encode({
                              'name': name,
                              'type': type,
                              'serialNumber': serialNumber,
                              'status': status,
                            });

                            final response = isEdit
                                ? await http.put(
                                    Uri.parse('${AuthService.baseUrl}/machines/${machine['_id']}'),
                                    headers: {
                                      'Content-Type': 'application/json',
                                      'Authorization': 'Bearer $token',
                                    },
                                    body: body,
                                  )
                                : await http.post(
                                    Uri.parse('${AuthService.baseUrl}/machines'),
                                    headers: {
                                      'Content-Type': 'application/json',
                                      'Authorization': 'Bearer $token',
                                    },
                                    body: body,
                                  );

                            if (response.statusCode == 200 || response.statusCode == 201) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isEdit ? 'Machine updated successfully' : 'Machine registered successfully'),
                                  backgroundColor: AppTheme.trustGreen,
                                ),
                              );
                              _loadMachines();
                            } else {
                              throw Exception(json.decode(response.body)['message'] ?? 'Error occurred');
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error saving: $e'), backgroundColor: AppTheme.alertRed),
                            );
                            setState(() => _isLoading = false);
                          }
                        },
                        child: Text(isEdit ? context.loc.save : context.loc.add, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
  }

  void _showMachineDetails(Map<String, dynamic> machine) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final String name = machine['name'] ?? 'Sewing Machine';
        final String type = machine['type'] ?? 'General';
        final String status = machine['status'] ?? 'Active';
        final String serialNumber = machine['serialNumber'] ?? 'N/A';
        final String assignedTo = machine['assignedTo']?['name'] ?? 'Unassigned';

        return AlertDialog(
          backgroundColor: AppTheme.darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.lightGrey, width: 0.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF1D2939),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.settings, color: AppTheme.brandPurple, size: 24),
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
              _detailRow(Icons.category_outlined, 'Machine Type', type),
              const SizedBox(height: 12),
              _detailRow(Icons.person_outline, 'Assigned Operator', assignedTo),
              const SizedBox(height: 12),
              _detailRow(Icons.info_outline, 'Status', status),
              const SizedBox(height: 12),
              _detailRow(Icons.numbers_outlined, 'Serial Number', serialNumber),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteMachine(machine['_id']);
              },
              child: const Text('Delete', style: TextStyle(color: AppTheme.alertRed, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showMachineForm(machine: machine);
              },
              child: const Text('Edit', style: TextStyle(color: AppTheme.brandPurple, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppTheme.darkGrey)),
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
        title: Text(context.loc.machines),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMachineForm(),
        backgroundColor: AppTheme.brandPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _machines.isEmpty
              ? Center(
                  child: Text(
                    'No machines found.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkGrey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _machines.length,
                  itemBuilder: (context, index) {
                    final machine = _machines[index];
                    final String name = machine['name'] ?? 'Sewing Machine';
                    final String type = machine['type'] ?? 'General';
                    final String status = machine['status'] ?? 'Active';
                    final String assignedTo = machine['assignedTo']?['name'] ?? 'None';
                    final isMaintenance = status.toLowerCase() == 'maintenance';

                    return NeoCard(
                      onTap: () => _showMachineDetails(machine),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.brandPurple.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.settings, color: AppTheme.brandPurple, size: 28),
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
                                  'Type: $type • Operator: $assignedTo',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkGrey, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isMaintenance
                                  ? AppTheme.alertRed.withValues(alpha: 0.15)
                                  : AppTheme.trustGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isMaintenance ? AppTheme.alertRed : AppTheme.trustGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
