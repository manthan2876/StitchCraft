import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stitchcraft/core/widgets/neo_skeuomorphic_widgets.dart';
import 'package:stitchcraft/core/widgets/smart_numpad_widget.dart';
import 'package:stitchcraft/core/widgets/voice_input_widget.dart';

class HapticMeasurementScreen extends StatefulWidget {
  final String garmentType;
  const HapticMeasurementScreen({super.key, this.garmentType = 'Shirt'});

  @override
  State<HapticMeasurementScreen> createState() => _HapticMeasurementScreenState();
}

class _HapticMeasurementScreenState extends State<HapticMeasurementScreen> {
  final Map<String, String> _measurements = {};
  String _selectedField = 'Length';
  double _fitPreference = 0.5; // 0: Tight, 0.5: Comfort, 1: Loose

  final List<String> _fields = [
    'Length',
    'Chest',
    'Shoulder',
    'Sleeve',
    'Neck',
    'Cuff'
  ];

  void _onKeyPress(String key) {
    setState(() {
      final current = _measurements[_selectedField] ?? '';
      _measurements[_selectedField] = current + key;
    });
  }

  void _onDelete() {
    setState(() {
      final current = _measurements[_selectedField] ?? '';
      if (current.isNotEmpty) {
        _measurements[_selectedField] = current.substring(0, current.length - 1);
      }
    });
  }

  void _onClear() {
    setState(() {
      _measurements[_selectedField] = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.backgroundColor,
      appBar: AppBar(
        title: Text('${widget.garmentType} Measurement Lab'),
        backgroundColor: NeoColors.surfaceColor,
        foregroundColor: NeoColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Left: Digital Mannequin Visualization
                  Expanded(
                    flex: 3,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return _buildMannequin(constraints.maxHeight);
                      },
                    ),
                  ),
                  // Right: Measurement List
                  Expanded(
                    flex: 2,
                    child: _buildFieldList(),
                  ),
              ],
            ),
          ),
          // Bottom Area: Input Controls
          _buildInputControls(),
        ],
      ),
    );
  }

  Widget _buildMannequin(double maxHeight) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 2),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Placeholder for SVG/Vector Mannequin
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.person, size: (maxHeight * 0.6).clamp(100, 280), color: Colors.grey.shade100),
                // Overlay measurement lines based on selection
                if (_selectedField == 'Chest')
                  _buildPulsePoint(Offset(0, -20)),
                if (_selectedField == 'Length')
                  _buildPulsePoint(Offset(0, 40)),
                if (_selectedField == 'Shoulder')
                  _buildPulsePoint(Offset(0, -60)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Tap body part to measure",
              style: TextStyle(color: NeoColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildPulsePoint(Offset offset) {
    return Transform.translate(
      offset: offset,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: NeoColors.primary.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: NeoColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      itemCount: _fields.length,
      itemBuilder: (context, index) {
        final field = _fields[index];
        final isSelected = _selectedField == field;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedField = field);
            },
            child: NeoCard(
              padding: const EdgeInsets.all(12),
              color: isSelected ? NeoColors.primary.withValues(alpha: 0.05) : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? NeoColors.primary : NeoColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _measurements[field] ?? '00.0',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: (_measurements[field]?.isNotEmpty ?? false) ? NeoColors.textPrimary : Colors.grey.shade300,
                        ),
                      ),
                      const Text("in", style: TextStyle(color: NeoColors.textSecondary, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputControls() {
    return Container(
      decoration: BoxDecoration(
        color: NeoColors.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Fit Preference Slider
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                const Text("Fit Type:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Expanded(
                  child: NeoSlider(
                    value: _fitPreference,
                    onChanged: (val) {
                      setState(() => _fitPreference = val);
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Tight", style: TextStyle(fontSize: 10, color: _fitPreference < 0.33 ? NeoColors.primary : NeoColors.textSecondary)),
                Text("Comfort", style: TextStyle(fontSize: 10, color: (_fitPreference >= 0.33 && _fitPreference <= 0.66) ? NeoColors.primary : NeoColors.textSecondary)),
                Text("Loose", style: TextStyle(fontSize: 10, color: _fitPreference > 0.66 ? NeoColors.primary : NeoColors.textSecondary)),
              ],
            ),
          ),
          
          // Numpad & Voice Toggle
          DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.apps), text: "Numpad"),
                    Tab(icon: Icon(Icons.mic), text: "Voice"),
                  ],
                  labelColor: NeoColors.primary,
                  unselectedLabelColor: NeoColors.textSecondary,
                  indicatorColor: NeoColors.primary,
                ),
                SizedBox(
                  height: 380, // Height to accommodate numpad
                  child: NotificationListener<OverscrollIndicatorNotification>(
                    onNotification: (notification) {
                      notification.disallowIndicator();
                      return false;
                    },
                    child: TabBarView(
                      physics: const NeverScrollableScrollPhysics(), // Prevent horizontal swipe from clashing with numpad gesture if any
                    children: [
                      ScaleTransition(
                        scale: AlwaysStoppedAnimation(1.0),
                        child: SmartNumpadWidget(
                          onKeyPressed: _onKeyPress,
                          onDelete: _onDelete,
                          onClear: _onClear,
                        ),
                      ),
                      Center(
                        child: VoiceInputWidget(
                          onResult: (val) {
                            setState(() => _measurements[_selectedField] = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ],
            ),
          ),
          
          // Submit Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: NeoButton(
              height: 60,
              color: NeoColors.primary,
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context, _measurements);
              },
              child: const Text(
                "SAVED MEASUREMENT",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
