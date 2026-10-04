import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'navigation/app_router.dart';
import 'navigation/app_routes.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final notificationService = NotificationService();
  await notificationService.requestPermission();

  final token = await notificationService.getToken();
  if (token == null) {
    developer.log('FCM token was null.');
  } else {
    developer.log('FCM token obtained successfully.');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CleanCycle',
      theme: AppTheme.lightTheme,
      // TEMPORARY DEV BYPASS: home is set to SplashScreen so the dev bypass
      // in SplashScreen routes to MunicipalDashboard for testing.
      // TO REMOVE: delete the home property (or replace with production home)
      // and restore initialRoute-only routing once authentication is integrated.
      home: const SplashScreen(),
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppRoutes.splash,
    );
  }
}
