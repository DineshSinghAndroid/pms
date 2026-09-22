import 'package:flutter/material.dart';

import '../theme/pms_theme.dart';

enum PmsSnackKind { info, success, error, warning }

void showPmsSnackBar(
  BuildContext context,
  String message, {
  PmsSnackKind kind = PmsSnackKind.info,
}) {
  final Color bg;
  switch (kind) {
    case PmsSnackKind.success:
      bg = PmsTheme.success;
    case PmsSnackKind.error:
      bg = PmsTheme.error;
    case PmsSnackKind.warning:
      bg = PmsTheme.warning;
    case PmsSnackKind.info:
      bg = PmsTheme.textPrimary;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

/// Drag handle + title + close for bottom sheets / dialogs.
class PmsSheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onClose;
  final Widget? trailing;

  const PmsSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onClose,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: PmsTheme.glassBorder,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: PmsTheme.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: PmsTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
            IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close_rounded, size: 20),
              color: PmsTheme.textSecondary,
              onPressed: onClose ?? () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ],
    );
  }
}

class PmsEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? accent;

  const PmsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final tone = accent ?? PmsTheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: PmsTheme.glass(radius: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: tone.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, size: 28, color: tone),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: PmsTheme.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: PmsTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class PmsPageHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final Color? accent;

  const PmsPageHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final tone = accent ?? PmsTheme.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [tone, tone.withValues(alpha: 0.72)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: tone.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: PmsTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: PmsTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

class PmsFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const PmsFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: selected ? Colors.white : PmsTheme.textSecondary,
      ),
      selectedColor: PmsTheme.primary,
      backgroundColor: PmsTheme.glassSurface,
      side: BorderSide(
        color: selected ? PmsTheme.primary : PmsTheme.glassBorder,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class PmsIconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;
  final Color? background;

  const PmsIconAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final tone = color ?? PmsTheme.primary;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background ?? tone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 18, color: tone),
          ),
        ),
      ),
    );
  }
}
