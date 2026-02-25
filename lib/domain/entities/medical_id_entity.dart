import 'package:equatable/equatable.dart';
import 'caregiver_entity.dart';

class MedicalIdEntity extends Equatable {
  final String? id;
  final String userId;
  final String bloodType;
  final List<String> allergies;

  // This links the sub-collection data at the Domain level
  final List<CaregiverEntity> caregivers;

  const MedicalIdEntity({
    this.id,
    required this.userId,
    required this.bloodType,
    required this.allergies,
    this.caregivers = const [],
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        bloodType,
        allergies,
        caregivers,
      ];

  /// Helper method to create a copy of the entity with updated fields
  MedicalIdEntity copyWith({
    String? id,
    String? userId,
    String? bloodType,
    List<String>? allergies,
    List<CaregiverEntity>? caregivers,
  }) {
    return MedicalIdEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      caregivers: caregivers ?? this.caregivers,
    );
  }
}
