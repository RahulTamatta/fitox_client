import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../global/api_config.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart'; // For debugPrint

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

  bool _submitting = false;

  // Helper to get auth token
  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  void _logRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    String? reqId,
  }) {
    if (kDebugMode) {
      debugPrint('🌐 API [$reqId] $method $endpoint');
      if (body != null) debugPrint('📦 Body: ${jsonEncode(body)}');
    }
  }

  void _logResponse(String endpoint, http.Response response, {String? reqId}) {
    if (kDebugMode) {
      debugPrint('✅ API [$reqId] ${response.statusCode} $endpoint');
      debugPrint('📄 Response: ${response.body}');
      debugPrint('🔑 Headers: ${response.headers}');
    }
  }

  void _logError(
    String endpoint,
    dynamic error, {
    String? reqId,
    StackTrace? stack,
  }) {
    if (kDebugMode) {
      debugPrint('❌ API [$reqId] Error $endpoint: $error');
      if (stack != null) debugPrint('📚 Stack: $stack');
    }
  }

  // Create a blog with proper multipart request
  Future<BlogResponse> createBlog({
    required String title,
    required String content,
    required String userId,
    required String role,
    File? image,
  }) async {
    if (_submitting) {
      debugPrint('❌ Create blog: Request already in progress');
      return BlogResponse(
        success: false,
        message: 'A submission is already in progress',
      );
    }

    try {
      _submitting = true;
      final reqId = DateTime.now().microsecondsSinceEpoch.toString();
      debugPrint('🌐 createBlog[$reqId] starting request');

      final token = await _getToken();
      if (token == null) {
        debugPrint('❌ createBlog[$reqId] no auth token');
        return BlogResponse(
          success: false,
          message: 'Not authenticated. Please log in.',
        );
      }

      // Create multipart request
      final request =
          http.MultipartRequest('POST', Uri.parse('$_base/create'))
            ..fields['title'] = title
            ..fields['content'] = content
            ..fields['userId'] = userId
            ..fields['role'] = role;

      // Add headers without Content-Type (it will be set automatically for multipart)
      request.headers['Authorization'] = 'Bearer $token';

      if (image != null) {
        debugPrint('📸 createBlog[$reqId] adding image: ${image.path}');
        try {
          final stream = http.ByteStream(image.openRead());
          final length = await image.length();

          final filename = image.path.split('/').last;
          final mimeType = lookupMimeType(filename) ?? 'image/jpeg';

          final multipartFile = http.MultipartFile(
            'image',
            stream,
            length,
            filename: filename,
            contentType: MediaType.parse(mimeType),
          );
          request.files.add(multipartFile);

          debugPrint(
            '📸 createBlog[$reqId] image details: $filename, $mimeType, $length bytes',
          );
        } catch (e) {
          debugPrint('❌ createBlog[$reqId] image processing error: $e');
        }
      }

      debugPrint('📤 createBlog[$reqId] sending request');
      debugPrint('📋 Request fields: ${request.fields}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 createBlog[$reqId] status=${response.statusCode}');
      debugPrint('📥 createBlog[$reqId] body=${response.body}');
      debugPrint('📥 createBlog[$reqId] headers=${response.headers}');

      if (response.statusCode == 500) {
        debugPrint('❌ createBlog[$reqId] server error: ${response.body}');
        return BlogResponse(
          success: false,
          message: 'Server error: Please try again (Error 500)',
        );
      }

      if (response.statusCode != 201) {
        return BlogResponse(
          success: false,
          message: 'Server error: ${response.statusCode}\n${response.body}',
        );
      }

      final responseData = jsonDecode(response.body);
      debugPrint('✅ createBlog[$reqId] success: $responseData');
      return BlogResponse.fromJson(responseData);
    } catch (e, stack) {
      debugPrint('❌ Create Blog error: $e');
      debugPrint('❌ Stack trace: $stack');
      return BlogResponse(success: false, message: 'Network error: $e');
    } finally {
      _submitting = false;
    }
  }

  // Enhanced getBlogs with pagination and filters
  Future<BlogResponse> getBlogs({
    String? category,
    int page = 1,
    String? authorRole,
    List<String>? tags,
    String? author,
    bool showLikedUsers = false,
  }) async {
    final reqId = DateTime.now().microsecondsSinceEpoch.toString();
    try {
      _logRequest(
        'GET',
        '/',
        body: {
          'page': page,
          'category': category,
          'authorRole': authorRole,
          'tags': tags,
          'author': author,
          'showLikedUsers': showLikedUsers,
        },
        reqId: reqId,
      );

      final token = await _getToken();
      final queryParams = {
        'page': page.toString(),
        if (category != null && category != 'All') 'category': category,
        if (authorRole != null) 'authorRole': authorRole,
        if (tags != null) 'tags': tags.join(','),
        if (author != null) 'author': author,
        'showLikedUsers': showLikedUsers.toString(),
      };

      final uri = Uri.parse(_base).replace(queryParameters: queryParams);
      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      _logResponse('/', response, reqId: reqId);

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
    } catch (e, stack) {
      _logError('/', e, reqId: reqId, stack: stack);
      return BlogResponse(success: false, message: 'Network error: $e');
    }
  }

  // Get blog details
  Future<BlogResponse> getBlogDetails(String blogId) async {
    final reqId = DateTime.now().microsecondsSinceEpoch.toString();
    try {
      _logRequest('GET', '/$blogId', reqId: reqId);

      final token = await _getToken();
      final response = await _client.get(
        Uri.parse('$_base/$blogId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      _logResponse('/$blogId', response, reqId: reqId);

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
    } catch (e, stack) {
      _logError('/$blogId', e, reqId: reqId, stack: stack);
      return BlogResponse(success: false, message: 'Network error: $e');
    }
  }

  // Like or unlike a blog
  Future<BlogResponse> toggleLikeBlog({
    required String blogId,
    required String userId,
    required bool isLiked,
  }) async {
    final reqId = DateTime.now().microsecondsSinceEpoch.toString();
    try {
      final url = isLiked ? '/unlike/$blogId' : '/like/$blogId';
      _logRequest('PUT', url, body: {'userId': userId}, reqId: reqId);

      final token = await _getToken();
      if (token == null) {
        return BlogResponse(
          success: false,
          message: 'Not authenticated. Please log in.',
        );
      }

      final response = await _client.put(
        Uri.parse('$_base$url'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'userId': userId}),
      );
      _logResponse(url, response, reqId: reqId);

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
    } catch (e, stack) {
      _logError(
        isLiked ? '/unlike/$blogId' : '/like/$blogId',
        e,
        reqId: reqId,
        stack: stack,
      );
      return BlogResponse(success: false, message: 'Network error: $e');
    }
  }

  // Post a comment
  Future<BlogResponse> postComment({
    required String blogId,
    required String userId,
    required String commentText,
  }) async {
    final reqId = DateTime.now().microsecondsSinceEpoch.toString();
    try {
      _logRequest(
        'POST',
        '/comment/$blogId',
        body: {'userId': userId, 'text': commentText},
        reqId: reqId,
      );

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
      _logResponse('/comment/$blogId', response, reqId: reqId);

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
    } catch (e, stack) {
      _logError('/comment/$blogId', e, reqId: reqId, stack: stack);
      return BlogResponse(success: false, message: 'Network error: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
