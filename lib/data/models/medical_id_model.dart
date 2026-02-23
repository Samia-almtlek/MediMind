import 'package:cloud_firestore/cloud_firestore.dart';

/// 1. The Blood Type Enum
enum BloodType {
  aPositive('A+'),
  aNegative('A-'),
  bPositive('B+'),
  bNegative('B-'),
  oPositive('O+'),
  oNegative('O-'),
  abPositive('AB+'),
  abNegative('AB-');

  final String label;
  const BloodType(this.label);

  // Helper to convert String from Firebase back to Enum
  static BloodType fromString(String label) {
    return BloodType.values.firstWhere(
      (e) => e.label == label,
      orElse: () => BloodType.oPositive,
    );
  }
}

/// 2. The Emergency Contact Sub-Class
class EmergencyContact {
  final String name;
  final String phone;
  final String email;

  EmergencyContact({
    required this.name,
    required this.phone,
    required this.email,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'email': email,
      };

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
    );
  }
}

/// 3. The Main Medical ID Model
class MedicalId {
  final String userId;
  final BloodType bloodType;
  final List<String> allergies;
  final EmergencyContact emergencyContact;

  MedicalId({
    required this.userId,
    required this.bloodType,
    required this.allergies,
    required this.emergencyContact,
  });

  // Convert Firebase Document to this Model
  factory MedicalId.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return MedicalId(
      userId: data['userId'] ?? '',
      bloodType: BloodType.fromString(data['bloodType'] ?? 'O+'),
      allergies: List<String>.from(data['allergies'] ?? []),
      emergencyContact:
          EmergencyContact.fromMap(data['emergencyContact'] ?? {}),
    );
  }

  // Convert this Model to a Map for Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'bloodType': bloodType.label,
      'allergies': allergies,
      'emergencyContact': emergencyContact.toMap(),
    };
  }
}
