class Medication {
  final String name;
  final String dosage;
  final String time;
  bool isTaken;

  Medication({
    required this.name,
    required this.dosage,
    required this.time,
    this.isTaken = false,
  });
}  
