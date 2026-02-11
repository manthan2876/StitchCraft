import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/widgets/primary_button.dart';

class MaterialSelectionScreen extends StatefulWidget {
  const MaterialSelectionScreen({super.key});

  @override
  State<MaterialSelectionScreen> createState() => _MaterialSelectionScreenState();
}

class _MaterialSelectionScreenState extends State<MaterialSelectionScreen> {
  bool _needsAstar = false;
  double _astarLength = 2.0;
  String _fabricSource = 'Customer'; // Customer or Shop

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(title: const Text('Material & Astar')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Fabric Photo
            NeoCard(
              child: Column(
                children: [
                  Text('Main Fabric', style: AppTheme.masterjiTheme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                        const SizedBox(height: 8),
                         Text('Take Photo of Cloth', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile(
                          title: const Text('Customer'),
                          value: 'Customer',
                          groupValue: _fabricSource,
                          onChanged: (val) => setState(() => _fabricSource = val.toString()),
                          activeColor: AppTheme.navyBlue,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile(
                          title: const Text('Shop'),
                          value: 'Shop',
                          groupValue: _fabricSource,
                          onChanged: (val) => setState(() => _fabricSource = val.toString()),
                          activeColor: AppTheme.navyBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Astar Section
            NeoCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Needs Astar (Lining)?', style: AppTheme.masterjiTheme.textTheme.titleMedium),
                      Switch(
                        value: _needsAstar,
                        onChanged: (val) => setState(() => _needsAstar = val),
                        activeColor: AppTheme.marigold,
                      ),
                    ],
                  ),
                  if (_needsAstar) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Length: '),
                        Expanded(
                          child: Slider(
                            value: _astarLength,
                            min: 0.5,
                            max: 5.0,
                            divisions: 9,
                            label: '${_astarLength}m',
                            activeColor: AppTheme.navyBlue,
                            onChanged: (val) => setState(() => _astarLength = val),
                          ),
                        ),
                        Text('${_astarLength}m', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            PrimaryButton(
              text: 'Confirm Order (ઓર્ડર અને બનાવો)',
              icon: Icons.check_circle,
              onPressed: () {
                // Show Success
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order Created Successfully!'),
                    backgroundColor: AppTheme.emerald,
                  ),
                );
                Navigator.popUntil(context, ModalRoute.withName('/home'));
              },
            ),
          ],
        ),
      ),
    );
  }
}
