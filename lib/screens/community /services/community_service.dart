import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

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
  static const String _baseUrlLocal = 'http://localhost:5000/api/blog';
  static const String _baseUrlRemote = 'http://10.0.2.2:5001/blog';
  static const String _baseUrlGetBlogs =
      'https://fitness-backend-node.onrender.com/api/blog';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  final http.Client _client = http.Client();

  // Helper to get auth token
  Future<String?> _getToken() async {
    return await _storage.read(key: 'access_token');
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

      if (kDebugMode) {
        debugPrint('Creating blog with userId: $userId, role: $role');
        debugPrint('Blog title: $title');
        debugPrint('Blog content length: ${content.length}');
      }

      // Use multipart request for file upload
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrlRemote/create'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      request.fields['title'] = title;
      request.fields['content'] = content;
      request.fields['userId'] = userId;
      request.fields['role'] = role;

      // Add image file if available
      if (image != null) {
        try {
          final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';
          final multipartFile = await http.MultipartFile.fromPath(
            'image',
            image.path,
            contentType: MediaType.parse(mimeType),
          );
          request.files.add(multipartFile);

          if (kDebugMode) {
            debugPrint('Adding image file: ${image.path}, mimeType: $mimeType');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Image file error: $e');
          }
          return BlogResponse(
            success: false,
            message: 'Failed to process image file: $e',
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

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
        if (kDebugMode) {
          debugPrint(
            'Blog creation successful - Status: ${response.statusCode}',
          );
          debugPrint('Response body: ${response.body}');
        }
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
        debugPrint('Create Blog error: $e');
      }
      return BlogResponse(success: false, message: 'Network error: $e');
    }
  }

  // Get all blogs
  Future<BlogResponse> getBlogs({String? category, int page = 1}) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse(_baseUrlGetBlogs).replace(
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
        Uri.parse('$_baseUrlRemote/$blogId'),
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
        Uri.parse('$_baseUrlRemote/$url/$blogId'),
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
        Uri.parse('$_baseUrlRemote/comment/$blogId'),
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
