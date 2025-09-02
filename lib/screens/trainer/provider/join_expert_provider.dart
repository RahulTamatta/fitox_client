import 'package:flutter/material.dart';
import 'dart:io';
import '../services/join_expert_service.dart';
import '../../account/services/profile_service.dart';

class JoinExpertProvider extends ChangeNotifier {
  final JoinExpertService _joinExpertService = JoinExpertService();

  // State management
  ResponseState _state = ResponseState.initial;
  String? _errorMessage;
  int _currentStep = 1;
  bool _isSubmitting = false;

  // Form data
  String _fullName = '';
  String _email = '';
  String _password = '';
  String _contactNumber = '';
  int? _age;
  String? _gender;
  List<String> _selectedLanguages = [];
  List<String> _selectedSpecializations = [];
  int? _yearsOfExperience;
  double? _feePerHour;
  List<File> _profileImages = [];
  List<File> _certificationImages = [];

  // Getters
  ResponseState get state => _state;
  String? get errorMessage => _errorMessage;
  int get currentStep => _currentStep;
  bool get isSubmitting => _isSubmitting;
  
  // Form data getters
  String get fullName => _fullName;
  String get email => _email;
  String get password => _password;
  String get contactNumber => _contactNumber;
  int? get age => _age;
  String? get gender => _gender;
  List<String> get selectedLanguages => _selectedLanguages;
  List<String> get selectedSpecializations => _selectedSpecializations;
  int? get yearsOfExperience => _yearsOfExperience;
  double? get feePerHour => _feePerHour;
  List<File> get profileImages => _profileImages;
  List<File> get certificationImages => _certificationImages;

  // Available options
  final List<String> availableLanguages = [
    "English", "Hindi", "Tamil", "Telugu", "Kannada",
    "Malayalam", "Bengali", "Marathi", "Gujarati", "Punjabi"
  ];

  final List<String> availableSpecializations = [
    "Yoga", "Weight Loss", "Muscle Building", "Nutrition", "Pilates",
    "CrossFit", "HIIT", "Cardio", "Sports Performance", "Rehabilitation",
    "Senior Fitness", "Pre/Post Natal", "Meditation", "Skin Care",
    "Hair Health", "Holistic Wellness", "Mental Health", "Massage Therapy"
  ];

  // Step navigation
  void nextStep() {
    if (_currentStep < 4) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 1) {
      _currentStep--;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    if (step >= 1 && step <= 4) {
      _currentStep = step;
      notifyListeners();
    }
  }

  // Form data setters
  void updateFullName(String value) {
    _fullName = value;
    notifyListeners();
  }

  void updateEmail(String value) {
    _email = value;
    notifyListeners();
  }

  void updatePassword(String value) {
    _password = value;
    notifyListeners();
  }

  void updateContactNumber(String value) {
    _contactNumber = value;
    notifyListeners();
  }

  void updateAge(int value) {
    _age = value;
    notifyListeners();
  }

  void updateGender(String value) {
    _gender = value;
    notifyListeners();
  }

  void toggleLanguage(String language) {
    if (_selectedLanguages.contains(language)) {
      _selectedLanguages.remove(language);
    } else {
      _selectedLanguages.add(language);
    }
    notifyListeners();
  }

  void toggleSpecialization(String specialization) {
    if (_selectedSpecializations.contains(specialization)) {
      _selectedSpecializations.remove(specialization);
    } else {
      _selectedSpecializations.add(specialization);
    }
    notifyListeners();
  }

  void updateYearsOfExperience(int value) {
    _yearsOfExperience = value;
    notifyListeners();
  }

  void updateFeePerHour(double value) {
    _feePerHour = value;
    notifyListeners();
  }

  void addProfileImage(File image) {
    if (_profileImages.length < 5) {
      _profileImages.add(image);
      notifyListeners();
    }
  }

  void removeProfileImage(int index) {
    if (index >= 0 && index < _profileImages.length) {
      _profileImages.removeAt(index);
      notifyListeners();
    }
  }

  void addCertificationImage(File image) {
    _certificationImages.add(image);
    notifyListeners();
  }

  void removeCertificationImage(int index) {
    if (index >= 0 && index < _certificationImages.length) {
      _certificationImages.removeAt(index);
      notifyListeners();
    }
  }

  // Validation methods
  String? validatePersonalInfo() {
    if (_fullName.trim().isEmpty) return 'Full name is required';
    if (_email.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_email)) {
      return 'Please enter a valid email';
    }
    if (_password.length < 6) return 'Password must be at least 6 characters';
    if (_contactNumber.trim().isEmpty) return 'Contact number is required';
    if (!RegExp(r'^\+91\d{10}$').hasMatch(_contactNumber)) {
      return 'Please enter a valid Indian mobile number';
    }
    if (_age == null || _age! < 18) return 'Age must be 18 or above';
    if (_gender == null) return 'Please select gender';
    if (_selectedLanguages.isEmpty) return 'Please select at least one language';
    return null;
  }

  String? validateProfessionalInfo() {
    if (_selectedSpecializations.isEmpty) {
      return 'Please select at least one specialization';
    }
    if (_yearsOfExperience == null || _yearsOfExperience! < 0) {
      return 'Please enter valid years of experience';
    }
    if (_feePerHour == null || _feePerHour! <= 0) {
      return 'Please enter a valid fee per hour';
    }
    return null;
  }

  String? validateFiles() {
    if (_profileImages.isEmpty) {
      return 'Please upload at least one profile image';
    }
    return null;
  }

  // Submit application
  Future<bool> submitApplication() async {
    _setState(ResponseState.loading);
    _isSubmitting = true;

    try {
      final response = await _joinExpertService.submitExpertApplication(
        fullName: _fullName,
        email: _email,
        password: _password,
        contactNumber: _contactNumber,
        age: _age!,
        gender: _gender!,
        languages: _selectedLanguages,
        specializations: _selectedSpecializations,
        yearsOfExperience: _yearsOfExperience!,
        feePerHour: _feePerHour!,
        profileImages: _profileImages,
        certificationImages: _certificationImages,
      );

      if (response.state == ResponseState.success) {
        _setState(ResponseState.success);
        _isSubmitting = false;
        return true;
      } else {
        _errorMessage = response.error;
        _setState(ResponseState.error);
        _isSubmitting = false;
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to submit application: $e';
      _setState(ResponseState.error);
      _isSubmitting = false;
      return false;
    }
  }

  // Helper methods
  void _setState(ResponseState state) {
    _state = state;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _state = ResponseState.initial;
    _errorMessage = null;
    _currentStep = 1;
    _isSubmitting = false;
    
    // Reset form data
    _fullName = '';
    _email = '';
    _password = '';
    _contactNumber = '';
    _age = null;
    _gender = null;
    _selectedLanguages.clear();
    _selectedSpecializations.clear();
    _yearsOfExperience = null;
    _feePerHour = null;
    _profileImages.clear();
    _certificationImages.clear();
    
    notifyListeners();
  }
}
