import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';

class Lab11AdvancedScreen extends StatefulWidget {
  const Lab11AdvancedScreen({super.key});

  @override
  State<Lab11AdvancedScreen> createState() => _Lab11AdvancedScreenState();
}

class _Lab11AdvancedScreenState extends State<Lab11AdvancedScreen> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  String? _scannedValue;
  bool _isScanning = false;

  // --- Image Picking Logic ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image picked successfully!'),
            backgroundColor: AppTheme.trustGreen,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab 11: Advanced Features'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('📊 Analytics Dashboard', 'Option D: Data Visualization'),
            const SizedBox(height: 12),
            _buildChartsSection(),
            const SizedBox(height: 24),
            
            _buildSectionHeader('📸 Design Studio', 'Option B: Image / Media Upload'),
            const SizedBox(height: 12),
            _buildImagePickerSection(),
            const SizedBox(height: 24),
            
            _buildSectionHeader('🔍 Smart Tools', 'Option E: QR/Barcode Scanner'),
            const SizedBox(height: 12),
            _buildScannerSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.textTheme.headlineMedium),
        Text(subtitle, style: AppTheme.textTheme.labelSmall?.copyWith(color: AppTheme.deepBronze)),
      ],
    );
  }

  // --- 1. Charts Section (Option D) ---
  Widget _buildChartsSection() {
    return NeoCard(
      child: Column(
        children: [
          const Text('Monthly Revenue (₹)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 20,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
                        return Text(days[value.toInt() % days.length], style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _makeGroupData(0, 12, AppTheme.deepBronze),
                  _makeGroupData(1, 15, AppTheme.trustGreen),
                  _makeGroupData(2, 8, AppTheme.safetyOrange),
                  _makeGroupData(3, 18, AppTheme.deepBronze),
                  _makeGroupData(4, 14, AppTheme.trustGreen),
                ],
              ),
            ),
          ),
          const Divider(height: 40),
          const Text('Order Categories', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 30,
                sections: [
                  PieChartSectionData(value: 40, title: 'Kurtas', color: AppTheme.deepBronze, radius: 40, titleStyle: const TextStyle(color: Colors.white, fontSize: 10)),
                  PieChartSectionData(value: 30, title: 'Shirts', color: AppTheme.trustGreen, radius: 40, titleStyle: const TextStyle(color: Colors.white, fontSize: 10)),
                  PieChartSectionData(value: 20, title: 'Blouse', color: AppTheme.bronzeTint, radius: 40, titleStyle: const TextStyle(color: Colors.white, fontSize: 10)),
                  PieChartSectionData(value: 10, title: 'Other', color: AppTheme.safetyOrange, radius: 40, titleStyle: const TextStyle(color: Colors.white, fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  // --- 2. Image Picker Section (Option B) ---
  Widget _buildImagePickerSection() {
    return NeoCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPickerButton(Icons.camera_alt, 'Camera', () => _pickImage(ImageSource.camera)),
              _buildPickerButton(Icons.photo_library, 'Gallery', () => _pickImage(ImageSource.gallery)),
            ],
          ),
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_selectedImages[index].path),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No design sketches uploaded yet.', style: TextStyle(color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  Widget _buildPickerButton(IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: AppTheme.softWhite,
        foregroundColor: AppTheme.deepBronze,
        elevation: 2,
      ),
    );
  }

  // --- 3. Scanner Section (Option E) ---
  Widget _buildScannerSection() {
    return NeoCard(
      child: Column(
        children: [
          if (_isScanning)
            SizedBox(
              height: 250,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      setState(() {
                        _scannedValue = barcodes.first.rawValue;
                        _isScanning = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Scanned: $_scannedValue'),
                          backgroundColor: AppTheme.trustGreen,
                        ),
                      );
                    }
                  },
                ),
              ),
            )
          else
            Column(
              children: [
                if (_scannedValue != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.trustGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.trustGreen),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code_2, color: AppTheme.trustGreen),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Result: $_scannedValue',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.trustGreen),
                          ),
                        ),
                      ],
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _isScanning = true),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Start Scanning Receipt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.deepBronze,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          if (_isScanning)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextButton(
                onPressed: () => setState(() => _isScanning = false),
                child: const Text('Cancel Scan', style: TextStyle(color: AppTheme.alertRed)),
              ),
            ),
        ],
      ),
    );
  }
}
