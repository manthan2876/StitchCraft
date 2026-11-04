import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/widgets/custom_app_bar.dart';
import 'package:stitchcraft/core/widgets/primary_button.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/utils/phone_utils.dart';
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';

class RepairDashboard extends StatefulWidget {
  const RepairDashboard({super.key});

  @override
  State<RepairDashboard> createState() => _RepairDashboardState();
}

class _RepairDashboardState extends State<RepairDashboard> {
  int _totalCost = 0;
  final Map<String, int> _cart = {};

  final List<Map<String, dynamic>> _repairItems = [
    {'name': 'Zipper Replace', 'price': 50, 'icon': Icons.flash_on_outlined},
    {'name': 'Button Stitch', 'price': 10, 'icon': Icons.radio_button_checked},
    {'name': 'Hemming', 'price': 30, 'icon': Icons.architecture},
    {'name': 'Fitting / Alteration', 'price': 80, 'icon': Icons.accessibility_new},
    {'name': 'Patch Work', 'price': 40, 'icon': Icons.extension_outlined},
    {'name': 'Ironing & Press', 'price': 20, 'icon': Icons.iron_outlined},
  ];

  void _addItem(String name, int price) {
    setState(() {
      _totalCost += price;
      _cart[name] = (_cart[name] ?? 0) + 1;
    });
  }

  void _removeItem(String name, int price) {
    setState(() {
      final current = _cart[name] ?? 0;
      if (current > 0) {
        _totalCost -= price;
        if (current == 1) {
          _cart.remove(name);
        } else {
          _cart[name] = current - 1;
        }
      }
    });
  }

  Future<void> _showCreateTicketModal() async {
    final theme = Theme.of(context);
    final nameController = TextEditingController(text: 'Walk-in Customer');
    final phoneController = TextEditingController();
    final notesController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create Repair Ticket',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Items chip summary
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _cart.entries.map((e) {
                  return Chip(
                    label: Text('${e.key} x${e.value}'),
                    backgroundColor: AppTheme.brandPurple.withValues(alpha: 0.12),
                    side: BorderSide(
                      color: AppTheme.brandPurple.withValues(alpha: 0.3),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number (Optional)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Instructions / Notes (e.g. deliver by 5 PM)',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Due',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        '₹$_totalCost',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppTheme.trustGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: PrimaryButton(
                      text: 'Confirm & Save',
                      icon: Icons.check,
                      onPressed: () async {
                        final now = DateTime.now().millisecondsSinceEpoch;
                        final cleanPhone = PhoneUtils.sanitizePhoneNumber(phoneController.text.trim());
                        final custId = 'CUST-WALKIN-${cleanPhone.isNotEmpty ? cleanPhone : now}';
                        final custName = nameController.text.trim().isEmpty
                            ? 'Walk-in Customer'
                            : nameController.text.trim();
                        final custPhone = cleanPhone; // Keep authentic phone; never fabricate '0000000000'

                        try {
                          if (custPhone.isNotEmpty) {
                            await LocalDatabaseService().insertRecord('customers', {
                              'id': custId,
                              'name': custName,
                              'phone': custPhone,
                              'sync_status': 1,
                              'updated_at': now,
                            });
                          }

                          final serviceTypes = _cart.entries
                              .map((e) => '${e.key} (x${e.value})')
                              .join(', ');

                          await LocalDatabaseService().insertRepairJob({
                            'id': 'REP-$now',
                            'customer_id': custId,
                            'customer_name': custName,
                            'service_type': serviceTypes,
                            'complexity': 'SIMPLE',
                            'price': _totalCost.toDouble(),
                            'status': 'pending',
                            'created_date': now,
                            'notes': notesController.text.trim(),
                            'sync_status': 1,
                            'updated_at': now,
                          });

                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Repair ticket created for $custName!'),
                                backgroundColor: AppTheme.trustGreen,
                              ),
                            );
                            setState(() {
                              _cart.clear();
                              _totalCost = 0;
                            });
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('Error saving ticket: $e'),
                                backgroundColor: AppTheme.alertRed,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    nameController.dispose();
    phoneController.dispose();
    notesController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(title: context.loc.fast_lane_repairs),
      body: Column(
        children: [
          // UX-17: Label Prototype / In-Shop Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.safetyOrange.withValues(alpha: 0.15),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.safetyOrange, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Express Workshop POS (Beta / In-Shop Only)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.safetyOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.05,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _repairItems.length,
              itemBuilder: (context, index) {
                final item = _repairItems[index];
                final String name = item['name'];
                final int price = item['price'];
                final count = _cart[name] ?? 0;

                return NeoCard(
                  onTap: count == 0 ? () => _addItem(name, price) : null,
                  color: count > 0
                      ? AppTheme.brandPurple.withValues(alpha: 0.12)
                      : null,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 32,
                        color: count > 0
                            ? AppTheme.brandPurple
                            : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹$price',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.trustGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (count > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () => _removeItem(name, price),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.error.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.remove,
                                  size: 16,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                '$count',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => _addItem(name, price),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppTheme.brandPurple.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 16,
                                  color: AppTheme.brandPurple,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          'Tap to add',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Cart Footer
          if (_totalCost > 0)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total Repair Cost',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          '₹$_totalCost',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppTheme.trustGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _showCreateTicketModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.receipt_long, size: 20),
                      label: const Text(
                        'CREATE TICKET',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
