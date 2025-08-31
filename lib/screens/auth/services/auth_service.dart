import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class AuthResponse {
  final bool success;
  final String message;
  final UserData? data;

  AuthResponse({required this.success, required this.message, this.data});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('token') && json.containsKey('user')) {
      return AuthResponse(
        success: true,
        message: json['message'] ?? 'Login successful',
        data: UserData.fromJson(json),
      );
    }
    if (json.containsKey('success')) {
      return AuthResponse(
        success: json['success'] ?? false,
        message: json['message'] ?? 'Unknown error',
        data: json['data'] != null ? UserData.fromJson(json['data']) : null,
      );
    }
    return AuthResponse(
      success: false,
      message: json['error'] ?? json['message'] ?? 'Unexpected response format',
      data: null,
    );
  }
}

class UserData {
  final String token;
  final User user;

  UserData({required this.token, required this.user});

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      token: json['token'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
    );
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String? role;
  final String? phoneNumber;
  final String? city;
  final int? age;
  final String? gender;
  final String? bio;
  final String? profileImage;
  final int? followers;
  final int? following;
  final int? rating;
  final bool? verified;
  final int? uId;
  final bool? phoneVerified;
  final int? wallet;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.phoneNumber,
    this.city,
    this.age,
    this.gender,
    this.bio,
    this.profileImage,
    this.followers,
    this.following,
    this.rating,
    this.verified,
    this.uId,
    this.phoneVerified,
    this.wallet,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'],
      phoneNumber: json['phoneNumber'],
      city: json['city'],
      age: json['age'],
      gender: json['gender'],
      bio: json['bio'],
      profileImage: json['profileImage'],
      followers: json['followers'],
      following: json['following'],
      rating: json['rating'],
      verified: json['verified'],
      uId: json['uId'],
      phoneVerified: json['phoneVerified'],
      wallet: json['wallet'],
    );
  }
}

class AuthService {
  static const String _baseUrl = 'https://fitox-server.onrender.com/api';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  final http.Client _client = http.Client();

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String city,
    required String gender,
    File? profileImage,
    bool isTrainer = false,
    String? charges,
    String? experience,
    String? currentOccupation,
    List<String>? availableTimings,
    String? tagline,
    List<String>? interests,
  }) async {
    try {
      final body = {
        'name': name,
        'email': email,
        'password': password,
        'bio': phone,
        'age': '30',
        'gender': gender,
        'city': city,
        'interests': interests?.join(',') ?? 'fitness,health',
      };

      if (isTrainer) {
        body['role'] = 'trainer';
        body['experience'] = experience ?? '0';
        body['currentOccupation'] = currentOccupation ?? 'Trainer';
        body['availableTimings'] = availableTimings?.join(',') ?? '9AM-5PM';
        body['tagline'] = tagline ?? 'Empowering fitness journeys';
        if (charges != null) body['charges'] = charges;
      }

      if (profileImage != null) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$_baseUrl/user/register'),
        );

        body.forEach((key, value) {
          request.fields[key] = value.toString();
        });

        final compressedImage = await FlutterImageCompress.compressWithFile(
          profileImage.path,
          minWidth: 512,
          minHeight: 512,
          quality: 70,
          format: CompressFormat.jpeg,
        );

        if (compressedImage == null) {
          return AuthResponse(
            success: false,
            message: 'Failed to compress image',
          );
        }

        final mimeType = lookupMimeType(profileImage.path) ?? 'image/jpeg';
        request.files.add(
          http.MultipartFile.fromBytes(
            'profileImage',
            compressedImage,
            filename: profileImage.path.split('/').last,
            contentType: MediaType.parse(mimeType),
          ),
        );

        if (kDebugMode) {
          debugPrint('Profile Image Path: ${profileImage.path}');
          debugPrint('Compressed Image Size: ${compressedImage.length} bytes');
          debugPrint('MIME Type: $mimeType');
        }

        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        if (kDebugMode) {
          debugPrint('Register Response status: ${response.statusCode}');
          debugPrint('Register Response body: $responseBody');
        }

        if (response.statusCode >= 300 && response.statusCode < 400) {
          return AuthResponse(success: false, message: 'Redirect detected');
        }

        if (response.statusCode != 200 && response.statusCode != 201) {
          return AuthResponse(
            success: false,
            message:
                'Server error: ${response.statusCode} - ${response.reasonPhrase}',
          );
        }

        try {
          final json = jsonDecode(responseBody);
          final authResponse = AuthResponse.fromJson(json);
          if (authResponse.success && authResponse.data != null) {
            await _storage.write(
              key: 'auth_token',
              value: authResponse.data!.token,
            );
          }
          return authResponse;
        } catch (e) {
          return AuthResponse(
            success: false,
            message: 'Invalid response format: ${e.toString()}',
          );
        }
      } else {
        final response = await _client.post(
          Uri.parse('$_baseUrl/user/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );

        if (kDebugMode) {
          debugPrint('Request Body Size: ${jsonEncode(body).length} bytes');
          debugPrint('Register Response status: ${response.statusCode}');
          debugPrint('Register Response body: ${response.body}');
        }

        if (response.statusCode >= 300 && response.statusCode < 400) {
          final redirectUrl = response.headers['location'];
          return AuthResponse(
            success: false,
            message: 'Redirect detected to: ${redirectUrl ?? 'unknown URL'}',
          );
        }

        if (response.statusCode != 200 && response.statusCode != 201) {
          return AuthResponse(
            success: false,
            message:
                'Server error: ${response.statusCode} - ${response.reasonPhrase}',
          );
        }

        try {
          final json = jsonDecode(response.body);
          final authResponse = AuthResponse.fromJson(json);
          if (authResponse.success && authResponse.data != null) {
            await _storage.write(
              key: 'auth_token',
              value: authResponse.data!.token,
            );
          }
          return authResponse;
        } catch (e) {
          return AuthResponse(
            success: false,
            message: 'Invalid response format: ${e.toString()}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Register error: $e');
      }
      return AuthResponse(success: false, message: 'Network error: $e');
    }
  }

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/user/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (kDebugMode) {
        debugPrint('Login Response status: ${response.statusCode}');
        debugPrint('Login Response body: ${response.body}');
        debugPrint('Login Response headers: ${response.headers}');
      }

      if (response.statusCode >= 300 && response.statusCode < 400) {
        final redirectUrl = response.headers['location'];
        return AuthResponse(
          success: false,
          message: 'Redirect detected to: ${redirectUrl ?? 'unknown URL'}',
        );
      }

      if (response.statusCode == 404) {
        return AuthResponse(
          success: false,
          message:
              'Login endpoint not found. Please check the server configuration.',
        );
      }

      if (response.statusCode != 200) {
        try {
          final json = jsonDecode(response.body);
          return AuthResponse.fromJson(json);
        } catch (_) {
          return AuthResponse(
            success: false,
            message:
                'Server error: ${response.statusCode} - ${response.reasonPhrase}',
          );
        }
      }

      try {
        final json = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(json);

        if (authResponse.success && authResponse.data != null) {
          await _storage.write(
            key: 'auth_token',
            value: authResponse.data!.token,
          );
        }

        return authResponse;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('JSON parsing error: $e');
        }
        return AuthResponse(
          success: false,
          message: 'Invalid response format: ${e.toString()}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Login error: $e');
      }
      return AuthResponse(success: false, message: 'Network error: $e');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  void dispose() {
    _client.close();
  }
}
