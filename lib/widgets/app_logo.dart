import 'package:flutter/material.dart';

/// Shared Prince Eduhub brand logo used across the app.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showShadow;
  final BoxFit fit;

  const AppLogo({
    super.key,
    this.size = 64,
    this.showShadow = true,
    this.fit = BoxFit.cover,
  });

  static const String assetPath = 'assets/logo.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: const Color(0xFF0B1C3F).withValues(alpha: 0.28),
                  blurRadius: size * 0.22,
                  offset: Offset(0, size * 0.08),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: fit,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, _, _) => Container(
            color: const Color(0xFF0B1C3F),
            alignment: Alignment.center,
            child: Text(
              'P',
              style: TextStyle(
                fontSize: size * 0.42,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFFACC15),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
