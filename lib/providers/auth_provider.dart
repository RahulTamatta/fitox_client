import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  AuthState _state = AuthState.initial;
  Map<String, dynamic>? _user;
  String? _error;
  bool _isInitialized = false;

  // Getters
  AuthState get state => _state;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;
  bool get isInitialized => _isInitialized;

  // Initialize auth state on app start
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _setState(AuthState.loading);
      
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        _user = await _authService.getCurrentUser();
        _setState(AuthState.authenticated);
      } else {
        _setState(AuthState.unauthenticated);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Auth initialization error: $e');
      }
      _setState(AuthState.unauthenticated);
    } finally {
      _isInitialized = true;
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    try {
      if (kDebugMode) {
        debugPrint('🔐 AuthProvider login attempt for: $email');
      }
      _setState(AuthState.loading);
      _clearError();

      final result = await _authService.login(email, password);
      
      if (result.isSuccess) {
        _user = result.user;
        if (kDebugMode) {
          debugPrint('✅ AuthProvider login successful, user: ${_user?['name']}');
        }
        _setState(AuthState.authenticated);
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ AuthProvider login failed: ${result.error}');
        }
        _setError(result.error ?? 'Login failed');
        _setState(AuthState.unauthenticated);
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 Login error in provider: $e');
      }
      _setError('Login failed: $e');
      _setState(AuthState.unauthenticated);
      return false;
    }
  }

  // Register
  Future<bool> register(Map<String, dynamic> userData) async {
    try {
      _setState(AuthState.loading);
      _clearError();

      final result = await _authService.register(userData);
      
      if (result.isSuccess) {
        _user = result.user;
        _setState(AuthState.authenticated);
        return true;
      } else {
        _setError(result.error ?? 'Registration failed');
        _setState(AuthState.unauthenticated);
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Register error in provider: $e');
      }
      _setError('Registration failed: $e');
      _setState(AuthState.unauthenticated);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      _setState(AuthState.loading);
      await _authService.logout();
      _user = null;
      _clearError();
      _setState(AuthState.unauthenticated);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Logout error in provider: $e');
      }
      // Even if logout fails on server, clear local state
      _user = null;
      _clearError();
      _setState(AuthState.unauthenticated);
    }
  }

  // Logout from all devices
  Future<bool> logoutFromAllDevices() async {
    try {
      _setState(AuthState.loading);
      
      final result = await _authService.logoutFromAllDevices();
      
      _user = null;
      _clearError();
      _setState(AuthState.unauthenticated);
      
      if (!result.isSuccess) {
        _setError(result.error ?? 'Logout from all devices failed');
        return false;
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Logout all devices error in provider: $e');
      }
      // Clear local state even if server request fails
      _user = null;
      _clearError();
      _setState(AuthState.unauthenticated);
      return false;
    }
  }

  // Refresh user data
  Future<void> refreshUser() async {
    try {
      _user = await _authService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Refresh user error: $e');
      }
    }
  }

  // Handle session expiry
  void handleSessionExpiry() {
    _user = null;
    _setError('Session expired. Please login again.');
    _setState(AuthState.unauthenticated);
  }

  // Clear error
  void clearError() {
    _clearError();
  }

  // Private methods
  void _setState(AuthState newState) {
    if (_state != newState) {
      if (kDebugMode) {
        debugPrint('🔄 AuthProvider state change: ${_state.name} → ${newState.name}');
      }
      _state = newState;
      notifyListeners();
    }
  }

  void _setError(String errorMessage) {
    _error = errorMessage;
    _setState(AuthState.error);
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }
}
