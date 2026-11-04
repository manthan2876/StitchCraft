import 'package:flutter/material.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';

class GarmentSelectionScreen extends StatefulWidget {
  const GarmentSelectionScreen({super.key});

  @override
  State<GarmentSelectionScreen> createState() => _GarmentSelectionScreenState();
}

class _GarmentSelectionScreenState extends State<GarmentSelectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('New order · 2 of 5 · Garment'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: 'Men'),
            Tab(text: 'Women'),
            Tab(text: 'Kids'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGarmentGrid(['Shirt', 'Pant', 'Safari', 'Kurta']),
          _buildGarmentGrid(['Blouse', 'Kurti', 'Salwar', 'Lehenga']),
          _buildGarmentGrid(['School Uniform', 'Baba Suit', 'Frock']),
        ],
      ),
    );
  }

  Widget _buildGarmentGrid(List<String> items) {
    final theme = Theme.of(context);
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return NeoCard(
          onTap: () {
            final arguments = ModalRoute.of(context)?.settings.arguments;
            final wizardData = arguments is Map<String, dynamic>
                ? Map<String, dynamic>.from(arguments)
                : <String, dynamic>{};
            wizardData['garmentType'] = items[index];
            Navigator.pushNamed(
              context,
              '/create_order_step3',
              arguments: wizardData,
            );
          },
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.image, size: 50, color: Colors.grey[400]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  items[index],
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
