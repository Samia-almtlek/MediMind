import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/scan_log_entity.dart';

class ScanLogModel extends ScanLogEntity {

  const ScanLogModel({
    required super.id,
    required super.userId,
    required super.barcode,
    required super.timestamp,
  });

  /// Convert Firestore document → Model
  factory ScanLogModel.fromFirestore(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {

    final data = doc.data();

    return ScanLogModel(
      id: doc.id,
      userId: data['gebruikerId'], // keep DB naming
      barcode: data['barcode'],
      timestamp:
          (data['timestamp'] as Timestamp).toDate(),
    );
  }

  /// Convert Entity → Model
  factory ScanLogModel.fromEntity(
      ScanLogEntity entity) {

    return ScanLogModel(
      id: entity.id,
      userId: entity.userId,
      barcode: entity.barcode,
      timestamp: entity.timestamp,
    );
  }

  /// Convert Model → Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'gebruikerId': userId,
      'barcode': barcode,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
