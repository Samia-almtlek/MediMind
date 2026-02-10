class Medication {
  final String name;
  final String dosage;
  final String time;
  bool isTaken;
  final DateTime endDate; // For future use in tracking treatment duration

  Medication({
    required this.name,
    required this.dosage,
    required this.time,
    this.isTaken = false,
    required this.endDate,
  });
}  
