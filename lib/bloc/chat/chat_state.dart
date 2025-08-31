import 'package:equatable/equatable.dart';
import '../../models/chat_message.dart';
import '../../models/user_info.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final bool isTyping;
  final bool otherUserTyping;
  final String? error;
  final UserInfo? otherUserInfo;

  const ChatLoaded({
    required this.messages,
    this.isTyping = false,
    this.otherUserTyping = false,
    this.error,
    this.otherUserInfo,
  });

  ChatLoaded copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    bool? otherUserTyping,
    String? error,
    UserInfo? otherUserInfo,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      otherUserTyping: otherUserTyping ?? this.otherUserTyping,
      error: error,
      otherUserInfo: otherUserInfo ?? this.otherUserInfo,
    );
  }

  @override
  List<Object?> get props => [messages, isTyping, otherUserTyping, error, otherUserInfo];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object> get props => [message];
}
