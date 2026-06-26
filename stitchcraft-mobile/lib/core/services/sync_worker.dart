import 'package:workmanager/workmanager.dart';
import 'package:stitchcraft/core/services/sync_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:stitchcraft/firebase_options.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    await SyncService().syncAll();
    return Future.value(true);
  });
}

class SyncWorker {
  static const String syncTaskName = "com.stitchcraft.sync_task";

  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
    );
  }

  static Future<void> schedulePeriodicSync() async {
    await Workmanager().registerPeriodicTask(
      "1",
      syncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
