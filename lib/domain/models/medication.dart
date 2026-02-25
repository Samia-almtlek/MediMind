import 'package:cloud_firestore/cloud_firestore.dart';

class Medication {
  final String id;
  final String userId;
  final String name;
  final String dosage;
  final String time;
  final String frequency; // e.g., "2x per day"
  final DateTime endDate;
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
    List<DateTime>? completedDates,
  }) : this.completedDates = completedDates ?? [];

  factory Medication.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Extracting the first time from the 'instructions' string (e.g., "8:00 AM")
    String rawInstructions = data['instructions'] ?? '';
    String extractedTime = "Not set";

    if (rawInstructions.contains("Times: ")) {
      // This splits "Times: 8:00 AM, 4:00 PM" and takes "8:00 AM"
      extractedTime = rawInstructions.replaceFirst("Times: ", "").split(",")[0];
    }

    return Medication(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? 'Unknown',
      dosage: data['dosage'] ?? '',
      // Use the extracted time here:
      time: extractedTime,
      // Use 'frequencyPerDay' from your logs:
      frequency: "${data['frequencyPerDay']}x per day",
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      completedDates: [], // Initialize empty or fetch from separate field
      instructions: data['instructions'] ?? '',
    );
  }

  /// ==========================
  /// TO FIRESTORE
  /// ==========================
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'dosage': dosage,
      'time': time,
      'endDate': Timestamp.fromDate(endDate),
      // Store the list as Timestamps
      'completedDates':
          completedDates.map((d) => Timestamp.fromDate(d)).toList(),
    };
  }

  Stream<List<Medication>> getUserMedications(String userId) {
    return FirebaseFirestore.instance
        .collection('user_medications')
        .where('userId', isEqualTo: userId) // Only get meds for THIS user
        .snapshots() // This makes it a "Live" stream
        .map((snapshot) =>
            snapshot.docs.map((doc) => Medication.fromFirestore(doc)).toList());
  }
}
