import 'package:cloud_firestore/cloud_firestore.dart';
import '../../service/database/firestore_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final FirestoreService _firestoreService;

  UserRepositoryImpl(this._firestoreService);

  @override
  Future<UserEntity?> getUserById(String userId) async {
    final doc = await _firestoreService.users
        .doc(userId)
        .get();

    if (!doc.exists) return null;

    return UserModel.fromFirestore(
        doc as QueryDocumentSnapshot<Map<String, dynamic>>);
  }

  @override
  Future<void> createUser(UserEntity user) async {
    final model = UserModel.fromEntity(user);

    await _firestoreService.users
        .doc(user.id)
        .set(model.toFirestore());
  }

  @override
  Future<void> updateUser(UserEntity user) async {
    final model = UserModel.fromEntity(user);

    await _firestoreService.users
        .doc(user.id)
        .update(model.toFirestore());
  }
}
