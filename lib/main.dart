import 'package:fit_talk/audio%20services/audio_screen.dart';
import 'package:fit_talk/screens/account/provider/profile_provider.dart';
import 'package:fit_talk/screens/chat/services/chat_provider.dart';
import 'package:fit_talk/screens/home/provider/home_provider.dart';
import 'package:fit_talk/screens/home/services/home_services.dart';
import 'package:fit_talk/screens/onboard/splash_screen.dart';
import 'package:fit_talk/screens/trainer/trainer_home_screen.dart';
import 'package:fit_talk/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider(HomeServices())),
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
            home: SplashScreen(),
          );
        },
      ),
    );
  }
}
