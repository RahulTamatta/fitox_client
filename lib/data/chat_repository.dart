import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../services/agora/agora_rtm_service.dart';
import 'package:uuid/uuid.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ChatRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _messagesCollection = 'chat_messages';
  static const Uuid _uuid = Uuid();

  // Socket.io
  static IO.Socket? _socket;
  static String? _currentUserId;
  // Real-time callback hooks (set by BLoC)
  static Function(String message, String senderId)? onMessageReceived;
  static Function(String userId, bool isTyping)? onTypingChanged;
  static Function(String messageId, MessageStatus status)?
  onMessageStatusChanged;

  // Socket.io initialization
  static Future<void> initSocket(String userId) async {
    try {
      _currentUserId = userId;

      // Use platform-specific URL
      final socketUrl =
          Platform.isAndroid ? 'http://10.0.2.2:5001' : 'http://localhost:5001';

      print(
        '🔌 [ChatRepository] Initializing Socket.io connection to: $socketUrl',
      );
      print('👤 [ChatRepository] User ID: $userId');

      _socket = IO.io(socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      _socket!.connect();

      _socket!.on('connect', (_) {
        print('✅ [ChatRepository] Socket.io connected successfully');
        _socket!.emit('join', userId);
        print('📡 [ChatRepository] Sent join event for user: $userId');
      });

      _socket!.on('disconnect', (_) {
        print('❌ [ChatRepository] Socket.io disconnected');
      });

      _socket!.on('receiveMessage', (data) {
        print('📨 [ChatRepository] Received message via Socket.io: $data');
        try {
          final sender = data['sender']?.toString();
          final msg = data['message']?.toString();
          if (sender != null && msg != null) {
            onMessageReceived?.call(msg, sender);
          }
        } catch (e) {
          print('⚠️ [ChatRepository] receiveMessage parse error: $e');
        }
      });

      _socket!.on('typing', (data) {
        print('⌨️ [ChatRepository] Typing event: $data');
        try {
          final from = data['from']?.toString();
          final isTyping = (data['isTyping'] == true);
          if (from != null) {
            onTypingChanged?.call(from, isTyping);
          }
        } catch (e) {
          print('⚠️ [ChatRepository] typing parse error: $e');
        }
      });

      _socket!.on('messageDelivered', (data) {
        print('✅ [ChatRepository] messageDelivered: $data');
        try {
          final id = data['messageId']?.toString();
          if (id != null) {
            onMessageStatusChanged?.call(id, MessageStatus.delivered);
          }
        } catch (e) {
          print('⚠️ [ChatRepository] messageDelivered parse error: $e');
        }
      });

      _socket!.on('messageRead', (data) {
        print('👀 [ChatRepository] messageRead: $data');
        try {
          final ids =
              (data['messageIds'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          for (final id in ids) {
            onMessageStatusChanged?.call(id, MessageStatus.read);
          }
        } catch (e) {
          print('⚠️ [ChatRepository] messageRead parse error: $e');
        }
      });

      _socket!.on('connect_error', (error) {
        print('💥 [ChatRepository] Socket.io connection error: $error');
      });
    } catch (e) {
      print('💥 [ChatRepository] Failed to initialize Socket.io: $e');
    }
  }

  // Save message to Firestore
  static Future<void> saveMessage(ChatMessage message) async {
    try {
      await _firestore.collection(_messagesCollection).doc(message.id).set({
        'id': message.id,
        'fromId': message.fromId,
        'toId': message.toId,
        'text': message.text,
        'sentAt': message.sentAt,
        'status': message.status.toString().split('.').last,
        'rtmMsgId': message.rtmMsgId,
        'isMe': message.isMe,
        'time': message.time,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Message saved to Firestore: ${message.id}');
    } catch (e) {
      print('Failed to save message to Firestore: $e');
      throw e;
    }
  }

  // Update message status
  static Future<void> updateMessageStatus(
    String messageId,
    MessageStatus status,
  ) async {
    try {
      await _firestore.collection(_messagesCollection).doc(messageId).update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to update message status: $e');
    }
  }

  // Watch messages between two users
  static Stream<List<ChatMessage>> watchThread(
    String userId,
    String otherUserId,
  ) {
    return _firestore
        .collection(_messagesCollection)
        .where('fromId', whereIn: [userId, otherUserId])
        .where('toId', whereIn: [userId, otherUserId])
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return ChatMessage.fromJson(data);
          }).toList();
        });
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead(
    String userId,
    String otherUserId,
  ) async {
    try {
      final batch = _firestore.batch();
      final unreadMessages =
          await _firestore
              .collection(_messagesCollection)
              .where('fromId', isEqualTo: otherUserId)
              .where('toId', isEqualTo: userId)
              .where('status', isNotEqualTo: 'read')
              .get();

      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'status': 'read',
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // Send read receipt via Socket.io
      if (_socket != null && _socket!.connected && _currentUserId != null) {
        _socket!.emit('markAsRead', {
          'from': _currentUserId,
          'to': otherUserId,
        });
      }
    } catch (e) {
      print('Failed to mark messages as read: $e');
    }
  }

  // Send typing indicator
  static Future<void> sendTypingIndicator(
    String toUserId,
    bool isTyping,
  ) async {
    if (_socket != null && _socket!.connected && _currentUserId != null) {
      _socket!.emit('typing', {
        'from': _currentUserId,
        'to': toUserId,
        'isTyping': isTyping,
      });
    }
  }

  // Send read receipt + mark as read on backend
  static Future<void> sendReadReceipt(
    String toUserId,
    List<String> messageIds,
  ) async {
    if (_socket != null && _socket!.connected && _currentUserId != null) {
      _socket!.emit('readReceipt', {
        'from': _currentUserId,
        'to': toUserId,
        'messageIds': messageIds,
      });
      _socket!.emit('markAsRead', {'from': _currentUserId, 'to': toUserId});
    }
  }

  // Get user chat summaries from backend
  static Future<List<Map<String, dynamic>>> getUserChatSummaries(
    String userId,
  ) async {
    try {
      print('🔍 [ChatRepository] Fetching chat summaries for user: $userId');

      final response = await http.get(
        Uri.parse('${_baseUrl()}/api/chat/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      print(
        '📡 [ChatRepository] Chat summaries response: ${response.statusCode}',
      );
      print('📄 [ChatRepository] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // The backend returns an array directly, not wrapped in 'chats'
        final List<dynamic> chatsArray =
            data is List ? data : (data['chats'] ?? []);

        final formattedChats =
            chatsArray
                .map(
                  (chat) => {
                    'chatId': chat['_id']?.toString() ?? '',
                    'otherUserId': chat['otherUserId']?.toString() ?? '',
                    'otherUserName': chat['otherUserName'] ?? 'Unknown User',
                    'otherUserImage': chat['otherUserImage'],
                    'lastMessage': chat['lastMessage'] ?? 'No messages yet',
                    'lastMessageTime':
                        chat['lastMessageTime'] != null
                            ? DateTime.parse(chat['lastMessageTime'])
                            : DateTime.now(),
                    'unreadCount': chat['unreadCount'] ?? 0,
                  },
                )
                .toList();

        print(
          '✅ [ChatRepository] Formatted ${formattedChats.length} chat summaries',
        );
        return List<Map<String, dynamic>>.from(formattedChats);
      } else {
        print(
          '❌ [ChatRepository] Failed to get chat summaries: ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      print('💥 [ChatRepository] Error getting chat summaries: $e');
      return [];
    }
  }

  // Load messages from MongoDB backend for a chat thread
  static Future<List<ChatMessage>> loadMessagesFromBackend(
    String userId,
    String otherUserId,
  ) async {
    try {
      print(
        '🔍 [ChatRepository] Loading messages from backend for $userId <-> $otherUserId',
      );

      final response = await http.get(
        Uri.parse('${_baseUrl()}/api/chat/messages/$userId/$otherUserId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final messagesData = data['messages'] as List<dynamic>? ?? [];

        print(
          '📥 [ChatRepository] Loaded ${messagesData.length} messages from backend',
        );

        return messagesData.map((msgData) {
          final senderId = msgData['sender'].toString();
          final isMe = senderId == userId;
          final timestamp = DateTime.parse(msgData['timestamp']);

          return ChatMessage(
            id: msgData['_id'].toString(),
            fromId: senderId,
            toId: isMe ? otherUserId : userId,
            text: msgData['message'],
            sentAt: timestamp,
            status: _parseMessageStatus(msgData['status']),
            isMe: isMe,
            time:
                '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
          );
        }).toList();
      } else {
        print(
          '❌ [ChatRepository] Failed to load messages: ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      print('💥 [ChatRepository] Error loading messages from backend: $e');
      return [];
    }
  }

  // Parse message status from backend
  static MessageStatus _parseMessageStatus(String status) {
    switch (status.toLowerCase()) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }

  // Initialize chat between users
  static Future<Map<String, dynamic>?> initializeChat(
    String userId,
    String otherUserId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl()}/api/chat/initiate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'participants': [userId, otherUserId],
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        print('Failed to initialize chat: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error initializing chat: $e');
      return null;
    }
  }

  // Mark chat as read
  static Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl()}/api/chat/markRead/$chatId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId}),
      );

      if (response.statusCode != 200) {
        print('Failed to mark chat as read: ${response.statusCode}');
      }
    } catch (e) {
      print('Error marking chat as read: $e');
    }
  }

  // Send message: Agora RTM primary, Socket.io fallback; always save to Firestore
  static Future<ChatMessage?> sendMessage({
    required String fromId,
    required String toId,
    required String text,
    String? clientMessageId,
  }) async {
    print(
      '🚀 [ChatRepository] Starting message send from $fromId to $toId: "$text"',
    );
    if (kDebugMode) {
      debugPrint('🚀 [DEBUG] ChatRepository.sendMessage called');
    }

    try {
      final now = DateTime.now();
      final message = ChatMessage(
        id: clientMessageId ?? _uuid.v4(),
        fromId: fromId,
        toId: toId,
        text: text,
        sentAt: now,
        status: MessageStatus.sending,
        isMe: true,
        time: '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      );

      print('📝 [ChatRepository] Created message with ID: ${message.id}');
      // Skip Firestore for now due to Firebase initialization issues
      print(
        '📝 [ChatRepository] Skipping Firestore save - using RTM/Socket only',
      );
      final rtmSuccess = await AgoraRtmService.sendMessage(
        peerId: toId,
        text: text,
      );

      if (rtmSuccess) {
        print('✅ [ChatRepository] Message sent successfully via Agora RTM');

        // Also send via Socket.io for real-time updates
        try {
          if (_socket != null && _socket!.connected) {
            _socket!.emit('sendMessage', {
              'sender': fromId,
              'receiver': toId,
              'message': text,
            });
            print(
              '📨 [ChatRepository] Message also sent via Socket.io for real-time sync',
            );
          } else {
            print('⚠️ [ChatRepository] Socket not connected, RTM-only send');
          }
        } catch (e) {
          print(
            '❌ [ChatRepository] Socket send error (RTM still succeeded): $e',
          );
        }

        // Update status to sent
        updateMessageStatus(message.id, MessageStatus.sent);
        print('✅ [ChatRepository] Message status updated to sent');
        return message.copyWith(status: MessageStatus.sent);
      } else {
        print(
          '❌ [ChatRepository] Agora RTM send failed, trying Socket.io fallback',
        );

        // Fallback: Socket.io only
        if (_socket != null && _socket!.connected) {
          _socket!.emit('sendMessage', {
            'sender': fromId,
            'receiver': toId,
            'message': text,
          });
          print('📨 [ChatRepository] Message sent via Socket.io fallback');
          updateMessageStatus(message.id, MessageStatus.sent);
          return message.copyWith(status: MessageStatus.sent);
        } else {
          print('❌ [ChatRepository] Both RTM and Socket.io failed');
          updateMessageStatus(message.id, MessageStatus.failed);
          return message.copyWith(status: MessageStatus.failed);
        }
      }
    } catch (e) {
      print('💥 [ChatRepository] Critical error in sendMessage: $e');
      // Create a failed message to show in UI
      final failedMessage = ChatMessage(
        id: _uuid.v4(),
        fromId: fromId,
        toId: toId,
        text: text,
        sentAt: DateTime.now(),
        status: MessageStatus.failed,
        isMe: true,
        time:
            '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      );
      return failedMessage;
    }
  }

  static void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentUserId = null;
  }

  static String _baseUrl() {
    return Platform.isAndroid
        ? 'http://10.0.2.2:5001'
        : 'http://localhost:5001';
  }

  // Get thread ID for two users (consistent ordering)
  static String _getThreadId(String userId1, String userId2) {
    final users = [userId1, userId2]..sort();
    return '${users[0]}_${users[1]}';
  }

  // Get last message for chat list
  static Future<ChatMessage?> getLastMessage(
    String userId1,
    String userId2,
  ) async {
    try {
      final threadId = _getThreadId(userId1, userId2);

      final snapshot =
          await _firestore
              .collection(_messagesCollection)
              .where('threadId', isEqualTo: threadId)
              .orderBy('sentAt', descending: true)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        return ChatMessage.fromJson({...data, 'id': snapshot.docs.first.id});
      }
      return null;
    } catch (e) {
      print('Failed to get last message: $e');
      return null;
    }
  }
}
