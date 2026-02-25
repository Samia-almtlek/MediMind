enum TicketStatus { open, inProgress, resolved }

class SupportTicketEntity {
  final String? id;
  final String userId;
  final String userEmail;
  final String question;
  final DateTime createdAt;
  final TicketStatus status;

  const SupportTicketEntity({
    this.id,
    required this.userId,
    required this.userEmail,
    required this.question,
    required this.createdAt,
    this.status = TicketStatus.open,
  });
}