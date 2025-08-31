import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_event.dart';
import 'chat_state.dart';
import '../../data/chat_repository.dart';
import '../../models/chat_message.dart';
import '../../services/agora/agora_rtm_service.dart';
import '../../services/user_service.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  String? _currentUserId;
  String? _otherUserId;
  StreamSubscription? _rtmSub;

  ChatBloc() : super(ChatInitial()) {
    on<ChatStarted>(_onStarted);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatMessageReceived>(_onMessageReceived);
    on<ChatTypingChanged>(_onTypingChanged);
  }

  Future<void> _onStarted(ChatStarted event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    _currentUserId = event.currentUserId;
    _otherUserId = event.otherUserId;

    try {
      // Init transports
      await AgoraRtmService.initialize();
      await AgoraRtmService.login(_currentUserId!);
      await ChatRepository.initSocket(_currentUserId!);

      // Fetch other user info for display
      final otherUserInfo = await UserService.getUserInfo(_otherUserId!);

      // RTM callback -> dispatch into BLoC
      AgoraRtmService.onMessageReceived = (message, peerId) {
        // ignore self and non-active peer
        if (peerId == _currentUserId) return;
        if (_otherUserId != null && peerId != _otherUserId) return;
        final String raw = message; // AgoraRtmService provides String message

        // Control payloads
        try {
          if (raw.startsWith('{')) {
            final obj = jsonDecode(raw);
            if (obj is Map && obj['type'] == 'typing') {
              final typing = obj['isTyping'] == true;
              add(ChatTypingChanged(typing, isOtherUserTyping: true));
              return;
            }
            if (obj is Map && obj['type'] == 'read') {
              // Optionally handle read receipts here
              return;
            }
          }
        } catch (_) {}

        add(ChatMessageReceived(peerId: peerId, text: raw));
      };

      // Socket.io callbacks wired from repository
      ChatRepository.onMessageReceived = (message, senderId) {
        if (senderId == _currentUserId) return;
        if (_otherUserId != null && senderId != _otherUserId) return;
        add(ChatMessageReceived(peerId: senderId, text: message));
      };

      ChatRepository.onTypingChanged = (userId, isTyping) {
        if (userId == _currentUserId) return;
        if (_otherUserId != null && userId != _otherUserId) return;
        add(ChatTypingChanged(isTyping, isOtherUserTyping: true));
      };

      ChatRepository.onMessageStatusChanged = (messageId, status) {
        final st = state;
        if (st is ChatLoaded) {
          final updated =
              st.messages
                  .map(
                    (m) =>
                        m.id == messageId
                            ? ChatMessage(
                              id: m.id,
                              fromId: m.fromId,
                              toId: m.toId,
                              text: m.text,
                              sentAt: m.sentAt,
                              status: status,
                              isMe: m.isMe,
                              time: m.time,
                            )
                            : m,
                  )
                  .toList();
          emit(st.copyWith(messages: updated));
        }
      };

      // Load history from backend (Mongo)
      final history = await ChatRepository.loadMessagesFromBackend(
        _currentUserId!,
        _otherUserId!,
      );
      emit(ChatLoaded(messages: history, otherUserInfo: otherUserInfo));

      // Mark read
      await ChatRepository.markMessagesAsRead(_currentUserId!, _otherUserId!);
    } catch (e) {
      emit(ChatError('Failed to start chat: $e'));
    }
  }

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded || _currentUserId == null || _otherUserId == null)
      return;
    final current = state as ChatLoaded;

    // 1) Create an optimistic message with a client-generated ID
    final now = DateTime.now();
    final clientMessageId = now.millisecondsSinceEpoch.toString();
    final optimistic = ChatMessage(
      id: clientMessageId,
      fromId: _currentUserId!,
      toId: _otherUserId!,
      text: event.text,
      sentAt: now,
      status: MessageStatus.sending,
      isMe: true,
      time: '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
    );
    emit(
      current.copyWith(messages: List.of(current.messages)..add(optimistic)),
    );

    try {
      // 2) Send via repository, passing clientMessageId so callbacks can map
      final sentMsg = await ChatRepository.sendMessage(
        fromId: _currentUserId!,
        toId: _otherUserId!,
        text: event.text,
        clientMessageId: clientMessageId,
      );

      if (sentMsg != null) {
        final st = state as ChatLoaded;
        // 3) Replace optimistic message with the 'sent' status version immediately
        final updated =
            st.messages
                .map(
                  (m) =>
                      m.id == clientMessageId
                          ? m.copyWith(status: sentMsg.status)
                          : m,
                )
                .toList();
        emit(st.copyWith(messages: updated));
      }
    } catch (e) {
      // Mark the optimistic message as failed
      final st = state as ChatLoaded;
      final updated =
          st.messages
              .map(
                (m) =>
                    m.id == clientMessageId
                        ? m.copyWith(status: MessageStatus.failed)
                        : m,
              )
              .toList();
      emit(st.copyWith(messages: updated, error: 'Failed to send: $e'));
    }
  }

  Future<void> _onMessageReceived(
    ChatMessageReceived event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded || _currentUserId == null) return;
    final current = state as ChatLoaded;

    final now = DateTime.now();
    final incoming = ChatMessage(
      id: now.millisecondsSinceEpoch.toString(),
      fromId: event.peerId,
      toId: _currentUserId!,
      text: event.text,
      sentAt: now,
      status: MessageStatus.delivered,
      isMe: false,
      time: '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
    );

    emit(current.copyWith(messages: List.of(current.messages)..add(incoming)));
  }

  Future<void> _onTypingChanged(
    ChatTypingChanged event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded || _otherUserId == null) return;
    final current = state as ChatLoaded;

    if (event.isOtherUserTyping) {
      // update UI for other user's typing
      emit(current.copyWith(otherUserTyping: event.isTyping));
      return;
    }

    // current user typing -> send to other user
    ChatRepository.sendTypingIndicator(_otherUserId!, event.isTyping);
    AgoraRtmService.sendTypingIndicator(_otherUserId!, event.isTyping);
    emit(current.copyWith(isTyping: event.isTyping));
  }

  @override
  Future<void> close() {
    _rtmSub?.cancel();
    AgoraRtmService.onMessageReceived = null;
    return super.close();
  }
}
