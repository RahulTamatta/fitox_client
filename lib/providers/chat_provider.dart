import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../data/chat_repository.dart';
import '../services/agora/agora_rtm_service.dart';
import 'dart:async';

class ChatProvider with ChangeNotifier {
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;
  bool _isOnline = true;
  String? _error;
  String? _currentUserId;
  String? _otherUserId;
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;
  Timer? _typingTimer;
  List<Map<String, dynamic>> _chatSummaries = [];

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isTyping => _isTyping;
  bool get isOnline => _isOnline;
  String? get error => _error;
  String? get errorMessage => _error;
  String? get currentUserId => _currentUserId;
  String? get otherUserId => _otherUserId;
  List<Map<String, dynamic>> get chatSummaries => _chatSummaries;

  Future<void> initializeChat(String currentUserId, String otherUserId) async {
    _isLoading = true;
    _error = null;
    _currentUserId = currentUserId;
    _otherUserId = otherUserId;
    notifyListeners();

    try {
      // Initialize RTM service
      await AgoraRtmService.initialize();
      await AgoraRtmService.login(currentUserId);

      // Initialize Socket.io primary transport
      await ChatRepository.initSocket(currentUserId);

      // Set up RTM callbacks
      AgoraRtmService.onMessageReceived = _handleRtmMessage;
      AgoraRtmService.onError = _handleRtmError;

      // Load existing messages from MongoDB backend
      print('📥 [ChatProvider] Loading existing messages from backend...');
      final existingMessages = await ChatRepository.loadMessagesFromBackend(currentUserId, otherUserId);
      _messages = existingMessages;
      print('✅ [ChatProvider] Loaded ${existingMessages.length} existing messages');
      notifyListeners();

      // Mark existing messages as read
      await ChatRepository.markMessagesAsRead(currentUserId, otherUserId);

    } catch (e) {
      _error = 'Failed to initialize chat: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text) async {
    print('🚀 [ChatProvider] sendMessage called with text: "$text"');
    print('👤 [ChatProvider] Current user ID: $_currentUserId, Other user ID: $_otherUserId');
    
    if (_currentUserId == null || _otherUserId == null) {
      print('❌ [ChatProvider] Missing user IDs - cannot send message');
      return;
    }
    
    try {
      print('📤 [ChatProvider] Calling ChatRepository.sendMessage...');
      final message = await ChatRepository.sendMessage(
        fromId: _currentUserId!,
        toId: _otherUserId!,
        text: text,
      );

      if (message != null) {
        print('✅ [ChatProvider] Message sent, adding to local messages with status: ${message.status}');
        _messages.add(message);
        notifyListeners();
      } else {
        print('❌ [ChatProvider] Failed to send message - ChatRepository returned null');
      }
    } catch (e) {
      print('💥 [ChatProvider] Error in sendMessage: $e');
      _error = 'Failed to send message: $e';
      notifyListeners();
    }
  }

  Future<void> retryMessage(String messageId) async {
    try {
      final messageIndex = _messages.indexWhere((m) => m.id == messageId);
      if (messageIndex == -1) return;

      final message = _messages[messageIndex];
      if (message.status != MessageStatus.failed) return;

      // Update to sending status
      await ChatRepository.updateMessageStatus(messageId, MessageStatus.sending);

      // Retry RTM send
      final rtmSuccess = await AgoraRtmService.sendMessage(
        peerId: message.toId,
        text: message.text,
      );

      // Update final status
      await ChatRepository.updateMessageStatus(
        messageId, 
        rtmSuccess ? MessageStatus.sent : MessageStatus.failed
      );

    } catch (e) {
      print('Failed to retry message: $e');
    }
  }

  void startTyping() {
    if (_otherUserId == null) return;

    _isTyping = true;
    notifyListeners();

    // Send typing indicator via Socket (primary)
    ChatRepository.sendTypingIndicator(_otherUserId!, true);
    // Also via RTM as fallback
    AgoraRtmService.sendTypingIndicator(_otherUserId!, true);

    // Auto-stop typing after 3 seconds
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), stopTyping);
  }

  void stopTyping() {
    if (!_isTyping || _otherUserId == null) return;

    _isTyping = false;
    notifyListeners();

    // Send stop typing indicator via Socket/RTM
    ChatRepository.sendTypingIndicator(_otherUserId!, false);
    AgoraRtmService.sendTypingIndicator(_otherUserId!, false);
    _typingTimer?.cancel();
  }

  void _handleRtmMessage(message, String peerId) {
    // Handle both string messages and object messages
    final text = message is String ? message : message.text;
    
    // Ignore messages that originate from self (prevents self-echo)
    if (peerId == _currentUserId) {
      print('↩️ [ChatProvider] Ignoring self-echo message from $peerId');
      return;
    }

    // Ignore messages that are not from the active peer in this chat thread
    if (_otherUserId != null && peerId != _otherUserId) {
      print('↪️ [ChatProvider] Ignoring message from non-active peer $peerId');
      return;
    }

    // Handle special message types
    if (text == 'TYPING_START') {
      // Handle typing indicator from peer
      return;
    } else if (text == 'TYPING_STOP') {
      // Handle stop typing indicator from peer
      return;
    }

    print('📨 [ChatProvider] Received RTM message from $peerId: "$text"');

    // Create ChatMessage from RTM message
    final chatMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fromId: peerId,
      toId: _currentUserId ?? '',
      text: text,
      sentAt: DateTime.now(),
      status: MessageStatus.delivered,
      isMe: false,
      time: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
    );

    // Add to messages and notify UI
    _messages.add(chatMessage);
    notifyListeners();

    print('✅ [ChatProvider] Message added to UI, total messages: ${_messages.length}');

    // Skip Firestore save for now - using RTM/Socket only
    print('📝 [ChatProvider] Message handled, skipping Firestore save');
  }


  void _handleRtmError(String error) {
    _error = 'RTM Error: $error';
    notifyListeners();
  }

  void setOnlineStatus(bool isOnline) {
    _isOnline = isOnline;
    notifyListeners();
  }

  Future<void> loadUserChats(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      print('🔄 [ChatProvider] Loading chats for user: $userId');
      
      // Load chat summaries from backend
      final chats = await ChatRepository.getUserChatSummaries(userId);
      _chatSummaries = chats;
      
      print('✅ [ChatProvider] Loaded ${chats.length} chat summaries');
      if (chats.isNotEmpty) {
        print('📋 [ChatProvider] First chat: ${chats.first}');
      }
      
      _error = null;
    } catch (e) {
      _error = 'Failed to load chats: $e';
      print('💥 [ChatProvider] Error loading user chats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateChatSummary(String chatId, String lastMessage, DateTime timestamp, String otherUserId, String otherUserName, String? otherUserImage) {
    final existingIndex = _chatSummaries.indexWhere((chat) => chat['chatId'] == chatId);
    final chatSummary = {
      'chatId': chatId,
      'lastMessage': lastMessage,
      'lastMessageTime': timestamp,
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'otherUserImage': otherUserImage,
      'unreadCount': 0,
    };
    
    if (existingIndex >= 0) {
      _chatSummaries[existingIndex] = chatSummary;
    } else {
      _chatSummaries.add(chatSummary);
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _typingTimer?.cancel();
    AgoraRtmService.logout();
    super.dispose();
  }
}
