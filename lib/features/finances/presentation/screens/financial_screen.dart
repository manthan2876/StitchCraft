import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/features/inventory/presentation/screens/inventory_scanner_screen.dart';

class FinancialScreen extends StatefulWidget {
  const FinancialScreen({super.key});

  @override
  State<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends State<FinancialScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  late TabController _tabController;

  // Expense Categories
  final List<String> _categories = [
    'Direct Materials', 
    'Outsourced Labor',
    'Shop Overheads', 
    'Staff Salaries',
    'Maintenance',
    'Marketing',
    'Tools',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddExpenseDialog() {
    final categoryController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = _categories.first;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Expense'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                // value is deprecated for FormField initialization, using initialValue
                initialValue: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {
                  selectedCategory = val!;
                  categoryController.text = val;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount (₹)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              if (amountController.text.isNotEmpty) {
                await _dbService.addExpense(
                  selectedCategory,
                  double.parse(amountController.text),
                  descriptionController.text,
                  DateTime.now(),
                );
                if (mounted) Navigator.pop(context);
                setState(() {}); // Refresh
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Finances & Inventory'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          onTap: (index) => HapticFeedback.selectionClick(),
          tabs: const [
            Tab(text: 'Business Intelligence'),
            Tab(text: 'Inventory & Scan'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0 ? FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showAddExpenseDialog();
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBusinessIntelligenceTab(),
          _buildInventoryTab(),
        ],
      ),
    );
  }

  Widget _buildBusinessIntelligenceTab() {
    return FutureBuilder<Map<String, double>>(
      future: _dbService.getFinancialSummary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error loading data: ${snapshot.error}'));
        }

        final data = snapshot.data ?? {
          'revenue': 0.0,
          'cogs': 0.0,
          'gross_profit': 0.0,
          'expenses': 0.0,
          'net_profit': 0.0,
        };

        final revenue = data['revenue']!;
        final netProfit = data['net_profit']!;
        final profitMargin = revenue == 0 ? 0.0 : (netProfit / revenue) * 100;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profitability Indicator Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, Colors.grey.shade900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Net Profit',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Real-time',
                              style: TextStyle(color: Colors.white30, fontSize: 12),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${profitMargin.toStringAsFixed(1)}% Margin',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '₹${netProfit.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Profit Formula Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 12,
                        child: Row(
                          children: [
                            Expanded(flex: (data['cogs']! / (revenue == 0 ? 1 : revenue) * 100).toInt(), child: Container(color: Colors.redAccent)),
                            Expanded(flex: (data['expenses']! / (revenue == 0 ? 1 : revenue) * 100).toInt(), child: Container(color: Colors.orangeAccent)),
                            Expanded(flex: (netProfit / (revenue == 0 ? 1 : revenue) * 100).toInt().clamp(0, 100), child: Container(color: Colors.greenAccent)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('COGS', style: TextStyle(color: Colors.white70, fontSize: 10)),
                        Text('Overhead', style: TextStyle(color: Colors.white70, fontSize: 10)),
                        Text('Profit', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              Text('Financial Breakdown', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              _buildFinanceRow('Total Revenue', data['revenue']!, isPositive: true),
              _buildFinanceRow('Labor & Materials (COGS)', -data['cogs']!, isPositive: false),
              _buildFinanceRow('Operational Expenses', -data['expenses']!, isPositive: false),
              const Divider(height: 32),
              _buildFinanceRow('Net Profit', data['net_profit']!, isPositive: data['net_profit']! >= 0, isBold: true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFinanceRow(String label, double amount, {bool isPositive = true, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            '${amount >= 0 ? "+" : ""}₹${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 16 : 14,
              color: isPositive ? AppTheme.success : AppTheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTab() {
    // Mock Inventory Data for "Low Stock" demo
    final lowStockItems = [
      {'name': 'White Thread (Cotton)', 'qty': '2 spools', 'status': 'Critical'},
      {'name': 'Gold Buttons (12mm)', 'qty': '5 pcs', 'status': 'Low'},
      {'name': 'Interfacing (Medium)', 'qty': '1.5 meters', 'status': 'Low'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // QR Scanner CTA
          InkWell(
            onTap: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (context) => const InventoryScannerScreen()),
               );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.qr_code_scanner, size: 48, color: AppTheme.primaryColor),
                  SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan Fabric Bag',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Pull up digital job card or stock',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text('Inventory Alerts', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          ...lowStockItems.map((item) => Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.orange.withValues(alpha: 0.3), width: 1),
            ),
            color: Colors.orange.withValues(alpha: 0.05),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              title: Text(item['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Quantity: ${item['qty']}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item['status']!,
                  style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}
