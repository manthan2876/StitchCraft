import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RateCardScreen extends StatefulWidget {
  const RateCardScreen({super.key});

  @override
  State<RateCardScreen> createState() => _RateCardScreenState();
}

class _RateCardScreenState extends State<RateCardScreen> {
  final Map<String, double> _astarRates = {
    'COTTON': 30.0,
    'CREPE': 50.0,
    'SATIN': 60.0,
    'TAFETTA': 55.0,
  };

  final Map<String, double> _repairRates = {
    'ZIPPER': 100.0,
    'HEM': 50.0,
    'PICO': 200.0,
    'FITTING': 150.0,
    'PATCH': 80.0,
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  Future<void> _loadRates() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Astar rates
    final astarJson = prefs.getString('astar_rates');
    if (astarJson != null) {
      final loaded = Map<String, double>.from(json.decode(astarJson));
      setState(() {
        _astarRates.addAll(loaded);
      });
    }

    // Load Repair rates
    final repairJson = prefs.getString('repair_rates');
    if (repairJson != null) {
      final loaded = Map<String, double>.from(json.decode(repairJson));
      setState(() {
        _repairRates.addAll(loaded);
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveRates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('astar_rates', json.encode(_astarRates));
    await prefs.setString('repair_rates', json.encode(_repairRates));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rate card saved successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  void _updateAstarRate(String material, double rate) {
    setState(() {
      _astarRates[material] = rate;
    });
  }

  void _updateRepairRate(String service, double rate) {
    setState(() {
      _repairRates[service] = rate;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Card Configuration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveRates,
            tooltip: 'Save Rates',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Astar Rates Section
          _buildSectionHeader(
            'Astar (Lining) Material Rates',
            'Per meter pricing for shop-provided lining',
            Icons.layers,
            AppTheme.accentColor,
          ),
          const SizedBox(height: 16),
          ..._astarRates.entries.map((entry) {
            return _buildRateCard(
              _getMaterialDisplayName(entry.key),
              entry.value,
              (value) => _updateAstarRate(entry.key, value),
              '₹/meter',
              Icons.straighten,
            );
          }),

          const SizedBox(height: 32),
          const Divider(thickness: 2),
          const SizedBox(height: 32),

          // Repair Rates Section
          _buildSectionHeader(
            'Repair Service Rates',
            'Standard pricing for common alterations',
            Icons.build,
            AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          ..._repairRates.entries.map((entry) {
            return _buildRateCard(
              _getServiceDisplayName(entry.key),
              entry.value,
              (value) => _updateRepairRate(entry.key, value),
              '₹/job',
              Icons.currency_rupee,
            );
          }),

          const SizedBox(height: 32),

          // Save Button
          ElevatedButton.icon(
            onPressed: _saveRates,
            icon: const Icon(Icons.save),
            label: const Text('Save Rate Card'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateCard(
    String name,
    double rate,
    Function(double) onChanged,
    String unit,
    IconData icon,
  ) {
    final controller = TextEditingController(text: rate.toStringAsFixed(0));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.accentColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 100,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onChanged: (value) {
                  final parsed = double.tryParse(value);
                  if (parsed != null) {
                    onChanged(parsed);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMaterialDisplayName(String key) {
    switch (key) {
      case 'COTTON':
        return 'Cotton Astar';
      case 'CREPE':
        return 'Crepe Astar';
      case 'SATIN':
        return 'Satin Astar';
      case 'TAFETTA':
        return 'Tafetta Astar';
      default:
        return key;
    }
  }

  String _getServiceDisplayName(String key) {
    switch (key) {
      case 'ZIPPER':
        return 'Chain Badlai (Zipper)';
      case 'HEM':
        return 'Turpai (Hemming)';
      case 'PICO':
        return 'Fall-Pico';
      case 'FITTING':
        return 'Fitting/Resizing';
      case 'PATCH':
        return 'Patch Work';
      default:
        return key;
    }
  }
}
