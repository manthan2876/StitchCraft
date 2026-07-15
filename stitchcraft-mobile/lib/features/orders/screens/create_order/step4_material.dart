import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/widgets/primary_button.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class MaterialSelectionScreen extends StatefulWidget {
  const MaterialSelectionScreen({super.key});

  @override
  State<MaterialSelectionScreen> createState() => _MaterialSelectionScreenState();
}

class _MaterialSelectionScreenState extends State<MaterialSelectionScreen> {
  final _authService = AuthService();
  bool _isLoading = false;
  Map<String, dynamic>? _wizardData;

  String _fabricSource = 'Customer';
  bool _needsLining = false;
  double _liningLength = 2.0;

  List<dynamic> _inventoryItems = [];
  Map<String, dynamic>? _selectedLiningItem;
  String? _fabricPhotoPath;

  Future<void> _pickFabricImage() async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Select Fabric Photo Source', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          _fabricPhotoPath = pickedFile.path;
        });
      }
    } catch (e) {
      developer.log("Error picking fabric image: $e");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_wizardData == null) {
      _wizardData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _loadLiningItems();
    }
  }

  Future<void> _loadLiningItems() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/inventory'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          // Filter items by type "lining" or let them choose any lining/lining-alike item
          _inventoryItems = data.where((item) {
            final type = (item['itemType'] ?? '').toString().toLowerCase();
            return type.contains('lining') || type.contains('fabric') || type.contains('astar');
          }).toList();
        });
      }
    } catch (e) {
      developer.log("Error loading lining inventory: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onNext() {
    if (_wizardData == null) return;

    if (_needsLining && _selectedLiningItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a lining material from your inventory'), backgroundColor: AppTheme.alertRed),
      );
      return;
    }

    _wizardData!['fabricSource'] = _fabricSource;
    _wizardData!['needsLining'] = _needsLining;
    _wizardData!['fabricPhotoPath'] = _fabricPhotoPath;

    if (_needsLining && _selectedLiningItem != null) {
      _wizardData!['liningItem'] = _selectedLiningItem;
      _wizardData!['liningQtyUsed'] = _liningLength;
    } else {
      _wizardData!.remove('liningItem');
      _wizardData!.remove('liningQtyUsed');
    }

    Navigator.pushNamed(context, '/create_order_step5', arguments: _wizardData);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Material & Lining'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fabric Details
            const Text('Main Fabric Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            NeoCard(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickFabricImage,
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color?.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: _fabricPhotoPath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb
                                  ? Image.network(
                                      _fabricPhotoPath!,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(_fabricPhotoPath!),
                                      fit: BoxFit.cover,
                                    ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.camera_alt_outlined, size: 36, color: AppTheme.brandPurple),
                                const SizedBox(height: 8),
                                Text('Take Fabric Photo', style: TextStyle(color: theme.colorScheme.onSurface)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile(
                          title: Text('Customer', style: TextStyle(color: theme.colorScheme.onSurface)),
                          value: 'Customer',
                          // ignore: deprecated_member_use
                          groupValue: _fabricSource,
                          // ignore: deprecated_member_use
                          onChanged: (val) => setState(() => _fabricSource = val.toString()),
                          activeColor: AppTheme.brandPurple,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile(
                          title: Text('Shop', style: TextStyle(color: theme.colorScheme.onSurface)),
                          value: 'Shop',
                          // ignore: deprecated_member_use
                          groupValue: _fabricSource,
                          // ignore: deprecated_member_use
                          onChanged: (val) => setState(() => _fabricSource = val.toString()),
                          activeColor: AppTheme.brandPurple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Lining / Astar toggle details
            const Text('Lining (Astar) Stock', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            NeoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Needs Lining / Astar?', style: TextStyle(color: theme.colorScheme.onSurface)),
                      Switch(
                        value: _needsLining,
                        onChanged: (val) => setState(() => _needsLining = val),
                        // ignore: deprecated_member_use
                        activeColor: AppTheme.brandPurple,
                      ),
                    ],
                  ),
                  if (_needsLining) ...[
                    const Divider(color: Colors.white10, height: 24),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _inventoryItems.isEmpty
                            ? const Text('No lining materials found in stock.', style: TextStyle(color: AppTheme.darkGrey))
                            : DropdownButtonFormField<Map<String, dynamic>>(
                                dropdownColor: AppTheme.darkCard,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Select Lining Stock'),
                                // ignore: deprecated_member_use
                                value: _selectedLiningItem,
                                items: _inventoryItems.map((item) {
                                  final name = item['itemName'] ?? 'Material';
                                  final qty = item['quantity'] ?? 0;
                                  final unit = item['unit'] ?? 'm';
                                  return DropdownMenuItem(
                                    value: item as Map<String, dynamic>,
                                    child: Text(
                                      '$name (Stock: $qty $unit)',
                                      style: const TextStyle(color: Colors.white),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedLiningItem = val;
                                  });
                                },
                              ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text('Length Required: ', style: TextStyle(color: theme.colorScheme.onSurface)),
                        Expanded(
                          child: Slider(
                            value: _liningLength,
                            min: 0.5,
                            max: 10.0,
                            divisions: 19,
                            label: '${_liningLength}m',
                            activeColor: AppTheme.brandPurple,
                            onChanged: (val) => setState(() => _liningLength = val),
                          ),
                        ),
                        Text(
                          '${_liningLength}m',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 40),

            PrimaryButton(
              text: 'Next: Confirm Details',
              onPressed: _onNext,
            ),
          ],
        ),
      ),
    );
  }
}
