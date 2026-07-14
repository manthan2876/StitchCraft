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
  Map<String, dynamic>? _wizardData;
  Map<String, TextEditingController> _controllers = {};
  List<String> _fields = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_wizardData == null) {
      _wizardData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _initFields();
    }
  }

  void _initFields() {
    final garment = _wizardData?['garmentType']?.toString().toLowerCase() ?? 'shirt';
    if (garment.contains('shirt')) {
      _fields = ['Length', 'Chest', 'Waist', 'Shoulder', 'Sleeve', 'Neck'];
    } else if (garment.contains('pant') || garment.contains('trouser')) {
      _fields = ['Length', 'Waist', 'Hip', 'Inseam', 'Thigh', 'Bottom'];
    } else if (garment.contains('suit') || garment.contains('kurta')) {
      _fields = ['Length', 'Shoulder', 'Chest', 'Waist', 'Sleeve', 'Collar'];
    } else {
      _fields = ['Length', 'Shoulder', 'Chest', 'Waist', 'Sleeve'];
    }

    _controllers = {
      for (final f in _fields) f: TextEditingController()
    };
  }

  void _onNext() {
    if (_wizardData == null) return;

    final Map<String, double> measurements = {};
    for (final f in _fields) {
      final val = double.tryParse(_controllers[f]!.text.trim()) ?? 0.0;
      measurements[f.toLowerCase()] = val;
    }

    _wizardData!['measurements'] = measurements;
    _wizardData!['measurementType'] = _isBodyMeasurement ? 'body' : 'sample';

    Navigator.pushNamed(context, '/create_order_step4', arguments: _wizardData);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String garmentTitle = _wizardData?['garmentType'] ?? 'Garment';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('$garmentTitle Measurements'),
      ),
      body: Column(
        children: [
          // Toggle Option: Body vs Sample
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppTheme.lightGrey),
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
                // Guide mannequin view
                Expanded(
                  flex: 2,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isBodyMeasurement ? Icons.accessibility_new_outlined : Icons.layers_outlined,
                            size: 80,
                            color: AppTheme.brandPurple.withValues(alpha: 0.15),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isBodyMeasurement ? 'Body View' : 'Garment Sample',
                            style: const TextStyle(color: AppTheme.darkGrey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Form field list
                Expanded(
                  flex: 3,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: _fields.map((f) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: VoiceTextField(
                          label: f,
                          controller: _controllers[f]!,
                          keyboardType: TextInputType.number,
                          hint: '0.0 in',
                          onMicTap: () {},
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: PrimaryButton(
              text: 'Next: Material & Fabric',
              onPressed: _onNext,
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
            color: isSelected ? AppTheme.brandPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.darkGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
