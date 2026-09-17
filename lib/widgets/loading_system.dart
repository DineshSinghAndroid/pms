import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/pms_theme.dart';

/// Global Loading Service tracking active network requests
class LoadingService {
  static final LoadingService _instance = LoadingService._internal();
  factory LoadingService() => _instance;
  LoadingService._internal();

  final ValueNotifier<int> _activeCount = ValueNotifier<int>(0);
  final ValueNotifier<String?> _messageNotifier = ValueNotifier<String?>(null);
  Timer? _autoResetTimer;

  ValueNotifier<int> get activeCount => _activeCount;
  ValueNotifier<String?> get messageNotifier => _messageNotifier;

  bool get isLoading => _activeCount.value > 0;

  void startLoading({String? message}) {
    _activeCount.value++;
    if (message != null) {
      _messageNotifier.value = message;
    }
    _autoResetTimer?.cancel();
    _autoResetTimer = Timer(const Duration(seconds: 15), () {
      reset();
    });
  }

  void stopLoading() {
    if (_activeCount.value > 0) {
      _activeCount.value--;
    }
    if (_activeCount.value == 0) {
      _messageNotifier.value = null;
      _autoResetTimer?.cancel();
    }
  }

  void reset() {
    _activeCount.value = 0;
    _messageNotifier.value = null;
    _autoResetTimer?.cancel();
  }
}

/// Global Prince Group Animated Loading Overlay wrapping the entire Flutter app.
///
/// The navigator stays as a stable [Stack] child so modal OverlayEntries are not
/// reparented when a request starts. The dimmer does not use [Scaffold] (that
/// looks up Overlay and breaks while a sheet is popping).
class PrinceGroupLoadingOverlay extends StatelessWidget {
  final Widget child;
  final Widget? banner;

  const PrinceGroupLoadingOverlay({
    super.key,
    required this.child,
    this.banner,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        const Positioned.fill(child: _LoadingLayer()),
        ?banner,
      ],
    );
  }
}

class _LoadingLayer extends StatelessWidget {
  const _LoadingLayer();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: LoadingService().activeCount,
      builder: (context, count, _) {
        final isVisible = count > 0;
        return IgnorePointer(
          ignoring: !isVisible,
          child: AnimatedOpacity(
            opacity: isVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: isVisible
                ? ValueListenableBuilder<String?>(
                    valueListenable: LoadingService().messageNotifier,
                    builder: (context, msg, _) {
                      return SizedBox.expand(
                        child: ColoredBox(
                          color: Colors.black.withValues(alpha: 0.35),
                          child: Center(
                            child: PrinceGroupAnimatedLoader(
                              message: msg ?? 'Connecting to server...',
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

/// High-End Animated Pulse & Orbit Loader Widget (Prince Group Branding)
class PrinceGroupAnimatedLoader extends StatefulWidget {
  final String? message;
  final double size;

  const PrinceGroupAnimatedLoader({
    super.key,
    this.message,
    this.size = 110,
  });

  @override
  State<PrinceGroupAnimatedLoader> createState() => _PrinceGroupAnimatedLoaderState();
}

class _PrinceGroupAnimatedLoaderState extends State<PrinceGroupAnimatedLoader>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: PmsTheme.primary.withValues(alpha: 0.18),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Outer Rotating Gradient Ring
                AnimatedBuilder(
                  animation: _spinController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _spinController.value * 2 * math.pi,
                      child: CustomPaint(
                        size: Size(widget.size, widget.size),
                        painter: _GradientRingPainter(),
                      ),
                    );
                  },
                ),

                // 2. Counter-Rotating Accent Spheres
                AnimatedBuilder(
                  animation: _spinController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: -_spinController.value * 2 * math.pi,
                      child: CustomPaint(
                        size: Size(widget.size, widget.size),
                        painter: _OrbitingDotsPainter(),
                      ),
                    );
                  },
                ),

                // 3. Central Pulsing Brand Emblem
                ScaleTransition(
                  scale: _pulseScale,
                  child: Container(
                    width: widget.size * 0.52,
                    height: widget.size * 0.52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [PmsTheme.primary, Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: PmsTheme.primary.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/logo.png',
                        width: widget.size * 0.32,
                        height: widget.size * 0.32,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Text(
                          'P',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (widget.message != null && widget.message!.isNotEmpty) ...[
            const SizedBox(height: 18),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.message!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: PmsTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const _AnimatedDots(),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Prince Group',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: PmsTheme.primary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'PMS Control System',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: PmsTheme.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GradientRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;

    const sweepGradient = SweepGradient(
      colors: [
        Color(0x004F46E5),
        PmsTheme.primary,
        Color(0xFF9333EA),
        PmsTheme.accent,
      ],
      stops: [0.0, 0.4, 0.75, 1.0],
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, 1.8 * math.pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _OrbitingDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;

    final dotPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;

    final dot2Paint = Paint()
      ..color = const Color(0xFFEC4899)
      ..style = PaintingStyle.fill;

    final dot1Pos = Offset(center.dx + radius * math.cos(0), center.dy + radius * math.sin(0));
    final dot2Pos = Offset(center.dx + radius * math.cos(math.pi), center.dy + radius * math.sin(math.pi));

    canvas.drawCircle(dot1Pos, 3.5, dotPaint);
    canvas.drawCircle(dot2Pos, 3.0, dot2Paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _AnimatedDots extends StatefulWidget {
  const _AnimatedDots();

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final step = (_controller.value * 3).floor() + 1;
        final dots = '.' * step;
        return SizedBox(
          width: 14,
          child: Text(
            dots,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: PmsTheme.primary,
              fontSize: 14,
            ),
          ),
        );
      },
    );
  }
}
