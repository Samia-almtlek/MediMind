import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/support_ticket_entity.dart';

class SupportTicketModel extends SupportTicketEntity {
  const SupportTicketModel({
    super.id,
    required super.userId,
    required super.userEmail,
    required super.question,
    required super.createdAt,
    super.status,
  });

  // Convert Entity/Model to Firestore Map
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'question': question,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.name, // Saves as "open", "inProgress", etc.
    };
  }

  // Create Model from Firestore Document
  factory SupportTicketModel.fromSnapshot(DocumentSnapshot snap) {
    var data = snap.data() as Map<String, dynamic>;
    return SupportTicketModel(
      id: snap.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      question: data['question'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: TicketStatus.values.byName(data['status'] ?? 'open'),
    );
  }
}
