import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../account/services/profile_service.dart';

class JoinExpertService {
  static const String _baseUrl = 'http://10.0.2.2:5001';
  static const Duration _timeoutDuration = Duration(seconds: 60);
  final http.Client _client = http.Client();

  Future<ApiResponse<Map<String, dynamic>>> submitExpertApplication({
    required String fullName,
    required String email,
    required String password,
    required String contactNumber,
    required int age,
    required String gender,
    required List<String> languages,
    required List<String> specializations,
    required int yearsOfExperience,
    required double feePerHour,
    required List<File> profileImages,
    List<File>? certificationImages,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/user/register'),
      );

      // Add form fields
      final fields = {
        'name': fullName,
        'email': email,
        'password': password,
        'bio': contactNumber, // Using bio field for phone as per existing pattern
        'age': age.toString(),
        'gender': gender,
        'city': 'India', // Default city
        'role': 'trainer',
        'experience': yearsOfExperience.toString(),
        'charges': feePerHour.toString(),
        'currentOccupation': 'Fitness Trainer',
        'availableTimings': '9AM-9PM', // Default timing
        'tagline': 'Empowering fitness journeys',
        'interests': 'fitness,health,wellness',
        'languages': languages.join(','),
        'specializations': specializations.join(','),
      };

      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      // Add profile images
      for (int i = 0; i < profileImages.length; i++) {
        final image = profileImages[i];
        final compressedImage = await _compressImage(image);
        
        if (compressedImage != null) {
          final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';
          request.files.add(
            http.MultipartFile.fromBytes(
              i == 0 ? 'profileImage' : 'profileImage$i',
              compressedImage,
              filename: 'profile_${i + 1}.jpg',
              contentType: MediaType.parse(mimeType),
            ),
          );
        }
      }

      // Add certification images if provided
      if (certificationImages != null) {
        for (int i = 0; i < certificationImages.length; i++) {
          final image = certificationImages[i];
          final compressedImage = await _compressImage(image);
          
          if (compressedImage != null) {
            final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';
            request.files.add(
              http.MultipartFile.fromBytes(
                'certification$i',
                compressedImage,
                filename: 'certification_${i + 1}.jpg',
                contentType: MediaType.parse(mimeType),
              ),
            );
          }
        }
      }

      if (kDebugMode) {
        debugPrint('Submitting expert application for: $email');
        debugPrint('Profile images: ${profileImages.length}');
        debugPrint('Certification images: ${certificationImages?.length ?? 0}');
      }

      final response = await request.send().timeout(_timeoutDuration);
      final responseBody = await response.stream.bytesToString();

      if (kDebugMode) {
        debugPrint('Expert application response status: ${response.statusCode}');
        debugPrint('Expert application response body: $responseBody');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final json = jsonDecode(responseBody);
          return ApiResponse.success(json as Map<String, dynamic>);
        } catch (e) {
          return ApiResponse.error('Invalid response format: $e');
        }
      } else {
        try {
          final json = jsonDecode(responseBody);
          return ApiResponse.error(json['message'] ?? 'Registration failed');
        } catch (e) {
          return ApiResponse.error('Server error: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Expert application error: $e');
      }
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<List<int>?> _compressImage(File image) async {
    try {
      return await FlutterImageCompress.compressWithFile(
        image.path,
        minWidth: 800,
        minHeight: 800,
        quality: 80,
        format: CompressFormat.jpeg,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Image compression error: $e');
      }
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
