import 'dart:convert';
import 'agora_token_service.dart';

// Mock RTM client for development
class _MockRtmClient {
  final String appId;
  Function(dynamic, String)? onMessageReceived;
  Function()? onTokenExpired;
  Function(dynamic)? onPeersOnlineStatusChanged;
  
  _MockRtmClient(this.appId);
  
  Future<void> login(String? token, String userId) async {
    print('Mock RTM login: $userId with appId: $appId');
  }
  
  Future<void> logout() async {
    print('Mock RTM logout');
  }
  
  dynamic createTextMessage(String text) {
    return MockMessage(text);
  }
  
  Future<void> sendMessageToPeer2(String peerId, dynamic message) async {
    print('Mock RTM send to $peerId: ${message.text}');
  }
  
  Future<void> release() async {
    print('Mock RTM client released');
  }
}

class MockMessage {
  final String text;
  MockMessage(this.text);
}

class AgoraRtmService {
  static String? _currentUserId;
  static bool _isLoggedIn = false;
  static String? _appId;
  static _MockRtmClient? _client;

  // Callbacks
  static Function(String message, String peerId)? onMessageReceived;
  static Function(String peerId, bool isOnline)? onPeerStatusChanged;
  static Function()? onTokenExpired;
  static Function(String error)? onError;

  static Future<bool> initialize() async {
    try {
      if (_client != null) return true;
      // Get app ID for RTM initialization via token service
      final tokenData = await AgoraTokenService.getRtmToken(uid: 'temp_init');
      if (tokenData == null || tokenData['appId'] == null) {
        print('Failed to get app ID for RTM initialization');
        return false;
      }

      _appId = tokenData['appId'];
      // Create mock RTM client for now - will be replaced with real implementation
      _client = _MockRtmClient(_appId!);

      // Register client event handlers
      _client!.onMessageReceived = (message, peerId) {
        final text = message.text;
        onMessageReceived?.call(text, peerId);
      };

      _client!.onTokenExpired = () {
        onTokenExpired?.call();
      };

      _client!.onPeersOnlineStatusChanged = (map) {
        map.forEach((peerId, state) {
          // Support both enum and int representations without importing the enum name
          final bool isOnline = (state is int)
              ? state == 0 // 0 == online
              : state.toString().toLowerCase().endsWith('.online');
          onPeerStatusChanged?.call(peerId, isOnline);
        });
      };

      print('RTM initialized with app ID: $_appId');
      return true;
    } catch (e) {
      print('Failed to initialize Agora RTM: $e');
      onError?.call('RTM init failed: $e');
      return false;
    }
  }

  static Future<bool> login(String userId) async {
    try {
      if (_isLoggedIn && _currentUserId == userId) return true;
      if (_client == null) {
        final ok = await initialize();
        if (!ok) return false;
      }

      // Get RTM token from backend
      final tokenData = await AgoraTokenService.getRtmToken(uid: userId);
      if (tokenData == null || tokenData['rtmToken'] == null) {
        print('Failed to get RTM token');
        return false;
      }

      final String token = tokenData['rtmToken'];
      await _client!.login(token, userId);

      _currentUserId = userId;
      _isLoggedIn = true;
      print('RTM Login successful for user: $userId');
      return true;
    } catch (e) {
      print('RTM Login failed: $e');
      onError?.call('Login failed: $e');
      return false;
    }
  }

  static Future<void> logout() async {
    try {
      if (_isLoggedIn && _client != null) {
        await _client!.logout();
      }
      _isLoggedIn = false;
      _currentUserId = null;
    } catch (e) {
      print('RTM Logout failed: $e');
    }
  }

  static Future<bool> sendMessage({
    required String peerId,
    required String text,
  }) async {
    try {
      if (!_isLoggedIn || _client == null) {
        print('RTM not logged in, cannot send message');
        return false;
      }
      final msg = _client!.createTextMessage(text);
      await _client!.sendMessageToPeer2(peerId, msg);
      return true;
    } catch (e) {
      print('Failed to send RTM message: $e');
      onError?.call('Failed to send message: $e');
      return false;
    }
  }

  static Future<void> sendTypingIndicator(String peerId, bool isTyping) async {
    try {
      if (!_isLoggedIn || _client == null) return;
      final payload = jsonEncode({
        'type': 'typing',
        'isTyping': isTyping,
        'from': _currentUserId,
        'ts': DateTime.now().millisecondsSinceEpoch,
      });
      final msg = _client!.createTextMessage(payload);
      await _client!.sendMessageToPeer2(peerId, msg);
    } catch (e) {
      print('Failed to send typing indicator: $e');
    }
  }

  static Future<void> sendReadReceipt(String peerId, String messageId) async {
    try {
      if (!_isLoggedIn || _client == null) return;
      final payload = jsonEncode({
        'type': 'read',
        'messageId': messageId,
        'from': _currentUserId,
        'ts': DateTime.now().millisecondsSinceEpoch,
      });
      final msg = _client!.createTextMessage(payload);
      await _client!.sendMessageToPeer2(peerId, msg);
    } catch (e) {
      print('Failed to send read receipt: $e');
    }
  }

  static Future<void> dispose() async {
    try {
      await logout();
      await _client?.release();
      _client = null;
    } catch (e) {
      print('Failed to dispose Agora RTM: $e');
    }
  }

  static bool get isLoggedIn => _isLoggedIn;
  static String? get currentUserId => _currentUserId;
}

