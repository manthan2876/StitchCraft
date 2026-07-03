import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

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
        title: const Text('Shop Machines'),
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
