import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ChatService {
  static const String _baseUrl = 'http://10.0.2.2:5001/chat';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  final http.Client _client;

  ChatService({http.Client? client}) : _client = client ?? http.Client();

  // Helper to get auth token
  Future<String?> _getToken() async {
    return await _storage.read(key: 'access_token');
  }

  /// Initiates a chat between a user and a trainer
  Future<Map<String, dynamic>> initiateChat({
    required String userId,
    required String trainerId,
  }) async {
    try {
      final token = await _getToken();
      final response = await _client.post(
        Uri.parse('$_baseUrl/initiate'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'userId': userId, 'trainerId': trainerId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw ChatServiceException(
          message: 'Failed to initiate chat: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ChatServiceException) rethrow;
      throw ChatServiceException(
        message: 'Network error while initiating chat: $e',
      );
    }
  }

  /// Sends a message in a specific chat
  Future<Map<String, dynamic>> sendMessage({
    required String chatId,
    required String userId,
    required String message,
  }) async {
    try {
      final token = await _getToken();
      final response = await _client.post(
        Uri.parse('$_baseUrl/message/$chatId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'userId': userId, 'message': message}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw ChatServiceException(
          message: 'Failed to send message: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ChatServiceException) rethrow;
      throw ChatServiceException(
        message: 'Network error while sending message: $e',
      );
    }
  }

  /// Fetches all messages from a given chat
  Future<List<dynamic>> getMessages({required String chatId}) async {
    try {
      final token = await _getToken();
      final response = await _client.get(
        Uri.parse('$_baseUrl/$chatId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw ChatServiceException(
          message: 'Failed to fetch messages: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ChatServiceException) rethrow;
      throw ChatServiceException(
        message: 'Network error while fetching messages: $e',
      );
    }
  }

  /// Fetches all chat conversations of a specific user
  Future<List<dynamic>> getUserChats({required String userId}) async {
    try {
      print("::: USER ID $userId");
      final token = await _getToken();
      final response = await _client.post(
        Uri.parse('$_baseUrl/user'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw ChatServiceException(
          message:
              'Failed to fetch user chats: ${response.statusCode} & ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ChatServiceException) rethrow;
      throw ChatServiceException(
        message: 'Network error while fetching user chats: $e',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

class ChatServiceException implements Exception {
  final String message;
  final int? statusCode;

  ChatServiceException({required this.message, this.statusCode});

  @override
  String toString() =>
      'ChatServiceException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}
