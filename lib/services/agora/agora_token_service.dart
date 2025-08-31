import 'dart:convert';
import 'package:http/http.dart' as http;

class AgoraTokenService {
  static const String _baseUrl = 'http://10.0.2.2:5001/api/agora';
  
  static Future<Map<String, dynamic>?> getRtcToken({
    required String channelName,
    required int uid,
    String role = 'publisher',
    int ttlSeconds = 3600,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/rtcToken'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'channelName': channelName,
          'uid': uid,
          'role': role,
          'ttlSeconds': ttlSeconds,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('RTC Token Error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('RTC Token Service Error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getRtmToken({
    required String uid,
    int ttlSeconds = 3600,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/rtmToken'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'ttlSeconds': ttlSeconds,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('RTM Token Error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('RTM Token Service Error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getSubscriptionStatus({
    required String userId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/subscription/status?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Subscription Status Error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Subscription Status Service Error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> validateSubscription({
    required String userId,
    required String action, // 'call' or 'chat'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/subscription/validate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'action': action,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Subscription Validation Error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Subscription Validation Service Error: $e');
      return null;
    }
  }
}
