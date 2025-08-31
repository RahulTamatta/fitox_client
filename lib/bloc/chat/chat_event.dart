import 'package:equatable/equatable.dart';

class ChatEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChatStarted extends ChatEvent {
  final String currentUserId;
  final String otherUserId;
  ChatStarted({required this.currentUserId, required this.otherUserId});

  @override
  List<Object?> get props => [currentUserId, otherUserId];
}

class ChatMessageSent extends ChatEvent {
  final String text;
  ChatMessageSent(this.text);

  @override
  List<Object?> get props => [text];
}

class ChatMessageReceived extends ChatEvent {
  final String peerId;
  final String text;
  ChatMessageReceived({required this.peerId, required this.text});

  @override
  List<Object?> get props => [peerId, text];
}

class ChatTypingChanged extends ChatEvent {
  final bool isTyping;
  ChatTypingChanged(this.isTyping);

  @override
  List<Object?> get props => [isTyping];
}
