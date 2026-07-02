/* lib/core/services/database/others_db_extension.dart */
import 'dart:async';
import '../../models/repair_job_model.dart' as repair_job_model;
import '../../models/lining_item_model.dart' as lining_item_model;
import '../../models/gallery_item_model.dart' as gallery_item_model;
import '../database_service.dart';

extension OthersDbExtension on DatabaseService {
  // ============== EXPENSE CRUD ==============
  Future<void> addExpense(String category, double amount, String description, DateTime date) async {
    final id = uuid.v4();
    final map = {
      'id': id,
      'category': category,
      'amount': amount,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'sync_status': 1,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
    await localDb.insertExpense(map);
    DatabaseService.expenseSignal.add(null);
  }

  Stream<List<Map<String, dynamic>>> getExpenses() async* {
    yield await getExpensesList();
    yield* DatabaseService.expenseSignal.stream.asyncMap((_) => getExpensesList());
  }

  Future<List<Map<String, dynamic>>> getExpensesList() async {
    return await localDb.getAllExpenses();
  }

  Future<void> deleteExpense(String id) async {
    await localDb.deleteExpense(id);
    DatabaseService.expenseSignal.add(null);
  }

  // ============== PROFITABILITY ANALYTICS ==============
  Future<Map<String, double>> getFinancialSummary() async {
    final orders = await getOrdersList();
    final expenses = await getExpensesList();

    double totalRevenue = 0;
    double totalCOGS = 0; // Labor + Material
    double totalOverhead = 0; // Assigned overheads
    double totalExpenses = 0; // OPEX from expense table

    for (var o in orders) {
       if (o.status != 'Cancelled') {
         totalRevenue += o.totalAmount;
         totalCOGS += (o.laborCost + o.materialCost);
         totalOverhead += o.overheadCost;
       }
    }

    for (var e in expenses) {
      totalExpenses += (e['amount'] as num).toDouble();
    }

    return {
      'revenue': totalRevenue,
      'cogs': totalCOGS,
      'gross_profit': totalRevenue - totalCOGS,
      'expenses': totalExpenses,
      'net_profit': totalRevenue - totalCOGS - totalExpenses - totalOverhead
    };
  }

  // ============== REPAIR JOBS CRUD ==============
  Future<void> addRepairJob(repair_job_model.RepairJob job) async {
    final id = job.id.isEmpty ? uuid.v4() : job.id;
    final updatedJob = job.copyWith(
      id: id,
      syncStatus: 1,
      updatedAt: DateTime.now(),
    );

    await localDb.insertRepairJob(updatedJob.toMap());
    DatabaseService.repairJobSignal.add(null);
  }

  Future<void> updateRepairJob(repair_job_model.RepairJob job) async {
    final updatedJob = job.copyWith(
      syncStatus: 1,
      updatedAt: DateTime.now(),
    );

    await localDb.insertRepairJob(updatedJob.toMap());
    DatabaseService.repairJobSignal.add(null);
  }

  Future<List<repair_job_model.RepairJob>> getRepairJobsList() async {
    final maps = await localDb.getAllRepairJobs();
    return maps.map((m) {
      final data = Map<String, dynamic>.from(m);
      data['id'] = m['id'];
      return repair_job_model.RepairJob.fromMap(data, m['id'] as String);
    }).toList();
  }

  Stream<List<repair_job_model.RepairJob>> getRepairJobsStream() {
    return DatabaseService.repairJobSignal.stream.asyncMap((_) => getRepairJobsList());
  }

  Future<void> deleteRepairJob(String id) async {
    await localDb.deleteRepairJob(id);
    DatabaseService.repairJobSignal.add(null);
  }

  // ============== LINING ITEMS CRUD ==============
  Future<void> addLiningItem(lining_item_model.LiningItem item) async {
    final id = item.id.isEmpty ? uuid.v4() : item.id;
    final updatedItem = item.copyWith(
      id: id,
      syncStatus: 1,
      updatedAt: DateTime.now(),
    );

    await localDb.insertLiningItem(updatedItem.toMap());
  }

  Future<List<lining_item_model.LiningItem>> getLiningItemsByOrder(String orderId) async {
    final maps = await localDb.getLiningItemsByOrder(orderId);
    return maps.map((m) {
      final data = Map<String, dynamic>.from(m);
      data['id'] = m['id'];
      return lining_item_model.LiningItem.fromMap(data, m['id'] as String);
    }).toList();
  }

  Future<void> deleteLiningItem(String id) async {
    await localDb.deleteLiningItem(id);
  }

  // ============== GALLERY ITEMS CRUD ==============
  Future<void> addGalleryItem(gallery_item_model.GalleryItem item) async {
    final id = item.id.isEmpty ? uuid.v4() : item.id;
    final updatedItem = item.copyWith(
      id: id,
      syncStatus: 1,
      updatedAt: DateTime.now(),
    );

    await localDb.insertGalleryItem(updatedItem.toMap());
    DatabaseService.gallerySignal.add(null);
  }

  Future<List<gallery_item_model.GalleryItem>> getGalleryItems() async {
    final maps = await localDb.getAllGalleryItems();
    return maps.map((m) {
      final data = Map<String, dynamic>.from(m);
      data['id'] = m['id'];
      return gallery_item_model.GalleryItem.fromMap(data, m['id'] as String);
    }).toList();
  }

  Stream<List<gallery_item_model.GalleryItem>> getGalleryItemsStream() {
    return DatabaseService.gallerySignal.stream.asyncMap((_) => getGalleryItems());
  }

  Future<void> deleteGalleryItem(String id) async {
    await localDb.deleteGalleryItem(id);
    DatabaseService.gallerySignal.add(null);
  }

  // ============== SYNC HELPERS ==============
  Future<List<Map<String, dynamic>>> getUnsyncedRecords(String table) async {
    return await localDb.getUnsyncedRecords(table);
  }

  Future<void> updateSyncStatus(String table, String id, int status) async {
    await localDb.updateSyncStatus(table, id, status);
  }
}
