import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'navigation/app_router.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/user_repository.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'screens/splash_screen.dart';
import 'features/notifications/data/fcm_service.dart';
import 'features/profile/presentation/profile_controller.dart';

class CleanCycleApp extends StatelessWidget {
  const CleanCycleApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        Provider<UserRepository>(create: (_) => UserRepository()),
        Provider<FcmService>(
          create: (ctx) =>
              FcmService(userRepository: ctx.read<UserRepository>()),
        ),
        ChangeNotifierProvider<AuthController>(
          create: (ctx) => AuthController(
            authRepository: ctx.read<AuthRepository>(),
            userRepository: ctx.read<UserRepository>(),
            firebaseReady: firebaseReady,
            fcmService: ctx.read<FcmService>(),
          ),
        ),
        ChangeNotifierProvider<ProfileController>(
          create: (ctx) => ProfileController(
            userRepository: ctx.read<UserRepository>(),
            authRepository: ctx.read<AuthRepository>(),
            authController: ctx.read<AuthController>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'CleanCycle',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(),
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
