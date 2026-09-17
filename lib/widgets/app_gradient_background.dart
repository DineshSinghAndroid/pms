import 'package:flutter/material.dart';

import '../theme/pms_theme.dart';

/// Full-bleed page gradient. Always paints at least the available viewport
/// so short scroll content does not leave a blank strip below.
class AppGradientBackground extends StatelessWidget {
  final Widget child;

  const AppGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = MediaQuery.sizeOf(context);
        final minW =
            constraints.maxWidth.isFinite ? constraints.maxWidth : size.width;
        final minH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : size.height;

        return DecoratedBox(
          decoration: const BoxDecoration(gradient: PmsTheme.pageGradient),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: minW,
              minHeight: minH,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
