import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'vishani/screens/tracking_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase successfully connected to: ${DefaultFirebaseOptions.currentPlatform.projectId}');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  runApp(const CleanCycleApp());
}

class CleanCycleApp extends StatelessWidget {
  const CleanCycleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyApp();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CleanCycle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B6A3B),
          primary: const Color(0xFF1B6A3B),
        ),
      ),
      home: const TrackingDashboardScreen(),
    );
  }
}