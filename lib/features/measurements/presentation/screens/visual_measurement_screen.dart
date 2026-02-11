import 'package:flutter/material.dart';
import 'package:stitchcraft/core/models/customer_model.dart';
import 'package:stitchcraft/core/models/measurement_model.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';

class VisualMeasurementListScreen extends StatefulWidget {
  const VisualMeasurementListScreen({super.key});

  @override
  State<VisualMeasurementListScreen> createState() => _VisualMeasurementListScreenState();
}

class _VisualMeasurementListScreenState extends State<VisualMeasurementListScreen> {
  final Map<String, double> _measurements = {};
  final Map<String, String> _fitPreferences = {};
  
  // Normalized Coordinates (0.0 to 1.0)
  // These are relative to the Image/Container dimensions.
  
  // MEN (T-Pose White Mannequin)
  // Assumed Aspect Ratio: Roughly Square or Portrait. 
  // We'll constrain the container to a specific aspect ratio or fit.
  final Map<String, List<Map<String, dynamic>>> _bodyParts = {
    'Men': [
      // Men (T-Pose)
      // Neck: High center.
      {'label': 'Neck', 'x': 0.5, 'y': 0.09},
      // Shoulder: Lateral point of shoulder/arm joint.
      {'label': 'Shoulder', 'x': 0.32, 'y': 0.16}, 
      // Chest: Center, below neck.
      {'label': 'Chest', 'x': 0.5, 'y': 0.22},
      // Waist: Navel area.
      {'label': 'Waist', 'x': 0.5, 'y': 0.40}, 
      // Hips: Widest part below waist.
      {'label': 'Hips', 'x': 0.5, 'y': 0.48},
      // Sleeve: Wrist/End of arm in T-pose.
      {'label': 'Sleeve', 'x': 0.88, 'y': 0.18}, 
      // Inseam: Inner thigh/crotch area.
      {'label': 'Inseam', 'x': 0.45, 'y': 0.55}, 
      // Length: Near feet/floor.
      {'label': 'Length', 'x': 0.60, 'y': 0.88},
    ],
    'Women': [
      // Women (Standing Straight)
      {'label': 'Neck', 'x': 0.5, 'y': 0.10},
      {'label': 'Shoulder', 'x': 0.35, 'y': 0.17},
      {'label': 'Bust', 'x': 0.5, 'y': 0.25},
      {'label': 'Waist', 'x': 0.5, 'y': 0.38},
      {'label': 'Hips', 'x': 0.5, 'y': 0.48},
      {'label': 'Sleeve', 'x': 0.72, 'y': 0.35},
      {'label': 'Length', 'x': 0.65, 'y': 0.88},
    ],
  };

  Future<void> _openMeasurementForm(String partName, Customer? customer) async {
     if (customer == null) return;
     
     final result = await Navigator.pushNamed(context, '/measurement_form', arguments: {
         'customerId': customer.id,
         'partName': partName,
     });

     if (result != null && result is Map) {
        setState(() {
           _measurements[partName] = result['value'];
           _fitPreferences[partName] = result['fit'];
        });
     }
  }

  Future<void> _saveAllMeasurements(Customer? customer, String category) async {
    if (customer == null) return;
    if (_measurements.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No measurements entered')));
        return;
    }

    try {
        final newMeasurement = Measurement(
            id: '',
            customerId: customer.id,
            orderId: '', 
            itemType: category, 
            measurements: Map.from(_measurements),
            measurementDate: DateTime.now(),
            updatedAt: DateTime.now(),
            notes: 'Created via Visual Tool. Fits: $_fitPreferences'
        );
        
        await DatabaseService().addMeasurement(newMeasurement);
        
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All Measurements Saved!')));
            Navigator.popUntil(context, ModalRoute.withName('/client_profile'));
        }
    } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final customer = args?['customer'] as Customer?;
    final category = args?['category'] as String? ?? 'Men'; 
    final isMen = category == 'Men';
    final parts = _bodyParts[category] ?? _bodyParts['Men']!; 
    final imageAsset = isMen ? 'assets/images/men_template.png' : 'assets/images/women_template.png';

    // Aspect Ratios: Men -> Wider (T-Pose), Women -> Narrower (Standing)
    final containerAspectRatio = isMen ? 0.9 : 0.5; 

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('$category Template'),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
             const SizedBox(height: 16),
             
             // Dynamic AspectRatio Container
             Center(
               child: AspectRatio(
                 aspectRatio: containerAspectRatio,
                 child: LayoutBuilder(
                   builder: (context, constraints) {
                     return Stack(
                       children: [
                         // Background Image (Cover/Contain to match Box)
                         Positioned.fill(
                           child: Image.asset(
                             imageAsset,
                             fit: BoxFit.contain,
                           ),
                         ),
                         
                         // Labels
                         ...parts.map((part) {
                           double x = part['x'];
                           double y = part['y'];
                           
                           // Map 0..1 to Width..Height
                           // Since we use BoxFit.contain, the image might have letterboxing if aspectRatio is slightly off.
                           // But if we tune aspectRatio close to image, it fills.
                           // Assuming aspect ratio provided (0.8 / 0.5) roughly matches.
                           
                           return Positioned(
                             top: constraints.maxHeight * y,
                             left: constraints.maxWidth * x - 25, // Adjusted centering offset
                             child: _TechnicalLabel(
                               label: part['label'],
                               value: _measurements[part['label']],
                               onTap: () => _openMeasurementForm(part['label'], customer),
                             ),
                           );
                         }),
                       ],
                     );
                   }
                 ),
               ),
             ),
             
             const SizedBox(height: 24),
             const Text('Tap points on the model', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      ),
      
      // Bottom Bar for Save Button - Guaranteed no overlap
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _saveAllMeasurements(customer, category),
              icon: const Icon(Icons.check),
              label: const Text('Save All Measurements'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor, // Use Theme Primary Color
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                elevation: 4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TechnicalLabel extends StatelessWidget {
  final String label;
  final double? value;
  final VoidCallback onTap;

  const _TechnicalLabel({required this.label, this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dot
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: hasValue ? Colors.green : Colors.black,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))
              ]
            ),
          ),
          
          Container(
            height: 20, 
            width: 1, 
            color: (hasValue ? Colors.green : Colors.black).withValues(alpha: 0.3)
          ),

          // Label Capsule
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: hasValue ? Colors.green : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: hasValue ? Colors.green : Colors.grey.shade300),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
              ]
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.w600,
                    color: hasValue ? Colors.white : Colors.black87
                  ),
                ),
                if (hasValue) ...[
                  const SizedBox(width: 6),
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4)
                      ),
                      child: Text(
                        '${value.toString()}"', 
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)
                      )
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
