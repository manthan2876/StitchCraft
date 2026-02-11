import 'package:flutter/material.dart';
import 'package:stitchcraft/core/models/measurement_model.dart';

class MeasurementDetailsScreen extends StatelessWidget {
  final Measurement measurement;

  const MeasurementDetailsScreen({super.key, required this.measurement});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Measurement Details'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.purple.shade200,
                child: const Icon(
                  Icons.straighten,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: Text(
                '${measurement.itemType[0].toUpperCase()}${measurement.itemType.substring(1)} Measurement',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 30),
            _buildDetailCard(
              icon: Icons.category,
              label: 'Item Type',
              value: measurement.itemType,
            ),
            const SizedBox(height: 12),
            _buildDetailCard(
              icon: Icons.calendar_today,
              label: 'Date',
              value: measurement.measurementDate.toLocal().toString().split(
                ' ',
              )[0],
            ),
            const SizedBox(height: 12),
            _buildDetailCard(
              icon: Icons.badge,
              label: 'Customer ID',
              value: measurement.customerId,
            ),
            if (measurement.orderId.isNotEmpty)
              Column(
                children: [
                  const SizedBox(height: 12),
                  _buildDetailCard(
                    icon: Icons.shopping_bag,
                    label: 'Order ID',
                    value: measurement.orderId,
                  ),
                ],
              ),
            const SizedBox(height: 20),
            Divider(thickness: 2),
            const SizedBox(height: 16),
            Text('Measurements', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...measurement.measurements.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${e.value.toStringAsFixed(2)} cm',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (measurement.notes.isNotEmpty) ...[
              const SizedBox(height: 20),
              Divider(thickness: 2),
              const SizedBox(height: 16),
              Text('Notes', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(measurement.notes),
                ),
              ),
            ],
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
