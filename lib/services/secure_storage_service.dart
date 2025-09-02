import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Token keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _accessTokenExpiryKey = 'access_token_expiry';
  static const String _refreshTokenExpiryKey = 'refresh_token_expiry';
  static const String _userDataKey = 'user_data';
  static const String _deviceIdKey = 'device_id';

  // Store access token
  Future<void> storeAccessToken(String token, int expiresInMs) async {
    try {
      await _storage.write(key: _accessTokenKey, value: token);
      final expiryTime = DateTime.now().millisecondsSinceEpoch + expiresInMs;
      await _storage.write(key: _accessTokenExpiryKey, value: expiryTime.toString());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error storing access token: $e');
      }
      rethrow;
    }
  }

  // Store refresh token
  Future<void> storeRefreshToken(String token, int expiresInMs) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
      final expiryTime = DateTime.now().millisecondsSinceEpoch + expiresInMs;
      await _storage.write(key: _refreshTokenExpiryKey, value: expiryTime.toString());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error storing refresh token: $e');
      }
      rethrow;
    }
  }

  // Get access token
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error reading access token: $e');
      }
      return null;
    }
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error reading refresh token: $e');
      }
      return null;
    }
  }

  // Check if access token is expired
  Future<bool> isAccessTokenExpired() async {
    try {
      final expiryStr = await _storage.read(key: _accessTokenExpiryKey);
      if (expiryStr == null) return true;
      
      final expiryTime = int.tryParse(expiryStr);
      if (expiryTime == null) return true;
      
      // Add 30 second buffer to prevent edge cases
      final bufferTime = 30 * 1000; // 30 seconds in ms
      return DateTime.now().millisecondsSinceEpoch >= (expiryTime - bufferTime);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking token expiry: $e');
      }
      return true;
    }
  }

  // Check if refresh token is expired
  Future<bool> isRefreshTokenExpired() async {
    try {
      final expiryStr = await _storage.read(key: _refreshTokenExpiryKey);
      if (expiryStr == null) return true;
      
      final expiryTime = int.tryParse(expiryStr);
      if (expiryTime == null) return true;
      
      return DateTime.now().millisecondsSinceEpoch >= expiryTime;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking refresh token expiry: $e');
      }
      return true;
    }
  }

  // Store user data
  Future<void> storeUserData(String userData) async {
    try {
      await _storage.write(key: _userDataKey, value: userData);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error storing user data: $e');
      }
      rethrow;
    }
  }

  // Get user data
  Future<String?> getUserData() async {
    try {
      return await _storage.read(key: _userDataKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error reading user data: $e');
      }
      return null;
    }
  }

  // Store device ID
  Future<void> storeDeviceId(String deviceId) async {
    try {
      await _storage.write(key: _deviceIdKey, value: deviceId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error storing device ID: $e');
      }
      rethrow;
    }
  }

  // Get device ID
  Future<String?> getDeviceId() async {
    try {
      return await _storage.read(key: _deviceIdKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error reading device ID: $e');
      }
      return null;
    }
  }

  // Clear all tokens (logout)
  Future<void> clearTokens() async {
    try {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _accessTokenExpiryKey),
        _storage.delete(key: _refreshTokenExpiryKey),
        _storage.delete(key: _userDataKey),
      ]);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error clearing tokens: $e');
      }
      rethrow;
    }
  }

  // Clear all data
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error clearing all data: $e');
      }
      rethrow;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final accessToken = await getAccessToken();
      final refreshToken = await getRefreshToken();
      
      if (accessToken == null || refreshToken == null) return false;
      
      // If refresh token is expired, user needs to login again
      if (await isRefreshTokenExpired()) return false;
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking login status: $e');
      }
      return false;
    }
  }
}
