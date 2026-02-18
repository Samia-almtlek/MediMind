class ScanLogEntity {
  final String id;
  final String userId;
  final String barcode;
  final DateTime timestamp;

  const ScanLogEntity({
    required this.id,
    required this.userId,
    required this.barcode,
    required this.timestamp,
  });
}
