import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pinController;
  late Animation<double> _pinY;
  late Animation<double> _pinScale;
  late Animation<double> _shadowScale;

  late AnimationController _textController;
  late Animation<double> _textOpacity;
  late Animation<double> _textY;
  late Animation<double> _taglineOpacity;

  late AnimationController _pulseController;
  late Animation<double> _pulseRadius;
  late Animation<double> _pulseOpacity;

  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();

    _pinController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _pinY = Tween<double>(begin: -250.0, end: 0.0).animate(
        CurvedAnimation(parent: _pinController, curve: Curves.bounceOut));
    _pinScale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(
            parent: _pinController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _shadowScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _pinController,
            curve: const Interval(0.6, 1.0, curve: Curves.easeOut)));

    _textController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textController, curve: Curves.easeIn));
    _textY = Tween<double>(begin: 28.0, end: 0.0).animate(
        CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _textController,
            curve: const Interval(0.5, 1.0)));

    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _pulseRadius = Tween<double>(begin: 0.9, end: 1.5).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
    _pulseOpacity = Tween<double>(begin: 0.3, end: 0.0).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    // Continuous bounce after drop
    _bounceController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: -10, end: 10).animate(
        CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut));

    _runSequence();
  }

  void _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _pinController.forward();
    await Future.delayed(const Duration(milliseconds: 900));
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF003D35),
              Color(0xFF006B5F),
              Color(0xFF00838F),
              Color(0xFF00BCD4),
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -100, right: -100,
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              bottom: -140, left: -80,
              child: Container(
                width: 380, height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),

            // Building silhouette
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Opacity(
                opacity: 0.07,
                child: CustomPaint(
                  size: Size(size.width, 110),
                  painter: _BuildingSilhouettePainter(),
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // Animated pin — drops in then bounces
                  AnimatedBuilder(
                    animation: Listenable.merge([_pinController, _bounceController]),
                    builder: (_, __) {
                      // After drop animation completes, add continuous bounce
                      final dropDone = _pinController.isCompleted;
                      return Transform.translate(
                        offset: Offset(0, _pinY.value + (dropDone ? _bounceAnim.value : 0)),
                        child: Transform.scale(
                          scale: _pinScale.value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                'assets/images/pin.png',
                                width: 110,
                                height: 110,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.location_on,
                                    size: 80,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),


                  const SizedBox(height: 44),

                  // Title + subtitle
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (_, __) => Opacity(
                      opacity: _textOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _textY.value),
                        child: Column(
                          children: [
                            Text(
                              'Campus Navigator',
                              style: GoogleFonts.poppins(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.3,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'LAU Edition',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.80),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  AnimatedBuilder(
                    animation: _taglineOpacity,
                    builder: (_, __) => Opacity(
                      opacity: _taglineOpacity.value,
                      child: const _BouncingDots(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  AnimatedBuilder(
                    animation: _taglineOpacity,
                    builder: (_, __) => Opacity(
                      opacity: _taglineOpacity.value,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 52),
                        child: Text(
                          'Find your way, always!',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.70),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bouncing dots ──────────────────────────────────────
class _BouncingDots extends StatefulWidget {
  const _BouncingDots();

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
          (_) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 500))
        ..repeat(reverse: true),
    );
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
    _anims = _controllers
        .map((c) => Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: c, curve: Curves.easeInOut),
    ))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
            (i) => AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _anims[i].value),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 5, height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Building silhouette painter ────────────────────────
class _BuildingSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final w = size.width;
    final buildings = [
      [0.00, 0.65, 0.12, 0.35],
      [0.13, 0.40, 0.10, 0.60],
      [0.24, 0.58, 0.09, 0.42],
      [0.34, 0.20, 0.14, 0.80],
      [0.49, 0.45, 0.09, 0.55],
      [0.59, 0.62, 0.08, 0.38],
      [0.68, 0.28, 0.13, 0.72],
      [0.82, 0.50, 0.10, 0.50],
      [0.93, 0.60, 0.07, 0.40],
    ];
    for (final b in buildings) {
      canvas.drawRect(
        Rect.fromLTWH(
            b[0] * w, b[1] * size.height, b[2] * w, b[3] * size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}