/* lib/core/services/database/measurement_db_extension.dart */
import '../../models/measurement_model.dart';
import '../database_service.dart';

extension MeasurementDbExtension on DatabaseService {
  Future<String> addMeasurement(Measurement measurement) async {
    final id = measurement.id.isEmpty ? uuid.v4() : measurement.id;
    final updatedMeasurement = measurement.copyWith(
      id: id,
      syncStatus: 1,
      updatedAt: DateTime.now(),
    );
    
    final map = updatedMeasurement.toMap()..['id'] = id;
    await localDb.insertMeasurement(map);
    DatabaseService.measurementSignal.add(null);
    return id;
  }

  Stream<List<Measurement>> getMeasurements() async* {
    yield await getMeasurementsList();
    yield* DatabaseService.measurementSignal.stream.asyncMap((_) => getMeasurementsList());
  }

  Future<List<Measurement>> getMeasurementsList() async {
    final maps = await localDb.getUnsyncedRecords('measurements');
    return maps.map((m) => Measurement.fromMap(m, m['id'] as String)).toList();
  }

  Stream<List<Measurement>> getMeasurementsByCustomerId(String customerId) async* {
    yield await getMeasurementsListByCustomer(customerId);
    yield* DatabaseService.measurementSignal.stream.asyncMap((_) => getMeasurementsListByCustomer(customerId));
  }

  Future<void> updateMeasurement(Measurement measurement) async {
    final updatedMeasurement = measurement.copyWith(
      syncStatus: 1,
      updatedAt: DateTime.now(),
    );
    await localDb.insertMeasurement(updatedMeasurement.toMap()..['id'] = measurement.id);
    DatabaseService.measurementSignal.add(null);
  }

  Future<void> deleteMeasurement(String id) async {
    await localDb.updateSyncStatus('measurements', id, 2);
    DatabaseService.measurementSignal.add(null);
  }

  Future<List<Measurement>> getMeasurementsListByCustomer(String customerId) async {
    final maps = await localDb.getMeasurementsByCustomer(customerId);
    return maps.map((m) => Measurement.fromMap(m, m['id'] as String)).toList();
  }
}
