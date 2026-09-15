import 'package:flutter/material.dart';

import '../theme/pms_theme.dart';

class AppGradientBackground extends StatelessWidget {
  final Widget child;

  const AppGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: PmsTheme.pageGradient),
      child: child,
    );
  }
}
