import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  String? _samplePhotoPath;

  Future<void> _pickSampleImage() async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Select Photo Source', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            icon: const Icon(Icons.camera_alt, color: AppTheme.brandPurple),
            label: const Text('Camera', style: TextStyle(color: Colors.white)),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            icon: const Icon(Icons.photo_library, color: AppTheme.brandPurple),
            label: const Text('Gallery', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (source == null) return;
    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _samplePhotoPath = pickedFile.path;
        });
      }
    } catch (e) {
      developer.log("Error picking sample image: $e");
    }
  }

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

    if (_isBodyMeasurement) {
      final Map<String, double> values = {};
      for (final f in _fields) {
        final val = double.tryParse(_controllers[f]!.text.trim()) ?? 0.0;
        String key = f.toLowerCase();
        if (key == 'hip') key = 'hips';
        if (key == 'sleeve') key = 'sleeves';
        values[key] = val;
      }

      final garment = _wizardData?['garmentType']?.toString().toLowerCase() ?? 'shirt';
      final Map<String, dynamic> structured = {};
      if (garment.contains('shirt')) {
        structured['shirt'] = values;
      } else if (garment.contains('pant') || garment.contains('trouser')) {
        structured['pant'] = values;
      } else {
        structured['others'] = values.entries.map((e) => '${e.key}: ${e.value}').join(', ');
      }

      _wizardData!['measurements'] = structured;
      _wizardData!.remove('samplePhotoPath');
    } else {
      _wizardData!['measurements'] = <String, dynamic>{};
      _wizardData!['samplePhotoPath'] = _samplePhotoPath;
    }

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
            child: _isBodyMeasurement
                ? Row(
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
                                  Icons.accessibility_new_outlined,
                                  size: 80,
                                  color: AppTheme.brandPurple.withValues(alpha: 0.15),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Body View',
                                  style: TextStyle(color: AppTheme.darkGrey, fontSize: 13),
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
                  )
                : Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Please upload or take a photo of the sample garment (Namuna)',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: _pickSampleImage,
                            child: Container(
                              width: double.infinity,
                              height: 250,
                              decoration: BoxDecoration(
                                color: theme.cardTheme.color,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: _samplePhotoPath != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: kIsWeb
                                          ? Image.network(
                                              _samplePhotoPath!,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.file(
                                              File(_samplePhotoPath!),
                                              fit: BoxFit.cover,
                                            ),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.camera_alt_outlined, size: 50, color: AppTheme.brandPurple),
                                        const SizedBox(height: 12),
                                        const Text('Tap to Take/Upload Photo', style: TextStyle(color: AppTheme.darkGrey)),
                                      ],
                                    ),
                            ),
                          ),
                          if (_samplePhotoPath != null) ...[
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: _pickSampleImage,
                              icon: const Icon(Icons.refresh, color: AppTheme.brandPurple),
                              label: const Text('Change Photo', style: TextStyle(color: AppTheme.brandPurple)),
                            ),
                          ],
                        ],
                      ),
                    ),
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
