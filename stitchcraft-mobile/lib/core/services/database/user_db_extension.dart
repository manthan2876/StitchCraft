/* lib/core/services/database/user_db_extension.dart */
import '../../models/user_model.dart';
import '../database_service.dart';

extension UserDbExtension on DatabaseService {
  Future<void> addUser(User user) async {
    await localDb.insertUser(user.toMap());
    DatabaseService.userSignal.add(null);
  }

  Future<User?> getUser(String id) async {
    final map = await localDb.getUser(id);
    return map != null ? User.fromMap(map) : null;
  }
  
  Future<User?> getUserByPhone(String phone) async {
    final map = await localDb.getUserByPhone(phone);
    return map != null ? User.fromMap(map) : null;
  }

  Future<void> updateUser(User user) async {
    final updatedUser = user.copyWith(
      syncStatus: 1,
      updatedAt: DateTime.now(),
    );
    await localDb.insertUser(updatedUser.toMap());
    DatabaseService.userSignal.add(null);
  }
}
