import 'package:flutter/material.dart';
import 'package:stitchcraft/features/orders/screens/order_list_screen.dart';

/// InvoiceScreen simply delegates to OrderListScreen showing all orders.
/// Detailed invoice view is handled by invoice_details_screen.dart
class InvoiceScreen extends StatelessWidget {
  const InvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const OrderListScreen(
      title: 'Invoices',
      statusFilter: 'all',
    );
  }
}
