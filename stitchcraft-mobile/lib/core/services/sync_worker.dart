import 'package:workmanager/workmanager.dart';
import 'package:stitchcraft/core/services/sync_service.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'dart:developer' as developer;

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await SyncService().syncAll();
      return true;
    } catch (error, stackTrace) {
      developer.log(
        'Background sync failed',
        name: 'SyncWorker',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  });
}

class SyncWorker {
  static const String syncTaskName = "com.stitchcraft.sync_task";

  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);
  }

  static Future<bool> schedulePeriodicSync() async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      developer.log(
        'Background sync not scheduled: no authenticated session',
        name: 'SyncWorker',
      );
      return false;
    }

    await Workmanager().registerPeriodicTask(
      "1",
      syncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
    return true;
  }
}
