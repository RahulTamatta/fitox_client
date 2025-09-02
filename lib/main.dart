import 'package:fit_talk/screens/account/provider/profile_provider.dart';
import 'package:fit_talk/screens/chat/services/chat_provider.dart';
import 'package:fit_talk/screens/home/provider/home_provider.dart';
import 'package:fit_talk/screens/home/services/home_services.dart';
import 'package:fit_talk/themes/app_theme.dart';
import 'package:fit_talk/providers/chat_provider.dart' as agora_chat;
import 'package:fit_talk/providers/call_provider.dart';
import 'package:fit_talk/providers/auth_provider.dart';
import 'package:fit_talk/widgets/auth_wrapper.dart';
import 'package:fit_talk/widgets/session_expiry_handler.dart';
// import 'package:fit_talk/providers/subscription_provider.dart'; // Commented out for testing
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Force debug mode for console logs
  print('🚀 APP STARTING - Debug mode enabled');
  print('🔧 Platform: ${Platform.operatingSystem}');
  
  // Initialize Firebase (optional - skip if not configured)
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    print('⚠️ App will continue without Firebase features');
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider(HomeServices())),
        // Agora-related providers
        ChangeNotifierProvider(create: (_) => agora_chat.ChatProvider()),
        ChangeNotifierProvider(create: (_) => CallProvider()),
        // ChangeNotifierProvider(create: (_) => SubscriptionProvider()), // Commented out for testing
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            title: 'Fit Talk',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const AppInitializer(),
          );
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SessionExpiryHandler(
      child: AuthWrapper(),
    );
  }
}
