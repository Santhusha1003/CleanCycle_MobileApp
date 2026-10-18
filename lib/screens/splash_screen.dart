import 'dart:async';

import 'package:flutter/material.dart';

import '../features/auth/presentation/screens/auth_gate.dart';
import '../theme/app_colors.dart';

/// A single launch animation, followed by the existing session/role gate.
/// Firebase and authentication remain owned by main.dart and CleanCycleApp.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const duration = Duration(seconds: 7);
  static const logoAsset = 'assets/images/logo.png';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  late final Timer _timer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: SplashScreen.duration,
      animationBehavior: AnimationBehavior.preserve,
    )..forward();
    _timer = Timer(SplashScreen.duration, _finish);
  }

  void _finish() {
    if (!mounted || _finished) return;
    _progress.stop();
    setState(() => _finished = true);
  }

  @override
  void dispose() {
    _timer.cancel();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Replace the launch content in place. No pushed routes, repeated timers,
    // sign-out, or shortcut around AuthGate's verification/role decisions.
    if (_finished) return const AuthGate();
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF1FFF6),
                Color(0xFFC8EFDC),
                Color(0xFF6EB995),
                Color(0xFF1E5E3F),
              ],
              stops: [0, 0.43, 0.78, 1],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const IgnorePointer(
                child: CustomPaint(painter: _OrganicBackdrop()),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final logoSize = (constraints.maxHeight * 0.25).clamp(
                      110.0,
                      190.0,
                    );
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 24,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 380),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: logoSize,
                                height: logoSize,
                                // Include the former border inset so removing
                                // the frame does not move or resize the artwork.
                                padding: const EdgeInsets.all(28),
                                decoration: const BoxDecoration(
                                  gradient: RadialGradient(
                                    // A diffuse green shade, rather than a box
                                    // shadow that could reveal a square frame.
                                    center: Alignment(0, 0.1),
                                    colors: [
                                      Color(0x141E5E3F),
                                      Color(0x0C2E8B57),
                                      Color(0x002E8B57),
                                    ],
                                    stops: [0, 0.55, 1],
                                  ),
                                ),
                                child: ShaderMask(
                                  blendMode: BlendMode.dstIn,
                                  shaderCallback: (bounds) => const RadialGradient(
                                    // Keep the central artwork fully opaque;
                                    // feather only its surrounding background.
                                    colors: [
                                      Colors.white,
                                      Colors.white,
                                      Color(0x66FFFFFF),
                                      Colors.transparent,
                                    ],
                                    stops: [0, 0.8, 0.92, 1],
                                  ).createShader(bounds),
                                  child: Image.asset(
                                    SplashScreen.logoAsset,
                                    fit: BoxFit.contain,
                                    semanticLabel: 'CleanCycle logo',
                                    // Retain a readable brand mark if an asset cannot
                                    // be decoded; never display a phone mockup.
                                    errorBuilder: (context, error, stack) =>
                                        Icon(
                                          Icons.recycling_rounded,
                                          color: AppColors.primary,
                                          size: logoSize * 0.5,
                                          semanticLabel: 'CleanCycle',
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              const Text(
                                'CleanCycle',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.primaryDark,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Clean Today, Greener Tomorrow',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF24583E),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 42),
                              SizedBox(
                                width: 170,
                                child: AnimatedBuilder(
                                  animation: _progress,
                                  builder: (context, child) => ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: _progress.value,
                                      minHeight: 4,
                                      color: AppColors.primaryDark,
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.55,
                                      ),
                                      semanticsLabel: 'Loading CleanCycle',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Loading...',
                                style: TextStyle(
                                  color: AppColors.primaryDark,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quiet vector decoration keeps the splash sharp at every screen size.
class _OrganicBackdrop extends CustomPainter {
  const _OrganicBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()..color = Colors.white.withValues(alpha: 0.22);
    canvas.drawCircle(
      Offset(size.width * 0.08, size.height * 0.04),
      size.width * 0.7,
      glow,
    );
    final wave = Path()
      ..moveTo(0, size.height * 0.88)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.73,
        size.width * 0.65,
        size.height * 1.05,
        size.width,
        size.height * 0.85,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      wave,
      Paint()..color = AppColors.primaryDark.withValues(alpha: 0.16),
    );
    _leaf(
      canvas,
      Offset(size.width * 0.88, size.height * 0.16),
      size.width * 0.15,
      -0.5,
    );
    _leaf(
      canvas,
      Offset(size.width * 0.09, size.height * 0.75),
      size.width * 0.11,
      0.55,
    );
    _leaf(
      canvas,
      Offset(size.width * 0.8, size.height * 0.93),
      size.width * 0.18,
      -0.9,
    );
  }

  void _leaf(Canvas canvas, Offset origin, double length, double angle) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);
    final leaf = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-length * 0.5, -length * 0.55, 0, -length)
      ..quadraticBezierTo(length * 0.6, -length * 0.5, 0, 0)
      ..close();
    canvas.drawPath(
      leaf,
      Paint()..color = Colors.white.withValues(alpha: 0.17),
    );
    canvas.drawLine(
      Offset.zero,
      Offset(0, -length * 0.8),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..strokeWidth = 1,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OrganicBackdrop oldDelegate) => false;
}
