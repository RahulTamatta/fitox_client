import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

enum ProfessionalType { trainer, dermatologist, dietician }

// Error class
class ServiceFailure {
  final String message;
  ServiceFailure(this.message);
}

// Professional model class (updated to match API response)
class Professional {
  final String id;
  final String name;
  final String email;
  final String role;
  final String bio;
  final String phoneNumber;
  final int age;
  final String gender;
  final String city;
  final String profileImage;
  final List<String> languages;
  final int followers;
  final int following;
  final String trainerType;
  final String experience;
  final String currentOccupation;
  final double rating;
  final String availableTimings;
  final String tagline;
  final double feesChat;
  final double feesCall;
  final bool verified;
  final bool phoneVerified;
  final double wallet;
  final List<dynamic> subscriptions;
  final List<dynamic> withdrawals;
  final DateTime createdAt;
  final DateTime updatedAt;

  Professional({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.bio,
    required this.phoneNumber,
    required this.age,
    required this.gender,
    required this.city,
    required this.profileImage,
    required this.languages,
    required this.followers,
    required this.following,
    required this.trainerType,
    required this.experience,
    required this.currentOccupation,
    required this.rating,
    required this.availableTimings,
    required this.tagline,
    required this.feesChat,
    required this.feesCall,
    required this.verified,
    required this.phoneVerified,
    required this.wallet,
    required this.subscriptions,
    required this.withdrawals,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Professional.fromJson(Map<String, dynamic> json) {
    return Professional(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      bio: json['bio'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      city: json['city'] ?? '',
      profileImage: json['profileImage'] ?? '',
      languages: List<String>.from(json['languages'] ?? []),
      followers: json['followers'] ?? 0,
      following: json['following'] ?? 0,
      trainerType: json['trainerType'] ?? '',
      experience: json['experience'] ?? '',
      currentOccupation: json['currentOccupation'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      availableTimings: json['availableTimings'] ?? '',
      tagline: json['tagline'] ?? '',
      feesChat: (json['feesChat'] ?? 0).toDouble(),
      feesCall: (json['feesCall'] ?? 0).toDouble(),
      verified: json['verified'] ?? false,
      phoneVerified: json['phoneVerified'] ?? false,
      wallet: (json['wallet'] ?? 0).toDouble(),
      subscriptions: json['subscriptions'] ?? [],
      withdrawals: json['withdrawals'] ?? [],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

// Service class
class HomeServices {
  //https//192.168.0.104:5001/api
  static const String _baseUrl = 'https://fitox-server.onrender.com';
  static const String _verifiedProfessionalsEndpoint =
      '/api/user/verified-trainers';

  // Convert enum to string expected by API
  String _getTypeString(ProfessionalType type) {
    switch (type) {
      case ProfessionalType.trainer:
        return 'Trainer';
      case ProfessionalType.dermatologist:
        return 'Dermatologist';
      case ProfessionalType.dietician:
        return 'Dietician';
    }
  }

  // Generic method to fetch professionals
  Future<Either<ServiceFailure, List<Professional>>> _fetchProfessionals(
    ProfessionalType type,
  ) async {
    try {
      final String typeString = _getTypeString(type);
      // Only include trainerType in payload for non-trainer categories.
      final Map<String, dynamic> payload =
          type == ProfessionalType.trainer ? {} : {'trainerType': typeString};
      if (kDebugMode) {
        print('Fetching $type with payload: ' + payload.toString());
      }
      final response = await http.post(
        Uri.parse('$_baseUrl$_verifiedProfessionalsEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      switch (response.statusCode) {
        case 200:
          final List<dynamic> data = jsonDecode(response.body);
          final professionals =
              data.map((json) => Professional.fromJson(json)).toList();
          return Right(professionals);
        case 400:
          return Left(ServiceFailure('Bad request: Invalid parameters'));
        case 401:
          return Left(ServiceFailure('Unauthorized: Please login again'));
        case 403:
          return Left(ServiceFailure('Forbidden: Access denied'));
        case 404:
          return Left(ServiceFailure('No $typeString professionals found'));
        case 500:
          return Left(ServiceFailure('Server error: Please try again later'));
        default:
          return Left(
            ServiceFailure('Unexpected error: ${response.statusCode}'),
          );
      }
    } on http.ClientException {
      return Left(
        ServiceFailure('Network error: Please check your connection'),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching $type professionals: $e');
      }
      return Left(ServiceFailure('Unexpected error occurred'));
    }
  }

  // Fetch verified trainers
  Future<Either<ServiceFailure, List<Professional>>>
  getVerifiedTrainers() async {
    return _fetchProfessionals(ProfessionalType.trainer);
  }

  // Fetch verified dermatologists
  Future<Either<ServiceFailure, List<Professional>>>
  getVerifiedDermatologists() async {
    return _fetchProfessionals(ProfessionalType.dermatologist);
  }

  // Fetch verified dieticians
  Future<Either<ServiceFailure, List<Professional>>>
  getVerifiedDieticians() async {
    return _fetchProfessionals(ProfessionalType.dietician);
  }

  // Fetch all types at once
  Future<Either<ServiceFailure, Map<ProfessionalType, List<Professional>>>>
  getAllVerifiedProfessionals() async {
    try {
      final results = await Future.wait([
        getVerifiedTrainers(),
        getVerifiedDermatologists(),
        getVerifiedDieticians(),
      ]);

      final Map<ProfessionalType, List<Professional>> allProfessionals = {};

      for (int i = 0; i < results.length; i++) {
        final type = ProfessionalType.values[i];
        final result = results[i];

        if (result.isLeft()) {
          return Left((result as Left).value);
        }

        allProfessionals[type] = (result as Right).value;
      }

      return Right(allProfessionals);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching all professionals: $e');
      }
      return Left(ServiceFailure('Failed to fetch all professionals'));
    }
  }
}
