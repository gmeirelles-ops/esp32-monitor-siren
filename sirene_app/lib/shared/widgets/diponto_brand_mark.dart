import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_assets.dart';

/// Marca Diponto compacta (ícone amarelo) — barra superior, chips, etc.
class DipontoBrandMark extends StatelessWidget {
  const DipontoBrandMark({
    super.key,
    this.size = 32,
    this.borderRadius = 6,
  });

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SvgPicture.asset(
        AppAssets.brandIcon,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => Image.asset(
          AppAssets.appIcon,
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
