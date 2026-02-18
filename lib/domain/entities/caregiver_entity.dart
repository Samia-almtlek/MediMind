class CaregiverEntity {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String relation;
  final bool isActive;
  final DateTime? addedAt;

  const CaregiverEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.relation,
    required this.isActive,
    this.addedAt,
  });
}
