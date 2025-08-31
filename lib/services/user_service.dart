import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_info.dart';

class UserService {
  static const String baseUrl = 'http://localhost:5001/api';
  
  static Future<UserInfo?> getUserInfo(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        print('No auth token found');
        return null;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/users/search?q=$query'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
