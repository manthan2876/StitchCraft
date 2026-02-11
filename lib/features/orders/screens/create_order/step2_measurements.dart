import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/primary_button.dart';
import 'package:stitchcraft/core/widgets/voice_text_field.dart';

class MeasurementInputScreen extends StatefulWidget {
  const MeasurementInputScreen({super.key});

  @override
  State<MeasurementInputScreen> createState() => _MeasurementInputScreenState();
}

class _MeasurementInputScreenState extends State<MeasurementInputScreen> {
  bool _isBodyMeasurement = true;
  final Map<String, TextEditingController> _controllers = {
    'Length': TextEditingController(),
    'Shoulder': TextEditingController(),
    'Chest': TextEditingController(),
    'Waist': TextEditingController(),
    'Sleeve': TextEditingController(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(title: const Text('Measurements')),
      body: Column(
        children: [
          // Toggle Switch
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppTheme.navyBlue),
              ),
              child: Row(
                children: [
                  _buildToggleOption('Body Measure', true),
                  _buildToggleOption('Sample (Namuna)', false),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: Row(
              children: [
                // Visual Guide (Left)
                Expanded(
                  flex: 2, // 40%
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isBodyMeasurement ? Icons.accessibility_new : Icons.layers,
                            size: 100,
                            color: AppTheme.navyBlue.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isBodyMeasurement ? 'Mannequin View' : 'Folded View',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Inputs (Right)
                Expanded(
                  flex: 3, // 60%
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: _controllers.keys.map((label) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: VoiceTextField(
                          label: label,
                          controller: _controllers[label]!,
                          keyboardType: TextInputType.number,
                          hint: '0.0',
                          onMicTap: () {},
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Next Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: PrimaryButton(
              text: 'Next: Material',
              onPressed: () {
                 Navigator.pushNamed(context, '/create_order_step3');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String title, bool isBody) {
    bool isSelected = _isBodyMeasurement == isBody;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isBodyMeasurement = isBody;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.navyBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? AppTheme.marigold : AppTheme.navyBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
