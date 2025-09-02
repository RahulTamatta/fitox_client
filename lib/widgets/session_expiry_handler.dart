import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SessionExpiryHandler extends StatefulWidget {
  final Widget child;
  
  const SessionExpiryHandler({
    super.key,
    required this.child,
  });

  @override
  State<SessionExpiryHandler> createState() => _SessionExpiryHandlerState();
}

class _SessionExpiryHandlerState extends State<SessionExpiryHandler> {
  @override
  void initState() {
    super.initState();
    
    // Listen to auth state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      authProvider.addListener(_handleAuthStateChange);
    });
  }

  void _handleAuthStateChange() {
    final authProvider = context.read<AuthProvider>();
    
    // Show session expired message when state changes to unauthenticated with error
    if (authProvider.state == AuthState.unauthenticated && 
        authProvider.error != null &&
        authProvider.error!.contains('Session expired')) {
      
      _showSessionExpiredDialog();
    }
  }

  void _showSessionExpiredDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Session Expired'),
          content: const Text(
            'Your session has expired. Please login again to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Clear error after showing dialog
                context.read<AuthProvider>().clearError();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    final authProvider = context.read<AuthProvider>();
    authProvider.removeListener(_handleAuthStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
