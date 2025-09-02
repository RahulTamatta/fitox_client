import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';

/// A widget that protects routes by checking authentication status
class AuthGuard extends StatelessWidget {
  final Widget child;
  final bool requireAuth;
  
  const AuthGuard({
    super.key,
    required this.child,
    this.requireAuth = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // If authentication is required and user is not authenticated
        if (requireAuth && !authProvider.isAuthenticated) {
          // If still loading, show loading indicator
          if (authProvider.isLoading || !authProvider.isInitialized) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          // Redirect to login screen
          return const LoginScreen();
        }
        
        // If authentication is not required or user is authenticated
        return child;
      },
    );
  }
}

/// Extension to easily wrap widgets with AuthGuard
extension AuthGuardExtension on Widget {
  Widget requireAuth() => AuthGuard(child: this);
  Widget optionalAuth() => AuthGuard(child: this, requireAuth: false);
}
