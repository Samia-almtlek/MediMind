import 'package:cloud_firestore/cloud_firestore.dart';

class Medication {
  final String id; // Added ID to track specific docs
  final String name;
  final String dosage;
  final String time;
  final String frequency;
  final DateTime endDate;
  final DateTime startDate;
  final List<DateTime> completedDates;
  final String instructions; // New field for instructions

  Medication({
    this.id = '',
    required this.name,
    required this.frequency,
    required this.dosage,
    required this.time,
    required this.endDate,
    required this.startDate,
    required this.instructions,
    List<DateTime>? completedDates,
  }) : completedDates = completedDates ?? [];

  /// ==========================
  /// FROM FIRESTORE
  /// ==========================
  factory Medication.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    final rawCompletedDates = (data['completedDates'] as List?) ?? [];
    final completedDates = rawCompletedDates
        .map<DateTime?>((value) {
          if (value is Timestamp) {
            return value.toDate();
          }
          if (value is DateTime) {
            return value;
          }
          return null;
        })
        .whereType<DateTime>()
        .toList();

    final frequencyPerDay = data['frequencyPerDay'];
    final int frequencyValue = frequencyPerDay is int
        ? frequencyPerDay
        : int.tryParse('$frequencyPerDay') ?? 1;

    // Extracting the first time from the 'instructions' string (e.g., "8:00 AM")
    String rawInstructions = data['instructions'] ?? '';
    String extractedTime = "Not set";

    if (rawInstructions.contains("Times: ")) {
      // This splits "Times: 8:00 AM, 4:00 PM" and takes "8:00 AM"
      extractedTime = rawInstructions.replaceFirst("Times: ", "").split(",")[0];
    }

    return Medication(
      id: doc.id,
      name: data['name'] ?? 'Unknown',
      dosage: data['dosage'] ?? '',
      // Use the extracted time here:
      time: extractedTime,
      // Use 'frequencyPerDay' from your logs:
      frequency: "${frequencyValue}x per day",
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      completedDates: completedDates,
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
