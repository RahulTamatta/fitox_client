import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Enum to represent API response states
enum ResponseState { initial, loading, success, error }

// Class to wrap API response
class ApiResponse<T> {
  final ResponseState state;
  final T? data;
  final String? error;

  ApiResponse({required this.state, this.data, this.error});

  factory ApiResponse.loading() => ApiResponse(state: ResponseState.loading);
  factory ApiResponse.success(T data) =>
      ApiResponse(state: ResponseState.success, data: data);
  factory ApiResponse.error(String error) =>
      ApiResponse(state: ResponseState.error, error: error);
}

class ProfileService {
  static const String _baseUrl = 'http://10.0.2.2:5001';
  static const Duration _timeoutDuration = Duration(seconds: 30);
  static const int _maxRetries = 2;

  // Helper method to get auth token from SharedPreferences
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Helper method to save auth token to SharedPreferences
  Future<void> _saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Helper method to make HTTP requests with retry logic
  Future<http.Response> _makeRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    int retryCount = 0,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final headers = {'Content-Type': 'application/json'};

      if (requiresAuth) {
        final token = await _getAuthToken();
        if (token == null) throw Exception('No auth token found');
        headers['Authorization'] = 'Bearer $token';
      }

      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http
              .get(uri, headers: headers)
              .timeout(_timeoutDuration);
          break;
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: jsonEncode(body))
              .timeout(_timeoutDuration);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
      return response;
    } catch (e) {
      if (retryCount < _maxRetries &&
          (e is TimeoutException || e is SocketException)) {
        if (kDebugMode) {
          print(
            'Retrying request ($retryCount/$_maxRetries) for $endpoint: $e',
          );
        }
        await Future.delayed(Duration(seconds: 1));
        return _makeRequest(
          method: method,
          endpoint: endpoint,
          body: body,
          requiresAuth: requiresAuth,
          retryCount: retryCount + 1,
        );
      }
      rethrow;
    }
  }

  // Helper method to handle HTTP responses
  ApiResponse<T> _handleResponse<T>(
    http.Response response, {
    required T Function(dynamic) parser,
  }) {
    try {
      if (kDebugMode) {
        print('Response statusCode: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.body.isEmpty) {
        return ApiResponse.error('Empty response from server');
      }

      dynamic body;
      try {
        body = jsonDecode(response.body);
      } catch (e) {
        return ApiResponse.error('Invalid JSON format: ${response.body} ($e)');
      }

      final statusCode = response.statusCode;
      if (statusCode >= 200 && statusCode < 300) {
        return ApiResponse.success(parser(body));
      } else {
        String error;
        switch (statusCode) {
          case 400:
            error = body['message'] ?? 'Bad request';
            break;
          case 401:
            error = 'Unauthorized: Invalid or expired token';
            break;
          case 403:
            error = 'Forbidden: Access denied';
            break;
          case 404:
            error = 'Not found';
            break;
          case 500:
            error = body['message'] ?? 'Server error';
            if (kDebugMode) {
              print('Server error details: ${response.body}');
            }
            break;
          default:
            error = 'Unexpected error: $statusCode';
        }
        return ApiResponse.error(error);
      }
    } catch (e) {
      return ApiResponse.error('Failed to process response: $e');
    }
  }

  // Get profile info
  Future<ApiResponse<Map<String, dynamic>>> getProfileInfo(
    String userId,
  ) async {
    try {
      final response = await _makeRequest(
        method: 'GET',
        endpoint: '/api/user/profile/$userId',
        requiresAuth: false, // Set to true if auth is required
      );

      return _handleResponse(
        response,
        parser: (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error in getProfileInfo: $e');
      }
      return ApiResponse.error('Failed to fetch profile: $e');
    }
  }

  // Update profile
  Future<ApiResponse<Map<String, dynamic>>> updateProfile({
    required String userId,
    Map<String, dynamic>? updateData,
  }) async {
    try {
      final body = {'userId': userId, if (updateData != null) ...updateData};

      final response = await _makeRequest(
        method: 'POST',
        endpoint: '/api/user/profile/update',
        body: body,
        requiresAuth: false, // Set to true if auth is required
      );

      return _handleResponse(
        response,
        parser: (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error in updateProfile: $e');
      }
      return ApiResponse.error('Failed to update profile: $e');
    }
  }

  // Get list of following users
  Future<ApiResponse<List<dynamic>>> getFollowing(String userId) async {
    try {
      final response = await _makeRequest(
        method: 'GET',
        endpoint: '/api/follow/following/$userId',
        requiresAuth: false,
      );

      return _handleResponse(response, parser: (data) => data as List<dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('Error in getFollowing: $e');
      }
      return ApiResponse.error('Failed to fetch following list: $e');
    }
  }

  // Get list of followers
  Future<ApiResponse<List<dynamic>>> getFollowers(String userId) async {
    try {
      final response = await _makeRequest(
        method: 'GET',
        endpoint: '/api/follow/followers/$userId',
        requiresAuth: false,
      );

      return _handleResponse(response, parser: (data) => data as List<dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('Error in getFollowers: $e');
      }
      return ApiResponse.error('Failed to fetch followers: $e');
    }
  }

  // Follow a user
  Future<ApiResponse<Map<String, dynamic>>> followUser({
    required String userId,
    required String targetId,
  }) async {
    try {
      final body = {'userId': userId, 'targetId': targetId};

      final response = await _makeRequest(
        method: 'POST',
        endpoint: '/api/follow/follow',
        body: body,
        requiresAuth: false,
      );

      return _handleResponse(
        response,
        parser: (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error in followUser: $e');
      }
      return ApiResponse.error('Failed to follow user: $e');
    }
  }

  // Unfollow a user
  Future<ApiResponse<Map<String, dynamic>>> unfollowUser({
    required String userId,
    required String targetId,
  }) async {
    try {
      final body = {'userId': userId, 'targetId': targetId};

      final response = await _makeRequest(
        method: 'POST',
        endpoint: '/api/follow/unfollow',
        body: body,
        requiresAuth: false,
      );

      return _handleResponse(
        response,
        parser: (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error in unfollowUser: $e');
      }
      return ApiResponse.error('Failed to unfollow user: $e');
    }
  }
}
