import 'dart:convert';
import 'dart:io' show Platform;
import '../models/user_info.dart';
import 'auth_service.dart';

class UserService {
  // Base URL without trailing /api; endpoints below include '/api/...'
  static String get baseUrl =>
      Platform.isAndroid
          ? 'https://fitox-server.onrender.com'
          : 'http://localhost:5001';

  static Future<UserInfo?> getUserInfo(String userId) async {
    try {
      final auth = AuthService();
      final response = await auth.authenticatedRequest(
        'GET',
        '/api/users/$userId',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserInfo.fromJson(data['user'] ?? data);
      } else {
        print('Failed to fetch user info: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching user info: $e');
      return null;
    }
  }

  static Future<List<UserInfo>> searchUsers(String query) async {
    try {
      final auth = AuthService();
      final response = await auth.authenticatedRequest(
        'GET',
        '/api/users/search?q=$query',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> users = data['users'] ?? [];
        return users.map((user) => UserInfo.fromJson(user)).toList();
      }
      return [];
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }
}
