import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'chat_services.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _currentChat;
  List<dynamic> _messages = [];
  List<dynamic> _userChats = [];

  ChatProvider({ChatService? chatService})
    : _chatService = chatService ?? ChatService();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get currentChat => _currentChat;
  List<dynamic> get messages => _messages;
  List<dynamic> get userChats => _userChats;

  Future<void> initiateChat({
    required String userId,
    required String trainerId,
  }) async {
    _setLoading(true);
    try {
      final chat = await _chatService.initiateChat(
        userId: userId,
        trainerId: trainerId,
      );
      _currentChat = chat;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String userId,
    required String message,
  }) async {
    _setLoading(true);
    try {
      await _chatService.sendMessage(
        chatId: chatId,
        userId: userId,
        message: message,
      );
      _errorMessage = null;
      await fetchMessages(chatId: chatId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchMessages({required String chatId}) async {
    _setLoading(true);
    try {
      _messages = await _chatService.getMessages(chatId: chatId);
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchUserChats({required String userId}) async {
    _setLoading(true);
    try {
      _userChats = await _chatService.getUserChats(userId: userId);
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _chatService.dispose();
    super.dispose();
  }
}
