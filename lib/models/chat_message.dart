enum MessageStatus { sending, sent, delivered, read, failed }

class ChatMessage {
  final String id;
  final String fromId;
  final String toId;
  final String text;
  final DateTime sentAt;
  final MessageStatus status;
  final String? rtmMsgId;
  final bool isMe;
  final String time;

  ChatMessage({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.text,
    required this.sentAt,
    required this.status,
    this.rtmMsgId,
    required this.isMe,
    required this.time,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      fromId: json['fromId'] ?? '',
      toId: json['toId'] ?? '',
      text: json['text'] ?? '',
      sentAt: DateTime.parse(json['sentAt'] ?? DateTime.now().toIso8601String()),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == 'MessageStatus.${json['status']}',
        orElse: () => MessageStatus.sent,
      ),
      rtmMsgId: json['rtmMsgId'],
      isMe: json['isMe'] ?? false,
      time: json['time'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromId': fromId,
      'toId': toId,
      'text': text,
      'sentAt': sentAt.toIso8601String(),
      'status': status.toString().split('.').last,
      'rtmMsgId': rtmMsgId,
      'isMe': isMe,
      'time': time,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? fromId,
    String? toId,
    String? text,
    DateTime? sentAt,
    MessageStatus? status,
    String? rtmMsgId,
    bool? isMe,
    String? time,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      fromId: fromId ?? this.fromId,
      toId: toId ?? this.toId,
      text: text ?? this.text,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
      rtmMsgId: rtmMsgId ?? this.rtmMsgId,
      isMe: isMe ?? this.isMe,
      time: time ?? this.time,
    );
  }
}
