import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/primary_button.dart';
import 'package:stitchcraft/core/widgets/voice_text_field.dart';

class AddMeasurementsBottomSheet extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String initialGarmentType; // 'shirt' or 'pant'
  final Map<String, dynamic>? existingMeasurements;
  final Function(Map<String, dynamic> updatedMeasurements) onSaved;

  const AddMeasurementsBottomSheet({
    super.key,
    required this.customerId,
    required this.customerName,
    this.initialGarmentType = 'shirt',
    this.existingMeasurements,
    required this.onSaved,
  });

  @override
  State<AddMeasurementsBottomSheet> createState() =>
      _AddMeasurementsBottomSheetState();
}

class _AddMeasurementsBottomSheetState
    extends State<AddMeasurementsBottomSheet> {
  final _localDb = LocalDatabaseService();
  final _authService = AuthService();

  late String _selectedGarment; // 'shirt' or 'pant'
  String _unit = 'in'; // 'in' or 'cm'
  bool _isSaving = false;
  String? _activeField;

  // Shirt controllers
  final Map<String, TextEditingController> _shirtControllers = {
    'Length': TextEditingController(),
    'Chest': TextEditingController(),
    'Waist': TextEditingController(),
    'Shoulder': TextEditingController(),
    'Sleeves': TextEditingController(),
    'Neck': TextEditingController(),
    'Hips': TextEditingController(),
    'Notes': TextEditingController(),
  };

  // Pant controllers
  final Map<String, TextEditingController> _pantControllers = {
    'Length': TextEditingController(),
    'Waist': TextEditingController(),
    'Hips': TextEditingController(),
    'Inseam': TextEditingController(),
    'Thigh': TextEditingController(),
    'Rise': TextEditingController(),
    'Bottom': TextEditingController(),
    'Notes': TextEditingController(),
  };

  final List<String> _shirtFields = [
    'Length',
    'Chest',
    'Waist',
    'Shoulder',
    'Sleeves',
    'Neck',
    'Hips',
  ];

  final List<String> _pantFields = [
    'Length',
    'Waist',
    'Hips',
    'Inseam',
    'Thigh',
    'Rise',
    'Bottom',
  ];

  // Dual-language field labels (English + Gujarati/Hindi)
  final Map<String, String> _shirtLabels = {
    'Length': 'Length (લંબાઈ / लंबाई)',
    'Chest': 'Chest (છાતી / सीना)',
    'Waist': 'Waist (કમર / कमर)',
    'Shoulder': 'Shoulder (શોલ્ડર / कन्धा)',
    'Sleeves': 'Sleeves (બાય / आस्तीन)',
    'Neck': 'Neck (ગળું / कॉलर)',
    'Hips': 'Hips (સીટ / हिप)',
  };

  final Map<String, String> _pantLabels = {
    'Length': 'Length (લંબાઈ / लंबाई)',
    'Waist': 'Waist (કમર / कमर)',
    'Hips': 'Hips (સીટ / हिप)',
    'Inseam': 'Inseam (ઇનસીમ / आन्तरिक)',
    'Thigh': 'Thigh (જાંઘ / जाँघ)',
    'Rise': 'Rise (આસન / आसन)',
    'Bottom': 'Bottom (બોટમ / मोहरी)',
  };

  @override
  void initState() {
    super.initState();
    _selectedGarment = widget.initialGarmentType.toLowerCase().contains('pant')
        ? 'pant'
        : 'shirt';
    _populateExisting();
    _activeField = _currentFields.isNotEmpty ? _currentFields.first : null;
  }

  void _populateExisting() {
    if (widget.existingMeasurements == null) return;

    final shirtData = widget.existingMeasurements!['shirt'];
    if (shirtData is Map) {
      shirtData.forEach((k, v) {
        if (v == null) return;
        final keyStr = k.toString().toLowerCase();
        final match = _shirtControllers.keys.firstWhere(
          (fk) => fk.toLowerCase() == keyStr,
          orElse: () => '',
        );
        if (match.isNotEmpty && v.toString() != '0' && v.toString() != '0.0') {
          _shirtControllers[match]?.text = v.toString();
        }
      });
      if (shirtData['notes'] != null && shirtData['notes'].toString().isNotEmpty) {
        _shirtControllers['Notes']?.text = shirtData['notes'].toString();
      }
    }

    final pantData = widget.existingMeasurements!['pant'];
    if (pantData is Map) {
      pantData.forEach((k, v) {
        if (v == null) return;
        final keyStr = k.toString().toLowerCase();
        final match = _pantControllers.keys.firstWhere(
          (fk) => fk.toLowerCase() == keyStr,
          orElse: () => '',
        );
        if (match.isNotEmpty && v.toString() != '0' && v.toString() != '0.0') {
          _pantControllers[match]?.text = v.toString();
        }
      });
      if (pantData['notes'] != null && pantData['notes'].toString().isNotEmpty) {
        _pantControllers['Notes']?.text = pantData['notes'].toString();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _shirtControllers.values) {
      c.dispose();
    }
    for (final c in _pantControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _currentFields =>
      _selectedGarment == 'shirt' ? _shirtFields : _pantFields;

  Map<String, TextEditingController> get _currentControllers =>
      _selectedGarment == 'shirt' ? _shirtControllers : _pantControllers;

  Map<String, String> get _currentLabels =>
      _selectedGarment == 'shirt' ? _shirtLabels : _pantLabels;

  void _applyFraction(String fraction) {
    if (_activeField == null) return;
    final controller = _currentControllers[_activeField];
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

  double? _parseMeasurement(String value) {
    final normalized = value.replaceAll('-', ' ').trim();
    if (normalized.isEmpty) return null;

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
        return whole + (numerator / denominator);
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

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    try {
      // 1. Build Shirt Map
      final Map<String, dynamic> shirtMap = {};
      for (final f in _shirtFields) {
        final raw = _shirtControllers[f]!.text.trim();
        final val = _parseMeasurement(raw);
        if (val != null && val > 0) {
          shirtMap[f.toLowerCase()] = val;
        }
      }
      final shirtNotes = _shirtControllers['Notes']!.text.trim();
      if (shirtNotes.isNotEmpty) {
        shirtMap['notes'] = shirtNotes;
      }

      // 2. Build Pant Map
      final Map<String, dynamic> pantMap = {};
      for (final f in _pantFields) {
        final raw = _pantControllers[f]!.text.trim();
        final val = _parseMeasurement(raw);
        if (val != null && val > 0) {
          pantMap[f.toLowerCase()] = val;
        }
      }
      final pantNotes = _pantControllers['Notes']!.text.trim();
      if (pantNotes.isNotEmpty) {
        pantMap['notes'] = pantNotes;
      }

      if (shirtMap.isEmpty && pantMap.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter at least one measurement value.'),
            backgroundColor: AppTheme.alertRed,
          ),
        );
        setState(() => _isSaving = false);
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch;

      // 3. Save into local SQLite `measurements` table
      if (shirtMap.isNotEmpty) {
        await _localDb.insertMeasurement({
          'id': '${widget.customerId}_shirt',
          'customer_id': widget.customerId,
          'item_type': 'shirt',
          'measurements_json': json.encode(shirtMap),
          'measurement_date': now,
          'notes': shirtNotes,
          'sync_status': 3,
          'updated_at': now,
          'measurement_mode': 'body',
        });
      }

      if (pantMap.isNotEmpty) {
        await _localDb.insertMeasurement({
          'id': '${widget.customerId}_pant',
          'customer_id': widget.customerId,
          'item_type': 'pant',
          'measurements_json': json.encode(pantMap),
          'measurement_date': now,
          'notes': pantNotes,
          'sync_status': 3,
          'updated_at': now,
          'measurement_mode': 'body',
        });
      }

      // 4. Push to remote backend if online
      try {
        final token = await _authService.getToken();
        if (token != null) {
          final payload = {
            'measurements': {
              'shirt': shirtMap,
              'pant': pantMap,
            },
          };
          await http
              .put(
                Uri.parse('${AuthService.baseUrl}/customers/${widget.customerId}'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
                body: json.encode(payload),
              )
              .timeout(const Duration(seconds: 8));
        }
      } catch (remoteErr) {
        developer.log('Remote measurement sync note: $remoteErr');
      }

      final updatedResult = {
        'shirt': shirtMap,
        'pant': pantMap,
      };

      widget.onSaved(updatedResult);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Measurements saved successfully!'),
            backgroundColor: AppTheme.trustGreen,
          ),
        );
      }
    } catch (e) {
      developer.log('Save measurements error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving measurements: $e'),
            backgroundColor: AppTheme.alertRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Measurements',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Fitting details for ${widget.customerName}',
                      style: const TextStyle(
                        color: AppTheme.darkGrey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Garment Selector (Shirt / Pant)
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkBg : AppTheme.lightGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildGarmentToggleTab(
                    label: 'Shirt / Kurta (શર્ટ / कुर्ता)',
                    value: 'shirt',
                    icon: Icons.checkroom,
                  ),
                ),
                Expanded(
                  child: _buildGarmentToggleTab(
                    label: 'Pant / Trouser (પેન્ટ / सलवार)',
                    value: 'pant',
                    icon: Icons.airline_seat_legroom_extra,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Unit toggle and fraction shortcuts
          Row(
            children: [
              // Interactive Unit Chip
              InkWell(
                onTap: () {
                  setState(() {
                    _unit = _unit == 'in' ? 'cm' : 'in';
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.brandPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.brandPurple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.straighten, size: 14, color: AppTheme.brandPurple),
                      const SizedBox(width: 4),
                      Text(
                        _unit.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.brandPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Fraction buttons row
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text(
                        'Fraction: ',
                        style: TextStyle(
                          color: AppTheme.darkGrey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ...['1/8', '1/4', '3/8', '1/2', '5/8', '3/4', '7/8'].map((frac) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => _applyFraction(frac),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.darkBg
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppTheme.brandPurple.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Text(
                                frac,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Measurement Fields List
          Expanded(
            child: ListView(
              children: [
                ..._currentFields.map((field) {
                  final isActive = _activeField == field;
                  final label = _currentLabels[field] ?? field;
                  final controller = _currentControllers[field]!;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
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
                        label: label,
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        hint: 'e.g. 38 1/2 or 38.5 ($_unit)',
                        onChanged: (_) {
                          if (_activeField != field) {
                            setState(() => _activeField = field);
                          }
                        },
                      ),
                    ),
                  );
                }),

                // Notes field for tailoring preferences
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: VoiceTextField(
                    label: 'Fitting Notes (વિશેષ નોંધ / विशेष विवरण)',
                    controller: _currentControllers['Notes']!,
                    hint: 'e.g. Loose fitting, French cuff, high waist...',
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Save Button
          PrimaryButton(
            text: _isSaving ? 'Saving...' : 'Save Measurements (માપ સાચવો)',
            onPressed: _isSaving ? () {} : _handleSave,
            isLoading: _isSaving,
          ),
        ],
      ),
    );
  }

  Widget _buildGarmentToggleTab({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _selectedGarment == value;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedGarment = value;
          _activeField = _currentFields.isNotEmpty ? _currentFields.first : null;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.darkGrey,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
