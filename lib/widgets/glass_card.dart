import 'package:flutter/material.dart';

import '../theme/pms_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;
  final bool active;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 24,
    this.onTap,
    this.backgroundColor,
    this.border,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ??
            Border.all(
              color: active ? PmsTheme.glassBorderActive : PmsTheme.glassBorder,
              width: 1,
            ),
        boxShadow: active ? PmsTheme.glowShadow : PmsTheme.glassShadow,
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: card,
      ),
    );
  }
}
