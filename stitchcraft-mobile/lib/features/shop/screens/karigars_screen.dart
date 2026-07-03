import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class KarigarsScreen extends StatefulWidget {
  const KarigarsScreen({super.key});

  @override
  State<KarigarsScreen> createState() => _KarigarsScreenState();
}

class _KarigarsScreenState extends State<KarigarsScreen> {
  final _authService = AuthService();
  List<dynamic> _karigars = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadKarigars();
  }

  Future<void> _loadKarigars() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/karigars'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _karigars = json.decode(response.body);
        });
      }
    } catch (e) {
      developer.log("Error loading karigars: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showKarigarDetails(Map<String, dynamic> karigar) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final String name = karigar['name'] ?? 'Staff Member';
        final String phone = karigar['phone'] ?? 'N/A';
        final String specialty = karigar['specialty'] ?? karigar['specialization'] ?? 'Stitching';
        final String status = karigar['status'] ?? 'Available';
        final int activeOrders = (karigar['activeOrders'] as num?)?.toInt() ?? 0;

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
                  name.isNotEmpty ? name[0].toUpperCase() : 'K',
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
              _detailRow(Icons.star_outline, 'Specialty', specialty),
              const SizedBox(height: 12),
              _detailRow(Icons.info_outline, 'Status', status),
              const SizedBox(height: 12),
              _detailRow(Icons.list_alt_outlined, 'Active Orders', '$activeOrders orders'),
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
        title: const Text('Tailoring Staff (Karigars)'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _karigars.isEmpty
              ? Center(
                  child: Text(
                    'No karigars found.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkGrey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _karigars.length,
                  itemBuilder: (context, index) {
                    final karigar = _karigars[index];
                    final String name = karigar['name'] ?? 'Staff Member';
                    final String specialty = karigar['specialty'] ?? 'Stitching';
                    final String status = karigar['status'] ?? 'Available';
                    final int activeOrders = (karigar['activeOrders'] as num?)?.toInt() ?? 0;
                    final isBusy = status.toLowerCase() == 'busy';

                    return NeoCard(
                      onTap: () => _showKarigarDetails(karigar),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppTheme.brandPurple.withValues(alpha: 0.15),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'K',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppTheme.brandPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                                  'Expertise: $specialty',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkGrey, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isBusy
                                      ? AppTheme.safetyOrange.withValues(alpha: 0.15)
                                      : AppTheme.trustGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isBusy ? AppTheme.safetyOrange : AppTheme.trustGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$activeOrders active orders',
                                style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.darkGrey),
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
