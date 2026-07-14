import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';
import 'package:stitchcraft/core/widgets/custom_app_bar.dart';
import 'package:stitchcraft/features/dashboard/widgets/drawer_menu.dart';

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



  void _showKarigarForm({Map<String, dynamic>? karigar}) {
    final isEdit = karigar != null;
    final nameController = TextEditingController(text: isEdit ? karigar['name'] : '');
    final phoneController = TextEditingController(text: isEdit ? karigar['phone'] : '');
    final specialtyController = TextEditingController(
      text: isEdit ? (karigar['specialty'] ?? karigar['specialization'] ?? 'Stitching') : 'Stitching',
    );
    String status = isEdit ? (karigar['status'] ?? 'Available') : 'Available';

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
                    isEdit ? context.loc.edit_staff : context.loc.add_staff,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Staff Full Name',
                      labelStyle: TextStyle(color: AppTheme.darkGrey),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.brandPurple)),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Contact Phone Number',
                      labelStyle: TextStyle(color: AppTheme.darkGrey),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.brandPurple)),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: specialtyController,
                    decoration: const InputDecoration(
                      labelText: 'Specialization (e.g. Pants, Suits, Shirts)',
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
                      const Text('Staff Current Status', style: TextStyle(color: AppTheme.darkGrey)),
                      DropdownButton<String>(
                        dropdownColor: AppTheme.darkCard,
                        value: status,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        items: const [
                          DropdownMenuItem(value: 'Available', child: Text('Available')),
                          DropdownMenuItem(value: 'Busy', child: Text('Busy')),
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
                          final phone = phoneController.text.trim();
                          final specialty = specialtyController.text.trim();

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Name cannot be empty'), backgroundColor: AppTheme.alertRed),
                            );
                            return;
                          }

                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);
                          setState(() => _isLoading = true);

                          try {
                            final token = await _authService.getToken();
                            final body = json.encode({
                              'name': name,
                              'phone': phone,
                              'specialty': specialty,
                              'status': status,
                            });

                            final response = isEdit
                                ? await http.put(
                                    Uri.parse('${AuthService.baseUrl}/karigars/${karigar['_id']}'),
                                    headers: {
                                      'Content-Type': 'application/json',
                                      'Authorization': 'Bearer $token',
                                    },
                                    body: body,
                                  )
                                : await http.post(
                                    Uri.parse('${AuthService.baseUrl}/karigars'),
                                    headers: {
                                      'Content-Type': 'application/json',
                                      'Authorization': 'Bearer $token',
                                    },
                                    body: body,
                                  );

                            if (response.statusCode == 200 || response.statusCode == 201) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(isEdit ? 'Karigar updated successfully' : 'Karigar added successfully'),
                                  backgroundColor: AppTheme.trustGreen,
                                ),
                              );
                              _loadKarigars();
                            } else {
                              throw Exception(json.decode(response.body)['message'] ?? 'Error occurred');
                            }
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Error saving: $e'), backgroundColor: AppTheme.alertRed),
                            );
                            if (mounted) setState(() => _isLoading = false);
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



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(title: context.loc.karigars, showDrawerButton: true),
      drawer: const DrawerMenu(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showKarigarForm(),
        backgroundColor: AppTheme.brandPurple,
        child: const Icon(Icons.add, color: Colors.white),
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
                      onTap: () async {
                        final reload = await Navigator.pushNamed(context, '/karigar_details', arguments: karigar['_id'] ?? karigar['id'] ?? '');
                        if (reload == true) {
                          _loadKarigars();
                        }
                      },
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
