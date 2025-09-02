import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/navigator/bottom_navigator_screen.dart';
import '../screens/splash/splash_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (kDebugMode) {
          debugPrint('🔍 AuthWrapper build - State: ${authProvider.state.name}, Initialized: ${authProvider.isInitialized}, Loading: ${authProvider.isLoading}');
        }

        // Show splash screen while initializing
        if (!authProvider.isInitialized || authProvider.isLoading) {
          return const SplashScreen();
        }

        // Navigate based on authentication state
        switch (authProvider.state) {
          case AuthState.authenticated:
            if (kDebugMode) {
              debugPrint('🏠 AuthWrapper navigating to BottomNavigatorScreen');
            }
            return const BottomNavigatorScreen();
          case AuthState.unauthenticated:
          case AuthState.error:
            if (kDebugMode) {
              debugPrint('🔑 AuthWrapper navigating to LoginScreen');
            }
            return const LoginScreen();
          default:
            return const SplashScreen();
        }
      },
    );
  }
}
