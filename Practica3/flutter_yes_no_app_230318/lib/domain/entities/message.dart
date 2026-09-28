enum FromWho { me, hers }

class Message {
  final String text;
  final FromWho fromWho;
  final String? imageUrl;
  final DateTime sentAt;

  Message({
    required this.text,
    required this.fromWho,
    this.imageUrl,
    DateTime? sentAt,
  }) : sentAt = sentAt ?? DateTime.now();
}
