import 'dart:io';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
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
  String _unit = 'in';
  Map<String, dynamic>? _wizardData;
  Map<String, TextEditingController> _controllers = {};
  List<String> _fields = [];
  String? _samplePhotoPath;
  String? _activeField;

  Future<void> _pickSampleImage() async {
    final picker = ImagePicker();
    final theme = Theme.of(context);
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardTheme.color,
        title: Text(
          'Select Photo Source',
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            icon: const Icon(Icons.camera_alt, color: AppTheme.brandPurple),
            label: Text('Camera', style: TextStyle(color: theme.colorScheme.onSurface)),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            icon: const Icon(Icons.photo_library, color: AppTheme.brandPurple),
            label: Text('Gallery', style: TextStyle(color: theme.colorScheme.onSurface)),
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
      _wizardData =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _initFields();
    }
  }

  void _initFields() {
    final garment =
        _wizardData?['garmentType']?.toString().toLowerCase() ?? 'shirt';
    if (garment.contains('blouse')) {
      _fields = ['Length', 'Chest', 'Waist', 'Shoulder', 'Sleeve', 'Front Neck', 'Back Neck'];
    } else if (garment.contains('kurti') || garment.contains('kameez')) {
      _fields = ['Length', 'Chest', 'Waist', 'Hip', 'Shoulder', 'Sleeve', 'Armhole'];
    } else if (garment.contains('salwar') || garment.contains('chudidar') || garment.contains('palazzo')) {
      _fields = ['Length', 'Waist', 'Hip', 'Thigh', 'Knee', 'Bottom'];
    } else if (garment.contains('lehenga') || garment.contains('skirt')) {
      _fields = ['Length', 'Waist', 'Hip', 'Flare'];
    } else if (garment.contains('pant') || garment.contains('trouser')) {
      _fields = ['Length', 'Waist', 'Hip', 'Inseam', 'Thigh', 'Bottom'];
    } else if (garment.contains('suit') || garment.contains('safari')) {
      _fields = ['Length', 'Shoulder', 'Chest', 'Waist', 'Sleeve', 'Collar'];
    } else if (garment.contains('shirt') || garment.contains('kurta')) {
      _fields = ['Length', 'Chest', 'Waist', 'Shoulder', 'Sleeve', 'Neck'];
    } else {
      _fields = ['Length', 'Shoulder', 'Chest', 'Waist', 'Sleeve'];
    }

    _controllers = {for (final f in _fields) f: TextEditingController()};

    // Pre-populate if customer has saved measurements (UX-08 Repeat Customer Shortcut)
    if (_wizardData?['measurements'] is Map) {
      final raw = _wizardData!['measurements'] as Map;
      Map<dynamic, dynamic>? sourceMap;
      final cleanKey = garment.replaceAll(RegExp(r'\s+'), '').toLowerCase();

      if (raw[cleanKey] is Map) {
        sourceMap = raw[cleanKey] as Map;
      } else if (cleanKey.contains('shirt') && raw['shirt'] is Map) {
        sourceMap = raw['shirt'] as Map;
      } else if ((cleanKey.contains('pant') || cleanKey.contains('salwar') || cleanKey.contains('trouser')) && raw['pant'] is Map) {
        sourceMap = raw['pant'] as Map;
      } else if (cleanKey.contains('blouse') && raw['blouse'] is Map) {
        sourceMap = raw['blouse'] as Map;
      } else if (cleanKey.contains('kurti') && raw['kurti'] is Map) {
        sourceMap = raw['kurti'] as Map;
      } else {
        // Search inside submaps
        for (final entry in raw.entries) {
          if (entry.value is Map && cleanKey.contains(entry.key.toString().toLowerCase())) {
            sourceMap = entry.value as Map;
            break;
          }
        }
        sourceMap ??= raw;
      }

      sourceMap.forEach((k, v) {
        final normK = k.toString().replaceAll(RegExp(r'[\s\-_]'), '').toLowerCase();
        final fieldKey = _fields.firstWhere(
          (f) => f.replaceAll(RegExp(r'[\s\-_]'), '').toLowerCase() == normK,
          orElse: () => '',
        );
        if (fieldKey.isNotEmpty && v != null && v.toString().isNotEmpty) {
          _controllers[fieldKey]?.text = v.toString();
        }
      });
    }

    if (_fields.isNotEmpty) {
      _activeField = _fields.first;
    }
  }

  void _applyFractionToActiveField(String fraction) {
    if (_activeField == null) return;
    final controller = _controllers[_activeField];
    if (controller == null) return;
    final current = controller.text.trim();
    if (current.isEmpty) {
      controller.text = fraction;
    } else if (current.contains('/')) {
      final parts = current.split(' ');
      controller.text = '${parts.first} $fraction';
    } else {
      controller.text = '$current $fraction';
    }
    setState(() {});
  }

  double? parseMeasurement(String value) {
    final normalized = value.replaceAll('-', ' ').trim();
    final parts = normalized.split(RegExp(r'\s+'));
    if (parts.length == 2 && parts[1].contains('/')) {
      final fraction = parts[1].split('/');
      final whole = double.tryParse(parts[0]);
      final numerator = double.tryParse(fraction[0]);
      final denominator = double.tryParse(fraction[1]);
      if (whole != null &&
          numerator != null &&
          denominator != null &&
          denominator != 0) {
        return whole + numerator / denominator;
      }
    }
    if (normalized.contains('/')) {
      final fraction = normalized.split('/');
      if (fraction.length == 2) {
        final numerator = double.tryParse(fraction[0]);
        final denominator = double.tryParse(fraction[1]);
        if (numerator != null && denominator != null && denominator != 0) {
          return numerator / denominator;
        }
      }
    }
    return double.tryParse(normalized);
  }

  void _onNext() {
    if (_wizardData == null) return;

    if (_isBodyMeasurement) {
      final Map<String, double> values = {};
      for (final f in _fields) {
        final rawValue = _controllers[f]!.text.trim();
        final val = parseMeasurement(rawValue);
        if (val == null || val <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Enter a valid $_unit value for $f'),
              backgroundColor: AppTheme.alertRed,
            ),
          );
          return;
        }

        String key = f.toLowerCase();
        if (key == 'hip') key = 'hips';
        if (key == 'sleeve') key = 'sleeves';
        values[key] = val;
      }

      final garment =
          _wizardData?['garmentType']?.toString().toLowerCase() ?? 'shirt';
      final Map<String, dynamic> structured = {};
      if (garment.contains('shirt')) {
        structured['shirt'] = values;
      } else if (garment.contains('pant') || garment.contains('trouser')) {
        structured['pant'] = values;
      } else {
        structured['others'] = values.entries
            .map((e) => '${e.key}: ${e.value}')
            .join(', ');
      }

      _wizardData!['measurements'] = structured;
      _wizardData!['measurementUnit'] = _unit;
      _wizardData!.remove('samplePhotoPath');
    } else {
      _wizardData!['measurements'] = <String, dynamic>{};
      _wizardData!['samplePhotoPath'] = _samplePhotoPath;
    }

    _wizardData!['measurementType'] = _isBodyMeasurement ? 'body' : 'sample';

    // Autosave draft (UX-04)
    try {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('draft_order_wizard', json.encode(_wizardData));
      });
    } catch (_) {}

    Navigator.pushNamed(context, '/create_order_step4', arguments: _wizardData);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String garmentTitle = _wizardData?['garmentType'] ?? 'Garment';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text('New order · 3 of 5 · $garmentTitle')),
      body: Column(
        children: [
          // Mode and unit controls
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      _buildToggleOption('Body Measurement (માપ)', true),
                      _buildToggleOption('Sample (નમૂનો / Namuna)', false),
                    ],
                  ),
                ),
                if (_isBodyMeasurement) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                      segments: const [
                        ButtonSegment(
                          value: 'in',
                          label: Text(
                            'Inches (in)',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          icon: Icon(Icons.straighten, size: 16),
                        ),
                        ButtonSegment(
                          value: 'cm',
                          label: Text(
                            'Centimeters (cm)',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          icon: Icon(Icons.square_foot, size: 16),
                        ),
                      ],
                      selected: {_unit},
                      onSelectionChanged: (selection) {
                        setState(() => _unit = selection.first);
                      },
                    ),
                  ),
                  if (_unit == 'in') ...[
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.brandPurple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.add, size: 14, color: AppTheme.brandPurple),
                                SizedBox(width: 3),
                                Text(
                                  'Fraction:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.brandPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          ...['1/8', '1/4', '3/8', '1/2', '5/8', '3/4', '7/8'].map((fraction) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: theme.cardTheme.color,
                                side: BorderSide(
                                  color: AppTheme.brandPurple.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                                label: Text(
                                  fraction,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                onPressed: () => _applyFractionToActiveField(fraction),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),

          Expanded(
            child: _isBodyMeasurement
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _fields.length,
                    itemBuilder: (context, index) {
                      final f = _fields[index];
                      final isActive = _activeField == f;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive
                                  ? AppTheme.brandPurple
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: VoiceTextField(
                            label: '$f ($_unit)',
                            controller: _controllers[f]!,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            hint: 'Enter $f measurement (e.g. 34 1/2)',
                            onChanged: (_) {
                              if (_activeField != f) {
                                setState(() => _activeField = f);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  )
                : Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Please upload or take a photo of the sample garment (Namuna)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: _pickSampleImage,
                            child: Container(
                              width: double.infinity,
                              height: 260,
                              decoration: BoxDecoration(
                                color: theme.cardTheme.color,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
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
                                        const Icon(
                                          Icons.camera_alt_outlined,
                                          size: 52,
                                          color: AppTheme.brandPurple,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Tap to Take or Upload Photo',
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          if (_samplePhotoPath != null) ...[
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: _pickSampleImage,
                              icon: const Icon(
                                Icons.refresh,
                                color: AppTheme.brandPurple,
                              ),
                              label: const Text(
                                'Change Photo',
                                style: TextStyle(color: AppTheme.brandPurple, fontWeight: FontWeight.bold),
                              ),
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
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.darkGrey,
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}
