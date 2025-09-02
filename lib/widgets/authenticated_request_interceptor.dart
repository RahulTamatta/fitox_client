import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

class AuthenticatedHttpClient extends http.BaseClient {
  final http.Client _inner;
  final BuildContext context;
  
  AuthenticatedHttpClient(this._inner, this.context);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final authService = AuthService();
      
      // Get valid access token (with auto-refresh)
      final token = await authService.getValidAccessToken();
      
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await _inner.send(request);
      
      // Handle token expiry
      if (response.statusCode == 401) {
        final responseBody = await response.stream.bytesToString();
        
        if (responseBody.contains('TOKEN_EXPIRED') || 
            responseBody.contains('INVALID_TOKEN')) {
          
          if (kDebugMode) {
            debugPrint('Token expired, handling session expiry');
          }
          
          // Handle session expiry on main thread
          WidgetsBinding.instance.addPostFrameCallback((_) {
            authProvider.handleSessionExpiry();
          });
        }
      }
      
      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Authenticated request error: $e');
      }
      rethrow;
    }
  }
}
