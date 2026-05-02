import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // Phase 1 — pin fades in large (fills screen)
  late AnimationController _fillCtrl;
  late Animation<double> _fillAlpha;
  late Animation<double> _fillScale;

  // Phase 2 — pin rotates (3D Y-axis spin while still large)
  late AnimationController _spinCtrl;
  late Animation<double> _spinAngle;

  // Phase 3 — pin shrinks from full-screen to final size
  late AnimationController _shrinkCtrl;

  // Phase 4 — settle bounce after shrink
  late AnimationController _settleCtrl;
  late Animation<double> _settleY;
  late Animation<double> _settleScale;

  // Phase 5 — title fades in
  late AnimationController _nameCtrl;
  late Animation<double> _nameAlpha;
  late Animation<double> _nameY;

  // Phase 6 — tagline fades in
  late AnimationController _taglineCtrl;
  late Animation<double> _taglineAlpha;
  late Animation<double> _taglineY;

  @override
  void initState() {
    super.initState();

    _fillCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fillAlpha = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fillCtrl, curve: Curves.easeOut));
    // Starts tiny, zooms up to fill screen
    _fillScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fillCtrl, curve: Curves.easeOut));

    _spinCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _spinAngle = Tween<double>(begin: 0.0, end: math.pi * 2.0).animate(
        CurvedAnimation(parent: _spinCtrl, curve: Curves.easeInOut));

    _shrinkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _settleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _settleY = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 14.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 14.0, end: -6.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 35),
      TweenSequenceItem(
          tween: Tween(begin: -6.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 25),
    ]).animate(_settleCtrl);
    _settleScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 0.96), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0), weight: 25),
    ]).animate(_settleCtrl);

    _nameCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _nameAlpha = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _nameCtrl, curve: Curves.easeIn));
    _nameY = Tween<double>(begin: 20.0, end: 0.0).animate(
        CurvedAnimation(parent: _nameCtrl, curve: Curves.easeOut));

    _taglineCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _taglineAlpha = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeIn));
    _taglineY = Tween<double>(begin: 10.0, end: 0.0).animate(
        CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOut));

    _runSequence();
  }

  void _runSequence() async {
    await _fillCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    await _spinCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    await _shrinkCtrl.forward();
    _settleCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _nameCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _taglineCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
    _fillCtrl.dispose();
    _spinCtrl.dispose();
    _shrinkCtrl.dispose();
    _settleCtrl.dispose();
    _nameCtrl.dispose();
    _taglineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const double finalSize = 220.0;
    final double fullSize = screenSize.shortestSide * 1.5;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF114C44),
              Color(0xFF249C8F),
              Color(0xFF4DD0E1),
            ],
          ),
        ),
        child: Stack(
          children: [

            // ── PIN (centered on screen, can be any size) ────────────
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _fillCtrl, _spinCtrl, _shrinkCtrl, _settleCtrl,
                ]),
                builder: (_, __) {
                  final alpha = _fillAlpha.value.clamp(0.0, 1.0);
                  final t = Curves.easeInOut.transform(_shrinkCtrl.value);
                  final currentSize = fullSize + (finalSize - fullSize) * t;
                  final settleOffsetY = (_settleCtrl.isAnimating || _settleCtrl.isCompleted)
                      ? _settleY.value : 0.0;
                  final settleS = (_settleCtrl.isAnimating || _settleCtrl.isCompleted)
                      ? _settleScale.value : 1.0;
                  final entryS = !_fillCtrl.isCompleted ? _fillScale.value : 1.0;
                  final angle = _spinAngle.value;

                  // As shrink goes 0→1, pin moves UP from center
                  // so the whole group (pin + text) ends up centered
                  final shrinkOffsetY = -80.0 * t; // moves up 80px as it shrinks

                  return Opacity(
                    opacity: alpha,
                    child: Transform.translate(
                      offset: Offset(0, shrinkOffsetY + settleOffsetY),
                      child: Transform.scale(
                        scale: entryS * settleS,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(angle),
                          child: Image.asset(
                            'assets/images/pin.png',
                            width: currentSize,
                            height: currentSize * (200 / 180),
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            isAntiAlias: true,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── TITLE + TAGLINE + DOTS (fixed at bottom) ─────────────
            Positioned(
              left: 0, right: 0,
              bottom: MediaQuery.of(context).size.height * 0.38,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  AnimatedBuilder(
                    animation: _nameCtrl,
                    builder: (_, __) => Opacity(
                      opacity: _nameAlpha.value,
                      child: Transform.translate(
                        offset: Offset(0, _nameY.value),
                        child: Text(
                          'CAMPUS NAVIGATOR',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            letterSpacing: 3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  AnimatedBuilder(
                    animation: _taglineCtrl,
                    builder: (_, __) => Opacity(
                      opacity: _taglineAlpha.value,
                      child: Transform.translate(
                        offset: Offset(0, _taglineY.value),
                        child: Text(
                          'Find your way, always!',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1,
                            color: const Color(0xFFCFE3DE),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  AnimatedBuilder(
                    animation: _nameCtrl,
                    builder: (_, __) => Opacity(
                      opacity: _nameAlpha.value,
                      child: const _BouncingDots(),
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

class _BouncingDots extends StatefulWidget {
  const _BouncingDots();
  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
          (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
    _animations = _controllers
        .map((c) => Tween<double>(begin: 0, end: -8).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
            (i) => AnimatedBuilder(
          animation: _animations[i],
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _animations[i].value),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}