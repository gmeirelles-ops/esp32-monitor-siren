import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/diponto_theme.dart';
import 'diponto_spinning_logo.dart';

/// Abertura do programa — exibida durante o bootstrap inicial.
class AppSplashScreen extends StatelessWidget {
  const AppSplashScreen({super.key});

  /// Tempo mínimo visível na abertura (logo + “Carregando”).
  static const minVisibleDuration = Duration(seconds: 5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF161616),
              Color(0xFF0D0D0D),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const DipontoSpinningLogo(size: 112),
                  const SizedBox(height: 36),
                  SvgPicture.asset(
                    AppAssets.brandWordmark,
                    width: 220,
                    fit: BoxFit.contain,
                    placeholderBuilder: (context) => Image.asset(
                      AppAssets.splashLogo,
                      width: 220,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Carregando',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: DipontoColors.onSurface.withValues(alpha: 0.55),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
