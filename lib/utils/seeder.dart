import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../models/customer_model.dart';
import '../models/order_model.dart' as order_model;
import '../models/measurement_model.dart';

/// Firebase Seeder - Utility to populate Firestore with sample data
class FirebaseSeeder {
  // Avoid holding a Firestore instance at import time. Use
  // `FirebaseFirestore.instance` inside methods to ensure Firebase
  // is initialized first (prevents platform-threading issues on Windows).

  /// Add sample customers to Firestore
  static Future<void> seedCustomers() async {
    try {
      final customers = [
        Customer(
          id: '',
          name: 'Raj Kumar',
          phone: '9876543210',
          email: 'raj@example.com',
        ),
        Customer(
          id: '',
          name: 'Priya Singh',
          phone: '9765432109',
          email: 'priya@example.com',
        ),
        Customer(
          id: '',
          name: 'Ahmed Hassan',
          phone: '9654321098',
          email: 'ahmed@example.com',
        ),
        Customer(
          id: '',
          name: 'Sarah Wilson',
          phone: '9543210987',
          email: 'sarah@example.com',
        ),
        Customer(
          id: '',
          name: 'Michael Brown',
          phone: '9432109876',
          email: 'michael@example.com',
        ),
      ];

      for (var customer in customers) {
        await FirebaseFirestore.instance
            .collection('customers')
            .add(customer.toMap());
      }
      developer.log(
        '✅ Seeded ${customers.length} customers',
        name: 'FirebaseSeeder',
      );
    } catch (e) {
      developer.log('❌ Error seeding customers: $e', name: 'FirebaseSeeder');
      rethrow;
    }
  }

  /// Add sample orders
  static Future<void> seedOrders() async {
    try {
      final customersSnapshot = await FirebaseFirestore.instance
          .collection('customers')
          .limit(3)
          .get();

      final orderDescriptions = [
        'Custom tailored shirt',
        'Designer pants tailoring',
        'Evening dress alterations',
        'Jacket fitting adjustments',
        'Formal suit customization',
      ];

      int orderIndex = 0;
      for (var customerDoc in customersSnapshot.docs) {
        final customer = Customer.fromSnapshot(customerDoc);

        final order = order_model.Order(
          id: '',
          customerId: customer.id,
          customerName: customer.name,
          orderDate: DateTime.now(),
          dueDate: DateTime.now().add(Duration(days: 14 + (orderIndex * 2))),
          status: orderIndex % 3 == 0
              ? 'pending'
              : orderIndex % 3 == 1
              ? 'in_progress'
              : 'completed',
          totalAmount: 500.0 + (orderIndex * 100),
          description: orderDescriptions[orderIndex % orderDescriptions.length],
          itemTypes: ['shirt', 'pants', 'dress'][(orderIndex) % 3].split(','),
          measurements: {},
        );

        await FirebaseFirestore.instance
            .collection('orders')
            .add(order.toMap());
        orderIndex++;
      }
      developer.log(
        '✅ Seeded ${customersSnapshot.docs.length} orders',
        name: 'FirebaseSeeder',
      );
    } catch (e) {
      developer.log('❌ Error seeding orders: $e', name: 'FirebaseSeeder');
      rethrow;
    }
  }

  /// Add sample measurements
  static Future<void> seedMeasurements() async {
    try {
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .limit(3)
          .get();

      final measurementSets = {
        'shirt': {
          'Chest': 90.0,
          'Shoulder': 40.0,
          'Sleeve Length': 65.0,
          'Waist': 85.0,
          'Length': 70.0,
          'Armhole': 20.0,
        },
        'pants': {
          'Waist': 85.0,
          'Inseam': 78.0,
          'Outseam': 100.0,
          'Thigh': 52.0,
          'Knee': 38.0,
          'Leg Opening': 16.0,
        },
        'dress': {
          'Bust': 90.0,
          'Waist': 75.0,
          'Hip': 95.0,
          'Shoulder': 38.0,
          'Length': 90.0,
          'Armhole': 19.0,
        },
      };

      int measurementIndex = 0;
      for (var orderDoc in ordersSnapshot.docs) {
        final orderData = orderDoc.data();
        final itemTypes = List<String>.from(
          orderData['itemTypes'] ?? ['shirt'],
        );
        final itemType = itemTypes.isNotEmpty ? itemTypes[0] : 'shirt';

        final measurement = Measurement(
          id: '',
          customerId: orderData['customerId'],
          orderId: orderDoc.id,
          itemType: itemType,
          measurements: measurementSets[itemType] ?? measurementSets['shirt']!,
          measurementDate: DateTime.now(),
          notes:
              'Sample measurement ${measurementIndex + 1} - Standard fitting',
        );

        await FirebaseFirestore.instance
            .collection('measurements')
            .add(measurement.toMap());
        measurementIndex++;
      }
      developer.log(
        '✅ Seeded ${ordersSnapshot.docs.length} measurements',
        name: 'FirebaseSeeder',
      );
    } catch (e) {
      developer.log('❌ Error seeding measurements: $e', name: 'FirebaseSeeder');
      rethrow;
    }
  }

  /// Seed all data at once
  static Future<void> seedAll() async {
    try {
      developer.log('🌱 Starting database seed...', name: 'FirebaseSeeder');

      await seedCustomers();
      await Future.delayed(Duration(seconds: 1));

      await seedOrders();
      await Future.delayed(Duration(seconds: 1));

      await seedMeasurements();

      developer.log(
        '✅ Database seeding completed successfully!',
        name: 'FirebaseSeeder',
      );
    } catch (e) {
      developer.log('❌ Seeding failed: $e', name: 'FirebaseSeeder');
      rethrow;
    }
  }

  /// Check if database already has data
  static Future<bool> hasData() async {
    try {
      final customersCount = await FirebaseFirestore.instance
          .collection('customers')
          .count()
          .get();
      return (customersCount.count ?? 0) > 0;
    } catch (e) {
      developer.log('Error checking database: $e', name: 'FirebaseSeeder');
      return false;
    }
  }

  /// Clear all collections (use with caution!)
  static Future<void> clearAllData() async {
    try {
      developer.log(
        '⚠️ Clearing all Firestore data...',
        name: 'FirebaseSeeder',
      );

      // Delete customers
      final customersSnapshot = await FirebaseFirestore.instance
          .collection('customers')
          .get();
      for (var doc in customersSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete orders
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .get();
      for (var doc in ordersSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete measurements
      final measurementsSnapshot = await FirebaseFirestore.instance
          .collection('measurements')
          .get();
      for (var doc in measurementsSnapshot.docs) {
        await doc.reference.delete();
      }

      developer.log('✅ All data cleared', name: 'FirebaseSeeder');
    } catch (e) {
      developer.log('❌ Error clearing data: $e', name: 'FirebaseSeeder');
      rethrow;
    }
  }
}
