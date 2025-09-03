import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class SubscriptionService {
  static const String _baseUrl = 'https://fitox-server.onrender.com/api/agora';
  static Map<String, dynamic>? _cachedStatus;
  static DateTime? _lastCacheTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  static Future<bool> isActive(String userId) async {
    try {
      // Check cache first
      if (_cachedStatus != null &&
          _lastCacheTime != null &&
          DateTime.now().difference(_lastCacheTime!) < _cacheValidDuration) {
        return _cachedStatus!['active'] ?? false;
      }

      // Fetch from backend
      print('🔍 [SubscriptionService] GET active status for user: $userId');
      final response = await http.get(
        Uri.parse('$_baseUrl/subscription/status?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      print(
        '📡 [SubscriptionService] Status resp: ${response.statusCode} ${response.body}',
      );
      if (response.statusCode == 200) {
        _cachedStatus = jsonDecode(response.body);
        _lastCacheTime = DateTime.now();
        return _cachedStatus!['active'] ?? false;
      } else {
        print('Subscription check failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Subscription service error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getStatus(String userId) async {
    try {
      // Check cache first
      if (_cachedStatus != null &&
          _lastCacheTime != null &&
          DateTime.now().difference(_lastCacheTime!) < _cacheValidDuration) {
        return _cachedStatus;
      }

      print('🔍 [SubscriptionService] GET status for user: $userId');
      final response = await http.get(
        Uri.parse('$_baseUrl/subscription/status?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      print(
        '📡 [SubscriptionService] Status resp: ${response.statusCode} ${response.body}',
      );
      if (response.statusCode == 200) {
        _cachedStatus = jsonDecode(response.body);
        _lastCacheTime = DateTime.now();
        return _cachedStatus;
      }
      return null;
    } catch (e) {
      print('Get subscription status error: $e');
      return null;
    }
  }

  static Future<bool> validateAction({
    required String userId,
    required String action, // 'call' or 'chat'
  }) async {
    try {
      print(
        '🔍 [SubscriptionService] POST validate action=$action for user: $userId',
      );
      final response = await http.post(
        Uri.parse('$_baseUrl/subscription/validate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'action': action}),
      );

      print(
        '📡 [SubscriptionService] Validate resp: ${response.statusCode} ${response.body}',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['allowed'] ?? false;
      }
      return false;
    } catch (e) {
      print('Validate subscription action error: $e');
      return false;
    }
  }

  static void clearCache() {
    _cachedStatus = null;
    _lastCacheTime = null;
  }

  static Future<String?> getCurrentUserId() async {
    final auth = AuthService();
    final user = await auth.getCurrentUser();
    final id = (user?['_id'] ?? user?['id']);
    return id?.toString();
  }
}
