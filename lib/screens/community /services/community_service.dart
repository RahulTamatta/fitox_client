import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../global/api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class BlogResponse {
  final bool success;
  final String message;
  final dynamic
  data; // Can be List<dynamic> for getBlogs, Map for getBlogDetails, or others

  BlogResponse({required this.success, required this.message, this.data});

  factory BlogResponse.fromJson(dynamic json) {
    // Handle direct List<dynamic> response (e.g., getBlogs)
    if (json is List) {
      return BlogResponse(
        success: true,
        message: 'Blogs fetched successfully',
        data: json,
      );
    }
    // Handle direct Map<String, dynamic> response (e.g., getBlogDetails returning a single blog)
    if (json is Map<String, dynamic> && json.containsKey('_id')) {
      return BlogResponse(
        success: true,
        message: 'Blog details fetched successfully',
        data: json,
      );
    }
    // Handle standard { success, message, data } response
    return BlogResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown error',
      data: json['data'],
    );
  }
}

class CommunityService {
  static final String _base = '${ApiConfig.baseUrl}/blog';
  static final FlutterSecureStorage _storage = FlutterSecureStorage();
  final http.Client _client = http.Client();

  // Helper to get auth token
  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // Create a blog
  Future<BlogResponse> createBlog({
    required String title,
    required String content,
    required String userId,
    required String role,
    File? image,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return BlogResponse(
          success: false,
          message: 'Not authenticated. Please log in.',
        );
      }

      // Prepare the JSON body
      final body = {
        'title': title,
        'content': content,
        'userId': userId,
        'role': role,
      };

      // Add base64-encoded image if available
      if (image != null) {
        try {
          final imageBytes = await image.readAsBytes();
          final base64Image = base64Encode(imageBytes);
          body['image'] = 'data:image/jpeg;base64,$base64Image';
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Image encoding error: $e');
          }
          return BlogResponse(
            success: false,
            message: 'Failed to encode image: $e',
          );
        }
      }
      print("::: Res");
      final response = await _client.post(
        Uri.parse('$_base/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (kDebugMode) {
        // debugPrint('Create Blog Response status: ${response.statusCode}');
        // debugPrint('Create Blog Response body: ${response.body}');
        // debugPrint('Create Blog Response headers: ${response.headers}');
      }

      if (response.statusCode >= 300 && response.statusCode < 400) {
        final redirectUrl = response.headers['location'];
        return BlogResponse(
          success: false,
          message: 'Redirect detected to: ${redirectUrl ?? 'unknown URL'}',
        );
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        return BlogResponse(
          success: false,
          message:
              'Server error: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }

      try {
        print("::: Yes");
        final json = jsonDecode(response.body);
        return BlogResponse.fromJson(json);
      } catch (e) {
        return BlogResponse(
          success: false,
          message: 'Invalid response format: ${e.toString()}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        //    debugPrint('Create Blog error: $e');
      }
      return BlogResponse(success: false, message: 'Network error: $e');
    }
  }

  // Get all blogs
  Future<BlogResponse> getBlogs({String? category, int page = 1}) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse(_base).replace(
        queryParameters: {
          if (category != null && category != 'All') 'category': category,
          'page': page.toString(),
        },
      );
      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode) {
        // debugPrint('Get Blogs Response status: ${response.statusCode}');
        // debugPrint('Get Blogs Response body: ${response.body}');
        // debugPrint('Get Blogs Response headers: ${response.headers}');
      }

      if (response.statusCode >= 300 && response.statusCode < 400) {
        final redirectUrl = response.headers['location'];
        return BlogResponse(
          success: false,
          message: 'Redirect detected to: ${redirectUrl ?? 'unknown URL'}',
        );
      }

      if (response.statusCode != 200) {
        return BlogResponse(
          success: false,
          message:
              'Server error: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }

      try {
        final json = jsonDecode(response.body);
        return BlogResponse.fromJson(json);
      } catch (e) {
        return BlogResponse(
          success: false,
          message: 'Invalid response format: ${e.toString()}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Get Blogs error: $e');
      }
      return BlogResponse(success: false, message: 'Network error: $e');
    }
  }

  // Get blog details
  Future<BlogResponse> getBlogDetails(String blogId) async {
    try {
      final token = await _getToken();
      final response = await _client.get(
        Uri.parse('$_base/$blogId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode) {
        debugPrint('Get Blog Details Response status: ${response.statusCode}');
        debugPrint(
          'Get Blog Details Response body: ${response.body}',
        ); // Log the body
        debugPrint('Get Blog Details Response headers: ${response.headers}');
      }

      if (response.statusCode >= 300 && response.statusCode < 400) {
        final redirectUrl = response.headers['location'];
        return BlogResponse(
          success: false,
          message: 'Redirect detected to: ${redirectUrl ?? 'unknown URL'}',
        );
      }

      if (response.statusCode != 200) {
        return BlogResponse(
          success: false,
          message:
              'Server error: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }

      try {
        final json = jsonDecode(response.body);
        return BlogResponse.fromJson(json);
      } catch (e) {
        return BlogResponse(
          success: false,
          message: 'Invalid response format: ${e.toString()}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Get Blog Details error: $e');
      }
      return BlogResponse(success: false, message: 'Network error: $e');
    }
  }

  // Like or unlike a blog
  Future<BlogResponse> toggleLikeBlog({
    required String blogId,
    required String userId,
    required bool isLiked,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return BlogResponse(
          success: false,
          message: 'Not authenticated. Please log in.',
        );
      }

      final url = isLiked ? 'unlike' : 'like';
      final response = await _client.put(
        Uri.parse('$_base/$url/$blogId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'userId': userId}),
      );

      if (kDebugMode) {
        debugPrint('Toggle Like Response status: ${response.statusCode}');
        debugPrint('Toggle Like Response body: ${response.body}');
        debugPrint('Toggle Like Response headers: ${response.headers}');
      }

      if (response.statusCode >= 300 && response.statusCode < 400) {
        final redirectUrl = response.headers['location'];
        return BlogResponse(
          success: false,
          message: 'Redirect detected to: ${redirectUrl ?? 'unknown URL'}',
        );
      }

      if (response.statusCode != 200) {
        return BlogResponse(
          success: false,
          message:
              'Server error: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }

      try {
        final json = jsonDecode(response.body);
        return BlogResponse.fromJson(json);
      } catch (e) {
        return BlogResponse(
          success: false,
          message: 'Invalid response format: ${e.toString()}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Toggle Like error: $e');
      }
      return BlogResponse(success: false, message: 'Network error: $e');
    }
  }

  // Post a comment
  Future<BlogResponse> postComment({
    required String blogId,
    required String userId,
    required String commentText,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return BlogResponse(
          success: false,
          message: 'Not authenticated. Please log in.',
        );
      }

      final response = await _client.post(
        Uri.parse('$_base/comment/$blogId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'userId': userId, 'text': commentText}),
      );

      if (kDebugMode) {
        debugPrint('Post Comment Response status: ${response.statusCode}');
        debugPrint('Post Comment Response body: ${response.body}');
        debugPrint('Post Comment Response headers: ${response.headers}');
      }

      if (response.statusCode >= 300 && response.statusCode < 400) {
        final redirectUrl = response.headers['location'];
        return BlogResponse(
          success: false,
          message: 'Redirect detected to: ${redirectUrl ?? 'unknown URL'}',
        );
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        return BlogResponse(
          success: false,
          message:
              'Server error: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }

      try {
        final json = jsonDecode(response.body);
        return BlogResponse.fromJson(json);
      } catch (e) {
        return BlogResponse(
          success: false,
          message: 'Invalid response format: ${e.toString()}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Post Comment error: $e');
      }
      return BlogResponse(success: false, message: 'Network error: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
