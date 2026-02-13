import '../entities/user_entity.dart';

abstract class UserRepository {
  Future<UserEntity?> getUserById(String userId);
  Future<void> createUser(UserEntity user);
  Future<void> updateUser(UserEntity user);
}
