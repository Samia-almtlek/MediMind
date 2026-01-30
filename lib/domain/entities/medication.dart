class Medication {
  final String id;
  final String name;
  final String dosage;
  final String time; //  "08:00"
  final bool taken;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.time,
    this.taken = false,
  });
}
