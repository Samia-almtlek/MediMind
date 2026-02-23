import '../../data/models/medical_id_model.dart';

class EmergencyContactEntity {
  final String name;
  final String phone;
  final String email;

  EmergencyContactEntity({
    required this.name,
    required this.phone,
    required this.email,
  });
}

class MedicalIdEntity {
  final String userId;
  final BloodType bloodType;
  final List<String> allergies;
  final EmergencyContactEntity emergencyContact;

  MedicalIdEntity({
    required this.userId,
    required this.bloodType,
    required this.allergies,
    required this.emergencyContact,
  });
}
