import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/utils/currency_utils.dart';
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final _localDb = LocalDatabaseService();
  List<Map<String, dynamic>> _allInvoices = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _localDb.getAllOrders();
      if (mounted) {
        setState(() {
          _allInvoices = orders;
        });
      }
    } catch (e) {
      debugPrint("Error loading invoices: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredInvoices {
    if (_searchQuery.trim().isEmpty) return _allInvoices;
    final q = _searchQuery.toLowerCase();
    return _allInvoices.where((inv) {
      final name = (inv['customer_name'] ?? '').toString().toLowerCase();
      final id = (inv['id'] ?? '').toString().toLowerCase();
      return name.contains(q) || id.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayed = _filteredInvoices;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.loc.invoices),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search invoices by customer or #ID...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayed.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty ? 'No invoices found.' : 'No invoices match "$_searchQuery"',
                          style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkGrey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadInvoices,
                        color: AppTheme.brandPurple,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: displayed.length,
                          itemBuilder: (context, index) {
                            final inv = displayed[index];
                            final String rawId = inv['id']?.toString() ?? '';
                            final String invoiceNum = 'INV-${rawId.split('-').first.toUpperCase()}';
                            final String customerName = inv['customer_name'] ?? 'Walk-in Customer';
                            final double total = (inv['total_amount'] as num?)?.toDouble() ?? 0.0;
                            final double advance = (inv['advance_amount'] as num?)?.toDouble() ?? 0.0;
                            final double balance = (total - advance).clamp(0, double.infinity);
                            final bool isPaid = balance <= 0.01;

                            return NeoCard(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/invoice_details',
                                  arguments: rawId,
                                );
                              },
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                leading: CircleAvatar(
                                  backgroundColor: isPaid
                                      ? AppTheme.trustGreen.withValues(alpha: 0.15)
                                      : AppTheme.safetyOrange.withValues(alpha: 0.15),
                                  child: Icon(
                                    Icons.receipt_long_outlined,
                                    color: isPaid ? AppTheme.trustGreen : AppTheme.safetyOrange,
                                    size: 20,
                                  ),
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        customerName,
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Text(
                                      CurrencyUtils.formatINR(total, showDecimals: false),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      invoiceNum,
                                      style: const TextStyle(color: AppTheme.darkGrey, fontSize: 12),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isPaid
                                            ? AppTheme.trustGreen.withValues(alpha: 0.15)
                                            : AppTheme.alertRed.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        isPaid ? 'PAID' : 'DUE ${CurrencyUtils.formatINR(balance, showDecimals: false)}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isPaid ? AppTheme.trustGreen : AppTheme.alertRed,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: AppTheme.darkGrey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
