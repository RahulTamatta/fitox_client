import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'secure_storage_service.dart';

class AuthService {
  static const String _baseUrl = 'http://10.0.2.2:5001';
  static const Duration _timeoutDuration = Duration(seconds: 30);
  
  final SecureStorageService _storage = SecureStorageService();
  final http.Client _client = http.Client();
  final Uuid _uuid = const Uuid();

  // Device ID for session tracking
  Future<String> _getOrCreateDeviceId() async {
    String? deviceId = await _storage.getDeviceId();
    if (deviceId == null) {
      deviceId = _uuid.v4();
      await _storage.storeDeviceId(deviceId);
    }
    return deviceId;
  }

  // Get headers with auth token
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'X-Device-Id': await _getOrCreateDeviceId(),
    };

    if (includeAuth) {
      final token = await getValidAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Login
  Future<AuthResult> login(String email, String password) async {
    try {
      final headers = await _getHeaders(includeAuth: false);
      
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/user/login'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(_timeoutDuration);

      if (kDebugMode) {
        debugPrint('Login response status: ${response.statusCode}');
        debugPrint('Login response body: ${response.body}');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('🔑 Storing tokens - accessToken: ${data['accessToken'] != null}, refreshToken: ${data['refreshToken'] != null}');
        }
        await _storeTokens(data);
        if (kDebugMode) {
          debugPrint('✅ Login tokens stored successfully');
        }
        return AuthResult.success(data['user']);
      } else {
        if (kDebugMode) {
          debugPrint('❌ Login failed with status: ${response.statusCode}');
        }
        return AuthResult.error(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Login error: $e');
      }
      return AuthResult.error('Network error: $e');
    }
  }

  // Register
  Future<AuthResult> register(Map<String, dynamic> userData) async {
    try {
      final headers = await _getHeaders(includeAuth: false);
      
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/user/register'),
        headers: headers,
        body: jsonEncode(userData),
      ).timeout(_timeoutDuration);

      if (kDebugMode) {
        debugPrint('Register response status: ${response.statusCode}');
        debugPrint('Register response body: ${response.body}');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Auto-login after successful registration
        return await login(userData['email'], userData['password']);
      } else {
        return AuthResult.error(data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Register error: $e');
      }
      return AuthResult.error('Network error: $e');
    }
  }

  // Get valid access token (with auto-refresh)
  Future<String?> getValidAccessToken() async {
    try {
      // Check if access token exists and is not expired
      if (!await _storage.isAccessTokenExpired()) {
        return await _storage.getAccessToken();
      }

      // Try to refresh token
      final refreshResult = await _refreshToken();
      if (refreshResult.isSuccess) {
        return await _storage.getAccessToken();
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting valid access token: $e');
      }
      return null;
    }
  }

  // Refresh access token
  Future<AuthResult> _refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || await _storage.isRefreshTokenExpired()) {
        return AuthResult.error('No valid refresh token');
      }

      final headers = await _getHeaders(includeAuth: false);
      
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/auth/refresh'),
        headers: headers,
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      ).timeout(_timeoutDuration);

      if (kDebugMode) {
        debugPrint('Refresh token response status: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _storeTokens(data);
        return AuthResult.success(data['user']);
      } else {
        // Refresh token is invalid, clear all tokens
        await logout();
        return AuthResult.error(data['message'] ?? 'Token refresh failed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Refresh token error: $e');
      }
      await logout(); // Clear invalid tokens
      return AuthResult.error('Token refresh failed');
    }
  }

  // Store tokens securely
  Future<void> _storeTokens(Map<String, dynamic> data) async {
    if (kDebugMode) {
      debugPrint('💾 Storing tokens: accessToken=${data['accessToken']?.substring(0, 20)}..., refreshToken=${data['refreshToken']?.substring(0, 20)}...');
    }
    
    if (data['accessToken'] == null || data['refreshToken'] == null) {
      throw Exception('Missing tokens in response: accessToken=${data['accessToken'] != null}, refreshToken=${data['refreshToken'] != null}');
    }
    
    await Future.wait([
      _storage.storeAccessToken(
        data['accessToken'],
        data['accessTokenExpiresIn'] ?? 15 * 60 * 1000, // 15 minutes default
      ),
      _storage.storeRefreshToken(
        data['refreshToken'],
        data['refreshTokenExpiresIn'] ?? 30 * 24 * 60 * 60 * 1000, // 30 days default
      ),
      if (data['user'] != null)
        _storage.storeUserData(jsonEncode(data['user'])),
    ]);
    
    if (kDebugMode) {
      debugPrint('✅ All tokens and user data stored successfully');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      
      if (refreshToken != null) {
        // Notify server about logout
        final headers = await _getHeaders(includeAuth: false);
        
        await _client.post(
          Uri.parse('$_baseUrl/api/auth/logout'),
          headers: headers,
          body: jsonEncode({
            'refreshToken': refreshToken,
          }),
        ).timeout(_timeoutDuration);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Logout server notification error: $e');
      }
    } finally {
      // Always clear local tokens
      await _storage.clearTokens();
    }
  }

  // Logout from all devices
  Future<AuthResult> logoutFromAllDevices() async {
    try {
      final headers = await _getHeaders();
      
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/auth/logout-all'),
        headers: headers,
      ).timeout(_timeoutDuration);

      await _storage.clearTokens();

      if (response.statusCode == 200) {
        return AuthResult.success(null);
      } else {
        final data = jsonDecode(response.body);
        return AuthResult.error(data['message'] ?? 'Logout failed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Logout all devices error: $e');
      }
      await _storage.clearTokens(); // Clear local tokens anyway
      return AuthResult.error('Logout failed');
    }
  }

  // Get current user
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final userData = await _storage.getUserData();
      if (userData != null) {
        return jsonDecode(userData);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Get current user error: $e');
      }
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _storage.isLoggedIn();
  }

  // Make authenticated request
  Future<http.Response> authenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? additionalHeaders,
  }) async {
    final headers = await _getHeaders();
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    final uri = Uri.parse('$_baseUrl$endpoint');
    
    switch (method.toUpperCase()) {
      case 'GET':
        return await _client.get(uri, headers: headers).timeout(_timeoutDuration);
      case 'POST':
        return await _client.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        ).timeout(_timeoutDuration);
      case 'PUT':
        return await _client.put(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        ).timeout(_timeoutDuration);
      case 'DELETE':
        return await _client.delete(uri, headers: headers).timeout(_timeoutDuration);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  void dispose() {
    _client.close();
  }
}

// Auth result wrapper
class AuthResult {
  final bool isSuccess;
  final String? error;
  final Map<String, dynamic>? user;

  AuthResult.success(this.user) : isSuccess = true, error = null;
  AuthResult.error(this.error) : isSuccess = false, user = null;
}
