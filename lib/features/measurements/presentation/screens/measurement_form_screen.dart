import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';

class MeasurementFormScreen extends StatefulWidget {
  const MeasurementFormScreen({super.key});

  @override
  State<MeasurementFormScreen> createState() => _MeasurementFormScreenState();
}

class _MeasurementFormScreenState extends State<MeasurementFormScreen> {
  double _fitValue = 0.5; // 0 = Tight, 1 = Loose
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Expecting args to include customerId and partName
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final partName = args['partName'] ?? 'Body Part';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: Text('$partName Measurement')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter Size (inches)', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                suffixText: 'in',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            
            const SizedBox(height: 48),
            Text('Fit Preference', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Tight'),
                Text('Regular'),
                Text('Loose'),
              ],
            ),
            Slider(
              value: _fitValue,
              onChanged: (val) => setState(() => _fitValue = val),
              divisions: 2,
              activeColor: AppTheme.primaryColor,
            ),
            
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                    if (_controller.text.isEmpty) return;
                    final val = double.tryParse(_controller.text) ?? 0.0;
                    Navigator.pop(context, {
                        'value': val,
                        'fit': _fitValue < 0.3 ? "Tight" : (_fitValue > 0.7 ? "Loose" : "Regular")
                    });
                },
                child: const Text('Save Measurement'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
