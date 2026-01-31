import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:developer' as developer;
import '../models/customer_model.dart';
import '../models/order_model.dart' as order_model;
import '../models/measurement_model.dart';

class DatabaseService {
  // Lazily obtain the Firestore instance for the named database to avoid
  // creating the instance at import time and to target the 'stitchcraft'
  // (non-default) database you've created in the Firebase console.
  FirebaseFirestore get _db =>
      FirebaseFirestore.instanceFor(databaseId: 'stitchcraft', app: Firebase.app());

  // ============== CUSTOMER CRUD ==============

  // CREATE
  Future<String> addCustomer(Customer customer) async {
    final docRef = await _db.collection('customers').add(customer.toMap());
    return docRef.id;
  }

  // READ - Stream for real-time UI updates
  Stream<List<Customer>> getCustomers() {
    return _db
        .collection('customers')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Customer.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // READ - Get single customer
  Future<Customer?> getCustomerById(String id) async {
    try {
      final doc = await _db.collection('customers').doc(id).get();
      if (doc.exists) {
        return Customer.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      developer.log('Error fetching customer: $e', name: 'DatabaseService');
      rethrow;
    }
  }

  // UPDATE
  Future<void> updateCustomer(Customer customer) async {
    await _db.collection('customers').doc(customer.id).update(customer.toMap());
  }

  // DELETE
  Future<void> deleteCustomer(String id) async {
    await _db.collection('customers').doc(id).delete();
  }

  // ============== ORDER CRUD ==============

  // CREATE
  Future<String> addOrder(order_model.Order order) async {
    final docRef = await _db.collection('orders').add(order.toMap());
    return docRef.id;
  }

  // READ - Stream for real-time UI updates
  Stream<List<order_model.Order>> getOrders() {
    return _db
        .collection('orders')
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => order_model.Order.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // READ - Get orders by customer ID
  Stream<List<order_model.Order>> getOrdersByCustomerId(String customerId) {
    return _db
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => order_model.Order.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // READ - Get single order
  Future<order_model.Order?> getOrderById(String id) async {
    try {
      final doc = await _db.collection('orders').doc(id).get();
      if (doc.exists) {
        return order_model.Order.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      developer.log('Error fetching order: $e', name: 'DatabaseService');
      rethrow;
    }
  }

  // UPDATE
  Future<void> updateOrder(order_model.Order order) async {
    await _db.collection('orders').doc(order.id).update(order.toMap());
  }

  // DELETE
  Future<void> deleteOrder(String id) async {
    await _db.collection('orders').doc(id).delete();
  }

  // UPDATE - Change order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _db.collection('orders').doc(orderId).update({'status': status});
  }

  // ============== MEASUREMENT CRUD ==============

  // CREATE
  Future<String> addMeasurement(Measurement measurement) async {
    final docRef = await _db
        .collection('measurements')
        .add(measurement.toMap());
    return docRef.id;
  }

  // READ - Stream for real-time UI updates
  Stream<List<Measurement>> getMeasurements() {
    return _db
        .collection('measurements')
        .orderBy('measurementDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Measurement.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // READ - Get measurements by customer ID
  Stream<List<Measurement>> getMeasurementsByCustomerId(String customerId) {
    return _db
        .collection('measurements')
        .where('customerId', isEqualTo: customerId)
        .orderBy('measurementDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Measurement.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // READ - Get measurements by order ID
  Stream<List<Measurement>> getMeasurementsByOrderId(String orderId) {
    return _db
        .collection('measurements')
        .where('orderId', isEqualTo: orderId)
        .orderBy('measurementDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Measurement.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // READ - Get single measurement
  Future<Measurement?> getMeasurementById(String id) async {
    try {
      final doc = await _db.collection('measurements').doc(id).get();
      if (doc.exists) {
        return Measurement.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      developer.log('Error fetching measurement: $e', name: 'DatabaseService');
      rethrow;
    }
  }

  // UPDATE
  Future<void> updateMeasurement(Measurement measurement) async {
    await _db
        .collection('measurements')
        .doc(measurement.id)
        .update(measurement.toMap());
  }

  // DELETE
  Future<void> deleteMeasurement(String id) async {
    await _db.collection('measurements').doc(id).delete();
  }

  // ============== BULK OPERATIONS ==============

  // Delete all orders for a customer
  Future<void> deleteCustomerOrders(String customerId) async {
    try {
      final querySnapshot = await _db
          .collection('orders')
          .where('customerId', isEqualTo: customerId)
          .get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      developer.log(
        'Error deleting customer orders: $e',
        name: 'DatabaseService',
      );
      rethrow;
    }
  }

  // Delete all measurements for a customer
  Future<void> deleteCustomerMeasurements(String customerId) async {
    try {
      final querySnapshot = await _db
          .collection('measurements')
          .where('customerId', isEqualTo: customerId)
          .get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      developer.log(
        'Error deleting customer measurements: $e',
        name: 'DatabaseService',
      );
      rethrow;
    }
  }

  // Delete all related data when deleting a customer
  Future<void> deleteCustomerAndRelatedData(String customerId) async {
    try {
      await deleteCustomerOrders(customerId);
      await deleteCustomerMeasurements(customerId);
      await deleteCustomer(customerId);
    } catch (e) {
      developer.log(
        'Error deleting customer and related data: $e',
        name: 'DatabaseService',
      );
      rethrow;
    }
  }
}
