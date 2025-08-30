/// Centralized API configuration
///
/// You can override the base URL at build/run time using:
///   flutter run --dart-define=API_BASE_URL=https://your-backend.example.com/api
///   flutter run --dart-define=API_BASE_URL=http://localhost:5001/api
///
/// If not provided, it auto-detects the best local URL by platform.
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Default production backend
  static const String _prodBaseUrl =
      'https://fitness-backend-eight.vercel.app/api';

  // Auto-detect local/dev backend
  static String get _defaultLocalBaseUrl {
    if (kIsWeb) return 'http://localhost:5001/api';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:5001/api';
    } catch (_) {
      // Fallback below
    }
    // iOS simulator / macOS / others
    return 'http://localhost:5001/api';
  }

  /// Read from --dart-define if provided; otherwise auto-select local.
  static String get baseUrl {
    const env = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (env.isNotEmpty) return env;
    return _defaultLocalBaseUrl;
  }

  /// Convenience getters if you want to hard switch in code
  static String get prod => _prodBaseUrl;
  static String get local => _defaultLocalBaseUrl;
}
