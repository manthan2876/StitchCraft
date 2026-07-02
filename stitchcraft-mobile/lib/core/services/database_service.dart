import 'dart:async';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:uuid/uuid.dart';

export 'database/user_db_extension.dart';
export 'database/customer_db_extension.dart';
export 'database/order_db_extension.dart';
export 'database/measurement_db_extension.dart';
export 'database/others_db_extension.dart';

class DatabaseService {
  final _localDb = LocalDatabaseService();
  final _uuid = Uuid();

  LocalDatabaseService get localDb => _localDb;
  Uuid get uuid => _uuid;

  // Signal Controllers for reactive UI (broadcasters)
  static final customerSignal = StreamController<void>.broadcast();
  static final orderSignal = StreamController<void>.broadcast();
  static final measurementSignal = StreamController<void>.broadcast();
  static final userSignal = StreamController<void>.broadcast();
  static final expenseSignal = StreamController<void>.broadcast();
  static final repairJobSignal = StreamController<void>.broadcast();
  static final gallerySignal = StreamController<void>.broadcast();
}
