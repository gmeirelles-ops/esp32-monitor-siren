import 'dart:async';

import 'package:flutter/material.dart';

/// Splash inicial Diponto – exibe logo e navega para setup após 3 s.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  static const Duration _splashDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _timer = Timer(_splashDuration, _irParaSetup);
  }

  void _irParaSetup() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/setup');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 250,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 40),
            CircularProgressIndicator(color: primary),
          ],
        ),
      ),
    );
  }
}
