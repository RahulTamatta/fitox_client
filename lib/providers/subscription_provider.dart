import 'package:flutter/material.dart';
import '../services/subscription_service.dart';

class SubscriptionProvider with ChangeNotifier {
  bool _isActive = false;
  String _plan = 'basic';
  DateTime? _expiresAt;
  double _walletBalance = 0.0;
  bool _isLoading = false;
  String? _error;

  bool get isActive => _isActive;
  String get plan => _plan;
  DateTime? get expiresAt => _expiresAt;
  double get walletBalance => _walletBalance;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> checkSubscription(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final status = await SubscriptionService.getStatus(userId);
      if (status != null) {
        _isActive = status['active'] ?? false;
        _plan = status['plan'] ?? 'basic';
        _walletBalance = (status['walletBalance'] ?? 0).toDouble();
        
        if (status['expiresAt'] != null) {
          _expiresAt = DateTime.fromMillisecondsSinceEpoch(status['expiresAt']);
        }
      }
    } catch (e) {
      _error = 'Failed to check subscription: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> validateAction(String userId, String action) async {
    try {
      return await SubscriptionService.validateAction(
        userId: userId,
        action: action,
      );
    } catch (e) {
      _error = 'Failed to validate action: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCache() {
    SubscriptionService.clearCache();
    _isActive = false;
    _plan = 'basic';
    _expiresAt = null;
    _walletBalance = 0.0;
    notifyListeners();
  }
}
