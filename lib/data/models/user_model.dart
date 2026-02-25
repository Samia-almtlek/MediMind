import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    super.profilePhotoUrl,
    super.createdAt,
    super.lastLogin,
    required super.notificationsEnabled,
  });

  /// 🔄 Firestore → Model
  factory UserModel.fromFirestore(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      profilePhotoUrl: data['profilePhotoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      notificationsEnabled: data['notificationsEnabled'] ?? false,
    );
  }

  /// 🔄 Entity → Model
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      profilePhotoUrl: entity.profilePhotoUrl,
      createdAt: entity.createdAt,
      lastLogin: entity.lastLogin,
      notificationsEnabled: entity.notificationsEnabled,
    );
  }

  /// 🔄 Model → Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'profilePhotoUrl': profilePhotoUrl,
      'createdAt':
          createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'lastLogin':
          lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'notificationsEnabled': notificationsEnabled,
    };
  }
}
