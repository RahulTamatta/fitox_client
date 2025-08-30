import 'package:flutter/material.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  // State variables
  ResponseState _state = ResponseState.initial;
  String? _errorMessage;
  Map<String, dynamic>? _userProfile;
  List<dynamic>? _followingList;
  List<dynamic>? _followersList;
  Map<String, dynamic>? _authData;

  // Getters
  ResponseState get getState => _state;
  String? get getErrorMessage => _errorMessage;
  Map<String, dynamic>? get getUserProfile => _userProfile;
  List<dynamic>? get getFollowingList => _followingList;
  List<dynamic>? get getFollowersList => _followersList;
  Map<String, dynamic>? get getAuthData => _authData;

  // Get profile info
  Future<void> getProfileInfo(String userId) async {
    setState(ResponseState.loading);

    try {
      final response = await _profileService.getProfileInfo(userId);

      if (response.state == ResponseState.success) {
        _userProfile = response.data;
        setState(ResponseState.success);
      } else {
        _errorMessage = response.error;
        setState(ResponseState.error);
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch profile: $e';
      setState(ResponseState.error);
    }
  }

  // Update profile
  Future<void> updateProfile({
    required String userId,
    Map<String, dynamic>? updateData,
  }) async {
    setState(ResponseState.loading);

    try {
      final response = await _profileService.updateProfile(
        userId: userId,
        updateData: updateData,
      );

      if (response.state == ResponseState.success) {
        _userProfile = response.data;
        setState(ResponseState.success);
      } else {
        _errorMessage = response.error;
        setState(ResponseState.error);
      }
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      setState(ResponseState.error);
    }
  }

  // Get list of following users
  Future<void> getFollowing(String userId) async {
    setState(ResponseState.loading);

    try {
      final response = await _profileService.getFollowing(userId);

      if (response.state == ResponseState.success) {
        _followingList = response.data;
        setState(ResponseState.success);
      } else {
        _errorMessage = response.error;
        setState(ResponseState.error);
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch following list: $e';
      setState(ResponseState.error);
    }
  }

  // Get list of followers
  Future<void> getFollowers(String userId) async {
    setState(ResponseState.loading);

    try {
      final response = await _profileService.getFollowers(userId);

      if (response.state == ResponseState.success) {
        _followersList = response.data;
        setState(ResponseState.success);
      } else {
        _errorMessage = response.error;
        setState(ResponseState.error);
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch followers list: $e';
      setState(ResponseState.error);
    }
  }

  // Follow a user
  Future<void> followUser({
    required String userId,
    required String targetId,
  }) async {
    setState(ResponseState.loading);

    try {
      final response = await _profileService.followUser(
        userId: userId,
        targetId: targetId,
      );

      if (response.state == ResponseState.success) {
        await getFollowing(userId); // Refresh following list
        setState(ResponseState.success);
      } else {
        _errorMessage = response.error;
        setState(ResponseState.error);
      }
    } catch (e) {
      _errorMessage = 'Failed to follow user: $e';
      setState(ResponseState.error);
    }
  }

  // Unfollow a user
  Future<void> unfollowUser({
    required String userId,
    required String targetId,
  }) async {
    setState(ResponseState.loading);

    try {
      final response = await _profileService.unfollowUser(
        userId: userId,
        targetId: targetId,
      );

      if (response.state == ResponseState.success) {
        await getFollowing(userId); // Refresh following list
        setState(ResponseState.success);
      } else {
        _errorMessage = response.error;
        setState(ResponseState.error);
      }
    } catch (e) {
      _errorMessage = 'Failed to unfollow user: $e';
      setState(ResponseState.error);
    }
  }

  // Helper method to set state
  void setState(ResponseState state) {
    _state = state;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Reset provider state
  void reset() {
    _state = ResponseState.initial;
    _errorMessage = null;
    _userProfile = null;
    _followingList = null;
    _followersList = null;
    _authData = null;
    notifyListeners();
  }
}
