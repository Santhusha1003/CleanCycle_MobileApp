import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'collection_schedule/screens/collection_schedule_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('Firebase initialized successfully');

  // Temporary authentication for Firestore testing
  try {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();

      user = userCredential.user;

      debugPrint('Anonymous login successful');
      debugPrint('AUTH USER UID: ${user?.uid}');
    } else {
      debugPrint('User already authenticated');
      debugPrint('AUTH USER UID: ${user.uid}');
    }
  } catch (e) {
    debugPrint('AUTH ERROR: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CleanCycle',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF159447)),
        useMaterial3: true,
      ),
      home: const CollectionScheduleScreen(),
    );
  }
}
