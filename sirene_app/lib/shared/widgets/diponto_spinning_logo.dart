import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_assets.dart';

/// Ícone Diponto girando — mesmo recurso visual do smart.diponto.com.
class DipontoSpinningLogo extends StatefulWidget {
  const DipontoSpinningLogo({
    super.key,
    this.size = 96,
    this.duration = const Duration(milliseconds: 1800),
  });

  final double size;
  final Duration duration;

  @override
  State<DipontoSpinningLogo> createState() => _DipontoSpinningLogoState();
}

class _DipontoSpinningLogoState extends State<DipontoSpinningLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: SvgPicture.asset(
        AppAssets.brandIcon,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => Image.asset(
          AppAssets.appIcon,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
