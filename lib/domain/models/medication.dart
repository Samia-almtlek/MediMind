import 'package:cloud_firestore/cloud_firestore.dart';

class Medication {
  final String id;
  final String userId;
  final String name;
  final String dosage;
  final String time;
  final String frequency;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> completedDoseIds; // Tracks "yyyy-MM-dd_HH:mm"
  final String instructions;

  Medication({
    this.id = '',
    this.userId = '',
    required this.name,
    required this.dosage,
    required this.time,
    required this.frequency,
    required this.startDate,
    required this.endDate,
    required this.instructions,
    List<String>? completedDoseIds,
  }) : completedDoseIds = completedDoseIds ?? [];

  factory Medication.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Medication(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? 'Unknown',
      dosage: data['dosage'] ?? '',
      time: data['time'] ?? '',
      frequency: data['frequency'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      instructions: data['instructions'] ?? '',
      completedDoseIds: List<String>.from(data['completedDoseIds'] ?? []),
    );
  }
}
